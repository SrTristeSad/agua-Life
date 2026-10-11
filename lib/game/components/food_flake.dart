import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

class FoodFlake extends PositionComponent {
  FoodFlake({
    required Vector2 start,
    required Random random,
  })  : _speed = 18 + random.nextDouble() * 18,
        _phase = random.nextDouble() * pi * 2,
        _drift = 2 + random.nextDouble() * 4,
        super(
          position: start,
          size: Vector2(4, 2.4),
          anchor: Anchor.center,
        );

  final double _speed;
  final double _phase;
  final double _drift;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    y += _speed * dt;
    x += sin(_elapsed * 2.8 + _phase) * _drift * dt;

    final tank = parent;
    if (tank is PositionComponent && y > tank.height * 0.86) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawOval(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = const Color(0xFFD98A38),
    );
    canvas.drawOval(
      Rect.fromLTWH(width * 0.15, height * 0.12, width * 0.5, height * 0.35),
      Paint()..color = const Color(0x55FFFFFF),
    );
  }
}
