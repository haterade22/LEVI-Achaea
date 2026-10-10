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

**We don't know yet whether this breaks anything.** `systemDefup` builds its batched command from
the defup PROFILE's names, not from these values, while `supportedDefence` reads the table as
`csd, ssd`. Which path sends which name, and whether one bad name rejects a whole batched command,
still needs tracing (`kb/CONFLICTS.md`).
