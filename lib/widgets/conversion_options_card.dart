import 'package:flutter/material.dart';

import '../models/encoding_options.dart';
import '../models/video_info.dart';
import '../services/localization_service.dart';

class ConversionOptionsCard extends StatefulWidget {
  final VideoInfo sourceVideo;
  final List<VideoResolution> resolutions;
  final VideoResolution? selectedResolution;
  final EncodingOptions encodingOptions;
  final bool showCodecSelection;
  final ValueChanged<VideoResolution> onResolutionChanged;
  final ValueChanged<EncodingOptions> onOptionsChanged;
  final AppLocalizations l10n;

  const ConversionOptionsCard({
    super.key,
    required this.sourceVideo,
    required this.resolutions,
    required this.selectedResolution,
    required this.encodingOptions,
    this.showCodecSelection = true,
    required this.onResolutionChanged,
    required this.onOptionsChanged,
    required this.l10n,
  });

  @override
  State<ConversionOptionsCard> createState() => _ConversionOptionsCardState();
}

class _ConversionOptionsCardState extends State<ConversionOptionsCard> {
  int _customBitrateMbps = 4;
  bool _isCustomFps = false;
  late int _customFps;

  @override
  void initState() {
    super.initState();
    _customBitrateMbps = (widget.encodingOptions.customBitrateKbps / 1000)
        .round()
        .clamp(1, 30);
    final sourceFps = (widget.sourceVideo.fps > 0 ? widget.sourceVideo.fps.round() : 60);
    final maxFps = sourceFps.clamp(15, 120);
    final currentFps = widget.encodingOptions.targetFps;
    if (currentFps > 0 && currentFps != 24 && currentFps != 30 && currentFps != 60) {
      _isCustomFps = true;
      _customFps = currentFps.clamp(10, maxFps);
    } else {
      _isCustomFps = false;
      _customFps = (currentFps > 0 ? currentFps : maxFps).clamp(10, maxFps);
    }
  }

  @override
  void didUpdateWidget(ConversionOptionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceVideo != widget.sourceVideo) {
      final sourceFps = (widget.sourceVideo.fps > 0 ? widget.sourceVideo.fps.round() : 60);
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                Text(
                  l10n.t('video_options'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. Resolution Selection
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

            // 2. Rate Control Selection (CRF vs Bitrate)
            _buildSectionLabel(
              icon: Icons.speed_rounded,
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
                  final isSelected =
                      widget.encodingOptions.rateControlMode == mode;
                  return _buildChoiceChip(
                    label: mode.displayName,
                    isSelected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        widget.onOptionsChanged(
                          widget.encodingOptions.copyWith(
                            rateControlMode: mode,
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.encodingOptions.rateControlMode ==
                              RateControlMode.crf
                          ? l10n.t('desc_crf')
                          : l10n.t('desc_bitrate'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(160),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.encodingOptions.rateControlMode ==
                RateControlMode.crf) ...[
              Text(
                l10n.t('crf_label'),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(140),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: widget.encodingOptions.crfValue.toDouble(),
                      min: 16,
                      max: 28,
                      divisions: 12,
                      label: widget.encodingOptions.crfValue.toString(),
                      onChanged: (val) {
                        widget.onOptionsChanged(
                          widget.encodingOptions.copyWith(
                            crfValue: val.round(),
                          ),
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
                      '${widget.encodingOptions.crfValue}',
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
            ] else ...[
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
                        setState(() {
                          _customBitrateMbps = val.round();
                        });
                        widget.onOptionsChanged(
                          widget.encodingOptions.copyWith(
                            customBitrateKbps: _customBitrateMbps * 1000,
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

            // Estimated Size display
            const SizedBox(height: 12),
            _buildSizeEstimator(theme),

            const SizedBox(height: 16),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 16),

            // 3. Format / Container Selection
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
                        VideoCodec newCodec = widget.encodingOptions.codec;
                        if (!widget.showCodecSelection) {
                          newCodec = VideoCodec.h264;
                        }
                        widget.onOptionsChanged(
                          widget.encodingOptions.copyWith(
                            container: format,
                            codec: newCodec,
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.t('desc_${widget.encodingOptions.container.name}'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(160),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.showCodecSelection) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: theme.dividerColor),
              const SizedBox(height: 16),

              // 4. Codec Selection
              _buildSectionLabel(
                icon: Icons.code_rounded,
                title: l10n.t('video_codec'),
                theme: theme,
              ),
              const SizedBox(height: 10),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: VideoCodec.values.map((codec) {
                    final isSelected = widget.encodingOptions.codec == codec;
                    return _buildChoiceChip(
                      label: codec.displayName,
                      isSelected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          widget.onOptionsChanged(
                            widget.encodingOptions.copyWith(codec: codec),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                    80,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.t('desc_${widget.encodingOptions.codec.name}'),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(160),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.encodingOptions.codec == VideoCodec.hevc) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withAlpha(110),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.t('codec_hevc_warning'),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface.withAlpha(220),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // 5. FPS Selector
            _buildFpsSelector(theme, l10n),
          ],
        ),
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
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withAlpha(200),
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
  }) {
    final theme = Theme.of(context);
    return ChoiceChip(
      showCheckmark: false,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
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
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
    );
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
                      Text(
                        '${res.width} × ${res.height}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? (isDark
                                    ? Colors.white.withAlpha(190)
                                    : theme.colorScheme.primary.withAlpha(200))
                              : theme.colorScheme.onSurface.withAlpha(120),
                        ),
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
    final sourceFps = (widget.sourceVideo.fps > 0 ? widget.sourceVideo.fps.round() : 60);
    final maxFps = sourceFps.clamp(15, 120);
    final minFps = (10 < maxFps) ? 10 : 1;
    final targetFps = widget.encodingOptions.targetFps;

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
              if (maxFps >= 50)
                _buildChoiceChip(
                  label: '60 FPS',
                  isSelected: !_isCustomFps && targetFps == 60,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _isCustomFps = false;
                      });
                      widget.onOptionsChanged(
                        widget.encodingOptions.copyWith(targetFps: 60),
                      );
                    }
                  },
                ),
              if (maxFps >= 30)
                _buildChoiceChip(
                  label: '30 FPS',
                  isSelected: !_isCustomFps && targetFps == 30,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _isCustomFps = false;
                      });
                      widget.onOptionsChanged(
                        widget.encodingOptions.copyWith(targetFps: 30),
                      );
                    }
                  },
                ),
              _buildChoiceChip(
                label: '24 FPS',
                isSelected: !_isCustomFps && targetFps == 24,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _isCustomFps = false;
                    });
                    widget.onOptionsChanged(
                      widget.encodingOptions.copyWith(targetFps: 24),
                    );
                  }
                },
              ),
              _buildChoiceChip(
                label: l10n.t('fps_custom'),
                isSelected: _isCustomFps,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _isCustomFps = true;
                      if (_customFps > maxFps) _customFps = maxFps;
                    });
                    widget.onOptionsChanged(
                      widget.encodingOptions.copyWith(targetFps: _customFps),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        // Custom Slider Section (Shown when Custom is selected)
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
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _customFps.toDouble().clamp(minFps.toDouble(), maxFps.toDouble()),
                    min: minFps.toDouble(),
                    max: maxFps.toDouble(),
                    divisions: (maxFps - minFps) > 0 ? (maxFps - minFps) : 1,
                    label: '$_customFps FPS',
                    onChanged: (val) {
                      final newFps = val.round();
                      setState(() {
                        _customFps = newFps;
                      });
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

        // Explanations Card (Strictly without emojis)
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(
              theme.brightness == Brightness.dark ? 30 : 50,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dividerColor.withAlpha(40),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.t('fps_info_title'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildFpsInfoRow(
                theme: theme,
                title: l10n.t('fps_original'),
                desc: l10n.t('fps_desc_original'),
                isActive: !_isCustomFps && targetFps == 0,
              ),
              if (maxFps >= 50) ...[
                const SizedBox(height: 6),
                _buildFpsInfoRow(
                  theme: theme,
                  title: '60 FPS',
                  desc: l10n.t('fps_desc_60'),
                  isActive: !_isCustomFps && targetFps == 60,
                ),
              ],
              if (maxFps >= 30) ...[
                const SizedBox(height: 6),
                _buildFpsInfoRow(
                  theme: theme,
                  title: '30 FPS',
                  desc: l10n.t('fps_desc_30'),
                  isActive: !_isCustomFps && targetFps == 30,
                ),
              ],
              const SizedBox(height: 6),
              _buildFpsInfoRow(
                theme: theme,
                title: '24 FPS',
                desc: l10n.t('fps_desc_24'),
                isActive: !_isCustomFps && targetFps == 24,
              ),
              const SizedBox(height: 6),
              _buildFpsInfoRow(
                theme: theme,
                title: l10n.t('fps_custom'),
                desc: l10n.t('fps_desc_custom'),
                isActive: _isCustomFps,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFpsInfoRow({
    required ThemeData theme,
    required String title,
    required String desc,
    required bool isActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withAlpha(200),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            desc,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: theme.colorScheme.onSurface.withAlpha(isActive ? 220 : 150),
            ),
          ),
        ),
      ],
    );
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
}
