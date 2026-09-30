import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/cache_manager_service.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';
import '../services/device_spec_helper.dart';

import 'package:package_info_plus/package_info_plus.dart';

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
  String _appVersion = 'Loading...';

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
          _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = 'v1.0.6 (6)';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('settings_title')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // 1. Language Section
            _buildSectionHeader(
              icon: Icons.language_rounded,
              title: l10n.t('settings_language'),
              theme: theme,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t('settings_language_desc'),
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...AppLocalizations.supportedLanguages.map((lang) {
                      final isSelected = settings.languageCode == lang['code'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(30)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: InkWell(
                            onTap: () async {
                              await _settingsService.setLanguage(lang['code']!);
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                            children: [
                              Text(
                                lang['flag'] ?? '',
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  lang['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                        ), // close InkWell
                        ), // close Ink
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Display Theme Section (Dark, OLED, Light)
            _buildSectionHeader(
              icon: Icons.palette_rounded,
              title: l10n.t('settings_theme'),
              theme: theme,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t('settings_theme_desc'),
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildThemeTile(
                      icon: Icons.dark_mode_rounded,
                      title: l10n.t('theme_dark'),
                      subtitle: l10n.t('theme_dark_desc'),
                      value: 'dark',
                      current: settings.themeMode,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    _buildThemeTile(
                      icon: Icons.brightness_2_rounded,
                      title: l10n.t('theme_oled'),
                      subtitle: l10n.t('theme_oled_desc'),
                      value: 'oled',
                      current: settings.themeMode,
                      theme: theme,
                      badge: 'OLED / AMOLED',
                    ),
                    const SizedBox(height: 8),
                    _buildThemeTile(
                      icon: Icons.light_mode_rounded,
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

            const SizedBox(height: 24),

            // 3. Keep Screen Awake (Wakelock) Section with Warning
            _buildSectionHeader(
              icon: Icons.screen_lock_portrait_rounded,
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
                            color: settings.keepScreenAwake
                                ? const Color(0xFFFF9F43).withAlpha(30)
                                : theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            settings.keepScreenAwake
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: settings.keepScreenAwake
                                ? const Color(0xFFFF9F43)
                                : theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            l10n.t('settings_wakelock'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: settings.keepScreenAwake
                            ? const Color(0xFFFF9F43).withAlpha(15)
                            : Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: settings.keepScreenAwake
                              ? const Color(0xFFFF9F43).withAlpha(60)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.battery_alert_rounded,
                            size: 18,
                            color: settings.keepScreenAwake
                                ? const Color(0xFFFF9F43)
                                : Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.t('settings_wakelock_desc'),
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: settings.keepScreenAwake
                                    ? const Color(0xFFFFD180)
                                    : Colors.white60,
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

            const SizedBox(height: 24),

            // 4. Hardware & Performance Section
            _buildSectionHeader(
              icon: Icons.memory_rounded,
              title: l10n.t('settings_hardware'),
              theme: theme,
            ),
            const SizedBox(height: 10),

            // Real Hardware Info Card
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
                          Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.t('device_specs'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildHardwareInfoRow(l10n.t('device_model'), '${_hardwareInfo!['manufacturer']} ${_hardwareInfo!['model']}'),
                      const SizedBox(height: 6),
                      _buildHardwareInfoRow(l10n.t('device_soc'), _hardwareInfo!['hardware']),
                      const SizedBox(height: 6),
                      _buildHardwareInfoRow(l10n.t('device_cpu_cores'), '${_hardwareInfo!['cores']} Core(s)'),
                      const SizedBox(height: 6),
                      _buildHardwareInfoRow(l10n.t('device_total_ram'), '${_hardwareInfo!['ramMb']} MB'),
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
                          Icons.speed_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('settings_cpu_threads'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            settings.cpuThreads == 0
                                ? l10n.t('settings_auto_cores')
                                : '${settings.cpuThreads} Core',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t(
                        'settings_detected_cores',
                        args: {'count': deviceCores.toString()},
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5CD85A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('settings_cpu_threads_desc'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
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
                              .where((c) => c <= (deviceCores > 0 ? (deviceCores + 2) : 8))
                              .map((c) => _buildCoreChip(
                                    label: '$c Core',
                                    value: c,
                                    current: settings.cpuThreads,
                                    theme: theme,
                                  )),
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
                          Icons.storage_rounded,
                          size: 20,
                          color: const Color(0xFF54A0FF),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('settings_ram_buffer'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF54A0FF).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${settings.ramBufferMb} MB',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF54A0FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('settings_ram_buffer_desc'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
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
                        ],
                      ),
                    ),
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
                          Icons.tune_rounded,
                          size: 20,
                          color: const Color(0xFFFF9F43),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('settings_cpu_preset'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9F43).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            settings.cpuPreset == 'medium' ? 'NORMAL' : settings.cpuPreset.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF9F43),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('settings_cpu_preset_desc'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          {
                            'key': 'fast',
                            'label': l10n.t('preset_fast'),
                          },
                          {
                            'key': 'medium',
                            'label': l10n.t('preset_normal'),
                          },
                          {
                            'key': 'slow',
                            'label': l10n.t('preset_slow'),
                          },
                        ].map((item) {
                          final key = item['key']!;
                          final label = item['label']!;
                          final isSelected = settings.cpuPreset == key;
                          return ChoiceChip(
                            showCheckmark: false,
                            label: Text(label),
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

            // Hardware Acceleration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5CD85A).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF5CD85A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('settings_hw_accel'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.t('settings_hw_accel_desc'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.hardwareAcceleration,
                      onChanged: (val) {
                        _settingsService.setHardwareAcceleration(val);
                        setState(() {});
                      },
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
                          Icons.audiotrack_rounded,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('settings_audio_quality'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            settings.audioBitrateKbps == 0
                                ? l10n.t('settings_audio_mute')
                                : '${settings.audioBitrateKbps} kbps',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('settings_audio_quality_desc'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.t('settings_audio_mute')),
                          selected: settings.audioBitrateKbps == 0,
                          onSelected: (selected) {
                            if (selected) {
                              _settingsService.setAudioBitrate(0);
                              setState(() {});
                            }
                          },
                        ),
                        ...[64, 128, 192, 256].map((kbps) {
                          final isSelected = settings.audioBitrateKbps == kbps;
                          return ChoiceChip(
                            label: Text('$kbps kbps'),
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Storage & Cache Management Section
            _buildSectionHeader(
              icon: Icons.cleaning_services_rounded,
              title: l10n.t('settings_storage'),
              theme: theme,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t('settings_storage_desc'),
              style: const TextStyle(fontSize: 12, color: Colors.white54),
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
                            color: const Color(0xFF54A0FF).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.storage_rounded,
                            size: 20,
                            color: Color(0xFF54A0FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('settings_cache_size'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CacheManagerService.formatBytes(_cacheSizeBytes),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isClearingCache
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  setState(() {
                                    _isClearingCache = true;
                                  });
                                  final freed = await _cacheManager.clearAllCache();
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
                            foregroundColor: const Color(0xFF54A0FF),
                            side: const BorderSide(color: Color(0xFF54A0FF)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_delete_rounded,
                          size: 16,
                          color: Color(0xFF5CD85A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.t('settings_cache_info'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5CD85A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('settings_cache_info_desc'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reset & Info
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmResetDefaults(context),
                icon: const Icon(Icons.restore_rounded),
                label: Text(l10n.t('settings_reset_default')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B6B),
                  side: const BorderSide(color: Color(0xFFFF6B6B)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // About Card
            Card(
              color: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.t('settings_about'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('settings_about_desc'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Colors.white12),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'App Version',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white54,
                          ),
                        ),
                        Text(
                          _appVersion,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
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
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
    return Ink(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(25)
            : Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : Colors.white12,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          await _settingsService.setThemeMode(value);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? theme.colorScheme.primary : Colors.white60,
            ),
            const SizedBox(width: 14),
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
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? theme.colorScheme.primary
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
                            color: const Color(0xFF7E76FF).withAlpha(35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7E76FF),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
        ), // close Container
      ), // close InkWell
    ); // close Ink
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
      label: Text(label),
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
  }) {
    final isSelected = value == current;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _settingsService.setRamBuffer(value);
          setState(() {});
        }
      },
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
                  SnackBar(
                    content: Text(l10n.t('settings_reset_success')),
                  ),
                );
              }
            },
            child: Text(
              l10n.t('settings_reset_default'),
              style: const TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }
}
