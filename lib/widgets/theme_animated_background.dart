import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// Highly-optimized, battery-friendly ambient background animator
/// that renders dynamic visuals matching the active app theme with
/// 100% continuous, seamlessly looping particle dynamics.
class ThemeAnimatedBackground extends StatefulWidget {
  final Widget child;

  const ThemeAnimatedBackground({super.key, required this.child});

  @override
  State<ThemeAnimatedBackground> createState() =>
      _ThemeAnimatedBackgroundState();
}

class _ThemeAnimatedBackgroundState extends State<ThemeAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _particles = <_BackgroundParticle>[];
  static const int _particleCount = 30;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        _BackgroundParticle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: 2.5 + random.nextDouble() * 5.0,
          cycles: 1 + random.nextInt(3), // 1, 2, or 3 integer full loops per cycle
          swayFreq: 1 + random.nextInt(2), // 1 or 2 sways per cycle
          swayAmplitude: 10.0 + random.nextDouble() * 16.0,
          rotCycles: (random.nextBool() ? 1 : -1) * (1 + random.nextInt(2)),
          phase: random.nextDouble() * 2 * math.pi,
          twinkleFreq: 2 + random.nextInt(4), // 2 to 5 twinkles per cycle
          variant: random.nextInt(4),
        ),
      );
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();

    return ListenableBuilder(
      listenable: Listenable.merge([_controller, settingsService]),
      builder: (context, _) {
        final themeMode = settingsService.settings.themeMode;
        final theme = Theme.of(context);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Ambient animated custom canvas
            RepaintBoundary(
              child: CustomPaint(
                painter: _ThemeBackgroundPainter(
                  themeMode: themeMode,
                  theme: theme,
                  progress: _controller.value,
                  particles: _particles,
                ),
              ),
            ),
            // Screen content
            widget.child,
          ],
        );
      },
    );
  }
}

class _BackgroundParticle {
  final double x;
  final double y;
  final double size;
  final int cycles;
  final int swayFreq;
  final double swayAmplitude;
  final int rotCycles;
  final double phase;
  final int twinkleFreq;
  final int variant;

  const _BackgroundParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.cycles,
    required this.swayFreq,
    required this.swayAmplitude,
    required this.rotCycles,
    required this.phase,
    required this.twinkleFreq,
    required this.variant,
  });
}

class _ThemeBackgroundPainter extends CustomPainter {
  final String themeMode;
  final ThemeData theme;
  final double progress;
  final List<_BackgroundParticle> particles;

  _ThemeBackgroundPainter({
    required this.themeMode,
    required this.theme,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    switch (themeMode) {
      case 'sakura':
      case 'oled_sakura':
        _paintSakura(canvas, size, paint);
        break;
      case 'oled':
        _paintOledStardust(canvas, size, paint);
        break;
      case 'light':
        _paintLightBokeh(canvas, size, paint);
        break;
      case 'dark':
      default:
        _paintDarkCyberDust(canvas, size, paint);
        break;
    }
  }

  /// 1. AMOLED Sakura: Graceful falling & rotating cherry blossom petals
  void _paintSakura(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      // Continuous modulo calculation
      final currentProgress = (p.y + progress * p.cycles) % 1.0;
      final yPos = currentProgress * size.height;

      final sway = math.sin(progress * 2 * math.pi * p.swayFreq + p.phase) *
          p.swayAmplitude;
      final xPos = (p.x * size.width + sway) % size.width;

      final rot = progress * 2 * math.pi * p.rotCycles + p.phase;
      final petalScale = p.size;

      // Smooth edge fade to prevent popping
      final edgeFade = math.sin(currentProgress * math.pi);

      canvas.save();
      canvas.translate(xPos, yPos);
      canvas.rotate(rot);

      if (p.variant == 0) {
        // Glowing pollen dust
        final alpha = (140 * edgeFade).toInt().clamp(0, 255);
        paint.color = const Color(0xFFFFB7C5).withAlpha(alpha);
        canvas.drawCircle(Offset.zero, 1.8, paint);
      } else {
        // Sakura Petal
        final baseAlpha = p.variant == 1 ? 160 : 130;
        final alpha = (baseAlpha * edgeFade).toInt().clamp(0, 255);
        paint.color = (p.variant == 1
                ? const Color(0xFFF472B6)
                : const Color(0xFFFDA4AF))
            .withAlpha(alpha);

        final path = Path();
        path.moveTo(0, -petalScale);
        path.cubicTo(
          petalScale * 0.9,
          -petalScale * 0.4,
          petalScale * 0.8,
          petalScale * 0.6,
          0,
          petalScale,
        );
        path.cubicTo(
          -petalScale * 0.8,
          petalScale * 0.6,
          -petalScale * 0.9,
          -petalScale * 0.4,
          0,
          -petalScale,
        );
        path.close();

        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  /// 2. OLED AMOLED: Twinkling minimalist stardust & constellations
  void _paintOledStardust(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final currentProgress = (p.y + progress * 0.5) % 1.0;
      final yPos = currentProgress * size.height;
      final xPos = (p.x * size.width +
              math.sin(progress * 2 * math.pi * p.swayFreq + p.phase) * 6.0) %
          size.width;

      // Perfectly continuous twinkle
      final twinkle =
          (math.sin(progress * 2 * math.pi * p.twinkleFreq + p.phase) + 1) / 2;
      final edgeFade = math.sin(currentProgress * math.pi);
      final alpha = ((30 + 190 * twinkle) * edgeFade).toInt().clamp(0, 255);

      paint.color = (p.variant == 1
              ? const Color(0xFF38BDF8)
              : (p.variant == 2
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFFFFFF)))
          .withAlpha(alpha);

      final r = (p.size * 0.32).clamp(0.9, 2.4);
      canvas.drawCircle(Offset(xPos, yPos), r, paint);
    }
  }

  /// 3. Dark Slate: Floating cyber dust & ambient glowing tech energy
  void _paintDarkCyberDust(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final currentProgress = (p.y + progress * p.cycles) % 1.0;
      final yPos = currentProgress * size.height;

      final sway = math.sin(progress * 2 * math.pi * p.swayFreq + p.phase) *
          p.swayAmplitude;
      final xPos = (p.x * size.width + sway) % size.width;

      final pulse =
          (math.sin(progress * 2 * math.pi * p.twinkleFreq + p.phase) + 1) / 2;
      final edgeFade = math.sin(currentProgress * math.pi);
      final alpha = ((35 + 85 * pulse) * edgeFade).toInt().clamp(0, 255);

      paint.color = (p.variant == 0
              ? const Color(0xFF00E5FF)
              : (p.variant == 1
                  ? const Color(0xFF0072FF)
                  : const Color(0xFF38BDF8)))
          .withAlpha(alpha);

      canvas.drawCircle(Offset(xPos, yPos), p.size * 0.75, paint);
    }
  }

  /// 4. Light Mode: Soft airy ambient sunlight bokeh drifting upward
  void _paintLightBokeh(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      // Drifts upward continuously
      final currentProgress = (1.0 - (p.y + progress * p.cycles) % 1.0);
      final yPos = currentProgress * size.height;

      final sway = math.sin(progress * 2 * math.pi * p.swayFreq + p.phase) *
          (p.swayAmplitude * 0.8);
      final xPos = (p.x * size.width + sway) % size.width;

      final edgeFade = math.sin(currentProgress * math.pi);
      final alpha = ((15 + 40 * math.sin(p.phase).abs()) * edgeFade).toInt();

      paint.color = (p.variant == 0
              ? const Color(0xFF0284C7)
              : (p.variant == 1
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFF2563EB)))
          .withAlpha(alpha);

      canvas.drawCircle(Offset(xPos, yPos), p.size * 1.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.themeMode != themeMode;
  }
}
