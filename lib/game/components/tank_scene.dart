import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../data/species_catalog.dart';
import '../models/fish_genome.dart';
import '../models/fish_species.dart';
import '../services/breeding_service.dart';
import 'fish_component.dart';

class TankScene extends PositionComponent {
  final Random _random = Random(260211);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final breeding = BreedingService(_random);
    final sunnyA = SpeciesCatalog.sunny.founderGenome;
    final sunnyB = FishGenome(
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

    final fish = <({FishSpecies species, FishGenome genome})>[
      (species: SpeciesCatalog.sunny, genome: sunnyA),
      (species: SpeciesCatalog.sunny, genome: sunnyB),
      (
        species: SpeciesCatalog.sunny,
        genome: breeding.breedSameSpecies(sunnyA, sunnyB),
      ),
      (
        species: SpeciesCatalog.sunny,
        genome: breeding.breedSameSpecies(sunnyA, sunnyB),
      ),
      (species: SpeciesCatalog.zephyr, genome: SpeciesCatalog.zephyr.founderGenome),
      (species: SpeciesCatalog.luna, genome: SpeciesCatalog.luna.founderGenome),
      (species: SpeciesCatalog.shadow, genome: SpeciesCatalog.shadow.founderGenome),
    ];

    for (final entry in fish) {
      add(
        FishComponent(
          species: entry.species,
          genome: entry.genome,
          random: _random,
        ),
      );
    }
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
          ui.Color(0xFF55D8FF),
          ui.Color(0xFF1789C8),
          ui.Color(0xFF0B4F81),
        ],
        const [0, 0.52, 1],
      );
    canvas.drawRect(rect, water);

    _drawLightRays(canvas);
    _drawPlants(canvas);
    _drawGravel(canvas);
    _drawBubbles(canvas);
    _drawGlassFrame(canvas);
  }

  void _drawLightRays(ui.Canvas canvas) {
    final rayPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF).withAlpha(18);
    final ray = ui.Path()
      ..moveTo(width * 0.08, 0)
      ..lineTo(width * 0.27, 0)
      ..lineTo(width * 0.48, height * 0.78)
      ..lineTo(width * 0.34, height * 0.78)
      ..close();
    canvas.drawPath(ray, rayPaint);
  }

  void _drawPlants(ui.Canvas canvas) {
    final stems = ui.Paint()
      ..color = const ui.Color(0xFF1B7A50)
      ..strokeWidth = max(2, width * 0.008)
      ..strokeCap = ui.StrokeCap.round;
    final leaves = ui.Paint()..color = const ui.Color(0xFF52B95B);

    for (var plant = 0; plant < 6; plant++) {
      final baseX = width * (0.08 + plant * 0.17);
      final baseY = height * 0.90;
      final plantHeight = height * (0.10 + (plant % 3) * 0.035);
      canvas.drawLine(
        ui.Offset(baseX, baseY),
        ui.Offset(baseX + (plant.isEven ? -4 : 4), baseY - plantHeight),
        stems,
      );
      for (var leaf = 1; leaf <= 3; leaf++) {
        final y = baseY - plantHeight * (leaf / 4);
        final side = leaf.isEven ? 1.0 : -1.0;
        canvas.drawOval(
          ui.Rect.fromCenter(
            center: ui.Offset(baseX + side * width * 0.018, y),
            width: width * 0.035,
            height: height * 0.022,
          ),
          leaves,
        );
      }
    }
  }

  void _drawGravel(ui.Canvas canvas) {
    final sand = ui.Paint()..color = const ui.Color(0xFFD9BE75);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, height * 0.88, width, height * 0.12),
      sand,
    );

    final pebblePaint = ui.Paint()..color = const ui.Color(0xFFB79A58);
    for (var i = 0; i < 28; i++) {
      final x = width * ((i * 37) % 101) / 101;
      final y = height * (0.895 + ((i * 13) % 70) / 1000);
      canvas.drawCircle(
        ui.Offset(x, y),
        max(1.2, width * (0.003 + (i % 3) * 0.0015)),
        pebblePaint,
      );
    }
  }

  void _drawBubbles(ui.Canvas canvas) {
    final bubblePaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF).withAlpha(95)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (var i = 0; i < 18; i++) {
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
