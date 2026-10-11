import '../models/fish_genome.dart';
import '../models/fish_species.dart';

abstract final class SpeciesCatalog {
  static const sunny = FishSpecies(
    id: 'sunny',
    name: 'Sunny',
    baseWidth: 34,
    baseHeight: 20,
    minSpeed: 14,
    maxSpeed: 24,
    founderGenome: FishGenome(
      primaryColor: 0xFFFFA726,
      secondaryColor: 0xFFFFD54F,
      pattern: FishPattern.solid,
      bodyScale: 1,
      finScale: 1,
      growthRate: 1,
      diseaseResistance: 1,
      fertility: 1,
      valueModifier: 1,
      shimmer: false,
    ),
  );

  static const zephyr = FishSpecies(
    id: 'zephyr',
    name: 'Zephyr',
    baseWidth: 33,
    baseHeight: 19,
    minSpeed: 18,
    maxSpeed: 30,
    founderGenome: FishGenome(
      primaryColor: 0xFF42A5F5,
      secondaryColor: 0xFF0D47A1,
      pattern: FishPattern.stripes,
      bodyScale: 0.96,
      finScale: 1.15,
      growthRate: 1.05,
      diseaseResistance: 0.95,
      fertility: 1,
      valueModifier: 1.05,
      shimmer: false,
    ),
  );

  static const luna = FishSpecies(
    id: 'luna',
    name: 'Luna',
    baseWidth: 31,
    baseHeight: 18,
    minSpeed: 15,
    maxSpeed: 25,
    founderGenome: FishGenome(
      primaryColor: 0xFFAB47BC,
      secondaryColor: 0xFFF48FB1,
      pattern: FishPattern.patches,
      bodyScale: 0.92,
      finScale: 1.25,
      growthRate: 0.95,
      diseaseResistance: 1.05,
      fertility: 1.1,
      valueModifier: 1.15,
      shimmer: false,
    ),
  );

  static const shadow = FishSpecies(
    id: 'shadow',
    name: 'Shadow',
    baseWidth: 35,
    baseHeight: 20,
    minSpeed: 13,
    maxSpeed: 22,
    founderGenome: FishGenome(
      primaryColor: 0xFF263238,
      secondaryColor: 0xFFE53935,
      pattern: FishPattern.spots,
      bodyScale: 1.04,
      finScale: 1.12,
      growthRate: 0.9,
      diseaseResistance: 1.2,
      fertility: 0.9,
      valueModifier: 1.25,
      shimmer: false,
    ),
  );

  static const all = <FishSpecies>[sunny, zephyr, luna, shadow];
}
