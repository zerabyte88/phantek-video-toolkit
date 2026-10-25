// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../services/device_spec_helper.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_glass_card.dart';
import '../widgets/theme_animated_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  Map<String, dynamic>? _hardwareInfo;
  String _appVersion = 'v2.9.2';
  String _buildNumber = '51';
  double? _dragCardOpacity;

  @override
  void initState() {
    super.initState();
    _settingsService.addListener(_onSettingsChanged);
    _loadHardwareInfo();
    _loadAppVersion();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${packageInfo.version}';
          _buildNumber = packageInfo.buildNumber.isNotEmpty
              ? packageInfo.buildNumber
              : '51';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appVersion = 'v2.9.2';
          _buildNumber = '51';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = _settingsService.settings;
    final l10n = _settingsService.l10n;
    final deviceCores = AppSettings.deviceCoreCount;

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
              // 1. Appearance & Language
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
                    // Language
                    _buildLanguageTile(context, theme, settings, l10n),
                    _buildDivider(theme),

                    // Theme header
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

                    // Theme selector
                    _buildThemeGrid(theme, settings, l10n),

                    _buildDivider(theme),

                    // Card opacity
                    _buildCardOpacitySlider(theme, settings, l10n),

                    _buildDivider(theme),

                    // Screen wakelock
                    _buildWakelockTile(theme, settings, l10n),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Performance & Hardware
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
                    // CPU cores
                    _buildCpuCoresSection(theme, settings, deviceCores, l10n),

                    _buildDivider(theme),

                    // RAM buffer
                    _buildRamBufferSection(theme, settings, l10n),

                    _buildDivider(theme),

                    // Speed preset
                    _buildCpuPresetSection(theme, settings, l10n),

                    _buildDivider(theme),

                    // Audio bitrate
                    _buildAudioQualitySection(theme, settings, l10n),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Advanced Settings
              _buildSectionTitle(
                icon: Icons.science_outlined,
                title: l10n.t('settings_advanced_title'),
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildAdvancedSettingsCard(context, theme, settings, l10n),

              const SizedBox(height: 20),

              // 4. Storage
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
                    // Video folder
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

                    _buildDivider(theme),

                    // Audio folder
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
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Device Specs & About
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
                      const SizedBox(height: 7),
                      _buildSpecRow(
                        theme,
                        l10n.t('device_model'),
                        _hardwareInfo!['modelCode'] as String? ??
                            _hardwareInfo!['model'] as String? ??
                            l10n.t('unknown'),
                      ),
                      const SizedBox(height: 7),
                      _buildCpuSpecRow(
                        context: context,
                        theme: theme,
                        l10n: l10n,
                        soc:
                            _hardwareInfo!['socDescription'] as SocDescription?,
                        fallbackText:
                            _hardwareInfo!['cpu'] as String? ??
                            _hardwareInfo!['hardware'] as String? ??
                            'Standard Processor',
                        cores:
                            _hardwareInfo!['cores'] as int? ??
                            AppSettings.deviceCoreCount,
                      ),
                      const SizedBox(height: 7),
                      _buildSpecRow(
                        theme,
                        l10n.t('device_gpu'),
                        _hardwareInfo!['gpu'] as String? ??
                            l10n.t('hardware_accel'),
                      ),
                      const SizedBox(height: 7),
                      _buildSpecRow(
                        theme,
                        l10n.t('device_ram'),
                        _hardwareInfo!['ram'] as String? ??
                            '${_hardwareInfo!['ramMb']} MB',
                      ),
                      const SizedBox(height: 7),
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

              // About card
              _buildAboutCard(theme, l10n),

              const SizedBox(height: 20),

              // Reset defaults
              Center(
                child: OutlinedButton.icon(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI components

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required ThemeData theme,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: theme.colorScheme.onSurface.withAlpha(220),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required Widget child,
    required ThemeData theme,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return AppGlassCard(padding: padding, child: child);
  }

  Widget _buildDivider(ThemeData theme, {double vertical = 12}) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
      ),
    );
  }

  // Language selector

  Widget _buildLanguageTile(
    BuildContext context,
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    // Active language metadata
    final active = AppLocalizations.supportedLanguages.firstWhere(
      (l) =>
          l['code'] == settings.languageCode ||
          (settings.languageCode == 'zh' && l['code'] == 'zh_CN'),
      orElse: () => {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showLanguageModal(context, theme, settings, l10n),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.t('settings_language_desc'),
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(45),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    active['flag'] ?? '',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      active['name'] ?? 'Language',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
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
                  thickness: 1,
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
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
                      final isSelected =
                          settings.languageCode == code ||
                          (settings.languageCode == 'zh' && code == 'zh_CN');

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

  // Theme selector

  Widget _buildThemeGrid(
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    final themes = [
      {
        'id': 'oled_snowfall',
        'title': l10n.t('theme_oled_snowfall'),
        'desc': l10n.t('theme_oled_snowfall_desc'),
        'icon': Icons.ac_unit_rounded,
        'accent': const Color(0xFF38BDF8),
        'badge': 'AMOLED',
      },
      {
        'id': 'light',
        'title': l10n.t('theme_light'),
        'desc': l10n.t('theme_light_desc'),
        'icon': Icons.light_mode_rounded,
        'accent': const Color(0xFFFBBF24),
        'badge': 'LIGHT',
      },
      {
        'id': 'oled_midnight',
        'title': l10n.t('theme_oled_midnight'),
        'desc': l10n.t('theme_oled_midnight_desc'),
        'icon': Icons.nightlight_round,
        'accent': const Color(0xFFA78BFA),
        'badge': 'AMOLED',
      },
      {
        'id': 'oled_sakura',
        'title': l10n.t('theme_oled_sakura'),
        'desc': l10n.t('theme_oled_sakura_desc'),
        'icon': Icons.local_florist_rounded,
        'accent': const Color(0xFFF472B6),
        'badge': 'AMOLED',
      },
      {
        'id': 'oled_pure',
        'title': l10n.t('theme_oled_pure'),
        'desc': l10n.t('theme_oled_pure_desc'),
        'icon': Icons.brightness_2_outlined,
        'accent': const Color(0xFF60A5FA),
        'badge': l10n.t('badge_static'),
      },
      {
        'id': 'light_clean',
        'title': l10n.t('theme_light_clean'),
        'desc': l10n.t('theme_light_clean_desc'),
        'icon': Icons.wb_sunny_outlined,
        'accent': const Color(0xFF0EA5E9),
        'badge': l10n.t('badge_static'),
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 80,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final item = themes[index];
        final id = item['id'] as String;
        final isSelected = settings.themeMode == id;
        final accent = item['accent'] as Color;
        final badge = item['badge'] as String?;

        return Material(
          color: isSelected
              ? accent.withAlpha(25)
              : theme.colorScheme.surfaceContainerHighest.withAlpha(35),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _settingsService.setThemeMode(id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : theme.colorScheme.outline.withAlpha(30),
                  width: isSelected ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 20,
                    color: isSelected ? accent : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? accent
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: accent.withAlpha(120),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              badge,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  // Card opacity slider

  Widget _buildCardOpacitySlider(
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    final effectiveOpacity = _dragCardOpacity ?? settings.cardOpacity;
    final opacity = effectiveOpacity.clamp(0.5, 1.0);
    final percentage = (opacity * 100).round();
    final isNotDefault = (settings.cardOpacity - 1.0).abs() > 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.opacity_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.t('settings_card_opacity'),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Percentage badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(60),
                ),
              ),
              child: Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            if (isNotDefault) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                tooltip: 'Reset 100%',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: theme.colorScheme.primary,
                onPressed: () {
                  setState(() {
                    _dragCardOpacity = null;
                  });
                  _settingsService.setCardOpacity(1.0);
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            l10n.t('settings_card_opacity_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: theme.colorScheme.onSurface.withAlpha(130),
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: theme.sliderTheme.copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: opacity,
            min: 0.50,
            max: 1.00,
            divisions: 10,
            label: '$percentage%',
            onChanged: (val) {
              final rounded = (val * 20).round() / 20.0;
              if (_dragCardOpacity != rounded) {
                setState(() {
                  _dragCardOpacity = rounded;
                });
                _settingsService.setCardOpacityFast(rounded);
              }
            },
            onChangeEnd: (val) {
              final rounded = (val * 20).round() / 20.0;
              setState(() {
                _dragCardOpacity = null;
              });
              _settingsService.setCardOpacity(rounded);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '50%',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '100% (Default)',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Wakelock tile

  Widget _buildWakelockTile(
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              child: Text(
                l10n.t('settings_wakelock'),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            RepaintBoundary(
              child: Switch(
                value: settings.keepScreenAwake,
                onChanged: (val) {
                  _settingsService.setKeepScreenAwake(val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            l10n.t('settings_wakelock_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: theme.colorScheme.onSurface.withAlpha(130),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // CPU cores section

  Widget _buildCpuCoresSection(
    ThemeData theme,
    AppSettings settings,
    int deviceCores,
    AppLocalizations l10n,
  ) {
    final ramMb =
        _hardwareInfo?['ramMb'] as int? ?? DeviceSpecHelper.getTotalRamMb();
    final autoBaseline = DeviceSpecHelper.resolveThreadCount(
      requestedThreads: 0,
    );
    final safeLimit = DeviceSpecHelper.maxSafeThreadCount(ramMb);
    final marketedRamGb = DeviceSpecHelper.getMarketedRamGb(ramMb);
    final isRisky = settings.cpuThreads > safeLimit;

    final badgeText = settings.cpuThreads == 0
        ? '${l10n.t('badge_auto')} ($autoBaseline ${l10n.t('unit_core')})'
        : '${settings.cpuThreads} ${l10n.t('unit_core')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
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
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        if (settings.cpuThreads == 0) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.t('settings_cpu_auto_subtitle'),
              style: TextStyle(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary.withAlpha(190),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildChoiceChip(
                theme: theme,
                label: l10n.t('badge_auto'),
                selected: settings.cpuThreads == 0,
                onSelected: () => _settingsService.setCpuThreads(0),
              ),
              ...[
                1,
                2,
                4,
                6,
                8,
              ].where((c) => c <= (deviceCores > 0 ? deviceCores : 8)).map((c) {
                final isRec = (c == autoBaseline);
                final label = isRec
                    ? '$c ${l10n.t('unit_core')} (${l10n.t('chip_recommended')})'
                    : '$c ${l10n.t('unit_core')}';
                return _buildChoiceChip(
                  theme: theme,
                  label: label,
                  selected: settings.cpuThreads == c,
                  onSelected: () => _settingsService.setCpuThreads(c),
                );
              }),
            ],
          ),
        ),
        if (isRisky) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.amber.withAlpha(120),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.t(
                      'warn_risky_cores',
                      args: {
                        'ram': marketedRamGb.toString(),
                        'cores': settings.cpuThreads.toString(),
                      },
                    ),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: Text(
            settings.cpuThreads == 0
                ? l10n.t('settings_cpu_threads_auto_desc')
                : _getCpuThreadsDesc(settings.cpuThreads, l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
        ),
      ],
    );
  }

  String _getCpuThreadsDesc(int threads, AppLocalizations l10n) {
    switch (threads) {
      case 1:
        return l10n.t('settings_cpu_threads_1_desc');
      case 2:
        return l10n.t('settings_cpu_threads_2_desc');
      case 4:
        return l10n.t('settings_cpu_threads_4_desc');
      case 6:
        return l10n.t('settings_cpu_threads_6_desc');
      case 8:
        return l10n.t('settings_cpu_threads_8_desc');
      default:
        return l10n.t(
          'settings_cpu_threads_manual_desc',
          args: {'count': threads.toString()},
        );
    }
  }

  // RAM buffer section

  Widget _buildRamBufferSection(
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
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.dns_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.t('settings_ram_buffer'),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildChoiceChip(
                theme: theme,
                label: '256 MB',
                selected: settings.ramBufferMb == 256,
                onSelected: () => _settingsService.setRamBuffer(256),
              ),
              _buildChoiceChip(
                theme: theme,
                label: '512 MB',
                selected: settings.ramBufferMb == 512,
                onSelected: () => _settingsService.setRamBuffer(512),
              ),
              _buildChoiceChip(
                theme: theme,
                label: '1024 MB',
                selected: settings.ramBufferMb == 1024,
                onSelected: () => _settingsService.setRamBuffer(1024),
              ),
              _buildChoiceChip(
                theme: theme,
                label: '2048 MB',
                selected: settings.ramBufferMb == 2048,
                onSelected: () => _settingsService.setRamBuffer(2048),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            settings.ramBufferMb <= 512
                ? l10n.t('settings_ram_low_desc')
                : l10n.t('settings_ram_high_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
        ),
      ],
    );
  }

  // Speed preset section

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
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildChoiceChip(
                theme: theme,
                label: l10n.t('preset_fast_title'),
                selected: settings.cpuPreset == 'fast',
                enabled: true,
                onSelected: () => _settingsService.setCpuPreset('fast'),
              ),
              _buildChoiceChip(
                theme: theme,
                label: l10n.t('preset_normal_title'),
                selected: settings.cpuPreset == 'medium',
                enabled: true,
                onSelected: () => _settingsService.setCpuPreset('medium'),
              ),
              _buildChoiceChip(
                theme: theme,
                label: l10n.t('preset_slow_title'),
                selected: settings.cpuPreset == 'slow',
                enabled: true,
                onSelected: () => _settingsService.setCpuPreset('slow'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            settings.cpuPreset == 'fast'
                ? l10n.t('preset_fast_desc')
                : (settings.cpuPreset == 'slow'
                      ? l10n.t('preset_slow_desc')
                      : l10n.t('preset_normal_desc')),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
        ),
      ],
    );
  }

  // Audio quality section

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
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.t('settings_audio_quality'),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildChoiceChip(
                theme: theme,
                label: l10n.t('settings_audio_mute'),
                selected: settings.audioBitrateKbps == 0,
                onSelected: () => _settingsService.setAudioBitrate(0),
              ),
              ...[64, 128, 192, 256, 320].map(
                (kbps) => _buildChoiceChip(
                  theme: theme,
                  label: '$kbps kbps',
                  selected: settings.audioBitrateKbps == kbps,
                  onSelected: () => _settingsService.setAudioBitrate(kbps),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _getAudioBitrateDesc(settings.audioBitrateKbps, l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
        ),
      ],
    );
  }

  String _getAudioBitrateDesc(int kbps, AppLocalizations l10n) {
    switch (kbps) {
      case 0:
        return l10n.t('settings_audio_mute_desc');
      case 64:
        return l10n.t('settings_audio_bitrate_64_desc');
      case 128:
        return l10n.t('settings_audio_bitrate_128_desc');
      case 192:
        return l10n.t('settings_audio_bitrate_192_desc');
      case 256:
        return l10n.t('settings_audio_bitrate_256_desc');
      case 320:
        return l10n.t('settings_audio_bitrate_320_desc');
      default:
        return l10n.t(
          'settings_audio_bitrate_desc',
          args: {'kbps': kbps.toString()},
        );
    }
  }

  // Advanced Settings

  Widget _buildAdvancedSettingsCard(
    BuildContext context,
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    return _buildModernCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master switch
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (settings.isAdvancedSettingsEnabled
                              ? Colors.amber
                              : theme.colorScheme.primary)
                          .withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.science_rounded,
                  size: 18,
                  color: settings.isAdvancedSettingsEnabled
                      ? Colors.amber
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.t('settings_advanced_enable'),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RepaintBoundary(
                child: Switch(
                  key: const Key('advanced_settings_switch'),
                  value: settings.isAdvancedSettingsEnabled,
                  activeTrackColor: Colors.amber.withAlpha(160),
                  activeThumbColor: Colors.amber,
                  onChanged: (val) => _handleToggleAdvancedSettings(val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              l10n.t('settings_advanced_enable_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: theme.colorScheme.onSurface.withAlpha(130),
                height: 1.3,
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.fastOutSlowIn,
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.topCenter,
            child: settings.isAdvancedSettingsEnabled
                ? RepaintBoundary(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDivider(theme),

                        // Custom Preset Selector
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showPresetPickerSheet(
                            context,
                            theme,
                            settings,
                            l10n,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withAlpha(20),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.speed_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.t('settings_custom_preset'),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            l10n.t(
                                              'settings_custom_preset_desc',
                                            ),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              height: 1.3,
                                              color: theme.colorScheme.onSurface
                                                  .withAlpha(140),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(
                                      15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withAlpha(45),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          settings.customPreset == 'default'
                                              ? l10n.t('preset_default')
                                              : settings.customPreset,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        _buildDivider(theme),

                        // Custom Scaler Selector
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showScalerPickerSheet(
                            context,
                            theme,
                            settings,
                            l10n,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withAlpha(20),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.aspect_ratio_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.t('settings_custom_scaler'),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            l10n.t(
                                              'settings_custom_scaler_desc',
                                            ),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              height: 1.3,
                                              color: theme.colorScheme.onSurface
                                                  .withAlpha(140),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(
                                      15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withAlpha(45),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.photo_size_select_actual_outlined,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          settings.customScaler == 'default'
                                              ? l10n.t('scaler_default')
                                              : settings.customScaler,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _handleToggleAdvancedSettings(bool enable) {
    _settingsService.setAdvancedSettingsEnabled(enable);
  }

  void _showPresetPickerSheet(
    BuildContext context,
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    final presets = [
      {
        'id': 'default',
        'label': l10n.t('preset_default'),
        'desc': l10n.t('preset_default_desc'),
      },
      {
        'id': 'ultrafast',
        'label': 'ultrafast',
        'desc': l10n.t('preset_ultrafast_desc'),
      },
      {
        'id': 'superfast',
        'label': 'superfast',
        'desc': l10n.t('preset_superfast_desc'),
      },
      {
        'id': 'veryfast',
        'label': 'veryfast',
        'desc': l10n.t('preset_veryfast_desc'),
      },
      {'id': 'faster', 'label': 'faster', 'desc': l10n.t('preset_faster_desc')},
      {
        'id': 'fast',
        'label': 'fast',
        'desc': l10n.t('preset_fast_custom_desc'),
      },
      {'id': 'medium', 'label': 'medium', 'desc': l10n.t('preset_medium_desc')},
      {
        'id': 'slow',
        'label': 'slow',
        'desc': l10n.t('preset_slow_custom_desc'),
      },
      {'id': 'slower', 'label': 'slower', 'desc': l10n.t('preset_slower_desc')},
      {
        'id': 'veryslow',
        'label': 'veryslow',
        'desc': l10n.t('preset_veryslow_desc'),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.t('settings_custom_preset'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: presets.length,
                    itemBuilder: (context, i) {
                      final p = presets[i];
                      final isSelected = settings.customPreset == p['id'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Material(
                          color: isSelected
                              ? theme.colorScheme.primary.withAlpha(20)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              await _settingsService.setCustomPreset(p['id']!);
                              if (mounted) setState(() {});
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
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 20,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withAlpha(
                                            100,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['label']!,
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
                                        const SizedBox(height: 2),
                                        Text(
                                          p['desc']!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface
                                                .withAlpha(130),
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

  void _showScalerPickerSheet(
    BuildContext context,
    ThemeData theme,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    final scalers = [
      {
        'id': 'default',
        'label': l10n.t('scaler_default'),
        'desc': l10n.t('scaler_default_desc'),
      },
      {
        'id': 'fast_bilinear',
        'label': 'fast_bilinear',
        'desc': l10n.t('scaler_fast_bilinear_desc'),
      },
      {
        'id': 'bilinear',
        'label': 'bilinear',
        'desc': l10n.t('scaler_bilinear_desc'),
      },
      {'id': 'gauss', 'label': 'gauss', 'desc': l10n.t('scaler_gauss_desc')},
      {'id': 'area', 'label': 'area', 'desc': l10n.t('scaler_area_desc')},
      {
        'id': 'bicubic',
        'label': 'bicubic',
        'desc': l10n.t('scaler_bicubic_desc'),
      },
      {'id': 'spline', 'label': 'spline', 'desc': l10n.t('scaler_spline_desc')},
      {
        'id': 'lanczos',
        'label': 'lanczos',
        'desc': l10n.t('scaler_lanczos_desc'),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.aspect_ratio_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.t('settings_custom_scaler'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: scalers.length,
                    itemBuilder: (context, i) {
                      final s = scalers[i];
                      final isSelected = settings.customScaler == s['id'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Material(
                          color: isSelected
                              ? theme.colorScheme.primary.withAlpha(20)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              await _settingsService.setCustomScaler(s['id']!);
                              if (mounted) setState(() {});
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
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 20,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withAlpha(
                                            100,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s['label']!,
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
                                        const SizedBox(height: 2),
                                        Text(
                                          s['desc']!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface
                                                .withAlpha(130),
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

  // Storage folder tile

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
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: onChange,
                icon: const Icon(Icons.folder_open_rounded, size: 15),
                label: Text(l10n.t('settings_change_folder')),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              if (onReset != null)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restore_rounded, size: 15),
                  label: Text(l10n.t('settings_reset_folder')),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // About & developer card

  Widget _buildAboutCard(ThemeData theme, AppLocalizations l10n) {
    return _buildModernCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF06B6D4),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.t('settings_about'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail rows
          _buildDetailRow(theme, l10n.t('app_version'), _appVersion),
          const SizedBox(height: 6),
          _buildDetailRow(theme, l10n.t('build_label'), _buildNumber),
          const SizedBox(height: 6),
          _buildDetailRow(
            theme,
            l10n.t('license_label'),
            'GPLv3',
            onTap: () => _showAppLicensePage(context, theme),
          ),

          const SizedBox(height: 12),

          // Developer profile
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.terminal_rounded,
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
                        'Developer: zerabyte88',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'github.com/zerabyte88',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withAlpha(130),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final uri = Uri.parse(
                        'https://github.com/zerabyte88/phantek-video-toolkit',
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
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(70),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'GitHub',
                            style: TextStyle(
                              fontSize: 11.5,
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
          ),
        ],
      ),
    );
  }

  void _showAppLicensePage(BuildContext context, ThemeData theme) {
    showLicensePage(
      context: context,
      applicationName: 'Phantek - Video Toolkit',
      applicationVersion: '',
      applicationLegalese: '',
      applicationIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
          Text(
            '$_appVersion ($_buildNumber)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(
              'Copyright © 2026 zerabyte88\n'
              'Licensed under the GNU General Public License v3.0 or later (GPL-3.0-or-later).\n\n'
              'This program comes with ABSOLUTELY NO WARRANTY. This is free software, '
              'and you are welcome to redistribute it under certain conditions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: theme.colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ),
          _buildLicenseLinkTile(
            theme: theme,
            icon: Icons.code_rounded,
            label: 'Source code',
            url: 'https://github.com/zerabyte88/phantek-video-toolkit',
          ),
          const SizedBox(height: 8),
          _buildLicenseLinkTile(
            theme: theme,
            icon: Icons.description_outlined,
            label: 'Third-party notices',
            url: 'https://github.com/zerabyte88/phantek-video-toolkit/blob/main/THIRD_PARTY_NOTICES.md',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLicenseLinkTile({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String url,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            try {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(35),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF06B6D4)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        url,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: const Color(0xFF06B6D4),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF06B6D4)
                              .withAlpha(120),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurface.withAlpha(130),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widgets

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

  Widget _buildCpuSpecRow({
    required BuildContext context,
    required ThemeData theme,
    required AppLocalizations l10n,
    required SocDescription? soc,
    required String fallbackText,
    required int cores,
  }) {
    final String cpuDisplay;
    final String rawName = soc?.rawName ?? fallbackText;
    if (soc != null && soc.isPrecise) {
      cpuDisplay = soc.displayName;
    } else if (soc != null && soc.displayName.isNotEmpty) {
      cpuDisplay = '${soc.displayName} · $cores ${l10n.t('unit_core')}';
    } else {
      cpuDisplay =
          '${l10n.t('device_cpu_generic')} · $cores ${l10n.t('unit_core')}';
    }

    return Semantics(
      label: '${l10n.t('device_cpu_detail_title')}, tap to open',
      button: true,
      child: Tooltip(
        message: rawName,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _showCpuDetailBottomSheet(
              context: context,
              theme: theme,
              l10n: l10n,
              soc: soc,
              displayCpu: cpuDisplay,
              cores: cores,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 105,
                    child: Text(
                      l10n.t('device_cpu'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cpuDisplay,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.primary.withAlpha(150),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCpuDetailBottomSheet({
    required BuildContext context,
    required ThemeData theme,
    required AppLocalizations l10n,
    required SocDescription? soc,
    required String displayCpu,
    required int cores,
  }) {
    final rawName = soc?.rawName ?? displayCpu;
    final details = <MapEntry<String, String>>[];

    details.add(MapEntry(l10n.t('device_cpu'), displayCpu));
    if (soc?.socModel != null && soc!.socModel!.isNotEmpty) {
      details.add(MapEntry('SoC Model', soc.socModel!));
    }
    if (soc?.hardware != null && soc!.hardware!.isNotEmpty) {
      details.add(MapEntry('Hardware', soc.hardware!));
    }
    if (soc?.board != null && soc!.board!.isNotEmpty) {
      details.add(MapEntry('Board', soc.board!));
    }
    if (soc?.brand != null && soc!.brand!.isNotEmpty) {
      details.add(MapEntry('Brand', soc.brand!));
    }
    if (soc?.manufacturer != null && soc!.manufacturer!.isNotEmpty) {
      details.add(MapEntry('Manufacturer', soc.manufacturer!));
    }
    details.add(
      MapEntry(l10n.t('cores_detected'), '$cores ${l10n.t('unit_core')}'),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withAlpha(50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.memory_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.t('device_cpu_detail_title'),
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                      60,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rawName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...details.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 110,
                                child: Text(
                                  e.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(150),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final sb = StringBuffer();
                      sb.writeln('=== CPU / SoC Specifications ===');
                      for (final e in details) {
                        sb.writeln('${e.key}: ${e.value}');
                      }
                      sb.writeln('Raw: $rawName');
                      try {
                        await Clipboard.setData(
                          ClipboardData(text: sb.toString().trim()),
                        );
                      } catch (_) {}
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.t('specs_copied')),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(l10n.t('copy_specs')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    final rowContent = Padding(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onTap != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (showChevron && onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: rowContent,
      );
    }
    return rowContent;
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
