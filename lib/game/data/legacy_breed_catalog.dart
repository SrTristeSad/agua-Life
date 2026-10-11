class LegacyBreedCatalog {
  const LegacyBreedCatalog._();

  static const List<String> bodyFamilies = <String>[
    'Shark',
    'Catfish',
    'Arrowfish',
    'Snout',
    'Fatfish',
    'Snooper',
    'Goldshark',
    'Fire-Arrow',
    'Fruitfish',
    'Flashfish',
    'Goldbulb',
    'Comet',
    'Stickfish',
    'Grouper',
    'Leaffish',
    'Carp',
    'Beta',
    'Pigmy',
    'Bananafish',
    'Quicksilver',
    'Spotanus',
  ];

  static const List<String> finFamilies = <String>[
    'Silky',
    'Tiger',
    'Hornet',
    'Fanned',
    'Pink',
    'Snubbed',
    'Wasp',
    'Canary',
    'Orange',
    'Oriental',
    'Golden',
    'Crimson',
    'Spined',
    'Stubby',
    'Speckled',
    'Razorback',
    'Greenfin',
    'Great-Sail',
    'Flagged',
    'Finless',
    'Twin-Fin',
  ];

  static const int bodyCount = 21;
  static const int finCount = 21;
  static const int totalCombinations = bodyCount * finCount;

  static int combinationId({required int body, required int fin}) {
    RangeError.checkValidIndex(body, bodyFamilies, 'body');
    RangeError.checkValidIndex(fin, finFamilies, 'fin');
    return body * finCount + fin;
  }

  static ({int body, int fin}) decodeCombination(int id) {
    if (id < 0 || id >= totalCombinations) {
      throw RangeError.range(id, 0, totalCombinations - 1, 'id');
    }
    return (body: id ~/ finCount, fin: id % finCount);
  }

  static String bodyName(int index) => bodyFamilies[index];
  static String finName(int index) => finFamilies[index];
}
