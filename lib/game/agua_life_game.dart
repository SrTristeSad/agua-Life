import 'package:flame/game.dart';

import 'components/tank_scene.dart';

class AguaLifeGame extends FlameGame {
  TankScene? _tankScene;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final tankScene = TankScene()..size = size;
    _tankScene = tankScene;
    await add(tankScene);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    _tankScene?.size = newSize;
  }
}
