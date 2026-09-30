import 'package:flutter/material.dart';

import '../models/encoding_options.dart';
import '../models/video_info.dart';
import '../services/localization_service.dart';

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
  int _customBitrateMbps = 4;

  @override
  void initState() {
    super.initState();
    _customBitrateMbps = (widget.encodingOptions.customBitrateKbps / 1000).round().clamp(1, 30);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.t('video_options'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Resolution Selection
            _buildSubHeader(
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

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // 2. Rate Control Selection (CRF vs Bitrate)
            _buildSubHeader(
              icon: Icons.speed_rounded,
              title: l10n.t('video_options'),
              theme: theme,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RateControlMode.values.map((mode) {
                final isSelected = widget.encodingOptions.rateControlMode == mode;
                return ChoiceChip(
                  label: Text(mode.displayName),
                  selected: isSelected,
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.dividerColor.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.encodingOptions.rateControlMode == RateControlMode.crf 
                          ? l10n.t('desc_crf') 
                          : l10n.t('desc_bitrate'),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(200)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.encodingOptions.rateControlMode == RateControlMode.crf) ...[
              Text(
                l10n.t('crf_label'),
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(140)),
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
                    width: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
                    ),
                    child: Text(
                      '${widget.encodingOptions.crfValue}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                l10n.t('bitrate_label'),
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(140)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
                    ),
                    child: Text(
                      '$_customBitrateMbps Mbps',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // 3. Format / Container Selection
            _buildSubHeader(
              icon: Icons.folder_zip_rounded,
              title: l10n.t('container_format'),
              theme: theme,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VideoContainer.values.map((format) {
                final isSelected = widget.encodingOptions.container == format;
                return ChoiceChip(
                  label: Text('${format.displayName} (.${format.extension})'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      // Smart codec adaptation
                      VideoCodec newCodec = widget.encodingOptions.codec;
                      if (format == VideoContainer.webm) {
                        newCodec = VideoCodec.vp9;
                      } else if (format == VideoContainer.mp4 && newCodec == VideoCodec.vp9) {
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.dividerColor.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.encodingOptions.container.description,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(200)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // 4. Codec Selection
            _buildSubHeader(
              icon: Icons.code_rounded,
              title: l10n.t('video_codec'),
              theme: theme,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VideoCodec.values.map((codec) {
                // If WebM, only VP9 is recommended
                final isCompatible = widget.encodingOptions.container != VideoContainer.webm || codec == VideoCodec.vp9;
                final isSelected = widget.encodingOptions.codec == codec;
                return ChoiceChip(
                  label: Text(codec.displayName),
                  selected: isSelected,
                  avatar: codec == VideoCodec.hevc
                      ? const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFF9F43))
                      : null,
                  onSelected: isCompatible
                      ? (selected) {
                          if (selected) {
                            widget.onOptionsChanged(
                              widget.encodingOptions.copyWith(codec: codec),
                            );
                          }
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.dividerColor.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.encodingOptions.codec.description,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(200)),
                    ),
                  ),
                ],
              ),
            ),
            _buildFpsSelector(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader({
    required IconData icon,
    required String title,
    required ThemeData theme,
    String? trailingBadge,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary.withAlpha(220)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withAlpha(180),
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (trailingBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
            ),
            child: Text(
              trailingBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResolutionTile({
    required VideoResolution res,
    required bool isSelected,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(25)
            : (theme.brightness == Brightness.dark
                ? (theme.scaffoldBackgroundColor == Colors.black ? const Color(0xFF14141C) : const Color(0xFF2A2A3E))
                : const Color(0xFFEAEBF2)),
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
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withAlpha(60),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${res.width} x ${res.height}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? theme.colorScheme.primary.withAlpha(180)
                              : theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQualityBadge(res),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFpsSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildSubHeader(
          icon: Icons.shutter_speed_rounded,
          title: 'Target FPS',
          theme: theme,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Original'),
              selected: widget.encodingOptions.targetFps == 0,
              onSelected: (val) {
                if (val) widget.onOptionsChanged(widget.encodingOptions.copyWith(targetFps: 0));
              },
            ),
            ChoiceChip(
              label: const Text('30 FPS'),
              selected: widget.encodingOptions.targetFps == 30,
              onSelected: (val) {
                if (val) widget.onOptionsChanged(widget.encodingOptions.copyWith(targetFps: 30));
              },
            ),
            ChoiceChip(
              label: const Text('24 FPS'),
              selected: widget.encodingOptions.targetFps == 24,
              onSelected: (val) {
                if (val) widget.onOptionsChanged(widget.encodingOptions.copyWith(targetFps: 24));
              },
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSizeEstimator(ThemeData theme) {
    // Estimating output size
    // Size = (Video Bitrate + Audio Bitrate) * Duration
    double sizeMb = 0.0;
    final durationSecs = widget.sourceVideo.durationSeconds;

    if (durationSecs > 0) {
      final targetW = widget.selectedResolution?.width ?? widget.sourceVideo.width;
      final targetH = widget.selectedResolution?.height ?? widget.sourceVideo.height;

      final targetBitrateKbps = widget.encodingOptions.calculateTargetBitrateKbps(
        targetWidth: targetW,
        targetHeight: targetH,
        sourceWidth: widget.sourceVideo.width,
        sourceHeight: widget.sourceVideo.height,
        sourceBitrateBps: widget.sourceVideo.bitrate,
      );

      // Video bitrate + standard AAC audio bitrate (~128 kbps)
      final totalBitrateKbps = targetBitrateKbps + 128;
      sizeMb = (totalBitrateKbps * 1000.0 / 8.0) * durationSecs / (1024 * 1024);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sd_storage_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.l10n.t('est_size_title'),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '~${sizeMb.toStringAsFixed(1)} MB',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (widget.encodingOptions.rateControlMode == RateControlMode.crf) ...[
            const SizedBox(height: 6),
            Text(
              widget.l10n.t('est_size_warning'),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withAlpha(110),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQualityBadge(VideoResolution res) {
    String label;
    Color color;
    if (res.height >= 2160) {
      label = '4K';
      color = const Color(0xFFFF6B6B);
    } else if (res.height >= 1440) {
      label = '2K';
      color = const Color(0xFFFF9F43);
    } else if (res.height >= 1080) {
      label = 'FHD';
      color = const Color(0xFF54A0FF);
    } else if (res.height >= 720) {
      label = 'HD';
      color = const Color(0xFF5CD85A);
    } else {
      label = 'SD';
      color = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
