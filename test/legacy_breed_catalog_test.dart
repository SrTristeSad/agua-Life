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

    test('child uses integer midpoint of both parents like the J2ME build', () {
      final child = LegacyBreedCatalog.childOf(
        motherBody: 2,
        motherFin: 4,
        fatherBody: 11,
        fatherFin: 19,
      );

      expect(child.body, 6);
      expect(child.fin, 11);
      expect(
        LegacyBreedCatalog.speciesName(body: child.body, fin: child.fin),
        'Crimson Goldshark',
      );
    });
  });
}
