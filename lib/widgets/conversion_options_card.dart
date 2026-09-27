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
    if (widget.encodingOptions.customBitrateKbps != null) {
      _customBitrateMbps = (widget.encodingOptions.customBitrateKbps! / 1000).round().clamp(1, 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;

    // Calculate estimated bitrate for current selection
    final targetW = widget.selectedResolution?.width ?? widget.sourceVideo.width;
    final targetH = widget.selectedResolution?.height ?? widget.sourceVideo.height;
    final estimatedBitrateKbps = widget.encodingOptions.calculateTargetBitrateKbps(
      targetWidth: targetW,
      targetHeight: targetH,
      sourceWidth: widget.sourceVideo.width,
      sourceHeight: widget.sourceVideo.height,
      sourceBitrateBps: widget.sourceVideo.bitrate,
    );

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

            // 2. Bitrate Selection
            _buildSubHeader(
              icon: Icons.speed_rounded,
              title: l10n.t('bitrate_setting'),
              theme: theme,
              trailingBadge: '${estimatedBitrateKbps >= 1000 ? (estimatedBitrateKbps / 1000).toStringAsFixed(1) : estimatedBitrateKbps} ${estimatedBitrateKbps >= 1000 ? 'Mbps' : 'Kbps'}',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBitrateChip(
                  label: l10n.t('bitrate_auto'),
                  preset: BitratePreset.auto,
                  theme: theme,
                ),
                _buildBitrateChip(
                  label: l10n.t('bitrate_high'),
                  preset: BitratePreset.high,
                  theme: theme,
                ),
                _buildBitrateChip(
                  label: l10n.t('bitrate_medium'),
                  preset: BitratePreset.medium,
                  theme: theme,
                ),
                _buildBitrateChip(
                  label: l10n.t('bitrate_low'),
                  preset: BitratePreset.low,
                  theme: theme,
                ),
                _buildBitrateChip(
                  label: l10n.t('bitrate_custom', args: {'value': (_customBitrateMbps * 1000).toString()}),
                  preset: BitratePreset.custom,
                  theme: theme,
                ),
              ],
            ),
            if (widget.encodingOptions.bitratePreset == BitratePreset.custom) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _customBitrateMbps.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
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
                      color: const Color(0xFF2A2A3E),
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
            const SizedBox(height: 6),
            Text(
              widget.encodingOptions.codec.description,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
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
            : const Color(0xFF2A2A3E),
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
                          : Colors.white30,
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
                          color: isSelected ? theme.colorScheme.primary : Colors.white,
                        ),
                      ),
                      Text(
                        '${res.width} x ${res.height}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? theme.colorScheme.primary.withAlpha(180)
                              : Colors.white38,
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

  Widget _buildBitrateChip({
    required String label,
    required BitratePreset preset,
    required ThemeData theme,
  }) {
    final isSelected = widget.encodingOptions.bitratePreset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          widget.onOptionsChanged(
            widget.encodingOptions.copyWith(
              bitratePreset: preset,
              customBitrateKbps: preset == BitratePreset.custom ? (_customBitrateMbps * 1000) : null,
            ),
          );
        }
      },
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
