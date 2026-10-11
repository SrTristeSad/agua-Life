import '../data/legacy_breed_catalog.dart';
import 'fish_genome.dart';
import 'fish_species.dart';

class FishState {
  FishState({
    required this.species,
    required this.genome,
    required this.bodyIndex,
    required this.finIndex,
    double hunger = 0.85,
    double health = 1,
    this.ageSeconds = 0,
  })  : _hunger = hunger.clamp(0, 1).toDouble(),
        _health = health.clamp(0, 1).toDouble() {
    RangeError.checkValidIndex(
      bodyIndex,
      LegacyBreedCatalog.bodyFamilies,
      'bodyIndex',
    );
    RangeError.checkValidIndex(
      finIndex,
      LegacyBreedCatalog.finFamilies,
      'finIndex',
    );
  }

  static const int adultAge = 20;
  static const int pregnancyAgeSteps = 3;
  static const double secondsPerAgeAtNormalSpeed = 600;
  static const double adulthoodSeconds =
      adultAge * secondsPerAgeAtNormalSpeed;

  final FishSpecies species;
  final FishGenome genome;
  final int bodyIndex;
  final int finIndex;

  double ageSeconds;
  double _hunger;
  double _health;
  bool alive = true;

  int? _pregnancyTargetAge;
  int? _pregnancyFatherBody;
  int? _pregnancyFatherFin;

  double get hunger => _hunger;
  double get health => _health;

  int get age => ageSeconds ~/ secondsPerAgeAtNormalSpeed;
  bool get isAdult => age >= adultAge;

  String get legacySpeciesName => LegacyBreedCatalog.speciesName(
        body: bodyIndex,
        fin: finIndex,
      );

  bool get pregnant => _pregnancyTargetAge != null;

  int get pregnancyAgesRemaining {
    final target = _pregnancyTargetAge;
    if (target == null) return 0;
    return (target - age).clamp(0, pregnancyAgeSteps);
  }

  double get growthProgress =>
      (ageSeconds / adulthoodSeconds).clamp(0, 1).toDouble();

  double get visualScale => 0.78 + growthProgress * 0.22;

  void tick(double dt) {
    if (!alive || dt <= 0) {
      return;
    }

    ageSeconds += dt;

    final hungerBurn = 0.00125 * genome.growthRate;
    _hunger = (_hunger - hungerBurn * dt).clamp(0, 1).toDouble();

    if (_hunger < 0.18) {
      final resistance = genome.diseaseResistance.clamp(0.5, 2).toDouble();
      _health = (_health - (0.0014 / resistance) * dt)
          .clamp(0, 1)
          .toDouble();
    } else if (_hunger > 0.45 && _health < 1) {
      _health = (_health + 0.00035 * genome.diseaseResistance * dt)
          .clamp(0, 1)
          .toDouble();
    }

    if (_health <= 0) {
      alive = false;
    }
  }

  void feed([double amount = 0.38]) {
    if (!alive) {
      return;
    }

    _hunger = (_hunger + amount).clamp(0, 1).toDouble();
    _health = (_health + 0.015).clamp(0, 1).toDouble();
  }

  bool startPregnancy(FishState mate) {
    if (!alive || !mate.alive || !isAdult || !mate.isAdult || pregnant) {
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
    if (age < target) {
      return null;
    }

    _pregnancyTargetAge = null;
    _pregnancyFatherBody = null;
    _pregnancyFatherFin = null;
    return (fatherBody: fatherBody, fatherFin: fatherFin);
  }
}
