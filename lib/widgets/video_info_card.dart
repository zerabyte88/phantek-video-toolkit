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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.video_file_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        videoInfo.fileName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getResolutionColor(videoInfo.height).withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          videoInfo.resolution,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getResolutionColor(videoInfo.height),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoGrid(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(AppLocalizations l10n) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _InfoTile(
          icon: Icons.aspect_ratio_rounded,
          label: l10n.t('resolution'),
          value: '${videoInfo.width}x${videoInfo.height}',
        ),
        _InfoTile(
          icon: Icons.timer_rounded,
          label: l10n.t('duration'),
          value: videoInfo.formattedDuration,
        ),
        _InfoTile(
          icon: Icons.speed_rounded,
          label: l10n.t('bitrate'),
          value: videoInfo.formattedBitrate,
        ),
        _InfoTile(
          icon: Icons.storage_rounded,
          label: l10n.t('file_size'),
          value: videoInfo.formattedFileSize,
        ),
        _InfoTile(
          icon: Icons.slow_motion_video_rounded,
          label: l10n.t('fps'),
          value: '${videoInfo.fps.toStringAsFixed(1)} fps',
        ),
        _InfoTile(
          icon: Icons.code_rounded,
          label: l10n.t('codec'),
          value: videoInfo.codec.toUpperCase(),
        ),
      ],
    );
  }

  Color _getResolutionColor(int height) {
    if (height >= 2160) return const Color(0xFFFF6B6B);
    if (height >= 1440) return const Color(0xFFFF9F43);
    if (height >= 1080) return const Color(0xFF54A0FF);
    return const Color(0xFF5CD85A);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
