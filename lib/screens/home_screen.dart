import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/encoding_options.dart';
import '../models/video_info.dart';
import '../services/cache_manager_service.dart';
import '../services/ffmpeg_service.dart';
import '../services/settings_service.dart';
import '../widgets/animated_flame_title.dart';
import '../widgets/audio_extractor_card.dart';
import '../widgets/conversion_options_card.dart';
import '../widgets/theme_animated_background.dart';
import '../widgets/video_info_card.dart';
import 'processing_screen.dart';
import 'settings_screen.dart';

// ─── Enum mode aplikasi ───────────────────────────────────────────────────────
enum _AppMode { convert, downscale, extractor }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _settingsService = SettingsService();

  // Easter Egg State
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
    CacheManagerService().clearAllCache();
  }

  // ─── Video Picking ───────────────────────────────────────────────────────

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
      final files = await FilePicker.pickFiles(type: FileType.video);

      if (!mounted) return;

      if (files.isNotEmpty) {
        final file = files.first;
        if (file.path == null) {
          setState(() => _isLoading = false);
          return;
        }

        setState(() => _loadingMessage = l10n.t('loading_analyzing'));

        final info = await FFmpegService.getVideoInfo(file.path!);

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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.t('error_read_video'))));
        }
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
      _encodingOptions = const EncodingOptions();
      if (_selectedMode != _AppMode.convert) {
        _encodingOptions = _encodingOptions.copyWith(
          codec: VideoCodec.h264,
          container: VideoContainer.mp4,
        );
      }
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

  // ─── Mode Switching ──────────────────────────────────────────────────────

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

    final options = _selectedMode == _AppMode.convert
        ? _encodingOptions
        : _encodingOptions.copyWith(codec: VideoCodec.h264);
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

  // ─── Easter Egg ─────────────────────────────────────────────────────────

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
      await _settingsService.setThemeMode('sakura');
      if (mounted) {
        final l10n = _settingsService.l10n;
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
                    l10n.t('easter_egg_sakura_unlocked'),
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

  // ─── Build ───────────────────────────────────────────────────────────────

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

  // ─── Loading State ───────────────────────────────────────────────────────

  Widget _buildLoadingState(ThemeData theme, l10n) {
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

  // ─── Empty / Landing State ───────────────────────────────────────────────

  Widget _buildEmptyState(ThemeData theme, l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 40
                  ? constraints.maxHeight - 40
                  : 0,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Mode Segmented Control ───────────────────────────────
                  _buildSegmentedModeBar(theme, l10n),

                  const SizedBox(height: 20),

                  // ── Clean Media Import Box ───────────────────────────────
                  _buildImportCard(theme, l10n),

                  const SizedBox(height: 28),

                  // ── Feature Checklist (Human & Clean) ────────────────────
                  _buildFeatureHighlights(theme, l10n),

                  const Spacer(),
                  const SizedBox(height: 24),
                  _buildMadeWithLoveFooter(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Modern, clean Segmented Control for Mode selection
  Widget _buildSegmentedModeBar(ThemeData theme, l10n) {
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
            // ── Video Group (Convert & Downscale) ───────────────────
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
            // ── Audio Group (Audio Extractor) ──────────────────────
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

  /// Clean, modern Import / Select Video Card
  Widget _buildImportCard(ThemeData theme, l10n) {
    return InkWell(
      onTap: _pickVideo,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline, width: 1.2),
        ),
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
              'MP4, MKV, MOV (up to 4K / 60 FPS)',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clean, professional feature highlights row
  Widget _buildFeatureHighlights(ThemeData theme, l10n) {
    final features = [
      (
        Icons.bolt_rounded,
        l10n.t('feature_offline_fast'),
        l10n.t('feature_offline_fast_desc'),
      ),
      (
        Icons.tune_rounded,
        l10n.t('feature_crf_bitrate'),
        l10n.t('feature_crf_bitrate_desc'),
      ),
      (
        Icons.security_rounded,
        l10n.t('feature_privacy'),
        l10n.t('feature_privacy_desc'),
      ),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Icon(f.$1, size: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.$3,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(130),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Content State (Video Loaded) ─────────────────────────────────────────

  Widget _buildContent(ThemeData theme, l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode switch bar at top
          _buildSegmentedModeBar(theme, l10n),
          const SizedBox(height: 14),

          // Video spec info card
          VideoInfoCard(videoInfo: _videoInfo!),
          const SizedBox(height: 14),

          // Options & resolutions / Audio Extractor
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
              showCodecSelection: _selectedMode == _AppMode.convert,
              onResolutionChanged: (res) =>
                  setState(() => _selectedResolution = res),
              onOptionsChanged: (opts) =>
                  setState(() => _encodingOptions = opts),
              l10n: l10n,
            ),

          const SizedBox(height: 20),

          // Start conversion CTA
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
          const SizedBox(height: 20),
          _buildMadeWithLoveFooter(theme),
        ],
      ),
    );
  }

  Widget _buildMadeWithLoveFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Made with ',
                style: TextStyle(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const Icon(
                Icons.favorite_rounded,
                size: 15,
                color: Color(0xFFEF4444),
              ),
              Text(
                ' by Zerabyte88',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withAlpha(220),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Crafted for high performance & offline privacy',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Segment Item Component ──────────────────────────────────────────────────

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
