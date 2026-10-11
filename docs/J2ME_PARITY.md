# J2ME parity contract

Agua Life is being rebuilt as a clean-room Flutter/Flame implementation of the supplied legacy J2ME game.

The target is **gameplay parity AND presentation parity**. The legacy executable is the behavioral and presentation reference. Final builds use new Dart code and newly redrawn high-resolution art, but the game itself should behave and present itself like the J2ME version.

## Non-negotiable rule

If there is a conflict between a modern redesign idea and the way the J2ME game works or presents a screen, **the J2ME version wins**.

Do not invent new gameplay, new navigation, new HUD structure, new tank layout, new management flow or new progression unless it is explicitly approved later.

## Presentation parity

- [x] Main tank screen restored to the 352x416 J2ME composition reference.
- [x] One aquarium is shown at a time; tanks are switched instead of displayed simultaneously.
- [x] Top action bar, bottom isolation area and softkey-style controls restored as the base interaction layout.
- [ ] Reproduce the complete menu hierarchy and navigation flow.
- [ ] Reproduce the exact shop/supplies presentation and interaction flow.
- [x] Reproduce the fish browsing/status interaction foundation.
- [x] Reproduce the isolation/breeding placement and selection foundation.
- [ ] Reproduce the same sale-tank presentation.
- [ ] Reproduce the same research/statistics/options/help presentation.
- [ ] Reproduce the same transitions and modal/popup behavior where applicable.
- [x] Do not show multiple aquariums simultaneously unless the J2ME screen being reproduced does so.
- [x] Do not add a modern persistent HUD if the equivalent J2ME screen does not have it.

### What may change visually

Only the art/rendering quality may be modernized:

- redraw aquarium backgrounds at high resolution;
- redraw fish sprites at high resolution;
- redraw plants, rocks, decorations and equipment;
- redraw buttons, panels, icons and fonts while preserving their role, hierarchy and approximate composition;
- use smooth animation and higher frame rates where this does not alter gameplay timing;
- scale the original composition to modern displays without stretching or distorting it;
- use safe-area padding/letterboxing when necessary to preserve the original composition;
- enlarge touch hitboxes invisibly when necessary, without changing the visible layout.

## Core aquarium simulation

- [x] Legacy age foundation: age 20 is adulthood.
- [x] Normal-speed age timing recovered from bytecode: one age step per 600 seconds.
- [x] Hunger foundation.
- [x] Health foundation.
- [x] Food is dropped into the tank as individual flakes; fish consume flakes individually.
- [ ] Exact remaining J2ME feeding values and research modifiers.
- [ ] Real-time clock separated from rendering.
- [ ] Offline progression while the app is closed.
- [x] Tank capacity restored to 18 fish.
- [x] Full-tank birth behavior foundation: newborn is not added when the tank is full.
- [ ] Exact young-fish environmental vulnerability rules.
- [ ] Death and removal/trashed-fish accounting.
- [ ] Persistent save with schema migrations.

## Breeding and species

- [x] Preserve the legacy 21 body families.
- [x] Preserve the legacy 21 fin families.
- [x] Preserve the 21 x 21 = 441 combination space.
- [x] Species names are built from the legacy fin-family + body-family names.
- [x] Exact child combination rule recovered from bytecode: integer midpoint of the two parents' body indices and fin indices.
- [x] Isolation breeding flow is functional: isolate one fish, select an adult mate, use MATCH/BREED.
- [x] Exact pregnancy timing structure recovered: pregnancy target is current age + 3.
- [x] At normal speed, three age steps equal up to 30 minutes, matching the J2ME tutorial text.
- [x] Adult threshold and breeding eligibility use age 20.
- [x] Birth into the mother's tank is functional.
- [ ] Multiple-baby/fertility Magic Fish effect.
- [ ] Mutation Magic Fish effect.
- [ ] Exact species discovery bookkeeping.
- [ ] Per-species asking price.

## Disease and treatment

- [ ] Ich disease.
- [ ] Fungus disease.
- [ ] Ich treatment.
- [ ] Fungal treatment.
- [ ] Fish vitamins.
- [ ] Cure probability and research/environment modifiers.
- [ ] Sick-fish isolation workflow.

## Supplies and chemicals

- [ ] Basic/common fish eggs.
- [ ] Unusual fish eggs.
- [ ] Rare fish eggs.
- [ ] Growth hormone.
- [ ] Mutation/unknown chemical.
- [ ] Food inventory and feeding supplies.
- [ ] Supply shop inventory and purchasing.

## Research and equipment

- [ ] Fish food research.
- [ ] Fish environment research.
- [ ] Advertising research.
- [ ] Aeration system.
- [ ] Temperature regulator.
- [ ] Cleaning snail.
- [ ] Golden seahorse.
- [ ] Nutrition plant.
- [ ] Incubation plant.
- [ ] Curing plant.
- [ ] Fertility plant.
- [ ] Decorations/ornaments.
- [ ] Second-tank progression/unlock rules.

## Selling and economy

- [ ] Dedicated sale tank.
- [ ] Adult-only sale eligibility.
- [ ] Customer arrival/sale simulation.
- [ ] Popularity/interest behavior.
- [ ] Customer feedback/comments behavior.
- [ ] Money earned/spent tracking.
- [ ] Average sale price.
- [ ] Highest-priced fish record.
- [ ] Economy values reconstructed from the J2ME behavior.

## Seven magic fish

- [ ] Fertility effect.
- [ ] Sustenance effect.
- [ ] Curing effect.
- [ ] Growth effect.
- [ ] Health effect.
- [ ] Mutation effect.
- [ ] Golden Guppy wealth effect.
- [ ] End-goal/progression state for discovering all seven.

## Statistics and settings

- [ ] Fish sold.
- [ ] Fish trashed.
- [ ] Fish cured.
- [ ] Money earned.
- [ ] Money spent.
- [ ] Average money per fish.
- [ ] Food given.
- [ ] Hours played.
- [ ] Species found.
- [ ] Top fish price.
- [ ] Magic species/fish bred.
- [ ] Total fish bred.
- [ ] Options, speed and audio settings.
- [ ] Help/tutorial behavior and presentation.

## Art replacement rule

The old art is a composition and animation reference only. New art must depict the same functional objects and preserve their visual role and approximate placement, but at a quality suitable for current phones.

The goal is not a redesign. It is the **same game, redrawn**.
