# Agua Life

Agua Life is a modern aquarium-management and fish-breeding game being rebuilt with **Flutter + Flame**.

> [!IMPORTANT]
> **PUBLIC REPOSITORY DOES NOT MEAN OPEN SOURCE.**
>
> This repository is public only so the project can use GitHub development tools and workflows. No permission is granted to use, copy, modify, redistribute, publish, sublicense, sell, mirror, repackage, train on, or create derivative works from this project's source code, game design, original artwork, assets, documentation, branding, or other project material, except where a file explicitly states otherwise.
>
> See [`LICENSE`](LICENSE) for the full terms.

## Status

Early development / playable foundation.

Current goals:

- responsive aquarium scene for modern phones;
- Flutter + Flame architecture;
- fish that remain visually small relative to the tank;
- species identity plus per-fish genetic variation;
- inheritance of colors, patterns, body scale, fin scale and gameplay traits;
- future cross-species breeding and discovery system;
- replacement artwork created specifically for Agua Life;
- save/offline progression, shop, research and collection systems in later milestones.

## Display strategy

The old 352x416 mobile format is treated only as a **legacy reference**, not as the final rendering resolution. Agua Life renders responsively at the device's available Flutter resolution. The aquarium and HUD are laid out for modern portrait phones while preserving the compact readability of classic mobile aquarium games.

## Art policy

Legacy game assets are **not part of the intended final art pipeline**. Agua Life will use newly created replacement artwork and its own visual identity. Temporary/procedural graphics may be used during development until final assets are integrated.

## Tech

- Flutter
- Flame 1.38.x
- Dart 3.11+

## Project structure

```text
lib/
  game/
    components/     # visual/gameplay components
    data/           # species definitions
    models/         # fish/genetic state
    services/       # breeding and simulation rules
  main.dart

docs/
  ARCHITECTURE.md
  ART_DIRECTION.md
```

## Development

After installing a compatible Flutter SDK:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Copyright

Copyright (c) 2026 SrTristeSad. All rights reserved.

The public visibility of this repository is not a grant of copyright, patent, trademark, or other intellectual-property rights.
