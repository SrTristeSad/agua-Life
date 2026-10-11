import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/agua_life_game.dart';
import 'game/data/legacy_economy_catalog.dart';
import 'game/data/legacy_supply_catalog.dart';
import 'game/models/fish_selection.dart';
import 'game/models/fish_state.dart';
import 'game/models/game_settings.dart';
import 'game/models/legacy_action.dart';
import 'pixel_landing.dart';

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
        home: PixelLandingScreen(
          gameBuilder: (_) => const AguaLifeScreen(),
          newGameBuilder: (_) => const AguaLifeScreen(startNewGame: true),
        ),
      );
}

enum _Panel { none, menu, supplies, sale, stats, options, trophy, help, about }

class AguaLifeScreen extends StatefulWidget {
  const AguaLifeScreen({super.key, this.startNewGame = false});

  final bool startNewGame;

  @override
  State<AguaLifeScreen> createState() => _AguaLifeScreenState();
}

class _AguaLifeScreenState extends State<AguaLifeScreen> {
  late final AguaLifeGame game = AguaLifeGame();
  _Panel panel = _Panel.none;
  int supplyIndex = 0;
  LegacySupply? replaceConfirmation;
  bool confirmNewGame = false;

  @override
  void initState() {
    super.initState();
    confirmNewGame = widget.startNewGame;
  }

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
                      Positioned(left: 0, top: 0, width: 352, height: 56, child: _topBar()),
                      Positioned(left: 104, top: 316, width: 144, height: 68, child: _isolation()),
                      Positioned(left: 0, top: 384, width: 352, height: 32, child: _softKeys()),
                      if (panel != _Panel.none) Positioned.fill(child: _activePanel()),
                      if (confirmNewGame) Positioned.fill(child: _newGamePrompt()),
                      if (replaceConfirmation != null) Positioned.fill(child: _replacePrompt(replaceConfirmation!)),
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
      listenable: Listenable.merge(<Listenable>[
        game.fishMode,
        game.action,
        game.focusedFish,
        game.isolationFish,
        game.currentTankNumber,
        game.hud,
        game.revision,
        game.selectedSupply,
      ]),
      builder: (context, _) {
        if (game.fishMode.value == FishInteractionMode.browsing) {
          final fish = game.focusedFish.value;
          final age = fish?.age ?? 0;
          final fed = ((fish?.hunger ?? 0) * 100).round();
          final health = ((fish?.health ?? 0) * 100).round();
          final healthText = fish?.isSick == true ? '$health% ${fish!.diseaseLabel}' : '$health%';
          return _bar(Row(children: [
            _arrow(Icons.chevron_left_rounded, () => game.browseFish(-1)),
            Expanded(flex: 3, child: _stat(fish?.speciesName ?? 'NO FISH', 'AGE $age')),
            Expanded(child: _stat('FED', '$fed%')),
            Expanded(child: _stat('HEALTH', healthText)),
            _arrow(Icons.chevron_right_rounded, () => game.browseFish(1)),
          ]));
        }

        final selected = game.fishMode.value == FishInteractionMode.selected;
        if (selected) {
          final actions = <LegacyAction>[
            LegacyAction.moveTank,
            LegacyAction.moveSale,
            LegacyAction.species,
            game.isolationFish.value == null ? LegacyAction.isolate : LegacyAction.breed,
            LegacyAction.trash,
            if (game.isolationFish.value != null) LegacyAction.release,
          ];
          return _bar(Row(children: [
            SizedBox(
              width: 54,
              child: Center(
                child: Text(
                  game.focusedFish.value?.speciesName ?? 'FISH',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions.map((a) => _actionSlot(a, width: 42)).toList(growable: false),
              ),
            ),
          ]));
        }

        return _bar(Row(children: [
          SizedBox(
            width: 42,
            child: Center(
              child: Text('T${game.currentTankNumber.value}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionSlot(LegacyAction.food, badge: '${game.hud.value.food}', width: 42),
                _actionSlot(LegacyAction.shop, width: 42),
                _actionSlot(LegacyAction.switchTank, width: 42),
                _actionSlot(LegacyAction.saleTank, width: 42),
                ...game.equippedSupplies.map(_supplyActionSlot),
              ],
            ),
          ),
        ]));
      },
    );
  }

  Widget _bar(Widget child) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF35205F), Color(0xFF241641)]),
          border: Border(bottom: BorderSide(color: Color(0xFF6C57A7), width: 2)),
        ),
        child: child,
      );

  Widget _actionSlot(LegacyAction action, {String? badge, double width = 47}) {
    final data = switch (action) {
      LegacyAction.food => (Icons.set_meal_rounded, 'FOOD'),
      LegacyAction.shop => (Icons.shopping_cart_rounded, 'SHOP'),
      LegacyAction.switchTank => (Icons.swap_horiz_rounded, 'TANK'),
      LegacyAction.saleTank => (Icons.sell_rounded, 'SALE'),
      LegacyAction.useSupply => (Icons.medication_rounded, 'ITEM'),
      LegacyAction.moveTank => (Icons.move_down_rounded, 'MOVE'),
      LegacyAction.moveSale => (Icons.sell_outlined, 'SELL'),
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
          border: Border.all(color: active ? const Color(0xFF8BF0FF) : Colors.transparent),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Stack(children: [
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(data.$1, size: 18),
              Text(data.$2, style: const TextStyle(fontSize: 5.8, fontWeight: FontWeight.w900)),
            ]),
          ),
          if (badge != null)
            Positioned(right: 1, top: 1, child: Text(badge, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900))),
        ]),
      ),
    );
  }

  Widget _supplyActionSlot(LegacySupply supply) {
    final definition = LegacySupplyCatalog.of(supply);
    final active = game.action.value == LegacyAction.useSupply && game.selectedSupply.value == supply;
    return InkWell(
      onTap: () => game.selectSupplyAction(supply),
      child: Container(
        width: 42,
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF633AA5) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFF8BF0FF) : Colors.transparent),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Stack(children: [
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(_supplyIcon(supply), size: 17),
            Text(definition.shortLabel, maxLines: 1, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 5.2, fontWeight: FontWeight.w900)),
          ])),
          Positioned(right: 1, top: 1, child: Text('${game.dosesFor(supply)}', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900))),
        ]),
      ),
    );
  }

  IconData _supplyIcon(LegacySupply supply) {
    final kind = LegacySupplyCatalog.of(supply).kind;
    return switch (kind) {
      LegacyShopKind.treatment => Icons.medication_liquid_rounded,
      LegacyShopKind.enhancement => Icons.science_rounded,
      LegacyShopKind.eggs => Icons.egg_alt_rounded,
      LegacyShopKind.research => Icons.biotech_rounded,
      LegacyShopKind.equipment => Icons.settings_suggest_rounded,
      LegacyShopKind.plant => Icons.local_florist_rounded,
      LegacyShopKind.ornament => Icons.category_rounded,
      LegacyShopKind.tank => Icons.water_rounded,
    };
  }

  Widget _stat(String title, String value) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: Color(0xFFBEAEE9))),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      );

  Widget _arrow(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: SizedBox(width: 34, child: Icon(icon, size: 27, color: const Color(0xFF75E7FF))),
      );

  Widget _isolation() {
    return ValueListenableBuilder<FishSelection?>(
      valueListenable: game.isolationFish,
      builder: (context, fish, _) => GestureDetector(
        onTap: fish == null ? null : game.selectIsolation,
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/art/tank_freshwater.webp', fit: BoxFit.cover, filterQuality: FilterQuality.high),
          const Positioned(left: 0, right: 0, top: 0, height: 14, child: ColoredBox(color: Color(0xFF101F2E))),
          if (fish != null)
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.34,
                heightFactor: 0.52,
                child: Image.asset(_visualAssetForBreed(fish), fit: BoxFit.contain),
              ),
            ),
          if (fish?.pregnant == true)
            const Positioned(right: 5, top: 17, child: Icon(Icons.egg_alt_rounded, size: 16, color: Color(0xFFFFF3A0))),
          if (fish?.isSick == true)
            Positioned(left: 5, top: 17, child: Text(fish!.diseaseLabel, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Color(0xFFFFF0A8)))),
          Positioned(
            left: 3,
            right: 3,
            bottom: 2,
            child: Text(
              fish == null ? 'ISOLATION' : fish.pregnant ? 'PREGNANT' : fish.speciesName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 6.5, fontWeight: FontWeight.w900),
            ),
          ),
        ]),
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
      builder: (context, mode, _) => ColoredBox(
        color: const Color(0xFF17142A),
        child: Row(children: [
          Expanded(child: _soft(mode == FishInteractionMode.none ? 'MENU' : 'BACK', mode == FishInteractionMode.none ? () => setState(() => panel = _Panel.menu) : game.cancelFishInteraction)),
          Expanded(child: _soft(mode == FishInteractionMode.browsing ? 'SELECT' : 'ACTION', _handleAction, active: true)),
          Expanded(child: _soft('FISH', game.enterFishBrowse)),
        ]),
      ),
    );
  }

  Widget _soft(String text, VoidCallback onTap, {bool active = false}) => InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          color: active ? const Color(0xFF282049) : Colors.transparent,
          child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: active ? const Color(0xFF85EDFF) : Colors.white)),
        ),
      );

  Widget _activePanel() => switch (panel) {
        _Panel.menu => _menu(),
        _Panel.supplies => _supplies(),
        _Panel.sale => _sale(),
        _Panel.stats => _stats(),
        _Panel.options => _options(),
        _Panel.trophy => _trophy(),
        _Panel.help => _help(),
        _Panel.about => _about(),
        _Panel.none => const SizedBox.shrink(),
      };

  Widget _panelFrame(String title, Widget body, {Widget? footer}) {
    return Material(
      color: const Color(0xFF0B1730),
      child: Column(children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF432477), Color(0xFF29194D)])),
          child: Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900))),
            Text('CASH: \$${game.coins}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFFFE082))),
          ]),
        ),
        Expanded(child: body),
        footer ?? SizedBox(height: 38, child: _soft('BACK', () => setState(() => panel = _Panel.none))),
      ]),
    );
  }

  Widget _menu() {
    final items = <(String, VoidCallback)>[
      ('RESUME', () => setState(() => panel = _Panel.none)),
      ('START NEW GAME', () => setState(() => confirmNewGame = true)),
      ('OPTIONS', () => setState(() => panel = _Panel.options)),
      ('TROPHY', () => setState(() => panel = _Panel.trophy)),
      ('STATS', () => setState(() => panel = _Panel.stats)),
      ('HELP', () => setState(() => panel = _Panel.help)),
      ('ABOUT', () => setState(() => panel = _Panel.about)),
      ('SAVE & EXIT', _saveAndClose),
    ];
    return Material(
      color: const Color(0xD0000710),
      child: Center(
        child: SizedBox(
          width: 240,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: const Color(0xFF3A226B), border: Border.all(color: const Color(0xFFA592D4), width: 2), borderRadius: BorderRadius.circular(7)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((entry) => InkWell(
                onTap: entry.$2,
                child: SizedBox(height: 34, child: Center(child: Text(entry.$1, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)))),
              )).toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _supplies() {
    return ListenableBuilder(
      listenable: game.revision,
      builder: (context, _) {
        final supply = LegacySupply.values[supplyIndex];
        final definition = LegacySupplyCatalog.of(supply);
        final price = game.shopPrice(supply);
        return _panelFrame(
          'SUPPLIES ${supplyIndex + 1}/${LegacySupply.values.length}',
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(children: [
              Row(children: [
                _arrow(Icons.chevron_left_rounded, () => setState(() => supplyIndex = (supplyIndex - 1 + LegacySupply.values.length) % LegacySupply.values.length)),
                Expanded(
                  child: Container(
                    height: 116,
                    decoration: BoxDecoration(color: const Color(0xFF163451), border: Border.all(color: const Color(0xFF5D9BC7), width: 2), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Icon(_supplyIcon(supply), size: 60, color: const Color(0xFF9CDFF7))),
                  ),
                ),
                _arrow(Icons.chevron_right_rounded, () => setState(() => supplyIndex = (supplyIndex + 1) % LegacySupply.values.length)),
              ]),
              const SizedBox(height: 8),
              Text(definition.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF8DEEFF))),
              const SizedBox(height: 5),
              Text(definition.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.2, height: 1.22)),
              const Spacer(),
              Text(game.shopStatus(supply), textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: Color(0xFFB7CDE0))),
              const SizedBox(height: 4),
              Text(price <= 0 ? '' : '\$$price', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFFFD35A))),
            ]),
          ),
          footer: SizedBox(
            height: 38,
            child: Row(children: [
              Expanded(child: _soft('BACK', () => setState(() => panel = _Panel.none))),
              Expanded(child: _soft('FOOD +20 / \$20', _buyFood)),
              Expanded(child: _soft(definition.isResearch ? 'RESEARCH' : 'BUY', () => _buySupply(supply), active: true)),
            ]),
          ),
        );
      },
    );
  }

  void _buyFood() {
    game.buyFoodPack();
    setState(() {});
    _showGameMessage();
  }

  void _buySupply(LegacySupply supply) {
    final definition = LegacySupplyCatalog.of(supply);
    if (definition.isConsumable && game.hasSupplySlotConflict(supply)) {
      setState(() => replaceConfirmation = supply);
      return;
    }
    game.buySupply(supply);
    setState(() {});
    _showGameMessage();
  }

  Widget _replacePrompt(LegacySupply supply) => _prompt(
        'REPLACE ITEM IN SLOT',
        'The item already in this legacy slot will be discarded.',
        () => setState(() => replaceConfirmation = null),
        () {
          setState(() => replaceConfirmation = null);
          game.buySupply(supply, replace: true);
          _showGameMessage();
        },
      );

  Widget _newGamePrompt() => _prompt(
        'START NEW GAME?',
        'This replaces the current local save.',
        () => setState(() => confirmNewGame = false),
        () async {
          setState(() => confirmNewGame = false);
          await game.newGame();
          if (!mounted) return;
          setState(() => panel = _Panel.none);
        },
      );

  Widget _prompt(String title, String body, VoidCallback no, VoidCallback yes) {
    return ColoredBox(
      color: const Color(0xC9000000),
      child: Center(
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF392365), border: Border.all(color: const Color(0xFFAE9ADE), width: 2), borderRadius: BorderRadius.circular(7)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _soft('NO', no)),
              Expanded(child: _soft('YES', yes, active: true)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _sale() {
    return ListenableBuilder(
      listenable: game.revision,
      builder: (context, _) {
        final fish = game.saleFish;
        return _panelFrame(
          'FISH STORE / SALE TANK',
          fish.isEmpty
              ? const Center(child: Text('NO FISH\nMove an adult healthy fish here with SELL.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: fish.length,
                  itemBuilder: (context, index) => _saleFishTile(fish[index], index),
                ),
          footer: SizedBox(
            height: 38,
            child: Row(children: [
              Expanded(child: _soft('BACK', () => setState(() => panel = _Panel.none))),
              Expanded(child: _soft('CUSTOMER', () {
                game.simulateCustomerNow();
                _showGameMessage();
              }, active: true)),
            ]),
          ),
        );
      },
    );
  }

  Widget _saleFishTile(FishState fish, int index) {
    final ask = game.askingPriceFor(fish);
    final fair = game.fairPriceFor(fish);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: const Color(0xFF142C46), border: Border.all(color: const Color(0xFF436F94)), borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fish.legacySpeciesName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
            Text('AGE ${fish.age}   FAIR \$$fair', style: const TextStyle(fontSize: 7, color: Color(0xFFAAC8DE))),
          ]),
        ),
        _miniButton('-', () => game.adjustAskingPrice(fish, -1)),
        SizedBox(width: 48, child: Text('\$$ask', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFFFD35A)))),
        _miniButton('+', () => game.adjustAskingPrice(fish, 1)),
        const SizedBox(width: 4),
        _miniButton('↩', () => game.returnSaleFish(index)),
      ]),
    );
  }

  Widget _miniButton(String text, VoidCallback tap) => InkWell(
        onTap: () {
          tap();
          setState(() {});
          _showGameMessage();
        },
        child: Container(width: 25, height: 25, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF3A2865), borderRadius: BorderRadius.circular(4)), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
      );

  Widget _stats() {
    return ListenableBuilder(
      listenable: game.revision,
      builder: (context, _) {
        final s = game.statistics;
        final rows = <(String, String)>[
          ('FISH SOLD', '${s.fishSold}'),
          ('FISH TRASHED', '${s.fishTrashed}'),
          ('FISH CURED', '${s.fishCured}'),
          (r'$$$ EARNED', '\$${s.moneyEarned}'),
          (r'$$$ SPENT', '\$${s.moneySpent}'),
          (r'AVG $/FISH', '\$${s.averageMoneyPerFish.toStringAsFixed(1)}'),
          ('FOOD GIVEN', '${s.foodGiven}'),
          ('HOURS PLAYED', s.hoursPlayed.toStringAsFixed(2)),
          ('SPECIES FOUND', '${game.discoveredSpeciesCount}/441'),
          ('TOP FISH PRICE', '\$${s.topFishPrice}'),
          ('MAGIC SPECIES', '${game.magicFoundCount}/7'),
          ('MAGIC FISH BRED', '${s.magicFishBred}'),
          ('TOTAL FISH BRED', '${s.totalFishBred}'),
        ];
        return _panelFrame('STATISTICS', ListView(padding: const EdgeInsets.all(12), children: rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [Expanded(child: Text(row.$1, style: const TextStyle(fontSize: 8, color: Color(0xFFB9D0E2)))), Text(row.$2, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900))]),
        )).toList()));
      },
    );
  }

  Widget _options() {
    return ListenableBuilder(
      listenable: game.revision,
      builder: (context, _) => _panelFrame(
        'OPTIONS',
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _optionRow('MUSIC', game.settings.music ? 'ON' : 'OFF', game.toggleMusic),
            _optionRow('SOUND', game.settings.sound ? 'ON' : 'OFF', game.toggleSound),
            _optionRow('HELP MESSAGES', game.settings.helpMessages ? 'ON' : 'OFF', game.toggleHelpMessages),
            const SizedBox(height: 14),
            const Text('SELECT SPEED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF8DEEFF))),
            const SizedBox(height: 8),
            ...GameSpeed.values.map((speed) => InkWell(
              onTap: () => game.setSpeed(speed),
              child: Container(
                height: 35,
                margin: const EdgeInsets.only(bottom: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: game.settings.speed == speed ? const Color(0xFF613B98) : const Color(0xFF172D49), borderRadius: BorderRadius.circular(5)),
                child: Text(speed.label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _optionRow(String title, String value, VoidCallback tap) => InkWell(
        onTap: tap,
        child: Container(
          height: 42,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFF172D49), borderRadius: BorderRadius.circular(5)),
          child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900))), Text(value, style: const TextStyle(fontSize: 9, color: Color(0xFF8DEEFF)))]),
        ),
      );

  Widget _trophy() {
    return ListenableBuilder(
      listenable: game.revision,
      builder: (context, _) => _panelFrame(
        'THE 7 MAGIC FISH',
        ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (var i = 0; i < LegacyEconomyCatalog.magicFish.length; i++)
              Container(
                height: 39,
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: const Color(0xFF172D49), borderRadius: BorderRadius.circular(5)),
                child: Row(children: [
                  Icon(game.magicFound.contains(i) ? Icons.emoji_events_rounded : Icons.help_outline_rounded, size: 20, color: game.magicFound.contains(i) ? const Color(0xFFFFD35A) : const Color(0xFF7791A7)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(game.magicFound.contains(i) ? LegacyEconomyCatalog.magicFish[i].name : 'UNKNOWN MAGIC FISH', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900))),
                ]),
              ),
            if (game.allMagicFishFound)
              const Padding(padding: EdgeInsets.only(top: 8), child: Text('ALL 7 MAGIC FISH DISCOVERED!', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFFFD35A)))),
          ],
        ),
      ),
    );
  }

  Widget _help() => _panelFrame(
        'HELP',
        const SingleChildScrollView(
          padding: EdgeInsets.all(14),
          child: Text(
            'THE GOAL IS TO BREED FISH AND FIND THE 7 MAGIC FISH. FINANCE THE MISSION BY SELLING FISH.\n\n'
            'Feed fish with FOOD. Adult fish are AGE 20 or older. Isolate an adult fish, select another adult and use BREED to make the isolated fish pregnant.\n\n'
            'Move healthy adult fish to SELL, set an asking price and wait for customers. Research environment for rarer eggs and food research so fish need less feeding.\n\n'
            'The game keeps running in real time while closed. Slow/Normal/Fast correspond to the recovered J2ME timing. Paused stops simulation and research.',
            style: TextStyle(fontSize: 8.5, height: 1.35),
          ),
        ),
      );

  Widget _about() => _panelFrame(
        'ABOUT',
        const Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text('AGUA LIFE\n\nFlutter/Flame preservation remake based on the supplied J2ME game behavior.\n\nTesting build: legacy rules are being reconstructed from the original bytecode.', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, height: 1.4)),
          ),
        ),
      );

  Future<void> _saveAndClose() async {
    await game.saveNow();
    if (!mounted) return;
    setState(() => panel = _Panel.none);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GAME SAVED.'), duration: Duration(seconds: 1)));
  }

  Future<void> _handleAction() async {
    final before = game.action.value;
    final ok = await game.pressAction();
    if (!mounted) return;
    if (before == LegacyAction.shop && ok) {
      setState(() {
        panel = _Panel.supplies;
        supplyIndex = 0;
      });
      return;
    }
    if (before == LegacyAction.saleTank && ok) {
      setState(() => panel = _Panel.sale);
      return;
    }
    if (_showGameMessage()) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ação indisponível.'), duration: Duration(seconds: 1)));
      return;
    }
    if (before == LegacyAction.species) {
      final fish = game.focusedFish.value;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fish == null ? 'SPECIES' : '${fish.speciesName}  AGE ${fish.age}'), duration: const Duration(seconds: 2)));
    }
  }

  bool _showGameMessage() {
    final message = game.eventMessage.value;
    if (message == null || !mounted) return false;
    game.clearEventMessage();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
    return true;
  }
}
