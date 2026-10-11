import '../data/legacy_breed_catalog.dart';
import '../data/species_catalog.dart';
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
  static const double adulthoodSeconds = adultAge * secondsPerAgeAtNormalSpeed;

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

  String get legacySpeciesName => LegacyBreedCatalog.speciesName(body: _bodyIndex, fin: _finIndex);
  bool get pregnant => _pregnancyTargetAge != null;

  int get pregnancyAgesRemaining {
    final target = _pregnancyTargetAge;
    if (target == null) return 0;
    return (target + 1 - age).clamp(0, pregnancyAgeSteps + 1).toInt();
  }

  double get growthProgress => (ageSeconds / adulthoodSeconds).clamp(0, 1).toDouble();
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

  void setFedPoints(int value) => _hunger = value.clamp(0, 100).toInt() / 100;
  void addFedPoints(int delta) => setFedPoints(fedPoints + delta);

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
    if (alive) disease = FishDisease.none;
  }

  void mutateLegacyFamily({int? bodyIndex, int? finIndex}) {
    if (bodyIndex != null) _bodyIndex = bodyIndex;
    if (finIndex != null) _finIndex = finIndex;
    _checkFamilyIndices();
  }

  bool startPregnancy(FishState mate) {
    if (!alive || !mate.alive || isSick || mate.isSick || !isAdult || !mate.isAdult || pregnant) {
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
    if (target == null || fatherBody == null || fatherFin == null || age <= target) return null;
    _clearPregnancy();
    return (fatherBody: fatherBody, fatherFin: fatherFin);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'body': _bodyIndex,
        'fin': _finIndex,
        'ageSeconds': ageSeconds,
        'hunger': _hunger,
        'health': _health,
        'alive': alive,
        'disease': disease.name,
        'pregnancyTargetAge': _pregnancyTargetAge,
        'pregnancyFatherBody': _pregnancyFatherBody,
        'pregnancyFatherFin': _pregnancyFatherFin,
        'genome': <String, dynamic>{
          'primaryColor': genome.primaryColor,
          'secondaryColor': genome.secondaryColor,
          'pattern': genome.pattern.name,
          'bodyScale': genome.bodyScale,
          'finScale': genome.finScale,
          'growthRate': genome.growthRate,
          'diseaseResistance': genome.diseaseResistance,
          'fertility': genome.fertility,
          'valueModifier': genome.valueModifier,
          'shimmer': genome.shimmer,
        },
      };

  static FishState fromJson(Map<String, dynamic> json) {
    final body = _int(json['body']).clamp(0, 20).toInt();
    final fin = _int(json['fin']).clamp(0, 20).toInt();
    final visual = SpeciesCatalog.visualForLegacy(body, fin);
    final genomeJson = json['genome'] is Map
        ? Map<String, dynamic>.from(json['genome'] as Map)
        : <String, dynamic>{};

    var pattern = visual.founderGenome.pattern;
    final patternName = genomeJson['pattern'] as String?;
    for (final candidate in FishPattern.values) {
      if (candidate.name == patternName) pattern = candidate;
    }
    var disease = FishDisease.none;
    final diseaseName = json['disease'] as String?;
    for (final candidate in FishDisease.values) {
      if (candidate.name == diseaseName) disease = candidate;
    }

    final state = FishState(
      species: visual,
      genome: FishGenome(
        primaryColor: _intOr(genomeJson['primaryColor'], visual.founderGenome.primaryColor),
        secondaryColor: _intOr(genomeJson['secondaryColor'], visual.founderGenome.secondaryColor),
        pattern: pattern,
        bodyScale: _doubleOr(genomeJson['bodyScale'], visual.founderGenome.bodyScale),
        finScale: _doubleOr(genomeJson['finScale'], visual.founderGenome.finScale),
        growthRate: _doubleOr(genomeJson['growthRate'], visual.founderGenome.growthRate),
        diseaseResistance: _doubleOr(genomeJson['diseaseResistance'], visual.founderGenome.diseaseResistance),
        fertility: _doubleOr(genomeJson['fertility'], visual.founderGenome.fertility),
        valueModifier: _doubleOr(genomeJson['valueModifier'], visual.founderGenome.valueModifier),
        shimmer: genomeJson['shimmer'] is bool ? genomeJson['shimmer'] as bool : visual.founderGenome.shimmer,
      ),
      bodyIndex: body,
      finIndex: fin,
      hunger: _doubleOr(json['hunger'], 0.85),
      health: _doubleOr(json['health'], 1),
      ageSeconds: _doubleOr(json['ageSeconds'], 0),
      disease: disease,
    );
    state.alive = json['alive'] is bool ? json['alive'] as bool : state.health > 0;
    state._pregnancyTargetAge = _nullableInt(json['pregnancyTargetAge']);
    state._pregnancyFatherBody = _nullableInt(json['pregnancyFatherBody']);
    state._pregnancyFatherFin = _nullableInt(json['pregnancyFatherFin']);
    return state;
  }

  void _clearPregnancy() {
    _pregnancyTargetAge = null;
    _pregnancyFatherBody = null;
    _pregnancyFatherFin = null;
  }

  void _checkFamilyIndices() {
    RangeError.checkValidIndex(_bodyIndex, LegacyBreedCatalog.bodyFamilies, 'bodyIndex');
    RangeError.checkValidIndex(_finIndex, LegacyBreedCatalog.finFamilies, 'finIndex');
  }

  static int _int(dynamic value) => value is num ? value.toInt() : 0;
  static int _intOr(dynamic value, int fallback) => value is num ? value.toInt() : fallback;
  static int? _nullableInt(dynamic value) => value is num ? value.toInt() : null;
  static double _doubleOr(dynamic value, double fallback) => value is num ? value.toDouble() : fallback;
}
