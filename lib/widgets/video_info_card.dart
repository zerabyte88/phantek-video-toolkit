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
    final resColor = _getResolutionColor(videoInfo.height);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + filename + resolution badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.video_file_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        videoInfo.fileName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _ResolutionBadge(label: videoInfo.resolution, color: resColor),
                          const SizedBox(width: 6),
                          _ResolutionBadge(
                            label: videoInfo.codec.toUpperCase(),
                            color: theme.colorScheme.secondary,
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

            // Info grid — 3 per row, evenly spaced
            _buildInfoGrid(l10n, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(AppLocalizations l10n, ThemeData theme) {
    final items = [
      _InfoItem(
        icon: Icons.aspect_ratio_rounded,
        label: l10n.t('resolution'),
        value: '${videoInfo.width}x${videoInfo.height}',
        iconColor: const Color(0xFF54A0FF),
      ),
      _InfoItem(
        icon: Icons.timer_rounded,
        label: l10n.t('duration'),
        value: videoInfo.formattedDuration,
        iconColor: const Color(0xFF5CD85A),
      ),
      _InfoItem(
        icon: Icons.slow_motion_video_rounded,
        label: l10n.t('fps'),
        value: '${videoInfo.fps.toStringAsFixed(1)} fps',
        iconColor: const Color(0xFFFF9F43),
      ),
      _InfoItem(
        icon: Icons.speed_rounded,
        label: l10n.t('bitrate'),
        value: videoInfo.formattedBitrate,
        iconColor: const Color(0xFFFF6B6B),
      ),
      _InfoItem(
        icon: Icons.storage_rounded,
        label: l10n.t('file_size'),
        value: videoInfo.formattedFileSize,
        iconColor: const Color(0xFFA29BFE),
      ),
    ];

    // Lay out in rows of 3
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 3) {
      final rowItems = items.skip(i).take(3).toList();
      rows.add(
        Row(
          children: List.generate(3, (j) {
            if (j < rowItems.length) {
              return Expanded(child: _InfoTile(item: rowItems[j], theme: theme));
            }
            return const Expanded(child: SizedBox());
          }),
        ),
      );
      if (i + 3 < items.length) rows.add(const SizedBox(height: 12));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Color _getResolutionColor(int height) {
    if (height >= 2160) return const Color(0xFFFF6B6B);
    if (height >= 1440) return const Color(0xFFFF9F43);
    if (height >= 1080) return const Color(0xFF54A0FF);
    return const Color(0xFF5CD85A);
  }
}

class _ResolutionBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ResolutionBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;
  final ThemeData theme;
  const _InfoTile({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(item.icon, size: 14, color: item.iconColor),
            const SizedBox(width: 5),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withAlpha(120),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          item.value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
