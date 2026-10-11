import 'dart:math';

import 'package:agua_life/game/data/legacy_economy_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegacyEconomyCatalog', () {
    test('recovered base matrix and overrides are stable', () {
      expect(LegacyEconomyCatalog.fairPrice(0, 0), 4);
      expect(LegacyEconomyCatalog.fairPrice(6, 2), 33);
      expect(LegacyEconomyCatalog.fairPrice(16, 20), 48);
      expect(LegacyEconomyCatalog.fairPrice(14, 14), 55);
      expect(LegacyEconomyCatalog.fairPrice(11, 11), 70);
      expect(LegacyEconomyCatalog.fairPrice(9, 10), 70);
      expect(LegacyEconomyCatalog.fairPrice(8, 5), 70);
      expect(LegacyEconomyCatalog.fairPrice(6, 13), 95);
      expect(LegacyEconomyCatalog.fairPrice(7, 7), 190);
    });

    test('all seven magic fish use recovered body and fin pairs', () {
      final pairs = LegacyEconomyCatalog.magicFish
          .map((fish) => '${fish.body}:${fish.fin}')
          .toList();
      expect(pairs, <String>[
        '16:20',
        '14:14',
        '11:11',
        '9:10',
        '8:5',
        '6:13',
        '7:7',
      ]);
    });

    test('all 441 family combinations produce a positive price', () {
      final keys = <String>{};
      for (var body = 0; body < 21; body++) {
        for (var fin = 0; fin < 21; fin++) {
          expect(LegacyEconomyCatalog.fairPrice(body, fin), greaterThan(0));
          keys.add(LegacyEconomyCatalog.speciesKey(body, fin));
        }
      }
      expect(keys.length, 441);
    });

    test('initial asking price stays inside the legacy twenty-percent band', () {
      final random = Random(42);
      final fair = LegacyEconomyCatalog.fairPrice(7, 7);
      final spread = max(1, fair ~/ 5);
      for (var i = 0; i < 100; i++) {
        final ask = LegacyEconomyCatalog.initialAskingPrice(7, 7, random);
        expect(ask, greaterThanOrEqualTo(fair - spread));
        expect(ask, lessThanOrEqualTo(fair + spread));
      }
    });
  });
}
