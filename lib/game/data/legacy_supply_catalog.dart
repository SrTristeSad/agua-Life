enum LegacySupply {
  ichTreatment,
  fungalTreatment,
  fishVitamins,
  growthHormone,
  unknownChemical,
}

class LegacySupplyDefinition {
  const LegacySupplyDefinition({
    required this.itemIndex,
    required this.name,
    required this.description,
    required this.price,
    required this.dosesPerPurchase,
    required this.shortLabel,
  });

  final int itemIndex;
  final String name;
  final String description;
  final int price;
  final int dosesPerPurchase;
  final String shortLabel;
}

class LegacySupplyCatalog {
  const LegacySupplyCatalog._();

  static const Map<LegacySupply, LegacySupplyDefinition> definitions = {
    LegacySupply.ichTreatment: LegacySupplyDefinition(
      itemIndex: 0,
      name: 'ICK TREATMENT',
      description: 'ICK IS WHITE SPECKS ON A FISH. CONTAINS 3 DOSES.',
      price: 30,
      dosesPerPurchase: 3,
      shortLabel: 'ICK',
    ),
    LegacySupply.fungalTreatment: LegacySupplyDefinition(
      itemIndex: 1,
      name: 'FUNGAL TREATMENT',
      description: 'FUNGUS IS GREEN GROWTH ON A FISH. CONTAINS 3 DOSES.',
      price: 40,
      dosesPerPurchase: 3,
      shortLabel: 'FUNGUS',
    ),
    LegacySupply.fishVitamins: LegacySupplyDefinition(
      itemIndex: 2,
      name: 'FISH VITAMINS',
      description: 'STIMULATE FISH METABOLISM. CONTAINS 3 DOSES.',
      price: 140,
      dosesPerPurchase: 3,
      shortLabel: 'VITAMIN',
    ),
    LegacySupply.growthHormone: LegacySupplyDefinition(
      itemIndex: 3,
      name: 'GROWTH HORMONE',
      description: 'ENCOURAGES GROWTH IN FISH. CONTAINS 3 DOSES.',
      price: 380,
      dosesPerPurchase: 3,
      shortLabel: 'GROWTH',
    ),
    LegacySupply.unknownChemical: LegacySupplyDefinition(
      itemIndex: 4,
      name: 'UNKNOWN CHEMICAL',
      description: 'CHEMICAL FROM A GENETIC LAB. CONTAINS ONE DOSE.',
      price: 650,
      dosesPerPurchase: 1,
      shortLabel: 'CHEM',
    ),
  };

  static LegacySupplyDefinition of(LegacySupply supply) => definitions[supply]!;
}
