---
topic: defences
confidence: CONFIRMED (live list); the mismatches below are unverified
sources:
  - kb/raw/live/def_all-defences_2026-10-10.txt
  - kb/raw/live/curing-priority-defence-list_normal_2026-10-10.txt
code:
  - src_new/scripts/_groups.yaml          # ataxiaTables.defences (client name -> server name)
  - src_new/scripts/levi_ataxia/levi/ataxia/deffing/002_Deffing_Up.lua   # systemDefup
last_verified: 2026-10-10
---

# Defences

Defences are the other half of curing. SSC keeps a defence up when it holds a
`CURING PRIORITY DEFENCE <name> <1-25>` (the game sets no default, see
[../curing/server-side-curing.md](../curing/server-side-curing.md)). Opponents strip defences,
and several curatives raise them (see [../curing/curatives.md](../curing/curatives.md)).

## The game's defence names (live, 279)

These are the server-side names the game listed on 2026-10-10. A few fight lines that were mixed
into the paste have been left out. Any name we send in `curing priority defence <name> ...` should
be one of these.

accursedresolve, acrobatics, affinity, agithtailegend, aiming, airpocket, alertness, alligatorlegend, amamaalierlegend, antiforce, arcaneshield, arctar, aria, arrowcatching, astralform, astronomy, auroragrace, avoid, balancing, barkskin, basking, battlesong, bedevilaura, belltattoo, blackboarlegend, blackwind, bladefire, blademastery, blessingofthegods, blindness, blocking, bloodquell, bloodscent, bloodshield, blunder, blur, boartattoo, bodyaugment, bodyblock, boostedregeneration, brains, bulk, chameleon, chargeshield, circling, circulate, clinging, cloak, cohesion, coldresist, consciousness, constitution, curseward, dawnhand, deafness, deathaura, deathsight, deflect, deliverance, demonarmour, demonfury, density, devilmark, devour, diamondskin, disassociate, disperse, distortedaura, dodging, dragonarmour, dragonbreath, dreyvoslegend, drunkensailor, durability, dustform, eaglelegend, earthshield, eavesdropping, electricresist, elementalpurity, elusiveness, embattled, encircling, enduranceblessing, endure, enhancedform, epitomise, evadeblock, evasion, extispicy, extrusion, eyes, faith, fangbarrier, fervour, firefly, fireresist, fireshroud, firstaid, flailingstaff, fleetness, freedom, frenzied, frostshield, fury, ghost, golgothagrace, greased, gripping, grookbubble, groundwatch, guidedstrike, guisecurse, harmony, haste, hawkstep, heads, heartsfury, heldbreath, heresy, hiding, hyperfocus, hypersense, hypersight, immunity, incandescence, indomitability, insomnia, inspiration, insufflate, insulation, ironform, ironwill, joints, kaiboost, kaitrance, karthweatherweaving, karthwisdom, knightsvigil, kola, laelegend, lament, lay, leechlogograph, levitating, lifebond, lifegiver, lifesteal, lifevision, lipreading, magicresist, maticlegend, megalithtattoo, mentalclarity, mercury, metawake, mindcloak, mindnet, mindseye, mindtelesense, mistral, moontattoo, morph, mosstattoo, mouths, nicatorlegend, nightsight, numbness, oxtattoo, pacing, painshift, panacea, phased, pinchblock, placement, poisonresist, potentiate, preachblessing, precision, prismatic, projectiles, promosurcoat, psibreakthrough, psicomprehend, psitranscend, psivanish, putrefaction, rebounding, reflections, reflexes, regeneration, resistance, retaliation, retribution, ruin, rupturesight, satiation, scales, scholasticism, scouting, seasonelegend, secondsight, secondskin, seleucarianinspiration, seleucarianmight, selfishness, setweapon, shadowveil, shield, shieldlogograph, shikudoform, shinbinding, shinclarity, shinperfection, shinrejoinder, shintrance, shipwarning, shroud, skysight, skywatch, slippery, softfocusing, songbird, soulbleedarmour, soulbleedcling, soulcage, speed, spinning, spinningstaff, spiritbonded, spiritwalk, splitmind, standingfirm, starburst, stealth, stonefist, stoneskin, strata, sulphur, susurrating, swiftcurse, sympathy, tekurastance, telesense, temperance, tempest, tempo, tentacles, thermalshield, thirdeye, tin, tongues, toughness, treewatch, tremorsense, truestare, tumors, tune, twoartsstance, unbowed, undeathvisage, unnamablepresence, vengeance, venomsacks, vigilance, vigour, viridian, vitality, ward, waterwalking, wavedance, weakvigour, weathering, weaving, wildgrowth, willpowerblessing, wisdomofages, wolflegend, xporb

## Satiation (Healing Metabolism)

`satiation` (in the list above) is raised by the Survival ability SATIATION alone. It is NOT a full
stomach, and it needs no food. Sources: AB 1390,
[../raw/ab/survival_satiation_1390.txt](../raw/ab/survival_satiation_1390.txt) (CONFIRMED: 4.00 s of
equilibrium, 100 mana), and the user's screen, 2026-10-26 (CONFIRMED):

```
+ ( def satiation ) +
You begin concentrating on efficient digestion.
...
- ( def satiation ) -
Your digestive efficiency returns to normal.
```

GMCP adds the defence with the activation line, before any eat. It is timed: about 11.3 s
(12:22:21.449 to 12:22:32.744, no food eaten). Whether eating in the window lengthens it is UNKNOWN.
The Mnemosyne boon Healing Metabolism ("health elixirs 50% more effective while you possess the
satiation defence") is what makes it worth casting; `ataxia_satiationTick`
(`misc_scripts/022_Horn_Of_Plenty.lua`) casts it below an HP threshold (v4.7.454).

## Our names that are not in this list

`ataxiaTables.defences` (inline in `_groups.yaml`) maps a client-side name to the SERVER-SIDE name
(CLAUDE.md, "Defence tables"). Checked against the list above, 9 of its 153 values are missing:

| Client name | Our server-side value | Game list has | Likely meaning |
|---|---|---|---|
| tune | `blade tune` | tune | A command, not a name |
| acrobatics | `acrobatics on` | acrobatics | A command, not a name |
| harrying | `dance harrying` | (absent) | A command; also not an SSC defence |
| avoid | `avoid ` (trailing space) | avoid | A typo |
| boostedregeneration | `boosting` | boostedregeneration | Wrong name |
| parrying | `parrying` | (absent) | Not an SSC defence |
| compoundmask | `compoundmask` | (absent) | Not an SSC defence |
| simultaneity | `simultaneity` | (absent) | Not an SSC defence |
| clarity | `clarity` | (absent) | Not an SSC defence |

**Traced: none of these values reaches SSC.** The table is MIXED: most values are server
names, but four are the commands that raise the defence (`blade tune`, `acrobatics on`,
`dance harrying`, `avoid <type>`). Every reader tries the client KEY first:
`supportedDefence` matches either side, and `ashow defs` checks `ataxia.defences[key] or
ataxia.defences[value]`. `systemDefup` builds its `curing priority defence ... 25` command from
the defup PROFILE's keys. So the values above are harmless.

**Tested 2026-10-10: one bad name does not sink the batch.** The defup command is ONE batched
command, and some keys our tables accept are not SSC defences (parrying, compoundmask,
simultaneity, clarity, harrying). `curing priority defence harrying 25 grookbubble 25` answered
"You may not set a priority for the 'harrying' defence." and still set grookbubble
(`kb/raw/live/defence-batch-test_2026-10-10.txt`). That refusal line is how to spot a bad name.
