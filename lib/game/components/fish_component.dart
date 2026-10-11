import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';

import '../models/fish_state.dart';

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
        super(
          size: Vector2(
            state.species.baseWidth * state.genome.bodyScale * state.visualScale,
            state.species.baseHeight * state.genome.bodyScale * state.visualScale,
          ),
          anchor: Anchor.center,
        );

  final FishState state;
  final void Function(FishComponent fish)? onSelected;
  final Random _random;
  final double _baseSpeed;
  final double _wavePhase;

  ui.Image? _art;
  double _elapsed = 0;
  double _direction = 1;
  double _feedGlow = 0;
  bool _selected = false;

  static const Map<String, String> _speciesArt = {
    'sunny': 'art/fish_sunny.webp',
    'zephyr': 'art/fish_zephyr.webp',
    'luna': 'art/fish_luna.webp',
    'shadow': 'art/fish_shadow.webp',
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final asset = _speciesArt[state.species.id] ?? _speciesArt['sunny']!;
    _art = await Flame.images.load(asset);
  }

  void celebrateFeeding() {
    _feedGlow = 1;
  }

  void setSelected(bool selected) {
    _selected = selected;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    const padding = 9.0;
    return point.x >= -padding &&
        point.x <= width + padding &&
        point.y >= -padding &&
        point.y <= height + padding;
  }

  @override
  void onTapDown(TapDownEvent event) {
    onSelected?.call(this);
  }

  @override
  void onMount() {
    super.onMount();
    final tank = parent;
    if (tank is! PositionComponent) {
      return;
    }

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
    // FishState time is advanced by AguaLifeGame for every tank, including
    // tanks that are not currently rendered. This component is presentation
    // only, so switching screens cannot pause another tank's simulation.
    _elapsed += dt;
    _feedGlow = max(0, _feedGlow - dt * 1.7);

    final targetScale = state.visualScale;
    size.setValues(
      state.species.baseWidth * state.genome.bodyScale * targetScale,
      state.species.baseHeight * state.genome.bodyScale * targetScale,
    );

    if (!state.alive) {
      return;
    }

    final tank = parent;
    if (tank is! PositionComponent) {
      return;
    }

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
          ..color = ui.Color.fromARGB(
            (165 * pulse).round(),
            92,
            232,
            255,
          )
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final art = _art;
    if (art == null) {
      return;
    }

    canvas.save();
    if (_direction < 0) {
      canvas.translate(width, 0);
      canvas.scale(-1, 1);
    }

    final bob = sin(_elapsed * 4.2 + _wavePhase) * 0.6;
    canvas.translate(0, bob);

    canvas.drawImageRect(
      art,
      ui.Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );

    if (state.genome.shimmer || _feedGlow > 0) {
      final alpha = state.genome.shimmer ? 85 : (80 * _feedGlow).round();
      canvas.drawOval(
        ui.Rect.fromLTWH(width * 0.28, height * 0.05, width * 0.48, height * 0.25),
        ui.Paint()..color = ui.Color.fromARGB(alpha, 255, 255, 255),
      );
    }

    canvas.restore();
  }
}
