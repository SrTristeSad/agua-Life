from __future__ import annotations

import base64
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PIXEL_SOURCE = ROOT / 'assets' / 'pixel'
PIXEL_RUNTIME = ROOT / 'assets' / 'images' / 'pixel'
PIXEL_RUNTIME.mkdir(parents=True, exist_ok=True)


def decode_asset(source: str, destination: str) -> None:
    src = PIXEL_SOURCE / source
    if not src.exists():
        raise SystemExit(f'missing pixel source: {src}')
    encoded = ''.join(src.read_text(encoding='utf-8').split())
    try:
        data = base64.b64decode(encoded, validate=True)
    except Exception as exc:
        raise SystemExit(f'invalid base64 in {src}: {exc}') from exc
    if not data.startswith(b'\x89PNG\r\n\x1a\n'):
        raise SystemExit(f'{src} did not decode to a PNG')
    (PIXEL_RUNTIME / destination).write_bytes(data)


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly one match, got {count}')
    return text.replace(old, new, 1)


decode_asset('menu_atlas.b64', 'menu_atlas.png')
decode_asset('fish_swim_a.b64', 'fish_swim_a.png')
decode_asset('fish_swim_b.b64', 'fish_swim_b.png')

# Runtime files are real PNGs. The base64 sources are only a transport bridge for
# the GitHub connector and are deleted once the workflow has materialized them.
for source in ('menu_atlas.b64', 'fish_swim_a.b64', 'fish_swim_b.b64'):
    (PIXEL_SOURCE / source).unlink(missing_ok=True)

pubspec_path = ROOT / 'pubspec.yaml'
pubspec = pubspec_path.read_text(encoding='utf-8')
pubspec = replace_once(pubspec, 'version: 0.6.0+6', 'version: 0.7.0+7', 'pubspec version')
if '    - assets/images/pixel/\n' not in pubspec:
    pubspec = replace_once(
        pubspec,
        '    - assets/images/art/\n',
        '    - assets/images/art/\n    - assets/images/pixel/\n',
        'pubspec assets',
    )
pubspec_path.write_text(pubspec, encoding='utf-8')

main_path = ROOT / 'lib' / 'main.dart'
main = main_path.read_text(encoding='utf-8')
if "import 'pixel_landing.dart';" not in main:
    main = replace_once(
        main,
        "import 'game/models/legacy_action.dart';\n",
        "import 'game/models/legacy_action.dart';\nimport 'pixel_landing.dart';\n",
        'main import',
    )
main = replace_once(
    main,
    '        home: const AguaLifeScreen(),',
    "        home: PixelLandingScreen(\n          gameBuilder: (_) => const AguaLifeScreen(),\n          newGameBuilder: (_) => const AguaLifeScreen(startNewGame: true),\n        ),",
    'main home',
)
main = replace_once(
    main,
    'class AguaLifeScreen extends StatefulWidget {\n  const AguaLifeScreen({super.key});\n',
    'class AguaLifeScreen extends StatefulWidget {\n  const AguaLifeScreen({super.key, this.startNewGame = false});\n\n  final bool startNewGame;\n',
    'AguaLifeScreen constructor',
)
main = replace_once(
    main,
    '  bool confirmNewGame = false;\n\n  @override\n  Widget build(BuildContext context) {',
    '  bool confirmNewGame = false;\n\n  @override\n  void initState() {\n    super.initState();\n    confirmNewGame = widget.startNewGame;\n  }\n\n  @override\n  Widget build(BuildContext context) {',
    'new-game startup',
)
main_path.write_text(main, encoding='utf-8')

fish_path = ROOT / 'lib' / 'game' / 'components' / 'fish_component.dart'
fish_path.write_text(r'''import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';

import '../models/fish_disease.dart';
import '../models/fish_state.dart';

/// Animated pixel-art fish renderer.
///
/// The legacy body/fin pair deterministically selects one of ten visual families.
/// Gameplay still uses all 21 x 21 legacy combinations; this renderer only maps
/// those combinations to the first production pixel-art animation set.
class FishComponent extends PositionComponent with TapCallbacks {
  FishComponent({
    required this.state,
    required Random random,
    this.onSelected,
  })  : _random = random,
        _baseSpeed = state.species.minSpeed +
            random.nextDouble() *
                (state.species.maxSpeed - state.species.minSpeed),
        _wavePhase = random.nextDouble() * pi * 2,
        _animationOffset = random.nextInt(_frameCount),
        super(
          size: Vector2(
            state.species.baseWidth * state.genome.bodyScale * state.visualScale,
            state.species.baseHeight * state.genome.bodyScale * state.visualScale,
          ),
          anchor: Anchor.center,
        );

  static const int _frameCount = 6;
  static const double _frameWidth = 16;
  static const double _frameHeight = 12;

  final FishState state;
  final void Function(FishComponent fish)? onSelected;
  final Random _random;
  final double _baseSpeed;
  final double _wavePhase;
  final int _animationOffset;

  ui.Image? _art;
  int _atlasRow = 0;
  double _elapsed = 0;
  double _direction = 1;
  double _feedGlow = 0;
  bool _selected = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final visualIndex = (state.bodyIndex * 3 + state.finIndex) % 10;
    _atlasRow = visualIndex % 5;
    final asset = visualIndex < 5
        ? 'pixel/fish_swim_a.png'
        : 'pixel/fish_swim_b.png';
    _art = await Flame.images.load(asset);
  }

  void celebrateFeeding() => _feedGlow = 1;

  void setSelected(bool selected) => _selected = selected;

  @override
  bool containsLocalPoint(Vector2 point) {
    const padding = 9.0;
    return point.x >= -padding &&
        point.x <= width + padding &&
        point.y >= -padding &&
        point.y <= height + padding;
  }

  @override
  void onTapDown(TapDownEvent event) => onSelected?.call(this);

  @override
  void onMount() {
    super.onMount();
    final tank = parent;
    if (tank is! PositionComponent) return;

    final usableWidth = max(1.0, tank.width - width * 1.6);
    final minY = tank.height * 0.22 + height / 2;
    final maxY = max(minY + 1, tank.height * 0.76 - height / 2);
    position = Vector2(
      width * 0.8 + _random.nextDouble() * usableWidth,
      minY + _random.nextDouble() * (maxY - minY),
    );
    _direction = _random.nextBool() ? 1 : -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _feedGlow = max(0, _feedGlow - dt * 1.7);

    final targetScale = state.visualScale;
    size.setValues(
      state.species.baseWidth * state.genome.bodyScale * targetScale,
      state.species.baseHeight * state.genome.bodyScale * targetScale,
    );

    if (!state.alive) return;
    final tank = parent;
    if (tank is! PositionComponent) return;

    final hungerSpeed = 0.48 + state.hunger * 0.52;
    final healthSpeed = 0.4 + state.health * 0.6;
    final speed = _baseSpeed * hungerSpeed * healthSpeed;
    x += _direction * speed * dt;
    y += sin(_elapsed * 1.9 + _wavePhase) * 2.4 * dt;

    final left = width * 0.75;
    final right = max(left, tank.width - width * 0.75);
    if (x <= left) {
      x = left;
      _direction = 1;
    } else if (x >= right) {
      x = right;
      _direction = -1;
    }

    final top = tank.height * 0.20 + height / 2;
    final bottom = max(top, tank.height * 0.77 - height / 2);
    y = y.clamp(top, bottom).toDouble();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    if (_selected) {
      final pulse = 0.62 + sin(_elapsed * 5) * 0.18;
      canvas.drawOval(
        ui.Rect.fromLTWH(-5, -5, width + 10, height + 10),
        ui.Paint()
          ..color = ui.Color.fromARGB((165 * pulse).round(), 92, 232, 255)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final art = _art;
    if (art == null) return;

    canvas.save();
    if (_direction < 0) {
      canvas.translate(width, 0);
      canvas.scale(-1, 1);
    }

    final bob = sin(_elapsed * 4.2 + _wavePhase) * 0.6;
    canvas.translate(0, bob);

    final frame = ((_elapsed * 6).floor() + _animationOffset) % _frameCount;
    final source = ui.Rect.fromLTWH(
      frame * _frameWidth,
      _atlasRow * _frameHeight,
      _frameWidth,
      _frameHeight,
    );
    canvas.drawImageRect(
      art,
      source,
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );

    _renderDisease(canvas);
    if (state.genome.shimmer || _feedGlow > 0) {
      final alpha = state.genome.shimmer ? 85 : (80 * _feedGlow).round();
      canvas.drawOval(
        ui.Rect.fromLTWH(width * 0.28, height * 0.05, width * 0.48, height * 0.25),
        ui.Paint()..color = ui.Color.fromARGB(alpha, 255, 255, 255),
      );
    }
    canvas.restore();
  }

  void _renderDisease(ui.Canvas canvas) {
    switch (state.disease) {
      case FishDisease.none:
        return;
      case FishDisease.ich:
        final paint = ui.Paint()..color = const ui.Color(0xF5F7FFFF);
        final radius = max(0.9, width * 0.025);
        const points = <(double, double)>[
          (0.30, 0.33),
          (0.43, 0.58),
          (0.56, 0.28),
          (0.66, 0.52),
          (0.76, 0.38),
          (0.51, 0.72),
        ];
        for (final point in points) {
          canvas.drawCircle(
            ui.Offset(width * point.$1, height * point.$2),
            radius,
            paint,
          );
        }
      case FishDisease.fungus:
        final outer = ui.Paint()..color = const ui.Color(0xD04F8F38);
        final inner = ui.Paint()..color = const ui.Color(0xD078C65A);
        final blobs = <ui.Offset>[
          ui.Offset(width * 0.42, height * 0.30),
          ui.Offset(width * 0.50, height * 0.25),
          ui.Offset(width * 0.56, height * 0.33),
          ui.Offset(width * 0.48, height * 0.39),
        ];
        for (var i = 0; i < blobs.length; i++) {
          final radius = max(1.2, width * (0.045 - i * 0.004));
          canvas.drawCircle(blobs[i], radius + 0.7, outer);
          canvas.drawCircle(blobs[i], radius, inner);
        }
    }
  }
}
''', encoding='utf-8')

readme_path = PIXEL_SOURCE / 'README.md'
readme_path.write_text(
    '''# Aqua Life pixel-art runtime assets\n\n'''
    '''The approved pixel-art sources are transported through GitHub as temporary Base64 text and materialized by `.github/workflows/apply-pixel-art.yml`.\n\n'''
    '''Runtime PNG files live in `assets/images/pixel/` and are rendered with nearest-neighbor filtering.\n\n'''
    '''Current runtime set:\n- `menu_atlas.png` — splash/main menu\n- `fish_swim_a.png` — Sunny/Zephyr/Koiya/Luna/Bubblefin, six swim frames each\n- `fish_swim_b.png` — Shadow/Pearl/Neon/Tigris/Blossom, six swim frames each\n''',
    encoding='utf-8',
)

print('Pixel-art integration prepared successfully.')
