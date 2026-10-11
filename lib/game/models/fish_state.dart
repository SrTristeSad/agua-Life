import '../data/legacy_breed_catalog.dart';
import 'fish_disease.dart';
import 'fish_genome.dart';
import 'fish_species.dart';

class FishState {
  FishState({
    required this.species,
    required this.genome,
    required int bodyIndex,
    required int finIndex,
    double hunger = 0.85,
    double health = 1,
    this.ageSeconds = 0,
    this.disease = FishDisease.none,
  })  : _bodyIndex = bodyIndex,
        _finIndex = finIndex,
        _hunger = hunger.clamp(0, 1).toDouble(),
        _health = health.clamp(0, 1).toDouble() {
    _checkFamilyIndices();
    if (_health <= 0) alive = false;
  }

  static const int adultAge = 20;
  static const int pregnancyAgeSteps = 3;
  static const double secondsPerAgeAtNormalSpeed = 600;
  static const double adulthoodSeconds =
      adultAge * secondsPerAgeAtNormalSpeed;

  final FishSpecies species;
  final FishGenome genome;
  int _bodyIndex;
  int _finIndex;

  double ageSeconds;
  double _hunger;
  double _health;
  bool alive = true;
  FishDisease disease;

  int? _pregnancyTargetAge;
  int? _pregnancyFatherBody;
  int? _pregnancyFatherFin;

  int get bodyIndex => _bodyIndex;
  int get finIndex => _finIndex;
  double get hunger => _hunger;
  double get health => _health;
  int get fedPoints => (_hunger * 100).round().clamp(0, 100).toInt();
  int get healthPoints => (_health * 100).round().clamp(0, 100).toInt();

  int get age => ageSeconds ~/ secondsPerAgeAtNormalSpeed;
  bool get isAdult => age >= adultAge;
  bool get isSick => disease != FishDisease.none;

  String get legacySpeciesName => LegacyBreedCatalog.speciesName(
        body: _bodyIndex,
        fin: _finIndex,
      );

  bool get pregnant => _pregnancyTargetAge != null;

  int get pregnancyAgesRemaining {
    final target = _pregnancyTargetAge;
    if (target == null) return 0;
    return (target + 1 - age).clamp(0, pregnancyAgeSteps + 1).toInt();
  }

  double get growthProgress =>
      (ageSeconds / adulthoodSeconds).clamp(0, 1).toDouble();

  double get visualScale => 0.78 + growthProgress * 0.22;

  int tick(double dt) {
    if (!alive || dt <= 0) return 0;
    final previousAge = age;
    ageSeconds += dt;
    return age - previousAge;
  }

  void feed([double amount = 0.38]) {
    if (!alive) return;
    _hunger = (_hunger + amount).clamp(0, 1).toDouble();
  }

  void setFedPoints(int value) {
    _hunger = value.clamp(0, 100).toInt() / 100;
  }

  void addFedPoints(int delta) {
    setFedPoints(fedPoints + delta);
  }

  void setHealthPoints(int value) {
    _health = value.clamp(0, 100).toInt() / 100;
    if (_health <= 0) alive = false;
  }

  void addHealthPoints(int delta) {
    if (!alive && delta <= 0) return;
    setHealthPoints(healthPoints + delta);
  }

  void addLegacyAge(int ages) {
    if (!alive || ages <= 0) return;
    ageSeconds += ages * secondsPerAgeAtNormalSpeed;
  }

  void infect(FishDisease next) {
    if (!alive || next == FishDisease.none || isSick) return;
    disease = next;
    _clearPregnancy();
  }

  void cureDisease() {
    if (!alive) return;
    disease = FishDisease.none;
  }

  void mutateLegacyFamily({int? bodyIndex, int? finIndex}) {
    if (bodyIndex != null) _bodyIndex = bodyIndex;
    if (finIndex != null) _finIndex = finIndex;
    _checkFamilyIndices();
  }

  bool startPregnancy(FishState mate) {
    if (!alive ||
        !mate.alive ||
        isSick ||
        mate.isSick ||
        !isAdult ||
        !mate.isAdult ||
        pregnant) {
      return false;
    }

    _pregnancyFatherBody = mate.bodyIndex;
    _pregnancyFatherFin = mate.finIndex;
    _pregnancyTargetAge = age + pregnancyAgeSteps;
    return true;
  }

  ({int fatherBody, int fatherFin})? completePregnancyIfReady() {
    final target = _pregnancyTargetAge;
    final fatherBody = _pregnancyFatherBody;
    final fatherFin = _pregnancyFatherFin;
    if (target == null || fatherBody == null || fatherFin == null) {
      return null;
    }

    if (age <= target) return null;

    _clearPregnancy();
    return (fatherBody: fatherBody, fatherFin: fatherFin);
  }

  void _clearPregnancy() {
    _pregnancyTargetAge = null;
    _pregnancyFatherBody = null;
    _pregnancyFatherFin = null;
  }

  void _checkFamilyIndices() {
    RangeError.checkValidIndex(
      _bodyIndex,
      LegacyBreedCatalog.bodyFamilies,
      'bodyIndex',
    );
    RangeError.checkValidIndex(
      _finIndex,
      LegacyBreedCatalog.finFamilies,
      'finIndex',
    );
  }
}
