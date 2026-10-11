# J2ME gameplay parity contract

Agua Life is being rebuilt as a clean-room Flutter/Flame implementation of the gameplay loop observed in the supplied legacy J2ME build.

The target is **functional parity**, not reuse of the legacy executable in the shipped game. Final builds use new Dart code and replacement art/audio. The J2ME package is a behavioral reference only.

## Core aquarium simulation

- [x] Two visible aquarium tanks in the modern layout
- [x] Individual fish age/growth foundation
- [x] Hunger and feeding foundation
- [x] Health foundation
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
- [ ] Isolation/breeding tank workflow
- [ ] Pregnancy state and real-time birth delay
- [ ] Multiple-baby/fertility effects
- [ ] Adult threshold and breeding eligibility
- [ ] Species discovery book
- [ ] Per-species asking price
- [ ] Lineage/history in the modern UI without changing legacy results

## Disease and treatment

- [ ] Ich disease (white-speck presentation)
- [ ] Fungus disease (green-growth presentation)
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
- [ ] Popularity/interest graph
- [ ] Customer feedback/comments with newly written text
- [ ] Money earned/spent tracking
- [ ] Average sale price
- [ ] Highest-priced fish record
- [ ] Economy balance reconstructed from the legacy behavior

## Seven magic fish

- [ ] Fertility effect: increased baby output
- [ ] Sustenance effect: reduced feeding pressure
- [ ] Curing effect: improved cure chance
- [ ] Growth effect: faster juvenile growth
- [ ] Health effect: improved health
- [ ] Mutation effect: chance of unrelated offspring result
- [ ] Golden Guppy wealth effect
- [ ] End-goal/progression state for discovering all seven

## Statistics and menus

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
- [ ] Help/tutorial rewritten for the new interface

## Modern presentation rules

- Do not stretch one aquarium to fill the phone.
- Use the extra vertical space on modern phones to present both main aquariums.
- Tanks must read as physical objects resting on shelves/cabinets, not flat full-screen backgrounds.
- Fish should remain relatively small inside the tank so the habitat has breathing room.
- Replacement fish art uses the polished Aqua Life direction approved for the remake.
- Modern UI may improve readability and touch ergonomics, but must not silently change simulation results.
