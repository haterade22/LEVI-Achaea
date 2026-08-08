# Bard

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction | Damage
- **Difficulty**: Medium
- **Lock Affliction**: Voyria (blocks immunity elixir sip)

## Skills
```
Composition: Song-based abilities and harmonics
Bladedance: Combat dancing with rapier
Sagas: Storytelling abilities and effects (default)
  -OR-
Woe: Alternative Cyrene-exclusive skill
```

## Specializations
```yaml
Sagas:
  description: "Default storytelling abilities"
  style: "Narrative-based combat effects"
  unlock: "Default for most bards"

Woe:
  description: "Cyrene-exclusive variant"
  style: "Alternative to Sagas"
  unlock: "Cyrene city exclusive"
```

## Kill Routes

> Implemented in `bard/001_LeviBard.lua` via `bard.dispatchOne()` / `bard.dispatchTwo()`
> (backward-compat globals `levibardone()` / `levibardtwo()`). There is NO "resonance"
> mechanic anywhere in the offense code — the routes below are what the dispatch chain
> actually does with rapier `blade <move>` attacks.

### Primary Kill: Limb-Prep Sunrise / Sunset
```yaml
type: limb
summary: Prep all four limb groups with rapier hits, then fire sunrise/sunset

prerequisites:
  - head + arm + torso + leg all "prepped" (bard.calcPreps: hits + rapierdamage >= 100)
  - rapierdamage = ataxiaTables.limbData.bardRapier

steps:
  1: "Progressive limb prep — highsun (head/arm), jab (torso), heelsnap (legs)"
  2: "Each blade move also delivers a refrain (see selectRefrain priority table)"
  3: "Once head+arm+torso+leg prepped: 'blade sunrise <target> <left|right> <refrain>'"
  4: "bardsunset flag routes to 'blade sunset <target> <side>' (envenom-fang variant)"

notes: "dispatchOne owns the sunrise kill chain; dispatchTwo is tempo-gated sunset."
```

### Alternative Kill: Crescendo / Finale Burst
```yaml
type: damage
summary: Build crescendo, then trigger finale for the burst kill

prerequisites:
  - tAffs.crescendo built on target (crescendo is a Bard aff, cured by ash)
  - bladefinale flag set (finale is ready)

steps:
  1: "Attacks build crescendo (tracked via tAffs.crescendo)"
  2: "When bladefinale == true, dispatchOne fires 'blade flick <target>;finale <target>'"
  3: "dispatchTwo fires 'finale <target>' directly"

notes: "combatEcho shows [CRES:n] while building, [FINALE] when bladefinale set."
```

### Alternative Kill: Affliction Lock
```yaml
type: affliction
summary: Deliver refrains via blade moves to stack afflictions toward a lock

steps:
  1: "Each blade move carries a refrain from the priority table (selectRefrain)"
  2: "Use bladedance venoms for additional pressure"
  3: "Stack toward true lock"
  4: "Apply voyria to block immunity sip"
  5: "Damage to death through lock"

required_afflictions:
  - asthma: "blocks smoking"
  - anorexia: "blocks eating"
  - slickness: "blocks applying"
  - paralysis: "blocks tree"
  - impatience: "blocks focus"
  - voyria: "blocks immunity elixir (class-specific)"
```

## Offensive Abilities

The offense uses a single command family — `blade <move> <target> [<limb>] <refrain>` — plus
`finale <target>`. There is no SING/TUNE/SLASH/THRUST/RIPOSTE/RECITE in the code.

```yaml
# Bladedance — the one attack family (bard/001_LeviBard.lua)
blade:
  skill: Bladedance
  balance: bal
  effect: "Rapier strike; also delivers a refrain and preps a limb"
  syntax: "blade <move> <target> [<limb>] <refrain>"
  moves:
    - highsun: "head / arm prep"
    - jab: "torso prep"
    - heelsnap: "leg prep"
    - flick: "refrain delivery / crescendo build (default PvE attack)"
    - punctuate: "shield/rebounding bypass (used when target shielded or rebounding)"
    - sunset: "limb finisher (bardsunset routes to envenom-fang jab variant)"
    - sunrise: "kill finisher once head+arm+torso+leg prepped"

finale:
  skill: Composition
  effect: "Crescendo burst kill"
  syntax: "finale <target>"
  gate: "fires when bladefinale flag is set (tAffs.crescendo built)"

# Refrain -> affliction priority table (selectRefrain, REFRAIN_AFFS)
# First entry whose aff the target LACKS is chosen; fallback = paean.
refrains:
  - paean: paralysis
  - ode: asthma
  - ghazal: slickness
  - elegy: lethargy
  - prosodion: sensitivity
  - bhajan: dizziness
  - gusheh: addiction
  fallback: paean

# Dispatch / commands (bard/001_LeviBard.lua)
dispatch:
  entry_points:
    - "bard.dispatchOne()  (alias/global: levibardone) — sunrise kill route"
    - "bard.dispatchTwo()  (alias/global: levibardtwo) — tempo-gated sunset route"
  offense_aliases:
    - bardstatus: "status display (preps, tempo, crescendo, refrain)"
    - bardreset: "reset dispatch state + bare globals"
    - barddebug: "toggle bard.config.debug echo"
    - bardecho: "toggle bard.config.echoStrategy per-attack echo"

# Rebounding / shield counter
punctuate_gate:
  effect: "Both dispatchers switch to 'blade punctuate <target> <refrain>' when the target has shield or rebounding — punctuate bypasses rebound (bard.hasShield()/bard.hasRebounding())"

# Bardflick gate
bardflick:
  effect: "Each dispatch sets global bardflick via checkAffList(FLICK_AFF_LIST, FLICK_AFF_THRESHOLD): true when target has >=3 of the 14-aff FLICK_AFF_LIST"

# Sunset envenom mechanic
sunset_envenom:
  effect: "When bardsunset set, dispatchOne wields a fang, envenoms with slike, and jabs (queues 'slike' into envenomList) instead of the lyre/rapier prefix"
```

**Tempo / footwork also drives PvP routing:** `bardtempo` (back/side), `bardtempostance`
(Adagio/Moderato/Allegro), and `bardtemposequence` select `sunset` vs `flick` inside
`dispatchTwo` — not just the bashing footwork loop (see Bashing).

**Symphony / harmonics:** when `ataxia.bardStuff.symphony` is set and `bardHarmsInRoom`, the
system wields the instrument and sends `play symphony`; missing harmonics trigger
`call harmonics` / `whistle for songbird`. Toggles live under `ataxia.bardStuff`
(`instrument`, `symphony`, etc.) — see `030_ATTACK.lua` and `010_Prompt_Running.lua`.

## Defensive Abilities
```yaml
fitness:
  skill: Bladedance
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

harmonic_shield:
  skill: Composition
  effect: "Song-based damage absorption"
  syntax: "SING HARMONY"
```

## Passive Cures
```yaml
fitness:
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Passive, automatic on asthma gain"
```

## Limb Strategy
```yaml
enabled: true
notes: "The PRIMARY kill route is limb-based. bard.calcPreps() marks a limb 'prepped' when
  hits + rapierdamage (ataxiaTables.limbData.bardRapier) >= 100. Prep head+arm+torso+leg,
  then 'blade sunrise' / 'blade sunset' finishes. Refrains ride along each blade move."
```

## Bashing (PvE)
```yaml
attack_command: "blade flick <target> nomos"   # default; 'blade punctuate <target> nomos' when the bashPunctuate toggle is on (psychic-resistant denizens); 'blade flick <target> paean' while the Warmarch boon is active
attack_skill: Bladedance
warmarch: "Mnemosyne 'Warmarch' boon makes the paean refrain hit denizens (+100% psychic). While bardWarmarch is set, flick becomes 'blade flick <target> paean'. Set on boon claim / seeing it in the BOONS list; cleared on Mnemosyne run start/end (triggers 001/009/010)."
mechanic:
  footwork_tempo: "The dance auto-cycles front -> side -> back -> loop as you attack. Tempo/stance sets attacks-per-position before you're carried onward: Adagio 4/4/3, Moderato 3/2/2, Allegro 2/1/1, none 5/2/1. Tracked by bardtempo/bardtempostance/bardtemposequence (tempo triggers)."
  back_bonus: "Bladedance attacks vs denizens deal BONUS DAMAGE from the back position (AB FOOTWORK). The bashing goal is to maximize back-position uptime."
battlerage: "ataxiaBasher_bardBattlerage() (basher/001). Priority: culling blade (reap, off cooldown + >=36 rage; Bard is excluded from the global culling check and owns it here) > charm 2nd denizen (2+ denizens, >=32 rage) > trill target (2+ denizens, >=28, off ~42s cd) > howlslash (>=36) > moulinet (>=14)."
lifecycle:
  bash_start: "basher_engaged() (genrunning/003) sets tempo (bashTempo) and calls ataxiaBasher_bardCompose() ONCE."
  compose: "ataxiaBasher_bardCompose() (basher/002) wields the lyre (required to perform), composes bashCompose, and arms the 15-min 'Bard Performance' timer. Compose is NOT done per attack, and only ever runs when not performing (bash start / timer expiry / 'not performing' trigger), so no 'performance end' is needed. Debounced to one compose per 2s."
  refresh: "The performance lasts 15 min. On timer expiry the Bard Performance timer (timers/004) re-runs ataxiaBasher_bardCompose(); disengage disables the timer so it never fires while idle. If it lapses early, the 'You can hardly manipulate a grand performance...' line (performance_tracking/005) also re-composes while bashing."
config:
  bashTempo: "ataxia.bardStuff.bashTempo (default 'moderato'). Sent as 'TEMPO <name>' at bash start. Alias: 'bashtempo <adagio|moderato|allegro|none>'. 'none' = unmanaged."
  bashCompose: "ataxia.bardStuff.bashCompose (default 'paean prelude scherzo sonata maqam') = paean song + prelude/scherzo(regen)/sonata(cleanse)/maqam(crit)."
  bashPunctuate: "ataxia.bardStuff.bashPunctuate (default false). Toggle with the 'bashpunctuate' alias; true -> attack becomes 'blade punctuate <target> nomos' for psychic-resistant denizens (002_Class_Bashing.lua:202)."
tempo_choice:
  moderato: "Best steady-state back share (2 of every 7 hits); default. First back attack at hit #6."
  allegro: "Reaches back fastest (hit #4) -> more back hits per kill on squishy denizens that die before Moderato ever reaches back."
```

## Bladedance dances (defences)
```yaml
# Confirmed from AB, 2026-08-06. All dances are DEFENCES: they appear in DEF and are raised
# with DANCE <name>. They are MUTUALLY EXCLUSIVE -- AB HAWKSTEP: "you can only dance one
# thing at a time, so the hawkstep is exclusive with the dance of the harrying, for example."
# Never put two of them in one keepup profile; the system would re-raise each in turn forever.
exclusivity: "one dance at a time -- raising any dance drops the current one"
dances:
  harrying:
    syntax: "DANCE HARRYING"
    cooldown: "2.50 seconds of balance"
    ab_effect: "Swift rapier blows keep the enemy pinned inside your encirclement. The blows typically do no real harm, but the threat of the point makes it hard for even a fleet foe to escape."
    abadmin_id: 3166
  hawkstep:
    syntax: "DANCE HAWKSTEP"
    cooldown: "2.50 seconds of balance"
    ab_effect: "Swift motion and exacting precision. While dancing it, attempts to hinder YOUR escape from a room (rites of piety and the like) are less likely to succeed."
    abadmin_id: 3193
  wavedance:
    syntax: "DANCE WAVEDANCE"
    cooldown: "2.00 seconds of balance"
    ab_effect: "You will NOT be parried while dancing, but you also do NO limb damage."
    abadmin_id: 3242
system_wiring:
  eligibility: "ataxiaTables.classDefences.bard (deffing/004) -- lets defadd/keepadd accept them"
  display: "ataxiaTables.defenceWords.bard (deffing/004) -- renders 'Hawkstep (dance hawkstep)' in `defs valid`"
  gmcp_names: "UNCONFIRMED for hawkstep/wavedance. `harrying` is confirmed GMCP-tracked; the other two are assumed to use the same bare-word naming. A live DEF capture while dancing each would settle it -- if they differ, fix deffing/004 and BARD_DANCES in basher/002."
open_question: |
  The bashing dance-picker (ataxiaBasher_bardWantDance, basher/002) selects wavedance for
  bosses on the stated basis of "ignoring 75% of resistance", and hawkstep for crowds/deep
  ripples on the basis of "25% damage resistance". NEITHER number appears anywhere in the AB
  text above, which describes hawkstep as escape-assurance and wavedance as unparryable /
  no-limb-damage. Those bashing rationales are therefore unverified and possibly wrong; the
  picker's behaviour has not been changed pending confirmation.
```

## Fighting Against This Class
```yaml
priority_cures:
  - asthma: "Restore smoking ability"
  - slickness: "Restore salve application"
  - anorexia: "Restore eating ability"
  - paralysis: "Restore tree usage"
  - dissonance: "Cure song afflictions"

dangerous_abilities:
  - finale_burst: "Crescendo -> finale high burst damage (cure crescendo with ash)"
  - refrains: "Affliction pressure delivered by blade moves"
  - bladedance: "Rapier limb prep toward sunrise/sunset"

avoid:
  - "Letting crescendo build toward finale"
  - "Ignoring refrain afflictions"
  - "Letting lock afflictions stack"
  - "Letting all four limb groups get prepped (sunrise/sunset kill)"

recommended_strategy: |
  Cure crescendo (ash) before finale lands.
  Cure refrain afflictions quickly.
  Prioritize curing lock afflictions.
  Apply weariness to block their Fitness.
  Rebounding helps slow their attacks.
  Don't let voyria stick or you can't sip immunity.
```

## Implementation Notes
```
Offense entry points (bard/001_LeviBard.lua):
- bard.dispatchOne() / levibardone()  — sunrise kill route, sunset tempo
- bard.dispatchTwo() / levibardtwo()  — tempo-gated sunset, shorter chain
- Shared preamble bard.preDispatch(): sets bardflick, clears envenomList, runs calcPreps.

State machine:
- Crescendo builds via tAffs.crescendo; bladefinale flag => finale burst.
- bardflick set when target has >=3 of FLICK_AFF_LIST (14 affs), threshold 3.
- Refrain chosen by bard.selectRefrain() from REFRAIN_AFFS priority list (fallback paean).
- Rebounding/shield => 'blade punctuate' (bypasses rebound).
- Bare globals owned by triggers: bardtempo/bardtempostance/bardtemposequence,
  bardsunset, bardsunrise, bladefinale, rapierdamage, envenomList.

Edge cases:
- Voyria is their class-specific lock aff
- Bladedance allows venom application (sunset envenom-fang jab, slike)
- Crescendo builds and can burst via finale
- Sagas vs Woe have different abilities
```

## Movement in the tower: BACKFLIP, not LEAP (v4.7.217)

User, 2026-08-06: *"when in bard, we should BACKFLIP (direction) instead of Leap as it is
faster balance."* Acrobatics BACKFLIP recovers quicker than the chitin-greaves LEAP, and every
tactical move in Mnemosyne is a retreat made because something is going badly -- the balance we
get back is the balance we spend curing.

Applied in `S._tacticalGo` (`mnemosyne/009_Swarm_Tactics.lua`) via `S.moveVerb(dir)`: the pull
retreat, the low-HP escape, the re-entry and the forced disengage. The normal sweep already
WALKS (`_exploreMove` sends a bare direction), so there was never balance to save there.

**LEAP is kept wherever a wall is known to stand** -- `_escapeSuffix` wall-mode (both
branches), the wall-mode re-entry, and the explorer's "a wall blocks the way". Those jumps
exist to clear our OWN icewall, and greaves-LEAP is the ability confirmed to do that in both
directions (it is why re-entry needs no melt). **Whether BACKFLIP crosses an icewall is not
confirmed**, and guessing wrong is not a slow move -- it is a silent no-op in the indoor low-HP
escape, i.e. the anti-death ladder livelocking at crash HP, the exact failure the LEAP was
introduced to fix. `moveVerb` disambiguates from `wallRaised[room]` and falls back to LEAP when
the wall state cannot be resolved.

*Open:* if backflip does clear icewalls, the wall branch can be dropped and all four sites
converted. One in-game test settles it -- raise a wall with the bracers and backflip that edge.

## Acrobatics defence

The defence is toggled with `acrobatics on` / `acrobatics off` (not `defence acrobatics`).

## The bash performance: the attack eats the lyre (v4.7.232)

`ataxiaBasher_bardCompose` sent `remove lyre;wield left lyre;compose ...` **raw**, and the
basher dispatches an attack on the next prompt -- which **re-wields the shield into the left
hand**. The lyre was pulled out between `wield` and `compose`, so compose failed with *"How are
you going to perform a song without your instrument wielded?"* while the echo still said
*"composed"*. We announced a performance that never started, then bashed unbuffed for 15
minutes.

The fix needs BOTH halves, either alone still loses the race:

1. **One queued line** -- `queue addclear free remove lyre;wield lyre;compose <list>` -- so the
   three run in order and each waits for what it needs.
2. **`ataxiaTemp.bardComposeHold` gates `ataxiaBasher_attack`** (same place as `swarmHold`,
   because several triggers call `attack()` directly). Bounded by a timer AND released by the
   performance-duration line, so it cannot wedge.

*General shape: any multi-command setup that changes what is in our HANDS races the attack
dispatcher, because the attack re-wields. Queue it and hold the attack.*

## Battlerage runs on the SHARED slots (v4.7.230)

Bard owns no rotation table. `moulinet` gates on `battleRage_Timers.small`, `howlslash` on
`.large`, `trill` on `.special`; `cyclone` carries its own epoch stamp
(`ataxiaTemp.bardCycloneAt`) and **`charm` is deliberately not cooldown-gated**.

Those names were missing from `BR_READY_MAP`, so *"You can use Moulinet again."* was matched by
trigger 328, passed to `ataxiaBasher_brReady`, found nothing and was **dropped** -- we then waited
out the rest of a hardcoded 17s timer the game had already ended. Now mapped. **Do not map
`charm`**: clearing a slot on its ready line would free an unrelated ability.

## Shadow Tempo (boon, v4.7.241)

*"Increase the bonus damage when striking denizens from the back position with bladedance
attacks to 100%."*

Bladedance moves us around the target on its own -- *"carries you with lethal promise to the
blindspot"*, *"carries you back around to face"* -- so the back position arrives without being
chosen. Doubling its bonus makes it worth **keeping**: `charm` and `trill` are the two abilities
that reposition us, so while `mnemShadowTempo` is held AND `bardtempo == "back"` they yield to
plain damage.

Reads `bardtempo`, which the tempo triggers (`tempo/001-004`) have maintained all along -- a
second position flag would have been two sources of truth for one fact. Gated on the boon:
without it the back bonus is small and the crowd abilities are worth more.
