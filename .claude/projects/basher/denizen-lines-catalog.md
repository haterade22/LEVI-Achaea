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
| Nerveslash | `NSL <t>` | 22 | 31s | afflict **Weakness** | — |
| Headstrike | `STRIKE <t> HEAD` | 25 | 23s | **conditional dmg** | **reckless / feared** |
| Daze | `SHIN DAZE <t>` | 26 | 33s | afflict **Stun** | — |
| Spinslash | `SPINSLASH <t>` | 36 | 23s | damage dump | — |
| Provoke | `PROVOKE <t>` | 32 | 20s | taunt (mob→you) | — (costs 2.5s bal/eq) |

Our battlerage resource/cooldown lines: `You can use <Ability> again.` (ready), `Your <Ability> ability could be used again but you lack the necessary Rage.` (ready + rage-gated), `The surge of terrible rage leaves you.` (rage faded). The first two are the same event seen with and without rage to pay, and since v4.7.167 they are **consumed**, not just reference: trigger `328_Battlerage_Ready.lua` captures the ability name and `ataxiaBasher_brReady` (`basher/011_Battlerage_Ready_Lines.lua:91`) clears that verb's stamp in whichever owned rotation table holds it — an authoritative server cooldown in place of the send-side guess. Unknown verbs are ignored, so it is class-agnostic.

Shin-energy (TwoArts/Shindo, distinct resource): `INFUSE FIRE` (5 Shin, blade fire enchant + ablaze), `SHIN HEALTHTRANS <amt>` / `SHIN MANATRANS <amt>` (burn Shin → health/mana; use ~10, not `ALL`).

## Denizen afflictions / states

The first 10 rows are the battlerage afflictions in the data-driven `ataxiaBasher_BR_AFFS` spec (each with a duration). The last three (**shielded**, **ablaze**, **confused**) are **not** in `BR_AFFS` — they're tracked as no-duration states in the same `denizenState[id].affs` table (cleared by an explicit line, not a timer).
| State | Dur | Source(s) | exploitedBy | apply line | ends line |
|---|---|---|---|---|---|
| **charm** | 5s | Wayward Heir proc / BR | swap (keep alive) | `Your foe's eyes glaze over as they stay their hand against you, their wrath slowly shifting toward others nearby.` | `With a snarl, <mob> forces clarity back into their mind and turns their wrath upon you once more.` |
| **recklessness** | 15s | Haskor's Bravado / BR | **Headstrike** | `Your foe puffs up their chest and rushes headlong into danger.` (current target) | `Caution returns to <mob>.` |
| feared | 8s | BR | **Headstrike** | TODO-line | TODO-line |
| sensitivity | 8s | BR | **burst** | TODO-line | TODO-line |
| **inhibit** | 9s | Ripplestrike (Monk BR) / BR | burst | `You quickly strike <mob> with the tips of your fingers, targeting specific nerves.` (our Ripplestrike → current target, `023`) | TODO-line |
| **aeon** | 6s | Temporal Anomaly proc / BR | — (mitigation) | `Your foe blurs and begins to move slower in time.` (current target) | `<mob> returns to normal speed.` |
| weakness | 7s | Nerveslash / BR | — (mitigation) | `You lightly stab <mob> in several key locations with your blade, causing <them> to slump weakly.` (our Nerveslash cast → current target) | `<mob> stands up straight, having overcome the weakness that afflicted <him>.` |
| stun | 4s | Daze / Great Bard boon / BR | — (mitigation) | `You hurl a precise blast of Shin energy at <mob>'s eyes.` (our Daze → current target, `019`); `An echo of the Great Bard forms in the wake of your strike, ensnaring all presence with His stunning charisma.` (Mnemosyne boon proc → **AoE** stun on all denizens, `021`) | `<mob> is no longer stunned.` |
| **clumsy** | 7s | Scramble (Monk BR) / BR | — (mitigation) | `You rummage quickly through <mob>'s mind, finding the link to fine motor control before exerting a small amount of psychic force and deadening it.` (our Scramble → current target, `022`) | TODO-line |
| amnesia | (2-3 hits) | BR | — (mitigation) | TODO-line | TODO-line |
| **shielded** | — | mob | **Shatter** | `A nearly invisible magical shield forms around <mob>.` (`336_Mob_Shielded`) | raze / death |
| **ablaze** | — | Infuse Fire | fire (bonus, keep up) | `Flames engulf <mob>, scorching him in a fiery blaze.` | TODO-line |
| confused | — | proc | — (info) | `<mob> hesitates for a moment as a look of confusion flickers across their face.` / `Colour fractures into kaleidoscopic chaos across <mob>.` | TODO-line |

Affliction **resisted** (bosses): `<mob> sneers at your feeble attempt to afflict him.` — record only, don't set the aff.

**Proc-boons that afflict denizens** (Mnemosyne wade-status "Ongoing effects"): Wayward Heir / Child of Chaos (10% random BR aff — charm source), Haskor's Bravado (5% recklessness), Temporal Anomaly (5% aeon, once/5s). Afflictions are tracked from **any** source (our BR, boons, groupmates).

## Parry intel (SLC bashing mode)

**Parry-success line** (first-person, limb-bearing — confirmed from 2026-07-25 live log):
`You parry the assault to your <limb> with a deft maneouvre.` — the game spells it "man**eo**uvre" here, while the third-person PvP lines use "man**oe**uvre"; trigger `highlighting/027_Parry_Success` tolerates both, highlights bold spring_green, and feeds `ataxia_parrySuccess(limb)` (a parried swing prints NO perceive line, so this is the only signal the tracker gets while the parry is working).

**Per-mob parry entries** (`selfLimbDamage.denizenPatterns`, 005):
| Mob | Entry | Why (from logs) |
|---|---|---|
| an axe-wielding revenant | cycle: right leg x2 → left leg x2 → torso x2 | fixed swing rotation, two perceive lines per swing |
| a steel-encased Death Knight | **fixed: left leg** | knee-snap is the parryable attack (all observed parries = left leg); torso stomp / head slam / arm crush / throat slash are accepted (user-confirmed tactic) |
| a ravager of the Infernal Legion | **fixed: torso** | torso cleave is her only limb-targeted attack (perceive "dealt 30.0% damage to your torso" x2/swing); dive names no limb, shoulder-charge impale is unblockable |
| an unbound frost elemental | **fixed: torso** | ice-shard fist slam names the torso in both halves of the swing ("Shards of ice explode from ... as they slam into your torso with bone-chilling force." then "dealt 30.0% damage to your torso"); the frost-prickle / humour-tempering output targets no limb (2026-07-29) |
| an iron malagma | **fixed: right arm** | TWO arm attacks to one head attack, and broken arms *refuse* the Sword-and-Board swing outright — the arms gate the whole offence (2026-07-30) |
| an invar malagma | **fixed: right leg** | the shovel leg-shatter is its only limb-targeted attack; the shoulder-charge knockdown names no limb, so leg cover is free (2026-07-30) |

**Mine malagmae attack lines** (2026-07-30 Mnemosyne log, as abbreviated in the `005:53-70` comments — `...` marks elided text, either the mob-name position or an omitted middle; these are not full verbatim lines and are not safe to paste into a pattern):
| Line | Limb |
|---|---|
| `Grabbing a pick from the floor of the mine, ... embeds the rusted head into your arm.` | iron malagma — **arm** (side unnamed) |
| `Grabbing your arm in his vice-like hands, ... snaps the bone in two.` | iron malagma — **arm** (side unnamed) |
| `... swings a partially rotted wooden shaft at your head` | iron malagma — head |
| `... sweeps a shovel above the ground ... crashing into your leg and shattering the bone` | invar malagma — **leg** (side unnamed) |

Two things follow from these, and both are the reason the iron malagma is the highest-value
parry call in the tower. First, a broken pair of arms does not merely hurt: the game answers
the swing with `You cannot do that because both of your arms must be whole and unbound.`
(trigger `344_Broken_Arms.lua`), so the arms are the limbs gating our entire offence — the
battlerage in the same queued chain still rides, since collide/onslaught need no arms.
Second, `fixed` and not `cycle`: **neither arm line names a side**, so there is nothing to
phase a cycle against, and an unsynchronised cycle would guard the wrong arm half the time.
Covering one arm permanently halves the rate at which *both* end up broken, which is the
state that actually matters. Level-1 breaks come in from these fast — ~25 `Your <limb>
breaks with a loud crack.` in 90 seconds in that log (trigger `038_Limb_Broken_L1.lua`).

**Audited, NO parryable attacks** (head default applies — don't re-audit):
| Mob | Attacks seen |
|---|---|
| an Infernal hellspawn | bone-appendage impale (physical cutting, no limb named, leaves IMPALED+prone); whirling flurry (**unblockable**); corpse explodes on death |
| a rotskull demon | miasmic breath / claw lurch / jaw bite — all poison-typed, no limb named (bite adds a cutting component + strips skin coating) |
| a mindless thrall | grasp/frenzy lines do no damage (disrupt focus/countermeasures); gnaw (physical cutting, no limb, applies haemophilia) |

**Open non-parry observations** (2026-07-25 log): Infernal Legion corpses explode for 2500 unblockable after the kill (basher/explorer currently just eats it); the hellspawn impale caused ~30 spammed `You are impaled and must writhe off before you may do that.` / `…both of your arms must be whole and unbound.` failure lines — something keeps re-sending commands while IMPALED. *Partly closed in v4.7.167:* the arms line now rolls back every owned rotation's in-flight replay instead of firing an unthrottled `diag` (trigger `344`), and its leg twin `Both of your legs must be free and unhindered to do that.` gained a handler (`345_Broken_Legs_Block.lua`) which also releases a `stand;leap <dir>` the explorer had in flight. The IMPALED re-send loop itself is still open.

## Our own pets turning on us

A mauled pet turns on its owner, and once flipped it keeps clawing every few seconds. Both
knight pets have been caught doing it live. The response is the same and it is **free**:
`ORDER <pet> PASSIVE` costs no balance and no equilibrium, so it can go out on any round,
including a gated one. Sent **directly, not queued** — the basher rebuilds its command every
prompt with `queue addclearfull`, which would wipe a queued recovery before it ran. 10s
debounce on each, so a burst of claw lines issues one order but a genuine re-engage is
answered again.

| Line | Pet | Trigger |
|---|---|---|
| `A daemonic hyena snarls as she hurls herself at you,` | Infernal hyena | `372_Hyena_Turned_On_Us.lua` (2026-07-29) |
| `A razor-beaked falcon dives at you, raking your face with its talons.` | Runewarden falcon | `376_Falcon_Turned_On_Us.lua` (2026-07-30) |
| `A razor-beaked falcon rips out a chunk of your flesh with its beak.` | Runewarden falcon | `376_Falcon_Turned_On_Us.lua` (2026-07-30) |

All three patterns are **anchored on the second-person form on purpose**. Against a real foe
the same attacks read "...hurls herself at a royal guard...", "...dives at a revolting ghoul,
raking his face..." and "...rips out a chunk of a wraith's flesh...", which are the pet's
normal rake/maul lines and belong to the cooldown triggers (`367`, `370-371`). Only the
"...at you" / "your flesh" forms name US, so these cannot fire on a working pet. Note the
trailing `, ` in the hyena pattern — that comma is what separates "at you," from "at a royal
guard".

The two cases have different *causes*. The hyena flipped because "a daemonic hyena" was not
on `ataxiaBasher.ownDenizens` and the basher was attacking it (seen at 4% on the mob bar);
the keyword was added, and the trigger remains for a pet that has already flipped. `falcon`
was already on the list, so the falcon was never targeted by us — something else flipped it
(an AoE clipping it, or a tower effect). Same response either way.

## An earth wyrm (Mnemosyne) — captured 2026-07-31 from a death log

The denizen that motivated the PvE curing profile (v4.7.172). Its whole design is
resource-denial: it breaks **both limbs of a pair per bite**, impales, and sprays *cosmetic*
mental afflictions that a PvP-tuned curing table dutifully spends the eating balance on.

**Attacks**
```
Razor-sharp fangs and claws tear apart your flesh and bone as an earth wyrm latches onto you.
  -> ~1,900-3,350 physical cutting
  -> breaks BOTH arms or BOTH legs in the same hit
  -> applies "Your own shadow betrays you, leaving your thoughts scattered and wan."
     + one of the junk mental affs + "Your mind aches with a new malady." (unknown aff)

Chittering loudly, an earth wyrm rushes forward and slams his onyx-plated bulk into you.
  -> ~1,300-1,450 physical blunt

Stilling for a moment with his tri-horned skull raised, an earth wyrm drives forward in your
direction, impaling you in the stomach.
  -> ~1,380 physical cutting, applies IMPALED (writhe) + prone
  -> DoT: "Your health continues to drain away as your impaled body shudders on the end of
     the weapon." ~1,100 per tick
```

Two wyrms sustained **~1,600 HP/s**. Bites land ~2.5s apart, so limb breaks arrive at ~0.8/s
against a salve balance that cures ~1/s — **break-even at best**, and any salve spent on
cracked ribs puts you permanently behind.

**Affliction spray observed** (all cosmetic to a basher, all cost a mineral eat):
paranoia (x3), shyness, claustrophobia, depression, masochism, confusion, sensitivity,
retardation-family "Your mind is able to focus once again.", anorexia, hypochondria,
deafness-strip ("Your hearing is suddenly restored."), plus repeated unnamed maladies.

**Not yet captured as triggers.** Recorded here as intel; the counter shipped in v4.7.172 is
the curing profile, not per-line tracking.

## Status capture stages
- **Stage 1 (done, v4.7.62):** `008_Denizen_State.lua` module + tests; lifecycle sync in `update_stuff/003`; HP feed in `010`; **charm** apply/end triggers (`011,012`). `ataxiaBasher_dsStatus()` dumps live state.
- **Stage 2 (done):** `ataxiaBasher_blademasterBattlerage` — Blademaster owns its battlerage (excluded from the shared culling check), spends rage by priority so it never idles (fixes the 100+-rage-unused bug), and cashes in a reckless/feared target with **Headstrike** for bonus damage. **recklessness** + **aeon** capture triggers (`013-016`). Isolated to Blademaster (no other class touched). Tests `test_basher_battlerage.lua`.
- **Stage 2.1 (done, v4.7.65):** in-game verification confirmed Daze (Stun) already fires ~every 33s (its cooldown ceiling) under the Mnemosyne priority, so the rotation is unchanged. Added visibility: `ataxiaBasher_dsAlert(msg,colour)` highlights the triggering line + echoes a `(BR):` tag (toggle `ataxiaBasher.brAlerts`, default on), wired into charm/recklessness/aeon/weakness/stun applies. Captured **weakness** apply (`017`, Nerveslash cast) + end (`018`) and **stun** apply (`019`, Daze cast) + end (`020`).
- Stage 3: charm-swap targeting (remaining). **Stage 4 DONE (v4.7.109–111)**: first-hit auto-parry — see "Parry intel" above. Remaining aff lines (feared/sensitivity/clumsy/inhibit/amnesia/…) still TODO-line.
