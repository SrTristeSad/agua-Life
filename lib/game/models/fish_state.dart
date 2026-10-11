import 'fish_genome.dart';
import 'fish_species.dart';

class FishState {
  FishState({
    required this.species,
    required this.genome,
    double hunger = 0.85,
    double health = 1,
    this.ageSeconds = 0,
  })  : _hunger = hunger.clamp(0, 1).toDouble(),
        _health = health.clamp(0, 1).toDouble();

  final FishSpecies species;
  final FishGenome genome;

  double ageSeconds;
  double _hunger;
  double _health;
  bool alive = true;

  double get hunger => _hunger;
  double get health => _health;

  double get growthProgress {
    final adulthoodSeconds = 210 / genome.growthRate;
    return (ageSeconds / adulthoodSeconds).clamp(0, 1).toDouble();
  }

  double get visualScale => 0.78 + growthProgress * 0.22;

  void tick(double dt) {
    if (!alive || dt <= 0) {
      return;
    }

    ageSeconds += dt;

    final hungerBurn = 0.00125 * genome.growthRate;
    _hunger = (_hunger - hungerBurn * dt).clamp(0, 1).toDouble();

    if (_hunger < 0.18) {
      final resistance = genome.diseaseResistance.clamp(0.5, 2).toDouble();
      _health = (_health - (0.0014 / resistance) * dt)
          .clamp(0, 1)
          .toDouble();
    } else if (_hunger > 0.45 && _health < 1) {
      _health = (_health + 0.00035 * genome.diseaseResistance * dt)
          .clamp(0, 1)
          .toDouble();
    }

    if (_health <= 0) {
      alive = false;
    }
  }

  void feed([double amount = 0.38]) {
    if (!alive) {
      return;
    }

    _hunger = (_hunger + amount).clamp(0, 1).toDouble();
    _health = (_health + 0.015).clamp(0, 1).toDouble();
  }
}
