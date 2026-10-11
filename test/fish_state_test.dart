import 'package:agua_life/game/data/species_catalog.dart';
import 'package:agua_life/game/models/fish_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FishState fish({
    int body = 0,
    int fin = 0,
    double age = 0,
    double hunger = 0.85,
  }) =>
      FishState(
        species: SpeciesCatalog.sunny,
        genome: SpeciesCatalog.sunny.founderGenome,
        bodyIndex: body,
        finIndex: fin,
        ageSeconds: age * FishState.secondsPerAgeAtNormalSpeed,
        hunger: hunger,
      );

  group('FishState', () {
    test('legacy age 20 is adulthood at normal speed', () {
      final state = fish(age: 19);
      expect(state.isAdult, isFalse);

      state.tick(FishState.secondsPerAgeAtNormalSpeed);

      expect(state.age, 20);
      expect(state.isAdult, isTrue);
      expect(state.growthProgress, 1);
    });

    test('hunger falls and feeding restores it', () {
      final state = fish(hunger: 0.7);

      state.tick(80);
      final hungryValue = state.hunger;
      expect(hungryValue, lessThan(0.7));

      state.feed();
      expect(state.hunger, greaterThan(hungryValue));
      expect(state.hunger, lessThanOrEqualTo(1));
    });

    test('starvation eventually damages health', () {
      final state = FishState(
        species: SpeciesCatalog.shadow,
        genome: SpeciesCatalog.shadow.founderGenome,
        bodyIndex: 5,
        finIndex: 5,
        hunger: 0.1,
      );

      final initialHealth = state.health;
      state.tick(30);

      expect(state.health, lessThan(initialHealth));
    });

    test('pregnancy requires adult fish and lasts three legacy ages', () {
      final mother = fish(body: 2, fin: 4, age: 20);
      final father = fish(body: 10, fin: 14, age: 20);

      expect(mother.startPregnancy(father), isTrue);
      expect(mother.pregnant, isTrue);
      expect(mother.pregnancyAgesRemaining, 3);

      mother.tick(FishState.secondsPerAgeAtNormalSpeed * 2);
      expect(mother.completePregnancyIfReady(), isNull);
      expect(mother.pregnancyAgesRemaining, 1);

      mother.tick(FishState.secondsPerAgeAtNormalSpeed);
      final completed = mother.completePregnancyIfReady();
      expect(completed, isNotNull);
      expect(completed!.fatherBody, 10);
      expect(completed.fatherFin, 14);
      expect(mother.pregnant, isFalse);
    });

    test('juveniles cannot breed', () {
      final mother = fish(age: 19);
      final father = fish(age: 20);
      expect(mother.startPregnancy(father), isFalse);
    });
  });
}
