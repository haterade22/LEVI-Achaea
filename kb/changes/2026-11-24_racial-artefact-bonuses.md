---
topic: racial-artefact-bonuses-2026-11-24
confidence: mixed (tagged per claim)
sources:
  - kb/raw/announcements/racial_artefacts_2026-11-24.txt
  - docs/artefacts-reference.md
  - kb/raw/live/artefact_power_list_owned.txt
code:
  - src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/033_Artefacts.lua
last_verified: 2026-11-24
---

# Racial artefact bonuses (2026-11-24)

Each race now has one artefact power at level 1, for free. An owned artefact of the same power
wins, so a level 2 or 3 artefact is still an upgrade. The bonus is fixed at level 1. For us
nothing changes: we own all of these powers at level 2 or 3. For any OTHER player, "no
artefacts" is no longer the floor: their race's level-1 power is.

## Facts

### Race to power
The race/power pairs are READ (the game post, `kb/raw/announcements/racial_artefacts_2026-11-24.txt`).
The level-1 item and its size are from `docs/artefacts-reference.md` (HELP-based; the game's
`ARTEFACT POWER SHOW` records state no size, `docs/my-artefacts.md`, "The game's power records").

| Race | Power (key) | Level-1 item | Size at level 1 | Ours (`kb/raw/live/artefact_power_list_owned.txt`) |
|---|---|---|---|---|
| Human | `health_sip` | Mayan Ring | +10% health elixir healing | Logosian ring, 3 |
| Siren | `intelligence` | Sash of Insight | +1 INT | Sash of Wisdom, 3 |
| Grook | `faster_eq` | Circlet of the Wise | 7% faster equilibrium (x0.93) | Aldar Diadem, 2 |
| Tash'la | `reserves` | Atavian Bracelets | +5% max health and mana | Logosian Bracelets, 3 |
| Dwarf | `constitution` | Girdle of the Titans | +1 CON | Girdle of Aegis, 3 |
| Tsol'aa | `mana_regen` | Crescent Moon | level 1 mana regeneration | Suremekh'neina, 3 |
| Rajamala | `dexterity` | Buckled Boots | +1 DEX | Pixie's Boots, 3 |
| Fayad | `mana_sip` | ring of Socresia | +10% mana elixir healing | ring of Lunastra, 3 |
| Troll | `strength` | Ogre Gauntlets | +1 STR | Logosian Gauntlets, 3 |
| Satyr | `health_regen` | Boar Tusk | level 1 health regeneration | Suremekh'neina, 3 |
| Mhun | `endurance_regen` | Ring of Tenacity | level 1 endurance regeneration | Band of Tenacity, 2 |
| Xoran | `magic_damage` | Collar of Ceylon | +10% magical damage | Collar of Agatheis, 3 |

### Horkval and Atavian (READ)
- **Horkval:** the racial leap recovers as fast as a LEAP with chitin greaves (`leap`).
- **Atavian:** the wings perform as a ring of flying (`flying`).
- **Wingless Atavian:** the benefit of a fishscale tunic, underwater breathing (`breathe_underwater`).
- We own all three items (chitin greaves, ring of flying, glittering fishscale tunic).

### Rules (READ)
- An owned artefact of the same power "applies with priority". The racial bonus does not add to it
  (`docs/artefacts-reference.md`: similar artefacts do not stack).
- Fixed at level 1. It cannot be upgraded; level 2 or 3 needs the artefact.
- Not for Dragon or Elemental Lord.
- Off in honourable duels, as artefacts are.
- A stat change can take up to 1 minute to show after login.
- When no equal or better power is owned, the bonus shows at the bottom of ARTEFACT POWER LIST OWNED.
- A refund for an L1 artefact (or Atavian ring, Horkval greaves) that the race now makes useless: ISSUE.

## Fight impact
- **Another player's timings.** A figure tagged ANOTHER PLAYER (CLAUDE.md, rule 5) now has a race
  floor. Example: a Grook spends at most x0.93 of a BASE equilibrium cost from 2026-11-24 on,
  even with no artefacts. Logs before 2026-11-24 do not have this. Our own factors are unchanged
  (`kb/mechanics/balance-and-queueing.md`, "Our speed factors").
- **Honourable duels** have no racial bonus and no artefacts: there BASE is the right figure, for both sides.
- **Damage and healing.** A Xoran's magic damage (+10%) and a Human's health sip (+10%) count
  in a damage-kill estimate of another player (`docs/my-artefacts.md`, "The damage-kill thresholds").
  No code models another player's artefacts today.

## Code
- `ataxia_eqFactor` (`033_Artefacts.lua`:227) and every other reader in 033 read only OUR list.
  Our list holds each of the 12 powers at level 2 or 3, so our factors do not change.
- **The racial row, captured (OURS, `kbcapture artefacts` 2026-11-24T23:21Z,
  `raw/live/artefact_power_list_owned.txt`).** It is the last row of the list, with `-` for the id:
  `-             Racial bonus                        health_sip             1`.
  The game shows it although we own `health_sip` at level 3. So the row appears for every
  player, and it is no proof that the bonus applies; the post says an owned equal or better
  power wins.
- `ataxia_parseArtefactPowerRow` (033:125-130) needs a numeric id, so it returns nil for this row
  (tested on the live profile, 2026-11-24), and the save said "Artefact powers saved: 74", not 75.
  For us that is right. For a player whose race power is not owned (a Grook with no faster_eq
  artefact), `ataxia_eqFactor` leaves out the racial x0.93: [CONFLICTS #85](../CONFLICTS.md).

## Conflicts
Open: [CONFLICTS #85](../CONFLICTS.md). Should the parser count the racial row when no owned
artefact has that power?
