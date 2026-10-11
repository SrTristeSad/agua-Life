# Agua Life architecture

## Rendering strategy

Agua Life does not render into a fixed 176x208 or 352x416 framebuffer. Those dimensions are historical references only.

The Flame game receives the actual Flutter canvas size and lays out the aquarium responsively. This lets the game remain sharp on modern phones while preserving the compact composition of classic aquarium-management games.

## Current layers

```text
Flutter shell
  -> FlameGame
    -> TankScene
      -> FishComponent

SpeciesCatalog
  -> FishSpecies
    -> founder FishGenome

BreedingService
  -> inherits / mutates FishGenome
```

## Fish identity

A fish is conceptually split into two layers:

1. **Species identity** — body family, baseline size, baseline movement and future animation set.
2. **Individual genome** — color, pattern, body scale, fin scale and gameplay traits.

This is deliberate: two fish can be the same species while still looking and behaving slightly differently.

## Planned fish rendering pipeline

The procedural renderer is temporary. Final artwork should be modular enough to support genetic variation without requiring one fully hand-painted sprite for every possible combination.

Suggested layers:

```text
body base
+ tail
+ dorsal fin
+ lower fin
+ pattern mask
+ primary palette
+ secondary palette
+ eyes/details
+ rare effect layer
```

The renderer can later swap procedural geometry for sprite layers without changing the genetic model.

## Simulation roadmap

Planned services should remain separated from rendering:

- growth and aging;
- hunger and feeding;
- health and disease;
- pregnancy / breeding cooldowns;
- same-species inheritance;
- cross-species discovery rules;
- economy and selling;
- research progression;
- inventory and consumables;
- offline progression;
- persistence / save migration.

## Save compatibility

Genetic data should be serialized as stable primitives (IDs, integers, doubles and booleans). Art assets and render implementation must not be embedded into save data. This makes later art upgrades possible without invalidating player saves.
