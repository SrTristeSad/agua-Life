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
    // The J2ME birth predicate is targetAge < currentAge, so the target age
    // itself is still pregnant.
    return (target + 1 - age).clamp(0, pregnancyAgeSteps + 1);
  }

  double get growthProgress =>
      (ageSeconds / adulthoodSeconds).clamp(0, 1).toDouble();

  double get visualScale => 0.78 + growthProgress * 0.22;

  void tick(double dt) {
    if (!alive || dt <= 0) {
      return;
    }

    final previousAge = age;
    ageSeconds += dt;
    final currentAge = age;

    // In the legacy simulation feeding/health pressure is processed once for
    // each age step, not continuously every rendered second. This baseline is
    // the level-1 food behavior recovered from n.a(m, boolean). Research and
    // Magic Fish modifiers are layered on later by the simulation service.
    for (var step = previousAge; step < currentAge && alive; step++) {
      _advanceLegacyNeedsOneAge();
    }
  }

  void _advanceLegacyNeedsOneAge() {
    _hunger = (_hunger - 0.01).clamp(0, 1).toDouble();

    // The J2ME code clamps FED to zero at <=2 and removes one HEALTH point.
    if (_hunger <= 0.02) {
      _hunger = 0;
      _health = (_health - 0.01).clamp(0, 1).toDouble();
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

    // Exact predicate from m.h(): pregnancyTargetAge < currentAge.
    if (age <= target) {
      return null;
    }

    _pregnancyTargetAge = null;
    _pregnancyFatherBody = null;
    _pregnancyFatherFin = null;
    return (fatherBody: fatherBody, fatherFin: fatherFin);
  }
}
