import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../data/species_catalog.dart';
import '../models/fish_genome.dart';
import '../models/fish_state.dart';
import '../services/breeding_service.dart';
import 'fish_component.dart';
import 'food_flake.dart';

class TankScene extends PositionComponent {
  TankScene({
    required this.tankNumber,
    required this.backgroundAsset,
    this.onFishSelected,
  });

  final int tankNumber;
  final String backgroundAsset;
  final void Function(FishState state, int tankNumber)? onFishSelected;

  final Random _random = Random(260211);
  final List<FishComponent> _fish = <FishComponent>[];
  ui.Image? _background;

  int get fishCount => _fish.where((fish) => fish.state.alive).length;
  double get averageHunger => _averageOf((fish) => fish.state.hunger);
  double get averageHealth => _averageOf((fish) => fish.state.health);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _background = await Flame.images.load(backgroundAsset);

    final breeding = BreedingService(_random);
    final sunny = SpeciesCatalog.sunny.founderGenome;
    const sunnySpotted = FishGenome(
      primaryColor: 0xFFFF8A33,
      secondaryColor: 0xFFFFE082,
      pattern: FishPattern.spots,
      bodyScale: 0.92,
      finScale: 1.12,
      growthRate: 1.05,
      diseaseResistance: 0.95,
      fertility: 1.08,
      valueModifier: 1.12,
      shimmer: false,
    );

    final fishStates = tankNumber == 1
        ? <FishState>[
            FishState(
              species: SpeciesCatalog.sunny,
              genome: sunny,
              ageSeconds: 210,
              hunger: 0.88,
            ),
            FishState(
              species: SpeciesCatalog.zephyr,
              genome: SpeciesCatalog.zephyr.founderGenome,
              ageSeconds: 182,
              hunger: 0.82,
            ),
            FishState(
              species: SpeciesCatalog.luna,
              genome: SpeciesCatalog.luna.founderGenome,
              ageSeconds: 126,
              hunger: 0.79,
            ),
            FishState(
              species: SpeciesCatalog.sunny,
              genome: breeding.breedSameSpecies(sunny, sunnySpotted),
              ageSeconds: 58,
              hunger: 0.91,
            ),
          ]
        : <FishState>[
            FishState(
              species: SpeciesCatalog.shadow,
              genome: SpeciesCatalog.shadow.founderGenome,
              ageSeconds: 210,
              hunger: 0.80,
            ),
            FishState(
              species: SpeciesCatalog.sunny,
              genome: sunnySpotted,
              ageSeconds: 148,
              hunger: 0.86,
            ),
            FishState(
              species: SpeciesCatalog.luna,
              genome: SpeciesCatalog.luna.founderGenome,
              ageSeconds: 74,
              hunger: 0.76,
            ),
          ];

    for (final state in fishStates) {
      final component = FishComponent(
        state: state,
        random: _random,
        onSelected: _selectFish,
      );
      _fish.add(component);
      await add(component);
    }
  }

  int feedAll() {
    final living = _fish.where((fish) => fish.state.alive).toList();
    if (living.isEmpty) {
      return 0;
    }

    for (final fish in living) {
      fish.state.feed();
      fish.celebrateFeeding();
    }

    for (var i = 0; i < 14; i++) {
      add(
        FoodFlake(
          start: Vector2(
            width * (0.10 + _random.nextDouble() * 0.80),
            height * (0.16 + _random.nextDouble() * 0.04),
          ),
          random: _random,
        ),
      );
    }

    return living.length;
  }

  void clearSelection() {
    for (final fish in _fish) {
      fish.setSelected(false);
    }
  }

  void _selectFish(FishComponent selected) {
    for (final fish in _fish) {
      fish.setSelected(identical(fish, selected));
    }
    onFishSelected?.call(selected.state, tankNumber);
  }

  double _averageOf(double Function(FishComponent fish) read) {
    final living = _fish.where((fish) => fish.state.alive).toList();
    if (living.isEmpty) {
      return 0;
    }
    final total = living.fold<double>(0, (sum, fish) => sum + read(fish));
    return total / living.length;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    _drawFurniture(canvas);

    final background = _background;
    if (background != null) {
      canvas.drawImageRect(
        background,
        ui.Rect.fromLTWH(
          0,
          0,
          background.width.toDouble(),
          background.height.toDouble(),
        ),
        ui.Rect.fromLTWH(0, 0, width, height),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
    } else {
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(0, 0, width, height),
          const ui.Radius.circular(12),
        ),
        ui.Paint()..color = const ui.Color(0xFF1297C0),
      );
    }

    final glass = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, 0),
        ui.Offset(width, height),
        const [
          ui.Color(0x35FFFFFF),
          ui.Color(0x00FFFFFF),
          ui.Color(0x1AFFFFFF),
        ],
      );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(width * 0.03, height * 0.08, width * 0.94, height * 0.76),
        ui.Radius.circular(width * 0.018),
      ),
      glass,
    );
  }

  void _drawFurniture(ui.Canvas canvas) {
    final shelfY = height * 0.92;
    final shelf = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(-width * 0.035, shelfY, width * 1.07, height * 0.13),
      ui.Radius.circular(width * 0.025),
    );
    canvas.drawRRect(
      shelf.shift(ui.Offset(0, height * 0.035)),
      ui.Paint()..color = const ui.Color(0x55000000),
    );
    canvas.drawRRect(
      shelf,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(0, shelfY),
          ui.Offset(0, shelfY + height * 0.13),
          const [ui.Color(0xFF8D5A31), ui.Color(0xFF4C2B19)],
        ),
    );
    canvas.drawRect(
      ui.Rect.fromLTWH(width * 0.04, shelfY, width * 0.92, max(2, height * 0.018)),
      ui.Paint()..color = const ui.Color(0xFFD69A5C),
    );
  }
}
