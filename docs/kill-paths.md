# Enemy Kill Paths -- cross-class index

**Every class has one or more kill paths. This file is the index of what we actually know.**

The per-class dossiers live in `.claude/classes/<class>.md`. This page exists so you can answer
"what is this person trying to do to me, and what is the tell?" without reading a dossier.

## Confidence convention -- use it, it is the point of this file

| Tag | Meaning |
|---|---|
| **CONFIRMED** | Observed in one of our own combat logs, with timestamps. Cite the log. |
| **WIKI** | Documented on wiki.achaea.com / AB but never seen by us. Trustworthy but unverified in practice. |
| **ASSUMED** | Inherited from an older doc or inferred. **Treat as a hypothesis.** |

**Do not silently promote ASSUMED to CONFIRMED.** The Sentinel entry below was ASSUMED
("primary kill: eviscerate") for a long time and was wrong -- the class killed us with
SKULLBASH and never attempted eviscerate once.

## The method (how to derive a kill path from a log)

Worked end to end in `.claude/classes/sentinel.md`. The steps that actually produce answers:

1. **Parse the prompt, not the prose.** Our prompt carries the authoritative affliction token
   list. Note that it **wraps across two lines** when the block is long -- a naive parser silently
   drops exactly the late-fight, most-afflicted prompts. Decode tokens against
   `ataxia/008_Affliction_Colouring.lua`, never by guessing (`par` is **paranoia**; `PAR` is
   paralysis).
2. **Build first/last windows per affliction.** An affliction with only 2-3 windows across a long
   fight is a *deliberate play*, not chip damage. That is how the anorexia trigger and the
   weariness counter-counter were found.
3. **Attribute each affliction to its source line.** Print the raw lines between the previous
   prompt and the one where the token first appears.
4. **Tabulate every distinct enemy attack line and what follows it** within the same prompt
   window. This is what turns "he hit me a lot" into an ability table.
5. **Cross-reference the wiki** to get the real ability names. Expect to be wrong: three of our
   log inferences did not survive this step.
6. **Build the limb ledger** -- break time, restore time, delta. Restoration is ~4s and heals ONE
   limb; that number is the whole reason opponents park prepped limbs.
7. **Count what did NOT happen.** Consumption totals, cures per eat, outbound command counts.

## Index

### Sentinel -- **CONFIRMED** (2026-08-19, `Sentinel.txt`, death)

Full dossier: `.claude/classes/sentinel.md`

| Path | Status | Requirement | Tell |
|---|---|---|---|
| **SKULLBASH** | **CONFIRMED KILL** -- 8,556 unblockable | **PRONE** (AB: `kb/classes/sentinel.md`:349; head damage raises its damage, and the wording does not make a broken head a gate). In this log he had both, so it cannot separate them (`kb/CONFLICTS.md` #51) | he stops hitting a limb he has clearly prepped |
| ENSNARE -> RATTLE -> TRUSS | WIKI | prone -> transfixed -> unconscious | ENSNARE on a prone target |
| IMPALE -> WRENCH | WIKI | prone | IMPALE |
| EXTIRPATE | WIKI | petrified (basilisk form) | morph to basilisk |
| Affliction lock (soft/hard/venom/true) | **CONFIRMED** | venoms ride every attack | **anorexia landing** = one step from closing |
| Rift lock | WIKI | both arms out + anorexia | second arm being prepped |

**Everything except the lock is gated on PRONE**, and TRIP is how he gets it -- one action that
prones you *and* breaks the leg you would need to stand back up with.

**The lock's job is to keep the target prone with a damaged head.** Prone cannot be stood out of
(broken leg + weariness), the head cannot be restored (anorexia/slickness block the salve).
**Counter: stand first; restoring the head cuts the damage.** If AB's wording is complete, a restored
head alone does not stop the bash (`kb/CONFLICTS.md` #51).
**Counter priority: weariness** (it blocks FITNESS, our lock-breaker) > sensitivity (+33% damage
taken) > the prepped limb. **Do not shield** -- RIVE shatters it and `ENRAGE LEMMING` strips it
for free.

**Attacking one:** he has Metamorphosis `FITNESS` (3.00s balance, purges asthma) in every combat
form, so an asthma-based lock is expensive against him. Target components he cannot self-purge.

### Monk (Shikudo) -- **CONFIRMED** DISPATCH (2026-10-11, a SHARED log, not our own fight)

Log: `kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt` (the monk's own view).
Every line, both views: `kb/combat/shikudo.md`. Dossier: `.claude/classes/monk.md`.

| Path | Status | Requirement | Tell |
|---|---|---|---|
| **DISPATCH** | **CONFIRMED KILL** (13:25, 86 s in) | prone + damaged head + crushed throat | a SWEEP, then FLASHHEEL breaking a leg every round (you spend your turns mending and never stand), then NEEDLE |
| CRESCENT (Maelstrom kick) | WIKI | prone + 50% health or less | he ASSESSes you after every combo ("You glance over...") |
| MIND SCYTHE | WIKI | mangled head + two of stupidity, impatience, dizziness, epilepsy, confusion | Telepathy afflictions on top of head damage |
| Affliction lock | CONFIRMED (the pieces) | MIND IMPATIENCE and MIND PARALYSE between combos; livestrike asthma, ruku slickness, hiraku anorexia | Not captured from the victim's side (the monk sees "You fill the mind of <T> with an impatient feeling.") |

**The fight's shape:** Gaital (dawnkick, kuro for weariness/lethargy, flashheel to break a leg),
Rain (frontkick for prone, kuro, ruku for clumsiness/healthleech), Oak (nervestrike, livestrike,
risingkick), Willow (hiru, hiraku, SHATTER for the shield tattoo, MIND IMPATIENCE and PARALYSE),
then Rain and Oak again, Gaital at kata 13, Rain at kata 10, and last ADOPT GAITAL FORM from Rain at
kata 0 (4.1 s of balance) for the Dispatch combos (sweep, flashheel, needle, jinzuku). A TRANSITION
needs a kata of at least 5, and only to a form on the current form's list; ADOPT needs no kata but
costs balance.

**Blackout** (the user, 2026-10-11: a CRITICAL affliction; the victim usually touches the tree to
cure it, he gives it again, and under it you cannot see what he does to you). The game's record: it
lasts 4 s and "obscures your prompt and prevents you from seeing many things happening". In log 2 the
victim's own drink, eat and tree lines vanished, while her balance, cooldown, stun-end and
elixir-effect lines, and the monk eating, still printed. Mystor: blackout, then one combo, and the
combo is hidden, so a blackout is the tell that a combo you cannot see is coming. In log 2 the
blackout landed WITH a combo whose first two strikes were visible, so it came with the combo, not
before it.

### Runewarden (sword and board) -- **CONFIRMED** DISEMBOWEL (2026-10-11, a SHARED log)

Log: `kb/raw/logs/2026-10-11_runewarden-snb-vs-shikudo_defender.txt` (the Runewarden's view),
and the same Runewarden losing in the Shikudo log above. Write-up: `kb/combat/runewarden-snb.md`.

| Path | Status | Requirement | Tell |
|---|---|---|---|
| **IMPALE -> DISEMBOWEL** | **CONFIRMED KILL** | torso past 100% | slices to the torso every round; RAZE strips your shield and rebounding first |
| Paralysis pressure | **CONFIRMED** | the shield strike "...smash into your spine." gives paralysis | seen 20 times in 86 s; a venom rides every slice |

**Her Dagaz rune cures her afflictions on a timer** while she stands on it.

### Four classes from Mystor's six arena fights (2026-10-11, SHARED logs, the Shikudo's view)

Logs: `kb/raw/logs/2026-10-11_mystor_*`. Write-ups, with line numbers: `kb/combat/fights/`. Five of the
six had MIND SAPIENCE on the opponent, so his own commands are known, not guessed.

| Class | Path | Status | Requirement | Tell |
|---|---|---|---|---|
| **Shaman** | truelock, then **BEHEAD** with a scimitar | **CONFIRMED KILL** | asthma, anorexia, slickness, impatience and paralysis (weariness first, which blocks FITNESS). The victim was NOT prone | the scimitar is drawn only for the kill; about 10 s from the swing to death. A probable TZANTZA at four afflictions did not kill (six are needed) |
| **Depthswalker** | **SHADOW DICTATE** | **CONFIRMED KILL** | mana below 40%, plus 5% per amplifier (depression, madness, retribution, parasite) | the depression capstone line, the leach capstone ("shadow claimed"), then one packet that wields the dagger and sends INTONE TOOROS before DICTATE. Recklessness made the prompt read full health and mana while it was lethal. One uncured timeloop doubled 8 instills |
| Infernal (two scimitars, DSL) | VIVISECT | CONFIRMED (tried 5 times, never landed) | all four limbs broken | "<T> reaches out for your chest but his hand stops short of it." is the refused attempt. Epteth/epseth break the LEFT limb first; DEATHAURA 547 every 7 s; TORMENT's healthleech 506 |
| Apostate | DEADEYES pressure | CONFIRMED (pressure; no kill in these logs, a VIVISECT kill is below) | paralysis about every 2.3 s from DEADEYES affliction pairs, with loyals and the daegger | `touch mercy / order loyals / truestare / deadeyes <t> <aff> <aff>` every round; Syphon every 12 s |

### Twenty fights filed 2026-11-01 (SHARED logs, all 1v1)

Logs: `kb/raw/logs/2026-11-01_*` (ids below). The model behind these: `kb/mechanics/foundations.md`.
Warnings are seconds from the first sign to the kill. All are MEASURED from prompt stamps unless marked, and
a margin under 0.5 s is unresolved. Classes are readings of the logs, not game records.

| Class | Path | Status | Conditions, in order | Earliest tell, warning |
|---|---|---|---|---|
| **Serpent** | truelock, then poison | **CONFIRMED KILL** x2 (`azbErKcK`, `Z5cyffxx`), plus a win against one (`X8pRorzR`) | paralysis, asthma + weariness (DSTAB), slickness + anorexia, impatience (monkshood reaction or hypochondria chain), then IMPULSE + BITE scytherus; "You scream out in agony" costs 994-1362 a tick (X, Z5). **No EXECUTE or BEHEAD in 4 Serpent logs** | "A terrible sense of unease": 18.7 s to truelock (Z5, n=1). Asthma + weariness: 24.5 s to death (az) |
| **Pariah** (Talo) | LATENCY, then voyria | **CONFIRMED KILL** x2 (`Vr.NkCGD`, `WKuEakBZ`), same order | 3 of 5 plagues (Sting, or an Infest relapse with no attacker line), burrowed swarm, "imperiously snaps" (READ: Latency, immunity blocked 13 s), Scorpion, Serpent (voyria + paralysis), 5 ACCELERATE. No immunity sip was tried, so the block is untested | "undulating" Infest: about 20 s (precision 3 of 8). Third plague: 13.4 s. Latency: at least 11.7 s |
| **Pariah** (Reyl) | SCOURGE | **CONFIRMED KILL** (`4c_SeyaA`) | thinned blood, haemophilia, pyramides, 200 bleeding; "decisively snaps" | Scorpion: 4.24 s. Failed snaps show the fishing (rows 791, 2921) |
| **Air Lord** (Talo) | pressure counter, CLAP at 6 | **CONFIRMED KILL** n=1 (`s98kPGv6`) at 90% health | gain = 1 + manaleech and deadening held (fit 6 of 6); pear removes one and spends the LUNGS, which the wind afflictions also need | pressure(3): 53.8 s. pressure(6): 1.69 s |
| **Runewarden, two handed** (Blonk) | sweep, IMPALE, 2700 unblockable | **CONFIRMED KILL** (`CxxKSMq`) | prone, right leg level 2, impale. INFERRED, n=1: tumbling while impaled caused the 2700; no writhe was sent | bastard sword drawn: 18 s. Sweep: 10.8 s |
| **Apostate** (Pharaus) | truelock, sleep, ankheg trample, VIVISECT | **CONFIRMED KILL** (`2026-11-01_..._LcJC-rJ5`) | truelock, sleep, two tramples, four limbs | softlock: 21.2 s. Asthma + weariness: 16.8 s |
| **Blademaster** (Alyzar) | leg breaks, then "Planting his foot" rounds | **CONFIRMED KILL** (`OwkA-G99`). Class from ability lines; INFERRED BALANCESLASH, which `.claude/classes/blademaster.md`:814 says is never used | legslash breaks a leg, knees prone, right leg breaks, six rounds at 1.37-1.64 s, 1326 cold each | left leg 72.6% with right 59.4%: 6.9 s to first break. "Planting" with legs broken: 7.75 s |
| **Sentinel** (Vothaec) | truelock at any health; TRIP + impale | CONFIRMED pieces (`JDvzR7j7`, `uW_VbgR`); the JD kill was guards | asthma + slickness by axe, anorexia + impatience by one doublestrike, paralysis, in 19 s, at 203% health (uW) | doublestrike: 2.63 s to truelock |
| **Depthswalker** (Nikita) | DICTATE; Degeneration capstone; truelock + symptoms | **CONFIRMED KILL** x3 (`L8LSw7xD`, `kAQnlFAW`, `X8pRorzR`) | Tooros + Mutilate drains mana (2868 to 1004 in one packet), shadow, shield down. L had no depression line, swapped away from the dagger, and Tooros was refused, yet DICTATE landed, so the tell above is not required | leach: 31.9 s. Mutilate: 2.9-3.8 s |
| **Monk (Shikudo)** (Elmer) | DISPATCH | **CONFIRMED KILL** x2 more (`2N1HTSWZ`, `3ys7NuHA`) | head parked one hit short, ADOPT GAITAL, sweep, flashheel, kick, needle. All conditions true for about 2.6 s. Restoration takes 4 s, so reacting to the last hit is too late | head parked and idle: 41-82 s. ADOPT: 14-20 s. Sweep: 9-13 s |
| **Depthswalker** (Akri + Kutcher, on us, group) | attune, leach strikes, shadow taken, phylactery strike | **CONFIRMED KILL** (`ours/2026-11-03_102138_Tabethys` rows 8749-9313). A group fight, so it is no route for a 1v1 rule | Attune 8.5 s before death; about 1,225 psychic per strike, each about every 2.1 s; `your shadow clings to the blade` 3.9 s and 2.2 s before; word of power (599), then `Drawing a shadow from a bone phylactery` for all that was left (2,845), about 33% health. The same strike failed on Antoninus just after his starburst. INFERRED: a kill below 40% (`classes/depthswalker.md`); the wiki says "significant" damage | Display-only alert since v4.7.476 (`SHADOW(name)` on the prompt). The wiki says the victim must be in their location, so leaving is a possible exit; no log shows it tried. EPITOMISE did not stop it. No shield in the last 30 s, so a shield is untested |
| Runewarden (Claes) | IMPALE, DISEMBOWEL; BISECT | **CONFIRMED KILL** (`WO7tC3kL`, `J7Xnr_Jg`) | torso parked at 94.6% for 108 s, leg built, then right leg, torso, impale, disembowel in 8.3 s. BISECT at 20% or less | torso parked: 8+ s |
| Blademaster (unnamed) | a staged finisher, INFERRED DEATHSTRIKE | seen once (`KtdftABt`, 1 s stamps) against a Tekura | Shin 100; no other prerequisite is visible; about 9 s of stages | not visible from the victim's side |
| Bard (Anzerloi) | crescendo | pressure only, lost twice (`kAQnlFAW`, `L8LSw7xD`) | 30 of 33 stage lines follow an EAT, and one stannum resets stages 2-6 to 1 (13 observations). `.claude/classes/bard.md`:66 says attacks build it | stage 6 |

**Blackout.** One Blademaster log shows about 7 s (`KtdftABt`, 1 s stamps), against the game's 4 s above. It may be
two applications.

### Every other class -- **ASSUMED**

`.claude/classes/*.md` carry kill routes for all classes, and most have not been verified against a
log. They are inherited documentation. When you fight one and survive with a log, run the method above
and promote the entry here.

Highest value to confirm next, by how often they kill us and how little we know:

| Class | Documented primary | Why it matters |
|---|---|---|
| Shaman | Tzantza | instant, and goldenseal-stack gated. Seen instead (above): a truelock, then BEHEAD |
| Occultist | Wheel cheese | `combatQueue()` already has a hardcoded response to it |
| Monk/Tekura | Limb prep (backbreaker) | shares the limb machinery we just fixed for Sentinel (Shikudo is confirmed above) |

## What this file is not

It is **not** a strategy guide and not a substitute for the dossiers. It is an index plus a
confidence ledger, so that a wrong entry is visible as wrong rather than quietly authoritative.
