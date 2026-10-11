import 'dart:math';

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
  final ValueNotifier<int> activeTank = ValueNotifier<int>(1);

  TankScene? _tank1;
  TankScene? _tank2;
  FishState? _selectedFishState;
  double _hudTimer = 0;
  final int _coins = 250;
  int _food = 12;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final tank1 = TankScene(
      tankNumber: 1,
      backgroundAsset: 'art/tank_freshwater.webp',
      onFishSelected: _onFishSelected,
    );
    final tank2 = TankScene(
      tankNumber: 2,
      backgroundAsset: 'art/tank_tropical.webp',
      onFishSelected: _onFishSelected,
    );

    _tank1 = tank1;
    _tank2 = tank2;
    await add(tank1);
    await add(tank2);
    _layoutTanks();
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
    _layoutTanks();
  }

  bool feedFish() {
    if (_food <= 0) {
      return false;
    }

    final target = activeTank.value == 2 ? _tank2 : _tank1;
    final fed = target?.feedAll() ?? 0;
    if (fed == 0) {
      return false;
    }

    _food--;
    _publishHud();
    return true;
  }

  void _onFishSelected(FishState state, int tankNumber) {
    _selectedFishState = state;
    activeTank.value = tankNumber;
    if (tankNumber == 1) {
      _tank2?.clearSelection();
    } else {
      _tank1?.clearSelection();
    }
    selectedFish.value = FishSelection.fromState(state);
  }

  void _layoutTanks() {
    final tank1 = _tank1;
    final tank2 = _tank2;
    if (tank1 == null || tank2 == null || size.x <= 0 || size.y <= 0) {
      return;
    }

    final topReserve = (size.y * 0.15).clamp(86.0, 118.0).toDouble();
    final bottomReserve = (size.y * 0.24).clamp(132.0, 205.0).toDouble();
    final usableHeight = max(220.0, size.y - topReserve - bottomReserve);
    final gap = (usableHeight * 0.045).clamp(10.0, 18.0).toDouble();
    final maxTankHeight = max(92.0, (usableHeight - gap) / 2);
    final maxWidthFromHeight = maxTankHeight / 0.535;
    final tankWidth = max(150.0, min(size.x * 0.90, maxWidthFromHeight));
    final tankHeight = tankWidth * 0.535;
    final totalHeight = tankHeight * 2 + gap;
    final startY = topReserve + max(0.0, (usableHeight - totalHeight) / 2);
    final startX = (size.x - tankWidth) / 2;

    tank1
      ..position = Vector2(startX, startY)
      ..size = Vector2(tankWidth, tankHeight);
    tank2
      ..position = Vector2(startX, startY + tankHeight + gap)
      ..size = Vector2(tankWidth, tankHeight);
  }

  void _publishHud() {
    final first = _tank1;
    final second = _tank2;
    final count1 = first?.fishCount ?? 0;
    final count2 = second?.fishCount ?? 0;
    final totalCount = count1 + count2;

    double weightedAverage(
      double firstValue,
      int firstCount,
      double secondValue,
      int secondCount,
    ) {
      if (firstCount + secondCount == 0) {
        return 1;
      }
      return (firstValue * firstCount + secondValue * secondCount) /
          (firstCount + secondCount);
    }

    hud.value = GameHudState(
      coins: _coins,
      food: _food,
      fishCount: totalCount,
      averageHunger: weightedAverage(
        first?.averageHunger ?? 1,
        count1,
        second?.averageHunger ?? 1,
        count2,
      ),
      averageHealth: weightedAverage(
        first?.averageHealth ?? 1,
        count1,
        second?.averageHealth ?? 1,
        count2,
      ),
    );

    final selected = _selectedFishState;
    if (selected != null) {
      selectedFish.value = FishSelection.fromState(selected);
    }
  }
}
