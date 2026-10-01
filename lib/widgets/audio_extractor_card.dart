import 'package:flutter/material.dart';

import '../models/encoding_options.dart';
import '../models/video_info.dart';
import '../services/localization_service.dart';

class AudioExtractorCard extends StatelessWidget {
  final VideoInfo sourceVideo;
  final EncodingOptions encodingOptions;
  final ValueChanged<EncodingOptions> onOptionsChanged;
  final AppLocalizations l10n;

  const AudioExtractorCard({
    super.key,
    required this.sourceVideo,
    required this.encodingOptions,
    required this.onOptionsChanged,
    required this.l10n,
  });

  String _formatEstimatedSize() {
    final durationSec = sourceVideo.durationSeconds;
    if (durationSec <= 0) return '~';

    int bitrateKbps = encodingOptions.audioExtractBitrateKbps;
    if (bitrateKbps <= 0) {
      // Stream copy: approximate with 160 kbps if source bitrate unknown
      bitrateKbps = 160;
    }

    final estimatedBytes = (durationSec * (bitrateKbps * 1024 / 8)).round();
    final mb = estimatedBytes / (1024 * 1024);
    if (mb < 1) {
      final kb = (estimatedBytes / 1024).round();
      return '$kb KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _getAudioFormatDescription(AudioFormat format, AppLocalizations l10n) {
    switch (format) {
      case AudioFormat.mp3:
        return l10n.t('desc_audio_mp3');
      case AudioFormat.m4a:
        return l10n.t('desc_audio_m4a');
      case AudioFormat.wav:
        return l10n.t('desc_audio_wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Icons.audiotrack_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.t('audio_options'),
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

            if (!sourceVideo.hasAudio) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_off_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.t('no_audio_track'),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Audio Format Selection
            Row(
              children: [
                Icon(
                  Icons.album_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.t('audio_format'),
                  style: TextStyle(
                    fontSize: 13,
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
                runSpacing: 8,
                children: AudioFormat.values.map((fmt) {
                  final isSelected = encodingOptions.audioFormat == fmt;
                  return ChoiceChip(
                    showCheckmark: false,
                    label: Text(fmt.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onOptionsChanged(
                          encodingOptions.copyWith(audioFormat: fmt),
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
                _getAudioFormatDescription(encodingOptions.audioFormat, l10n),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 16),

            // 2. Audio Bitrate / Quality Selection (only if not WAV)
            if (encodingOptions.audioFormat != AudioFormat.wav) ...[
              Row(
                children: [
                  Icon(
                    Icons.speed_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.t('audio_bitrate'),
                    style: TextStyle(
                      fontSize: 13,
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
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text(l10n.t('audio_copy')),
                      selected: encodingOptions.audioExtractBitrateKbps == 0,
                      onSelected: (selected) {
                        if (selected) {
                          onOptionsChanged(
                            encodingOptions.copyWith(audioExtractBitrateKbps: 0),
                          );
                        }
                      },
                    ),
                    ...[128, 192, 256, 320].map((kbps) {
                      final isSelected =
                          encodingOptions.audioExtractBitrateKbps == kbps;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text('$kbps kbps'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            onOptionsChanged(
                              encodingOptions.copyWith(
                                  audioExtractBitrateKbps: kbps),
                            );
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: theme.dividerColor),
              const SizedBox(height: 16),
            ],

            // 3. Estimated Output Size
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.t('est_size_title'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    _formatEstimatedSize(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
