import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../models/fish_state.dart';
import 'fish_component.dart';
import 'food_flake.dart';

class TankScene extends PositionComponent {
  TankScene({
    required this.tankNumber,
    required this.backgroundAsset,
    required List<FishState> fishStates,
    this.onFishFocused,
  }) : _fishStates = fishStates;

  final int tankNumber;
  final String backgroundAsset;
  final List<FishState> _fishStates;
  final void Function(FishState? state)? onFishFocused;

  final Random _random = Random(260211);
  final List<FishComponent> _fish = <FishComponent>[];
  final List<FoodFlake> _food = <FoodFlake>[];

  ui.Image? _background;
  bool _pixelBackground = false;
  int _focusedIndex = -1;
  bool _browsingEnabled = false;

  int get fishCount => _fish.where((fish) => fish.state.alive).length;
  List<FishState> get fishStates => List.unmodifiable(_fishStates);
  FishState? get focusedFish =>
      _focusedIndex >= 0 && _focusedIndex < _fish.length
          ? _fish[_focusedIndex].state
          : null;

  double get averageHunger => _averageOf((fish) => fish.state.hunger);
  double get averageHealth => _averageOf((fish) => fish.state.health);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Tank 1 now uses the production pixel-art aquarium. Tank 2 keeps the
    // previous art until its dedicated atlas is imported, so a missing visual
    // asset can never stop the game from loading.
    if (tankNumber == 1) {
      try {
        _background = await Flame.images.load('pixel/tank_main.png');
        _pixelBackground = true;
      } catch (_) {
        _background = await Flame.images.load(backgroundAsset);
      }
    } else {
      _background = await Flame.images.load(backgroundAsset);
    }

    for (final state in _fishStates) {
      await _addFishComponent(state);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _resolveFoodEating();
  }

  Future<void> _addFishComponent(FishState state) async {
    final component = FishComponent(
      state: state,
      random: _random,
      onSelected: _focusByTap,
    );
    _fish.add(component);
    await add(component);
  }

  void beginBrowsing() {
    _browsingEnabled = true;
    final living = _livingFish();
    if (living.isEmpty) {
      _focusedIndex = -1;
      onFishFocused?.call(null);
      return;
    }

    if (_focusedIndex < 0 ||
        _focusedIndex >= _fish.length ||
        !_fish[_focusedIndex].state.alive) {
      _focusedIndex = _fish.indexOf(living.first);
    }
    _applyFocus();
  }

  void browse(int delta) {
    final living = _livingFish();
    if (living.isEmpty) return;

    final current = focusedFish;
    var index = current == null
        ? 0
        : living.indexWhere((f) => identical(f.state, current));
    if (index < 0) index = 0;
    index = (index + delta) % living.length;
    if (index < 0) index += living.length;
    _focusedIndex = _fish.indexOf(living[index]);
    _applyFocus();
  }

  void lockFocus() {
    _browsingEnabled = false;
  }

  void clearFocus() {
    _browsingEnabled = false;
    _focusedIndex = -1;
    for (final fish in _fish) {
      fish.setSelected(false);
    }
    onFishFocused?.call(null);
  }

  FishState? removeFocusedFish() {
    if (_focusedIndex < 0 || _focusedIndex >= _fish.length) return null;
    final component = _fish.removeAt(_focusedIndex);
    final state = component.state;
    _fishStates.remove(state);
    component.removeFromParent();
    _focusedIndex = -1;
    _applyFocus();
    return state;
  }

  Future<void> addFish(FishState state) async {
    if (!_fishStates.contains(state)) {
      _fishStates.add(state);
    }
    await _addFishComponent(state);
  }

  int dropFood() {
    final living = _livingFish();
    if (living.isEmpty) return 0;

    for (var i = 0; i < 12; i++) {
      final flake = FoodFlake(
        start: Vector2(
          width * (0.08 + _random.nextDouble() * 0.84),
          height * (0.10 + _random.nextDouble() * 0.04),
        ),
        random: _random,
      );
      _food.add(flake);
      add(flake);
    }
    return 12;
  }

  void _resolveFoodEating() {
    if (_food.isEmpty || _fish.isEmpty) return;

    _food.removeWhere((flake) => flake.parent == null || flake.consumed);
    final living = _livingFish();
    if (living.isEmpty) return;

    for (final flake in List<FoodFlake>.from(_food)) {
      if (flake.consumed || flake.parent == null) continue;

      FishComponent? eater;
      var bestDistance = double.infinity;
      for (final fish in living) {
        final distance = fish.position.distanceTo(flake.position);
        final biteDistance = max(9.0, fish.width * 0.42);
        if (distance <= biteDistance && distance < bestDistance) {
          bestDistance = distance;
          eater = fish;
        }
      }

      if (eater != null) {
        eater.state.feed(0.075);
        eater.celebrateFeeding();
        flake.consume();
      }
    }
  }

  void _focusByTap(FishComponent selected) {
    if (!_browsingEnabled) return;
    final index = _fish.indexOf(selected);
    if (index < 0) return;
    _focusedIndex = index;
    _applyFocus();
  }

  void _applyFocus() {
    for (var i = 0; i < _fish.length; i++) {
      _fish[i].setSelected(i == _focusedIndex);
    }
    onFishFocused?.call(focusedFish);
  }

  List<FishComponent> _livingFish() =>
      _fish.where((fish) => fish.state.alive).toList(growable: false);

  double _averageOf(double Function(FishComponent fish) read) {
    final living = _livingFish();
    if (living.isEmpty) return 0;
    return living.fold<double>(0, (sum, fish) => sum + read(fish)) /
        living.length;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    final background = _background;
    if (background == null) {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, width, height),
        ui.Paint()..color = const ui.Color(0xFF158EC0),
      );
      return;
    }

    final sourceWidth = background.width.toDouble();
    final sourceHeight = background.height.toDouble();
    final targetRatio = width / height;
    final sourceRatio = sourceWidth / sourceHeight;

    late ui.Rect source;
    if (sourceRatio > targetRatio) {
      final wantedWidth = sourceHeight * targetRatio;
      source = ui.Rect.fromLTWH(
        (sourceWidth - wantedWidth) / 2,
        0,
        wantedWidth,
        sourceHeight,
      );
    } else {
      final wantedHeight = sourceWidth / targetRatio;
      source = ui.Rect.fromLTWH(
        0,
        (sourceHeight - wantedHeight) / 2,
        sourceWidth,
        wantedHeight,
      );
    }

    canvas.drawImageRect(
      background,
      source,
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()
        ..filterQuality =
            _pixelBackground ? ui.FilterQuality.none : ui.FilterQuality.high,
    );

    // Pixel aquarium art already contains its own glass frame, lid, substrate,
    // plants and shadows. Do not cover it with the old procedural frame.
    if (_pixelBackground) return;

    final framePaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, 0),
        ui.Offset(0, height * 0.13),
        const [ui.Color(0xFF182B3B), ui.Color(0xFF07121D)],
      );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(0, 0, width, height * 0.115),
        ui.Radius.circular(width * 0.025),
      ),
      framePaint,
    );
    canvas.drawRect(
      ui.Rect.fromLTWH(0, height * 0.93, width, height * 0.07),
      ui.Paint()..color = const ui.Color(0xFF0A1824),
    );

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          const ui.Offset(0, 0),
          ui.Offset(width, height),
          const [
            ui.Color(0x20FFFFFF),
            ui.Color(0x00000000),
            ui.Color(0x1400B8E6),
          ],
        ),
    );
  }
}
