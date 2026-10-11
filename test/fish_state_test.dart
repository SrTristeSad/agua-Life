import 'package:agua_life/game/data/species_catalog.dart';
import 'package:agua_life/game/models/fish_disease.dart';
import 'package:agua_life/game/models/fish_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FishState fish({
    int body = 0,
    int fin = 0,
    double age = 0,
    double hunger = 0.85,
    double health = 1,
  }) =>
      FishState(
        species: SpeciesCatalog.sunny,
        genome: SpeciesCatalog.sunny.founderGenome,
        bodyIndex: body,
        finIndex: fin,
        ageSeconds: age * FishState.secondsPerAgeAtNormalSpeed,
        hunger: hunger,
        health: health,
      );

  group('FishState', () {
    test('legacy age 20 is adulthood at normal speed', () {
      final state = fish(age: 19);
      expect(state.isAdult, isFalse);

      final steps = state.tick(FishState.secondsPerAgeAtNormalSpeed);

      expect(steps, 1);
      expect(state.age, 20);
      expect(state.isAdult, isTrue);
      expect(state.growthProgress, 1);
    });

    test('tick reports crossed age steps without inventing simulation effects', () {
      final state = fish(age: 2, hunger: 0.70);
      final initialFed = state.fedPoints;

      final steps = state.tick(FishState.secondsPerAgeAtNormalSpeed * 3);

      expect(steps, 3);
      expect(state.age, 5);
      expect(state.fedPoints, initialFed);
    });

    test('feeding restores FED and clamps to 100', () {
      final state = fish(hunger: 0.70);
      state.feed();
      expect(state.hunger, 1);
    });

    test('pregnancy uses target age plus three and strict greater-than birth', () {
      final mother = fish(body: 2, fin: 4, age: 20);
      final father = fish(body: 10, fin: 14, age: 20);

      expect(mother.startPregnancy(father), isTrue);
      expect(mother.pregnant, isTrue);

      mother.tick(FishState.secondsPerAgeAtNormalSpeed * 3);
      expect(mother.age, 23);
      expect(mother.completePregnancyIfReady(), isNull);

      mother.tick(FishState.secondsPerAgeAtNormalSpeed);
      final completed = mother.completePregnancyIfReady();
      expect(completed, isNotNull);
      expect(completed!.fatherBody, 10);
      expect(completed.fatherFin, 14);
      expect(mother.pregnant, isFalse);
    });

    test('sickness blocks breeding and infection cancels pregnancy', () {
      final mother = fish(age: 20);
      final father = fish(body: 4, fin: 4, age: 20);
      expect(mother.startPregnancy(father), isTrue);

      mother.infect(FishDisease.fungus);
      expect(mother.isSick, isTrue);
      expect(mother.pregnant, isFalse);
      expect(mother.startPregnancy(father), isFalse);
    });

    test('legacy family mutation changes the species name source indices', () {
      final state = fish(body: 0, fin: 0);
      final before = state.legacySpeciesName;
      state.mutateLegacyFamily(bodyIndex: 1);
      expect(state.bodyIndex, 1);
      expect(state.legacySpeciesName, isNot(before));
    });

    test('juveniles cannot breed', () {
      final mother = fish(age: 19);
      final father = fish(age: 20);
      expect(mother.startPregnancy(father), isFalse);
    });
  });
}
