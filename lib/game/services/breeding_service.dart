import 'dart:math';

import '../models/fish_genome.dart';

class BreedingService {
  BreedingService(this.random);

  final Random random;

  FishGenome breedSameSpecies(
    FishGenome parentA,
    FishGenome parentB,
  ) {
    return FishGenome(
      primaryColor: _inheritColor(parentA.primaryColor, parentB.primaryColor),
      secondaryColor:
          _inheritColor(parentA.secondaryColor, parentB.secondaryColor),
      pattern: _inheritPattern(parentA.pattern, parentB.pattern),
      bodyScale: _inheritDouble(parentA.bodyScale, parentB.bodyScale, 0.08, 0.8, 1.2),
      finScale: _inheritDouble(parentA.finScale, parentB.finScale, 0.12, 0.75, 1.4),
      growthRate:
          _inheritDouble(parentA.growthRate, parentB.growthRate, 0.08, 0.7, 1.35),
      diseaseResistance: _inheritDouble(
        parentA.diseaseResistance,
        parentB.diseaseResistance,
        0.08,
        0.7,
        1.4,
      ),
      fertility:
          _inheritDouble(parentA.fertility, parentB.fertility, 0.08, 0.7, 1.4),
      valueModifier: _inheritDouble(
        parentA.valueModifier,
        parentB.valueModifier,
        0.1,
        0.75,
        1.6,
      ),
      shimmer: parentA.shimmer || parentB.shimmer || random.nextDouble() < 0.02,
    );
  }

  int _inheritColor(int a, int b) {
    final chosen = random.nextBool() ? a : b;
    if (random.nextDouble() >= 0.22) {
      return chosen;
    }

    final alpha = (chosen >> 24) & 0xFF;
    final red = (chosen >> 16) & 0xFF;
    final green = (chosen >> 8) & 0xFF;
    final blue = chosen & 0xFF;

    int mutate(int channel) {
      final delta = random.nextInt(31) - 15;
      return (channel + delta).clamp(0, 255);
    }

    return (alpha << 24) |
        (mutate(red) << 16) |
        (mutate(green) << 8) |
        mutate(blue);
  }

  FishPattern _inheritPattern(FishPattern a, FishPattern b) {
    if (random.nextDouble() < 0.92) {
      return random.nextBool() ? a : b;
    }
    return FishPattern.values[random.nextInt(FishPattern.values.length)];
  }

  double _inheritDouble(
    double a,
    double b,
    double mutationRange,
    double min,
    double max,
  ) {
    final inherited = (a + b) / 2;
    final mutation = (random.nextDouble() * 2 - 1) * mutationRange;
    return (inherited + mutation).clamp(min, max).toDouble();
  }
}
