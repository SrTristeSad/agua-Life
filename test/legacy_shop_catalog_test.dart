import 'package:agua_life/game/data/legacy_supply_catalog.dart';
import 'package:agua_life/game/models/game_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('legacy shop catalog', () {
    test('contains the 26 browsable J2ME items and skips internal index 25', () {
      expect(LegacySupply.values.length, 26);
      final indices = LegacySupply.values
          .map((item) => LegacySupplyCatalog.of(item).itemIndex)
          .toSet();
      expect(indices.contains(25), isFalse);
      expect(indices.contains(26), isTrue);
    });

    test('recovered research prices are exact', () {
      expect(LegacySupplyCatalog.researchPrice(LegacySupply.advertisingResearch, 1), 350);
      expect(LegacySupplyCatalog.researchPrice(LegacySupply.advertisingResearch, 2), 1500);
      expect(LegacySupplyCatalog.researchPrice(LegacySupply.fishFoodResearch, 1), 200);
      expect(LegacySupplyCatalog.researchPrice(LegacySupply.fishFoodResearch, 2), 650);
      expect(LegacySupplyCatalog.researchPrice(LegacySupply.fishEnvironmentResearch, 1), 500);
      expect(LegacySupplyCatalog.researchPrice(LegacySupply.fishEnvironmentResearch, 2), 1750);
      expect(LegacySupplyCatalog.researchPrice(LegacySupply.fishEnvironmentResearch, 3), 0);
    });

    test('legacy speed maps to 15, 10, 5 minutes and pause', () {
      expect(GameSpeed.slow.legacyMinutesPerAge, 15);
      expect(GameSpeed.normal.legacyMinutesPerAge, 10);
      expect(GameSpeed.fast.legacyMinutesPerAge, 5);
      expect(GameSpeed.paused.simulationMultiplier, 0);
    });
  });
}
