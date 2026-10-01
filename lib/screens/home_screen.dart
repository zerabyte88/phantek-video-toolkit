import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/encoding_options.dart';
import '../models/video_info.dart';
import '../services/cache_manager_service.dart';
import '../services/ffmpeg_service.dart';
import '../services/settings_service.dart';
import '../widgets/conversion_options_card.dart';
import '../widgets/video_info_card.dart';
import 'processing_screen.dart';
import 'settings_screen.dart';

// ─── Enum mode aplikasi ───────────────────────────────────────────────────────
enum _AppMode { downscale, upscale, convert }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _settingsService = SettingsService();

  // State
  _AppMode _selectedMode = _AppMode.downscale;
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('error_read_video'))),
          );
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

  // ─── Mode Switching ──────────────────────────────────────────────────────

  List<VideoResolution> _getResolutionsForMode(_AppMode mode, [VideoInfo? source]) {
    final info = source ?? _videoInfo;
    if (info == null) return [];

    final targets = <VideoResolution>[];

    if (mode == _AppMode.convert) {
      targets.add(VideoResolution(
        label: 'Original (${info.resolution})',
        width: info.width,
        height: info.height,
      ));
      return targets;
    }

    final h = info.height;

    if (mode == _AppMode.upscale) {
      final upscaleOptions =
          VideoResolution.standardResolutions.where((r) => r.height > h).toList();
      if (upscaleOptions.isEmpty) {
        targets.add(VideoResolution(
          label: 'Original (${info.resolution})',
          width: info.width,
          height: info.height,
        ));
      } else {
        targets.addAll(upscaleOptions.reversed);
      }
    } else if (mode == _AppMode.downscale) {
      final downscaleOptions =
          VideoResolution.standardResolutions.where((r) => r.height < h).toList();
      if (downscaleOptions.isEmpty) {
        targets.add(VideoResolution(
          label: 'Original (${info.resolution})',
          width: info.width,
          height: info.height,
        ));
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
        _encodingOptions = _encodingOptions.copyWith(
          codec: VideoCodec.h264,
          container: _encodingOptions.container == VideoContainer.webm
              ? VideoContainer.mp4
              : _encodingOptions.container,
        );
      }
    });
  }

  void _startProcessing() async {
    if (_videoInfo == null || _selectedResolution == null) return;
    final options = _selectedMode == _AppMode.convert
        ? _encodingOptions
        : _encodingOptions.copyWith(
            codec: VideoCodec.h264,
            container: _encodingOptions.container == VideoContainer.webm
                ? VideoContainer.mp4
                : _encodingOptions.container,
          );
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          videoInfo: _videoInfo!,
          targetResolution: _selectedResolution!,
          encodingOptions: options,
          appSettings: _settingsService.settings,
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

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = _settingsService.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('app_title')),
        actions: [
          if (_videoInfo != null && !_isLoading)
            IconButton(
              onPressed: _resetVideo,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.t('reset'),
            ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.t('settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(theme, l10n)
            : _videoInfo == null
                ? _buildEmptyState(theme, l10n)
                : _buildContent(theme, l10n),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
        ],
      ),
    );
  }

  /// Modern, clean Segmented Control for Mode selection
  Widget _buildSegmentedModeBar(ThemeData theme, l10n) {
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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SegmentItem(
                  icon: Icons.compress_rounded,
                  label: l10n.t('mode_downscale'),
                  isSelected: _selectedMode == _AppMode.downscale,
                  onTap: () => _onModeChanged(_AppMode.downscale),
                ),
              ),
              Expanded(
                child: _SegmentItem(
                  icon: Icons.expand_rounded,
                  label: l10n.t('mode_upscale'),
                  isSelected: _selectedMode == _AppMode.upscale,
                  onTap: () => _onModeChanged(_AppMode.upscale),
                ),
              ),
              Expanded(
                child: _SegmentItem(
                  icon: Icons.swap_horiz_rounded,
                  label: l10n.t('mode_convert'),
                  isSelected: _selectedMode == _AppMode.convert,
                  onTap: () => _onModeChanged(_AppMode.convert),
                ),
              ),
            ],
          ),
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
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 1.2,
          ),
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
              'MP4, MKV, MOV, WebM (up to 4K / 60 FPS)',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      (Icons.bolt_rounded, l10n.t('feature_offline_fast'), l10n.t('feature_offline_fast_desc')),
      (Icons.tune_rounded, l10n.t('feature_crf_bitrate'), l10n.t('feature_crf_bitrate_desc')),
      (Icons.security_rounded, l10n.t('feature_privacy'), l10n.t('feature_privacy_desc')),
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

          // Options & resolutions
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
            onPressed: _selectedResolution != null ? _startProcessing : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(l10n.t('start_conversion')),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withAlpha(180),
            ),
            const SizedBox(width: 6),
            Flexible(
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
