import 'dart:math';

import '../models/fish_disease.dart';
import '../models/fish_state.dart';

typedef LegacyRoll = int Function(int maxExclusive);

class LegacyHealthService {
  LegacyHealthService({LegacyRoll? roll})
      : _roll = roll ?? Random().nextInt;

  final LegacyRoll _roll;

  /// Runs the health portion of one legacy age step (n.c(m)).
  void advanceHealth(
    FishState fish, {
    int environmentResearchLevel = 1,
    bool ownsAerationSystem = false,
    bool ownsTemperatureRegulator = false,
  }) {
    if (!fish.alive) return;

    final level = environmentResearchLevel.clamp(1, 3);
    final body = fish.bodyIndex;
    final fin = fish.finIndex;
    var delta = 0;

    if (body.isOdd || fin.isOdd) {
      delta = switch (level) {
        1 => -19,
        2 => -6,
        _ => 0,
      };
    } else if ((body - 2) % 4 == 0 || (fin - 2) % 4 == 0) {
      delta = switch (level) {
        1 => -1,
        2 => 1,
        _ => 3,
      };
    } else if (body % 4 == 0 || fin % 4 == 0) {
      delta = switch (level) {
        1 => 1,
        2 => 3,
        _ => 5,
      };
    }

    if (ownsAerationSystem && _roll(100) <= 40) delta++;
    if (ownsTemperatureRegulator && _roll(100) <= 40) delta++;

    if ((fish.isSick || fish.fedPoints < 5) && delta > 0) {
      delta = 0;
    }
    if (fish.isSick) delta--;

    fish.addHealthPoints(delta);
  }

  /// Runs the FED portion of one legacy age step (n.a(m, boolean)).
  void advanceFed(
    FishState fish, {
    int foodResearchLevel = 1,
    bool magicSustenance = false,
    bool ownsNutritionPlant = false,
  }) {
    if (!fish.alive) return;

    final level = foodResearchLevel.clamp(1, 3);
    final consume = switch (level) {
      1 => true,
      2 => _roll(100) <= 60,
      _ => _roll(100) <= 30,
    };
    if (consume) fish.addFedPoints(-1);

    if (fish.fedPoints <= 2) {
      fish.setFedPoints(0);
      final avoidsDamage = magicSustenance && _roll(100) <= 33;
      if (!avoidsDamage) fish.addHealthPoints(-1);

      if (ownsNutritionPlant && _roll(100) <= 20) {
        fish.addFedPoints(5);
      }
    }
  }

  /// Adult natural infection check recovered from n.a(m, int).
  bool maybeInfect(
    FishState fish, {
    required int sickFishCount,
    int environmentResearchLevel = 1,
    bool halveRiskProtection = false,
  }) {
    if (!fish.alive || fish.isSick || !fish.isAdult) return false;

    final level = environmentResearchLevel.clamp(1, 3);
    final family = fish.bodyIndex;
    var threshold = 2;

    if (family % 4 == 0) {
      threshold = switch (level) {
        1 => 10,
        2 => 5,
        _ => 1,
      };
    } else if ((family - 2) % 4 == 0) {
      threshold = switch (level) {
        1 => 20,
        2 => 10,
        _ => 3,
      };
    } else if (family.isOdd) {
      threshold = switch (level) {
        1 => 30,
        2 => 20,
        _ => 5,
      };
    }

    if (halveRiskProtection) threshold ~/= 2;
    threshold += 6 * sickFishCount;
    if (fish.age > 600) threshold += 15;

    if (_roll(10000) >= threshold) return false;
    fish.infect(_roll(2) == 0 ? FishDisease.ich : FishDisease.fungus);
    return true;
  }

  /// Exact normal cure chance: random(100) < 40.
  int treat(Iterable<FishState> fish, FishDisease disease) {
    var cured = 0;
    for (final state in fish) {
      if (!state.alive || state.disease != disease) continue;
      if (_roll(100) < 40) {
        state.cureDisease();
        cured++;
      }
    }
    return cured;
  }

  /// Fish vitamins: HEALTH += random(10) + 6 => +6..+15.
  int applyVitamins(Iterable<FishState> fish) {
    var affected = 0;
    for (final state in fish) {
      if (!state.alive) continue;
      state.addHealthPoints(_roll(10) + 6);
      affected++;
    }
    return affected;
  }

  /// Growth hormone: if AGE <= 40, AGE += random(5) + 2 => +2..+6.
  int applyGrowthHormone(Iterable<FishState> fish) {
    var affected = 0;
    for (final state in fish) {
      if (!state.alive || state.age > 40) continue;
      state.addLegacyAge(_roll(5) + 2);
      affected++;
    }
    return affected;
  }

  /// Unknown chemical: for each living fish, roll <= 25 mutates one family
  /// index by one. At 0/20 the mutation always moves inward.
  int applyUnknownChemical(Iterable<FishState> fish) {
    var mutated = 0;
    for (final state in fish) {
      if (!state.alive || _roll(100) > 25) continue;

      final mutateBody = _roll(100) < 50;
      final current = mutateBody ? state.bodyIndex : state.finIndex;
      late int next;
      if (current == 0) {
        next = 1;
      } else if (current == 20) {
        next = 19;
      } else {
        next = _roll(100) < 50 ? current + 1 : current - 1;
      }

      state.mutateLegacyFamily(
        bodyIndex: mutateBody ? next : null,
        finIndex: mutateBody ? null : next,
      );
      mutated++;
    }
    return mutated;
  }
}
