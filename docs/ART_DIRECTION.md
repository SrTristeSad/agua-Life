# Agua Life art direction

## Goal

Recreate the supplied J2ME game's presentation as faithfully as possible while replacing its low-resolution artwork with newly redrawn, higher-quality art suitable for current phones.

This is **not a visual redesign**. Screen composition, hierarchy, aquarium framing, menus, panels, item placement and interaction flow should follow the J2ME reference.

## Core rule

Keep the original presentation. Improve only the rendering quality.

That means:

- same screen composition;
- same visible gameplay elements;
- same relative placement and hierarchy;
- same tank framing and presentation;
- same menu/panel purpose;
- same interaction flow;
- same approximate fish-to-tank scale;
- same role for every icon, item and decoration.

Do not introduce a new dashboard, persistent HUD, simultaneous-tank layout, modern card system, quests panel, or any other visual structure that does not exist in the J2ME reference unless explicitly approved later.

## Fish art

Fish must be proper redrawn sprites/illustrations, not procedural geometry drawn by code.

The J2ME fish system is the visual reference for:

- body families;
- fin/tail families;
- species combinations;
- orientation;
- swimming presentation;
- growth stages;
- disease overlays/effects where applicable.

The new sprites can contain more detail, cleaner edges, better shading and smoother animation, but they must remain recognizably equivalent in gameplay role and proportions.

## Aquarium art

Each aquarium should be redrawn at high resolution while preserving the J2ME composition and functional layout.

Improve:

- glass;
- water;
- substrate;
- plants;
- rocks;
- equipment;
- decorations;
- lighting;
- bubbles;
- object clarity.

Do not replace the original screen composition with a different room, shelf, cabinet, multi-tank dashboard or full-screen aquarium unless that presentation exists in the J2ME reference.

## UI art

Buttons, panels, tabs, indicators, item icons and fonts may be redrawn to look cleaner on modern displays, but their position, purpose and hierarchy should follow the legacy screen being reproduced.

Touch targets may be larger than the visible artwork invisibly for usability.

## Resolution strategy

The original logical composition is the reference coordinate system. Final assets should be authored at higher resolution, then rendered with preserved aspect ratio.

Modern phones should use:

- aspect-ratio-preserving scaling;
- safe-area handling;
- letterboxing or controlled background extension when required;
- no stretching of the original composition;
- no rearranging UI just to fill unused screen space.

## Legacy material

The supplied J2ME package may be inspected privately as a reference for layout, animation, timing and gameplay behavior. Final committed game assets should be newly redrawn rather than direct copies of the original bitmap files.

## Asset families to redraw

1. Splash/title presentation
2. Aquarium/tank backgrounds and frames
3. Fish body families
4. Fish fin/tail families
5. Growth-stage visuals
6. Disease visuals
7. Food and medicine
8. Eggs and chemicals
9. Shop/supplies UI
10. Isolation/breeding tank
11. Sale tank
12. Plants, rocks, decorations and equipment
13. Buttons, panels, icons and fonts
14. Research/statistics/options/help screens

## Definition of success

A player familiar with the J2ME version should immediately recognize the same game and same interface flow, but it should look like the artwork was redrawn for a modern high-resolution phone.
