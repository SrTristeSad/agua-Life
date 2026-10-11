import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'components/tank_scene.dart';
import 'models/fish_selection.dart';
import 'models/fish_state.dart';
import 'models/game_hud_state.dart';

class AguaLifeGame extends FlameGame {
  final ValueNotifier<GameHudState> hud =
      ValueNotifier<GameHudState>(GameHudState.empty);
  final ValueNotifier<FishSelection?> selectedFish =
      ValueNotifier<FishSelection?>(null);

  TankScene? _tankScene;
  FishState? _selectedFishState;
  double _hudTimer = 0;
  final int _coins = 250;
  int _food = 12;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final tankScene = TankScene(onFishSelected: _onFishSelected)..size = size;
    _tankScene = tankScene;
    await add(tankScene);
    _publishHud();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _hudTimer += dt;
    if (_hudTimer >= 0.2) {
      _hudTimer = 0;
      _publishHud();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _tankScene?.size = size;
  }

  bool feedFish() {
    if (_food <= 0) {
      return false;
    }

    final fed = _tankScene?.feedAll() ?? 0;
    if (fed == 0) {
      return false;
    }

    _food--;
    _publishHud();
    return true;
  }

  void _onFishSelected(FishState state) {
    _selectedFishState = state;
    selectedFish.value = FishSelection.fromState(state);
  }

  void _publishHud() {
    final tank = _tankScene;
    hud.value = GameHudState(
      coins: _coins,
      food: _food,
      fishCount: tank?.fishCount ?? 0,
      averageHunger: tank?.averageHunger ?? 1,
      averageHealth: tank?.averageHealth ?? 1,
    );

    final selected = _selectedFishState;
    if (selected != null) {
      selectedFish.value = FishSelection.fromState(selected);
    }
  }
}
