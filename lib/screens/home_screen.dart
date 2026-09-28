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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _settingsService = SettingsService();
  VideoInfo? _videoInfo;
  VideoResolution? _selectedResolution;
  EncodingOptions _encodingOptions = const EncodingOptions();
  bool _isLoading = false;
  String _loadingMessage = '';
  late AnimationController _loadingAnimController;

  @override
  void initState() {
    super.initState();
    _loadingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Auto-clean any stale temporary files from previous sessions
    CacheManagerService().clearAllCache();
  }

  @override
  void dispose() {
    _loadingAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final l10n = _settingsService.l10n;

    // Clean stale cache before picking new video
    await CacheManagerService().clearAllCache(
      specificInputPath: _videoInfo?.filePath,
    );

    // Immediately show loading screen BEFORE opening the system file picker,
    // so when user selects a file and taps OK, the app is already showing the loading screen
    // while the OS copies/caches the file and FFprobe analyzes it.
    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.t('loading_pick');
      _videoInfo = null;
      _selectedResolution = null;
    });

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.video,
      );

      if (!mounted) return;

      if (files.isNotEmpty) {
        final file = files.first;
        if (file.path == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _loadingMessage = l10n.t('loading_analyzing');
        });

        final info = await FFmpegService.getVideoInfo(file.path!);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _videoInfo = info;
          if (info != null && info.availableDownscaleTargets.isNotEmpty) {
            _selectedResolution = info.availableDownscaleTargets.first;
          }
        });

        if (info == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.t('error_read_video')),
            ),
          );
        }
      } else {
        // User cancelled picker
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.t('error_read_video')}: $e'),
          ),
        );
      }
    }
  }

  void _startProcessing() {
    if (_videoInfo == null || _selectedResolution == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          videoInfo: _videoInfo!,
          targetResolution: _selectedResolution!,
          encodingOptions: _encodingOptions,
          appSettings: _settingsService.settings,
        ),
      ),
    );
  }

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
              onPressed: () {
                CacheManagerService().clearAllCache(
                  specificInputPath: _videoInfo?.filePath,
                );
                setState(() {
                  _videoInfo = null;
                  _selectedResolution = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.t('reset'),
            ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_rounded),
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

  Widget _buildLoadingState(ThemeData theme, l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: theme.colorScheme.primary,
                    backgroundColor: Colors.white10,
                  ),
                ),
                AnimatedBuilder(
                  animation: _loadingAnimController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.6 + (_loadingAnimController.value * 0.4),
                      child: Icon(
                        Icons.movie_filter_rounded,
                        size: 38,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              _loadingMessage.isNotEmpty ? _loadingMessage : l10n.t('loading_analyzing'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.t('loading_large_hint'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(160),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_settings_rounded,
                size: 64,
                color: theme.colorScheme.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.t('app_title'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.t('app_tagline'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library_rounded),
                label: Text(l10n.t('pick_video')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(icon: Icons.hd_rounded, label: l10n.t('feature_downscale')),
                _FeatureChip(icon: Icons.speed_rounded, label: l10n.t('feature_fast')),
                _FeatureChip(icon: Icons.high_quality_rounded, label: l10n.t('feature_quality')),
                _FeatureChip(icon: Icons.offline_bolt_rounded, label: l10n.t('feature_offline')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VideoInfoCard(videoInfo: _videoInfo!),
          const SizedBox(height: 16),
          ConversionOptionsCard(
            sourceVideo: _videoInfo!,
            resolutions: _videoInfo!.availableDownscaleTargets,
            selectedResolution: _selectedResolution,
            encodingOptions: _encodingOptions,
            onResolutionChanged: (res) {
              setState(() {
                _selectedResolution = res;
              });
            },
            onOptionsChanged: (opts) {
              setState(() {
                _encodingOptions = opts;
              });
            },
            l10n: l10n,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _selectedResolution != null ? _startProcessing : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text(l10n.t('start_conversion')),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(l10n.t('change_video')),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? (theme.scaffoldBackgroundColor == Colors.black ? const Color(0xFF14141C) : const Color(0xFF2A2A3E))
        : const Color(0xFFEAEBF2);
    final textColor = theme.colorScheme.onSurface.withAlpha(150);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ],
      ),
    );
  }
}
