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
