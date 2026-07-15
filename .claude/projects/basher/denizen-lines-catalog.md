# Denizen combat-line catalog (Blademaster tower-climber)

Reference for the per-denizen combat-state layer (`basher/008_Denizen_State.lua`) and the smarter Blademaster battlerage rotation. Lines are grouped by what they tell us. `<mob>` = regex `(.+)`. **TODO-line** = we know the affliction/effect exists but haven't captured the exact game line yet — fill the `apply`/`ends` in `ataxiaBasher_BR_AFFS` + add a trigger when captured.

## Our attacks on denizens
| Line | Kind |
|---|---|
| `…draw Blazing Flames from its scabbard and unleash a vicious slash towards <mob>` | main-hand |
| `Lashing out with a clenched fist, you aim a precise strike at <mob>` | off-hand |
| `Your vicious attack cleaves to a nearby enemy.` | **cleave** (AoE splash) |
| `You twist in a tight circle, slashing <mob> with each spin.` | **Spinslash** (36r/23s) |
| `You swing the culling blade in a great arc, black energy leaping from the blade.` / `The energy rips into <mob> in a detonation of power.` | **Culling Blade** (AoE reap) |
| `A storm of deadly leaves descends… viciously shredding all…` | leaves tattoo (AoE) |
| `A Shin-enhanced leap flings you high into the air… squarely striking <mob>…` | **Leapstrike** (14r/16s) |
| `Time wreaks ruin upon <mob>, deteriorating before your eyes.` | psychic DoT proc |
| `Flames engulf <mob>, scorching him in a fiery blaze.` | **Infuse Fire** proc → sets **ablaze**; extra dmg if already ablaze |
| `<mob>'s form begins to atrophy as your attack kindles ethereal mist…` | atrophy proc |
| `You raze <mob>'s magical shield with Blazing Flames.` | shield raze |
| `Damage dealt: N (type).` | damage (captured by `350_Damage_Dealt`) |
| `You have slain <mob>, retrieving the corpse.` | kill (`340_Slain`) |

## Blademaster battlerage abilities (rage) — from AB ATTAINMENT
| Ability | Command | Rage | CD | Type | Exploits |
|---|---|---|---|---|---|
| Leapstrike | `LEAPSTRIKE <t>` | 14 | 16s | damage/execute | — |
| Shatter | `SHIN SHATTER <t>` | 17 | ~global | shield-break | shielded |
| Nerveslash | `NERVESLASH <t>` | 22 | 31s | afflict **Weakness** | — |
| Headstrike | `STRIKE <t> HEAD` | 25 | 23s | **conditional dmg** | **reckless / feared** |
| Daze | `SHIN DAZE <t>` | 26 | 33s | afflict **Stun** | — |
| Spinslash | `SPINSLASH <t>` | 36 | 23s | damage dump | — |
| Provoke | `PROVOKE <t>` | 32 | 20s | taunt (mob→you) | — (costs 2.5s bal/eq) |

Our battlerage resource/cooldown lines: `You can use <Ability> again.` (ready), `Your <Ability> ability could be used again but you lack the necessary Rage.` (ready + rage-gated), `The surge of terrible rage leaves you.` (rage faded).

Shin-energy (TwoArts/Shindo, distinct resource): `INFUSE FIRE` (5 Shin, blade fire enchant + ablaze), `SHIN HEALTHTRANS <amt>` / `SHIN MANATRANS <amt>` (burn Shin → health/mana; use ~10, not `ALL`).

## Denizen afflictions / states

The first 10 rows are the battlerage afflictions in the data-driven `ataxiaBasher_BR_AFFS` spec (each with a duration). The last three (**shielded**, **ablaze**, **confused**) are **not** in `BR_AFFS` — they're tracked as no-duration states in the same `denizenState[id].affs` table (cleared by an explicit line, not a timer).
| State | Dur | Source(s) | exploitedBy | apply line | ends line |
|---|---|---|---|---|---|
| **charm** | 5s | Wayward Heir proc / BR | swap (keep alive) | `Your foe's eyes glaze over as they stay their hand against you, their wrath slowly shifting toward others nearby.` | `With a snarl, <mob> forces clarity back into their mind and turns their wrath upon you once more.` |
| **recklessness** | 15s | Haskor's Bravado / BR | **Headstrike** | `Your foe puffs up their chest and rushes headlong into danger.` (current target) | `Caution returns to <mob>.` |
| feared | 8s | BR | **Headstrike** | TODO-line | TODO-line |
| sensitivity | 8s | BR | **burst** | TODO-line | TODO-line |
| inhibit | 9s | BR | burst | TODO-line | TODO-line |
| **aeon** | 6s | Temporal Anomaly proc / BR | — (mitigation) | `Your foe blurs and begins to move slower in time.` (current target) | `<mob> returns to normal speed.` |
| weakness | 7s | Nerveslash / BR | — (mitigation) | TODO-line | TODO-line |
| stun | 4s | Daze / BR | — (mitigation) | `You hurl a precise blast of Shin energy at <mob>'s eyes.` (our Daze cast → stun; any-source mob-stunned line still TODO) | TODO-line |
| clumsy | 7s | BR | — (mitigation) | TODO-line | TODO-line |
| amnesia | (2-3 hits) | BR | — (mitigation) | TODO-line | TODO-line |
| **shielded** | — | mob | **Shatter** | `A nearly invisible magical shield forms around <mob>.` (`336_Mob_Shielded`) | raze / death |
| **ablaze** | — | Infuse Fire | fire (bonus, keep up) | `Flames engulf <mob>, scorching him in a fiery blaze.` | TODO-line |
| confused | — | proc | — (info) | `<mob> hesitates for a moment as a look of confusion flickers across their face.` / `Colour fractures into kaleidoscopic chaos across <mob>.` | TODO-line |

Affliction **resisted** (bosses): `<mob> sneers at your feeble attempt to afflict him.` — record only, don't set the aff.

**Proc-boons that afflict denizens** (Mnemosyne wade-status "Ongoing effects"): Wayward Heir / Child of Chaos (10% random BR aff — charm source), Haskor's Bravado (5% recklessness), Temporal Anomaly (5% aeon, once/5s). Afflictions are tracked from **any** source (our BR, boons, groupmates).

## Status capture stages
- **Stage 1 (done, v4.7.62):** `008_Denizen_State.lua` module + tests; lifecycle sync in `update_stuff/003`; HP feed in `010`; **charm** apply/end triggers (`011,012`). `ataxiaBasher_dsStatus()` dumps live state.
- **Stage 2 (done):** `ataxiaBasher_blademasterBattlerage` — Blademaster owns its battlerage (excluded from the shared culling check), spends rage by priority so it never idles (fixes the 100+-rage-unused bug), and cashes in a reckless/feared target with **Headstrike** for bonus damage. **recklessness** + **aeon** capture triggers (`013-016`). Isolated to Blademaster (no other class touched). Tests `test_basher_battlerage.lua`.
- Stage 3: charm-swap targeting. Stage 4: first-hit auto-parry. Remaining aff lines (feared/sensitivity/stun-on-mob/…) still TODO-line.
