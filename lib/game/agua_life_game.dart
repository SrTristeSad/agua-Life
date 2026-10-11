import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'components/tank_scene.dart';
import 'data/legacy_breed_catalog.dart';
import 'data/legacy_supply_catalog.dart';
import 'data/species_catalog.dart';
import 'models/fish_disease.dart';
import 'models/fish_genome.dart';
import 'models/fish_selection.dart';
import 'models/fish_state.dart';
import 'models/game_hud_state.dart';
import 'models/legacy_action.dart';
import 'services/legacy_health_service.dart';

class AguaLifeGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF0A2A43);

  static const int maxFishPerTank = 18;

  final ValueNotifier<GameHudState> hud =
      ValueNotifier<GameHudState>(GameHudState.empty);
  final ValueNotifier<FishSelection?> focusedFish =
      ValueNotifier<FishSelection?>(null);
  final ValueNotifier<FishSelection?> isolationFish =
      ValueNotifier<FishSelection?>(null);
  final ValueNotifier<FishInteractionMode> fishMode =
      ValueNotifier<FishInteractionMode>(FishInteractionMode.none);
  final ValueNotifier<LegacyAction> action =
      ValueNotifier<LegacyAction>(LegacyAction.food);
  final ValueNotifier<int> currentTankNumber = ValueNotifier<int>(1);
  final ValueNotifier<String?> eventMessage = ValueNotifier<String?>(null);
  final ValueNotifier<int> supplyRevision = ValueNotifier<int>(0);
  final ValueNotifier<LegacySupply?> selectedSupply =
      ValueNotifier<LegacySupply?>(null);

  final LegacyHealthService _healthService = LegacyHealthService();
  final List<FishState> _tank1 = <FishState>[];
  final List<FishState> _tank2 = <FishState>[];

  TankScene? _scene;
  FishState? _isolated;
  FishState? _focused;
  int? _isolationHomeTank;
  double _hudTimer = 0;

  int _coins = 300;
  int _food = 12;

  LegacySupply? _treatmentSlot;
  int _treatmentDoses = 0;
  LegacySupply? _enhancementSlot;
  int _enhancementDoses = 0;

  int get coins => _coins;

  List<LegacySupply> get equippedSupplies => <LegacySupply>[
        if (_treatmentSlot != null && _treatmentDoses > 0) _treatmentSlot!,
        if (_enhancementSlot != null && _enhancementDoses > 0)
          _enhancementSlot!,
      ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _seedFish();
    await _showTank(1);
    _publishHud();
  }

  @override
  void update(double dt) {
    super.update(dt);

    var sickFishCount = <FishState>[..._tank1, ..._tank2]
        .where((fish) => fish.alive && fish.isSick)
        .length;

    void advanceTankFish(FishState fish) {
      final steps = fish.tick(dt);
      for (var step = 0; step < steps && fish.alive; step++) {
        _healthService.advanceHealth(
          fish,
          environmentResearchLevel: 1,
        );
        if (fish.alive &&
            _healthService.maybeInfect(
              fish,
              sickFishCount: sickFishCount,
              environmentResearchLevel: 1,
            )) {
          sickFishCount++;
        }
        _healthService.advanceFed(fish, foodResearchLevel: 1);
      }
    }

    for (final fish in _tank1) {
      advanceTankFish(fish);
    }
    for (final fish in _tank2) {
      advanceTankFish(fish);
    }

    final isolated = _isolated;
    if (isolated != null) {
      final steps = isolated.tick(dt);
      for (var step = 0; step < steps && isolated.alive; step++) {
        _healthService.advanceHealth(
          isolated,
          environmentResearchLevel: 1,
        );
        _healthService.maybeInfect(
          isolated,
          sickFishCount: 0,
          environmentResearchLevel: 1,
        );
        _healthService.advanceFed(isolated, foodResearchLevel: 1);
      }

      final father = isolated.completePregnancyIfReady();
      if (father != null) {
        _deliverBaby(isolated, father);
      }
    }

    _hudTimer += dt;
    if (_hudTimer >= 0.2) {
      _hudTimer = 0;
      _publishHud();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutScene();
  }

  void chooseAction(LegacyAction next) {
    action.value = next;
    if (next != LegacyAction.useSupply) {
      selectedSupply.value = null;
    }
  }

  void selectSupplyAction(LegacySupply supply) {
    if (dosesFor(supply) <= 0) return;
    selectedSupply.value = supply;
    action.value = LegacyAction.useSupply;
  }

  int dosesFor(LegacySupply supply) {
    if (_isTreatmentSupply(supply)) {
      return _treatmentSlot == supply ? _treatmentDoses : 0;
    }
    return _enhancementSlot == supply ? _enhancementDoses : 0;
  }

  LegacySupply? occupyingSupplyFor(LegacySupply supply) =>
      _isTreatmentSupply(supply) ? _treatmentSlot : _enhancementSlot;

  bool hasSupplySlotConflict(LegacySupply supply) {
    final occupant = occupyingSupplyFor(supply);
    return occupant != null && dosesFor(occupant) > 0;
  }

  bool buySupply(LegacySupply supply, {bool replace = false}) {
    final definition = LegacySupplyCatalog.of(supply);
    if (hasSupplySlotConflict(supply) && !replace) {
      eventMessage.value = 'REPLACE ITEM IN SLOT';
      return false;
    }
    if (_coins < definition.price) {
      eventMessage.value = "YOU CAN'T AFFORD IT!";
      return false;
    }

    _coins -= definition.price;
    if (_isTreatmentSupply(supply)) {
      _treatmentSlot = supply;
      _treatmentDoses = definition.dosesPerPurchase;
    } else {
      _enhancementSlot = supply;
      _enhancementDoses = definition.dosesPerPurchase;
    }

    selectSupplyAction(supply);
    supplyRevision.value++;
    eventMessage.value = '${definition.name}  ${definition.dosesPerPurchase} DOSES';
    _publishHud();
    return true;
  }

  bool useSelectedSupply() {
    final supply = selectedSupply.value;
    if (supply == null || dosesFor(supply) <= 0) return false;

    final current = currentTankNumber.value == 1 ? _tank1 : _tank2;
    var affected = 0;
    switch (supply) {
      case LegacySupply.ichTreatment:
        affected = _healthService.treat(
          <FishState>[
            ...current,
            if (_isolated != null) _isolated!,
          ],
          FishDisease.ich,
        );
      case LegacySupply.fungalTreatment:
        affected = _healthService.treat(
          <FishState>[
            ...current,
            if (_isolated != null) _isolated!,
          ],
          FishDisease.fungus,
        );
      case LegacySupply.fishVitamins:
        affected = _healthService.applyVitamins(current);
      case LegacySupply.growthHormone:
        affected = _healthService.applyGrowthHormone(current);
      case LegacySupply.unknownChemical:
        affected = _healthService.applyUnknownChemical(current);
    }

    _consumeSupplyDose(supply);
    final definition = LegacySupplyCatalog.of(supply);
    eventMessage.value = '${definition.name}: $affected FISH AFFECTED';
    _publishHud();
    return true;
  }

  void enterFishBrowse() {
    fishMode.value = FishInteractionMode.browsing;
    _scene?.beginBrowsing();
  }

  void browseFish(int delta) {
    if (fishMode.value != FishInteractionMode.browsing) return;
    _scene?.browse(delta);
  }

  void selectIsolation() {
    final isolated = _isolated;
    if (isolated == null) return;
    _scene?.clearFocus();
    _focused = null;
    focusedFish.value = FishSelection.fromState(isolated);
    fishMode.value = FishInteractionMode.selected;
    action.value = LegacyAction.release;
  }

  void cancelFishInteraction() {
    fishMode.value = FishInteractionMode.none;
    _focused = null;
    focusedFish.value = null;
    _scene?.clearFocus();
  }

  Future<bool> pressAction() async {
    if (fishMode.value == FishInteractionMode.browsing) {
      final state = _scene?.focusedFish;
      if (state == null) return false;
      _focused = state;
      _scene?.lockFocus();
      focusedFish.value = FishSelection.fromState(state);
      fishMode.value = FishInteractionMode.selected;
      action.value = _isolated == null ? LegacyAction.isolate : LegacyAction.breed;
      return true;
    }

    if (fishMode.value == FishInteractionMode.selected) {
      switch (action.value) {
        case LegacyAction.isolate:
          return _isolateFocused();
        case LegacyAction.release:
          return _releaseIsolation();
        case LegacyAction.moveTank:
          return _moveFocusedToOtherTank();
        case LegacyAction.trash:
          return _trashFocused();
        case LegacyAction.breed:
          return _breedFocusedWithIsolation();
        case LegacyAction.species:
          return _focused != null || _isolated != null;
        case LegacyAction.food:
        case LegacyAction.shop:
        case LegacyAction.switchTank:
        case LegacyAction.saleTank:
        case LegacyAction.useSupply:
          return false;
      }
    }

    switch (action.value) {
      case LegacyAction.food:
        return _dropFood();
      case LegacyAction.switchTank:
        await _showTank(currentTankNumber.value == 1 ? 2 : 1);
        return true;
      case LegacyAction.useSupply:
        return useSelectedSupply();
      case LegacyAction.shop:
      case LegacyAction.saleTank:
        return true;
      case LegacyAction.moveTank:
      case LegacyAction.species:
      case LegacyAction.isolate:
      case LegacyAction.release:
      case LegacyAction.breed:
      case LegacyAction.trash:
        return false;
    }
  }

  void clearEventMessage() {
    eventMessage.value = null;
  }

  void _seedFish() {
    if (_tank1.isNotEmpty || _tank2.isNotEmpty) return;

    const spotted = FishGenome(
      primaryColor: 0xFFFF8A33,
      secondaryColor: 0xFFFFE082,
      pattern: FishPattern.spots,
      bodyScale: 0.93,
      finScale: 1.08,
      growthRate: 1.02,
      diseaseResistance: 0.96,
      fertility: 1.04,
      valueModifier: 1.1,
      shimmer: false,
    );

    _tank1.addAll([
      FishState(
        species: SpeciesCatalog.sunny,
        genome: SpeciesCatalog.sunny.founderGenome,
        bodyIndex: 0,
        finIndex: 0,
        ageSeconds: 20 * FishState.secondsPerAgeAtNormalSpeed,
        hunger: 0.78,
      ),
      FishState(
        species: SpeciesCatalog.zephyr,
        genome: SpeciesCatalog.zephyr.founderGenome,
        bodyIndex: 1,
        finIndex: 1,
        ageSeconds: 21 * FishState.secondsPerAgeAtNormalSpeed,
        hunger: 0.84,
      ),
      FishState(
        species: SpeciesCatalog.luna,
        genome: SpeciesCatalog.luna.founderGenome,
        bodyIndex: 2,
        finIndex: 4,
        ageSeconds: 10 * FishState.secondsPerAgeAtNormalSpeed,
        hunger: 0.88,
      ),
      FishState(
        species: SpeciesCatalog.sunny,
        genome: spotted,
        bodyIndex: 3,
        finIndex: 3,
        ageSeconds: 3 * FishState.secondsPerAgeAtNormalSpeed,
        hunger: 0.91,
      ),
    ]);

    _tank2.addAll([
      FishState(
        species: SpeciesCatalog.shadow,
        genome: SpeciesCatalog.shadow.founderGenome,
        bodyIndex: 16,
        finIndex: 11,
        ageSeconds: 20 * FishState.secondsPerAgeAtNormalSpeed,
        hunger: 0.82,
      ),
      FishState(
        species: SpeciesCatalog.luna,
        genome: SpeciesCatalog.luna.founderGenome,
        bodyIndex: 15,
        finIndex: 10,
        ageSeconds: 12 * FishState.secondsPerAgeAtNormalSpeed,
        hunger: 0.80,
      ),
    ]);
  }

  Future<void> _showTank(int number) async {
    final old = _scene;
    if (old != null) old.removeFromParent();

    currentTankNumber.value = number;
    final states = number == 1 ? _tank1 : _tank2;
    final scene = TankScene(
      tankNumber: number,
      backgroundAsset: 'art/tank_freshwater.webp',
      fishStates: states,
      onFishFocused: _onFishFocused,
    );
    _scene = scene;
    _layoutScene();
    await add(scene);
    cancelFishInteraction();
    _publishHud();
  }

  void _layoutScene() {
    final scene = _scene;
    if (scene == null || size.x <= 0 || size.y <= 0) return;

    final scaleX = size.x / 352.0;
    final scaleY = size.y / 416.0;
    scene
      ..position = Vector2(0, 56 * scaleY)
      ..size = Vector2(352 * scaleX, 260 * scaleY);
  }

  bool _dropFood() {
    if (_food <= 0) return false;
    final dropped = _scene?.dropFood() ?? 0;
    if (dropped == 0) return false;
    _food--;
    _publishHud();
    return true;
  }

  bool _isolateFocused() {
    if (_isolated != null) return false;
    final state = _scene?.removeFocusedFish();
    if (state == null) return false;
    _isolated = state;
    _isolationHomeTank = currentTankNumber.value;
    isolationFish.value = FishSelection.fromState(state);
    cancelFishInteraction();
    _publishHud();
    return true;
  }

  Future<bool> _releaseIsolation() async {
    final state = _isolated;
    if (state == null) return false;

    final target = currentTankNumber.value == 1 ? _tank1 : _tank2;
    if (target.length >= maxFishPerTank) {
      eventMessage.value = 'TANK FULL!';
      return false;
    }

    _isolated = null;
    _isolationHomeTank = null;
    isolationFish.value = null;
    final scene = _scene;
    if (scene != null) await scene.addFish(state);
    cancelFishInteraction();
    _publishHud();
    return true;
  }

  bool _breedFocusedWithIsolation() {
    final mother = _isolated;
    final mate = _focused;
    if (mother == null || mate == null) return false;
    if (mother.pregnant) {
      eventMessage.value = 'ALREADY PREGNANT!';
      return false;
    }
    if (mother.isSick || mate.isSick) {
      eventMessage.value = 'SICK FISH CANNOT BREED.';
      return false;
    }
    if (!mother.isAdult || !mate.isAdult) {
      eventMessage.value = 'ONLY ADULT FISH CAN BREED.';
      return false;
    }

    final started = mother.startPregnancy(mate);
    if (!started) return false;

    isolationFish.value = FishSelection.fromState(mother);
    eventMessage.value = 'FISH PREGNANT';
    cancelFishInteraction();
    _publishHud();
    return true;
  }

  void _deliverBaby(
    FishState mother,
    ({int fatherBody, int fatherFin}) father,
  ) {
    final homeTank = _isolationHomeTank ?? currentTankNumber.value;
    final target = homeTank == 1 ? _tank1 : _tank2;

    if (target.length >= maxFishPerTank) {
      eventMessage.value = 'TANK FULL! BABY FISH WAS EATEN.';
      _publishHud();
      return;
    }

    final breed = LegacyBreedCatalog.childOf(
      motherBody: mother.bodyIndex,
      motherFin: mother.finIndex,
      fatherBody: father.fatherBody,
      fatherFin: father.fatherFin,
    );
    final visual = SpeciesCatalog.visualForLegacy(breed.body, breed.fin);
    final baby = FishState(
      species: visual,
      genome: visual.founderGenome,
      bodyIndex: breed.body,
      finIndex: breed.fin,
      ageSeconds: 0,
      hunger: 0.90,
      health: 1,
    );
    target.add(baby);

    final scene = _scene;
    if (homeTank == currentTankNumber.value && scene != null) {
      unawaited(scene.addFish(baby));
    }

    eventMessage.value = 'A NEW BABY WAS BORN! ${baby.legacySpeciesName.toUpperCase()}';
    _publishHud();
  }

  bool _moveFocusedToOtherTank() {
    final state = _scene?.focusedFish;
    if (state == null) return false;
    final target = currentTankNumber.value == 1 ? _tank2 : _tank1;
    if (target.length >= maxFishPerTank) {
      eventMessage.value = 'TANK FULL!';
      return false;
    }

    final removed = _scene?.removeFocusedFish();
    if (removed == null) return false;
    if (!target.contains(removed)) target.add(removed);
    cancelFishInteraction();
    _publishHud();
    return true;
  }

  bool _trashFocused() {
    final state = _scene?.removeFocusedFish();
    if (state == null) return false;
    _tank1.remove(state);
    _tank2.remove(state);
    cancelFishInteraction();
    _publishHud();
    return true;
  }

  bool _isTreatmentSupply(LegacySupply supply) =>
      supply == LegacySupply.ichTreatment ||
      supply == LegacySupply.fungalTreatment;

  void _consumeSupplyDose(LegacySupply supply) {
    if (_isTreatmentSupply(supply)) {
      if (_treatmentSlot != supply) return;
      _treatmentDoses--;
      if (_treatmentDoses <= 0) {
        _treatmentDoses = 0;
        _treatmentSlot = null;
      }
    } else {
      if (_enhancementSlot != supply) return;
      _enhancementDoses--;
      if (_enhancementDoses <= 0) {
        _enhancementDoses = 0;
        _enhancementSlot = null;
      }
    }

    if (dosesFor(supply) <= 0 && selectedSupply.value == supply) {
      selectedSupply.value = null;
      action.value = LegacyAction.food;
    }
    supplyRevision.value++;
  }

  void _onFishFocused(FishState? state) {
    _focused = state;
    focusedFish.value = state == null ? null : FishSelection.fromState(state);
  }

  void _publishHud() {
    final scene = _scene;
    hud.value = GameHudState(
      coins: _coins,
      food: _food,
      fishCount: scene?.fishCount ?? 0,
      averageHunger: scene?.averageHunger ?? 1,
      averageHealth: scene?.averageHealth ?? 1,
    );

    final state = _focused;
    if (state != null) focusedFish.value = FishSelection.fromState(state);
    final isolated = _isolated;
    if (isolated != null) {
      isolationFish.value = FishSelection.fromState(isolated);
    }
  }
}
