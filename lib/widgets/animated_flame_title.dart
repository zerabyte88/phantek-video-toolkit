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

  // 1. Dark Mode: Aurora Borealis & Falling Snow
  static const _darkColors = [
    Color(0xFF10B981), // Emerald Aurora Green
    Color(0xFF06B6D4), // Vivid Arctic Teal
    Color(0xFF00E5FF), // Electric Arctic Cyan
    Color(0xFF8B5CF6), // Cosmic Aurora Violet
    Color(0xFF059669), // Deep Polar Emerald
    Color(0xFF10B981), // Back to Emerald Aurora
  ];

  // 2. Dark OLED: Glowing Moon, Twinkling Stars & Shooting Meteors
  static const _oledColors = [
    Color(0xFFE2E8F0), // Lunar Silver
    Color(0xFF818CF8), // Cosmic Starlight Violet
    Color(0xFF6366F1), // Deep Night Indigo
    Color(0xFFFDE68A), // Pale Moonlight Gold
    Color(0xFF38BDF8), // Electric Starlight Blue
    Color(0xFFE2E8F0), // Back to Lunar Silver
  ];

  // 3. Light Mode: Warm Sunbeams & Daylight Sky
  static const _lightColors = [
    Color(0xFFF59E0B), // Warm Sun Amber
    Color(0xFFFBBF24), // Bright Daylight Gold
    Color(0xFF0284C7), // Sky Azure
    Color(0xFF38BDF8), // Light Cyan Breeze
    Color(0xFFEA580C), // Radiant Sunburst Orange
    Color(0xFFF59E0B), // Back to Warm Sun Amber
  ];

  // 4. AMOLED Sakura: Cherry Blossom & Blooming Branches
  static const _sakuraColors = [
    Color(0xFFFF69B4), // Hot Pink
    Color(0xFFFFB7C5), // Cherry Blossom Pink
    Color(0xFFF472B6), // Pink 400
    Color(0xFFFDA4AF), // Rose 300
    Color(0xFFFF1493), // Deep Cherry Pink
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
            activeIcon = Icons.nightlight_round;
            iconColor = Color.lerp(
              const Color(0xFFFDE68A),
              const Color(0xFFE2E8F0),
              (math.sin(progress * 2 * math.pi) + 1) / 2,
            );
            break;
          case 'light':
            activeColors = _lightColors;
            activeIcon = Icons.wb_sunny_rounded;
            iconColor = Color.lerp(
              const Color(0xFFF59E0B),
              const Color(0xFF0284C7),
              (math.sin(progress * 2 * math.pi) + 1) / 2,
            );
            break;
          case 'dark':
          default:
            activeColors = _darkColors;
            activeIcon = Icons.ac_unit_rounded;
            iconColor = Color.lerp(
              const Color(0xFF10B981),
              const Color(0xFF00E5FF),
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
                  Icon(activeIcon, size: 16, color: iconColor),
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
