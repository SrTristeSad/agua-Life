import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/agua_life_game.dart';
import 'game/models/fish_selection.dart';
import 'game/models/legacy_action.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AguaLifeApp());
}

class AguaLifeApp extends StatelessWidget {
  const AguaLifeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Agua Life',
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: const AguaLifeScreen(),
      );
}

class AguaLifeScreen extends StatefulWidget {
  const AguaLifeScreen({super.key});

  @override
  State<AguaLifeScreen> createState() => _AguaLifeScreenState();
}

class _AguaLifeScreenState extends State<AguaLifeScreen> {
  late final AguaLifeGame game = AguaLifeGame();
  bool menuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061321),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B2E4D), Color(0xFF06111E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 352,
                  height: 416,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameWidget(game: game),
                      Positioned(
                        left: 0,
                        top: 0,
                        width: 352,
                        height: 56,
                        child: _topBar(),
                      ),
                      Positioned(
                        left: 104,
                        top: 316,
                        width: 144,
                        height: 68,
                        child: _isolation(),
                      ),
                      Positioned(
                        left: 0,
                        top: 384,
                        width: 352,
                        height: 32,
                        child: _softKeys(),
                      ),
                      if (menuOpen) Positioned.fill(child: _menu()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        game.fishMode,
        game.action,
        game.focusedFish,
        game.isolationFish,
        game.currentTankNumber,
        game.hud,
      ]),
      builder: (context, _) {
        if (game.fishMode.value == FishInteractionMode.browsing) {
          final fish = game.focusedFish.value;
          final age = fish?.age ?? 0;
          final fed = ((fish?.hunger ?? 0) * 100).round();
          final health = ((fish?.health ?? 0) * 100).round();
          return _bar(
            Row(
              children: [
                _arrow(Icons.chevron_left_rounded, () => game.browseFish(-1)),
                Expanded(
                  flex: 3,
                  child: _stat(fish?.speciesName ?? 'NO FISH', 'AGE $age'),
                ),
                Expanded(child: _stat('FED', '$fed%')),
                Expanded(child: _stat('HEALTH', '$health%')),
                _arrow(Icons.chevron_right_rounded, () => game.browseFish(1)),
              ],
            ),
          );
        }

        final selected = game.fishMode.value == FishInteractionMode.selected;
        final actions = selected
            ? <LegacyAction>[
                LegacyAction.moveTank,
                LegacyAction.species,
                game.isolationFish.value == null
                    ? LegacyAction.isolate
                    : LegacyAction.breed,
                LegacyAction.trash,
                if (game.isolationFish.value != null) LegacyAction.release,
              ]
            : <LegacyAction>[
                LegacyAction.food,
                LegacyAction.shop,
                LegacyAction.switchTank,
                LegacyAction.saleTank,
              ];

        return _bar(
          Row(
            children: [
              SizedBox(
                width: 58,
                child: Center(
                  child: Text(
                    selected
                        ? (game.focusedFish.value?.speciesName ?? 'FISH')
                        : 'T${game.currentTankNumber.value}',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: actions
                      .map((a) => _actionSlot(
                            a,
                            badge: a == LegacyAction.food
                                ? '${game.hud.value.food}'
                                : null,
                          ))
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(Widget child) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF35205F), Color(0xFF241641)],
          ),
          border: Border(bottom: BorderSide(color: Color(0xFF6C57A7), width: 2)),
        ),
        child: child,
      );

  Widget _actionSlot(LegacyAction action, {String? badge}) {
    final data = switch (action) {
      LegacyAction.food => (Icons.set_meal_rounded, 'FOOD'),
      LegacyAction.shop => (Icons.shopping_cart_rounded, 'SHOP'),
      LegacyAction.switchTank => (Icons.swap_horiz_rounded, 'TANK'),
      LegacyAction.saleTank => (Icons.sell_rounded, 'SALE'),
      LegacyAction.moveTank => (Icons.move_down_rounded, 'MOVE'),
      LegacyAction.species => (Icons.info_outline_rounded, 'SPECIES'),
      LegacyAction.isolate => (Icons.inventory_2_outlined, 'ISOLATE'),
      LegacyAction.release => (Icons.outbox_rounded, 'RELEASE'),
      LegacyAction.breed => (Icons.favorite_rounded, 'BREED'),
      LegacyAction.trash => (Icons.delete_outline_rounded, 'TRASH'),
    };
    final active = game.action.value == action;
    return InkWell(
      onTap: () => game.chooseAction(action),
      child: Container(
        width: 47,
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF633AA5) : Colors.transparent,
          border: Border.all(
            color: active ? const Color(0xFF8BF0FF) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.$1, size: 20),
                  Text(data.$2,
                      style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                right: 1,
                top: 1,
                child: Text(badge,
                    style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String title, String value) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8, color: Color(0xFFBEAEE9))),
          Text(value,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      );

  Widget _arrow(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 34,
          child: Icon(icon, size: 27, color: const Color(0xFF75E7FF)),
        ),
      );

  Widget _isolation() {
    return ValueListenableBuilder<FishSelection?>(
      valueListenable: game.isolationFish,
      builder: (context, fish, _) => GestureDetector(
        onTap: fish == null ? null : game.selectIsolation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/art/tank_freshwater.webp',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 14,
              child: ColoredBox(color: Color(0xFF101F2E)),
            ),
            if (fish != null)
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.34,
                  heightFactor: 0.52,
                  child: Image.asset(
                    _visualAssetForBreed(fish),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (fish?.pregnant == true)
              const Positioned(
                right: 5,
                top: 17,
                child: Icon(
                  Icons.egg_alt_rounded,
                  size: 16,
                  color: Color(0xFFFFF3A0),
                ),
              ),
            Positioned(
              left: 3,
              right: 3,
              bottom: 2,
              child: Text(
                fish == null
                    ? 'ISOLATION'
                    : fish.pregnant
                        ? 'PREGNANT  ${fish.pregnancyAgesRemaining}/3'
                        : fish.speciesName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _visualAssetForBreed(FishSelection fish) {
    final key = (fish.bodyIndex * 3 + fish.finIndex) % 4;
    return switch (key) {
      0 => 'assets/images/art/fish_sunny.webp',
      1 => 'assets/images/art/fish_zephyr.webp',
      2 => 'assets/images/art/fish_luna.webp',
      _ => 'assets/images/art/fish_shadow.webp',
    };
  }

  Widget _softKeys() {
    return ValueListenableBuilder<FishInteractionMode>(
      valueListenable: game.fishMode,
      builder: (context, mode, _) {
        return ColoredBox(
          color: const Color(0xFF17142A),
          child: Row(
            children: [
              Expanded(
                child: _soft(
                  mode == FishInteractionMode.none ? 'MENU' : 'BACK',
                  mode == FishInteractionMode.none
                      ? () => setState(() => menuOpen = true)
                      : game.cancelFishInteraction,
                ),
              ),
              Expanded(
                child: _soft(
                  mode == FishInteractionMode.browsing ? 'SELECT' : 'ACTION',
                  _handleAction,
                  active: true,
                ),
              ),
              Expanded(child: _soft('FISH', game.enterFishBrowse)),
            ],
          ),
        );
      },
    );
  }

  Widget _soft(String text, VoidCallback onTap, {bool active = false}) => InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          color: active ? const Color(0xFF282049) : Colors.transparent,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: active ? const Color(0xFF85EDFF) : Colors.white,
            ),
          ),
        ),
      );

  Widget _menu() {
    const items = [
      'RESUME',
      'START NEW GAME',
      'OPTIONS',
      'TROPHY',
      'STATS',
      'HELP',
      'ABOUT',
      'SAVE & EXIT',
    ];
    return Material(
      color: const Color(0xD0000710),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.67,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF3A226B),
              border: Border.all(color: const Color(0xFFA592D4), width: 2),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items
                  .map((item) => InkWell(
                        onTap: item == 'RESUME'
                            ? () => setState(() => menuOpen = false)
                            : null,
                        child: SizedBox(
                          height: 28,
                          child: Center(
                            child: Text(item,
                                style: const TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ))
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction() async {
    final before = game.action.value;
    final ok = await game.pressAction();
    if (!mounted) return;

    final message = game.eventMessage.value;
    if (message != null) {
      game.clearEventMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ação indisponível.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (before == LegacyAction.species) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(game.focusedFish.value?.speciesName ?? 'SPECIES'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
