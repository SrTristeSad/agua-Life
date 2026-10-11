import 'dart:math';

import 'package:agua_life/game/data/species_catalog.dart';
import 'package:agua_life/game/models/fish_genome.dart';
import 'package:agua_life/game/services/breeding_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreedingService', () {
    test('same-species offspring remains inside safe trait ranges', () {
      final service = BreedingService(Random(42));
      final parentA = SpeciesCatalog.sunny.founderGenome;
      const parentB = FishGenome(
        primaryColor: 0xFFFF7A30,
        secondaryColor: 0xFFFFE680,
        pattern: FishPattern.spots,
        bodyScale: 0.9,
        finScale: 1.2,
        growthRate: 1.1,
        diseaseResistance: 0.9,
        fertility: 1.15,
        valueModifier: 1.2,
        shimmer: false,
      );

      for (var i = 0; i < 100; i++) {
        final child = service.breedSameSpecies(parentA, parentB);

        expect(child.bodyScale, inInclusiveRange(0.8, 1.2));
        expect(child.finScale, inInclusiveRange(0.75, 1.4));
        expect(child.growthRate, inInclusiveRange(0.7, 1.35));
        expect(child.diseaseResistance, inInclusiveRange(0.7, 1.4));
        expect(child.fertility, inInclusiveRange(0.7, 1.4));
        expect(child.valueModifier, inInclusiveRange(0.75, 1.6));
      }
    });

    test('offspring inherits or mutates visual traits', () {
      final service = BreedingService(Random(9));
      final parentA = SpeciesCatalog.sunny.founderGenome;
      const parentB = FishGenome(
        primaryColor: 0xFFEF6C00,
        secondaryColor: 0xFFFFF176,
        pattern: FishPattern.stripes,
        bodyScale: 1,
        finScale: 1,
        growthRate: 1,
        diseaseResistance: 1,
        fertility: 1,
        valueModifier: 1,
        shimmer: false,
      );

      final children = List.generate(
        40,
        (_) => service.breedSameSpecies(parentA, parentB),
      );

      expect(children, isNotEmpty);
      expect(
        children.any(
          (child) =>
              child.primaryColor != parentA.primaryColor ||
              child.pattern != parentA.pattern ||
              child.finScale != parentA.finScale,
        ),
        isTrue,
      );
    });
  });
}
