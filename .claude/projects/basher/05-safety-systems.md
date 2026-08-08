# Safety Systems

## Danger Level Assessment

Function: `ataxiaBasher_dangerLevel()` in `basher/001_Bashing_Functions.lua`

Returns one of: `"attack"`, `"shield"`, `"flee"`, `"wait"`

### Decision Tree

```
1. bashFlee == true?                → "wait"
2. hpp == 0?                        → "wait" (invalid state)
3. aeon, paralysis, or peace?       → "wait" (can't act)
4. No-flee area (World Tree/Mnemosyne)?
     ├─ extreme damage + can shield → "shield" (one-cycle guard, keep attacking)
     └─ else                        → skip both flee checks below
5. hpp ≤ fleeThresholdPct (25%)?    → "flee"
6. Extreme damage rate detected?    → "flee"
7. hpp ≤ shieldThresholdPct (40%)?  → "shield" (if can shield)
8. Otherwise                        → "attack"
```

### Extreme Damage Rate Detection

Function: `ataxiaBasher_isDamageRateExtreme()` — returns true if total damage in last 5 seconds exceeds 60% of max HP.

Damage recorded via `ataxiaBasher_recordDamage(amount)` as `{timestamp, amount}` tuples in a rolling window.

### No-Flee Areas

Function: `ataxiaBasher_isNoFleeArea(area)` in `basher/001_Bashing_Functions.lua`

Some areas cannot be fled — there is nowhere to `goto`. In these areas the danger
level **never returns `"flee"`**: an extreme-damage spike or low HP shields instead,
and the attack loop keeps swinging through the shield (the HP≥70 re-attack gate in
`ataxiaBasher_attack()` is dropped for no-flee areas, so it guards reactively rather
than pausing).

**Swarm-retreat is NOT flee.** The Mnemosyne swarm tactics (`mnemosyne/009_Swarm_Tactics.lua`)
deliberately step one room back from a 3+-mob room to funnel followers — a TACTIC, executed
via the explorer's tactical-move machinery (`M._tacticalArm`), never via `executeFlee`.
`dangerLevel()` is untouched: it still never returns `"flee"` in a no-flee area, the shield
ladder still applies, and none of the flee state (`bashFlee`/`fleeOriginRoom`/`fleeReturning`)
is used. The tactic's own gate is `ataxiaTemp.swarmHold` (attack-dispatch hold while a pull
chain is queued), with its own timeout and reload-safety clears.

**At low HP the swarm module also supersedes shield-in-place** (v4.7.114+): at
`swarm.escapeAt`% (default 35, HP-gated only) it flies to hover outdoors / retreats one room
indoors instead of shielding — `touch shield` needs a working arm, which is exactly what a
chip-down death takes first. The shield ladder remains the fallback when no escape route
exists, and SLC's both-arms-broken flee is inert inside the tower (fixed-direction blind
runs; the swarm module owns tower escapes).

| Area | Detection |
|------|-----------|
| the Fathomless Expanse of the World Tree | exact `gmcp.Room.Info.area` match |
| Mnemosyne (tower-climb mod) | `ataxiaBasher.inMnemosyne` flag |

**Mnemosyne detection.** Mnemosyne is an unmapped instance — `gmcp.Room.Info.area`
is `""`, so it cannot be matched from GMCP. Instead the `351_Mnemosyne_Survey`
trigger (`^You are in .*Mnemosyne`) sets `ataxiaBasher.inMnemosyne = true`, and
`ataxia_Room_Update()` clears the flag on entering any real (non-empty `area`) room.
Inside the tower `area` stays `""`, so the flag persists across floors.

**Mitigation-first battlerage supports the no-flee climb.** Since Mnemosyne can't be
fled, hit-prevention matters more than kill speed. When `inMnemosyne` is set, the
Blademaster battlerage rotation reprioritises to fire Daze (→ Stun, mob does nothing
4s) above its damage abilities, reducing incoming damage during the shield-and-swing
survival loop. See [battlerage-pve.md](battlerage-pve.md).

## Flee Execution

Function: `ataxiaBasher_executeFlee()` in `basher/001_Bashing_Functions.lua`

1. Set `bashFlee=true`, `paused=true`
2. Save `fleeOriginRoom` (current room)
3. Start circuit breaker timer (20s)
4. Clear command queue (`cq all`)
5. Check movement-blocking afflictions (paralysis, entangled, webbed, impaled, transfixation, stun)
   - If blocked: shield and wait for cures
   - If mobile: navigate to safe room
6. Navigation priority:
   - Area-specific safe room (`ataxiaBasher.safeRooms[area]`)
   - Previous room (`mmp.previousroom`)
   - Random exit direction
   - Shield if no exit available

## Stun (`ataxiaBasher_stunStart` / `ataxiaBasher_stunEnd`, v4.7.219)

`ataxia.afflictions.stun` gates the affliction check in `ataxiaBasher_tryAttack`, and trigger
723 dispatches straight off `You are no longer stunned.` -- the dispatch was never the slow
part. Two things around it were:

1. **The re-queue cooldown outlived the stun.** `ataxiaBasher_atk` (0.3s) is armed by the last
   dispatch BEFORE the stun latched, and its clearing `tempTimer` runs through the whole stun
   while `affed("stun")` blocks every `tryAttack`, so nothing consumes it. 723's direct call
   ignores the flag, but the follow-up prompt dispatch does not -- a refused or wiped first
   round sat out a window armed for an unrelated reason. `stunEnd` now drops it and kills its
   timer, so that timer cannot fire later and clobber a fresh one.

2. **The flag had one way out and no failsafe.** Two of trigger 722's three patterns are
   Vertani-soldier-specific, so in practice the setter is the REFUSAL line ("You are too
   stunned to be able to do anything") -- which fires for ANY stun source, because it only
   appears when we tried to act. Exactly one line cleared it. Miss that line (different
   wording, split line, lost packet) and the flag latched TRUE and the basher was blocked until
   the next stun happened to print it: a STALL, indistinguishable from lag at the keyboard. The
   flag now self-expires after `ataxiaBasher_STUN_FAILSAFE` (5s) and dispatches on the way out,
   so the worst case is five seconds instead of forever.

**Not done, and why:** pre-queuing during the stun would beat the client round-trip, but the
refusal line exists and is GAGGED in `011_GAG2`, which means queued commands are attempted and
burned mid-stun rather than held. Re-queuing to compensate would re-run the whole round
assembly each time, spending battlerage charges, deck picks and cooldown stamps on rounds that
get refused -- the class of bug `ataxiaBasher_brCommit` exists to prevent. Needs the server's
queue-during-stun behaviour confirmed first.

## PvE Auto-Parry (v4.7.222)

From a Duke Semiro log: over ~20 swings, **two parries landed**. Three separate defects.

1. **Following the LAST hit is the wrong rule** against a mob that spreads. Semiro interleaves
   right leg, torso and head, so focus-follow parked the cover on the limb he had just finished
   with -- permanently one swing behind, actively anti-correlated with an alternating attacker.
   `selfLimbDamage.hitHistory` (rolling 6) already existed and **nothing in the PvE path read
   it**. `ataxia_bashingParryFocus()` now takes the MOST-hit limb, ties broken toward the more
   recent so a genuine focus-switch is still followed rather than outvoted by history.
2. **The broken-limb filter excluded exactly the limb worth covering.** Skipping a limb because
   it is already broken is backwards in PvE: re-hits are how `rl1` becomes `Rl2`, and how BOTH
   legs break -- the state that refuses our own attacks outright. The predictive `fixed` path
   (005) had always parked on broken limbs deliberately; focus-follow now matches.
3. **A 3-second lockout on a mob swinging every 2 seconds.** `parryAttempted` exists to cover
   the round-trip until the server confirms (~100-300ms). Trigger 757 -- the confirm, gagged for
   display but still firing -- now frees it on landing; the timer is the fallback only, cut
   3 -> 1.5s, tracked and killed on re-arm so a stale timer cannot clear a newer guard.

**The trap this created:** a PARRIED swing emits no `dealt N% damage` perceive line, so it never
reaches `ataxia_raiseLimbDamage`. Counting only unparried hits would under-represent exactly the
limb the parry is succeeding on -- the parry would sabotage itself. `ataxia_recordSelfHit` is
shared and `ataxia_parrySuccess` feeds it.

*General shape: when you start scoring an event stream, check which events the SUCCESS case
removes from the stream.*

## Circuit Breaker

Function: `ataxiaBasher_startFleeTimer()` — 20-second timeout (configurable via `ataxiaBasher.fleeTimeout`).

If flee state persists after timeout, calls `ataxiaBasher_areaoff()` to fully disable the basher as a safety measure, preventing zombie bashing loops.

## PvP Detection

Function: `ataxiaBasher_onAttacked()` in `genrunning/001_Bashing_API.lua`

Triggered by `"attacker class detected"` event:
1. Immediately disables basher
2. Clears all queues and flee state
3. Navigates to Mhaldor (`expandAlias("goto Mhaldor")`)

### Player Flee (Per-Area)

Function: `ataxiaBasher_checkPlayerFlee()` in `basher/001_Bashing_Functions.lua`

- Configured via `ataxiaBasher.fleeFromPlayers[area]` — list of player names
- When hostile player detected: calls `areaoff()`, shields, alerts

## Death Handling

Function: `ataxiaBasher_onDeath()` in `genrunning/001_Bashing_API.lua`

Triggered by `"player death"` event:
1. Save death area (before respawn changes it)
2. Disable basher, clear all modes
3. Kill ALL timers (flee, return, stuck, attack)
4. Pause mapper
5. Raise `"basher disabled"` event
6. After 2s: unpause mapper, navigate to safe room

## Room Skip (scanRoom)

Function: `ataxiaBasher_scanRoom()` in `genrunning/001_Bashing_API.lua`

Sets `ataxiaBasher_skipRoom = true` when:
- Mob in `ataxiaBasher.mobIgnore` is present
- Dangerous mob count exceeds `ataxiaBasher.dangerCount`
- Non-ignored player present (except Mhaldor)

## Own Denizens (pets/allies — never targeted, room NOT skipped)

Function: `ataxiaBasher_isOwnDenizen(name)` in `basher/001_Bashing_Functions.lua`

`ataxiaBasher.ownDenizens` is a list of **case-insensitive substring keywords** for
denizens that belong to you (falcons, Baalzadeen, summons). Unlike `mobIgnore`, a
match does **not** skip the room — the basher keeps killing everything else while
your pet stands there. Matches are excluded from:

- auto-learn (`update_stuff/003_ataxia_RoomContents_Update.lua`)
- slain auto-add (`triggers/.../340_Slain.lua`)
- target selection (`search_targets()` and `shieldedTarget()` in `genrunning/002_search_targets.lua`)
- the `bash add` manual candidate list

Seeded with `{"falcon", "baalzadeen", "ashbeast", "hyena"}`
(`002_Check_For_Any_Missing_Variables.lua:146`; `ashbeast`/`hyena` arrive by backfill so
existing saves get them too). Managed via `bash mine` (see configuration doc); adding a
keyword also purges already-learned matches from every target list via
`ataxiaBasher_purgeOwnFromTargets()`.

### The substring match cuts both ways — `notOwnDenizens` (v4.7.169)

Substring matching is what lets one keyword cover a whole family of pet names without
enumerating the variants, and it is also why a **real, killable denizen** whose name merely
contains a pet's word is silently shielded. `a slope-backed hyena` is exactly that: a genuine
mob, protected by the `hyena` keyword seeded for the Infernal pet, and
`ataxiaBasher_purgeOwnFromTargets()` additionally **deleted it from the learned target list
across every area**.

Outside the tower that costs xp. Inside Mnemosyne it stalls the run, because the whole tower
stack agrees with the mistake: the explorer filters own denizens through the same predicate
in both of its room readings (`M._roomHasDenizens`, `mnemosyne/008_Explorer.lua:97`, and
`M._denizenCount`, `008:108`), so a shielded mob is invisible to the sweep as well as
unpickable by `search_targets`. The room reads *clear* while a live denizen stands in it: the
explorer moves on, no boon screen arrives (a ripple ends only when its denizens are dead —
`M.onBoonScreen`, `008:684`), and the grid-swept boss/straggler patrol burns its
`MAX_PATROL_LOOPS` (3, `008:55`) hunting something it cannot see before giving up with
"no boss / straggler found after patrolling; stopping" (`008:532`). The 30s stall watchdog
(`008:52`) does not catch it either: it is re-armed on every progress event and the patrol
keeps arriving in rooms, so it never trips — and when the patrol gives up, `_exploreStop`
kills it outright (`008:643`). Nothing errors and nothing warns; the run simply ends on a
ripple that was never cleared.

`ataxiaBasher.notOwnDenizens` is the exemption list and it **wins**: it is scanned first in
`ataxiaBasher_isOwnDenizen` (`basher/001_Bashing_Functions.lua:348-356`), so the pet
("a daemonic hyena") stays protected while the mob is targetable again. Seeded by backfill
rather than as a default (existing saves already carry the bare keyword), and managed with
`bash notmine [add|rem] <name>`. Narrowing the seeded keyword to `daemonic hyena` was
considered and rejected: it only helps fresh installs, and does nothing for the next
collision. **When adding a pet keyword, prefer the most specific form that still covers the
variants, and expect collisions — the exemption list is the general answer.**

## Attack Gate Afflictions

The basher blocks attacks when any of these afflictions are active:
paralysis, aeon, peace, transfixation, webbed, impaled, constricted, deepsleep, entangled, unconsciousness, snared

## Emergency Systems

### Wand of Reflection
- Threshold: `ataxia.wandReflectionThreshold` (default 10% HP)
- Recovery: `ataxia.wandReflectionRecovery` (default 70% HP)
- Command: `point [wandId] at me`
- Cooldown: 1 hour

### Maran Barrier (Legend Deck)
- Threshold: `ataxia.maranThreshold` (default 25% HP)
- Requires: Maran card charge available
- Command: `ldeck draw maran`
- Cooldown: 65 seconds (the barrier lasts 60)
- **Stands down in Mnemosyne** (v4.7.165, `basher/001_Bashing_Functions.lua:588-606`): when
  `inMnemosyne` and `mnemLdeck.enabled`, the tower card layer owns Maran along with five
  other cards. This path `return`s and forfeits the whole attack cycle, the card layer rides
  the assembled round instead — running both would double-draw a 2-charge card.

### Blood Maiden Cloak (model corrected v4.7.167)
- Trigger: 4+ mobs matching the area target list, **or** any mob in
  `ataxiaBasher.bloodMaidenBosses` — and never while `prone`
- Charge: `ataxiaTemp.bloodshieldReady`, one charge, set by `A cloak of the Blood Maiden
  seems to grow hot against your skin.` (trigger `769_Blood_Maiden_Cloak.lua`, which also
  gags the line while bashing) and **consumed by one `activate bloodshield`**
- Guard: `ataxiaTemp.bloodshieldCooldown`, a 3-**second** anti-double-send flag, not a
  cooldown on the cloak

BLOODSHIELD blocks **the next attack**, once. The code used to read TALISMAN INFO's "failing
to make a kill within 3 minutes will cause the blood reserves to deplete" as *"the cloak
stays active for 3 minutes, so re-activation is free"*, and dropped the mob threshold from 4
to 3 on that basis. Both halves were wrong — the 3 minutes is the depletion timer on the
reserves, not an uptime — so a charge earned over five kills was spent and then re-spent
every 3s against a cloak that had nothing left. One charge, one activation, spent only on a
genuinely dangerous room. The prone exclusion is its own mechanic: under aggression aura the
cloak refuses while prone, and has a 50% chance to eat the charge for nothing.

## Timing Summary

| System | Duration | Configurable |
|--------|----------|-------------|
| Anti-spam delay | 0.3s | No |
| Flee circuit breaker | 20s | `fleeTimeout` |
| Return navigation timeout | 15s | No |
| Stuck detection | 15s | `stuckTimeout` |
| Shield duration (default) | 3.1s | `shieldTimerDefault` |
| Damage rate window | 5s | No |
| Throttle pause | 2s | No |
| Max attacks/sec | 5 | No |

**Vitals-pinning effects vs the safety ladder (v4.7.124):** the Senseless Flurry numb
keeper is CROWD-GATED because numbness defers damage — HP pins while it is up, which
silently blinds every HP-based safety (the damage-rate watchdog records nothing, danger
levels never trip, the swarm escape ladder's vitals watchdog reads a flat line) until
the deferred lump lands as one −40% blow. In a swarm-threshold room that lump can
exceed max HP. The keeper therefore only numbs in thin rooms (< swarm threshold, no
tactic running), where the lump is survivable and the next prompt's hp-delta trips the
rate-shield normally. General rule: any effect that pins or fakes vitals must be gated
away from exactly the situations these safeties exist for.
