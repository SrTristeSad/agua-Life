enum LegacySupply {
  ichTreatment,
  fungalTreatment,
  fishVitamins,
  growthHormone,
  unknownChemical,
  commonFishEggs,
  unusualFishEggs,
  rareFishEggs,
  advertisingResearch,
  aerationSystem,
  temperatureRegulator,
  cleaningSnail,
  goldenSeahorse,
  nutritionPlant,
  incubationPlant,
  curingPlant,
  fertilityPlant,
  fishFoodResearch,
  shellOrnament,
  pagodaOrnament,
  diverOrnament,
  coralOrnament,
  sunkenColumn,
  sunkenShip,
  secondTank,
  fishEnvironmentResearch,
}

enum LegacyShopKind {
  treatment,
  enhancement,
  eggs,
  research,
  equipment,
  plant,
  ornament,
  tank,
}

class LegacySupplyDefinition {
  const LegacySupplyDefinition({
    required this.itemIndex,
    required this.name,
    required this.description,
    required this.price,
    required this.dosesPerPurchase,
    required this.shortLabel,
    required this.kind,
    this.secondResearchPrice,
    this.requiredEnvironmentLevel = 1,
  });

  final int itemIndex;
  final String name;
  final String description;
  final int price;
  final int dosesPerPurchase;
  final String shortLabel;
  final LegacyShopKind kind;
  final int? secondResearchPrice;
  final int requiredEnvironmentLevel;

  bool get isConsumable =>
      kind == LegacyShopKind.treatment || kind == LegacyShopKind.enhancement;
  bool get isResearch => kind == LegacyShopKind.research;
}

abstract final class LegacySupplyCatalog {
  static const Map<LegacySupply, LegacySupplyDefinition> definitions = {
    LegacySupply.ichTreatment: LegacySupplyDefinition(itemIndex: 0, name: 'ICK TREATMENT', description: 'ICK IS WHITE SPECKS ON A FISH. CONTAINS 3 DOSES.', price: 30, dosesPerPurchase: 3, shortLabel: 'ICK', kind: LegacyShopKind.treatment),
    LegacySupply.fungalTreatment: LegacySupplyDefinition(itemIndex: 1, name: 'FUNGAL TREATMENT', description: 'FUNGUS IS GREEN GROWTH ON A FISH. CONTAINS 3 DOSES.', price: 40, dosesPerPurchase: 3, shortLabel: 'FUNGUS', kind: LegacyShopKind.treatment),
    LegacySupply.fishVitamins: LegacySupplyDefinition(itemIndex: 2, name: 'FISH VITAMINS', description: 'STIMULATE FISH METABOLISM. CONTAINS 3 DOSES.', price: 140, dosesPerPurchase: 3, shortLabel: 'VITAMIN', kind: LegacyShopKind.enhancement),
    LegacySupply.growthHormone: LegacySupplyDefinition(itemIndex: 3, name: 'GROWTH HORMONE', description: 'ENCOURAGES GROWTH IN FISH. CONTAINS 3 DOSES.', price: 380, dosesPerPurchase: 3, shortLabel: 'GROWTH', kind: LegacyShopKind.enhancement),
    LegacySupply.unknownChemical: LegacySupplyDefinition(itemIndex: 4, name: 'UNKNOWN CHEMICAL', description: 'CHEMICAL FROM A GENETIC LAB. CONTAINS ONE DOSE.', price: 650, dosesPerPurchase: 1, shortLabel: 'CHEM', kind: LegacyShopKind.enhancement),
    LegacySupply.commonFishEggs: LegacySupplyDefinition(itemIndex: 5, name: 'COMMON FISH EGGS', description: 'FOUND IN THE LAGOON OF ISOLA.', price: 120, dosesPerPurchase: 0, shortLabel: 'COMMON', kind: LegacyShopKind.eggs),
    LegacySupply.unusualFishEggs: LegacySupplyDefinition(itemIndex: 6, name: 'UNUSUAL FISH EGGS', description: 'NEED MORE CARE. RESEARCH FISH ENVIRONMENT.', price: 450, dosesPerPurchase: 0, shortLabel: 'UNUSUAL', kind: LegacyShopKind.eggs, requiredEnvironmentLevel: 2),
    LegacySupply.rareFishEggs: LegacySupplyDefinition(itemIndex: 7, name: 'RARE FISH EGGS', description: 'NEED EXPERT CARE. RESEARCH FISH ENVIRONMENT.', price: 1200, dosesPerPurchase: 0, shortLabel: 'RARE', kind: LegacyShopKind.eggs, requiredEnvironmentLevel: 3),
    LegacySupply.advertisingResearch: LegacySupplyDefinition(itemIndex: 8, name: 'ADVERTISING RESEARCH', description: 'KEEP YOUR SHOP CROWDED AND THE CASH FLOWING.', price: 350, dosesPerPurchase: 0, shortLabel: 'ADS', kind: LegacyShopKind.research, secondResearchPrice: 1500),
    LegacySupply.aerationSystem: LegacySupplyDefinition(itemIndex: 9, name: 'AERATION SYSTEM', description: 'HELPS SURVIVAL BY PUTTING OXYGEN IN THE WATER.', price: 70, dosesPerPurchase: 0, shortLabel: 'AIR', kind: LegacyShopKind.equipment),
    LegacySupply.temperatureRegulator: LegacySupplyDefinition(itemIndex: 10, name: 'TEMPERATURE REGULATOR', description: 'HELPS FISH SURVIVE BY MAINTAINING TEMPERATURE.', price: 175, dosesPerPurchase: 0, shortLabel: 'TEMP', kind: LegacyShopKind.equipment),
    LegacySupply.cleaningSnail: LegacySupplyDefinition(itemIndex: 11, name: 'CLEANING SNAIL', description: 'WILL NEVER TIRE OF CLEANING YOUR TANKS.', price: 80, dosesPerPurchase: 0, shortLabel: 'SNAIL', kind: LegacyShopKind.equipment),
    LegacySupply.goldenSeahorse: LegacySupplyDefinition(itemIndex: 12, name: 'GOLDEN SEAHORSE', description: 'MAGICALLY ENHANCES THE LIFE OF YOUR FISH.', price: 1300, dosesPerPurchase: 0, shortLabel: 'HORSE', kind: LegacyShopKind.equipment),
    LegacySupply.nutritionPlant: LegacySupplyDefinition(itemIndex: 13, name: 'PLANT OF NUTRITION FROM ISOLA', description: 'RELEASES NUTRIENTS TO HELP PREVENT STARVATION.', price: 200, dosesPerPurchase: 0, shortLabel: 'NUTRI', kind: LegacyShopKind.plant),
    LegacySupply.incubationPlant: LegacySupplyDefinition(itemIndex: 14, name: 'PLANT OF INCUBATION FROM ISOLA', description: 'INCREASES THE VIABILITY OF EGGS.', price: 350, dosesPerPurchase: 0, shortLabel: 'INCUB', kind: LegacyShopKind.plant),
    LegacySupply.curingPlant: LegacySupplyDefinition(itemIndex: 15, name: 'PLANT OF CURING FROM ISOLA', description: 'HELPS PREVENT DISEASE.', price: 650, dosesPerPurchase: 0, shortLabel: 'CURE', kind: LegacyShopKind.plant),
    LegacySupply.fertilityPlant: LegacySupplyDefinition(itemIndex: 16, name: 'PLANT OF FERTILITY FROM ISOLA', description: 'ENCOURAGES MORE BABIES FROM PREGNANT FISH.', price: 1250, dosesPerPurchase: 0, shortLabel: 'FERT', kind: LegacyShopKind.plant),
    LegacySupply.fishFoodResearch: LegacySupplyDefinition(itemIndex: 17, name: 'FISH FOOD RESEARCH', description: 'HELPS WARD OFF DISEASE. LESS FEEDING IS NEEDED.', price: 200, dosesPerPurchase: 0, shortLabel: 'FOOD R', kind: LegacyShopKind.research, secondResearchPrice: 650),
    LegacySupply.shellOrnament: LegacySupplyDefinition(itemIndex: 18, name: 'SHELL ORNAMENT', description: 'HELPS DRAW MORE CROWDS.', price: 20, dosesPerPurchase: 0, shortLabel: 'SHELL', kind: LegacyShopKind.ornament),
    LegacySupply.pagodaOrnament: LegacySupplyDefinition(itemIndex: 19, name: 'PAGODA ORNAMENT', description: 'ADD STYLE AND ELEGANCE TO YOUR TANK!', price: 50, dosesPerPurchase: 0, shortLabel: 'PAGODA', kind: LegacyShopKind.ornament),
    LegacySupply.diverOrnament: LegacySupplyDefinition(itemIndex: 20, name: 'DIVER ORNAMENT', description: 'THE CLASSIC AQUATIC DIVER.', price: 350, dosesPerPurchase: 0, shortLabel: 'DIVER', kind: LegacyShopKind.ornament),
    LegacySupply.coralOrnament: LegacySupplyDefinition(itemIndex: 21, name: 'CORAL ORNAMENT', description: 'FISH LOVE CORAL AND SO DO YOUR CUSTOMERS.', price: 950, dosesPerPurchase: 0, shortLabel: 'CORAL', kind: LegacyShopKind.ornament),
    LegacySupply.sunkenColumn: LegacySupplyDefinition(itemIndex: 22, name: 'SUNKEN COLUMN', description: 'LIKE IN THE WATERS OF GREECE!', price: 1500, dosesPerPurchase: 0, shortLabel: 'COLUMN', kind: LegacyShopKind.ornament),
    LegacySupply.sunkenShip: LegacySupplyDefinition(itemIndex: 23, name: 'SUNKEN SHIP ORNAMENT', description: 'EVERYONE WILL ADMIRE ITS MYSTERIOUS BEAUTY.', price: 3500, dosesPerPurchase: 0, shortLabel: 'SHIP', kind: LegacyShopKind.ornament),
    LegacySupply.secondTank: LegacySupplyDefinition(itemIndex: 24, name: 'SECOND TANK', description: 'ANOTHER TANK FOR BREEDING YOUR FISH.', price: 450, dosesPerPurchase: 0, shortLabel: 'TANK 2', kind: LegacyShopKind.tank),
    LegacySupply.fishEnvironmentResearch: LegacySupplyDefinition(itemIndex: 26, name: 'FISH ENVIRONMENT RESEARCH', description: 'ALLOWS RARER FISH TO SURVIVE IN YOUR TANKS.', price: 500, dosesPerPurchase: 0, shortLabel: 'ENV R', kind: LegacyShopKind.research, secondResearchPrice: 1750),
  };

  static LegacySupplyDefinition of(LegacySupply supply) => definitions[supply]!;

  static int researchPrice(LegacySupply supply, int currentLevel) {
    final definition = of(supply);
    if (!definition.isResearch || currentLevel >= 3) return 0;
    return currentLevel <= 1 ? definition.price : definition.secondResearchPrice!;
  }
}
