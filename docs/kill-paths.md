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
| **SKULLBASH** | **CONFIRMED KILL** -- 8,556 unblockable | **PRONE *and* BROKEN HEAD, simultaneously** | he stops hitting a limb he has clearly prepped |
| ENSNARE -> RATTLE -> TRUSS | WIKI | prone -> transfixed -> unconscious | ENSNARE on a prone target |
| IMPALE -> WRENCH | WIKI | prone | IMPALE |
| EXTIRPATE | WIKI | petrified (basilisk form) | morph to basilisk |
| Affliction lock (soft/hard/venom/true) | **CONFIRMED** | venoms ride every attack | **anorexia landing** = one step from closing |
| Rift lock | WIKI | both arms out + anorexia | second arm being prepped |

**Everything except the lock is gated on PRONE**, and TRIP is how he gets it -- one action that
prones you *and* breaks the leg you would need to stand back up with.

**The lock's job is to make the two SKULLBASH conditions simultaneous and permanent.** Prone
cannot be stood out of (broken leg + weariness), the head cannot be restored (anorexia/slickness
block the salve). **Counter: break either leg of the conjunction -- restore the head, or stand.**
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

### Every other class -- **ASSUMED**

`.claude/classes/*.md` carry kill routes for all classes, but none has been verified against one
of our own logs. They are inherited documentation. When you fight one and survive with a log,
run the method above and promote the entry here.

Highest value to confirm next, by how often they kill us and how little we know:

| Class | Documented primary | Why it matters |
|---|---|---|
| Serpent | Ekanelia / voyria | fast, and our anti-Serpent handler is the most elaborate |
| Shaman | Tzantza | instant, and goldenseal-stack gated |
| Occultist | Wheel cheese | `combatQueue()` already has a hardcoded response to it |
| Pariah | Voyria kill | ditto |
| Monk/Tekura | Limb prep (backbreaker) | shares the limb machinery we just fixed for Sentinel (Shikudo is confirmed above) |

## What this file is not

It is **not** a strategy guide and not a substitute for the dossiers. It is an index plus a
confidence ledger, so that a wrong entry is visible as wrong rather than quietly authoritative.
