import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// Highly-optimized, battery-friendly ambient background animator
/// that renders dynamic visuals matching the active app theme with
/// 100% continuous, seamlessly looping particle & celestial dynamics.
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
  static const int _particleCount = 34;

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
          cycles:
              1 + random.nextInt(3), // 1, 2, or 3 integer full loops per cycle
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
        _paintSakuraWithBranches(canvas, size, paint);
        break;
      case 'oled':
        _paintMoonMeteors(canvas, size, paint);
        break;
      case 'light':
        _paintLightDaylight(canvas, size, paint);
        break;
      case 'dark':
      default:
        _paintSnowfallVillage(canvas, size, paint);
        break;
    }
  }

  // =========================================================================
  // 1. SNOWFALL MODE: WINTER VILLAGE NIGHT & WARM CABIN GLOW
  // =========================================================================
  void _paintSnowfallVillage(Canvas canvas, Size size, Paint paint) {
    // A. Distant Snow Hill (Background rolling slope)
    final backHillPath = Path();
    final backHillBaseY = size.height * 0.83;
    backHillPath.moveTo(0, backHillBaseY + 14);
    backHillPath.cubicTo(
      size.width * 0.30,
      backHillBaseY - 24,
      size.width * 0.65,
      backHillBaseY + 20,
      size.width,
      backHillBaseY - 12,
    );
    backHillPath.lineTo(size.width, size.height);
    backHillPath.lineTo(0, size.height);
    backHillPath.close();

    final backHillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E293B).withAlpha(120),
          const Color(0xFF0F172A).withAlpha(190),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(backHillPath, backHillPaint);

    // Distant Snow Cap on back hill
    final backHillSnowPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF94A3B8).withAlpha(55);
    canvas.drawPath(backHillPath, backHillSnowPaint);

    // Pine trees on distant slope
    _drawSnowyPine(
      canvas,
      Offset(size.width * 0.08, backHillBaseY + 10),
      22,
      38,
    );
    _drawSnowyPine(
      canvas,
      Offset(size.width * 0.52, backHillBaseY + 16),
      24,
      40,
    );

    // B. Foreground Village Hill (Main layer)
    final hillPath = Path();
    final hillBaseY = size.height * 0.88;
    hillPath.moveTo(0, hillBaseY - 10);
    hillPath.cubicTo(
      size.width * 0.32,
      hillBaseY + 18,
      size.width * 0.68,
      hillBaseY - 28,
      size.width,
      hillBaseY + 8,
    );
    hillPath.lineTo(size.width, size.height);
    hillPath.lineTo(0, size.height);
    hillPath.close();

    final hillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E293B).withAlpha(220),
          const Color(0xFF0F172A).withAlpha(255),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(hillPath, hillPaint);

    // Crisp Snow Ridge Crest along main hill
    final snowRidgePaint = Paint()
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFCFF0FF).withAlpha(90),
          const Color(0xFFBAE6FD).withAlpha(160),
          const Color(0xFFCFF0FF).withAlpha(70),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(hillPath, snowRidgePaint);

    // Pine trees on foreground slope
    _drawSnowyPine(canvas, Offset(size.width * 0.38, hillBaseY + 12), 18, 30);
    _drawSnowyPine(canvas, Offset(size.width * 0.92, hillBaseY - 4), 20, 34);

    // C. Village Cabins with warm glowing windows & chimney smoke
    // Cabin 1: Left slope (cozy cottage)
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.22, hillBaseY + 6),
      34.0,
      30.0,
      chimneyXOffset: 8,
      hasChimney: true,
    );

    // Cabin 2: Right slope (main village cabin)
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.74, hillBaseY - 18),
      42.0,
      36.0,
      chimneyXOffset: -10,
      hasChimney: true,
    );

    // D. Falling Snowflakes in crystalline #CFF0FF
    final snowBaseColor = const Color(0xFFCFF0FF);
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final currentProgress = (p.y + progress * p.cycles) % 1.0;
      final yPos = currentProgress * size.height;

      final sway =
          math.sin(progress * 2 * math.pi * p.swayFreq + p.phase) *
          (p.swayAmplitude * 1.3);
      final xPos = (p.x * size.width + sway) % size.width;

      final edgeFade = math.sin(currentProgress * math.pi);
      final alpha = ((50 + 190 * edgeFade) * edgeFade).toInt().clamp(0, 255);

      if (p.variant == 0) {
        // Crystal cross snowflake for prominent flakes
        final rot = progress * 2 * math.pi * p.rotCycles + p.phase;
        canvas.save();
        canvas.translate(xPos, yPos);
        canvas.rotate(rot);

        final arm = p.size * 0.85;
        final flakePaint = Paint()
          ..color = snowBaseColor.withAlpha(alpha)
          ..strokeWidth = 1.1
          ..style = PaintingStyle.stroke;

        canvas.drawLine(Offset(-arm, 0), Offset(arm, 0), flakePaint);
        canvas.drawLine(Offset(0, -arm), Offset(0, arm), flakePaint);
        final diag = arm * 0.65;
        canvas.drawLine(Offset(-diag, -diag), Offset(diag, diag), flakePaint);
        canvas.drawLine(Offset(-diag, diag), Offset(diag, -diag), flakePaint);
        canvas.restore();
      } else if (p.variant == 1) {
        // Frosty soft snowflake with halo
        paint.color = snowBaseColor.withAlpha((alpha * 0.35).toInt());
        canvas.drawCircle(Offset(xPos, yPos), p.size * 0.9, paint);
        paint.color = snowBaseColor.withAlpha(alpha);
        canvas.drawCircle(Offset(xPos, yPos), p.size * 0.45, paint);
      } else {
        // Crisp snow crystal dot
        paint.color = snowBaseColor.withAlpha(alpha);
        canvas.drawCircle(
          Offset(xPos, yPos),
          (p.size * 0.4).clamp(1.0, 2.8),
          paint,
        );
      }
    }
  }

  void _drawSnowyPine(Canvas canvas, Offset base, double width, double height) {
    final trunkHeight = height * 0.22;
    final trunkWidth = width * 0.18;
    final trunkRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - trunkHeight / 2),
      width: trunkWidth,
      height: trunkHeight,
    );
    canvas.drawRect(trunkRect, Paint()..color = const Color(0xFF1E293B));

    for (int tier = 0; tier < 3; tier++) {
      final tierBottom = base.dy - trunkHeight * 0.8 - (tier * height * 0.26);
      final tierTop = tierBottom - height * 0.38;
      final tierW = width * (1.0 - tier * 0.25);

      final foliagePath = Path();
      foliagePath.moveTo(base.dx, tierTop);
      foliagePath.lineTo(base.dx + tierW / 2, tierBottom);
      foliagePath.lineTo(base.dx - tierW / 2, tierBottom);
      foliagePath.close();

      canvas.drawPath(
        foliagePath,
        Paint()..color = const Color(0xFF0F172A).withAlpha(240),
      );

      final snowPath = Path();
      snowPath.moveTo(base.dx - tierW / 2, tierBottom);
      snowPath.quadraticBezierTo(
        base.dx,
        tierBottom - 4,
        base.dx + tierW / 2,
        tierBottom,
      );
      canvas.drawPath(
        snowPath,
        Paint()
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFCFF0FF).withAlpha(180),
      );
    }
  }

  void _drawSnowyCabin(
    Canvas canvas,
    Offset base,
    double width,
    double height, {
    required double chimneyXOffset,
    required bool hasChimney,
  }) {
    final bodyHeight = height * 0.58;
    final bodyRect = Rect.fromLTWH(
      base.dx - width / 2,
      base.dy - bodyHeight,
      width,
      bodyHeight,
    );
    canvas.drawRect(bodyRect, Paint()..color = const Color(0xFF1E293B));

    // Warm golden glowing window
    final winW = width * 0.32;
    final winH = bodyHeight * 0.44;
    final winRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - bodyHeight * 0.48),
      width: winW,
      height: winH,
    );

    // Window warm ambient halo glow
    final windowGlowPulse =
        (math.sin(progress * 2 * math.pi + base.dx) + 1) / 2;
    final haloPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFDE047)
                  .withAlpha((90 + 35 * windowGlowPulse).toInt()),
              const Color(0xFFFEF08A).withAlpha(25),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
            Rect.fromCircle(center: winRect.center, radius: winW * 1.8),
          );
    canvas.drawCircle(winRect.center, winW * 1.8, haloPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(winRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFFDE047).withAlpha(235),
    );

    final framePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(winRect.left, winRect.center.dy),
      Offset(winRect.right, winRect.center.dy),
      framePaint,
    );
    canvas.drawLine(
      Offset(winRect.center.dx, winRect.top),
      Offset(winRect.center.dx, winRect.bottom),
      framePaint,
    );

    // Chimney & rising smoke
    if (hasChimney) {
      final chW = width * 0.16;
      final chH = height * 0.34;
      final chX = base.dx + chimneyXOffset;
      final chY = base.dy - bodyHeight - height * 0.22;
      canvas.drawRect(
        Rect.fromLTWH(chX - chW / 2, chY, chW, chH),
        Paint()..color = const Color(0xFF0F172A),
      );

      // Chimney snow cap
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chX - chW * 0.65, chY - 2, chW * 1.3, 3),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFCFF0FF),
      );

      // Drifting chimney smoke puffs
      for (int s = 0; s < 4; s++) {
        final smokeProgress = (progress + s * 0.25) % 1.0;
        final smokeY = chY - smokeProgress * 42.0;
        final smokeSway =
            math.sin(smokeProgress * math.pi * 3 + s) * 6.0 +
            (smokeProgress * 7.0);
        final smokeX = chX + smokeSway;
        final smokeRadius = 2.4 + smokeProgress * 6.5;
        final smokeAlpha = ((1.0 - smokeProgress) * 75).toInt().clamp(0, 255);

        canvas.drawCircle(
          Offset(smokeX, smokeY),
          smokeRadius,
          Paint()..color = const Color(0xFFE2E8F0).withAlpha(smokeAlpha),
        );
      }
    }

    // Snow-covered gable roof
    final roofPeak = Offset(base.dx, base.dy - height);
    final roofLeft = Offset(base.dx - width * 0.64, base.dy - bodyHeight + 2);
    final roofRight = Offset(base.dx + width * 0.64, base.dy - bodyHeight + 2);

    final roofPath = Path();
    roofPath.moveTo(roofPeak.dx, roofPeak.dy);
    roofPath.lineTo(roofRight.dx, roofRight.dy);
    roofPath.lineTo(roofLeft.dx, roofLeft.dy);
    roofPath.close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF0F172A));

    final snowRoofPath = Path();
    snowRoofPath.moveTo(roofPeak.dx, roofPeak.dy - 3);
    snowRoofPath.lineTo(roofRight.dx + 2, roofRight.dy - 1);
    snowRoofPath.lineTo(roofRight.dx - 2, roofRight.dy + 3);
    snowRoofPath.lineTo(roofPeak.dx, roofPeak.dy + 2);
    snowRoofPath.lineTo(roofLeft.dx + 2, roofLeft.dy + 3);
    snowRoofPath.lineTo(roofLeft.dx - 2, roofLeft.dy - 1);
    snowRoofPath.close();

    canvas.drawPath(
      snowRoofPath,
      Paint()..color = const Color(0xFFCFF0FF).withAlpha(240),
    );
  }

  // =========================================================================
  // 2. DARK OLED: GLOWING MOON, TWINKLING STARS & SHOOTING METEORS
  // =========================================================================
  void _paintMoonMeteors(Canvas canvas, Size size, Paint paint) {
    // A. Glowing Moon in the upper celestial sky
    final moonCenter = Offset(size.width * 0.83, 72.0);
    final moonPulse = (math.sin(progress * 2 * math.pi) + 1) / 2;

    // Ethereal Moon Halo
    final haloRadius = 44.0 + moonPulse * 4.0;
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE2E8F0).withAlpha((36 + 14 * moonPulse).toInt()),
          const Color(0xFF818CF8).withAlpha(12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: haloRadius));
    canvas.drawCircle(moonCenter, haloRadius, haloPaint);

    // Crescent Moon Disc
    const moonRadius = 16.5;
    final moonDiscPaint = Paint()
      ..color = const Color(0xFFF8FAFC).withAlpha(245)
      ..style = PaintingStyle.fill;

    final moonPath = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: moonRadius));
    final shadowPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(moonCenter.dx - 6.2, moonCenter.dy - 3.2),
          radius: moonRadius * 0.95,
        ),
      );
    final crescentPath = Path.combine(
      PathOperation.difference,
      moonPath,
      shadowPath,
    );
    canvas.drawPath(crescentPath, moonDiscPaint);

    // Subtle golden moon aura rim
    final rimPaint = Paint()
      ..color = const Color(0xFFFDE68A)
          .withAlpha((140 + 70 * moonPulse).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawPath(crescentPath, rimPaint);

    // B. Twinkling Star Field
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final xPos = (p.x * size.width);
      final yPos = (p.y * size.height);

      final twinkle =
          (math.sin(progress * 2 * math.pi * p.twinkleFreq + p.phase) + 1) / 2;
      final alpha = (30 + 220 * twinkle).toInt().clamp(0, 255);

      final starColor = p.variant == 0
          ? const Color(0xFFFFFFFF)
          : (p.variant == 1
                ? const Color(0xFF93C5FD)
                : const Color(0xFFFDE68A));

      paint.color = starColor.withAlpha(alpha);
      final r = (p.size * 0.32).clamp(0.8, 2.2);
      canvas.drawCircle(Offset(xPos, yPos), r, paint);

      // Star flare on brightest stars
      if (p.size > 5.2 && twinkle > 0.6) {
        final flareLen = (twinkle - 0.6) * 11.0;
        final flarePaint = Paint()
          ..color = starColor.withAlpha((190 * twinkle).toInt().clamp(0, 255))
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(xPos - flareLen, yPos),
          Offset(xPos + flareLen, yPos),
          flarePaint,
        );
        canvas.drawLine(
          Offset(xPos, yPos - flareLen),
          Offset(xPos, yPos + flareLen),
          flarePaint,
        );
      }
    }

    // C. Falling Meteors / Shooting Stars Animation
    final meteors = [
      (
        start: 0.08,
        end: 0.26,
        sX: 0.85,
        sY: 0.04,
        dx: -0.52,
        dy: 0.44,
        len: 120.0,
      ),
      (
        start: 0.42,
        end: 0.60,
        sX: 0.62,
        sY: 0.02,
        dx: -0.58,
        dy: 0.48,
        len: 145.0,
      ),
      (
        start: 0.74,
        end: 0.92,
        sX: 0.94,
        sY: 0.12,
        dx: -0.48,
        dy: 0.40,
        len: 125.0,
      ),
    ];

    for (final m in meteors) {
      if (progress >= m.start && progress <= m.end) {
        final t = (progress - m.start) / (m.end - m.start);
        final envelope = math.sin(t * math.pi); // Smooth fade in and out

        final headX = (m.sX + m.dx * t) * size.width;
        final headY = (m.sY + m.dy * t) * size.height;

        final dir = Offset(m.dx, m.dy);
        final dirNorm = dir / dir.distance;
        final tailOffset = dirNorm * (m.len * envelope);
        final tailX = headX - tailOffset.dx;
        final tailY = headY - tailOffset.dy;

        // Meteor Trail Shader
        final trailPaint = Paint()
          ..strokeWidth = 1.8 * envelope
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..shader =
              LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  const Color(0xFFFFFFFF)
                      .withAlpha((240 * envelope).toInt().clamp(0, 255)),
                  const Color(0xFF38BDF8)
                      .withAlpha((180 * envelope).toInt().clamp(0, 255)),
                  const Color(0xFF818CF8)
                      .withAlpha((60 * envelope).toInt().clamp(0, 255)),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.25, 0.7, 1.0],
              ).createShader(
                Rect.fromPoints(Offset(headX, headY), Offset(tailX, tailY)),
              );

        canvas.drawLine(Offset(tailX, tailY), Offset(headX, headY), trailPaint);

        // Meteor Luminous Head
        paint.color = Colors.white.withAlpha(
          (255 * envelope).toInt().clamp(0, 255),
        );
        canvas.drawCircle(Offset(headX, headY), 2.2 * envelope, paint);
      }
    }
  }

  // =========================================================================
  // 3. LIGHT MODE: WARM SUNBEAMS & FRESH DAYLIGHT BREEZE
  // =========================================================================
  void _paintLightDaylight(Canvas canvas, Size size, Paint paint) {
    // A. Warm Sunlight Flare in top right corner
    final sunCenter = Offset(size.width * 0.92, -10.0);
    final sunPulse = (math.sin(progress * 2 * math.pi) + 1) / 2;
    final sunRadius = size.width * 0.6;

    final sunGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withAlpha((36 + 12 * sunPulse).toInt()),
          const Color(0xFFFBBF24).withAlpha(16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunGlowPaint);

    // B. Upward drifting sunlight motes & warm breeze particles
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final currentProgress = (1.0 - (p.y + progress * p.cycles) % 1.0);
      final yPos = currentProgress * size.height;

      final sway =
          math.sin(progress * 2 * math.pi * p.swayFreq + p.phase) *
          (p.swayAmplitude * 0.85);
      final xPos = (p.x * size.width + sway) % size.width;

      final edgeFade = math.sin(currentProgress * math.pi);
      final alpha = ((20 + 55 * math.sin(p.phase).abs()) * edgeFade)
          .toInt()
          .clamp(0, 255);

      final color = p.variant == 0
          ? const Color(0xFFF59E0B) // Amber sunlight
          : (p.variant == 1
                ? const Color(0xFF0284C7) // Sky azure
                : (p.variant == 2
                      ? const Color(0xFFFBBF24) // Gold solar mote
                      : const Color(0xFF38BDF8))); // Light sky

      paint.color = color.withAlpha(alpha);
      canvas.drawCircle(Offset(xPos, yPos), p.size * 1.3, paint);
    }
  }

  // =========================================================================
  // 4. AMOLED SAKURA: CHERRY BLOSSOM BRANCHES & FALLING PETALS
  // =========================================================================
  void _paintSakuraWithBranches(Canvas canvas, Size size, Paint paint) {
    final windSway = math.sin(progress * 2 * math.pi) * 2.0;

    // A. Tree Branches in top-right and top-left corners
    final branchPaint = Paint()
      ..color =
          const Color(0xFF26141D) // Rich dark cherry wood bark
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final branchDetailPaint = Paint()
      ..color = const Color(0xFF3E1E2D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Top-Right Branch
    final brPath = Path();
    brPath.moveTo(size.width + 12, -8);
    brPath.cubicTo(
      size.width * 0.90,
      12 + windSway,
      size.width * 0.78,
      28 + windSway,
      size.width * 0.68,
      42 + windSway,
    );
    branchPaint.strokeWidth = 5.2;
    canvas.drawPath(brPath, branchPaint);
    branchDetailPaint.strokeWidth = 2.0;
    canvas.drawPath(brPath, branchDetailPaint);

    // Sub-twigs Top-Right
    final twig1 = Path();
    twig1.moveTo(size.width * 0.78, 28 + windSway);
    twig1.quadraticBezierTo(
      size.width * 0.74,
      52 + windSway,
      size.width * 0.64,
      68 + windSway,
    );
    branchPaint.strokeWidth = 2.6;
    canvas.drawPath(twig1, branchPaint);

    final twig2 = Path();
    twig2.moveTo(size.width * 0.88, 14 + windSway);
    twig2.quadraticBezierTo(
      size.width * 0.86,
      36 + windSway,
      size.width * 0.80,
      54 + windSway,
    );
    branchPaint.strokeWidth = 2.2;
    canvas.drawPath(twig2, branchPaint);

    // 2. Top-Left Branch
    final blPath = Path();
    blPath.moveTo(-10, -6);
    blPath.cubicTo(
      size.width * 0.12,
      16 - windSway,
      size.width * 0.22,
      32 - windSway,
      size.width * 0.32,
      46 - windSway,
    );
    branchPaint.strokeWidth = 4.8;
    canvas.drawPath(blPath, branchPaint);
    branchDetailPaint.strokeWidth = 1.8;
    canvas.drawPath(blPath, branchDetailPaint);

    // Sub-twig Top-Left
    final blTwig = Path();
    blTwig.moveTo(size.width * 0.20, 29 - windSway);
    blTwig.quadraticBezierTo(
      size.width * 0.24,
      52 - windSway,
      size.width * 0.28,
      72 - windSway,
    );
    branchPaint.strokeWidth = 2.2;
    canvas.drawPath(blTwig, branchPaint);

    // B. Blooming Sakura Flower Clusters anchored to branches
    final flowers = [
      // Top Right Cluster
      (x: size.width * 0.88, y: 15.0 + windSway, scale: 9.5),
      (x: size.width * 0.78, y: 30.0 + windSway, scale: 11.0),
      (x: size.width * 0.72, y: 44.0 + windSway, scale: 8.5),
      (x: size.width * 0.65, y: 69.0 + windSway, scale: 10.0),
      (x: size.width * 0.80, y: 55.0 + windSway, scale: 8.0),
      (x: size.width * 0.94, y: 32.0 + windSway, scale: 7.5),
      // Top Left Cluster
      (x: size.width * 0.12, y: 18.0 - windSway, scale: 9.0),
      (x: size.width * 0.22, y: 33.0 - windSway, scale: 11.5),
      (x: size.width * 0.32, y: 47.0 - windSway, scale: 8.5),
      (x: size.width * 0.28, y: 73.0 - windSway, scale: 9.5),
      (x: size.width * 0.05, y: 36.0 - windSway, scale: 7.0),
    ];

    for (final f in flowers) {
      _drawSakuraBlossom(canvas, Offset(f.x, f.y), f.scale);
    }

    // C. Falling & Fluttering Cherry Blossom Petals
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final currentProgress = (p.y + progress * p.cycles) % 1.0;
      final yPos = currentProgress * size.height;

      final sway =
          math.sin(progress * 2 * math.pi * p.swayFreq + p.phase) *
          p.swayAmplitude;
      final xPos = (p.x * size.width + sway) % size.width;

      final rot = progress * 2 * math.pi * p.rotCycles + p.phase;
      final petalScale = p.size;
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
        // Falling Sakura Petal
        final baseAlpha = p.variant == 1 ? 165 : 135;
        final alpha = (baseAlpha * edgeFade).toInt().clamp(0, 255);
        paint.color =
            (p.variant == 1 ? const Color(0xFFF472B6) : const Color(0xFFFDA4AF))
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

  /// Helper to draw a blooming 5-petal sakura flower with stamen center
  void _drawSakuraBlossom(Canvas canvas, Offset center, double scale) {
    final petalPaint = Paint()
      ..color = const Color(0xFFFFB7C5).withAlpha(225)
      ..style = PaintingStyle.fill;

    final centerPaint = Paint()
      ..color = const Color(0xFFBE185D).withAlpha(240)
      ..style = PaintingStyle.fill;

    // Draw 5 overlapping petals
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final petalCenter = Offset(
        center.dx + math.cos(angle) * (scale * 0.55),
        center.dy + math.sin(angle) * (scale * 0.55),
      );

      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);

      final pPath = Path();
      pPath.moveTo(0, -scale * 0.5);
      pPath.cubicTo(
        scale * 0.45,
        -scale * 0.2,
        scale * 0.4,
        scale * 0.35,
        0,
        scale * 0.5,
      );
      pPath.cubicTo(
        -scale * 0.4,
        scale * 0.35,
        -scale * 0.45,
        -scale * 0.2,
        0,
        -scale * 0.5,
      );
      pPath.close();

      canvas.drawPath(pPath, petalPaint);
      canvas.restore();
    }

    // Flower stamen center
    canvas.drawCircle(center, scale * 0.22, centerPaint);
    final corePaint = Paint()
      ..color = const Color(0xFFFFD0E0).withAlpha(255)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, scale * 0.10, corePaint);
  }

  @override
  bool shouldRepaint(covariant _ThemeBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.themeMode != themeMode;
  }
}
