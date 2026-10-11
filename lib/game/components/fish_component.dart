import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';

import '../models/fish_disease.dart';
import '../models/fish_state.dart';

/// Animated pixel-art fish renderer.
///
/// Gameplay still uses all 21 x 21 legacy body/fin combinations. The current
/// production art maps those combinations onto ten visual families while the
/// original simulation data remains untouched.
class FishComponent extends PositionComponent with TapCallbacks {
  FishComponent({
    required this.state,
    required Random random,
    this.onSelected,
  })  : _random = random,
        _baseSpeed = state.species.minSpeed +
            random.nextDouble() *
                (state.species.maxSpeed - state.species.minSpeed),
        _wavePhase = random.nextDouble() * pi * 2,
        _animationOffset = random.nextInt(_swimFrameCount),
        super(
          size: Vector2(
            state.species.baseWidth * state.genome.bodyScale * state.visualScale,
            state.species.baseHeight * state.genome.bodyScale * state.visualScale,
          ),
          anchor: Anchor.center,
        );

  static const int _swimFrameCount = 6;
  static const int _eatFrameCount = 3;
  static const int _babyFrameCount = 4;
  static const double _frameWidth = 16;
  static const double _frameHeight = 12;

  final FishState state;
  final void Function(FishComponent fish)? onSelected;
  final Random _random;
  final double _baseSpeed;
  final double _wavePhase;
  final int _animationOffset;

  ui.Image? _swimArt;
  ui.Image? _eatArt;
  ui.Image? _babyArt;
  int _atlasRow = 0;
  double _elapsed = 0;
  double _direction = 1;
  double _feedGlow = 0;
  double _feedAnimation = 0;
  bool _selected = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final visualIndex = (state.bodyIndex * 3 + state.finIndex) % 10;
    _atlasRow = visualIndex % 5;
    final suffix = visualIndex < 5 ? 'a' : 'b';
    _swimArt = await Flame.images.load('pixel/fish_swim_$suffix.png');
    _eatArt = await Flame.images.load('pixel/fish_eat_$suffix.png');
    _babyArt = await Flame.images.load('pixel/fish_baby_$suffix.png');
  }

  void celebrateFeeding() {
    _feedGlow = 1;
    _feedAnimation = 0.72;
  }

  void setSelected(bool selected) => _selected = selected;

  @override
  bool containsLocalPoint(Vector2 point) {
    const padding = 9.0;
    return point.x >= -padding &&
        point.x <= width + padding &&
        point.y >= -padding &&
        point.y <= height + padding;
  }

  @override
  void onTapDown(TapDownEvent event) => onSelected?.call(this);

  @override
  void onMount() {
    super.onMount();
    final tank = parent;
    if (tank is! PositionComponent) return;

    final usableWidth = max(1.0, tank.width - width * 1.6);
    final minY = tank.height * 0.22 + height / 2;
    final maxY = max(minY + 1, tank.height * 0.76 - height / 2);
    position = Vector2(
      width * 0.8 + _random.nextDouble() * usableWidth,
      minY + _random.nextDouble() * (maxY - minY),
    );
    _direction = _random.nextBool() ? 1 : -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _feedGlow = max(0, _feedGlow - dt * 1.7);
    _feedAnimation = max(0, _feedAnimation - dt);

    final targetScale = state.visualScale;
    size.setValues(
      state.species.baseWidth * state.genome.bodyScale * targetScale,
      state.species.baseHeight * state.genome.bodyScale * targetScale,
    );

    if (!state.alive) return;
    final tank = parent;
    if (tank is! PositionComponent) return;

    final hungerSpeed = 0.48 + state.hunger * 0.52;
    final healthSpeed = 0.4 + state.health * 0.6;
    final speed = _baseSpeed * hungerSpeed * healthSpeed;
    x += _direction * speed * dt;
    y += sin(_elapsed * 1.9 + _wavePhase) * 2.4 * dt;

    final left = width * 0.75;
    final right = max(left, tank.width - width * 0.75);
    if (x <= left) {
      x = left;
      _direction = 1;
    } else if (x >= right) {
      x = right;
      _direction = -1;
    }

    final top = tank.height * 0.20 + height / 2;
    final bottom = max(top, tank.height * 0.77 - height / 2);
    y = y.clamp(top, bottom).toDouble();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    if (_selected) {
      final pulse = 0.62 + sin(_elapsed * 5) * 0.18;
      canvas.drawOval(
        ui.Rect.fromLTWH(-5, -5, width + 10, height + 10),
        ui.Paint()
          ..color = ui.Color.fromARGB((165 * pulse).round(), 92, 232, 255)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final animation = _animationForState();
    final art = animation.$1;
    if (art == null) return;

    canvas.save();
    if (_direction < 0) {
      canvas.translate(width, 0);
      canvas.scale(-1, 1);
    }

    final bob = sin(_elapsed * 4.2 + _wavePhase) * 0.6;
    canvas.translate(0, bob);

    final frameCount = animation.$2;
    final framesPerSecond = animation.$3;
    final frame = ((_elapsed * framesPerSecond).floor() + _animationOffset) %
        frameCount;
    final source = ui.Rect.fromLTWH(
      frame * _frameWidth,
      _atlasRow * _frameHeight,
      _frameWidth,
      _frameHeight,
    );
    canvas.drawImageRect(
      art,
      source,
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );

    _renderDisease(canvas);
    if (state.genome.shimmer || _feedGlow > 0) {
      final alpha = state.genome.shimmer ? 85 : (80 * _feedGlow).round();
      canvas.drawOval(
        ui.Rect.fromLTWH(width * 0.28, height * 0.05, width * 0.48, height * 0.25),
        ui.Paint()..color = ui.Color.fromARGB(alpha, 255, 255, 255),
      );
    }
    canvas.restore();
  }

  (ui.Image?, int, double) _animationForState() {
    if (!state.isAdult) {
      return (_babyArt ?? _swimArt, _babyFrameCount, 7.0);
    }
    if (_feedAnimation > 0) {
      return (_eatArt ?? _swimArt, _eatFrameCount, 9.0);
    }
    return (_swimArt, _swimFrameCount, 6.0);
  }

  void _renderDisease(ui.Canvas canvas) {
    switch (state.disease) {
      case FishDisease.none:
        return;
      case FishDisease.ich:
        final paint = ui.Paint()..color = const ui.Color(0xF5F7FFFF);
        final radius = max(0.9, width * 0.025);
        const points = <(double, double)>[
          (0.30, 0.33),
          (0.43, 0.58),
          (0.56, 0.28),
          (0.66, 0.52),
          (0.76, 0.38),
          (0.51, 0.72),
        ];
        for (final point in points) {
          canvas.drawCircle(
            ui.Offset(width * point.$1, height * point.$2),
            radius,
            paint,
          );
        }
      case FishDisease.fungus:
        final outer = ui.Paint()..color = const ui.Color(0xD04F8F38);
        final inner = ui.Paint()..color = const ui.Color(0xD078C65A);
        final blobs = <ui.Offset>[
          ui.Offset(width * 0.42, height * 0.30),
          ui.Offset(width * 0.50, height * 0.25),
          ui.Offset(width * 0.56, height * 0.33),
          ui.Offset(width * 0.48, height * 0.39),
        ];
        for (var i = 0; i < blobs.length; i++) {
          final radius = max(1.2, width * (0.045 - i * 0.004));
          canvas.drawCircle(blobs[i], radius + 0.7, outer);
          canvas.drawCircle(blobs[i], radius, inner);
        }
    }
  }
}
