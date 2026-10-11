# v0.6 full-system testing build

This build makes every major system in the recovered J2ME design reachable so it can be tested end-to-end.

## Recovered exactly from bytecode/data

- 21 body families x 21 fin families (441 species combinations).
- Adult age 20; normal age step 600 seconds.
- Speed timing: Slow 15 min/age, Normal 10, Fast 5, Paused.
- Pregnancy target and strict birth predicate already recovered in previous builds.
- Exact base-price matrix plus legacy overrides.
- Exact seven Magic Fish body/fin combinations.
- Fertility Magic Fish extra baby.
- Mutation Magic Fish newborn mutation predicate and +/-1 family mutation.
- Curing Magic Fish 20% age-step cure roll.
- Growth Magic Fish <=10/100 age bonus roll.
- Health Magic Fish +1 HEALTH age-step effect.
- Sustenance Magic Fish starvation protection through the recovered health service.
- Aeration and temperature-regulator health rolls already recovered.
- Nutrition plant starvation support already recovered.
- Fertility plant extra baby.
- Original prices for items 0-24 and Environment Research item 26.
- Original level-two research prices: Advertising $1500, Food $650, Environment $1750.
- Research clock rate recovered from the J2ME timer: progress uses the selected legacy speed.

## Functional in this testing build

- Persistent local save with a versioned schema.
- Offline fish/research progression (safety-capped to 30 days per load).
- New Game confirmation and Save & Exit.
- Full supplies browser covering treatments, enhancements, eggs, research, equipment, Isola plants, ornaments and second tank.
- Food-pack replenishment.
- Common, unusual and rare egg spawning with environment-research gates.
- Second tank purchase/unlock and switching.
- Dedicated sale list; only healthy adult fish can enter it.
- Per-species asking prices, +/- price adjustment, customer visits and automatic sales.
- Advertising and ornaments affect the current customer-interest model.
- Statistics screen and persistent counters.
- Options screen for Music, Sound, Help Messages and Slow/Normal/Fast/Paused.
- Trophy screen for all seven Magic Fish and completion state.
- Help/About screens.

## Still approximation pending deeper bytecode reconstruction

These systems are functional, but their final probability/distribution has not yet been proven byte-for-byte:

- customer purchase/feedback probability formula;
- exact egg family distribution, egg count and incubation viability;
- exact gameplay effects of Cleaning Snail, Golden Seahorse and Plant of Incubation;
- food-pack purchase price/count (the J2ME localization confirms food is sold, but the exact transaction has not yet been isolated);
- final visual layout/art parity for every secondary screen;
- actual MIDI playback (the switches persist, but audio playback is not yet wired).

Do not mark those subrules as exact parity until the remaining bytecode paths are recovered.
