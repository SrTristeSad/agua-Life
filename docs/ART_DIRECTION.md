# Agua Life art direction

## Goal

Create a fresh visual identity for Agua Life rather than shipping enlarged legacy mobile sprites.

The target is bright, readable 2D aquarium art with enough detail for modern phones while retaining the immediacy of classic mobile management games.

## Fish scale

Fish should remain relatively small inside the aquarium. A normal adult should generally occupy only a modest fraction of the tank width so that:

- the aquarium feels spacious;
- groups of fish remain readable;
- plants and decorations matter visually;
- juvenile-to-adult growth is noticeable;
- rare large specimens feel special instead of normal.

The current procedural founders use roughly 31-35 logical pixels of width on a ~350 logical-pixel-wide phone as a starting proportion, not a final sprite resolution.

## Species + genetic variation

A species keeps a recognizable silhouette, but individuals can vary through inherited traits:

- primary color;
- secondary color;
- solid / striped / spotted / patched pattern;
- body scale;
- fin scale;
- rare shimmer or future special effects.

Future art should support these changes as modular layers or masks wherever practical.

## Asset resolution

Do not author final assets at 176x208-era sprite resolution.

Final source art should be created at a comfortably high resolution and exported down as needed. Flutter/Flame will position and scale those assets responsively. The 352x416 legacy format is useful only for composition reference and migration comparisons.

## Legacy material

Extracted assets from older games may be used privately as reference during analysis where legally appropriate, but they are not intended to be committed as the final Agua Life asset set. The shipped game should use newly created artwork with its own branding and visual identity.

## Initial asset families

1. Aquarium backgrounds and glass frames
2. Fish body families
3. Tails and fins
4. Pattern masks
5. Eyes/details
6. Food and medicine items
7. Shop UI
8. Plants, rocks, caves and decorations
9. Breeding/isolation tank
10. Currency, buttons and status icons
