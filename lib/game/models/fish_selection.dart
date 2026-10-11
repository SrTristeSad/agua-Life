import 'fish_disease.dart';
import 'fish_genome.dart';
import 'fish_state.dart';

class FishSelection {
  const FishSelection({
    required this.speciesName,
    required this.age,
    required this.hunger,
    required this.health,
    required this.growthProgress,
    required this.bodyIndex,
    required this.finIndex,
    required this.pregnant,
    required this.pregnancyAgesRemaining,
    required this.disease,
    required this.pattern,
    required this.bodyScale,
    required this.finScale,
    required this.growthRate,
    required this.diseaseResistance,
    required this.fertility,
    required this.valueModifier,
    required this.shimmer,
  });

  factory FishSelection.fromState(FishState state) {
    return FishSelection(
      speciesName: state.legacySpeciesName,
      age: state.age,
      hunger: state.hunger,
      health: state.health,
      growthProgress: state.growthProgress,
      bodyIndex: state.bodyIndex,
      finIndex: state.finIndex,
      pregnant: state.pregnant,
      pregnancyAgesRemaining: state.pregnancyAgesRemaining,
      disease: state.disease,
      pattern: state.genome.pattern,
      bodyScale: state.genome.bodyScale,
      finScale: state.genome.finScale,
      growthRate: state.genome.growthRate,
      diseaseResistance: state.genome.diseaseResistance,
      fertility: state.genome.fertility,
      valueModifier: state.genome.valueModifier,
      shimmer: state.genome.shimmer,
    );
  }

  final String speciesName;
  final int age;
  final double hunger;
  final double health;
  final double growthProgress;
  final int bodyIndex;
  final int finIndex;
  final bool pregnant;
  final int pregnancyAgesRemaining;
  final FishDisease disease;
  final FishPattern pattern;
  final double bodyScale;
  final double finScale;
  final double growthRate;
  final double diseaseResistance;
  final double fertility;
  final double valueModifier;
  final bool shimmer;

  bool get isSick => disease != FishDisease.none;
  String get diseaseLabel => disease.legacyLabel;

  String get patternLabel => switch (pattern) {
        FishPattern.solid => 'Liso',
        FishPattern.stripes => 'Listrado',
        FishPattern.spots => 'Pintado',
        FishPattern.patches => 'Manchado',
      };
}
