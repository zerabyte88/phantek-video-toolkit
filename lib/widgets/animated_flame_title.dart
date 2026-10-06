import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// A sleek AppBar title widget wrapped in a dynamic animated border and themed icon
/// that matches the selected app theme (Dark, OLED, Light, AMOLED Sakura).
class AnimatedFlameTitle extends StatefulWidget {
  final String title;

  const AnimatedFlameTitle({super.key, this.title = 'Phantek'});

  @override
  State<AnimatedFlameTitle> createState() => _AnimatedFlameTitleState();
}

class _AnimatedFlameTitleState extends State<AnimatedFlameTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // 1. OLED AMOLED Plasma Flame
  static const _oledColors = [
    Color(0xFFFF1E00), // Deep Crimson Red
    Color(0xFFFF6A00), // Hot Blaze Orange
    Color(0xFFFFD000), // Fiery Gold
    Color(0xFFFF3B30), // Electric Coral
    Color(0xFFFF9500), // Bright Amber
    Color(0xFFFF1E00), // Back to Crimson
  ];

  // 2. Dark Slate Electric Cyber Cyan/Blue
  static const _darkColors = [
    Color(0xFF00E5FF), // Electric Cyan
    Color(0xFF00B0FF), // Sky Light Blue
    Color(0xFF2979FF), // Vivid Royal Blue
    Color(0xFF38BDF8), // Light Cyan
    Color(0xFF60A5FA), // Soft Blue
    Color(0xFF00E5FF), // Back to Cyan
  ];

  // 3. Light Mode Azure Breeze
  static const _lightColors = [
    Color(0xFF2563EB), // Cobalt Blue
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF38BDF8), // Light Cyan
    Color(0xFF6366F1), // Indigo
    Color(0xFF0EA5E9), // Ocean Blue
    Color(0xFF2563EB), // Back to Cobalt
  ];

  // 4. AMOLED Sakura Cherry Blossom
  static const _sakuraColors = [
    Color(0xFFFF69B4), // Hot Pink
    Color(0xFFFFB7C5), // Cherry Blossom
    Color(0xFFF472B6), // Pink 400
    Color(0xFFFDA4AF), // Rose 300
    Color(0xFFFF1493), // Deep Pink
    Color(0xFFFF69B4), // Back to Hot Pink
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsService = SettingsService();

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, settingsService]),
      builder: (context, child) {
        final mode = settingsService.settings.themeMode;
        final progress = _controller.value;

        List<Color> activeColors;
        IconData activeIcon;
        Color? iconColor;

        switch (mode) {
          case 'sakura':
          case 'oled_sakura':
            activeColors = _sakuraColors;
            activeIcon = Icons.local_florist_rounded;
            iconColor = Color.lerp(
              const Color(0xFFFF69B4),
              const Color(0xFFFFB7C5),
              (math.sin(progress * 2 * math.pi) + 1) / 2,
            );
            break;
          case 'oled':
            activeColors = _oledColors;
            activeIcon = Icons.local_fire_department_rounded;
            iconColor = Color.lerp(
              const Color(0xFFFF3D00),
              const Color(0xFFFFC107),
              (math.sin(progress * 2 * math.pi) + 1) / 2,
            );
            break;
          case 'light':
            activeColors = _lightColors;
            activeIcon = Icons.wb_sunny_rounded;
            iconColor = Color.lerp(
              const Color(0xFF2563EB),
              const Color(0xFF0284C7),
              (math.sin(progress * 2 * math.pi) + 1) / 2,
            );
            break;
          case 'dark':
          default:
            activeColors = _darkColors;
            activeIcon = Icons.bolt_rounded;
            iconColor = Color.lerp(
              const Color(0xFF00E5FF),
              const Color(0xFF2979FF),
              (math.sin(progress * 2 * math.pi) + 1) / 2,
            );
            break;
        }

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: CustomPaint(
            painter: _FlameBorderPainter(
              progress: progress,
              colors: activeColors,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: theme.colorScheme.surface.withAlpha(210),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    activeIcon,
                    size: 16,
                    color: iconColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlameBorderPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _FlameBorderPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    // 1. Fiery outer glow
    final glowPaint = Paint()
      ..shader = SweepGradient(
        colors: colors.map((c) => c.withAlpha(120)).toList(),
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawRRect(rrect, glowPaint);

    // 2. Sharp vibrant fiery core border
    final borderPaint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FlameBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.colors != colors;
  }
}
