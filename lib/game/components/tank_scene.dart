import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../data/species_catalog.dart';
import '../models/fish_genome.dart';
import '../models/fish_state.dart';
import '../services/breeding_service.dart';
import 'fish_component.dart';
import 'food_flake.dart';

class TankScene extends PositionComponent {
  final Random _random = Random(260211);
  final List<FishComponent> _fish = <FishComponent>[];

  int get fishCount => _fish.where((fish) => fish.state.alive).length;

  double get averageHunger => _averageOf((fish) => fish.state.hunger);
  double get averageHealth => _averageOf((fish) => fish.state.health);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final breeding = BreedingService(_random);
    final sunnyA = SpeciesCatalog.sunny.founderGenome;
    const sunnyB = FishGenome(
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

    final fishStates = <FishState>[
      FishState(
        species: SpeciesCatalog.sunny,
        genome: sunnyA,
        ageSeconds: 210,
        hunger: 0.88,
      ),
      FishState(
        species: SpeciesCatalog.sunny,
        genome: sunnyB,
        ageSeconds: 155,
        hunger: 0.78,
      ),
      FishState(
        species: SpeciesCatalog.sunny,
        genome: breeding.breedSameSpecies(sunnyA, sunnyB),
        ageSeconds: 82,
        hunger: 0.72,
      ),
      FishState(
        species: SpeciesCatalog.sunny,
        genome: breeding.breedSameSpecies(sunnyA, sunnyB),
        ageSeconds: 34,
        hunger: 0.92,
      ),
      FishState(
        species: SpeciesCatalog.zephyr,
        genome: SpeciesCatalog.zephyr.founderGenome,
        ageSeconds: 210,
        hunger: 0.84,
      ),
      FishState(
        species: SpeciesCatalog.luna,
        genome: SpeciesCatalog.luna.founderGenome,
        ageSeconds: 170,
        hunger: 0.81,
      ),
      FishState(
        species: SpeciesCatalog.shadow,
        genome: SpeciesCatalog.shadow.founderGenome,
        ageSeconds: 120,
        hunger: 0.76,
      ),
    ];

    for (final state in fishStates) {
      final component = FishComponent(state: state, random: _random);
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

    for (var i = 0; i < 22; i++) {
      add(
        FoodFlake(
          start: Vector2(
            width * (0.08 + _random.nextDouble() * 0.84),
            height * (0.09 + _random.nextDouble() * 0.05),
          ),
          random: _random,
        ),
      );
    }

    return living.length;
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

    final rect = ui.Rect.fromLTWH(0, 0, width, height);
    final water = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(width * 0.5, 0),
        ui.Offset(width * 0.5, height),
        const [
          ui.Color(0xFF64E4FF),
          ui.Color(0xFF168BC8),
          ui.Color(0xFF084B78),
        ],
        const [0, 0.52, 1],
      );
    canvas.drawRect(rect, water);

    _drawLightRays(canvas);
    _drawBackPlants(canvas);
    _drawCave(canvas);
    _drawGravel(canvas);
    _drawBubbles(canvas);
    _drawGlassFrame(canvas);
  }

  void _drawLightRays(ui.Canvas canvas) {
    final rayPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF).withAlpha(20);

    final firstRay = ui.Path()
      ..moveTo(width * 0.06, 0)
      ..lineTo(width * 0.23, 0)
      ..lineTo(width * 0.46, height * 0.78)
      ..lineTo(width * 0.32, height * 0.78)
      ..close();
    canvas.drawPath(firstRay, rayPaint);

    final secondRay = ui.Path()
      ..moveTo(width * 0.58, 0)
      ..lineTo(width * 0.68, 0)
      ..lineTo(width * 0.78, height * 0.58)
      ..lineTo(width * 0.69, height * 0.58)
      ..close();
    canvas.drawPath(secondRay, rayPaint);
  }

  void _drawBackPlants(ui.Canvas canvas) {
    final stems = ui.Paint()
      ..color = const ui.Color(0xFF146A49)
      ..strokeWidth = max(2, width * 0.007)
      ..strokeCap = ui.StrokeCap.round;
    final leaves = ui.Paint()..color = const ui.Color(0xFF43AD58);

    for (var plant = 0; plant < 7; plant++) {
      final baseX = width * (0.055 + plant * 0.15);
      final baseY = height * 0.90;
      final plantHeight = height * (0.10 + (plant % 4) * 0.032);
      final lean = plant.isEven ? -5.0 : 5.0;
      canvas.drawLine(
        ui.Offset(baseX, baseY),
        ui.Offset(baseX + lean, baseY - plantHeight),
        stems,
      );
      for (var leaf = 1; leaf <= 4; leaf++) {
        final y = baseY - plantHeight * (leaf / 5);
        final side = leaf.isEven ? 1.0 : -1.0;
        canvas.drawOval(
          ui.Rect.fromCenter(
            center: ui.Offset(baseX + side * width * 0.017, y),
            width: width * 0.037,
            height: height * 0.021,
          ),
          leaves,
        );
      }
    }
  }

  void _drawCave(ui.Canvas canvas) {
    final rock = ui.Paint()..color = const ui.Color(0xFF5F6E68);
    final rockLight = ui.Paint()..color = const ui.Color(0xFF84918B);
    final opening = ui.Paint()..color = const ui.Color(0xFF193C43);

    final caveRect = ui.Rect.fromLTWH(
      width * 0.69,
      height * 0.76,
      width * 0.18,
      height * 0.13,
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(caveRect, ui.Radius.circular(width * 0.05)),
      rock,
    );
    canvas.drawOval(
      ui.Rect.fromLTWH(
        width * 0.735,
        height * 0.805,
        width * 0.09,
        height * 0.085,
      ),
      opening,
    );
    canvas.drawOval(
      ui.Rect.fromLTWH(
        width * 0.71,
        height * 0.77,
        width * 0.07,
        height * 0.025,
      ),
      rockLight,
    );
  }

  void _drawGravel(ui.Canvas canvas) {
    final sand = ui.Paint()..color = const ui.Color(0xFFD9BE75);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, height * 0.88, width, height * 0.12),
      sand,
    );

    final pebblePaint = ui.Paint()..color = const ui.Color(0xFFB79A58);
    final pebbleDark = ui.Paint()..color = const ui.Color(0xFF8E784B);
    for (var i = 0; i < 38; i++) {
      final x = width * ((i * 37) % 101) / 101;
      final y = height * (0.895 + ((i * 13) % 70) / 1000);
      canvas.drawCircle(
        ui.Offset(x, y),
        max(1.2, width * (0.003 + (i % 3) * 0.0015)),
        i.isEven ? pebblePaint : pebbleDark,
      );
    }
  }

  void _drawBubbles(ui.Canvas canvas) {
    final bubblePaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF).withAlpha(105)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (var i = 0; i < 20; i++) {
      final x = width * (((i * 47) % 97) / 100 + 0.02);
      final y = height * (0.12 + ((i * 31) % 65) / 100);
      final radius = max(1.8, width * (0.006 + (i % 4) * 0.002));
      canvas.drawCircle(ui.Offset(x, y), radius, bubblePaint);
    }
  }

  void _drawGlassFrame(ui.Canvas canvas) {
    final frame = ui.Paint()
      ..color = const ui.Color(0xDD142B3C)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = max(4, width * 0.018);
    canvas.drawRect(
      ui.Rect.fromLTWH(2, 2, max(0, width - 4), max(0, height - 4)),
      frame,
    );

    final highlight = ui.Paint()
      ..color = const ui.Color(0x66FFFFFF)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      ui.Offset(width * 0.04, height * 0.04),
      ui.Offset(width * 0.04, height * 0.83),
      highlight,
    );
  }
}
