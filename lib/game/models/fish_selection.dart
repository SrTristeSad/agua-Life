import 'fish_genome.dart';
import 'fish_state.dart';

class FishSelection {
  const FishSelection({
    required this.speciesName,
    required this.hunger,
    required this.health,
    required this.growthProgress,
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
      speciesName: state.species.name,
      hunger: state.hunger,
      health: state.health,
      growthProgress: state.growthProgress,
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
  final double hunger;
  final double health;
  final double growthProgress;
  final FishPattern pattern;
  final double bodyScale;
  final double finScale;
  final double growthRate;
  final double diseaseResistance;
  final double fertility;
  final double valueModifier;
  final bool shimmer;

  String get patternLabel => switch (pattern) {
        FishPattern.solid => 'Liso',
        FishPattern.stripes => 'Listrado',
        FishPattern.spots => 'Pintado',
        FishPattern.patches => 'Manchado',
      };
}
