import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/agua_life_game.dart';
import 'game/data/legacy_supply_catalog.dart';
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
  bool suppliesOpen = false;
  int supplyIndex = 0;
  LegacySupply? replaceConfirmation;

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
                      if (suppliesOpen) Positioned.fill(child: _supplies()),
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
        game.supplyRevision,
        game.selectedSupply,
      ]),
      builder: (context, _) {
        if (game.fishMode.value == FishInteractionMode.browsing) {
          final fish = game.focusedFish.value;
          final age = fish?.age ?? 0;
          final fed = ((fish?.hunger ?? 0) * 100).round();
          final health = ((fish?.health ?? 0) * 100).round();
          final healthText = fish?.isSick == true
              ? '$health% ${fish!.diseaseLabel}'
              : '$health%';
          return _bar(
            Row(
              children: [
                _arrow(Icons.chevron_left_rounded, () => game.browseFish(-1)),
                Expanded(
                  flex: 3,
                  child: _stat(fish?.speciesName ?? 'NO FISH', 'AGE $age'),
                ),
                Expanded(child: _stat('FED', '$fed%')),
                Expanded(child: _stat('HEALTH', healthText)),
                _arrow(Icons.chevron_right_rounded, () => game.browseFish(1)),
              ],
            ),
          );
        }

        final selected = game.fishMode.value == FishInteractionMode.selected;
        if (selected) {
          final actions = <LegacyAction>[
            LegacyAction.moveTank,
            LegacyAction.species,
            game.isolationFish.value == null
                ? LegacyAction.isolate
                : LegacyAction.breed,
            LegacyAction.trash,
            if (game.isolationFish.value != null) LegacyAction.release,
          ];
          return _bar(
            Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Center(
                    child: Text(
                      game.focusedFish.value?.speciesName ?? 'FISH',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: actions
                        .map((a) => _actionSlot(a, width: 47))
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          );
        }

        return _bar(
          Row(
            children: [
              SizedBox(
                width: 46,
                child: Center(
                  child: Text(
                    'T${game.currentTankNumber.value}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionSlot(
                      LegacyAction.food,
                      badge: '${game.hud.value.food}',
                      width: 42,
                    ),
                    _actionSlot(LegacyAction.shop, width: 42),
                    _actionSlot(LegacyAction.switchTank, width: 42),
                    _actionSlot(LegacyAction.saleTank, width: 42),
                    ...game.equippedSupplies
                        .map((supply) => _supplyActionSlot(supply)),
                  ],
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
          border: Border(
            bottom: BorderSide(color: Color(0xFF6C57A7), width: 2),
          ),
        ),
        child: child,
      );

  Widget _actionSlot(
    LegacyAction action, {
    String? badge,
    double width = 47,
  }) {
    final data = switch (action) {
      LegacyAction.food => (Icons.set_meal_rounded, 'FOOD'),
      LegacyAction.shop => (Icons.shopping_cart_rounded, 'SHOP'),
      LegacyAction.switchTank => (Icons.swap_horiz_rounded, 'TANK'),
      LegacyAction.saleTank => (Icons.sell_rounded, 'SALE'),
      LegacyAction.useSupply => (Icons.medication_rounded, 'ITEM'),
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
        width: width,
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
                  Icon(data.$1, size: 19),
                  Text(
                    data.$2,
                    style: const TextStyle(
                      fontSize: 6.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                right: 1,
                top: 1,
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _supplyActionSlot(LegacySupply supply) {
    final definition = LegacySupplyCatalog.of(supply);
    final active = game.action.value == LegacyAction.useSupply &&
        game.selectedSupply.value == supply;
    return InkWell(
      onTap: () => game.selectSupplyAction(supply),
      child: Container(
        width: 42,
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
                  Icon(_supplyIcon(supply), size: 18),
                  Text(
                    definition.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      fontSize: 5.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 1,
              top: 1,
              child: Text(
                '${game.dosesFor(supply)}',
                style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _supplyIcon(LegacySupply supply) => switch (supply) {
        LegacySupply.ichTreatment => Icons.water_drop_outlined,
        LegacySupply.fungalTreatment => Icons.medication_liquid_rounded,
        LegacySupply.fishVitamins => Icons.health_and_safety_rounded,
        LegacySupply.growthHormone => Icons.trending_up_rounded,
        LegacySupply.unknownChemical => Icons.science_rounded,
      };

  Widget _stat(String title, String value) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, color: Color(0xFFBEAEE9)),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
          ),
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
            if (fish?.isSick == true)
              Positioned(
                left: 5,
                top: 17,
                child: Text(
                  fish!.diseaseLabel,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFF0A8),
                  ),
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
                        ? 'PREGNANT'
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

  Widget _supplies() {
    final supply = LegacySupply.values[supplyIndex];
    final definition = LegacySupplyCatalog.of(supply);
    final occupant = game.occupyingSupplyFor(supply);
    final slotText = occupant == null
        ? 'SLOT EMPTY'
        : '${LegacySupplyCatalog.of(occupant).shortLabel}: ${game.dosesFor(occupant)} DOSES';

    return Material(
      color: const Color(0xFF0B1730),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF432477), Color(0xFF29194D)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'SUPPLIES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        'CASH: \$${game.coins}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFE082),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 13, 18, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _arrow(
                              Icons.chevron_left_rounded,
                              () => setState(() {
                                supplyIndex = (supplyIndex - 1) %
                                    LegacySupply.values.length;
                                if (supplyIndex < 0) {
                                  supplyIndex += LegacySupply.values.length;
                                }
                              }),
                            ),
                            Expanded(
                              child: Container(
                                height: 132,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF163451),
                                  border: Border.all(
                                    color: const Color(0xFF5D9BC7),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 88,
                                    height: 105,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDF7FF),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFF274E72),
                                        width: 3,
                                      ),
                                    ),
                                    child: Icon(
                                      _supplyIcon(supply),
                                      size: 55,
                                      color: const Color(0xFF315B7E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _arrow(
                              Icons.chevron_right_rounded,
                              () => setState(() {
                                supplyIndex = (supplyIndex + 1) %
                                    LegacySupply.values.length;
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          definition.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF8DEEFF),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          definition.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 8.5, height: 1.25),
                        ),
                        const Spacer(),
                        Text(
                          slotText,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xFFB7CDE0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${definition.price}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFD35A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      Expanded(
                        child: _soft(
                          'BACK',
                          () => setState(() {
                            suppliesOpen = false;
                            replaceConfirmation = null;
                          }),
                        ),
                      ),
                      Expanded(
                        child: _soft('BUY', () => _buySupply(supply), active: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (replaceConfirmation != null) _replacePrompt(replaceConfirmation!),
        ],
      ),
    );
  }

  Widget _replacePrompt(LegacySupply supply) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xB9000000),
        child: Center(
          child: Container(
            width: 245,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF392365),
              border: Border.all(color: const Color(0xFFAE9ADE), width: 2),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'REPLACE ITEM IN SLOT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _soft(
                        'NO',
                        () => setState(() => replaceConfirmation = null),
                      ),
                    ),
                    Expanded(
                      child: _soft(
                        'YES',
                        () {
                          setState(() => replaceConfirmation = null);
                          game.buySupply(supply, replace: true);
                          _showGameMessage();
                        },
                        active: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _buySupply(LegacySupply supply) {
    if (game.hasSupplySlotConflict(supply)) {
      setState(() => replaceConfirmation = supply);
      return;
    }
    game.buySupply(supply);
    setState(() {});
    _showGameMessage();
  }

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
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
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

    if (before == LegacyAction.shop && ok) {
      setState(() {
        suppliesOpen = true;
        supplyIndex = 0;
      });
      return;
    }

    if (_showGameMessage()) return;

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

  bool _showGameMessage() {
    final message = game.eventMessage.value;
    if (message == null || !mounted) return false;
    game.clearEventMessage();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
    return true;
  }
}
