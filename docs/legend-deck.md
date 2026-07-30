# Legend Deck Reference

The deck of legends is a set of playing cards with unique powers obtained via giftbags and promotional items.

## Commands

- `LEGENDDECK SHOW` - List deck contents
- `LEGENDDECK DRAW <cardname> [target]` - Activate a card
- `LEGENDDECK ADD <card>` - Add held card to deck
- `LEGENDDECK REMOVE <card>` - Remove card (only when fully charged, not jokers)
- `LEGENDDECK HELP` - Show in-game help

## System Integration

### Emergency Defenses (PVE)

Located in `src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua`:

The basher has layered emergency defenses that trigger automatically:

**1. Wand of Reflection (HP < 10%)** - Most critical, triggers first
```lua
ataxia.wandReflectionThreshold = 10  -- HP% to trigger (default 10%)
ataxia.wandReflectionRecovery = 70   -- HP% to resume attacks (default 70%)
-- Uses: point wand234800 at me
-- Pauses attacks until HP recovers, 1 hour cooldown
```

**2. Maran Barrier (HP < 25%)** - Secondary defense
```lua
ataxia.maranThreshold = 25  -- HP% to trigger (default 25%)
-- Draws Maran card for 5000hp barrier, requires card charges
```
This out-of-tower path **stands down in Mnemosyne** — the card layer below owns Maran there
(running both would double-draw a 2-charge card).

### Mnemosyne Auto-Draw (v4.7.165)

Located in `src_new/scripts/levi_ataxia/levi/ataxia/basher/010_Mnemosyne_Legend_Deck.lua`.
The older `ataxiaBasher.ldeckRules` system (in `genrunning/002_search_targets.lua`) is
**mob-name driven** and so useless in the tower, where the roster changes every ripple.
This layer keys off state instead and rides the assembled attack round.

| Card | Condition | Effect | Interval |
|---|---|---|---|
| **Morimbuul** | while bound | Shrug off denizen ropes/bindings, 5 min | 300s |
| **Maran** | hp <= `maranAt` (20%) | 5000hp barrier on the room, 60s | 65s |
| **Seasone** | hp <= `seasoneAt` (35%) | `FOR ELIXIR`: +10% health elixir, 5 min | 300s |
| **Matic** | >= `maticAt` (3) denizens, mob above `conserveAt` | Next attack is a guaranteed high-end crit | 45s + once/room |
| **Covenant** | payoff affordable AND off cooldown, mob above `conserveAt` | Plants RECKLESSNESS | 45s |
| **Xylthus** | payoff affordable AND off cooldown, mob above `conserveAt` | Plants STUN (never on a boss) | 45s |

"Enough battlerage to do a battlerage attack that benefits from this" is resolved per class
against the rotations that actually read the affliction, via `ataxiaBasher_rageAfford` (so
the rage floor composes):

| Class | Affliction | Cashed in by | Rage |
|---|---|---|---|
| Blademaster | recklessness | Headstrike | 25 |
| Magi | recklessness | Firefall | 25 |
| Runewarden | stun | Etch | 25 |

Any other class draws neither card — planting an affliction nothing can spend wastes a
charge. **These cards hold 2-3 charges and regenerate one per HOUR**, which is why every
gate is conservative: one card per round, the per-card interval above, a hard charge check,
and a skip when the denizen already carries the affliction.

Affording the payoff is only half of it: it must also be **off cooldown right now**. A
charge spent on an affliction we cannot cash in for another 20s is a charge thrown away,
so each row of the class table above carries a `ready()` predicate alongside its rage cost
(`basher/010:90-101`) — Headstrike and
Firefall against the timestamp cooldowns `ataxiaTemp.bmHeadstrikeReadyAt` /
`magiFirefallReadyAt` (both armed with +23s at `basher/001:859` and `001:995`), Etch
against `ataxiaTemp.rwBrAt.etch` plus its 23s AB cooldown. When this is what is holding a
card back, `mnem cards` says so explicitly: `(payoff on cooldown)` (`basher/010:388`).

**Offensive cards stand down on a dying mob (v4.7.167).** Matic, Covenant and Xylthus all
skip when the target is at or below `ataxiaBasher.mnemLdeck.conserveAt` (default 25%) —
`targetNearlyDead`, `basher/010:185-193`. This is the `rageConserveThreshold` idiom the
battlerage rotations already use, and it applies *more* strongly here: rage refills in
seconds, these charges refill once an hour, and a guaranteed crit on a mob at 5% is the
purest waste in the layer. The defensive draws (Maran/Seasone/Morimbuul) are deliberately
**not** gated on it — our own emergency does not care how healthy the mob is. There is no
`mnem cards` subcommand for this one; set `ataxiaBasher.mnemLdeck.conserveAt` directly.

The GMCP read inside that helper is **fully guarded**, unlike the equivalent reads in the
rotations, and that is not defensive habit. `ataxiaBasher_mnemLdeck` is called under
`pcall` from `assembleAttack` (`basher/001:679`), so an unguarded index into a
not-yet-delivered `gmcp.IRE.Target.Info` would be swallowed there and would silently
disable the **entire card layer** with nothing on the console to say why. A missing or
zero reading is treated as "never block".

Commands: `mnem cards` (status: charges, intervals, this class's payoff),
`mnem cards on|off`, `mnem cards maran <hp%>`, `mnem cards seasone <hp%>`,
`mnem cards matic <n>`. Config lives in `ataxiaBasher.mnemLdeck` and
`ataxiaBasher.mnemLdeckBindings`.

**Ordering (v4.7.166): card -> CONFIRMED -> battlerage.** The affliction a card plants is
recorded on the denizen only when the draw is confirmed, so the exploiting battlerage
fires on the *following* round. Stamping it at send time was a lie whenever the draw
failed -- and it did, live: Etch spent 25 rage on a phantom stun.

**Charge counts from `ldm` are not trustworthy.** `ldm.initDeck()` seeds every unseen card
at its max, so a deck that has never been `LDECK LIST`ed claims full charges for
everything. The game's own rejection -- "A card depicting X currently lacks the power to
invoke its stored potential." -- is the ground truth (trigger
`legenddeck_cards/008_LDeck_No_Charges.lua`): it zeroes the count, drops the in-flight
replay, and stamps nothing. Run `LDECK LIST` once to sync the real counts.

**The root cause, found by live-log audit (v4.7.167): `ldm.matchFullName` could not
resolve a comma-suffixed card name.** It took `fullName:match("^(%S+)")`, so
"Xylthus, the Outcast" yielded the token `Xylthus,` — *with the comma* — which matches no
key in `ldm.db`. It returned nil for every such card, silently, and that killed both
halves of the charge story at once:

- `legenddeck_cards/001_Identify_Uses.lua:49` — the generic charge line "A card depicting
  X may be used N more times..." — never resolved a key, so **`ldm.deck[card].charges` was
  never updated from the game at all**. Since `initDeck` seeds every unseen card at its
  MAX, the deck claimed full charges forever: that is where the "3 charge(s) left" echo on
  a card the game then refused came from.
- `008_LDeck_No_Charges.lua:53-54` early-returns on a nil key, so **the v4.7.166 fix that
  was supposed to stop drawing into a wall never ran at all.** (`002_LDeck_Card_Out.lua:42`
  was dead the same way.)

Cards whose key *is* the first bare word — Maran, Matic, Covenant — resolved fine, which
is why this survived so long. `ldm.matchFullName` (`legend_deck/003_Legend_Deck_Functions.lua:579-604`)
now scans the name's tokens, strips punctuation from each and takes the earliest hit,
which additionally resolves past a leading honorific ("Lord Nicator, The Chosen One" ->
`Nicator`) that the first-word rule could never reach. Apostrophes are deliberately kept —
several keys carry them. `LDECK LIST` parsing was never affected: `004_LDeck_List_Line.lua`
matches `^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)$` and so reads the bare key out of the first
column rather than the flavour name, which is why a manual sync always worked while the
live feed did not. Covered by
`src_new/tests/test_legend_deck_match.lua`.

**Lapse is not confirmation (v4.7.167).** The pending replay window is 4s
(`basher/010:121`). When it runs out with no draw-success line, the layer calls
`ataxiaBasher_mnemLdeckLapse` (`basher/010:335-341`), which holds the card's interval — so
a silently-eaten draw cannot re-fire every round — releases the replay, and **stamps
nothing on the denizen**. The v4.7.166 cut called `...Confirm` on that path, and Confirm
stamps the affliction, so an *unacknowledged* draw still planted a phantom stun for Etch to
buy at 25 rage: precisely the hole that release had been written to close. Three outcomes,
three functions, and only one of them may touch denizen state — confirm (`:317`) stamps,
lapse (`:335`) and rejected (`:350`) do not.

**Known gap:** Xylthus's bind line is still uncaptured, so the stun is recorded from the
draw confirmation rather than from the bind itself (lazily expired in 4s by
`ataxiaBasher_BR_AFFS`).

### Card Tracking

Located in `src_new/scripts/levi_ataxia/levi/ataxia/legend_deck/001_Legend_Deck_Table.lua`:

```lua
ataxiaTables.ldeckcardscount.Maran  -- Check remaining charges
```

---

## Cards by Suit

### Tsol'teth Suit (Nemesis Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 1 | **Agith'tai** | Defence for 30s - chance to give focus afflictions back to attacker | 3 | 1/2hr |
| 2 | **Agith'maal** | Teleport to ruins of Seleucar (blocked by monolith) | 2 | 1/hr |
| 3 | **Ama-maalier** | Immovable for 10 seconds | 3 | 1/hr |
| 4 | **Parni** | Give hatred affliction (20s) to target | 3 | 1/hr |
| J | **Ithin'urai** | Joker - refreshes suit charges | 1 | 1/12hr |

### Seleucarian Suit (Salvation Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 5 | **Severian** | Steelmind defence to all mutual allies in room | 5 | 1/hr |
| 6 | **Lucaine** | Trueblind for 20s + significant bleeding | 3 | 1/hr |
| 7 | **Catarin** | Heal HP of everyone in room (not self, has mana cost) | 5 | 1/hr |
| 8 | **Nicator** | 30% XP boost to groups you lead for 30 min | 5 | 1/hr |
| J | **Mycale** | Joker - refreshes suit charges | 1 | 1/12hr |

### Saviours Suit (Salvation Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 9 | **Yudhishthira** | Melt icewall in direction (1s balance) | 4 | 1/hr |
| 10 | **Matic** | Next attack guaranteed high-end crit | 3 | 1/hr |
| 11 | **Ashaxei** | Travel to mutual ally on any plane (blocked by monolith) | 1 | 1/8hr |
| 12 | **Sycaerunax** | DRAGONFORM: Restore on death, fight 10s more, then die | 3 | 1/hr |
| J | **Alcibiades** | Joker - refreshes suit charges | 1 | 1/24hr |

### Betrayed/Betrayers Suit (Nemesis/Damned Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 13 | **Slith** | Stun all souls in room for 15s (short immunity after) | 3 | 1/hr |
| 14 | **Pazuzu** | Blood rain preventing magical travel >1 room away (1 min) | 3 | 1/hr |
| 15 | **Enheduanna** | Destroy corpse, massive mana damage to soul | 5 | 1/hr |
| 16 | **Ugrach** | Determine where someone in death sequence is | ∞ | - |
| J | **Han-Silnar** | Joker - refreshes suit charges | 1 | 1/12hr |

### Islanders Suit (Nemesis Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 17 | **Lordan** | Ship plunder bonus + resist plundering for 20 min | 3 | 1/hr |
| 18 | **Yuthka** | Become meteor arrow, strike outdoor target in area | 4 | 1/hr |
| 19 | **Arsentar** | If target dies in 12s, gain large HP back | 2 | 1/hr |
| 20 | **Trixy** | Wager gold, teleport to roulette (Mysia/New Thera) | 3 | 1/hr |
| J | **Vultubus** | Joker - refreshes suit charges | 1 | 1/12hr |

### Ancients Suit (Historical Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 21 | **Vellis** | Pull people down from trees/flying | 4 | 1/hr |
| 22 | **Black Boar** | Level 3 HP regen to group (3-5 min) | 2 | 1/2hr |
| 23 | **Seasone** | FOR ELIXIR: +10% health elixir for 5 min / FOR POISON: 2x loki to room | 3 | 1/hr |
| 24 | **Rurin** | Restock denizen shop to max | 1 | 1/2hr |
| J | **A Sheep** | Joker - boosts charges + reduces cooldowns | 1 | varies |

### Originals Suit (Historical Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 25 | **Haidion** | Lock target's celerity to yours (2-5 min) | 3 | 1/hr |
| 26 | **Maran** | 5000hp barrier absorbing 25% damage for room (1 min) | 2 | 1/hr |
| 27 | **Covenant** | Battlerage attack: charmed/reckless status | 3 | 1/hr |
| 28 | **Aringar** | Strip shield from target in line of sight | 4 | 1/hr |
| J | **Harlequin** | Joker - refreshes suit charges | 1 | 1/12hr |

### Impudent Suit (Renowned Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 29 | **Maklak** | Summon icewall in line of sight | 4 | 1/hr |
| 30 | **Xylthus** | Bind denizen (battlerage stun, not bosses) | 3 | 1/hr |
| 31 | **Morimbuul** | Immune to denizen ropes/bindings for 5 min | 3 | 1/hr |
| 32 | **Zh'risia** | Set all present ablaze | 3 | 1/hr |
| J | **Hycanthus** | Joker - refreshes suit charges | 1 | 1/12hr |

### Aesthetes Suit (Renowned Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 33 | **Murad** | Use your name as forging descriptor | 1 | 1/hr |
| 34 | **Bakios** | Random flask effect | 3 | 1/hr |
| 35 | **Maim** | Create sculpture of player, BREAK to travel to them | 3 | 1/hr |
| 36 | **Reinhold** | Produce random NDS food item | 4 | 1/hr |
| J | **Makesh** | Joker - refreshes suit charges | 1 | 1/12hr |

### Intrepid Suit (Renowned/Enigma Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 37 | **Horald** | Chance to reduce ship weapon fire balance by 20% (3 fires) | 3 | 1/hr |
| 38 | **Icosse** | Gain a reflection | 3 | 1/hr |
| 39 | **Aran'kesh** | Summon vulture nest (holds 10 items, never decays) | 3 | 1/hr |
| 40 | **Vulkuz** | Place random trap (clothesline/horseshoe/noose) targeting enemies | 2 | 1/hr |
| J | **Boulder** | Joker - refreshes suit charges | 1 | 1/12hr |

### Lovers Suit (Loveless Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 41 | **Rudolpho** | Stuttering effect in room for 1 min (says/tells/shouts) | 2 | 1/hr |
| 42 | **Camilla** | All mutual allies follow you | 4 | 1/hr |
| 43 | **Anna** | Room becomes private for 1 min | 1 | 1/5hr |
| 44 | **Travian** | Both you and target gain lusted status | 3 | 1/hr |
| J | **Maros** | Joker - refreshes suit charges | 1 | 1/12hr |

### Estranged Suit (Loveless Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 45 | **Maya** | Next tattoo completes instantly (not starburst) | 3 | 1/hr |
| 46 | **Belladona** | Return unsent letter/parcel from postal office | 2 | 1/hr |
| 47 | **Zsarachnor** | Target enemies another adventurer for 30s | 2 | 1/2hr |
| 48 | **The Horror** | Target cannot speak your name for 1 Achaean month | 1 | 1/30hr |
| J | **Sallust** | Joker - refreshes suit charges | 1 | 1/12hr |

### Animals Suit (Historical Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 49 | **Patches** | No waterwalk/water weird for target (30s) | 2 | 1/hr |
| 50 | **Scorn** | Sense all in target room's area (like fullsense) | 8 | 1/hr |
| 51 | **Grimlath** | PACING defence for 2 min | 5 | 1/hr |
| 52 | **Chenubis** | Teleport to Mount Nicator peak (2s balance) | 2 | 1/hr |
| J | **Penelope** | Joker - refreshes suit charges | 1 | 1/12hr |

### Scrappers Suit (Loveless Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 53 | **Jovan** | See all infamous characters and their infamy level | 5 | 1/hr |
| 54 | **Elma** | Reset scrapper's treat cooldown | 1 | 1/24hr |
| 55 | **Wavel** | Persistent farsee on target (9 ticks over 72s) | 4 | 1/hr |
| 56 | **Yozhik** | Create thornwall in direction | 3 | 1/hr |

### Knights Suit (Salvation Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 57 | **Caerid** | Numbness for 10s, ally takes double damage when it ends | 1 | 1/hr |
| 58 | **Kemnast** | Destroy player corpse, regain 30% HP/mana | 5 | 1/hr |
| 59 | **Davis Kephry** | Defend ally like a knight | 3 | 1/hr |
| 60 | **Sir Temelin** | Sense all burrowed players on continent + depth | 3 | 1/hr |
| J | **Odysseus Rani** | Joker - refreshes suit charges | 1 | varies |

### Spiritsoul Suit (Forests Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 61 | **Clio** | Create forest map, touch to travel to spirit's forest | 2 | 1/hr |
| 62 | **Erato** | Throw adventurer into trees | 3 | 1/hr |
| 63 | **Eupheme** | Pacify non-boss animal denizens in room | 3 | 1/hr |
| 64 | **Calliope** | SLOTH metamorphosis (REST to regen endurance) | 3 | 1/2hr |
| J | **Thalia** | Joker - refreshes suit charges | 1 | varies |

### Spiritheart Suit (Forests Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 65 | **Urania** | Blanket area in fog for 4 min | 1 | 1/2hr |
| 66 | **Polyhymnia** | Force everyone in clouds to move randomly | 2 | 1/hr |
| 67 | **Euterpe** | Force burrowed players to surface | 3 | 1/hr |
| 68 | **Terpsichore** | Fear all mounts in room (like Bard MARCH) | 1 | 1/hr |
| J | **Melpomene** | Joker - refreshes suit charges | 1 | varies |

### Hunterblood Suit (Hunt Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 69 | **Hippo** | Throw someone in specified direction | 2 | 1/hr |
| 70 | **Leopard** | Freeze ground in adjacent room | 3 | 1/hr |
| 71 | **Eagle** | 10% lightning resist while flying (1 min) | 3 | 1/hr |
| 72 | **Centaur** | Pull target from sky (balance knock/stun/entangle) | 3 | 1/hr |
| J | **Eel** | Joker - refreshes suit charges | 1 | varies |

### Huntersoul Suit (Hunters Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 73 | **Bear** | Sense everyone with stink affliction (cross-plane) | 5 | 1/hr |
| 74 | **Scorpion** | Place firewalls in line of sight (up to 3 rooms) | 2 | 1/hr |
| 75 | **Alligator** | Reduce current effects while swimming (1 min) | 3 | 1/hr |
| 76 | **Wolf** | Wolflegend defence (40s) - cure aff when hitting parry | 1 | 1/2hr |
| J | **Jarbo** | Joker - refreshes suit charges | 1 | varies |

### Catacombs Suit (Damned Collection)

| # | Card | Effect | Charges | Regen |
|---|------|--------|---------|-------|
| 77 | **Rhuzios** | Wrap target in bandages (3 min) - pull corpse to inv on death | 2 | 1/hr |
| 78 | **Dreyvos** | Next poison attack deals zero damage (fades in 1 min) | 2 | 1/hr |
| 79 | **Ulgase** | Teleport to random graveyard | 2 | 1/hr |
| 80 | **Malvoc** | Heal 5% HP per soul in area, halve their mana, cure per 10 souls | 1 | 1/2hr |

---

## PVE-Relevant Cards

### Direct Combat
| Card | Effect | Charges |
|------|--------|---------|
| **Matic** | Guaranteed high-end crit | 3 (1/hr) |
| **Xylthus** | Bind denizen (not bosses) | 3 (1/hr) |
| **Covenant** | Battlerage attack | 3 (1/hr) |
| **Vulkuz** | Random trap vs enemies | 2 (1/hr) |

### Survival/Defense
| Card | Effect | Charges |
|------|--------|---------|
| **Maran** | 5000hp barrier (25% absorb) | 2 (1/hr) |
| **Seasone** (ELIXIR) | +10% health elixir (5 min) | 3 (1/hr) |
| **Morimbuul** | Immune to denizen bindings (5 min) | 3 (1/hr) |
| **Sycaerunax** | Dragon death save (10s) | 3 (1/hr) |

### Group Hunting
| Card | Effect | Charges |
|------|--------|---------|
| **Nicator** | **30% XP boost** (30 min) | 5 (1/hr) |
| **Catarin** | Heal everyone (not self) | 5 (1/hr) |
| **Severian** | Steelmind to allies | 5 (1/hr) |
| **Davis** | Defend ally like knight | 3 (1/hr) |
| **Black Boar** | L3 HP regen to group | 2 (1/2hr) |

### Sailing PVE
| Card | Effect | Charges |
|------|--------|---------|
| **Lordan** | Plunder bonus (20 min) | 3 (1/hr) |
| **Horald** | Ship weapon balance reduction | 3 (1/hr) |

---

## Legend Deck Manager (LDM) v2.0

The LDM system provides charge tracking, display, joker management, and a query API for combat scripts.

### LDM Aliases

| Alias | Pattern | Effect |
|-------|---------|--------|
| `ldm` | `^ldm(?:\| (.+))$` | Main command dispatcher (help, toggle, config) |
| `ldm combat` | via ldm command | Show combat-relevant cards grouped by use case |
| `ldm all` | via ldm command | Show all cards with charges |
| `ldm <category>` | via ldm command | Filter by category (combat, travel, utility, etc.) |
| `ldraw <card>` | `^ldraw\s+(\w+)$` | Draw a card using its suit joker |
| `ldc` | `^ldc$` | Quick combat card display |

### LDM Query API (for scripts)

```lua
ldm.hasCharges("Maran")     -- true/false
ldm.getCharges("Maran")     -- number
ldm.getMaxCharges("Maran")  -- number
ldm.draw("Maran")           -- send ldeck draw maran
ldm.draw("Maran", "target") -- send ldeck draw maran target
ldm.drawQueued("Maran", "target", "eqbal") -- queue add eqbal ldeck draw maran target
```

### Card Tracking

Located in `src_new/scripts/levi_ataxia/levi/ataxia/legend_deck/`:
- `001_Legend_Deck_Init.lua` - Namespace, backward compat proxy, deck init
- `002_Legend_Deck_DB.lua` - Complete card database (80+ cards)
- `003_Legend_Deck_Functions.lua` - Display, parsing, query API, combat display
- `004_Legend_Deck_Save_Load.lua` - Persistence

Backward compatibility: `ataxiaTables.ldeckcardscount.Maran` still works — it's a metatable proxy that reads/writes through `ldm.deck["Maran"].charges`.

---

## Serpent Combat Use Cases

**Design principle**: The serpent offense (`serp_ekanelia_offense()`) does NOT auto-draw cards. Dstab/impulse timing is too sensitive for automated card draws. Instead: manual aliases + keybinds for situational draws, with `ldc` for at-a-glance status.

### Pre-Fight Setup

Draw these BEFORE engaging the target:

| Card | Effect | Why | Alias |
|------|--------|-----|-------|
| **Pazuzu** | Blood rain — blocks magical travel >1 room (1 min) | Prevents teleport escape | `ldeck draw pazuzu` |
| **Haidion** | Lock target's celerity to yours (2-5 min) | Prevents speed kiting | `ldeck draw haidion target` |
| **Grimlath** | PACING defence (2 min) | Sustain during extended fight | `ldeck draw grimlath` |
| **Noxtra** | Stop flying + duanathar (3 min) | Grounds fliers pre-engage | `ldeck draw noxtra target` |

### During Lock Phase

Reactive draws when target tries to escape the lock:

| Card | Effect | When | Alias |
|------|--------|------|-------|
| **Aringar** | Strip shield at LoS | Target shields during lock attempt | `ldeck draw aringar target` |
| **Vellis** | Pull from trees/flying | Target uses aerial escape | `ldeck draw vellis target` |
| **Centaur** | Pull from sky + stun/entangle/balance knock | Target flying | `ldeck draw centaur target` |
| **Seasone** (POISON) | Double loki in room | Group fight area denial | `ldeck draw seasone` |

### Execute / Finish Phase

Use when you have the lock and are going for the kill:

| Card | Effect | When | Alias |
|------|--------|------|-------|
| **Ama-maalier** | Self-root 10s (immovable) | Prevents pull-away during execute | `ldeck draw ama-maalier` |
| **Rudolpho** | Prevent speech in room (1 min) | Blocks raido/wings during finish | `ldeck draw rudolpho` |
| **Yozhik** | Thornwall in direction | Block escape route before execute | `ldeck draw yozhik <dir>` |
| **Maklak** | Icewall in direction | Block escape route (alt) | `ldeck draw maklak <dir>` |

### Defensive / Emergency

| Card | Effect | When | Alias |
|------|--------|------|-------|
| **Maran** | 5000hp barrier (25% absorb, 1 min) | HP dropping dangerously | `ldeck draw maran` |
| **Icosse** | +1 Reflection | Need extra defense layer | `ldeck draw icosse` |
| **Agith'tai** | Reflect focus affs for 30s | Under heavy mental aff pressure | `ldeck draw agith'tai` |
| **Sycaerunax** | 2nd wind 10s on death (DRAGON only) | Emergency last stand | `ldeck draw sycaerunax` |
| **Whitewolf** | Cure aff when hitting parry (40s) | Extended fight, aff pressure | `ldeck draw whitewolf` |

### Group Combat (`ekgroup` mode)

| Card | Effect | When | Alias |
|------|--------|------|-------|
| **Severian** | Steelmind all allies | Fight start | `ldeck draw severian` |
| **Zsarachnor** | Force target to enemy another player (30s) | Redirect enemy DPS | `ldeck draw zsarachnor target` |
| **Parni** | Hatred (20s) — treat all as enemy | Disrupt group coordination | `ldeck draw parni target` |

### Pre-Fight Macro Chains (Future)

Example keybind sequences for common setups:
```
-- Anti-escape setup (bind to F-key)
ldeck draw pazuzu
ldeck draw haidion target
ek

-- Lock finish setup
ldeck draw rudolpho
ldeck draw ama-maalier
ldeck draw yozhik <escape_dir>
```

### Integration Checklist

- [x] `ldm.hasCharges("maran")` available for custom keybinds
- [x] `ldc` alias shows combat cards with charges at a glance
- [x] Backward compat: basher Maran emergency still works via `ataxiaTables.ldeckcardscount.Maran`
- [ ] Future: pre-fight macro alias chains (e.g., `lpaz` + `lhai` + `ek`)
- [ ] Future: situational auto-draw in defense scripts (e.g., Maran below HP threshold — already in basher)
