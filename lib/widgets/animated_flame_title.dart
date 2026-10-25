// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// AppBar title widget
class AnimatedFlameTitle extends StatefulWidget {
  final String title;

  const AnimatedFlameTitle({super.key, this.title = 'Phantek'});

  @override
  State<AnimatedFlameTitle> createState() => _AnimatedFlameTitleState();
}

class _AnimatedFlameTitleState extends State<AnimatedFlameTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Snowfall
  static const _darkColors = [
    Color(0xFF38BDF8),
    Color(0xFFCFF0FF),
    Color(0xFFBAE6FD),
    Color(0xFFFDE047),
    Color(0xFF0284C7),
    Color(0xFF38BDF8),
  ];

  // Midnight
  static const _oledColors = [
    Color(0xFFE2E8F0),
    Color(0xFF818CF8),
    Color(0xFF6366F1),
    Color(0xFFFDE68A),
    Color(0xFF38BDF8),
    Color(0xFFE2E8F0),
  ];

  // Daylight
  static const _lightColors = [
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
    Color(0xFF0284C7),
    Color(0xFF38BDF8),
    Color(0xFFEA580C),
    Color(0xFFF59E0B),
  ];

  // Sakura
  static const _sakuraColors = [
    Color(0xFFFF69B4),
    Color(0xFFFFB7C5),
    Color(0xFFF472B6),
    Color(0xFFFDA4AF),
    Color(0xFFFF1493),
    Color(0xFFFF69B4),
  ];

  // Pure AMOLED
  static const _oledPureColors = [
    Color(0xFF60A5FA),
    Color(0xFF93C5FD),
    Color(0xFF3B82F6),
    Color(0xFFBFDBFE),
    Color(0xFF1D4ED8),
    Color(0xFF60A5FA),
  ];

  // Clean Light
  static const _lightCleanColors = [
    Color(0xFF0EA5E9),
    Color(0xFF38BDF8),
    Color(0xFF7DD3FC),
    Color(0xFFBAE6FD),
    Color(0xFF0284C7),
    Color(0xFF0EA5E9),
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
          case 'oled_sakura':
          case 'sakura':
            activeColors = _sakuraColors;
            activeIcon = Icons.local_florist_rounded;
            iconColor = Color.lerp(
              const Color(0xFFFF69B4),
              const Color(0xFFFFB7C5),
              (math.sin(progress * 2 * math.pi) + 1) / 2,
            );
            break;
          case 'oled_pure':
          case 'pure_oled':
            activeColors = _oledPureColors;
            activeIcon = Icons.brightness_2_outlined;
            iconColor = Color.lerp(
              const Color(0xFF60A5FA),
              const Color(0xFF93C5FD),
              (math.sin(progress * 2 * math.pi) + 1) / 2,
            );
            break;
          case 'oled_midnight':
          case 'oled':
            activeColors = _oledColors;
            activeIcon = Icons.nightlight_round;
            iconColor = Color.lerp(
              const Color(0xFFFDE68A),
              const Color(0xFFE2E8F0),
              (math.sin(progress * 2 * math.pi) + 1) / 2,
            );
            break;
          case 'light_clean':
          case 'clean_light':
            activeColors = _lightCleanColors;
            activeIcon = Icons.wb_sunny_outlined;
            iconColor = Color.lerp(
              const Color(0xFF0EA5E9),
              const Color(0xFF38BDF8),
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
          case 'oled_snowfall':
          case 'dark':
          default:
            activeColors = _darkColors;
            activeIcon = Icons.ac_unit_rounded;
            iconColor = Color.lerp(
              const Color(0xFFCFF0FF),
              const Color(0xFF38BDF8),
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

    // Outer glow
    final glowPaint = Paint()
      ..shader = SweepGradient(
        colors: colors.map((c) => c.withAlpha(120)).toList(),
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawRRect(rrect, glowPaint);

    // Core border
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
