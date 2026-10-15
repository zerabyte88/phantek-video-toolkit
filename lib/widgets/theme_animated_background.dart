import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/settings_service.dart';

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

    final initialTheme = SettingsService().settings.themeMode;
    final isStatic =
        initialTheme == 'oled_pure' || initialTheme == 'light_clean';

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (!isStatic) {
      _controller.repeat();
    }
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
        final isStatic = themeMode == 'oled_pure' || themeMode == 'light_clean';

        if (isStatic) {
          if (_controller.isAnimating) {
            _controller.stop();
          }
        } else {
          if (!_controller.isAnimating) {
            _controller.repeat();
          }
        }

        final theme = Theme.of(context);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Ambient animated custom canvas (only active in animated themes)
            if (!isStatic)
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

    if (themeMode == 'oled_pure' || themeMode == 'light_clean') {
      return;
    }

    final paint = Paint()..style = PaintingStyle.fill;

    switch (themeMode) {
      case 'sakura':
      case 'oled_sakura':
        _paintSakuraWithBranches(canvas, size, paint);
        break;
      case 'oled_midnight':
      case 'oled':
        _paintMoonMeteors(canvas, size, paint);
        break;
      case 'light':
        _paintLightDaylight(canvas, size, paint);
        break;
      case 'oled_snowfall':
      case 'dark':
      default:
        _paintSnowfallVillage(canvas, size, paint);
        break;
    }
  }

  // Snowfall
  void _paintSnowfallVillage(Canvas canvas, Size size, Paint paint) {
    // Distant hill
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

    // Fill path
    final backHillFill = Path.from(backHillPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final backHillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0F172A).withAlpha(120),
          Colors.black.withAlpha(240),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(backHillFill, backHillPaint);

    // Snow cap
    final backHillSnowPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF94A3B8).withAlpha(55);
    canvas.drawPath(backHillPath, backHillSnowPaint);

    // Distant pines
    _drawSnowyPine(
      canvas,
      Offset(size.width * 0.07, backHillBaseY + 10),
      22,
      38,
      isDistant: true,
    );
    _drawSnowyPine(
      canvas,
      Offset(size.width * 0.40, backHillBaseY + 18),
      20,
      34,
      isDistant: true,
    );
    _drawSnowyPine(
      canvas,
      Offset(size.width * 0.90, backHillBaseY - 14),
      24,
      40,
      isDistant: true,
    );

    // Distant cabins
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.20, backHillBaseY + 6),
      22.0,
      20.0,
      chimneyXOffset: 4,
      hasChimney: true,
      isDistant: true,
    );
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.64, backHillBaseY + 18),
      24.0,
      22.0,
      chimneyXOffset: -5,
      hasChimney: true,
      isDistant: true,
    );

    // Foreground hill
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

    // Fill path
    final hillFill = Path.from(hillPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final hillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0C1322).withAlpha(220), Colors.black],
      ).createShader(Offset.zero & size);
    canvas.drawPath(hillFill, hillPaint);

    // Snow ridge
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

    // Foreground pines
    _drawSnowyPine(canvas, Offset(size.width * 0.04, hillBaseY - 8), 22, 36);
    _drawSnowyPine(canvas, Offset(size.width * 0.34, hillBaseY + 14), 20, 32);
    _drawSnowyPine(canvas, Offset(size.width * 0.60, hillBaseY - 14), 22, 35);
    _drawSnowyPine(canvas, Offset(size.width * 0.95, hillBaseY - 2), 24, 38);

    // Village cabins
    // Cabin 1
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.16, hillBaseY + 6),
      34.0,
      30.0,
      chimneyXOffset: -7,
      hasChimney: true,
    );

    // Cabin 2
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.25, hillBaseY + 12),
      28.0,
      25.0,
      chimneyXOffset: 5,
      hasChimney: true,
    );

    // Cabin 3
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.46, hillBaseY + 22),
      32.0,
      28.0,
      chimneyXOffset: 6,
      hasChimney: true,
    );

    // Cabin 4
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.74, hillBaseY - 18),
      42.0,
      36.0,
      chimneyXOffset: -10,
      hasChimney: true,
    );

    // Cabin 5
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.84, hillBaseY - 10),
      30.0,
      26.0,
      chimneyXOffset: 5,
      hasChimney: true,
    );

    // Snowflakes
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
        paint.color = snowBaseColor.withAlpha((alpha * 0.35).toInt());
        canvas.drawCircle(Offset(xPos, yPos), p.size * 0.9, paint);
        paint.color = snowBaseColor.withAlpha(alpha);
        canvas.drawCircle(Offset(xPos, yPos), p.size * 0.45, paint);
      } else {
        paint.color = snowBaseColor.withAlpha(alpha);
        canvas.drawCircle(
          Offset(xPos, yPos),
          (p.size * 0.4).clamp(1.0, 2.8),
          paint,
        );
      }
    }
  }

  void _drawSnowyPine(
    Canvas canvas,
    Offset base,
    double width,
    double height, {
    bool isDistant = false,
  }) {
    final trunkHeight = height * 0.22;
    final trunkWidth = width * 0.18;
    final trunkRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - trunkHeight / 2),
      width: trunkWidth,
      height: trunkHeight,
    );
    // Trunk
    canvas.drawRect(
      trunkRect,
      Paint()
        ..color = isDistant
            ? const Color(0xFF2C1E18).withAlpha(180)
            : const Color(0xFF3E2723),
    );

    // Foliage layers
    final tierColors = isDistant
        ? [
            const Color(0xFF0F291E).withAlpha(190),
            const Color(0xFF143628).withAlpha(200),
            const Color(0xFF194432).withAlpha(210),
          ]
        : [
            const Color(0xFF143628), // Deep base pine
            const Color(0xFF1B4332), // Rich evergreen green
            const Color(0xFF22543D), // Vibrant pine crown
          ];

    for (int tier = 0; tier < 3; tier++) {
      final tierBottom = base.dy - trunkHeight * 0.8 - (tier * height * 0.26);
      final tierTop = tierBottom - height * 0.38;
      final tierW = width * (1.0 - tier * 0.25);

      final foliagePath = Path();
      foliagePath.moveTo(base.dx, tierTop);
      foliagePath.lineTo(base.dx + tierW / 2, tierBottom);
      foliagePath.lineTo(base.dx - tierW / 2, tierBottom);
      foliagePath.close();

      canvas.drawPath(foliagePath, Paint()..color = tierColors[tier]);

      // Branch snow
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
          ..strokeWidth = isDistant ? 1.4 : 2.0
          ..style = PaintingStyle.stroke
          ..color = isDistant
              ? const Color(0xFFCFF0FF).withAlpha(120)
              : const Color(0xFFCFF0FF).withAlpha(190),
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
    bool isDistant = false,
  }) {
    final bodyHeight = height * 0.58;
    final bodyRect = Rect.fromLTWH(
      base.dx - width / 2,
      base.dy - bodyHeight,
      width,
      bodyHeight,
    );

    // Cabin wall
    final wallColor = isDistant
        ? const Color(0xFF1A2230).withAlpha(190)
        : const Color(0xFF27211D); // Warm dark medieval wood
    canvas.drawRect(bodyRect, Paint()..color = wallColor);

    // Timber frame
    if (!isDistant && width >= 26) {
      final timberPaint = Paint()
        ..color = const Color(0xFF16120F)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawRect(bodyRect, timberPaint);
      canvas.drawLine(
        Offset(base.dx, base.dy - bodyHeight),
        Offset(base.dx, base.dy),
        timberPaint,
      );
    }

    // Window glow
    final winW = width * 0.32;
    final winH = bodyHeight * 0.44;
    final winRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - bodyHeight * 0.48),
      width: winW,
      height: winH,
    );

    final windowGlowPulse =
        (math.sin(progress * 2 * math.pi + base.dx) + 1) / 2;
    final haloRadius = isDistant ? winW * 1.3 : winW * 1.8;
    final haloAlpha = isDistant
        ? (55 + 20 * windowGlowPulse).toInt()
        : (90 + 35 * windowGlowPulse).toInt();

    final haloPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFDE047).withAlpha(haloAlpha),
              const Color(0xFFFEF08A).withAlpha(isDistant ? 12 : 25),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
            Rect.fromCircle(center: winRect.center, radius: haloRadius),
          );
    canvas.drawCircle(winRect.center, haloRadius, haloPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(winRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFFDE047).withAlpha(isDistant ? 180 : 235),
    );

    // Window frame
    if (!isDistant) {
      final framePaint = Paint()
        ..color = const Color(0xFF16120F)
        ..strokeWidth = 1.1
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
    }

    // Chimney
    if (hasChimney) {
      final chW = width * 0.16;
      final chH = height * 0.34;
      final chX = base.dx + chimneyXOffset;
      final chY = base.dy - bodyHeight - height * 0.22;
      canvas.drawRect(
        Rect.fromLTWH(chX - chW / 2, chY, chW, chH),
        Paint()..color = const Color(0xFF1E293B), // Stone chimney
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chX - chW * 0.65, chY - 2, chW * 1.3, 3),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFCFF0FF),
      );

      // Smoke puffs
      for (int s = 0; s < 4; s++) {
        final smokeProgress = (progress + s * 0.25) % 1.0;
        final smokeY = chY - smokeProgress * (isDistant ? 26.0 : 42.0);
        final smokeSway =
            math.sin(smokeProgress * math.pi * 3 + s) *
                (isDistant ? 3.5 : 6.0) +
            (smokeProgress * (isDistant ? 4.0 : 7.0));
        final smokeX = chX + smokeSway;
        final smokeRadius =
            (isDistant ? 1.6 : 2.4) + smokeProgress * (isDistant ? 3.8 : 6.5);
        final maxAlpha = isDistant ? 45 : 75;
        final smokeAlpha = ((1.0 - smokeProgress) * maxAlpha).toInt().clamp(
          0,
          255,
        );

        canvas.drawCircle(
          Offset(smokeX, smokeY),
          smokeRadius,
          Paint()..color = const Color(0xFFE2E8F0).withAlpha(smokeAlpha),
        );
      }
    }

    // Roof
    final roofPeak = Offset(base.dx, base.dy - height);
    final roofLeft = Offset(base.dx - width * 0.68, base.dy - bodyHeight + 2);
    final roofRight = Offset(base.dx + width * 0.68, base.dy - bodyHeight + 2);

    final roofPath = Path();
    roofPath.moveTo(roofPeak.dx, roofPeak.dy);
    roofPath.lineTo(roofRight.dx, roofRight.dy);
    roofPath.lineTo(roofLeft.dx, roofLeft.dy);
    roofPath.close();
    canvas.drawPath(
      roofPath,
      Paint()
        ..color = isDistant
            ? const Color(0xFF0F172A).withAlpha(200)
            : const Color(0xFF1E1712),
    );

    // Roof snow
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
      Paint()
        ..color = isDistant
            ? const Color(0xFFCFF0FF).withAlpha(180)
            : const Color(0xFFCFF0FF).withAlpha(240),
    );
  }

  // Midnight
  void _paintMoonMeteors(Canvas canvas, Size size, Paint paint) {
    // Moon
    final moonCenter = Offset(size.width * 0.83, 72.0);
    final moonPulse = (math.sin(progress * 2 * math.pi) + 1) / 2;

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

    final rimPaint = Paint()
      ..color = const Color(0xFFFDE68A)
          .withAlpha((140 + 70 * moonPulse).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawPath(crescentPath, rimPaint);

    // Stars
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

    // Meteors
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

        paint.color = Colors.white.withAlpha(
          (255 * envelope).toInt().clamp(0, 255),
        );
        canvas.drawCircle(Offset(headX, headY), 2.2 * envelope, paint);
      }
    }
  }

  // Daylight
  void _paintLightDaylight(Canvas canvas, Size size, Paint paint) {
    // Sunlight flare
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

    // Floating particles
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

  // Sakura
  void _paintSakuraWithBranches(Canvas canvas, Size size, Paint paint) {
    final windSway = math.sin(progress * 2 * math.pi) * 2.0;

    // Branches
    final branchPaint = Paint()
      ..color =
          const Color(0xFF26141D) // Rich dark cherry wood bark
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final branchDetailPaint = Paint()
      ..color = const Color(0xFF3E1E2D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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

    // Flower clusters
    final flowers = [
      (x: size.width * 0.88, y: 15.0 + windSway, scale: 9.5),
      (x: size.width * 0.78, y: 30.0 + windSway, scale: 11.0),
      (x: size.width * 0.72, y: 44.0 + windSway, scale: 8.5),
      (x: size.width * 0.65, y: 69.0 + windSway, scale: 10.0),
      (x: size.width * 0.80, y: 55.0 + windSway, scale: 8.0),
      (x: size.width * 0.94, y: 32.0 + windSway, scale: 7.5),
      (x: size.width * 0.12, y: 18.0 - windSway, scale: 9.0),
      (x: size.width * 0.22, y: 33.0 - windSway, scale: 11.5),
      (x: size.width * 0.32, y: 47.0 - windSway, scale: 8.5),
      (x: size.width * 0.28, y: 73.0 - windSway, scale: 9.5),
      (x: size.width * 0.05, y: 36.0 - windSway, scale: 7.0),
    ];

    for (final f in flowers) {
      _drawSakuraBlossom(canvas, Offset(f.x, f.y), f.scale);
    }

    // Falling petals
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
        final alpha = (140 * edgeFade).toInt().clamp(0, 255);
        paint.color = const Color(0xFFFFB7C5).withAlpha(alpha);
        canvas.drawCircle(Offset.zero, 1.8, paint);
      } else {
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

  /// Draws a 5-petal sakura flower.
  void _drawSakuraBlossom(Canvas canvas, Offset center, double scale) {
    final petalPaint = Paint()
      ..color = const Color(0xFFFFB7C5).withAlpha(225)
      ..style = PaintingStyle.fill;

    final centerPaint = Paint()
      ..color = const Color(0xFFBE185D).withAlpha(240)
      ..style = PaintingStyle.fill;

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
