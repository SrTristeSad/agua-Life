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
- [x] Supplies screen navigation/purchase foundation is functional; final redrawn supply art/layout parity is still pending.
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
- [x] FED/HEALTH advance on legacy age steps instead of draining every rendered second.
- [x] Baseline level-1 FED behavior recovered: one FED point is removed per age step.
- [x] Food-research level 2/3 FED probability logic recovered in the simulation service.
- [x] Starvation baseline recovered: FED is clamped to zero at <=2 and HEALTH loses one point.
- [x] Environment-driven HEALTH deltas for legacy body/fin families and research levels recovered.
- [x] Food is dropped into the tank as visible flakes; exact remaining food-hit modifiers are still being reconstructed.
- [ ] Sustenance Magic Fish feeding modifier activation/progression.
- [x] Tank simulation is independent of rendering; off-screen tanks continue advancing.
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
- [x] Exact pregnancy target recovered: target age = current age + 3.
- [x] Exact birth predicate recovered from m.h(): birth is ready only when target age < current age.
- [x] The tutorial text says "up to 1/2 an hour"; where text and bytecode disagree, the bytecode predicate is authoritative for parity.
- [x] Adult threshold and breeding eligibility use age 20.
- [x] Sick fish cannot breed and infection clears the shared pregnancy physiological state.
- [x] Birth into the mother's tank is functional.
- [ ] Multiple-baby/fertility Magic Fish effect.
- [ ] Mutation Magic Fish effect.
- [ ] Exact species discovery bookkeeping.
- [ ] Per-species asking price.

## Disease and treatment

- [x] Ick disease state and visible white-speck symptom overlay.
- [x] Fungus disease state and visible green-growth symptom overlay.
- [x] Natural adult infection thresholds recovered, including contagion count and old-age modifier.
- [x] Ick treatment applies to the current tank plus isolation fish.
- [x] Fungal treatment applies to the current tank plus isolation fish.
- [x] Exact normal cure roll recovered: random(100) < 40.
- [x] Fish vitamins recovered: +6..+15 HEALTH per living fish in the selected tank.
- [x] Sick-fish isolation remains functional.
- [ ] Curing Magic Fish/tutorial forced-cure modifiers.
- [ ] Remaining protective equipment modifiers activation/progression.

## Supplies and chemicals

- [x] Original starting cash restored to $300.
- [x] First five legacy prices recovered exactly: Ick $30, Fungus $40, Vitamins $140, Growth Hormone $380, Unknown Chemical $650.
- [x] Original doses restored: first four items = 3 doses, Unknown Chemical = 1 dose.
- [x] Original shared-slot behavior restored: Ick/Fungus share one slot; Vitamins/Growth/Chemical share another; replacement is confirmed.
- [x] Growth hormone recovered: AGE += 2..6 when AGE <= 40.
- [x] Unknown chemical recovered: per-living-fish mutation roll <=25, one family index moves by one with inward boundary behavior at 0/20.
- [x] First five supply purchases are functional and purchased items appear on the tank top action bar.
- [ ] Basic/common fish eggs.
- [ ] Unusual fish eggs.
- [ ] Rare fish eggs.
- [ ] Remaining food inventory/purchasing parity.

## Research and equipment

- [ ] Fish food research purchasing/progression screen.
- [ ] Fish environment research purchasing/progression screen.
- [ ] Advertising research.
- [ ] Aeration system purchase/equipment state.
- [ ] Temperature regulator purchase/equipment state.
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
- [ ] Money earned/spent statistics.
- [ ] Average sale price.
- [ ] Highest-priced fish record.
- [ ] Remaining economy values reconstructed from J2ME behavior.

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
