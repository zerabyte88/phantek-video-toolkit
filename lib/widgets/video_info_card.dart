import 'package:flutter/material.dart';

import '../models/video_info.dart';
import '../services/localization_service.dart';
import '../services/settings_service.dart';

class VideoInfoCard extends StatelessWidget {
  final VideoInfo videoInfo;

  const VideoInfoCard({super.key, required this.videoInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = SettingsService().l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Media icon + filename + badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.movie_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        videoInfo.fileName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _StatusBadge(
                            label: videoInfo.resolution,
                            color: theme.colorScheme.primary,
                          ),
                          _StatusBadge(
                            label: videoInfo.codec.toUpperCase(),
                            color: theme.colorScheme.secondary,
                          ),
                          _StatusBadge(
                            label: videoInfo.formattedFileSize,
                            color: theme.colorScheme.onSurface.withAlpha(180),
                            isNeutral: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 14),

            // Metadata spec grid: 4 columns or 2x2
            _buildSpecsGrid(l10n, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsGrid(AppLocalizations l10n, ThemeData theme) {
    final items = [
      _SpecItem(
        label: l10n.t('resolution'),
        value: '${videoInfo.width} × ${videoInfo.height}',
      ),
      _SpecItem(
        label: l10n.t('duration'),
        value: videoInfo.formattedDuration,
      ),
      _SpecItem(
        label: l10n.t('fps'),
        value: '${videoInfo.fps.toStringAsFixed(1)} fps',
      ),
      _SpecItem(
        label: l10n.t('bitrate'),
        value: videoInfo.formattedBitrate,
      ),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isNeutral;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.isNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isNeutral
        ? (theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
        : color.withAlpha(25);
    final fg = isNeutral ? theme.colorScheme.onSurface : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _SpecItem {
  final String label;
  final String value;
  const _SpecItem({required this.label, required this.value});
}
