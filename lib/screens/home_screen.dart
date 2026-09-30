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

// ─── Enum untuk mode yang tersedia ─────────────────────────────────────────
enum _AppMode { downscale, upscale, convert }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _settingsService = SettingsService();

  // State
  _AppMode _selectedMode = _AppMode.downscale;
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
    CacheManagerService().clearAllCache();
  }

  @override
  void dispose() {
    _loadingAnimController.dispose();
    super.dispose();
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
          if (info != null && info.availableDownscaleTargets.isNotEmpty) {
            _selectedResolution = info.availableDownscaleTargets.first;
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

  // ─── Loading ─────────────────────────────────────────────────────────────

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
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    strokeCap: StrokeCap.round,
                    color: theme.colorScheme.primary,
                  ),
                ),
                AnimatedBuilder(
                  animation: _loadingAnimController,
                  builder: (context, _) => Opacity(
                    opacity: 0.5 + (_loadingAnimController.value * 0.5),
                    child: Icon(
                      Icons.movie_filter_rounded,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              _loadingMessage.isNotEmpty
                  ? _loadingMessage
                  : l10n.t('loading_analyzing'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _InfoBanner(
              icon: Icons.info_outline_rounded,
              message: l10n.t('loading_large_hint'),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty / Landing State ───────────────────────────────────────────────

  Widget _buildEmptyState(ThemeData theme, l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero icon + headline ─────────────────────────────────
          _buildHero(theme, l10n),

          const SizedBox(height: 28),

          // ── Mode selector ────────────────────────────────────────
          _buildModeSelector(theme, l10n),

          const SizedBox(height: 24),

          // ── Pick video CTA ───────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _selectedMode == _AppMode.downscale ? _pickVideo : null,
            icon: const Icon(Icons.video_library_rounded, size: 22),
            label: Text(l10n.t('pick_video')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ThemeData theme, l10n) {
    return Column(
      children: [
        // Icon glow
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withAlpha(35),
                    theme.colorScheme.primary.withAlpha(0),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(55),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.video_settings_rounded,
                size: 52,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.t('app_title'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.t('app_tagline'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withAlpha(140),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ─── Mode Selector ───────────────────────────────────────────────────────

  Widget _buildModeSelector(ThemeData theme, l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            l10n.t('select_mode'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withAlpha(170),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _ModeCard(
                icon: Icons.compress_rounded,
                label: l10n.t('mode_downscale'),
                sublabel: '4K → 1080p',
                isSelected: _selectedMode == _AppMode.downscale,
                isEnabled: true,
                accentColor: theme.colorScheme.primary,
                onTap: () => setState(() => _selectedMode = _AppMode.downscale),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeCard(
                icon: Icons.expand_rounded,
                label: l10n.t('mode_upscale'),
                sublabel: '1080p → 4K',
                isSelected: _selectedMode == _AppMode.upscale,
                isEnabled: false,
                accentColor: const Color(0xFF5CD85A),
                badgeText: l10n.t('badge_soon'),
                onTap: null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeCard(
                icon: Icons.swap_horiz_rounded,
                label: l10n.t('mode_convert'),
                sublabel: 'MP4 / MKV / ...',
                isSelected: _selectedMode == _AppMode.convert,
                isEnabled: false,
                accentColor: const Color(0xFFFF9F43),
                badgeText: l10n.t('badge_soon'),
                onTap: null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Content (video dipilih) ──────────────────────────────────────────────

  Widget _buildContent(ThemeData theme, l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode indicator pill di atas
          _ActiveModePill(mode: _selectedMode, theme: theme),
          const SizedBox(height: 12),

          VideoInfoCard(videoInfo: _videoInfo!),
          const SizedBox(height: 14),

          ConversionOptionsCard(
            sourceVideo: _videoInfo!,
            resolutions: _videoInfo!.availableDownscaleTargets,
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
                _selectedResolution != null ? _startProcessing : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
            label: Text(l10n.t('start_conversion')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
          const SizedBox(height: 10),

          // Change video
          OutlinedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            label: Text(l10n.t('change_video')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mode Card Widget ─────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isSelected;
  final bool isEnabled;
  final Color accentColor;
  final VoidCallback? onTap;
  final String? badgeText;

  const _ModeCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.isEnabled,
    required this.accentColor,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Warna berdasarkan state
    final Color bgColor;
    final Color borderColor;
    final Color iconBg;
    final Color labelColor;
    final Color sublabelColor;

    if (!isEnabled) {
      // Disabled — abu-abu lembut
      bgColor = isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(4);
      borderColor =
          isDark ? Colors.white.withAlpha(14) : Colors.black.withAlpha(10);
      iconBg = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6);
      labelColor = theme.colorScheme.onSurface.withAlpha(60);
      sublabelColor = theme.colorScheme.onSurface.withAlpha(40);
    } else if (isSelected) {
      // Selected + enabled
      bgColor = accentColor.withAlpha(20);
      borderColor = accentColor.withAlpha(120);
      iconBg = accentColor.withAlpha(30);
      labelColor = accentColor;
      sublabelColor = accentColor.withAlpha(160);
    } else {
      // Not selected, enabled
      bgColor = isDark ? Colors.white.withAlpha(7) : Colors.black.withAlpha(4);
      borderColor =
          isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(14);
      iconBg = isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6);
      labelColor = theme.colorScheme.onSurface.withAlpha(180);
      sublabelColor = theme.colorScheme.onSurface.withAlpha(100);
    }

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isEnabled
                        ? (isSelected
                            ? accentColor
                            : theme.colorScheme.onSurface.withAlpha(100))
                        : theme.colorScheme.onSurface.withAlpha(40),
                  ),
                ),
                // "Segera" badge untuk fitur belum tersedia
                if (!isEnabled)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3A3A4A)
                            : const Color(0xFFE0E2EE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withAlpha(15),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badgeText ?? 'Soon',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withAlpha(80),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: sublabelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active Mode Pill (di content screen) ────────────────────────────────────

class _ActiveModePill extends StatelessWidget {
  final _AppMode mode;
  final ThemeData theme;

  const _ActiveModePill({required this.mode, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (mode) {
      _AppMode.downscale => (
          Icons.compress_rounded,
          'Mode: Downscale',
          theme.colorScheme.primary
        ),
      _AppMode.upscale => (
          Icons.expand_rounded,
          'Mode: Upscale',
          const Color(0xFF5CD85A)
        ),
      _AppMode.convert => (
          Icons.swap_horiz_rounded,
          'Mode: Convert',
          const Color(0xFFFF9F43)
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(150),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
