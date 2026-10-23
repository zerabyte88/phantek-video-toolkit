import 'package:flutter/material.dart';

import '../models/encoding_options.dart';
import '../models/video_info.dart';
import '../services/device_spec_helper.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';
import 'app_glass_card.dart';

class ConversionOptionsCard extends StatefulWidget {
  final VideoInfo sourceVideo;
  final List<VideoResolution> resolutions;
  final VideoResolution? selectedResolution;
  final EncodingOptions encodingOptions;
  final ValueChanged<VideoResolution> onResolutionChanged;
  final ValueChanged<EncodingOptions> onOptionsChanged;
  final AppLocalizations l10n;

  const ConversionOptionsCard({
    super.key,
    required this.sourceVideo,
    required this.resolutions,
    required this.selectedResolution,
    required this.encodingOptions,
    required this.onResolutionChanged,
    required this.onOptionsChanged,
    required this.l10n,
  });

  @override
  State<ConversionOptionsCard> createState() => _ConversionOptionsCardState();
}

class _ConversionOptionsCardState extends State<ConversionOptionsCard> {
  int _crfValue = 22;
  int _customBitrateMbps = 4;
  bool _isCustomFps = false;
  late int _customFps;

  @override
  void initState() {
    super.initState();
    SettingsService().addListener(_onSettingsUpdated);
    _crfValue = widget.encodingOptions.crfValue;
    _customBitrateMbps = (widget.encodingOptions.customBitrateKbps / 1000)
        .round()
        .clamp(1, 30);
    final appSettings = SettingsService().settings;
    if (appSettings.isAdvancedSettingsEnabled &&
        appSettings.enableHardwareAcceleration &&
        widget.encodingOptions.rateControlMode == RateControlMode.crf) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOptionsChanged(
          widget.encodingOptions.copyWith(rateControlMode: RateControlMode.bitrate),
        );
      });
    }
    final sourceFps = (widget.sourceVideo.fps > 0
        ? widget.sourceVideo.fps.round()
        : 60);
    final maxFps = sourceFps.clamp(15, 120);
    final currentFps = widget.encodingOptions.targetFps;
    const standardFps = [0, 60, 50, 48, 30, 25, 24];
    if (currentFps > 0 && !standardFps.contains(currentFps)) {
      _isCustomFps = true;
      _customFps = currentFps.clamp(10, maxFps);
    } else {
      _isCustomFps = false;
      _customFps = (currentFps > 0 ? currentFps : maxFps).clamp(10, maxFps);
    }
  }

  void _onSettingsUpdated() {
    if (mounted) {
      final appSettings = SettingsService().settings;
      if (appSettings.isAdvancedSettingsEnabled &&
          appSettings.enableHardwareAcceleration &&
          widget.encodingOptions.rateControlMode == RateControlMode.crf) {
        widget.onOptionsChanged(
          widget.encodingOptions.copyWith(rateControlMode: RateControlMode.bitrate),
        );
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    SettingsService().removeListener(_onSettingsUpdated);
    super.dispose();
  }

  @override
  void didUpdateWidget(ConversionOptionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final appSettings = SettingsService().settings;
    if (appSettings.isAdvancedSettingsEnabled &&
        appSettings.enableHardwareAcceleration &&
        widget.encodingOptions.rateControlMode == RateControlMode.crf) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOptionsChanged(
          widget.encodingOptions.copyWith(rateControlMode: RateControlMode.bitrate),
        );
      });
    }
    if (oldWidget.encodingOptions.crfValue != widget.encodingOptions.crfValue) {
      _crfValue = widget.encodingOptions.crfValue;
    }
    if (oldWidget.encodingOptions.customBitrateKbps !=
        widget.encodingOptions.customBitrateKbps) {
      _customBitrateMbps = (widget.encodingOptions.customBitrateKbps / 1000)
          .round()
          .clamp(1, 30);
    }
    if (oldWidget.encodingOptions.targetFps !=
        widget.encodingOptions.targetFps) {
      final currentFps = widget.encodingOptions.targetFps;
      const standardFps = [0, 60, 50, 48, 30, 25, 24];
      if (currentFps > 0 && !standardFps.contains(currentFps)) {
        _isCustomFps = true;
        _customFps = currentFps;
      }
    }
    if (oldWidget.sourceVideo != widget.sourceVideo) {
      final sourceFps = (widget.sourceVideo.fps > 0
          ? widget.sourceVideo.fps.round()
          : 60);
      final maxFps = sourceFps.clamp(15, 120);
      if (_customFps > maxFps) {
        _customFps = maxFps;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;
    final appSettings = SettingsService().settings;
    final isHwAccelActive = appSettings.isAdvancedSettingsEnabled &&
        appSettings.enableHardwareAcceleration;
    final resolvedThreads = DeviceSpecHelper.resolveThreadCount(
      video: widget.sourceVideo,
      requestedThreads: appSettings.cpuThreads,
    );
    final is4K =
        widget.sourceVideo.width >= 3840 ||
        widget.sourceVideo.height >= 2160 ||
        (widget.sourceVideo.width >= 2160 && widget.sourceVideo.height >= 3840);

    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.t('video_options'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.memory_rounded,
                      size: 13,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appSettings.cpuThreads == 0
                          ? l10n.t(
                              'auto_runtime_normal',
                              args: {'count': resolvedThreads.toString()},
                            )
                          : '$resolvedThreads ${l10n.t('unit_core')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (appSettings.cpuThreads == 0 && is4K) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.t(
                  'auto_runtime_4k',
                  args: {'count': resolvedThreads.toString()},
                ),
                style: TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.primary.withAlpha(190),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Resolution
          _buildSectionLabel(
            icon: Icons.aspect_ratio_rounded,
            title: l10n.t('target_resolution'),
            theme: theme,
          ),
          const SizedBox(height: 10),
          ...widget.resolutions.map((res) {
            final isSelected = widget.selectedResolution?.label == res.label;
            return _buildResolutionTile(
              res: res,
              isSelected: isSelected,
              theme: theme,
            );
          }),

          const SizedBox(height: 16),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 16),

          // Active preset
          _buildActivePresetIndicator(theme, l10n),

          const SizedBox(height: 16),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 16),

          // Rate control mode
          _buildSectionLabel(
            icon: Icons.tune_rounded,
            title: l10n.t('rate_control'),
            theme: theme,
          ),
          const SizedBox(height: 10),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: RateControlMode.values.map((mode) {
                final isCrf = mode == RateControlMode.crf;
                final isChipEnabled = !(isHwAccelActive && isCrf);
                final isSelected =
                    widget.encodingOptions.rateControlMode == mode;
                return _buildChoiceChip(
                  label: mode.displayName,
                  isSelected: isSelected && isChipEnabled,
                  isEnabled: isChipEnabled,
                  onSelected: isChipEnabled
                      ? (selected) {
                          if (selected) {
                            widget.onOptionsChanged(
                              widget.encodingOptions.copyWith(rateControlMode: mode),
                            );
                          }
                        }
                      : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isHwAccelActive
                  ? l10n.t('hw_accel_crf_disabled_desc')
                  : (widget.encodingOptions.rateControlMode == RateControlMode.crf
                      ? l10n.t('desc_crf')
                      : l10n.t('desc_bitrate')),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: isHwAccelActive
                    ? theme.colorScheme.onSurface.withAlpha(150)
                    : theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.encodingOptions.rateControlMode == RateControlMode.crf)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _crfValue.toDouble(),
                        min: 16,
                        max: 28,
                        divisions: 12,
                        label: '$_crfValue',
                        onChanged: (val) {
                          final newCrf = val.round();
                          if (newCrf != _crfValue) {
                            setState(() {
                              _crfValue = newCrf;
                            });
                            widget.onOptionsChanged(
                              widget.encodingOptions.copyWith(crfValue: newCrf),
                            );
                          }
                        },
                        onChangeEnd: (val) {
                          final newCrf = val.round();
                          widget.onOptionsChanged(
                            widget.encodingOptions.copyWith(crfValue: newCrf),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_crfValue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                // Slider guide
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.t('crf_hint_sharp'),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurface.withAlpha(120),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.t('crf_hint_small'),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurface.withAlpha(120),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Reset button
                if (_crfValue !=
                    widget.encodingOptions.speedPreset.defaultCrf) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        key: const Key('crf_custom_badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.t('crf_custom'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                      InkWell(
                        key: const Key('crf_reset_button'),
                        onTap: () {
                          final defaultCrf =
                              widget.encodingOptions.speedPreset.defaultCrf;
                          setState(() {
                            _crfValue = defaultCrf;
                          });
                          widget.onOptionsChanged(
                            widget.encodingOptions.copyWith(
                              crfValue: defaultCrf,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                l10n.t('crf_reset'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.encodingOptions.crfValue <= 17) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.amber.withAlpha(90),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.t('crf_warning_low'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.amber,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          if (widget.encodingOptions.rateControlMode ==
              RateControlMode.bitrate) ...[
            Text(
              l10n.t('bitrate_label'),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _customBitrateMbps.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '$_customBitrateMbps Mbps',
                    onChanged: (val) {
                      final newBitrate = val.round();
                      if (newBitrate != _customBitrateMbps) {
                        setState(() {
                          _customBitrateMbps = newBitrate;
                        });
                        widget.onOptionsChanged(
                          widget.encodingOptions.copyWith(
                            customBitrateKbps: newBitrate * 1000,
                          ),
                        );
                      }
                    },
                    onChangeEnd: (val) {
                      final newBitrate = val.round();
                      widget.onOptionsChanged(
                        widget.encodingOptions.copyWith(
                          customBitrateKbps: newBitrate * 1000,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_customBitrateMbps Mbps',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Estimated size
          const SizedBox(height: 12),
          _buildSizeEstimator(theme),

          const SizedBox(height: 16),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 16),

          // Container format
          _buildSectionLabel(
            icon: Icons.video_file_outlined,
            title: l10n.t('container_format'),
            theme: theme,
          ),
          const SizedBox(height: 10),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: VideoContainer.values.map((format) {
                final isSelected = widget.encodingOptions.container == format;
                return _buildChoiceChip(
                  label: '${format.displayName} (.${format.extension})',
                  isSelected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      widget.onOptionsChanged(
                        widget.encodingOptions.copyWith(
                          container: format,
                          codec: VideoCodec.h264,
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.t('desc_${widget.encodingOptions.container.name}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ),

          // Target FPS
          _buildFpsSelector(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String title,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha(200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool>? onSelected,
    double fontSize = 12,
    bool isEnabled = true,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chip = ChoiceChip(
      showCheckmark: false,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: isDark
          ? theme.colorScheme.surfaceContainerHighest.withAlpha(40)
          : theme.colorScheme.surface,
      side: BorderSide(
        color: !isEnabled
            ? theme.colorScheme.outline.withAlpha(40)
            : (isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline),
        width: isSelected ? 1.2 : 1.0,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: !isEnabled
              ? theme.colorScheme.onSurface.withAlpha(80)
              : (isSelected ? Colors.white : theme.colorScheme.onSurface),
        ),
      ),
      selected: isEnabled && isSelected,
      onSelected: isEnabled ? onSelected : null,
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(
        message: tooltip,
        triggerMode: TooltipTriggerMode.tap,
        child: chip,
      );
    }
    return chip;
  }

  Widget _buildResolutionTile({
    required VideoResolution res,
    required bool isSelected,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected
            ? (isDark
                  ? theme.colorScheme.primary.withAlpha(45)
                  : theme.colorScheme.primary.withAlpha(25))
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => widget.onResolutionChanged(res),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withAlpha(80),
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.label.startsWith('Original')
                            ? (res.label.contains('(')
                                  ? '${widget.l10n.t('res_original')} (${res.label.substring(res.label.indexOf('(') + 1)}'
                                  : widget.l10n.t('res_original'))
                            : res.label,
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
                      Builder(
                        builder: (context) {
                          final isPortrait =
                              widget.sourceVideo.height >
                              widget.sourceVideo.width;
                          final displayW =
                              isPortrait && !res.label.startsWith('Original')
                              ? res.height
                              : res.width;
                          final displayH =
                              isPortrait && !res.label.startsWith('Original')
                              ? res.width
                              : res.height;
                          return Text(
                            '$displayW × $displayH',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? (isDark
                                        ? Colors.white.withAlpha(190)
                                        : theme.colorScheme.primary.withAlpha(
                                            200,
                                          ))
                                  : theme.colorScheme.onSurface.withAlpha(120),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _buildQualityBadge(res, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFpsSelector(ThemeData theme, AppLocalizations l10n) {
    final sourceFps = (widget.sourceVideo.fps > 0
        ? widget.sourceVideo.fps.round()
        : 60);
    final maxFps = sourceFps.clamp(15, 120);
    final minFps = (10 < maxFps) ? 10 : 1;
    final targetFps = widget.encodingOptions.targetFps;
    final tooltipExceeds = l10n.t(
      'fps_exceeds_source',
      args: {'fps': '$sourceFps'},
    );
    const standardFpsOptions = [60, 50, 48, 30, 25, 24];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(height: 1, color: theme.dividerColor),
        const SizedBox(height: 16),
        _buildSectionLabel(
          icon: Icons.speed_outlined,
          title: l10n.t('target_fps'),
          theme: theme,
        ),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildChoiceChip(
                label: l10n.t('fps_original'),
                isSelected: !_isCustomFps && targetFps == 0,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _isCustomFps = false;
                    });
                    widget.onOptionsChanged(
                      widget.encodingOptions.copyWith(targetFps: 0),
                    );
                  }
                },
              ),
              ...standardFpsOptions.map((fps) {
                final isAllowed = fps <= maxFps;
                return _buildChoiceChip(
                  label: '$fps FPS',
                  isSelected: !_isCustomFps && targetFps == fps,
                  isEnabled: isAllowed,
                  tooltip: isAllowed ? null : tooltipExceeds,
                  onSelected: (val) {
                    if (val && isAllowed) {
                      setState(() {
                        _isCustomFps = false;
                      });
                      widget.onOptionsChanged(
                        widget.encodingOptions.copyWith(targetFps: fps),
                      );
                    }
                  },
                );
              }),
              _buildChoiceChip(
                label: l10n.t('fps_custom'),
                isSelected: _isCustomFps,
                onSelected: (val) {
                  if (val) {
                    final initialCustom = (targetFps > 0 ? targetFps : maxFps)
                        .clamp(minFps, maxFps);
                    setState(() {
                      _isCustomFps = true;
                      _customFps = initialCustom;
                    });
                    widget.onOptionsChanged(
                      widget.encodingOptions.copyWith(targetFps: initialCustom),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        // Custom FPS slider
        if (_isCustomFps) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                theme.brightness == Brightness.dark ? 40 : 60,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(35),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.t('fps_custom')}: $_customFps FPS',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${l10n.t('fps_max')}: $maxFps FPS',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: _customFps.toDouble().clamp(
                      minFps.toDouble(),
                      maxFps.toDouble(),
                    ),
                    min: minFps.toDouble(),
                    max: maxFps.toDouble(),
                    divisions: (maxFps - minFps) > 0 ? (maxFps - minFps) : 1,
                    label: '$_customFps FPS',
                    onChanged: (val) {
                      final newFps = val.round();
                      if (newFps != _customFps) {
                        setState(() {
                          _customFps = newFps;
                        });
                        widget.onOptionsChanged(
                          widget.encodingOptions.copyWith(targetFps: newFps),
                        );
                      }
                    },
                    onChangeEnd: (val) {
                      final newFps = val.round();
                      widget.onOptionsChanged(
                        widget.encodingOptions.copyWith(targetFps: newFps),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),
        Center(
          child: Text(
            _getFpsDescription(targetFps, _isCustomFps, l10n),
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

  String _getFpsDescription(
    int targetFps,
    bool isCustomFps,
    AppLocalizations l10n,
  ) {
    if (isCustomFps) return l10n.t('fps_desc_custom');
    switch (targetFps) {
      case 0:
        return l10n.t('fps_desc_original');
      case 60:
        return l10n.t('fps_desc_60');
      case 50:
        return l10n.t('fps_desc_50');
      case 48:
        return l10n.t('fps_desc_48');
      case 30:
        return l10n.t('fps_desc_30');
      case 25:
        return l10n.t('fps_desc_25');
      case 24:
        return l10n.t('fps_desc_24');
      default:
        return l10n.t('fps_desc_custom');
    }
  }

  Widget _buildSizeEstimator(ThemeData theme) {
    double sizeMb = 0.0;
    final durationSecs = widget.sourceVideo.durationSeconds;

    if (durationSecs > 0) {
      final targetW =
          widget.selectedResolution?.width ?? widget.sourceVideo.width;
      final targetH =
          widget.selectedResolution?.height ?? widget.sourceVideo.height;

      final targetBitrateKbps = widget.encodingOptions
          .calculateTargetBitrateKbps(
            targetWidth: targetW,
            targetHeight: targetH,
            sourceWidth: widget.sourceVideo.width,
            sourceHeight: widget.sourceVideo.height,
            sourceBitrateBps: widget.sourceVideo.bitrate,
          );

      final totalBitrateKbps = targetBitrateKbps + 128;
      sizeMb = (totalBitrateKbps * 1000.0 / 8.0) * durationSecs / (1024 * 1024);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.data_usage_rounded,
            size: 17,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.l10n.t('est_size_title'),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
          Text(
            '~${sizeMb.toStringAsFixed(1)} MB',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBadge(VideoResolution res, ThemeData theme) {
    final dim = res.width < res.height ? res.width : res.height;
    String label;
    if (dim >= 2160) {
      label = '4K';
    } else if (dim >= 1440) {
      label = '2K';
    } else if (dim >= 1080) {
      label = 'FHD';
    } else if (dim >= 720) {
      label = 'HD';
    } else {
      label = 'SD';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withAlpha(180),
        ),
      ),
    );
  }

  Widget _buildActivePresetIndicator(ThemeData theme, AppLocalizations l10n) {
    final appSettings = SettingsService().settings;
    final isCustomPreset = appSettings.isAdvancedSettingsEnabled &&
        (appSettings.customPreset != 'default' ||
            appSettings.customScaler != 'default');

    final preset = widget.encodingOptions.speedPreset;
    final presetLabel = isCustomPreset
        ? l10n.t('preset_custom_title')
        : (preset == SpeedPreset.fast
            ? l10n.t('preset_fast_title')
            : (preset == SpeedPreset.max
                ? l10n.t('preset_slow_title')
                : l10n.t('preset_normal_title')));

    final presetDesc = preset == SpeedPreset.fast
        ? l10n.t('preset_fast_desc')
        : (preset == SpeedPreset.max
            ? l10n.t('preset_slow_desc')
            : l10n.t('preset_normal_desc'));

    final effectivePreset = appSettings.customPreset != 'default'
        ? appSettings.customPreset
        : preset.x264Preset;
    final effectiveScaler = appSettings.customScaler != 'default'
        ? appSettings.customScaler
        : preset.scaler;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(50),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isCustomPreset ? Icons.tune_rounded : Icons.speed_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    text: '${l10n.t('settings_cpu_preset')}: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                    children: [
                      TextSpan(
                        text: presetLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCustomPreset) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildPresetChoiceBadge(
                        theme: theme,
                        icon: Icons.speed_rounded,
                        label:
                            'Preset: ${appSettings.customPreset == 'default' ? "${l10n.t('preset_default')} ($effectivePreset)" : appSettings.customPreset}',
                      ),
                      _buildPresetChoiceBadge(
                        theme: theme,
                        icon: Icons.photo_size_select_large_rounded,
                        label:
                            'Scaler: ${appSettings.customScaler == 'default' ? "${l10n.t('scaler_default')} ($effectiveScaler)" : appSettings.customScaler}',
                      ),
                      if (appSettings.enableHardwareAcceleration)
                        _buildPresetChoiceBadge(
                          theme: theme,
                          icon: Icons.bolt_rounded,
                          label: 'MediaCodec (HW)',
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${appSettings.enableHardwareAcceleration ? "MediaCodec HW" : "x264 $effectivePreset"} • Scaler $effectiveScaler',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 3),
                  Text(
                    presetDesc,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChoiceBadge({
    required ThemeData theme,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(60),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
