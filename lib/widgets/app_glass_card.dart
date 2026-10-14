import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// Performance-optimized Glassmorphism / Translucent Card for Phantek.
///
/// Uses zero-cost GPU alpha tinting based on [cardOpacity] to guarantee
/// rock-solid 60–120 FPS performance without [BackdropFilter] or offscreen buffer overhead.
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final VoidCallback? onTap;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsService = SettingsService();
    final opacity = settingsService.settings.cardOpacity;
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);

    final effectiveBorder =
        border ??
        Border.all(
          color: theme.colorScheme.outline.withAlpha(isDark ? 35 : 55),
          width: 1.0,
        );

    final baseSurface = theme.colorScheme.surface;
    final surfaceColor = opacity < 1.0
        ? baseSurface.withAlpha(
            (255 * opacity.clamp(0.5, 1.0)).round().clamp(0, 255),
          )
        : baseSurface;

    final boxDecoration = BoxDecoration(
      color: surfaceColor,
      borderRadius: radius,
      border: effectiveBorder,
      boxShadow: (!isDark && opacity >= 0.95)
          ? [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );

    Widget cardBody = Container(
      padding: padding,
      decoration: boxDecoration,
      child: child,
    );

    if (onTap != null) {
      cardBody = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(onTap: onTap, borderRadius: radius, child: cardBody),
      );
    }

    // ── 60-120 FPS Optimization: Pure alpha compositing without GPU blur ────
    return Padding(padding: margin, child: cardBody);
  }
}
