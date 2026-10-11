import 'package:agua_life/game/data/species_catalog.dart';
import 'package:agua_life/game/models/fish_disease.dart';
import 'package:agua_life/game/models/fish_state.dart';
import 'package:agua_life/game/services/legacy_health_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FixedRolls {
  FixedRolls(List<int> values) : _values = List<int>.from(values);

  final List<int> _values;

  int call(int maxExclusive) {
    if (_values.isEmpty) {
      throw StateError('No fixed roll remaining for max=$maxExclusive');
    }
    final value = _values.removeAt(0);
    if (value < 0 || value >= maxExclusive) {
      throw RangeError.range(value, 0, maxExclusive - 1);
    }
    return value;
  }
}

FishState fish({
  int body = 0,
  int fin = 0,
  int age = 20,
  int fed = 80,
  int health = 100,
}) {
  return FishState(
    species: SpeciesCatalog.sunny,
    genome: SpeciesCatalog.sunny.founderGenome,
    bodyIndex: body,
    finIndex: fin,
    ageSeconds: age * FishState.secondsPerAgeAtNormalSpeed,
    hunger: fed / 100,
    health: health / 100,
  );
}

void main() {
  group('LegacyHealthService', () {
    test('normal treatment cures at roll 39 but not at 40', () {
      final curedFish = fish()..infect(FishDisease.ich);
      final failedFish = fish()..infect(FishDisease.ich);
      final service = LegacyHealthService(roll: FixedRolls([39, 40]).call);

      final cured = service.treat(
        [curedFish, failedFish],
        FishDisease.ich,
      );

      expect(cured, 1);
      expect(curedFish.disease, FishDisease.none);
      expect(failedFish.disease, FishDisease.ich);
    });

    test('vitamins add random(10)+6 health points', () {
      final state = fish(health: 50);
      final service = LegacyHealthService(roll: FixedRolls([0]).call);

      service.applyVitamins([state]);

      expect(state.healthPoints, 56);
    });

    test('growth hormone adds random(5)+2 ages only through age 40', () {
      final young = fish(age: 40);
      final old = fish(age: 41);
      final service = LegacyHealthService(roll: FixedRolls([4]).call);

      final affected = service.applyGrowthHormone([young, old]);

      expect(affected, 1);
      expect(young.age, 46);
      expect(old.age, 41);
    });

    test('unknown chemical mutates inward at family boundary', () {
      final state = fish(body: 0, fin: 20);
      final service = LegacyHealthService(roll: FixedRolls([25, 0]).call);

      final mutated = service.applyUnknownChemical([state]);

      expect(mutated, 1);
      expect(state.bodyIndex, 1);
      expect(state.finIndex, 20);
    });

    test('adult infection threshold can produce fungus exactly', () {
      final state = fish(body: 1, age: 20);
      final service = LegacyHealthService(roll: FixedRolls([29, 1]).call);

      final infected = service.maybeInfect(
        state,
        sickFishCount: 0,
        environmentResearchLevel: 1,
      );

      expect(infected, isTrue);
      expect(state.disease, FishDisease.fungus);
    });

    test('environment level one odd family loses 19 health per age step', () {
      final state = fish(body: 1, fin: 2, health: 100);
      final service = LegacyHealthService(roll: FixedRolls([]).call);

      service.advanceHealth(state, environmentResearchLevel: 1);

      expect(state.healthPoints, 81);
    });

    test('level one food research always removes one FED point', () {
      final state = fish(fed: 70);
      final service = LegacyHealthService(roll: FixedRolls([]).call);

      service.advanceFed(state, foodResearchLevel: 1);

      expect(state.fedPoints, 69);
    });

    test('FED at two falls to zero and starvation removes one health', () {
      final state = fish(fed: 2, health: 80);
      final service = LegacyHealthService(roll: FixedRolls([]).call);

      service.advanceFed(state, foodResearchLevel: 1);

      expect(state.fedPoints, 0);
      expect(state.healthPoints, 79);
    });
  });
}
