import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  String _appVersion = 'v1.3.1';
  String _buildNumber = '18';

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
              : '18';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = 'v1.3.1';
          _buildNumber = '18';
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
      appBar: AppBar(title: Text(l10n.t('settings_title'))),
      body: ThemeAnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
            // 1. Language Section
            _buildSectionHeader(
              icon: Icons.language_rounded,
              title: l10n.t('settings_language'),
              theme: theme,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t('settings_language_desc'),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: AppLocalizations.supportedLanguages.map((lang) {
                    final isSelected = settings.languageCode == lang['code'];
                    final isDark = theme.brightness == Brightness.dark;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: isSelected
                            ? (isDark
                                  ? theme.colorScheme.primary.withAlpha(45)
                                  : theme.colorScheme.primary.withAlpha(25))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () async {
                            await _settingsService.setLanguage(lang['code']!);
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  lang['flag'] ?? '',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    lang['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.white
                                                : theme.colorScheme.primary)
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: isDark
                                        ? Colors.white
                                        : theme.colorScheme.primary,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // 2. Display Theme Section
            _buildSectionHeader(
              icon: Icons.palette_outlined,
              title: l10n.t('settings_theme'),
              theme: theme,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t('settings_theme_desc'),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildThemeTile(
                      icon: Icons.dark_mode_outlined,
                      title: l10n.t('theme_dark'),
                      subtitle: l10n.t('theme_dark_desc'),
                      value: 'dark',
                      current: settings.themeMode,
                      theme: theme,
                    ),
                    const SizedBox(height: 6),
                    _buildThemeTile(
                      icon: Icons.brightness_2_outlined,
                      title: l10n.t('theme_oled'),
                      subtitle: l10n.t('theme_oled_desc'),
                      value: 'oled',
                      current: settings.themeMode,
                      theme: theme,
                      badge: 'AMOLED',
                    ),
                    const SizedBox(height: 6),
                    _buildThemeTile(
                      icon: Icons.local_florist_outlined,
                      title: l10n.t('theme_sakura'),
                      subtitle: l10n.t('theme_sakura_desc'),
                      value: 'sakura',
                      current: settings.themeMode,
                      theme: theme,
                      badge: '🌸 AMOLED',
                    ),
                    const SizedBox(height: 6),
                    _buildThemeTile(
                      icon: Icons.light_mode_outlined,
                      title: l10n.t('theme_light'),
                      subtitle: l10n.t('theme_light_desc'),
                      value: 'light',
                      current: settings.themeMode,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // 3. Keep Screen Awake Section
            _buildSectionHeader(
              icon: Icons.screen_lock_portrait_outlined,
              title: l10n.t('settings_wakelock'),
              theme: theme,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            settings.keepScreenAwake
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.t('settings_wakelock'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: settings.keepScreenAwake,
                          onChanged: (val) {
                            _settingsService.setKeepScreenAwake(val);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha(80),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.t('settings_wakelock_desc'),
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  150,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // 4. Hardware & Performance Section
            _buildSectionHeader(
              icon: Icons.memory_outlined,
              title: l10n.t('settings_hardware'),
              theme: theme,
            ),
            const SizedBox(height: 10),

            if (_hardwareInfo != null)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.t('device_specs'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildHardwareInfoRow(
                        theme,
                        l10n.t('device_name'),
                        _hardwareInfo!['deviceName'] as String? ??
                            '${_hardwareInfo!['manufacturer']} ${_hardwareInfo!['model']}',
                      ),
                      const SizedBox(height: 6),
                      _buildHardwareInfoRow(
                        theme,
                        l10n.t('device_model'),
                        _hardwareInfo!['modelCode'] as String? ??
                            _hardwareInfo!['model'] as String? ??
                            'Unknown',
                      ),
                      const SizedBox(height: 6),
                      _buildHardwareInfoRow(
                        theme,
                        l10n.t('device_cpu'),
                        '${_hardwareInfo!['cpu'] ?? _hardwareInfo!['hardware']} (${_hardwareInfo!['cores']} ${l10n.t('unit_core')})',
                      ),
                      const SizedBox(height: 6),
                      _buildHardwareInfoRow(
                        theme,
                        l10n.t('device_gpu'),
                        _hardwareInfo!['gpu'] as String? ??
                            'Hardware Graphics Accelerator',
                      ),
                      const SizedBox(height: 6),
                      _buildHardwareInfoRow(
                        theme,
                        l10n.t('device_ram'),
                        _hardwareInfo!['ram'] as String? ??
                            '${_hardwareInfo!['ramMb']} MB',
                      ),
                      const SizedBox(height: 6),
                      _buildHardwareInfoRow(
                        theme,
                        l10n.t('device_storage'),
                        '${_hardwareInfo!['storage'] ?? '256 GB'} (${_hardwareInfo!['storageFree'] ?? '142 GB'} ${l10n.t('storage_free')})',
                      ),
                    ],
                  ),
                ),
              ),

            // CPU Cores Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.speed_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('settings_cpu_threads'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            settings.cpuThreads == 0
                                ? l10n.t('settings_auto_cores')
                                : '${settings.cpuThreads} ${l10n.t('unit_core')}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.t(
                        'settings_detected_cores',
                        args: {'count': deviceCores.toString()},
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('settings_cpu_threads_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCoreChip(
                            label: l10n.t('settings_auto_cores'),
                            value: 0,
                            current: settings.cpuThreads,
                            theme: theme,
                          ),
                          ...[1, 2, 4, 6, 8]
                              .where(
                                (c) =>
                                    c <=
                                    (deviceCores > 0 ? (deviceCores + 2) : 8),
                              )
                              .map(
                                (c) => _buildCoreChip(
                                  label: '$c ${l10n.t('unit_core')}',
                                  value: c,
                                  current: settings.cpuThreads,
                                  theme: theme,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // RAM & Memory Buffer Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.storage_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('settings_ram_buffer'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('settings_ram_buffer_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildRamChip(
                            label: '256 MB',
                            value: 256,
                            current: settings.ramBufferMb,
                            theme: theme,
                          ),
                          _buildRamChip(
                            label: '512 MB',
                            value: 512,
                            current: settings.ramBufferMb,
                            theme: theme,
                          ),
                          _buildRamChip(
                            label: '1024 MB',
                            value: 1024,
                            current: settings.ramBufferMb,
                            theme: theme,
                          ),
                          _buildRamChip(
                            label: '2048 MB',
                            value: 2048,
                            current: settings.ramBufferMb,
                            theme: theme,
                          ),
                          _buildRamChip(
                            label: '4096 MB',
                            value: 4096,
                            current: settings.ramBufferMb,
                            theme: theme,
                            enabled: !is4GbDisabled,
                          ),
                        ],
                      ),
                    ),
                    if (is4GbDisabled) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          l10n.t('settings_ram_4gb_disabled_hint'),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withAlpha(120),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // CPU Preset Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('settings_cpu_preset'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            settings.cpuPreset == 'medium'
                                ? 'NORMAL'
                                : settings.cpuPreset.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('settings_cpu_preset_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                              {'key': 'fast', 'label': l10n.t('preset_fast')},
                              {
                                'key': 'medium',
                                'label': l10n.t('preset_normal'),
                              },
                            ].map((item) {
                              final key = item['key']!;
                              final label = item['label']!;
                              final isSelected = settings.cpuPreset == key;
                              return ChoiceChip(
                                showCheckmark: false,
                                selectedColor: theme.colorScheme.primary,
                                backgroundColor: theme.colorScheme.surface,
                                side: BorderSide(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                                  width: isSelected ? 1.2 : 1.0,
                                ),
                                label: Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _settingsService.setCpuPreset(key);
                                    setState(() {});
                                  }
                                },
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Audio Quality Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.audiotrack_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('settings_audio_quality'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('settings_audio_quality_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            showCheckmark: false,
                            selectedColor: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.surface,
                            side: BorderSide(
                              color: settings.audioBitrateKbps == 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              width: settings.audioBitrateKbps == 0 ? 1.2 : 1.0,
                            ),
                            label: Text(
                              l10n.t('settings_audio_mute'),
                              style: TextStyle(
                                fontWeight: settings.audioBitrateKbps == 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: settings.audioBitrateKbps == 0
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            selected: settings.audioBitrateKbps == 0,
                            onSelected: (selected) {
                              if (selected) {
                                _settingsService.setAudioBitrate(0);
                                setState(() {});
                              }
                            },
                          ),
                          ...[64, 128, 192, 256, 320].map((kbps) {
                            final isSelected =
                                settings.audioBitrateKbps == kbps;
                            return ChoiceChip(
                              showCheckmark: false,
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: isSelected ? 1.2 : 1.0,
                              ),
                              label: Text(
                                '$kbps kbps',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  _settingsService.setAudioBitrate(kbps);
                                  setState(() {});
                                }
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Storage & Cache Management Section
            _buildSectionHeader(
              icon: Icons.cleaning_services_outlined,
              title: l10n.t('settings_storage'),
              theme: theme,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t('settings_storage_desc'),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
            const SizedBox(height: 10),

            // Video Output Storage Directory Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.folder_special_outlined,
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
                                l10n.t('settings_output_folder'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                settings.outputDirectory.isEmpty
                                    ? l10n.t('settings_folder_default')
                                    : settings.outputDirectory,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: settings.outputDirectory.isEmpty
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  color: settings.outputDirectory.isEmpty
                                      ? theme.colorScheme.onSurface.withAlpha(
                                          140,
                                        )
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.t('settings_output_folder_desc'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final selectedDir =
                                    await FilePicker.getDirectoryPath(
                                      dialogTitle: l10n.t(
                                        'settings_output_folder',
                                      ),
                                    );
                                if (selectedDir != null &&
                                    selectedDir.trim().isNotEmpty) {
                                  await _settingsService.setOutputDirectory(
                                    selectedDir.trim(),
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
                              } catch (e) {
                                debugPrint('Failed to pick directory: $e');
                              }
                            },
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: 16,
                            ),
                            label: Text(l10n.t('settings_change_folder')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          if (settings.outputDirectory.isNotEmpty) ...[
                            TextButton.icon(
                              onPressed: () async {
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
                              },
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: Text(l10n.t('settings_reset_folder')),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Audio Output Storage Directory Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.audio_file_outlined,
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
                                l10n.t('settings_audio_output_folder'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                settings.audioOutputDirectory.isEmpty
                                    ? l10n.t('settings_audio_folder_default')
                                    : settings.audioOutputDirectory,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      settings.audioOutputDirectory.isEmpty
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  color: settings.audioOutputDirectory.isEmpty
                                      ? theme.colorScheme.onSurface.withAlpha(
                                          140,
                                        )
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.t('settings_audio_output_folder_desc'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final selectedDir =
                                    await FilePicker.getDirectoryPath(
                                      dialogTitle: l10n.t(
                                        'settings_audio_output_folder',
                                      ),
                                    );
                                if (selectedDir != null &&
                                    selectedDir.trim().isNotEmpty) {
                                  await _settingsService
                                      .setAudioOutputDirectory(
                                        selectedDir.trim(),
                                      );
                                  if (context.mounted) {
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.t(
                                            'settings_audio_folder_changed',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                debugPrint(
                                  'Failed to pick audio directory: $e',
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: 16,
                            ),
                            label: Text(l10n.t('settings_change_folder')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          if (settings.audioOutputDirectory.isNotEmpty) ...[
                            TextButton.icon(
                              onPressed: () async {
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
                              },
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: Text(
                                l10n.t('settings_audio_reset_folder'),
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

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.storage_outlined,
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
                                l10n.t('settings_cache_size'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    140,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CacheManagerService.formatBytes(
                                  _cacheSizeBytes,
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isClearingCache
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  setState(() {
                                    _isClearingCache = true;
                                  });
                                  final freed = await _cacheManager
                                      .clearAllCache();
                                  await _loadCacheSize();
                                  if (!mounted) return;
                                  setState(() {
                                    _isClearingCache = false;
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.t(
                                          'settings_clear_cache_success',
                                          args: {
                                            'size':
                                                CacheManagerService.formatBytes(
                                                  freed,
                                                ),
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                          icon: _isClearingCache
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                ),
                          label: Text(l10n.t('settings_clear_cache')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: theme.colorScheme.outline),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_delete_outlined,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.t('settings_cache_info'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('settings_cache_info_desc'),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(130),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Reset Default Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmResetDefaults(context),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: Text(l10n.t('settings_reset_default')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // About Card (Redesigned to match Image 1 with offline avatar)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: (i) About Phantek + green version pill badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF10B981).withAlpha(140),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            _appVersion,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF34D399),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.t('about_phantek_subtitle'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key-Value Specifications
                    _buildAboutDetailRow(
                      theme,
                      l10n.t('app_version'),
                      _appVersion,
                    ),
                    _buildAboutDetailRow(
                      theme,
                      l10n.t('build_label'),
                      '$_buildNumber (Release APK)',
                    ),
                    _buildAboutDetailRow(
                      theme,
                      l10n.t('architecture_label'),
                      'ARM64-v8a (FFmpeg 6.0)',
                    ),
                    _buildAboutDetailRow(
                      theme,
                      l10n.t('license_label'),
                      'GPLv3',
                    ),

                    const SizedBox(height: 12),
                    Divider(
                      height: 20,
                      color: theme.colorScheme.outline.withAlpha(35),
                    ),
                    const SizedBox(height: 8),

                    // Developer Tile (Offline avatar) - No web navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF06B6D4),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF06B6D4)
                                      .withAlpha(70),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icon/developer_avatar.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
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
                                Text(
                                  'Developer: zerabyte88',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.t('developer_role'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildAboutDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareInfoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
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

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String current,
    required ThemeData theme,
    String? badge,
  }) {
    final isSelected = value == current;
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isSelected
          ? (isDark
                ? theme.colorScheme.primary.withAlpha(45)
                : theme.colorScheme.primary.withAlpha(25))
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () async {
          await _settingsService.setThemeMode(value);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (isDark ? Colors.white : theme.colorScheme.primary)
                    : theme.colorScheme.onSurface.withAlpha(160),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? (isDark
                                      ? Colors.white
                                      : theme.colorScheme.primary)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? (isDark
                                  ? Colors.white.withAlpha(190)
                                  : theme.colorScheme.onSurface.withAlpha(180))
                            : theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? Colors.white : theme.colorScheme.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoreChip({
    required String label,
    required int value,
    required int current,
    required ThemeData theme,
  }) {
    final isSelected = value == current;
    return ChoiceChip(
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
        width: isSelected ? 1.2 : 1.0,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _settingsService.setCpuThreads(value);
          setState(() {});
        }
      },
    );
  }

  Widget _buildRamChip({
    required String label,
    required int value,
    required int current,
    required ThemeData theme,
    bool enabled = true,
  }) {
    final isSelected = value == current;
    return ChoiceChip(
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: !enabled
            ? theme.colorScheme.outline.withAlpha(50)
            : (isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline),
        width: isSelected ? 1.2 : 1.0,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: !enabled
              ? theme.colorScheme.onSurface.withAlpha(80)
              : (isSelected ? Colors.white : theme.colorScheme.onSurface),
        ),
      ),
      selected: isSelected && enabled,
      onSelected: enabled
          ? (selected) {
              if (selected) {
                _settingsService.setRamBuffer(value);
                setState(() {});
              }
            }
          : null,
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
