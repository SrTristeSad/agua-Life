import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'components/tank_scene.dart';
import 'data/legacy_breed_catalog.dart';
import 'data/legacy_economy_catalog.dart';
import 'data/legacy_supply_catalog.dart';
import 'data/species_catalog.dart';
import 'models/fish_disease.dart';
import 'models/fish_genome.dart';
import 'models/fish_selection.dart';
import 'models/fish_state.dart';
import 'models/game_hud_state.dart';
import 'models/game_settings.dart';
import 'models/game_statistics.dart';
import 'models/legacy_action.dart';
import 'services/game_save_service.dart';
import 'services/legacy_health_service.dart';

class AguaLifeGame extends FlameGame {
  static const int maxFishPerTank = 18;
  static const int saveSchemaVersion = 2;

  @override
  Color backgroundColor() => const Color(0xFF0A2A43);

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
  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  final ValueNotifier<LegacySupply?> selectedSupply =
      ValueNotifier<LegacySupply?>(null);
  final ValueNotifier<bool> initialized = ValueNotifier<bool>(false);

  final Random _random = Random();
  final LegacyHealthService _healthService = LegacyHealthService();
  final GameSaveService _saveService = GameSaveService();
  final List<FishState> _tank1 = <FishState>[];
  final List<FishState> _tank2 = <FishState>[];
  final List<FishState> _saleTank = <FishState>[];
  final Set<int> _ownedItems = <int>{};
  final Set<String> _discoveredSpecies = <String>{};
  final Set<int> _magicFound = <int>{};
  final Map<String, int> _askingPrices = <String, int>{};
  final Map<int, double> _researchProgress = <int, double>{};

  TankScene? _scene;
  FishState? _isolated;
  FishState? _focused;
  int? _isolationHomeTank;
  GameSettings settings = GameSettings();
  GameStatistics statistics = GameStatistics();

  int _coins = 300;
  int _food = 30;
  int _advertisingLevel = 1;
  int _foodResearchLevel = 1;
  int _environmentLevel = 1;
  LegacySupply? _treatmentSlot;
  int _treatmentDoses = 0;
  LegacySupply? _enhancementSlot;
  int _enhancementDoses = 0;
  double _hudTimer = 0;
  double _autosaveTimer = 0;
  double _customerTimer = 0;
  bool _sceneRebuildPending = false;

  int get coins => _coins;
  int get food => _food;
  int get advertisingLevel => _advertisingLevel;
  int get foodResearchLevel => _foodResearchLevel;
  int get environmentResearchLevel => _environmentLevel;
  int get discoveredSpeciesCount => _discoveredSpecies.length;
  int get magicFoundCount => _magicFound.length;
  bool get allMagicFishFound => _magicFound.length >= 7;
  bool get ownsSecondTank => _ownedItems.contains(24);
  List<FishState> get saleFish => List<FishState>.unmodifiable(_saleTank);
  Set<int> get magicFound => Set<int>.unmodifiable(_magicFound);

  List<LegacySupply> get equippedSupplies {
    final result = <LegacySupply>[];
    if (_treatmentSlot != null && _treatmentDoses > 0) {
      result.add(_treatmentSlot!);
    }
    if (_enhancementSlot != null && _enhancementDoses > 0) {
      result.add(_enhancementSlot!);
    }
    return result;
  }

  List<FishState> get _currentTank =>
      currentTankNumber.value == 1 ? _tank1 : _tank2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final saved = await _saveService.load();
    if (saved == null) {
      _resetState();
    } else {
      _restore(saved);
      _applyOfflineProgress(saved);
    }
    await _showTank(currentTankNumber.value, force: true);
    _publishHud();
    initialized.value = true;
    _touch();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!initialized.value) return;

    statistics.playSeconds += dt;
    final simulationDt = dt * settings.speed.simulationMultiplier;
    if (simulationDt > 0) {
      _advanceTank(_tank1, simulationDt);
      _advanceTank(_tank2, simulationDt);
      _advanceIsolated(simulationDt);
    }
    _advanceResearch(dt);
    _advanceCustomers(dt);
    _cleanupDeadFish();

    _hudTimer += dt;
    _autosaveTimer += dt;
    if (_hudTimer >= 0.2) {
      _hudTimer = 0;
      _publishHud();
    }
    if (_autosaveTimer >= 10) {
      _autosaveTimer = 0;
      unawaited(saveNow());
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutScene();
  }

  @override
  void onRemove() {
    unawaited(saveNow());
    super.onRemove();
  }

  void chooseAction(LegacyAction next) {
    action.value = next;
    if (next != LegacyAction.useSupply) selectedSupply.value = null;
  }

  void selectSupplyAction(LegacySupply supply) {
    if (dosesFor(supply) <= 0) return;
    selectedSupply.value = supply;
    action.value = LegacyAction.useSupply;
  }

  void enterFishBrowse() {
    fishMode.value = FishInteractionMode.browsing;
    _scene?.beginBrowsing();
  }

  void browseFish(int delta) {
    if (fishMode.value == FishInteractionMode.browsing) {
      _scene?.browse(delta);
    }
  }

  void selectIsolation() {
    final fish = _isolated;
    if (fish == null) return;
    _scene?.clearFocus();
    _focused = null;
    focusedFish.value = FishSelection.fromState(fish);
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
      final fish = _scene?.focusedFish;
      if (fish == null) return false;
      _focused = fish;
      _scene?.lockFocus();
      focusedFish.value = FishSelection.fromState(fish);
      fishMode.value = FishInteractionMode.selected;
      action.value = _isolated == null
          ? LegacyAction.isolate
          : LegacyAction.breed;
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
        case LegacyAction.moveSale:
          return _moveFocusedToSale();
        case LegacyAction.trash:
          return _trashFocused();
        case LegacyAction.breed:
          return _breedFocusedWithIsolation();
        case LegacyAction.species:
          return _focused != null || _isolated != null;
        default:
          return false;
      }
    }

    switch (action.value) {
      case LegacyAction.food:
        return _dropFood();
      case LegacyAction.switchTank:
        return _switchTank();
      case LegacyAction.useSupply:
        return useSelectedSupply();
      case LegacyAction.shop:
      case LegacyAction.saleTank:
        return true;
      default:
        return false;
    }
  }

  void clearEventMessage() {
    eventMessage.value = null;
  }

  int dosesFor(LegacySupply supply) {
    if (_isTreatmentSupply(supply)) {
      return _treatmentSlot == supply ? _treatmentDoses : 0;
    }
    if (_isEnhancementSupply(supply)) {
      return _enhancementSlot == supply ? _enhancementDoses : 0;
    }
    return 0;
  }

  bool isOwned(LegacySupply supply) =>
      _ownedItems.contains(LegacySupplyCatalog.of(supply).itemIndex);

  int researchLevelFor(LegacySupply supply) {
    switch (supply) {
      case LegacySupply.advertisingResearch:
        return _advertisingLevel;
      case LegacySupply.fishFoodResearch:
        return _foodResearchLevel;
      case LegacySupply.fishEnvironmentResearch:
        return _environmentLevel;
      default:
        return 0;
    }
  }

  double researchProgressFor(LegacySupply supply) {
    return _researchProgress[LegacySupplyCatalog.of(supply).itemIndex] ?? 0;
  }

  int shopPrice(LegacySupply supply) {
    final definition = LegacySupplyCatalog.of(supply);
    if (definition.isResearch) {
      return LegacySupplyCatalog.researchPrice(
        supply,
        researchLevelFor(supply),
      );
    }
    return definition.price;
  }

  String shopStatus(LegacySupply supply) {
    final definition = LegacySupplyCatalog.of(supply);
    if (definition.isResearch) {
      final level = researchLevelFor(supply);
      final progress = researchProgressFor(supply);
      if (level >= 3) return 'FULLY RESEARCHED!';
      if (progress > 0) {
        return 'RESEARCH IN PROGRESS... ${progress.floor()}%';
      }
      return 'YOU HAVE LEVEL $level';
    }
    if (definition.isConsumable) {
      final doses = dosesFor(supply);
      return doses > 0 ? '$doses DOSES' : 'NOT OWNED';
    }
    return isOwned(supply) ? 'OWNED' : 'NOT OWNED';
  }

  LegacySupply? occupyingSupplyFor(LegacySupply supply) {
    if (_isTreatmentSupply(supply)) return _treatmentSlot;
    if (_isEnhancementSupply(supply)) return _enhancementSlot;
    return null;
  }

  bool hasSupplySlotConflict(LegacySupply supply) {
    final occupant = occupyingSupplyFor(supply);
    return occupant != null && occupant != supply && dosesFor(occupant) > 0;
  }

  bool buySupply(LegacySupply supply, {bool replace = false}) {
    final definition = LegacySupplyCatalog.of(supply);
    if (definition.isResearch) return _startResearch(supply);
    if (definition.kind == LegacyShopKind.eggs) return _buyEggs(supply);

    if (definition.isConsumable &&
        hasSupplySlotConflict(supply) &&
        !replace) {
      eventMessage.value = 'REPLACE ITEM IN SLOT';
      return false;
    }
    if (!definition.isConsumable && isOwned(supply)) {
      eventMessage.value = 'YOU ALREADY OWN IT!';
      return false;
    }
    if (_coins < definition.price) {
      eventMessage.value = "YOU CAN'T AFFORD IT!";
      return false;
    }

    _spend(definition.price);
    if (_isTreatmentSupply(supply)) {
      _treatmentSlot = supply;
      _treatmentDoses = definition.dosesPerPurchase;
      selectSupplyAction(supply);
    } else if (_isEnhancementSupply(supply)) {
      _enhancementSlot = supply;
      _enhancementDoses = definition.dosesPerPurchase;
      selectSupplyAction(supply);
    } else {
      _ownedItems.add(definition.itemIndex);
    }

    eventMessage.value = supply == LegacySupply.secondTank
        ? 'SECOND TANK UNLOCKED!'
        : definition.isConsumable
            ? '${definition.name}  ${definition.dosesPerPurchase} DOSES'
            : '${definition.name} PURCHASED';
    _touch();
    unawaited(saveNow());
    return true;
  }

  bool buyFoodPack() {
    const price = 20;
    if (_coins < price) {
      eventMessage.value = "YOU CAN'T AFFORD IT!";
      return false;
    }
    _spend(price);
    _food += 20;
    eventMessage.value = 'FISH FOOD +20';
    _touch();
    return true;
  }

  bool useSelectedSupply() {
    final supply = selectedSupply.value;
    if (supply == null || dosesFor(supply) <= 0) return false;

    var affected = 0;
    switch (supply) {
      case LegacySupply.ichTreatment:
        affected = _healthService.treat(
          <FishState>[..._currentTank, if (_isolated != null) _isolated!],
          FishDisease.ich,
        );
        statistics.fishCured += affected;
      case LegacySupply.fungalTreatment:
        affected = _healthService.treat(
          <FishState>[..._currentTank, if (_isolated != null) _isolated!],
          FishDisease.fungus,
        );
        statistics.fishCured += affected;
      case LegacySupply.fishVitamins:
        affected = _healthService.applyVitamins(_currentTank);
      case LegacySupply.growthHormone:
        affected = _healthService.applyGrowthHormone(_currentTank);
      case LegacySupply.unknownChemical:
        affected = _healthService.applyUnknownChemical(_currentTank);
        for (final fish in _currentTank) {
          _registerSpecies(fish);
        }
        _requestSceneRebuild();
      default:
        return false;
    }

    _consumeSupplyDose(supply);
    eventMessage.value =
        '${LegacySupplyCatalog.of(supply).name}: $affected FISH AFFECTED';
    _touch();
    return true;
  }

  Future<void> newGame() async {
    _resetState();
    await _showTank(1, force: true);
    _publishHud();
    _touch();
    await saveNow();
  }

  Future<void> saveNow() async {
    if (!initialized.value) return;
    await _saveService.save(_snapshot());
  }

  void setSpeed(GameSpeed speed) {
    settings.speed = speed;
    _touch();
  }

  void toggleMusic() {
    settings.music = !settings.music;
    _touch();
  }

  void toggleSound() {
    settings.sound = !settings.sound;
    _touch();
  }

  void toggleHelpMessages() {
    settings.helpMessages = !settings.helpMessages;
    _touch();
  }

  int fairPriceFor(FishState fish) =>
      LegacyEconomyCatalog.fairPrice(fish.bodyIndex, fish.finIndex);

  int askingPriceFor(FishState fish) {
    final key = LegacyEconomyCatalog.speciesKey(fish.bodyIndex, fish.finIndex);
    return _askingPrices.putIfAbsent(
      key,
      () => LegacyEconomyCatalog.initialAskingPrice(
        fish.bodyIndex,
        fish.finIndex,
        _random,
      ),
    );
  }

  void adjustAskingPrice(FishState fish, int delta) {
    final key = LegacyEconomyCatalog.speciesKey(fish.bodyIndex, fish.finIndex);
    _askingPrices[key] = max(1, askingPriceFor(fish) + delta);
    _touch();
  }

  bool returnSaleFish(int index) {
    if (index < 0 || index >= _saleTank.length) return false;
    if (_currentTank.length >= maxFishPerTank) {
      eventMessage.value = 'TANK FULL!';
      return false;
    }
    final fish = _saleTank.removeAt(index);
    _currentTank.add(fish);
    if (_scene != null) unawaited(_scene!.addFish(fish));
    eventMessage.value = 'FISH RETURNED TO TANK';
    _touch();
    return true;
  }

  String simulateCustomerNow() {
    final result = _runCustomerVisit(force: true);
    eventMessage.value = result;
    _touch();
    return result;
  }

  void _resetState() {
    _tank1.clear();
    _tank2.clear();
    _saleTank.clear();
    _ownedItems.clear();
    _discoveredSpecies.clear();
    _magicFound.clear();
    _askingPrices.clear();
    _researchProgress.clear();
    _isolated = null;
    _focused = null;
    _isolationHomeTank = null;
    _coins = 300;
    _food = 30;
    _advertisingLevel = 1;
    _foodResearchLevel = 1;
    _environmentLevel = 1;
    _treatmentSlot = null;
    _treatmentDoses = 0;
    _enhancementSlot = null;
    _enhancementDoses = 0;
    settings = GameSettings();
    statistics = GameStatistics();
    currentTankNumber.value = 1;
    action.value = LegacyAction.food;
    selectedSupply.value = null;
    _seedFish();
  }

  void _seedFish() {
    const specialGenome = FishGenome(
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

    _tank1.addAll(<FishState>[
      _newFish(body: 0, fin: 0, age: 20, hunger: 0.78),
      _newFish(body: 1, fin: 1, age: 21, hunger: 0.84),
      _newFish(body: 2, fin: 4, age: 10, hunger: 0.88),
      FishState(
        species: SpeciesCatalog.sunny,
        genome: specialGenome,
        bodyIndex: 3,
        finIndex: 3,
        ageSeconds: 3 * FishState.secondsPerAgeAtNormalSpeed,
        hunger: 0.91,
      ),
    ]);
    for (final fish in _tank1) {
      _registerSpecies(fish);
    }
  }

  FishState _newFish({
    required int body,
    required int fin,
    required int age,
    double hunger = 0.9,
    double health = 1,
  }) {
    final visual = SpeciesCatalog.visualForLegacy(body, fin);
    return FishState(
      species: visual,
      genome: visual.founderGenome,
      bodyIndex: body,
      finIndex: fin,
      ageSeconds: age * FishState.secondsPerAgeAtNormalSpeed,
      hunger: hunger,
      health: health,
    );
  }

  void _advanceTank(List<FishState> tank, double dt) {
    if (tank.isEmpty) return;
    var sickCount = tank.where((fish) => fish.alive && fish.isSick).length;
    final magic = _magicPresent(tank);

    for (final fish in List<FishState>.from(tank)) {
      final steps = fish.tick(dt);
      for (var i = 0; i < steps && fish.alive; i++) {
        _healthService.advanceHealth(
          fish,
          environmentResearchLevel: _environmentLevel,
          ownsAerationSystem: _ownedItems.contains(9),
          ownsTemperatureRegulator: _ownedItems.contains(10),
        );
        if (magic.contains(4)) fish.addHealthPoints(1);
        if (_ownedItems.contains(12)) fish.addHealthPoints(1);

        if (fish.isSick &&
            magic.contains(2) &&
            _random.nextInt(100) < 20) {
          fish.cureDisease();
          statistics.fishCured++;
          sickCount = max(0, sickCount - 1);
        }

        final infected = _healthService.maybeInfect(
          fish,
          sickFishCount: sickCount,
          environmentResearchLevel: _environmentLevel,
          halveRiskProtection: _ownedItems.contains(15),
        );
        if (infected) sickCount++;

        _healthService.advanceFed(
          fish,
          foodResearchLevel: _foodResearchLevel,
          magicSustenance: magic.contains(1),
          ownsNutritionPlant: _ownedItems.contains(13),
        );
        if (magic.contains(3) && _random.nextInt(100) <= 10) {
          fish.addLegacyAge(1);
        }
      }
    }
  }

  void _advanceIsolated(double dt) {
    final fish = _isolated;
    if (fish == null) return;
    final homeTank = (_isolationHomeTank ?? 1) == 1 ? _tank1 : _tank2;
    final magic = _magicPresent(homeTank);
    final steps = fish.tick(dt);

    for (var i = 0; i < steps && fish.alive; i++) {
      _healthService.advanceHealth(
        fish,
        environmentResearchLevel: _environmentLevel,
        ownsAerationSystem: _ownedItems.contains(9),
        ownsTemperatureRegulator: _ownedItems.contains(10),
      );
      if (magic.contains(4)) fish.addHealthPoints(1);
      if (fish.isSick &&
          magic.contains(2) &&
          _random.nextInt(100) < 20) {
        fish.cureDisease();
        statistics.fishCured++;
      }
      _healthService.maybeInfect(
        fish,
        sickFishCount: 0,
        environmentResearchLevel: _environmentLevel,
        halveRiskProtection: _ownedItems.contains(15),
      );
      _healthService.advanceFed(
        fish,
        foodResearchLevel: _foodResearchLevel,
        magicSustenance: magic.contains(1),
        ownsNutritionPlant: _ownedItems.contains(13),
      );
      if (magic.contains(3) && _random.nextInt(100) <= 10) {
        fish.addLegacyAge(1);
      }
    }

    final father = fish.completePregnancyIfReady();
    if (father != null) _deliverBabies(fish, father);
  }

  Set<int> _magicPresent(List<FishState> tank) {
    final result = <int>{};
    for (final fish in tank) {
      if (!fish.alive) continue;
      final magic =
          LegacyEconomyCatalog.magicFor(fish.bodyIndex, fish.finIndex);
      if (magic != null) result.add(magic.index);
    }
    return result;
  }

  void _deliverBabies(
    FishState mother,
    ({int fatherBody, int fatherFin}) father,
  ) {
    final tankNumber = _isolationHomeTank ?? currentTankNumber.value;
    final target = tankNumber == 1 ? _tank1 : _tank2;
    final magic = _magicPresent(target);
    final child = LegacyBreedCatalog.childOf(
      motherBody: mother.bodyIndex,
      motherFin: mother.finIndex,
      fatherBody: father.fatherBody,
      fatherFin: father.fatherFin,
    );
    var body = child.body;
    var fin = child.fin;

    if (magic.contains(5) && _random.nextInt(100) <= 15) {
      if (_random.nextBool()) {
        body = _mutatedFamily(body);
      } else {
        fin = _mutatedFamily(fin);
      }
    }

    var requested = 1;
    if (magic.contains(0)) requested++;
    if (_ownedItems.contains(16)) requested++;
    var born = 0;

    for (var i = 0;
        i < requested && target.length < maxFishPerTank;
        i++) {
      final baby = _newFish(body: body, fin: fin, age: 0, hunger: 0.90);
      target.add(baby);
      _registerSpecies(baby);
      statistics.totalFishBred++;
      if (LegacyEconomyCatalog.magicFor(body, fin) != null) {
        statistics.magicFishBred++;
      }
      if (tankNumber == currentTankNumber.value && _scene != null) {
        unawaited(_scene!.addFish(baby));
      }
      born++;
    }

    if (born == 0) {
      eventMessage.value = 'TANK FULL! BABY FISH WAS EATEN.';
    } else if (born == 1) {
      eventMessage.value =
          'A NEW BABY WAS BORN! ${LegacyBreedCatalog.speciesName(body: body, fin: fin).toUpperCase()}';
    } else {
      eventMessage.value = '$born BABY FISH WERE BORN!';
    }
    _touch();
  }

  int _mutatedFamily(int value) {
    if (value <= 0) return 1;
    if (value >= 20) return 19;
    return _random.nextBool() ? value + 1 : value - 1;
  }

  bool _dropFood() {
    if (_food <= 0) {
      eventMessage.value = 'OUT OF FISH FOOD!';
      return false;
    }
    final dropped = _scene?.dropFood() ?? 0;
    if (dropped == 0) return false;
    _food--;
    statistics.foodGiven++;
    _touch();
    return true;
  }

  bool _isolateFocused() {
    if (_isolated != null) return false;
    final fish = _scene?.removeFocusedFish();
    if (fish == null) return false;
    _isolated = fish;
    _isolationHomeTank = currentTankNumber.value;
    isolationFish.value = FishSelection.fromState(fish);
    cancelFishInteraction();
    _touch();
    return true;
  }

  Future<bool> _releaseIsolation() async {
    final fish = _isolated;
    if (fish == null) return false;
    final tankNumber = _isolationHomeTank ?? currentTankNumber.value;
    final target = tankNumber == 1 ? _tank1 : _tank2;
    if (target.length >= maxFishPerTank) {
      eventMessage.value = 'TANK FULL!';
      return false;
    }

    _isolated = null;
    _isolationHomeTank = null;
    isolationFish.value = null;
    target.add(fish);
    if (tankNumber == currentTankNumber.value && _scene != null) {
      await _scene!.addFish(fish);
    }
    cancelFishInteraction();
    _touch();
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
    if (!mother.startPregnancy(mate)) return false;

    isolationFish.value = FishSelection.fromState(mother);
    eventMessage.value = 'FISH PREGNANT';
    cancelFishInteraction();
    _touch();
    return true;
  }

  bool _moveFocusedToOtherTank() {
    if (!ownsSecondTank) {
      eventMessage.value = "YOU DON'T OWN A SECOND TANK!";
      return false;
    }
    final target = currentTankNumber.value == 1 ? _tank2 : _tank1;
    if (target.length >= maxFishPerTank) {
      eventMessage.value = 'TANK FULL!';
      return false;
    }
    final fish = _scene?.removeFocusedFish();
    if (fish == null) return false;
    target.add(fish);
    cancelFishInteraction();
    _touch();
    return true;
  }

  bool _moveFocusedToSale() {
    final fish = _scene?.focusedFish;
    if (fish == null) return false;
    if (!fish.isAdult) {
      eventMessage.value = 'TOO YOUNG!';
      return false;
    }
    if (fish.isSick) {
      eventMessage.value = 'SICK FISH!';
      return false;
    }
    if (_saleTank.length >= maxFishPerTank) {
      eventMessage.value = 'SALE TANK FULL!';
      return false;
    }
    final removed = _scene?.removeFocusedFish();
    if (removed == null) return false;
    _saleTank.add(removed);
    cancelFishInteraction();
    eventMessage.value = 'FISH MOVED TO SALE TANK';
    _touch();
    return true;
  }

  bool _trashFocused() {
    final fish = _scene?.removeFocusedFish();
    if (fish == null) return false;
    _tank1.remove(fish);
    _tank2.remove(fish);
    statistics.fishTrashed++;
    cancelFishInteraction();
    _touch();
    return true;
  }

  Future<bool> _switchTank() async {
    if (currentTankNumber.value == 1 && !ownsSecondTank) {
      eventMessage.value =
          "YOU DON'T OWN A SECOND TANK! IT ALLOWS YOU TO BREED MORE FISH. YOU CAN BUY THIS TANK AT THE SUPPLY SHOP.";
      return false;
    }
    await _showTank(currentTankNumber.value == 1 ? 2 : 1);
    return true;
  }

  Future<void> _showTank(int number, {bool force = false}) async {
    if (number == 2 && !ownsSecondTank && !force) return;
    final old = _scene;
    if (old != null) old.removeFromParent();

    currentTankNumber.value = number;
    final scene = TankScene(
      tankNumber: number,
      backgroundAsset: number == 1
          ? 'art/tank_freshwater.webp'
          : 'art/tank_tropical.webp',
      fishStates: number == 1 ? _tank1 : _tank2,
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

  bool _buyEggs(LegacySupply supply) {
    final definition = LegacySupplyCatalog.of(supply);
    if (_environmentLevel < definition.requiredEnvironmentLevel) {
      eventMessage.value = 'RESEARCH FISH ENVIRONMENT FIRST.';
      return false;
    }
    if (_currentTank.length >= maxFishPerTank) {
      eventMessage.value = 'TANK FULL!';
      return false;
    }
    if (_coins < definition.price) {
      eventMessage.value = "YOU CAN'T AFFORD IT!";
      return false;
    }

    _spend(definition.price);
    final rarity = supply == LegacySupply.commonFishEggs
        ? 0
        : supply == LegacySupply.unusualFishEggs
            ? 1
            : 2;
    final count = _ownedItems.contains(14) ? 4 : 3;
    var hatched = 0;

    for (var i = 0;
        i < count && _currentTank.length < maxFishPerTank;
        i++) {
      final fish = _newFish(
        body: _eggFamily(rarity),
        fin: _eggFamily(rarity),
        age: 0,
        hunger: 0.95,
      );
      _currentTank.add(fish);
      _registerSpecies(fish);
      if (_scene != null) unawaited(_scene!.addFish(fish));
      hatched++;
    }
    eventMessage.value = '$hatched FISH HATCHED FROM ${definition.name}';
    _touch();
    return true;
  }

  int _eggFamily(int rarity) {
    if (rarity == 0) return _random.nextInt(8);
    if (rarity == 1) return 4 + _random.nextInt(11);
    return 10 + _random.nextInt(11);
  }

  bool _startResearch(LegacySupply supply) {
    final definition = LegacySupplyCatalog.of(supply);
    final level = researchLevelFor(supply);
    if (level >= 3) {
      eventMessage.value = 'FULLY RESEARCHED!';
      return false;
    }

    final itemIndex = definition.itemIndex;
    final existingProgress = _researchProgress[itemIndex] ?? 0;
    if (existingProgress > 0 && existingProgress < 100) {
      eventMessage.value =
          'RESEARCH IN PROGRESS... ${existingProgress.floor()}%';
      return false;
    }

    final price = LegacySupplyCatalog.researchPrice(supply, level);
    if (_coins < price) {
      eventMessage.value = "YOU CAN'T AFFORD IT!";
      return false;
    }
    _spend(price);
    _researchProgress[itemIndex] = 1;
    eventMessage.value = 'RESEARCH IN PROGRESS... 1%';
    _touch();
    return true;
  }

  void _advanceResearch(double dt) {
    if (settings.speed == GameSpeed.paused || _researchProgress.isEmpty) {
      return;
    }
    final perSecond = 2 / (60 * settings.speed.legacyMinutesPerAge);
    final completed = <int>[];
    final entries = _researchProgress.entries.toList(growable: false);
    for (final entry in entries) {
      final next = min(100.0, entry.value + dt * perSecond);
      _researchProgress[entry.key] = next;
      if (next >= 100) completed.add(entry.key);
    }

    for (final item in completed) {
      _researchProgress.remove(item);
      if (item == 8) _advertisingLevel = min(3, _advertisingLevel + 1);
      if (item == 17) _foodResearchLevel = min(3, _foodResearchLevel + 1);
      if (item == 26) _environmentLevel = min(3, _environmentLevel + 1);
      final supply = _supplyByItemIndex(item);
      if (supply != null) {
        eventMessage.value =
            'YOU COMPLETED A LEVEL OF ${LegacySupplyCatalog.of(supply).name}.';
      }
      _touch();
    }
  }

  void _advanceCustomers(double dt) {
    if (_saleTank.isEmpty || settings.speed == GameSpeed.paused) return;
    _customerTimer += dt * settings.speed.simulationMultiplier;
    final ornamentCount =
        _ownedItems.where((item) => item >= 18 && item <= 23).length;
    final interval =
        max(3.0, 12.0 - _advertisingLevel * 1.6 - ornamentCount * 0.35);
    if (_customerTimer < interval) return;
    _customerTimer = 0;
    _runCustomerVisit(force: false);
  }

  String _runCustomerVisit({required bool force}) {
    if (_saleTank.isEmpty) return 'NO FISH';
    final candidates = _saleTank
        .where((fish) => fish.alive && fish.isAdult && !fish.isSick)
        .toList(growable: false);
    if (candidates.isEmpty) {
      if (_saleTank.any((fish) => fish.isSick)) return 'SICK FISH!';
      return 'TOO YOUNG!';
    }

    final fish = candidates[_random.nextInt(candidates.length)];
    final fair = fairPriceFor(fish);
    final ask = askingPriceFor(fish);
    final ratio = ask / max(1, fair);
    var chance = 7;
    if (ratio <= 1) {
      chance = 72;
    } else if (ratio <= 1.25) {
      chance = 48;
    } else if (ratio <= 1.5) {
      chance = 24;
    }
    chance += (_advertisingLevel - 1) * 8;
    chance +=
        _ownedItems.where((item) => item >= 18 && item <= 23).length * 2;
    if (_ownedItems.contains(11)) chance += 2;
    chance = chance.clamp(2, 95).toInt();

    final requiredChance = force ? max(chance, 40) : chance;
    if (_random.nextInt(100) >= requiredChance) {
      if (ratio > 1.5) {
        return _random.nextBool() ? 'TOO EXPENSIVE' : 'OVERPRICED';
      }
      if (ratio > 1.15) return 'COSTS TOO MUCH';
      return _random.nextBool() ? 'NICE SELECTION' : 'BEAUTIFUL!';
    }

    _saleTank.remove(fish);
    _coins += ask;
    statistics.fishSold++;
    statistics.moneyEarned += ask;
    statistics.topFishPrice = max(statistics.topFishPrice, ask);
    eventMessage.value = 'SOLD FOR \$$ask';
    _touch();
    return 'SOLD FOR \$$ask';
  }

  void _cleanupDeadFish() {
    final before1 = _tank1.length;
    final before2 = _tank2.length;
    _tank1.removeWhere((fish) => !fish.alive);
    _tank2.removeWhere((fish) => !fish.alive);
    _saleTank.removeWhere((fish) => !fish.alive);

    if (_isolated != null && !_isolated!.alive) {
      _isolated = null;
      _isolationHomeTank = null;
      isolationFish.value = null;
    }

    final currentChanged =
        currentTankNumber.value == 1 && before1 != _tank1.length ||
            currentTankNumber.value == 2 && before2 != _tank2.length;
    if (currentChanged && _scene != null) {
      _requestSceneRebuild();
      _touch();
    }
  }

  void _requestSceneRebuild() {
    if (_sceneRebuildPending || _scene == null) return;
    _sceneRebuildPending = true;
    unawaited(
      _showTank(currentTankNumber.value, force: true).whenComplete(() {
        _sceneRebuildPending = false;
      }),
    );
  }

  void _registerSpecies(FishState fish) {
    final key = LegacyEconomyCatalog.speciesKey(fish.bodyIndex, fish.finIndex);
    if (_discoveredSpecies.add(key)) {
      _askingPrices[key] = LegacyEconomyCatalog.initialAskingPrice(
        fish.bodyIndex,
        fish.finIndex,
        _random,
      );
    }
    final magic =
        LegacyEconomyCatalog.magicFor(fish.bodyIndex, fish.finIndex);
    if (magic != null) _magicFound.add(magic.index);
  }

  void _spend(int amount) {
    _coins -= amount;
    statistics.moneySpent += amount;
  }

  bool _isTreatmentSupply(LegacySupply supply) =>
      supply == LegacySupply.ichTreatment ||
      supply == LegacySupply.fungalTreatment;

  bool _isEnhancementSupply(LegacySupply supply) =>
      supply == LegacySupply.fishVitamins ||
      supply == LegacySupply.growthHormone ||
      supply == LegacySupply.unknownChemical;

  void _consumeSupplyDose(LegacySupply supply) {
    if (_isTreatmentSupply(supply)) {
      if (_treatmentSlot != supply) return;
      _treatmentDoses = max(0, _treatmentDoses - 1);
      if (_treatmentDoses == 0) _treatmentSlot = null;
    } else if (_isEnhancementSupply(supply)) {
      if (_enhancementSlot != supply) return;
      _enhancementDoses = max(0, _enhancementDoses - 1);
      if (_enhancementDoses == 0) _enhancementSlot = null;
    }

    if (dosesFor(supply) <= 0 && selectedSupply.value == supply) {
      selectedSupply.value = null;
      action.value = LegacyAction.food;
    }
  }

  LegacySupply? _supplyByItemIndex(int itemIndex) {
    for (final supply in LegacySupply.values) {
      if (LegacySupplyCatalog.of(supply).itemIndex == itemIndex) return supply;
    }
    return null;
  }

  void _onFishFocused(FishState? fish) {
    _focused = fish;
    focusedFish.value =
        fish == null ? null : FishSelection.fromState(fish);
  }

  void _publishHud() {
    hud.value = GameHudState(
      coins: _coins,
      food: _food,
      fishCount: _currentTank.where((fish) => fish.alive).length,
      averageHunger: _average(_currentTank, (fish) => fish.hunger),
      averageHealth: _average(_currentTank, (fish) => fish.health),
    );
    if (_focused != null) {
      focusedFish.value = FishSelection.fromState(_focused!);
    }
    if (_isolated != null) {
      isolationFish.value = FishSelection.fromState(_isolated!);
    }
  }

  double _average(
    List<FishState> fish,
    double Function(FishState fish) read,
  ) {
    final living = fish.where((state) => state.alive).toList(growable: false);
    if (living.isEmpty) return 0;
    var total = 0.0;
    for (final state in living) {
      total += read(state);
    }
    return total / living.length;
  }

  void _touch() {
    revision.value++;
    _publishHud();
  }

  Map<String, dynamic> _snapshot() {
    return <String, dynamic>{
      'schemaVersion': saveSchemaVersion,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'coins': _coins,
      'food': _food,
      'currentTank': currentTankNumber.value,
      'tank1': _tank1.map((fish) => fish.toJson()).toList(),
      'tank2': _tank2.map((fish) => fish.toJson()).toList(),
      'saleTank': _saleTank.map((fish) => fish.toJson()).toList(),
      'isolated': _isolated?.toJson(),
      'isolationHomeTank': _isolationHomeTank,
      'ownedItems': _ownedItems.toList(),
      'discoveredSpecies': _discoveredSpecies.toList(),
      'magicFound': _magicFound.toList(),
      'askingPrices': _askingPrices,
      'researchLevels': <String, int>{
        'advertising': _advertisingLevel,
        'food': _foodResearchLevel,
        'environment': _environmentLevel,
      },
      'researchProgress': _researchProgress.map(
        (key, value) => MapEntry<String, double>('$key', value),
      ),
      'treatmentSlot': _treatmentSlot == null
          ? null
          : LegacySupplyCatalog.of(_treatmentSlot!).itemIndex,
      'treatmentDoses': _treatmentDoses,
      'enhancementSlot': _enhancementSlot == null
          ? null
          : LegacySupplyCatalog.of(_enhancementSlot!).itemIndex,
      'enhancementDoses': _enhancementDoses,
      'settings': settings.toJson(),
      'statistics': statistics.toJson(),
    };
  }

  void _restore(Map<String, dynamic> json) {
    _tank1
      ..clear()
      ..addAll(_fishList(json['tank1']));
    _tank2
      ..clear()
      ..addAll(_fishList(json['tank2']));
    _saleTank
      ..clear()
      ..addAll(_fishList(json['saleTank']));

    _coins = _intOr(json['coins'], 300);
    _food = _intOr(json['food'], 30);
    currentTankNumber.value = _intOr(json['currentTank'], 1) == 2 ? 2 : 1;

    _ownedItems
      ..clear()
      ..addAll(_intSet(json['ownedItems']));
    _discoveredSpecies
      ..clear()
      ..addAll(_stringSet(json['discoveredSpecies']));
    _magicFound
      ..clear()
      ..addAll(_intSet(json['magicFound']));
    _askingPrices
      ..clear()
      ..addAll(_intMap(json['askingPrices']));

    final levels = json['researchLevels'] is Map
        ? Map<String, dynamic>.from(json['researchLevels'] as Map)
        : <String, dynamic>{};
    _advertisingLevel = _intOr(levels['advertising'], 1).clamp(1, 3).toInt();
    _foodResearchLevel = _intOr(levels['food'], 1).clamp(1, 3).toInt();
    _environmentLevel = _intOr(levels['environment'], 1).clamp(1, 3).toInt();

    _researchProgress.clear();
    final progress = json['researchProgress'];
    if (progress is Map) {
      for (final entry in progress.entries) {
        final key = int.tryParse('${entry.key}');
        if (key != null && entry.value is num) {
          _researchProgress[key] = (entry.value as num).toDouble();
        }
      }
    }

    _treatmentSlot =
        _supplyByItemIndex(_nullableInt(json['treatmentSlot']) ?? -1);
    _treatmentDoses = _intOr(json['treatmentDoses'], 0);
    _enhancementSlot =
        _supplyByItemIndex(_nullableInt(json['enhancementSlot']) ?? -1);
    _enhancementDoses = _intOr(json['enhancementDoses'], 0);

    settings = GameSettings.fromJson(
      json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : null,
    );
    statistics = GameStatistics.fromJson(
      json['statistics'] is Map
          ? Map<String, dynamic>.from(json['statistics'] as Map)
          : null,
    );

    final isolatedJson = json['isolated'];
    _isolated = isolatedJson is Map
        ? FishState.fromJson(Map<String, dynamic>.from(isolatedJson))
        : null;
    _isolationHomeTank = _nullableInt(json['isolationHomeTank']);

    final allFish = <FishState>[
      ..._tank1,
      ..._tank2,
      ..._saleTank,
      if (_isolated != null) _isolated!,
    ];
    for (final fish in allFish) {
      _registerSpecies(fish);
    }
    if (currentTankNumber.value == 2 && !ownsSecondTank) {
      currentTankNumber.value = 1;
    }
  }

  void _applyOfflineProgress(Map<String, dynamic> json) {
    final savedAt = _nullableInt(json['savedAt']);
    if (savedAt == null || settings.speed == GameSpeed.paused) return;
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - savedAt) / 1000.0;
    if (elapsed <= 1) return;

    final safeElapsed = min(elapsed, 60 * 60 * 24 * 30).toDouble();
    final simulationDt = safeElapsed * settings.speed.simulationMultiplier;
    _advanceTank(_tank1, simulationDt);
    _advanceTank(_tank2, simulationDt);
    _advanceIsolated(simulationDt);
    _advanceResearch(safeElapsed);
    _cleanupDeadFish();
    eventMessage.value =
        'OFFLINE PROGRESS: ${(safeElapsed / 60).floor()} MIN';
  }

  List<FishState> _fishList(dynamic value) {
    if (value is! List) return <FishState>[];
    final result = <FishState>[];
    for (final entry in value) {
      if (entry is Map) {
        result.add(FishState.fromJson(Map<String, dynamic>.from(entry)));
      }
    }
    return result;
  }

  Set<int> _intSet(dynamic value) {
    if (value is! List) return <int>{};
    final result = <int>{};
    for (final entry in value) {
      if (entry is num) result.add(entry.toInt());
    }
    return result;
  }

  Set<String> _stringSet(dynamic value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  Map<String, int> _intMap(dynamic value) {
    final result = <String, int>{};
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.value is num) {
          result['${entry.key}'] = (entry.value as num).toInt();
        }
      }
    }
    return result;
  }

  static int _intOr(dynamic value, int fallback) =>
      value is num ? value.toInt() : fallback;
  static int? _nullableInt(dynamic value) =>
      value is num ? value.toInt() : null;
}
