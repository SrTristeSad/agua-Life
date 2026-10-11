import 'package:agua_life/game/data/species_catalog.dart';
import 'package:agua_life/game/models/fish_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FishState', () {
    test('fish grows toward adult scale over time', () {
      final fish = FishState(
        species: SpeciesCatalog.sunny,
        genome: SpeciesCatalog.sunny.founderGenome,
      );

      final initialScale = fish.visualScale;
      fish.tick(120);

      expect(fish.visualScale, greaterThan(initialScale));
      expect(fish.visualScale, lessThanOrEqualTo(1));
    });

    test('hunger falls and feeding restores it', () {
      final fish = FishState(
        species: SpeciesCatalog.sunny,
        genome: SpeciesCatalog.sunny.founderGenome,
        hunger: 0.7,
      );

      fish.tick(80);
      final hungryValue = fish.hunger;
      expect(hungryValue, lessThan(0.7));

      fish.feed();
      expect(fish.hunger, greaterThan(hungryValue));
      expect(fish.hunger, lessThanOrEqualTo(1));
    });

    test('starvation eventually damages health', () {
      final fish = FishState(
        species: SpeciesCatalog.shadow,
        genome: SpeciesCatalog.shadow.founderGenome,
        hunger: 0.1,
      );

      final initialHealth = fish.health;
      fish.tick(30);

      expect(fish.health, lessThan(initialHealth));
    });
  });
}
