# Sentinel

> **HOW TO READ THIS FILE.** Everything from **THE ABILITY MAP** down to **Open questions** is
> **CONFIRMED** -- derived from our own death log (`Sentinel.txt`, 2026-08-19, 123s) and
> cross-referenced against [Skirmishing](https://wiki.achaea.com/Skirmishing),
> [Woodlore](https://wiki.achaea.com/Woodlore) and
> [Metamorphosis](https://wiki.achaea.com/Metamorphosis). **Trust it.**
>
> Everything from **Kill Routes** downward is older inherited documentation, tagged **ASSUMED**.
> It has not been verified and at least one entry (eviscerate) is probably wrong. Where the two
> halves disagree, **the confirmed half wins.** See `docs/kill-paths.md` for the convention.

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Limb (depends on morph/companion)
- **Difficulty**: Medium
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Woodlore: Animal companion and tracking abilities
Metamorphosis: Shapeshifting into various forms
Skirmishing: Combat techniques with spear and traps
```

## Metamorph Forms
```yaml
# Sentinel-Exclusive Forms
jaguar:
  description: "Stealthy jungle cat"
  style: "Fast attacks, stealth"
  strength: "Speed, ambush capability"
  sentinel_only: true

basilisk:
  description: "Petrifying gaze serpent"
  style: "Gaze attacks, petrification"
  strength: "Crowd control, instant kill potential"
  shared: true
  notes: "Sentinel specializes in this differently than Druid"

# Shared Forms (with Druid)
wolf:
  description: "Pack predator"
  style: "Fast attacks, pack tactics"
  strength: "Speed, tracking"
  shared: true

bear:
  description: "Powerful predator"
  style: "High damage, resilience"
  strength: "Raw power, tankiness"
  shared: true

eagle:
  description: "Aerial predator"
  style: "Flight, aerial attacks"
  strength: "Mobility, vision"
  shared: true
```

## THE ABILITY MAP -- observed line -> real ability -> why he threw it

Cross-referenced from the 2026-08-19 Grulk log (`Sentinel.txt`, 123s) against
[Skirmishing](https://wiki.achaea.com/Skirmishing) and [Woodlore](https://wiki.achaea.com/Woodlore).
**Every line below was seen live.** This is the table to reach for first.

| Observed line | Ability | Bal | What it is FOR |
|---|---|---|---|
| `<X> cocks back <his> arm and throws a claw-etched handaxe... at your <limb>.` | **RETURNING** (`THROW HANDAXE AT`) | weapon speed | **The engine. 42 of 57 attacks.** 14.7% limb + venom, 745-1021 dmg. The axe RETURNS -- no pick-up cost. |
| `<X> swiftly sweeps your feet out from beneath you with a Stormspear before driving the point of the weapon into your <limb>.` | **TRIP** (`TRIP <t> LEFT/RIGHT [venom]`) | 2.75s | **PRONE + the limb break.** Only 483 dmg -- not a damage tool. **3 of 3 landed trips produced a LEVEL 2 break.** |
| `<X> savagely gouges into you with a Stormspear.` | **GOUGE** (`GOUGE <t> [limb] [venom]`) | var | **WEARINESS.** All 3 weariness windows in the fight opened on a gouge. Damage frequently absorbed -- he is not throwing it for damage. |
| `<X> viciously lacerates you with a Stormspear.` | **LACERATE** (`LACERATE <t> [limb] [venom]`) | var | **HAEMOPHILIA + max bleeding.** 2 of 2 gave haemophilia. Highest-damage spear hit (1,432). |
| `<X> lays open your flesh with an expert lateral slice...` **+** `Turning with the motion of <his> strike, <X> comes back around to slam the haft of <his> weapon into your temple.` | **DOUBLESTRIKE** -- **one ability, two messages** | var | **THE LOCK CLOSER.** 2 of 3 delivered **anorexia**; all 3 delivered **impatience** on the haft half. Both hard-lock components in one action -- in both cases the next prompt read `(Locks: soft, hard)`. |
| `Agony radiates out from the point of impact as <X> brings the haft of a Stormspear down upon your head with crushing force.` | **SKULLBASH** | 3.30s | **THE KILL. 8,556 unblockable.** Needs **PRONE *and* BROKEN HEAD, simultaneously** (confirmed). |
| `<X> thrusts <his> blade angrily towards you, but you dodge easily out of the way.` | **THRUST** | var | basic poke / filler |
| `The barbs on a Stormspear viciously tear into you.` | **BARBS** (crafted, attached) | -- | passive wound-severity rider on the spear |

**The weapon swapping is not fidgeting.** 14 spear wields / 11 handaxe wields, alternating: the
axe is the prep+venom engine, the spear is the utility kit. Each attack picks its weapon.

## THE ALGORITHM

Three tracks, concurrent, each feeding the others:

```
A  VENOM       default curare; deviate only to top up a missing lock component
B  LIMBS       14.7% per THROW, 4-7 hit runs per limb
C  COMPANIONS  free actions -- a second affliction stream you never get to contest
```

**A and B are the same action** -- 40 of the 44 limb hits we took carried a venom. He never
chooses between prepping a limb and pressuring your cures.

**Order of operations, as executed:**

1. **Starve the cure channel.** Curare is the default (24 of 44 hits). Every paralysis costs a
   full EAT balance -- 27 magnesium in 123s -- and the kelp/aurum queue (asthma, slickness,
   weariness, sensitivity, healthleech) sits behind it. **We ate zero herbs all fight.**
2. **Prep limbs on those same hits.** Free.
3. **Do NOT break early.** His first three breaks were all restored in ~4-5s. He stopped.
4. **Park prepped limbs at 1-hit-from-break.** Right leg parked **19s**, head parked **8s**.
5. **Disable the counter** -- GOUGE for weariness, which blocks our FITNESS.
6. **Close the lock** with DOUBLESTRIKE (anorexia + impatience together).
7. **Cash every parked limb inside the lock**, where no salve can be applied.
8. **TRIP for prone, then SKULLBASH** -- which needs **prone AND a broken head, together**.

**The lock is not a parallel win condition -- it is the mechanism that makes prone and
broken-head simultaneously uncurable.** That is its entire purpose in this class's plan.

## THE LOCK IS SELF-SEALING -- and it lives on ONE balance

**The whole plan is to not get soft- or true-locked.** Everything else is damage control.

Measured cure channels from the 2026-08-19 log -- **four of the five components cure on the same
contended EAT balance**, and paralysis alone saturates it:

| Component | Cured by, in this fight | Balance |
|---|---|---|
| paralysis | magnesium **x24** | **EAT** |
| slickness | magnesium x3 | **EAT** |
| asthma | aurum x3 -- *or* **FITNESS** | **EAT** / free |
| impatience | plumbum x2 | **EAT** |
| **anorexia** | realgar **SMOKE** x1, **FOCUS** x1 | **not eat** |

**27 magnesium and ZERO herbs in 123 seconds.** You cannot out-cure a Sentinel lock on the eat
balance; he re-applies curare faster than the queue drains.

**And each component protects the others:**

```
asthma      -> "Your lungs are much too constricted to smoke."  kills SMOKE
impatience  -> blocks FOCUS
              ...and SMOKE + FOCUS are the ONLY two cures for anorexia
weariness   -> blocks FITNESS, the only non-eat cure for asthma
paralysis   -> saturates the EAT balance the other three depend on
```

**That is what "true lock" actually means here: every non-eat escape channel closed.** It is not
five afflictions stacked, it is four gates shutting one door.

### What follows for play

1. **Act at TWO components, never three.** By three, the cheap outs are gone. The prompt now shows
   **`PRE-LOCK 2/3`** while it is still preventable, and **`SEALED(no smoke/focus)`** the moment
   asthma + impatience close both anorexia channels -- which can be true *before* any lock exists.
2. **ANOREXIA is the lever.** It is the only component never on the eat balance, and it is the one
   he holds back as the trigger. Lock attempt 1 in that log collapsed in **0.3 seconds** because
   anorexia went first.
3. **WEARINESS is the highest-value cure in the fight** -- it is the gate on FITNESS, and FITNESS
   is the only asthma cure that does not queue behind paralysis.

### The kelp stack, and the order to dig it out

He inflicts **five of the six kelp/aurum afflictions**: asthma, weariness, sensitivity,
healthleech, clumsiness. One eat removes ONE. That is deliberate -- it is the same design as the
paralysis spam, applied to a second queue.

`Algedonic.sentinelKelpDig()` digs in the order of **what each cure BUYS**, not severity:

| # | Aff | Why here |
|---|---|---|
| 1 | **weariness** | the only one that pays for itself -- unblocks FITNESS, which then clears asthma **off-balance**. One eat, two afflictions gone |
| 2 | **asthma** | prefer **FITNESS** (no eat balance at all). Asthma also blocks SMOKE, one of anorexia's two outs |
| 3 | **sensitivity** | measured **+33%** damage taken |
| 4 | **healthleech** | 16.5% of all damage taken in that fight, never cured once |
| 5 | **clumsiness** | 33% miss -- costs offence, not survival |

Fires at 2+ of the five, throttled to 1.5s, and echoes `KELP STACK n/5 - DIGGING <aff>` at 3+.

## The lock ladder: three attempts, not one

| # | Time | Reached | How it ended |
|---|---|---|---|
| 1 | 09:58:40.136 | **soft** | anorexia cured in **0.3s** |
| 2 | 09:59:35.990 | **soft + hard** | **our FITNESS fired 09:59:40.377** -- asthma purged, whole lock collapsed 0.2s later |
| 3 | 09:59:51.668 -> 09:59:55.789 | **soft -> hard -> venom -> TRUE** | held to death |

**Anorexia has only 3 windows in 123 seconds -- one per attempt.** He holds slike and plays it
last, via DOUBLESTRIKE. **Anorexia landing is the tell that the lock is one step from closing.**

**Weariness is the counter-counter and he uses it deliberately.** Only 3 windows, all from GOUGE:

```
09:58:22.275 -> 09:58:45.084
09:59:18.821 -> 09:59:20.233
09:59:47.771 -> END      7.2s after our fitness broke his lock,
                         and 1.3s BEFORE fitness came off cooldown
```

Our fitness succeeded twice, **both times with weariness down**. Attempt 3 worked because he
gouged weariness back on first and only then rebuilt the lock.

## The limb ledger: prep, park, break inside the lock

```
09:58:39.105  LEFT ARM BROKEN   -> restored 09:58:44.266   (5.2s)
09:59:00.219  RIGHT LEG BROKEN  -> restored 09:59:04.154   (3.9s)   [TRIP]
09:59:23.535  RIGHT LEG BROKEN  -> restored 09:59:27.860   (4.3s)   [TRIP]
09:59:39.527  RIGHT LEG PREPPED (1 hit)   <- HELD 19s
09:59:54.558  HEAD PREPPED (1 hit)        <- HELD 8s
09:59:55.789  *** TRUE LOCK ***
09:59:58.309  RIGHT LEG BROKEN + PRONE    <- TRIP, never restored
10:00:02.286  HEAD BROKEN                 <- THROW, never restored
10:00:03.686  SKULLBASH -- 8,556 unblockable -> dead
```

Restoration takes ~4s and heals ONE limb. **If a Sentinel stops hitting a limb he has clearly
prepped, he is not being slow -- he is waiting for the lock. That pause is the last warning.**

## Companions -- a third channel, actively rotated

Summoned at **3.00s equilibrium** each; **`ENRAGE <animal> <person>` costs no balance at all.**
He cycled them all fight: 19 lemming arrivals, 13 fox, 9 badger, 4 raven.

| Animal | Observed in log | Wiki-confirmed purpose |
|---|---|---|
| **Lemming** | 20 defence strips, 4 vertigo | `ENRAGE LEMMING` strips **SHIELD before REBOUNDING**, then a random defence. **Free.** Plus vertigo. |
| **Wolf** | 1,113 or **1,480** dmg; 3 howls | Damage; **the howl amplifies damage taken if you lack DEAFNESS** |
| **Butterfly** | stripped our **deafness** (09:58:18.9) and our **blindness** (09:58:29) | *"restoring their hearing"* -- **it is the ENABLER for the wolf howl and the raven** |
| **Raven** | 6 paranoia | *"dart in and out of an opponent's line of sight, instilling paranoia"* -- needs us not blind |
| **Badger** | 68-85 dmg; **6/6 gave addiction or nausea** | Wiki lists bleeding + asthma at 200+ bleed. **Log disagrees -- treat the log as primary, re-check the AB.** |
| **Fox** | 13 attacks, **zero damage lines** | *"if they are suffering from haemophilia, the bleeding she inflicts will be higher"* -- pure bleed amplifier |

**The butterfly combo is the elegant part and easy to miss:** it removes YOUR deafness and
blindness so the wolf howl and the raven both work. Against a Sentinel, deafness and blindness
are not comfort defences -- they are the counters to two of his companions, and he has a
dedicated animal for peeling them.

## SENSITIVITY = ~+33% damage taken (quantified)

Two independent sources in the same log:

| Source | Without `sen` | With `sen` | Delta |
|---|---|---|---|
| Wolf bite | 1,113 | 1,480 | **+33.0%** |
| Healthleech tick | 1,062 | 1,390 | **+30.9%** |

Cure sensitivity **before** healthleech when both are up -- it is the multiplier on everything.

## Metamorphosis: he has FITNESS too, and it is NOT our FITNESS

**`FITNESS` (Metamorphosis) -- 3.00s balance, purges asthma.** Available on Cheetah, Elephant,
Hydra, Hyena, Jaguar, Wolf, Wyvern. Grulk was in **jaguar** form all fight
(`Prowling like a jaguar, <X> enters from the <dir>.`), so he had it.

**Offensive consequence: an asthma-based lock on a Sentinel is expensive.** He purges it on a
3.00s balance with no meaningful cooldown -- you cannot build a soft lock the way you would on a
class without a self-purge. Go for the components he cannot purge.

**Do not confuse it with ours.** Blademaster's `fitness` (the one `ataxia_breakLock` sends)
measured a **~9.8s cooldown** in this log and is blocked by weariness. Same verb, different
ability, an order of magnitude apart in cost. See `.claude/classes/blademaster.md`.

## Kill paths available to Skirmishing

1. **SKULLBASH** -- prone + head. **This is what killed us.** 8,556 unblockable.
2. **ENSNARE -> RATTLE -> TRUSS** -- prone -> transfixed -> unconscious -> bound. Not attempted.
3. **IMPALE -> WRENCH** -- prone -> impaled -> "terrible internal damage". Not attempted.
4. **EXTIRPATE** -- shatter a petrified enemy (basilisk form). Not attempted.
5. **Affliction lock** -- soft/hard/venom/true, delivered by venoms riding every attack.
6. **RIFT LOCK** -- both arms out so you cannot outrift, plus anorexia so you cannot eat.

**Paths 1-3 are all gated on PRONE**, and TRIP/SHOVE are how he gets it. Note also **RIVE**
(2.25s) -- *"shatter an opponent's shield"* -- so between RIVE and a free `ENRAGE LEMMING`,
shielding a Sentinel is a losing trade twice over.

## Open questions -- do NOT guess these

- **`A savage light enters the eyes of <X>.`** -- 4 occurrences, every one immediately after a
  Stormspear hit. **BLOODSCENT (Metamorphosis) was proposed and TESTED against the log -- it does
  not fit.** Bloodscent triggers on *"striking a tumbling, bleeding target with a spear"*:

  | Condition | Result |
  |---|---|
  | spear | **PASS 4/4** -- gouge x2, doublestrike x1, trip x1 |
  | target tumbling | **FAIL 4/4** -- all four fired at 09:58:22 / :49 / 09:59:00 / :18; our first tumble was 09:59:24 |
  | target bleeding | inconclusive -- our prompt only renders `bld()` at 100+, and it read 0 each time |

  Remaining observation: **2 of the 4 are immediately preceded by `You look about yourself
  nervously.`** Still unidentified. **Needs an in-game `AB METAMORPHOSIS` / `AB SKIRMISHING`
  check, ideally with the third-person messages.**
- **Where healthleech came from.** Not the fox (no damage line; bleed amplifier only). Almost
  certainly a layered venom (**epseth**) -- `ENVENOM` explicitly *"layers venoms on weapons"*,
  which would also explain paralysis and healthleech arriving on one hit.
- **Badger discrepancy** -- see the table above.
- **Whether SKULLBASH needs a BROKEN head or merely prone.** Wiki states prone only. He had ~5s
  of prone before the head broke and did not fire, which suggests the break matters (damage
  scaling at minimum) -- but that is inference from two datapoints.
- **Confusion** (`You gasp as your fine-tuned reflexes disappear into a haze of confusion`, x3)
  never reaches our prompt as a token -- our tracker is not recording it.

## Kill Routes -- ASSUMED (legacy; see 'Kill paths available to Skirmishing' above)

> Everything below this line is inherited documentation that predates the 2026-08-19 log.
> The one CONFIRMED entry is SKULLBASH, immediately below.

### CONFIRMED KILL: SKULLBASH (Skirmishing, 3.30s -- needs PRONE **and** BROKEN HEAD)

**Source: live death log vs Grulk Stormwing, 2026-08-19 (`Sentinel.txt`, 2,819 lines).** This is
the only Sentinel kill this package has actually observed, and it is not eviscerate.

```
Agony radiates out from the point of impact as <X> brings the haft of a Stormspear
down upon your head with crushing force.
Health lost: 8556 (unblockable).
```

```yaml
type: execute
ability: SKULLBASH
confirmed: 2026-08-19
prerequisites:
  - PRONE  **and**  HEAD BROKEN -- BOTH, simultaneously (user-confirmed 2026-08-19)
damage: 8556 unblockable from 9817 HP -- one hit, ~57% of a 14,906 pool
notes: |
  UNBLOCKABLE. Paragon does not absorb it and it is not affected by resistances.
  It does NOT require the eviscerate limb set. A second SKULLBASH finished the
  remaining 560 HP three seconds later.

  THE CONJUNCTION IS THE WHOLE ENDGAME. Two conditions that are individually
  trivial to cure become a kill when they are made simultaneous and permanent:
    * TRIP supplies both halves at once -- it prones us AND breaks the leg, so the
      same action that sets prone also removes our ability to STAND out of it.
    * The affliction lock is what makes them stick. Prone cannot be stood out of
      (broken leg + weariness) and the head cannot be restored (anorexia and
      slickness block the salve). In the log the TRUE LOCK landed 09:59:55.789 --
      BEFORE the leg break (09:59:58) and before the head break (10:00:02).
    * Hence the parking: right leg held at 1-hit for 19s, head for 8s, both cashed
      only once the lock was up. Restoration is ~4s and heals ONE limb.
counter: |
  BREAK EITHER LEG OF THE CONJUNCTION -- restore the head, OR stand. You do not
  have to beat both.
  Cover the head once he starts on it (seven throws is ~25s of warning), and treat
  "head broken" as "do not go prone under any circumstance". `damagedhead` moved to
  curing priority 8 in v4.7.275; the alarm in Algedonic.AntiSentinel fires on the
  CONJUNCTION, because head-broken alone fires against every limb class and trains
  you to ignore it.
```

**This was NOT an attrition death.** Our HP sat between 9,800 and 14,900 for the whole 123
seconds; ~692 dps incoming was survivable. The head break is the entire kill condition.

### Primary Kill: Eviscerate (Skirmishing) -- **UNVERIFIED, POSSIBLY FICTIONAL**

> **WARNING (2026-08-19).** EVISCERATE does not appear anywhere in the current
> [Skirmishing](https://wiki.achaea.com/Skirmishing) ability list, and it was never attempted
> once in the 123-second death log. This section is inherited documentation of unknown
> provenance. **The confirmed kill is SKULLBASH** (see THE ABILITY MAP above). Treat everything
> below as ASSUMED until someone verifies it in game -- see `docs/kill-paths.md` for the
> confidence convention.

```yaml
type: limb
summary: Break limbs with spear, then eviscerate

prerequisites:
  - Both legs broken (level 2)
  - One arm broken (level 2)
  - Target prone

steps:
  1: "Use spear attacks to damage limbs"
  2: "Focus legs first, then arm"
  3: "Knock target prone"
  4: "EVISCERATE <target>"

required_limbs:
  left_leg: 2
  right_leg: 2
  left_arm: 2
```

### Alternative Kill: Petrify (Basilisk Form)
```yaml
type: execute
summary: Gaze attack to petrify target

prerequisites:
  - Must be in basilisk form
  - Target must meet petrification conditions

steps:
  1: "Morph into basilisk"
  2: "Use gaze attacks to build petrification"
  3: "When conditions met, PETRIFY <target>"
  4: "Target turns to stone (instant kill)"
```

### Alternative Kill: Animal Companion Pressure
```yaml
type: hybrid
summary: Use animal companion for affliction/damage pressure

steps:
  1: "Bond with animal companion (wolf, bear, etc.)"
  2: "Command companion attacks"
  3: "Apply afflictions through companion and self"
  4: "Work toward lock or damage kill"

notes: "Companion provides additional attack per round"
```

## Offensive Abilities -- ASSUMED

> Wiki-sourced list, largely unverified by us. The CONFIRMED ability behaviour is in THE ABILITY MAP above.
```yaml
# Woodlore
bond:
  skill: Woodlore
  balance: eq
  effect: "Bond with animal companion"
  syntax: "BOND <animal>"
  animals: [wolf, spider, bird, snake, etc.]

command:
  skill: Woodlore
  balance: free
  effect: "Command companion"
  syntax: "ORDER <companion> <command>"
  notes: "Free balance"

track:
  skill: Woodlore
  balance: eq
  effect: "Track target"
  syntax: "TRACK <target>"

# Metamorphosis
morph:
  skill: Metamorphosis
  balance: eq
  effect: "Transform into a form"
  syntax: "MORPH <form>"
  forms: [jaguar, basilisk, wolf, bear, eagle]

attack:
  skill: Metamorphosis
  balance: bal
  effect: "Attack in current morph form"
  syntax: "ATTACK <target>"

# Skirmishing
spear:
  skill: Skirmishing
  balance: bal
  effect: "Spear attack with venom"
  syntax: "SPEAR <target> <venom>"
  notes: "Can apply venoms"

impale:
  skill: Skirmishing
  balance: bal
  effect: "Impale target with spear"
  syntax: "IMPALE <target>"

eviscerate:
  skill: Skirmishing
  balance: bal
  effect: "Instant kill when limbs broken"
  syntax: "EVISCERATE <target>"
  notes: "Requires broken limbs + prone"

trap:
  skill: Skirmishing
  balance: eq
  effect: "Set traps"
  syntax: "SET TRAP"
```

## Defensive Abilities -- ASSUMED

> **ASSUMED.** Note the `fitness` entry below is the METAMORPHOSIS one (3.00s balance, purges asthma) -- not ours.
```yaml
fitness:
  skill: Metamorphosis
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

morph_defenses:
  skill: Metamorphosis
  effect: "Various defenses based on form"
  notes: "Bear has resilience, eagle has flight, etc."

companion_alert:
  skill: Woodlore
  effect: "Companion alerts to danger"
  notes: "Some companions provide warning abilities"
```

## Passive Cures -- ASSUMED

> **ASSUMED.** Metamorphosis FITNESS is 3.00s balance, not passive-on-gain as written.
```yaml
fitness:
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Passive, automatic on asthma gain"
```

## Limb Strategy -- ASSUMED

> **ASSUMED, and probably wrong** -- it describes the unverified eviscerate route. The confirmed limb plan is the limb ledger above.
```yaml
enabled: true
target_order: [left_leg, right_leg, left_arm]  # for eviscerate
break_requirements:
  left_leg: 2
  right_leg: 2
  left_arm: 2
finisher: "EVISCERATE <target>"
```

## Bashing (PvE) -- ASSUMED

> **ASSUMED.** Never observed.
```yaml
attack_command: "SPEAR <target>" or "ATTACK <target>" in morph
attack_skill: Skirmishing/Metamorphosis
battlerage_abilities:
  - spear: "Basic damage"
  - companion_attack: "Companion damage"
```

## Fighting Against This Class -- ASSUMED

> **Superseded** by the confirmed counter-play above; kept for the strategy notes.
```yaml
priority_cures:
  - weariness: "Restores your Fitness"
  - broken_limbs: "Prevent eviscerate setup"
  - entanglement: "WRITHE out of traps"
  - petrification: "Cure before full petrify"
  - venoms: "Spear can apply venoms"

dangerous_abilities:
  - eviscerate: "Instant kill when limbs broken"
  - petrify: "Basilisk instant kill"
  - companion: "Additional attacks"
  - traps: "Room-based hazards"

avoid:
  - "Getting limbs broken for eviscerate"
  - "Standing on traps"
  - "Ignoring companion"
  - "Letting petrification build (basilisk)"

recommended_strategy: |
  Parry the limb he is CURRENTLY on -- he runs 4-7 hits per limb before switching.
  Cover the HEAD the moment he starts on it: SKULLBASH is the kill, and it needs prone TOO --
  so if your head is broken, do not go prone; if you are prone, do not let the head break.
  Cure WEARINESS first. It blocks Fitness, which is our lock-breaker.
  Cure SENSITIVITY before healthleech -- it amplifies every tick by ~31%.
  Do not build a plan on shielding: a lemming strips it in ~2 seconds, for free.
  Never fight him in a room with aggressive denizens.
```

## Fighting a Sentinel: what the 2026-08-19 death actually taught

**1. WEARINESS is the affliction that decides the fight.** It blocks Fitness -- and for
Blademaster, Druid, Infernal, Monk, Paladin, Runewarden, Sentinel and Serpent, `fitness` IS the
lock-breaker (`ataxia_breakLock`). Weariness up in 180 of 511 prompts, continuous for the last 19
seconds, cured twice in 123 seconds. `ataxia_canActive()` was false through the entire true lock.
Promoted to curing priority 6 in v4.7.275.

**2. He wins the eat balance and that is the whole plan.** Paralysis on nearly every spear hit
(24 cures, 27 magnesium) saturates the shared eat balance, and behind it sits a five-deep
kelp/aurum stack -- `asthma`, `clumsiness`, `sensitivity`, `weariness`, `healthleech`. **Zero herbs
were eaten in 123 seconds**; all 68 consumptions were minerals.

**3. Use the active cure BEFORE the lock closes.** The soft/hard/true lock is
asthma + slickness/bloodfire + anorexia (+ impatience + paralysis). Waiting for the completed triad
means reaching for the cure at the exact moment weariness has made it unusable. `ataxia_needPreLockCure`
(v4.7.275) fires at one component away.

**4. He kites.** Six stealthed re-entries (`Prowling like a jaguar`), and he hid in-room repeatedly
(`<X> is here, hidden.`). Note that a hidden player **still appears in `gmcp.Room.Players`** -- our
room scans printed `(1) person here: Grulk` every time, including while hidden. `ataxia.playersHere`
is not the reason an attack gets suppressed against a hiding Sentinel.

**5. Tumbling can be worse than standing.** The escape at 10:00:02 went into a dead end (`a
shimmering hatchery`, single exit southwest) and he walked in behind us. With weariness refusing
ten stand/tumble attempts, that room ended the fight.

## Implementation Notes -- ASSUMED

> **ASSUMED.** The confirmed trigger lines are in THE ABILITY MAP above.
```
Triggers to watch for:
- "morphs into a *" - form change
- "orders * to attack" - companion attacking
- "Your * is damaged/broken" - limb tracking
- "eviscerates you" - instant kill attempt
- "Your body stiffens" - petrification building
- Trap activation messages

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- Otherwise parse damage messages
- Companion presence via room items

Edge cases:
- Selarnia venom forces them out of morph
- Companion orders are FREE balance
- Traps persist until triggered
- Different morphs have very different abilities
- Petrification has buildup before instant kill
- Jaguar can enter stealth
```
