import 'fish_genome.dart';

class FishSpecies {
  const FishSpecies({
    required this.id,
    required this.name,
    required this.baseWidth,
    required this.baseHeight,
    required this.minSpeed,
    required this.maxSpeed,
    required this.founderGenome,
  });

  final String id;
  final String name;
  final double baseWidth;
  final double baseHeight;
  final double minSpeed;
  final double maxSpeed;
  final FishGenome founderGenome;
}
