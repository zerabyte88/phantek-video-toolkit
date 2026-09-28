import 'dart:math' as math;
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
                Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.t('video_options'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

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
              title: 'Opsi Video & Kompresi', // Hardcoded temporarily, or add to l10n
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
                      widget.encodingOptions.rateControlMode.description,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(200)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.encodingOptions.rateControlMode == RateControlMode.crf) ...[
              Text(
                'CRF Value (Lebih kecil = Kualitas lebih baik, Ukuran lebih besar)',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(160)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? (theme.scaffoldBackgroundColor == Colors.black ? const Color(0xFF14141C) : const Color(0xFF2A2A3E))
                          : const Color(0xFFEAEBF2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.encodingOptions.crfValue}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Target Bitrate (Mbps)',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(160)),
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
                    width: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? (theme.scaffoldBackgroundColor == Colors.black ? const Color(0xFF14141C) : const Color(0xFF2A2A3E))
                          : const Color(0xFFEAEBF2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_customBitrateMbps Mbps',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
            const SizedBox(height: 6),
            Text(
              widget.encodingOptions.codec.description,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
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
        Icon(icon, size: 17, color: theme.colorScheme.primary.withAlpha(200)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        if (trailingBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trailingBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
    // Size = Bitrate * Duration
    double sizeMb = 0.0;
    final durationSecs = widget.sourceVideo.durationSeconds;

    if (widget.encodingOptions.rateControlMode == RateControlMode.bitrate) {
      sizeMb = (_customBitrateMbps * 1000000.0 / 8.0) * durationSecs / (1024 * 1024);
    } else {
      // Rough heuristic for CRF
      final crf = widget.encodingOptions.crfValue;
      final targetH = widget.selectedResolution?.height ?? widget.sourceVideo.height;
      // Assume a base bitrate for CRF 20 at 1080p is ~4Mbps.
      // Every +6 CRF roughly halves the bitrate.
      double baseMbps = 4.0;
      if (targetH <= 720) baseMbps = 2.0;
      if (targetH <= 480) baseMbps = 1.0;
      
      final diff = crf - 20;
      final factor = diff / 6.0;
      // formula: 0.5^factor
      double estimatedBitrate = baseMbps * math.pow(0.5, factor);
      sizeMb = (estimatedBitrate * 1000000.0 / 8.0) * durationSecs / (1024 * 1024);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sd_storage_rounded, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimasi Ukuran Output:',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                ),
              ),
              Text(
                '~${sizeMb.toStringAsFixed(1)} MB',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (widget.encodingOptions.rateControlMode == RateControlMode.crf) ...[
            const SizedBox(height: 4),
            Text(
              '* Ukuran asli dapat sangat bervariasi bergantung kerumitan visual video.',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withAlpha(120),
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
