import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../services/cache_manager_service.dart';
import '../services/device_spec_helper.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';
import '../widgets/theme_animated_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  final _cacheManager = CacheManagerService();
  int _cacheSizeBytes = 0;
  bool _isClearingCache = false;
  Map<String, dynamic>? _hardwareInfo;
  String _appVersion = 'v2.2.0';
  String _buildNumber = '19';

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    _loadHardwareInfo();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${packageInfo.version}';
          _buildNumber = packageInfo.buildNumber.isNotEmpty
              ? packageInfo.buildNumber
              : '19';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appVersion = 'v2.2.0';
          _buildNumber = '19';
        });
      }
    }
  }

  Future<void> _loadHardwareInfo() async {
    final info = await DeviceSpecHelper.getHardwareInfo();
    if (mounted) {
      setState(() {
        _hardwareInfo = info;
      });
    }
  }

  Future<void> _loadCacheSize() async {
    final size = await _cacheManager.getCacheSizeBytes();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = _settingsService.settings;
    final l10n = _settingsService.l10n;
    final deviceCores = AppSettings.deviceCoreCount;
    final totalRamMb = DeviceSpecHelper.getTotalRamMb();
    final marketedRamGb = DeviceSpecHelper.getMarketedRamGb(totalRamMb);
    final is4GbDisabled = marketedRamGb <= 4 || totalRamMb <= 4096;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('settings_title'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ThemeAnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // ─── 1. Appearance & Language ───────────────────────────
              _buildSectionTitle(
                icon: Icons.palette_outlined,
                title: l10n.t('theme_appearance'),
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildModernCard(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Language Selector Tile
                    _buildLanguageTile(context, theme, settings, l10n),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withAlpha(25),
                      ),
                    ),

                    // Theme Header
                    Row(
                      children: [
                        Icon(
                          Icons.contrast_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.t('settings_theme'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4-Grid Theme Selector
                    _buildThemeGrid(theme, settings.themeMode, l10n),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withAlpha(25),
                      ),
                    ),

                    // Keep Screen Awake Switch Tile
                    _buildWakelockTile(theme, settings, l10n),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── 2. Performance & Hardware ──────────────────────────
              _buildSectionTitle(
                icon: Icons.tune_rounded,
                title: l10n.t('performance_encoding'),
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildModernCard(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CPU Cores Setting
                    _buildCpuCoresSection(theme, settings, deviceCores, l10n),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withAlpha(25),
                      ),
                    ),

                    // RAM Buffer Setting
                    _buildRamBufferSection(
                      theme,
                      settings,
                      is4GbDisabled,
                      l10n,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withAlpha(25),
                      ),
                    ),

                    // CPU Preset Setting (Fast vs Normal)
                    _buildCpuPresetSection(theme, settings, l10n),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withAlpha(25),
                      ),
                    ),

                    // Audio Quality Setting
                    _buildAudioQualitySection(theme, settings, l10n),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── 3. Storage & Cache ─────────────────────────────────
              _buildSectionTitle(
                icon: Icons.folder_copy_outlined,
                title: l10n.t('storage_cache'),
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildModernCard(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Output Folder Tile
                    _buildFolderTile(
                      icon: Icons.video_library_outlined,
                      title: l10n.t('settings_output_folder'),
                      currentPath: settings.outputDirectory,
                      defaultLabel: l10n.t('settings_folder_default'),
                      theme: theme,
                      onChange: () async {
                        try {
                          final selected = await FilePicker.getDirectoryPath(
                            dialogTitle: l10n.t('settings_output_folder'),
                          );
                          if (selected != null && selected.trim().isNotEmpty) {
                            await _settingsService.setOutputDirectory(
                              selected.trim(),
                            );
                            if (context.mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.t('settings_folder_changed'),
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (_) {}
                      },
                      onReset: settings.outputDirectory.isNotEmpty
                          ? () async {
                              await _settingsService.setOutputDirectory('');
                              if (context.mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.t('settings_folder_changed'),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      l10n: l10n,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withAlpha(25),
                      ),
                    ),

                    // Audio Output Folder Tile
                    _buildFolderTile(
                      icon: Icons.music_note_outlined,
                      title: l10n.t('settings_audio_output_folder'),
                      currentPath: settings.audioOutputDirectory,
                      defaultLabel: l10n.t('settings_audio_folder_default'),
                      theme: theme,
                      onChange: () async {
                        try {
                          final selected = await FilePicker.getDirectoryPath(
                            dialogTitle: l10n.t('settings_audio_output_folder'),
                          );
                          if (selected != null && selected.trim().isNotEmpty) {
                            await _settingsService.setAudioOutputDirectory(
                              selected.trim(),
                            );
                            if (context.mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.t('settings_audio_folder_changed'),
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (_) {}
                      },
                      onReset: settings.audioOutputDirectory.isNotEmpty
                          ? () async {
                              await _settingsService.setAudioOutputDirectory(
                                '',
                              );
                              if (context.mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.t('settings_audio_folder_changed'),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      l10n: l10n,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withAlpha(25),
                      ),
                    ),

                    // Cache Size & Clear Section
                    _buildCacheSection(context, theme, l10n),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── 4. Device Specs & About ────────────────────────────
              _buildSectionTitle(
                icon: Icons.info_outline_rounded,
                title: l10n.t('device_specs_title'),
                theme: theme,
              ),
              const SizedBox(height: 8),
              if (_hardwareInfo != null) ...[
                _buildModernCard(
                  theme: theme,
                  child: Column(
                    children: [
                      _buildSpecRow(
                        theme,
                        l10n.t('device_name'),
                        _hardwareInfo!['deviceName'] as String? ??
                            '${_hardwareInfo!['manufacturer']} ${_hardwareInfo!['model']}',
                      ),
                      const SizedBox(height: 6),
                      _buildSpecRow(
                        theme,
                        l10n.t('device_model'),
                        _hardwareInfo!['modelCode'] as String? ??
                            _hardwareInfo!['model'] as String? ??
                            l10n.t('unknown'),
                      ),
                      const SizedBox(height: 6),
                      _buildSpecRow(
                        theme,
                        l10n.t('device_cpu'),
                        '${_hardwareInfo!['cpu'] ?? _hardwareInfo!['hardware']} (${_hardwareInfo!['cores']} ${l10n.t('unit_core')})',
                      ),
                      const SizedBox(height: 6),
                      _buildSpecRow(
                        theme,
                        l10n.t('device_gpu'),
                        _hardwareInfo!['gpu'] as String? ??
                            l10n.t('hardware_accel'),
                      ),
                      const SizedBox(height: 6),
                      _buildSpecRow(
                        theme,
                        l10n.t('device_ram'),
                        _hardwareInfo!['ram'] as String? ??
                            '${_hardwareInfo!['ramMb']} MB',
                      ),
                      const SizedBox(height: 6),
                      _buildSpecRow(
                        theme,
                        l10n.t('device_storage'),
                        '${_hardwareInfo!['storage'] ?? '256 GB'} (${_hardwareInfo!['storageFree'] ?? '142 GB'} ${l10n.t('storage_free')})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // About & Developer Card
              _buildAboutCard(theme, l10n),

              const SizedBox(height: 20),

              // Reset Defaults Button
              OutlinedButton.icon(
                onPressed: () => _confirmResetDefaults(context),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(
                  l10n.t('settings_reset_default'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withAlpha(120),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UI Helper Components ──────────────────────────────────────────────────

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: theme.colorScheme.onSurface.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required Widget child,
    required ThemeData theme,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withAlpha(170)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(isDark ? 35 : 55),
          width: 1.0,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }

  // ── Language Selector Tile & Bottom Sheet ──────────────────────────────────

  Widget _buildLanguageTile(
    BuildContext context,
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    // Find active language metadata
    final active = AppLocalizations.supportedLanguages.firstWhere(
      (l) => l['code'] == settings.languageCode,
      orElse: () => {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showLanguageModal(context, theme, settings, l10n),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.translate_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('settings_language'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.t('settings_language_desc'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(60),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    active['flag'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    active['name']?.split(' ').first ?? 'Language',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageModal(
    BuildContext context,
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withAlpha(50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.t('select_language_title'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withAlpha(30),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: AppLocalizations.supportedLanguages.length,
                    itemBuilder: (_, index) {
                      final item = AppLocalizations.supportedLanguages[index];
                      final code = item['code']!;
                      final isSelected = settings.languageCode == code;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: isSelected
                              ? theme.colorScheme.primary.withAlpha(25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await _settingsService.setLanguage(code);
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withAlpha(20),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    item['flag'] ?? '',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item['name'] ?? code,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_rounded,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.t('active_language_badge'),
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Theme Grid Selector ───────────────────────────────────────────────────

  Widget _buildThemeGrid(
    ThemeData theme,
    String currentTheme,
    AppLocalizations l10n,
  ) {
    final themes = [
      {
        'id': 'dark',
        'title': l10n.t('theme_dark'),
        'desc': l10n.t('theme_dark_desc'),
        'icon': Icons.dark_mode_rounded,
        'accent': const Color(0xFF38BDF8),
        'badge': null,
      },
      {
        'id': 'oled',
        'title': l10n.t('theme_oled'),
        'desc': l10n.t('theme_oled_desc'),
        'icon': Icons.nightlight_round,
        'accent': const Color(0xFFA78BFA),
        'badge': 'AMOLED',
      },
      {
        'id': 'sakura',
        'title': l10n.t('theme_sakura'),
        'desc': l10n.t('theme_sakura_desc'),
        'icon': Icons.local_florist_rounded,
        'accent': const Color(0xFFF472B6),
        'badge': '🌸 AMOLED',
      },
      {
        'id': 'light',
        'title': l10n.t('theme_light'),
        'desc': l10n.t('theme_light_desc'),
        'icon': Icons.light_mode_rounded,
        'accent': const Color(0xFFFBBF24),
        'badge': null,
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 82,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final item = themes[index];
        final id = item['id'] as String;
        final isSelected = currentTheme == id;
        final accent = item['accent'] as Color;
        final badge = item['badge'] as String?;

        return Material(
          color: isSelected
              ? accent.withAlpha(25)
              : theme.colorScheme.surfaceContainerHighest.withAlpha(35),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await _settingsService.setThemeMode(id);
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : theme.colorScheme.outline.withAlpha(25),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 17,
                        color: isSelected
                            ? accent
                            : theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? accent
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    )
                  else
                    Text(
                      (item['desc'] as String).split('•').first.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Wakelock Switch Tile ──────────────────────────────────────────────────

  Widget _buildWakelockTile(
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            settings.keepScreenAwake
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('settings_wakelock'),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.t('settings_wakelock_desc'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withAlpha(130),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: settings.keepScreenAwake,
          onChanged: (val) async {
            await _settingsService.setKeepScreenAwake(val);
            setState(() {});
          },
        ),
      ],
    );
  }

  // ── CPU Cores Section ─────────────────────────────────────────────────────

  Widget _buildCpuCoresSection(
    ThemeData theme,
    AppSettings settings,
    int deviceCores,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.memory_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.t('settings_cpu_threads'),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            l10n.t(
              'settings_detected_cores',
              args: {'count': deviceCores.toString()},
            ),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.t('settings_cpu_threads_desc'),
          style: TextStyle(
            fontSize: 11.5,
            color: theme.colorScheme.onSurface.withAlpha(130),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildChoiceChip(
              theme: theme,
              label: l10n.t('settings_auto_cores'),
              selected: settings.cpuThreads == 0,
              onSelected: () async {
                await _settingsService.setCpuThreads(0);
                setState(() {});
              },
            ),
            ...[1, 2, 4, 6, 8]
                .where((c) => c <= (deviceCores > 0 ? (deviceCores + 2) : 8))
                .map(
                  (c) => _buildChoiceChip(
                    theme: theme,
                    label: '$c ${l10n.t('unit_core')}',
                    selected: settings.cpuThreads == c,
                    onSelected: () async {
                      await _settingsService.setCpuThreads(c);
                      setState(() {});
                    },
                  ),
                ),
          ],
        ),
      ],
    );
  }

  // ── RAM Buffer Section ────────────────────────────────────────────────────

  Widget _buildRamBufferSection(
    ThemeData theme,
    AppSettings settings,
    bool is4GbDisabled,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dns_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.t('settings_ram_buffer'),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${settings.ramBufferMb} MB',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.t('settings_ram_buffer_desc'),
          style: TextStyle(
            fontSize: 11.5,
            color: theme.colorScheme.onSurface.withAlpha(130),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildChoiceChip(
              theme: theme,
              label: '256 MB',
              selected: settings.ramBufferMb == 256,
              onSelected: () async {
                await _settingsService.setRamBuffer(256);
                setState(() {});
              },
            ),
            _buildChoiceChip(
              theme: theme,
              label: '512 MB',
              selected: settings.ramBufferMb == 512,
              onSelected: () async {
                await _settingsService.setRamBuffer(512);
                setState(() {});
              },
            ),
            _buildChoiceChip(
              theme: theme,
              label: '1024 MB',
              selected: settings.ramBufferMb == 1024,
              onSelected: () async {
                await _settingsService.setRamBuffer(1024);
                setState(() {});
              },
            ),
            _buildChoiceChip(
              theme: theme,
              label: '2048 MB',
              selected: settings.ramBufferMb == 2048,
              onSelected: () async {
                await _settingsService.setRamBuffer(2048);
                setState(() {});
              },
            ),
            _buildChoiceChip(
              theme: theme,
              label: '4096 MB',
              selected: settings.ramBufferMb == 4096,
              enabled: !is4GbDisabled,
              onSelected: !is4GbDisabled
                  ? () async {
                      await _settingsService.setRamBuffer(4096);
                      setState(() {});
                    }
                  : null,
            ),
          ],
        ),
        if (is4GbDisabled) ...[
          const SizedBox(height: 6),
          Text(
            l10n.t('settings_ram_4gb_disabled_hint'),
            style: TextStyle(
              fontSize: 10.5,
              color: theme.colorScheme.onSurface.withAlpha(110),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  // ── CPU Preset Section ────────────────────────────────────────────────────

  Widget _buildCpuPresetSection(
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.speed_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.t('settings_cpu_preset'),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.t('settings_cpu_preset_desc'),
          style: TextStyle(
            fontSize: 11.5,
            color: theme.colorScheme.onSurface.withAlpha(130),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                theme: theme,
                label: l10n.t('preset_fast'),
                selected: settings.cpuPreset == 'fast',
                onSelected: () async {
                  await _settingsService.setCpuPreset('fast');
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildChoiceChip(
                theme: theme,
                label: l10n.t('preset_normal'),
                selected: settings.cpuPreset == 'medium',
                onSelected: () async {
                  await _settingsService.setCpuPreset('medium');
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Audio Quality Section ─────────────────────────────────────────────────

  Widget _buildAudioQualitySection(
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.t('settings_audio_quality'),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                settings.audioBitrateKbps == 0
                    ? l10n.t('settings_audio_mute')
                    : '${settings.audioBitrateKbps} kbps',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.t('settings_audio_quality_desc'),
          style: TextStyle(
            fontSize: 11.5,
            color: theme.colorScheme.onSurface.withAlpha(130),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildChoiceChip(
              theme: theme,
              label: l10n.t('settings_audio_mute'),
              selected: settings.audioBitrateKbps == 0,
              onSelected: () async {
                await _settingsService.setAudioBitrate(0);
                setState(() {});
              },
            ),
            ...[64, 128, 192, 256, 320].map(
              (kbps) => _buildChoiceChip(
                theme: theme,
                label: '$kbps kbps',
                selected: settings.audioBitrateKbps == kbps,
                onSelected: () async {
                  await _settingsService.setAudioBitrate(kbps);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Storage Folder Tile ───────────────────────────────────────────────────

  Widget _buildFolderTile({
    required IconData icon,
    required String title,
    required String currentPath,
    required String defaultLabel,
    required ThemeData theme,
    required VoidCallback onChange,
    required VoidCallback? onReset,
    required AppLocalizations l10n,
  }) {
    final isCustom = currentPath.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCustom ? currentPath : defaultLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isCustom
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isCustom
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.folder_open_rounded, size: 15),
              label: Text(l10n.t('settings_change_folder')),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
            if (onReset != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restore_rounded, size: 15),
                label: Text(l10n.t('settings_reset_folder')),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Cache Management Section ──────────────────────────────────────────────

  Widget _buildCacheSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('settings_cache_size'),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CacheManagerService.formatBytes(_cacheSizeBytes),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: _isClearingCache
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _isClearingCache = true);
                      final freed = await _cacheManager.clearAllCache();
                      await _loadCacheSize();
                      if (!mounted) return;
                      setState(() => _isClearingCache = false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.t(
                              'settings_clear_cache_success',
                              args: {
                                'size': CacheManagerService.formatBytes(freed),
                              },
                            ),
                          ),
                        ),
                      );
                    },
              icon: _isClearingCache
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 16),
              label: Text(l10n.t('settings_clear_cache')),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.auto_delete_outlined,
              size: 14,
              color: Color(0xFF10B981),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.t('settings_cache_info'),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l10n.t('settings_cache_info_desc'),
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withAlpha(120),
            height: 1.25,
          ),
        ),
      ],
    );
  }

  // ── About & Developer Card ────────────────────────────────────────────────

  Widget _buildAboutCard(ThemeData theme, AppLocalizations l10n) {
    return _buildModernCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFF06B6D4),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.t('settings_about'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withAlpha(120),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _appVersion,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('about_phantek_subtitle'),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withAlpha(130),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Details Rows
          _buildDetailRow(theme, l10n.t('app_version'), _appVersion),
          _buildDetailRow(
            theme,
            l10n.t('build_label'),
            '$_buildNumber (${l10n.t('release_apk')})',
          ),
          _buildDetailRow(
            theme,
            l10n.t('architecture_label'),
            'ARM64-v8a (FFmpeg 6.0)',
          ),
          _buildDetailRow(
            theme,
            l10n.t('license_label'),
            l10n.t('license_gpl'),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: theme.colorScheme.outline.withAlpha(25),
            ),
          ),

          // Developer Profile Section (Matches test expectations: 'Developer: zerabyte88', 'GitHub', open_in_new icon)
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF06B6D4),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withAlpha(60),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon/developer_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF06B6D4),
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Developer: zerabyte88',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final uri = Uri.parse(
                                'https://github.com/zerabyte88',
                              );
                              try {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (_) {}
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withAlpha(
                                    80,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 11.5,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    'GitHub',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.t('developer_role'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withAlpha(130),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helper Mini Widgets ───────────────────────────────────────────────────

  Widget _buildChoiceChip({
    required ThemeData theme,
    required String label,
    required bool selected,
    required VoidCallback? onSelected,
    bool enabled = true,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return ChoiceChip(
      showCheckmark: false,
      selected: selected && enabled,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark
          ? theme.colorScheme.surfaceContainerHighest.withAlpha(40)
          : theme.colorScheme.surface,
      side: BorderSide(
        color: !enabled
            ? theme.colorScheme.outline.withAlpha(40)
            : (selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withAlpha(60)),
        width: selected ? 1.4 : 1.0,
      ),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: !enabled
              ? theme.colorScheme.onSurface.withAlpha(80)
              : (selected ? Colors.white : theme.colorScheme.onSurface),
        ),
      ),
      onSelected: enabled && onSelected != null ? (_) => onSelected() : null,
    );
  }

  Widget _buildSpecRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetDefaults(BuildContext context) {
    final l10n = _settingsService.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('settings_reset_confirm_title')),
        content: Text(l10n.t('settings_reset_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.t('proc_no')),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await _settingsService.resetToDefaults();
              if (mounted) {
                nav.pop();
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.t('settings_reset_success'))),
                );
              }
            },
            child: Text(
              l10n.t('settings_reset_default'),
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}
