import 'package:flutter/material.dart';

import '../models/video_info.dart';
import '../services/settings_service.dart';

class ResolutionSelector extends StatelessWidget {
  final List<VideoResolution> resolutions;
  final VideoResolution? selected;
  final ValueChanged<VideoResolution> onSelected;

  const ResolutionSelector({
    super.key,
    required this.resolutions,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = SettingsService().l10n;

    if (resolutions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 40,
                  color: Colors.white24,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('no_downscale_options'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.t('target_resolution'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...resolutions.map((res) => _ResolutionOption(
              resolution: res,
              isSelected: selected?.label == res.label,
              onTap: () => onSelected(res),
            )),
          ],
        ),
      ),
    );
  }
}

class _ResolutionOption extends StatelessWidget {
  final VideoResolution resolution;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResolutionOption({
    required this.resolution,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(25)
            : const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
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
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolution.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.white,
                        ),
                      ),
                      Text(
                        '${resolution.width} x ${resolution.height}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? theme.colorScheme.primary.withAlpha(180)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQualityBadge(resolution),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityBadge(VideoResolution res) {
    String label;
    Color color;
    if (res.height >= 1080) {
      label = 'HD';
      color = const Color(0xFF54A0FF);
    } else if (res.height >= 720) {
      label = 'HD';
      color = const Color(0xFF5CD85A);
    } else {
      label = 'SD';
      color = const Color(0xFFFF9F43);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
