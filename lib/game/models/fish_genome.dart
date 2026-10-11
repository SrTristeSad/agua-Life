enum FishPattern {
  solid,
  stripes,
  spots,
  patches,
}

class FishGenome {
  const FishGenome({
    required this.primaryColor,
    required this.secondaryColor,
    required this.pattern,
    required this.bodyScale,
    required this.finScale,
    required this.growthRate,
    required this.diseaseResistance,
    required this.fertility,
    required this.valueModifier,
    required this.shimmer,
  });

  /// ARGB color stored as 0xAARRGGBB so the genetics layer is independent
  /// from Flutter widgets and render components.
  final int primaryColor;
  final int secondaryColor;
  final FishPattern pattern;

  /// Visual traits. 1.0 is the species baseline.
  final double bodyScale;
  final double finScale;

  /// Gameplay traits. These are intentionally normalized around 1.0 so that
  /// balancing can evolve without changing the genetic representation.
  final double growthRate;
  final double diseaseResistance;
  final double fertility;
  final double valueModifier;

  /// Rare visual trait that can be inherited or appear as a mutation.
  final bool shimmer;
}
