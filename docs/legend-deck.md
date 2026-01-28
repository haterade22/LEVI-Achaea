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
