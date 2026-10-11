import 'dart:math';

class LegacyMagicFish {
  const LegacyMagicFish({
    required this.index,
    required this.name,
    required this.body,
    required this.fin,
  });

  final int index;
  final String name;
  final int body;
  final int fin;
}

abstract final class LegacyEconomyCatalog {
  static const List<int> bodyBase = <int>[
    2, 10, 4, 10, 2, 10, 6, 10, 6, 20, 4, 24, 2, 10, 4, 10, 6, 10, 3, 10, 2,
  ];

  static const List<int> finBase = <int>[
    2, 10, 5, 10, 2, 14, 5, 25, 8, 10, 15, 10, 2, 18, 15, 10, 9, 10, 9, 20, 2,
  ];

  static const List<LegacyMagicFish> magicFish = <LegacyMagicFish>[
    LegacyMagicFish(index: 0, name: 'FERTILITY', body: 16, fin: 20),
    LegacyMagicFish(index: 1, name: 'SUSTENANCE', body: 14, fin: 14),
    LegacyMagicFish(index: 2, name: 'CURING', body: 11, fin: 11),
    LegacyMagicFish(index: 3, name: 'GROWTH', body: 9, fin: 10),
    LegacyMagicFish(index: 4, name: 'HEALTH', body: 8, fin: 5),
    LegacyMagicFish(index: 5, name: 'MUTATION', body: 6, fin: 13),
    LegacyMagicFish(index: 6, name: 'GOLDEN GUPPY OF ISOLA', body: 7, fin: 7),
  ];

  static String speciesKey(int body, int fin) => '$body:$fin';

  static int fairPrice(int body, int fin) {
    RangeError.checkValidIndex(body, bodyBase, 'body');
    RangeError.checkValidIndex(fin, finBase, 'fin');
    final override = _overrides[speciesKey(body, fin)];
    return override ?? bodyBase[body] + finBase[fin];
  }

  static int initialAskingPrice(int body, int fin, Random random) {
    final base = fairPrice(body, fin);
    final spread = max(1, base ~/ 5);
    final delta = random.nextInt(spread);
    return max(1, base + (random.nextBool() ? delta : -delta));
  }

  static LegacyMagicFish? magicFor(int body, int fin) {
    for (final magic in magicFish) {
      if (magic.body == body && magic.fin == fin) return magic;
    }
    return null;
  }

  static const Map<String, int> _overrides = <String, int>{
    '8:8': 20,
    '10:10': 33,
    '6:2': 33,
    '14:6': 33,
    '9:17': 45,
    '2:1': 30,
    '16:20': 48,
    '14:14': 55,
    '11:11': 70,
    '9:10': 70,
    '8:5': 70,
    '6:13': 95,
    '7:7': 190,
  };
}
