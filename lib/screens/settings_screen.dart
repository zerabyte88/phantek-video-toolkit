import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();

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
            // Language Section
            _buildSectionHeader(
              icon: Icons.language_rounded,
              title: l10n.t('settings_language'),
              theme: theme,
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
                      return InkWell(
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
                          margin: const EdgeInsets.only(bottom: 4),
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
                                        : Colors.white,
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
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Hardware & Performance Section
            _buildSectionHeader(
              icon: Icons.memory_rounded,
              title: l10n.t('settings_hardware'),
              theme: theme,
            ),
            const SizedBox(height: 10),

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
                    Wrap(
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
                    Wrap(
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
                            settings.cpuPreset.toUpperCase(),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'ultrafast',
                        'superfast',
                        'veryfast',
                        'fast',
                        'medium',
                        'slow',
                      ].map((preset) {
                        final isSelected = settings.cpuPreset == preset;
                        return ChoiceChip(
                          label: Text(preset),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _settingsService.setCpuPreset(preset);
                              setState(() {});
                            }
                          },
                        );
                      }).toList(),
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

  Widget _buildCoreChip({
    required String label,
    required int value,
    required int current,
    required ThemeData theme,
  }) {
    final isSelected = value == current;
    return ChoiceChip(
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
