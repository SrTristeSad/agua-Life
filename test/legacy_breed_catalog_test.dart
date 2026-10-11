import 'package:agua_life/game/data/legacy_breed_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegacyBreedCatalog', () {
    test('preserves the 21 by 21 breed grid', () {
      expect(LegacyBreedCatalog.bodyFamilies, hasLength(21));
      expect(LegacyBreedCatalog.finFamilies, hasLength(21));
      expect(LegacyBreedCatalog.totalCombinations, 441);
    });

    test('combination ids round-trip', () {
      for (var body = 0; body < LegacyBreedCatalog.bodyCount; body++) {
        for (var fin = 0; fin < LegacyBreedCatalog.finCount; fin++) {
          final id = LegacyBreedCatalog.combinationId(body: body, fin: fin);
          final decoded = LegacyBreedCatalog.decodeCombination(id);
          expect(decoded.body, body);
          expect(decoded.fin, fin);
        }
      }
    });
  });
}
