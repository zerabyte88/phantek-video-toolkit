import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/encoding_options.dart';
import '../models/video_info.dart';
import '../services/cache_manager_service.dart';
import '../services/ffmpeg_service.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';
import '../widgets/animated_flame_title.dart';
import '../widgets/app_glass_card.dart';
import '../widgets/audio_extractor_card.dart';
import '../widgets/conversion_options_card.dart';
import '../widgets/theme_animated_background.dart';
import '../widgets/video_info_card.dart';
import 'processing_screen.dart';
import 'settings_screen.dart';

// App operation modes
enum _AppMode { convert, downscale, extractor }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _settingsService = SettingsService();

  // Easter egg state
  int _easterEggTapCount = 0;
  DateTime? _lastEasterEggTapTime;

  // State
  _AppMode _selectedMode = _AppMode.convert;
  VideoInfo? _videoInfo;
  VideoResolution? _selectedResolution;
  EncodingOptions _encodingOptions = const EncodingOptions();
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    final defaultPreset = SpeedPreset.fromCpuPreset(
      _settingsService.settings.cpuPreset,
    );
    _encodingOptions = EncodingOptions(
      speedPreset: defaultPreset,
      crfValue: defaultPreset.defaultCrf,
    );
    _settingsService.addListener(_onSettingsChanged);
    CacheManagerService().clearAllCache();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCrashedJob();
    });
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final preset = SpeedPreset.fromCpuPreset(
      _settingsService.settings.cpuPreset,
    );
    if (_encodingOptions.speedPreset != preset) {
      setState(() {
        _encodingOptions = _encodingOptions.copyWith(
          speedPreset: preset,
          crfValue: preset.defaultCrf,
        );
      });
    }
  }

  Future<void> _loadVideoFromPath(String path) async {
    final l10n = _settingsService.l10n;
    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.t('loading_analyzing');
      _videoInfo = null;
      _selectedResolution = null;
    });

    try {
      final info = await FFmpegService.getVideoInfo(path);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _videoInfo = info;
        if (info != null) {
          final resolutions = _getResolutionsForMode(_selectedMode, info);
          if (resolutions.isNotEmpty) {
            _selectedResolution = resolutions.first;
          }
        }
      });
      if (info == null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.t('error_read_video'))));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('error_read_video')}: $e')),
        );
      }
    }
  }

  Future<void> _checkCrashedJob() async {
    final marker = await _settingsService.getJobMarker();
    if (marker == null || !mounted) return;

    final inputPath = marker['inputPath'] as String?;
    final outputPath = marker['outputPath'] as String?;
    final allocatedThreads = marker['allocatedThreads'] as int? ?? 4;
    final retryCount = marker['retryCount'] as int? ?? 0;
    final timestamp = marker['timestamp'] as int? ?? 0;

    // Clear stale marker (>24 hours)
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > 24 * 60 * 60 * 1000) {
      await _settingsService.clearJobMarker();
      return;
    }

    // Clean leftover partial file
    if (outputPath != null && outputPath.isNotEmpty) {
      try {
        final f = File(outputPath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }

    if (retryCount >= 2 || allocatedThreads <= 1) {
      await _settingsService.clearJobMarker();
      return;
    }

    final reducedThreads = (allocatedThreads - 1).clamp(1, 8);
    final l10n = _settingsService.l10n;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.t('recovery_title'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.t('recovery_desc', args: {'cores': reducedThreads.toString()}),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _settingsService.clearJobMarker();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(l10n.t('recovery_dismiss')),
            ),
            ElevatedButton(
              onPressed: () async {
                await _settingsService.setCpuThreads(reducedThreads);
                await _settingsService.clearJobMarker();
                if (ctx.mounted) Navigator.of(ctx).pop();

                // Auto-load input file if still available
                if (inputPath != null && File(inputPath).existsSync()) {
                  _loadVideoFromPath(inputPath);
                }
              },
              child: Text(
                l10n.t(
                  'recovery_retry',
                  args: {'cores': reducedThreads.toString()},
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Video selection

  Future<void> _pickVideo() async {
    final l10n = _settingsService.l10n;

    await CacheManagerService().clearAllCache(
      specificInputPath: _videoInfo?.filePath,
    );

    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.t('loading_pick');
      _videoInfo = null;
      _selectedResolution = null;
    });

    try {
      final file = await FilePicker.pickFile(type: FileType.video);

      if (!mounted) return;

      if (file != null && file.path != null) {
        await _loadVideoFromPath(file.path!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('error_read_video')}: $e')),
        );
      }
    }
  }

  void _resetVideo() {
    CacheManagerService().clearAllCache(
      specificInputPath: _videoInfo?.filePath,
    );
    setState(() {
      _videoInfo = null;
      _selectedResolution = null;
    });
  }

  void _resetOptions() {
    setState(() {
      final defaultPreset = SpeedPreset.fromCpuPreset(
        _settingsService.settings.cpuPreset,
      );
      _encodingOptions = EncodingOptions(
        speedPreset: defaultPreset,
        crfValue: defaultPreset.defaultCrf,
        codec: VideoCodec.h264,
        container: VideoContainer.mp4,
      );
      if (_videoInfo != null) {
        final resolutions = _getResolutionsForMode(_selectedMode, _videoInfo);
        if (resolutions.isNotEmpty) {
          _selectedResolution = resolutions.first;
        }
      }
    });

    final l10n = _settingsService.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.t('options_reset_success')),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Mode switching

  List<VideoResolution> _getResolutionsForMode(
    _AppMode mode, [
    VideoInfo? source,
  ]) {
    final info = source ?? _videoInfo;
    if (info == null) return [];

    final targets = <VideoResolution>[];

    if (mode == _AppMode.convert || mode == _AppMode.extractor) {
      targets.add(
        VideoResolution(
          label: 'Original (${info.resolution})',
          width: info.width,
          height: info.height,
        ),
      );
      return targets;
    }

    final dim = info.shortDimension;

    if (mode == _AppMode.downscale) {
      final downscaleOptions = VideoResolution.standardResolutions
          .where((r) => r.height < dim)
          .toList();
      if (downscaleOptions.isEmpty) {
        targets.add(
          VideoResolution(
            label: 'Original (${info.resolution})',
            width: info.width,
            height: info.height,
          ),
        );
      } else {
        targets.addAll(downscaleOptions);
      }
    }

    return targets;
  }

  void _onModeChanged(_AppMode mode) {
    if (_selectedMode == mode) return;
    setState(() {
      _selectedMode = mode;
      final resolutions = _getResolutionsForMode(mode);
      if (resolutions.isNotEmpty) {
        _selectedResolution = resolutions.first;
      }
      if (mode != _AppMode.convert) {
        _encodingOptions = _encodingOptions.copyWith(codec: VideoCodec.h264);
      }
    });
  }

  void _startProcessing() async {
    if (_videoInfo == null) return;
    if (_selectedMode == _AppMode.extractor && !_videoInfo!.hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_settingsService.l10n.t('no_audio_track'))),
      );
      return;
    }
    if (_selectedMode != _AppMode.extractor && _selectedResolution == null) {
      return;
    }

    final fallbackRes =
        _selectedResolution ??
        VideoResolution(
          label: 'Original (${_videoInfo!.resolution})',
          width: _videoInfo!.width,
          height: _videoInfo!.height,
        );

    EncodingOptions options = _selectedMode == _AppMode.convert
        ? _encodingOptions
        : _encodingOptions.copyWith(codec: VideoCodec.h264);

    // Heavy processing confirmation dialog
    if (_selectedMode != _AppMode.extractor &&
        options.speedPreset == SpeedPreset.max &&
        _videoInfo!.isHeavyProcessing) {
      final l10n = _settingsService.l10n;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.t('heavy_process_title'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Text(
              l10n.t('heavy_process_desc'),
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Switch to Normal preset
                  options = options.copyWith(
                    speedPreset: SpeedPreset.normal,
                    crfValue: SpeedPreset.normal.defaultCrf,
                  );
                  Navigator.of(ctx).pop(true);
                },
                child: Text(l10n.t('heavy_process_use_normal')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.t('heavy_process_continue')),
              ),
            ],
          );
        },
      );

      if (proceed != true) return;
    }

    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          videoInfo: _videoInfo!,
          targetResolution: fallbackRes,
          encodingOptions: options,
          appSettings: _settingsService.settings,
          isAudioExtraction: _selectedMode == _AppMode.extractor,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _videoInfo = null;
        _selectedResolution = null;
      });
      CacheManagerService().clearAllCache();
    }
  }

  // Easter egg

  void _onHeaderTitleTap() async {
    final now = DateTime.now();
    if (_lastEasterEggTapTime == null ||
        now.difference(_lastEasterEggTapTime!) > const Duration(seconds: 2)) {
      _easterEggTapCount = 1;
    } else {
      _easterEggTapCount++;
    }
    _lastEasterEggTapTime = now;

    if (_easterEggTapCount >= 10) {
      _easterEggTapCount = 0;
      final isAlreadyUnlocked = _settingsService.settings.isEasterEggUnlocked;

      if (!isAlreadyUnlocked) {
        await _settingsService.setEasterEggUnlocked(true);
        await _settingsService.setThemeMode('oled_sakura');
      }

      if (mounted) {
        final l10n = _settingsService.l10n;
        final message = isAlreadyUnlocked
            ? l10n.t('easter_egg_already_active')
            : l10n.t('easter_egg_sakura_unlocked');

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.local_florist_rounded,
                  color: Color(0xFFF472B6),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFF1F2),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF140D13),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFF472B6), width: 1.5),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = _settingsService.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: (_videoInfo != null && !_isLoading)
            ? IconButton(
                onPressed: _resetVideo,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: l10n.t('back_to_home'),
              )
            : null,
        title: GestureDetector(
          onTap: _onHeaderTitleTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedFlameTitle(title: l10n.t('app_title')),
        ),
        centerTitle: true,
        actions: [
          if (_videoInfo != null && !_isLoading)
            IconButton(
              onPressed: _resetOptions,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.t('reset_options'),
            ),
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.t('settings'),
          ),
        ],
      ),
      body: ThemeAnimatedBackground(
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState(theme, l10n)
              : _videoInfo == null
              ? _buildEmptyState(theme, l10n)
              : _buildContent(theme, l10n),
        ),
      ),
    );
  }

  // Loading state

  Widget _buildLoadingState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _loadingMessage.isNotEmpty
                  ? _loadingMessage
                  : l10n.t('loading_analyzing'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.t('loading_large_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(140),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode selector
          _buildSegmentedModeBar(theme, l10n),

          const SizedBox(height: 20),

          // Media import box
          _buildImportCard(theme, l10n),
        ],
      ),
    );
  }

  /// Segmented control for mode selection.
  Widget _buildSegmentedModeBar(ThemeData theme, AppLocalizations l10n) {
    final isVideoActive =
        _selectedMode == _AppMode.convert ||
        _selectedMode == _AppMode.downscale;
    final isAudioActive = _selectedMode == _AppMode.extractor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            l10n.t('select_mode'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha(150),
              letterSpacing: 0.2,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video modes
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_outlined,
                          size: 13,
                          color: isVideoActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha(150),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.t('category_video'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isVideoActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isVideoActive
                            ? theme.colorScheme.primary.withAlpha(120)
                            : theme.colorScheme.outline,
                        width: isVideoActive ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SegmentItem(
                            icon: Icons.swap_horiz_rounded,
                            label: l10n.t('mode_convert'),
                            isSelected: _selectedMode == _AppMode.convert,
                            onTap: () => _onModeChanged(_AppMode.convert),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _SegmentItem(
                            icon: Icons.compress_rounded,
                            label: l10n.t('mode_downscale'),
                            isSelected: _selectedMode == _AppMode.downscale,
                            onTap: () => _onModeChanged(_AppMode.downscale),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Audio modes
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.audiotrack_outlined,
                          size: 13,
                          color: isAudioActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha(150),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.t('category_audio'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isAudioActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAudioActive
                            ? theme.colorScheme.primary.withAlpha(120)
                            : theme.colorScheme.outline,
                        width: isAudioActive ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SegmentItem(
                            icon: Icons.audiotrack_rounded,
                            label: l10n.t('mode_extractor'),
                            isSelected: _selectedMode == _AppMode.extractor,
                            onTap: () => _onModeChanged(_AppMode.extractor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Video selection card.
  Widget _buildImportCard(ThemeData theme, AppLocalizations l10n) {
    return AppGlassCard(
      onTap: _pickVideo,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      border: Border.all(color: theme.colorScheme.outline, width: 1.2),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.file_upload_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.t('pick_video'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('supported_formats_hint'),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text(l10n.t('pick_video')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Loaded state

  Widget _buildContent(ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode switch
          _buildSegmentedModeBar(theme, l10n),
          const SizedBox(height: 14),

          // Video info card
          VideoInfoCard(videoInfo: _videoInfo!),
          const SizedBox(height: 14),

          // Options card
          if (_selectedMode == _AppMode.extractor)
            AudioExtractorCard(
              sourceVideo: _videoInfo!,
              encodingOptions: _encodingOptions,
              onOptionsChanged: (opts) =>
                  setState(() => _encodingOptions = opts),
              l10n: l10n,
            )
          else
            ConversionOptionsCard(
              sourceVideo: _videoInfo!,
              resolutions: _getResolutionsForMode(_selectedMode),
              selectedResolution: _selectedResolution,
              encodingOptions: _encodingOptions,
              onResolutionChanged: (res) =>
                  setState(() => _selectedResolution = res),
              onOptionsChanged: (opts) =>
                  setState(() => _encodingOptions = opts),
              l10n: l10n,
            ),

          const SizedBox(height: 20),

          // Start conversion
          ElevatedButton.icon(
            onPressed:
                ((_selectedMode == _AppMode.extractor &&
                        (_videoInfo?.hasAudio ?? true)) ||
                    (_selectedMode != _AppMode.extractor &&
                        _selectedResolution != null))
                ? _startProcessing
                : null,
            icon: Icon(
              _selectedMode == _AppMode.extractor
                  ? Icons.audiotrack_rounded
                  : Icons.play_arrow_rounded,
              size: 22,
            ),
            label: Text(
              _selectedMode == _AppMode.extractor
                  ? l10n.t('start_audio_extraction')
                  : l10n.t('start_conversion'),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 10),

          // Change video
          OutlinedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: Text(l10n.t('change_video')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// Segment item widget

class _SegmentItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withAlpha(180),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withAlpha(180),
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
