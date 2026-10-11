import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../models/fish_genome.dart';
import '../models/fish_species.dart';

class FishComponent extends PositionComponent {
  FishComponent({
    required this.species,
    required this.genome,
    required Random random,
  })  : _random = random,
        _speed = species.minSpeed +
            random.nextDouble() * (species.maxSpeed - species.minSpeed),
        _wavePhase = random.nextDouble() * pi * 2,
        super(
          size: Vector2(
            species.baseWidth * genome.bodyScale,
            species.baseHeight * genome.bodyScale,
          ),
          anchor: Anchor.center,
        );

  final FishSpecies species;
  final FishGenome genome;
  final Random _random;
  final double _speed;
  final double _wavePhase;

  double _elapsed = 0;
  double _direction = 1;

  @override
  void onMount() {
    super.onMount();
    final tank = parent;
    if (tank is! PositionComponent) {
      return;
    }

    final usableWidth = max(1.0, tank.width - width);
    final minY = tank.height * 0.18 + height / 2;
    final maxY = max(minY + 1.0, tank.height * 0.82 - height / 2);

    position = Vector2(
      width / 2 + _random.nextDouble() * usableWidth,
      minY + _random.nextDouble() * (maxY - minY),
    );
    _direction = _random.nextBool() ? 1 : -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    final tank = parent;
    if (tank is! PositionComponent) {
      return;
    }

    x += _direction * _speed * dt;
    y += sin(_elapsed * 1.7 + _wavePhase) * 2.4 * dt;

    final left = width / 2;
    final right = max(left, tank.width - width / 2);
    if (x <= left) {
      x = left;
      _direction = 1;
    } else if (x >= right) {
      x = right;
      _direction = -1;
    }

    final top = tank.height * 0.15 + height / 2;
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

    final primary = Color(genome.primaryColor);
    final secondary = Color(genome.secondaryColor);
    final bodyRect = Rect.fromLTWH(
      width * 0.20,
      height * 0.13,
      width * 0.68,
      height * 0.74,
    );

    final tailTop = (0.08 / genome.finScale).clamp(0.02, 0.2).toDouble();
    final tailBottom =
        (0.92 + (genome.finScale - 1) * 0.08).clamp(0.8, 0.98).toDouble();
    final tail = Path()
      ..moveTo(width * 0.25, height * 0.50)
      ..lineTo(0, height * tailTop)
      ..lineTo(0, height * tailBottom)
      ..close();
    canvas.drawPath(tail, Paint()..color = secondary);

    final dorsalTop =
        (0.02 / genome.finScale).clamp(0.0, 0.1).toDouble();
    final dorsal = Path()
      ..moveTo(width * 0.38, height * 0.20)
      ..lineTo(width * 0.54, height * dorsalTop)
      ..lineTo(width * 0.67, height * 0.22)
      ..close();
    canvas.drawPath(dorsal, Paint()..color = secondary);

    canvas.drawOval(bodyRect, Paint()..color = primary);
    _drawPattern(canvas, bodyRect, secondary);

    if (genome.shimmer) {
      canvas.drawOval(
        Rect.fromLTWH(
          bodyRect.left + bodyRect.width * 0.15,
          bodyRect.top + bodyRect.height * 0.12,
          bodyRect.width * 0.52,
          bodyRect.height * 0.22,
        ),
        Paint()..color = const Color(0xFFFFFFFF).withAlpha(70),
      );
    }

    canvas.drawOval(
      bodyRect,
      Paint()
        ..color = const Color(0xAA102A43)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final eyeCenter = Offset(width * 0.76, height * 0.40);
    canvas.drawCircle(
      eyeCenter,
      height * 0.095,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawCircle(
      eyeCenter,
      height * 0.045,
      Paint()..color = const Color(0xFF132238),
    );

    if (_direction < 0) {
      canvas.restore();
    }
  }

  void _drawPattern(Canvas canvas, Rect bodyRect, Color secondary) {
    if (genome.pattern == FishPattern.solid) {
      return;
    }

    canvas.save();
    canvas.clipPath(Path()..addOval(bodyRect));
    final patternPaint = Paint()..color = secondary.withAlpha(190);

    switch (genome.pattern) {
      case FishPattern.solid:
        break;
      case FishPattern.stripes:
        for (var i = 0; i < 3; i++) {
          final x = bodyRect.left + bodyRect.width * (0.28 + i * 0.18);
          canvas.drawRect(
            Rect.fromLTWH(
              x,
              bodyRect.top,
              bodyRect.width * 0.08,
              bodyRect.height,
            ),
            patternPaint,
          );
        }
        break;
      case FishPattern.spots:
        canvas.drawCircle(
          Offset(
            bodyRect.left + bodyRect.width * 0.35,
            bodyRect.top + bodyRect.height * 0.35,
          ),
          bodyRect.height * 0.12,
          patternPaint,
        );
        canvas.drawCircle(
          Offset(
            bodyRect.left + bodyRect.width * 0.56,
            bodyRect.top + bodyRect.height * 0.62,
          ),
          bodyRect.height * 0.10,
          patternPaint,
        );
        canvas.drawCircle(
          Offset(
            bodyRect.left + bodyRect.width * 0.68,
            bodyRect.top + bodyRect.height * 0.30,
          ),
          bodyRect.height * 0.08,
          patternPaint,
        );
        break;
      case FishPattern.patches:
        canvas.drawOval(
          Rect.fromLTWH(
            bodyRect.left + bodyRect.width * 0.20,
            bodyRect.top - bodyRect.height * 0.05,
            bodyRect.width * 0.30,
            bodyRect.height * 0.55,
          ),
          patternPaint,
        );
        canvas.drawOval(
          Rect.fromLTWH(
            bodyRect.left + bodyRect.width * 0.55,
            bodyRect.top + bodyRect.height * 0.48,
            bodyRect.width * 0.28,
            bodyRect.height * 0.42,
          ),
          patternPaint,
        );
        break;
    }

    canvas.restore();
  }
}
