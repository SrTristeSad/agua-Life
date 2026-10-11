import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../models/fish_genome.dart';
import '../models/fish_state.dart';

class FishComponent extends PositionComponent {
  FishComponent({
    required this.state,
    required Random random,
  })  : _random = random,
        _baseSpeed = state.species.minSpeed +
            random.nextDouble() *
                (state.species.maxSpeed - state.species.minSpeed),
        _wavePhase = random.nextDouble() * pi * 2,
        super(
          size: Vector2(
            state.species.baseWidth *
                state.genome.bodyScale *
                state.visualScale,
            state.species.baseHeight *
                state.genome.bodyScale *
                state.visualScale,
          ),
          anchor: Anchor.center,
        );

  final FishState state;
  final Random _random;
  final double _baseSpeed;
  final double _wavePhase;

  double _elapsed = 0;
  double _direction = 1;
  double _feedGlow = 0;

  void celebrateFeeding() {
    _feedGlow = 1;
  }

  @override
  void onMount() {
    super.onMount();
    final tank = parent;
    if (tank is! PositionComponent) {
      return;
    }

    final usableWidth = max(1.0, tank.width - width);
    final minY = tank.height * 0.17 + height / 2;
    final maxY = max(minY + 1, tank.height * 0.81 - height / 2);

    position = Vector2(
      width / 2 + _random.nextDouble() * usableWidth,
      minY + _random.nextDouble() * (maxY - minY),
    );
    _direction = _random.nextBool() ? 1 : -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    state.tick(dt);
    _elapsed += dt;
    _feedGlow = max(0, _feedGlow - dt * 1.7);

    final targetScale = state.visualScale;
    size.setValues(
      state.species.baseWidth * state.genome.bodyScale * targetScale,
      state.species.baseHeight * state.genome.bodyScale * targetScale,
    );

    final tank = parent;
    if (tank is! PositionComponent) {
      return;
    }

    final hungerSpeed = 0.48 + state.hunger * 0.52;
    final healthSpeed = 0.4 + state.health * 0.6;
    final speed = _baseSpeed * hungerSpeed * healthSpeed;

    x += _direction * speed * dt;
    y += sin(_elapsed * 1.8 + _wavePhase) * 2.6 * dt;

    final left = width / 2;
    final right = max(left, tank.width - width / 2);
    if (x <= left) {
      x = left;
      _direction = 1;
    } else if (x >= right) {
      x = right;
      _direction = -1;
    }

    final top = tank.height * 0.14 + height / 2;
    final bottom = max(top, tank.height * 0.84 - height / 2);
    y = y.clamp(top, bottom).toDouble();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_direction < 0) {
      canvas.save();
      canvas.translate(width, 0);
      canvas.scale(-1, 1);
    }

    final genome = state.genome;
    final primary = Color(genome.primaryColor);
    final secondary = Color(genome.secondaryColor);

    final tail = Path()
      ..moveTo(width * 0.27, height * 0.49)
      ..quadraticBezierTo(
        width * 0.08,
        height * 0.17,
        0,
        height * (0.08 / genome.finScale).clamp(0.025, 0.18),
      )
      ..quadraticBezierTo(
        width * 0.08,
        height * 0.50,
        0,
        height * (0.92 + (genome.finScale - 1) * 0.07).clamp(0.82, 0.98),
      )
      ..quadraticBezierTo(
        width * 0.10,
        height * 0.80,
        width * 0.27,
        height * 0.52,
      )
      ..close();
    canvas.drawPath(tail, Paint()..color = secondary);

    final dorsal = Path()
      ..moveTo(width * 0.39, height * 0.24)
      ..quadraticBezierTo(
        width * 0.50,
        height * (0.01 / genome.finScale).clamp(0, 0.09),
        width * 0.67,
        height * 0.23,
      )
      ..close();
    canvas.drawPath(dorsal, Paint()..color = secondary);

    final ventral = Path()
      ..moveTo(width * 0.46, height * 0.75)
      ..quadraticBezierTo(
        width * 0.55,
        height * (0.98 * genome.finScale).clamp(0.84, 1.0),
        width * 0.66,
        height * 0.75,
      )
      ..close();
    canvas.drawPath(ventral, Paint()..color = secondary.withAlpha(220));

    final body = Path()
      ..moveTo(width * 0.20, height * 0.50)
      ..cubicTo(
        width * 0.31,
        height * 0.16,
        width * 0.66,
        height * 0.10,
        width * 0.91,
        height * 0.43,
      )
      ..quadraticBezierTo(
        width * 0.96,
        height * 0.50,
        width * 0.91,
        height * 0.57,
      )
      ..cubicTo(
        width * 0.66,
        height * 0.90,
        width * 0.31,
        height * 0.84,
        width * 0.20,
        height * 0.50,
      )
      ..close();

    canvas.drawPath(body, Paint()..color = primary);

    final bodyBounds = body.getBounds();
    _drawPattern(canvas, body, bodyBounds, secondary);

    final pectoral = Path()
      ..moveTo(width * 0.58, height * 0.52)
      ..quadraticBezierTo(
        width * 0.46,
        height * 0.68,
        width * 0.66,
        height * 0.68,
      )
      ..close();
    canvas.drawPath(pectoral, Paint()..color = secondary.withAlpha(185));

    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xB3162D3D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    canvas.drawOval(
      Rect.fromLTWH(
        width * 0.34,
        height * 0.23,
        width * 0.39,
        height * 0.16,
      ),
      Paint()..color = const Color(0x35FFFFFF),
    );

    if (genome.shimmer || _feedGlow > 0) {
      final alpha = genome.shimmer ? 76 : (72 * _feedGlow).round();
      canvas.drawOval(
        Rect.fromLTWH(
          width * 0.38,
          height * 0.18,
          width * 0.34,
          height * 0.13,
        ),
        Paint()..color = Color.fromARGB(alpha, 255, 255, 255),
      );
    }

    final eyeCenter = Offset(width * 0.80, height * 0.41);
    canvas.drawCircle(
      eyeCenter,
      height * 0.105,
      Paint()..color = const Color(0xFFF8FDFF),
    );
    canvas.drawCircle(
      eyeCenter,
      height * 0.050,
      Paint()..color = const Color(0xFF102331),
    );
    canvas.drawCircle(
      Offset(eyeCenter.dx + height * 0.016, eyeCenter.dy - height * 0.019),
      height * 0.015,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    canvas.drawArc(
      Rect.fromLTWH(
        width * 0.84,
        height * 0.49,
        width * 0.08,
        height * 0.10,
      ),
      0.35,
      1.15,
      false,
      Paint()
        ..color = const Color(0x99102230)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        width * 0.68,
        height * 0.31,
        width * 0.13,
        height * 0.38,
      ),
      -1.15,
      2.3,
      false,
      Paint()
        ..color = const Color(0x65102230)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    if (_direction < 0) {
      canvas.restore();
    }
  }

  void _drawPattern(
    Canvas canvas,
    Path body,
    Rect bodyRect,
    Color secondary,
  ) {
    final pattern = state.genome.pattern;
    if (pattern == FishPattern.solid) {
      return;
    }

    canvas.save();
    canvas.clipPath(body);
    final patternPaint = Paint()..color = secondary.withAlpha(190);

    if (pattern == FishPattern.stripes) {
      for (var i = 0; i < 3; i++) {
        final x = bodyRect.left + bodyRect.width * (0.25 + i * 0.19);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x,
              bodyRect.top - 2,
              bodyRect.width * 0.075,
              bodyRect.height + 4,
            ),
            const Radius.circular(3),
          ),
          patternPaint,
        );
      }
    } else if (pattern == FishPattern.spots) {
      final spots = <Offset>[
        Offset(bodyRect.left + bodyRect.width * 0.32, bodyRect.top + bodyRect.height * 0.34),
        Offset(bodyRect.left + bodyRect.width * 0.52, bodyRect.top + bodyRect.height * 0.62),
        Offset(bodyRect.left + bodyRect.width * 0.66, bodyRect.top + bodyRect.height * 0.29),
      ];
      final radii = <double>[0.12, 0.10, 0.075];
      for (var i = 0; i < spots.length; i++) {
        canvas.drawCircle(spots[i], bodyRect.height * radii[i], patternPaint);
      }
    } else if (pattern == FishPattern.patches) {
      canvas.drawOval(
        Rect.fromLTWH(
          bodyRect.left + bodyRect.width * 0.14,
          bodyRect.top - bodyRect.height * 0.08,
          bodyRect.width * 0.32,
          bodyRect.height * 0.58,
        ),
        patternPaint,
      );
      canvas.drawOval(
        Rect.fromLTWH(
          bodyRect.left + bodyRect.width * 0.53,
          bodyRect.top + bodyRect.height * 0.47,
          bodyRect.width * 0.27,
          bodyRect.height * 0.43,
        ),
        patternPaint,
      );
    }

    canvas.restore();
  }
}
