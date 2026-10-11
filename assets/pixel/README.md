# Aqua Life Pixel Runtime Assets

These atlases are runtime-optimized 512x384 indexed PNG exports derived from the approved Aqua Life pixel-art direction. They are intentionally kept separate from the legacy J2ME reference assets.

- `menu_atlas.png` — splash / main-menu UI
- `game_ui_atlas.png` — HUD, navigation and negotiation UI
- `fish_atlas_a.png` — Sunny, Zephyr, Koiya, Luna, Bubblefin animation sheet
- `fish_atlas_b.png` — Shadow, Pearl, Neon, Tigris, Blossom animation sheet
- `fx_atlas.png` — food, bubbles, diseases, eggs and effects
- `tank_atlas.png` — tanks, plants, rocks and equipment

Runtime rendering should use nearest-neighbor filtering so the pixel-art edges stay crisp when scaled.
