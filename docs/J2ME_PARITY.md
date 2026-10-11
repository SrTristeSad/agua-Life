# J2ME parity contract

Agua Life is being rebuilt as a clean-room Flutter/Flame implementation of the supplied legacy J2ME game.

The target is **gameplay parity AND presentation parity**. The legacy executable is the behavioral and presentation reference. Final builds use new Dart code and newly redrawn high-resolution art, but the game itself should behave and present itself like the J2ME version.

## Non-negotiable rule

If there is a conflict between a modern redesign idea and the way the J2ME game works or presents a screen, **the J2ME version wins**.

Do not invent new gameplay, new navigation, new HUD structure, new tank layout, new management flow or new progression unless it is explicitly approved later.

## Presentation parity

- [ ] Reproduce the same screen structure and screen order as the J2ME build.
- [ ] Reproduce the same aquarium/tank presentation and switching behavior as the J2ME build.
- [ ] Reproduce the same menu hierarchy and navigation flow.
- [ ] Reproduce the same placement and purpose of gameplay controls.
- [ ] Reproduce the same shop/supplies presentation and interaction flow.
- [ ] Reproduce the same fish inspection/status presentation.
- [ ] Reproduce the same isolation/breeding presentation.
- [ ] Reproduce the same sale-tank presentation.
- [ ] Reproduce the same research/statistics/options/help presentation.
- [ ] Reproduce the same transitions and modal/popup behavior where applicable.
- [ ] Do not show multiple aquariums simultaneously unless the J2ME screen being reproduced does so.
- [ ] Do not add a modern persistent HUD if the equivalent J2ME screen does not have it.

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

- [x] Individual fish age/growth foundation
- [x] Hunger foundation
- [x] Health foundation
- [ ] Exact J2ME feeding interaction and food behavior
- [ ] Real-time clock separated from rendering
- [ ] Offline progression while the app is closed
- [ ] Tank capacity rules
- [ ] Young-fish vulnerability when a tank is overcrowded
- [ ] Death and removal/trashed-fish accounting
- [ ] Persistent save with schema migrations

## Breeding and species

- [x] Preserve the legacy 21 body families
- [x] Preserve the legacy 21 fin families
- [x] Preserve the 21 x 21 = 441 combination space
- [ ] Exact legacy parent-combination lookup behavior
- [ ] Exact isolation/breeding tank workflow
- [ ] Pregnancy state and real-time birth delay
- [ ] Multiple-baby/fertility effects
- [ ] Adult threshold and breeding eligibility
- [ ] Species discovery behavior
- [ ] Per-species asking price

## Disease and treatment

- [ ] Ich disease
- [ ] Fungus disease
- [ ] Ich treatment
- [ ] Fungal treatment
- [ ] Fish vitamins
- [ ] Cure probability and research/environment modifiers
- [ ] Sick-fish isolation workflow

## Supplies and chemicals

- [ ] Basic/common fish eggs
- [ ] Unusual fish eggs
- [ ] Rare fish eggs
- [ ] Growth hormone
- [ ] Mutation/unknown chemical
- [ ] Food inventory and feeding supplies
- [ ] Supply shop inventory and purchasing

## Research and equipment

- [ ] Fish food research
- [ ] Fish environment research
- [ ] Advertising research
- [ ] Aeration system
- [ ] Temperature regulator
- [ ] Cleaning snail
- [ ] Golden seahorse
- [ ] Nutrition plant
- [ ] Incubation plant
- [ ] Curing plant
- [ ] Fertility plant
- [ ] Decorations/ornaments
- [ ] Second-tank progression/unlock rules

## Selling and economy

- [ ] Dedicated sale tank
- [ ] Adult-only sale eligibility
- [ ] Customer arrival/sale simulation
- [ ] Popularity/interest behavior
- [ ] Customer feedback/comments behavior
- [ ] Money earned/spent tracking
- [ ] Average sale price
- [ ] Highest-priced fish record
- [ ] Economy values reconstructed from the J2ME behavior

## Seven magic fish

- [ ] Fertility effect
- [ ] Sustenance effect
- [ ] Curing effect
- [ ] Growth effect
- [ ] Health effect
- [ ] Mutation effect
- [ ] Golden Guppy wealth effect
- [ ] End-goal/progression state for discovering all seven

## Statistics and settings

- [ ] Fish sold
- [ ] Fish trashed
- [ ] Fish cured
- [ ] Money earned
- [ ] Money spent
- [ ] Average money per fish
- [ ] Food given
- [ ] Hours played
- [ ] Species found
- [ ] Top fish price
- [ ] Magic species/fish bred
- [ ] Total fish bred
- [ ] Options, speed and audio settings
- [ ] Help/tutorial behavior and presentation

## Art replacement rule

The old art is a composition and animation reference only. New art must depict the same functional objects and preserve their visual role and approximate placement, but at a quality suitable for current phones.

The goal is not a redesign. It is the **same game, redrawn**.
