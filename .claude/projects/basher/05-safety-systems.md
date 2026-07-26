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

Seeded with `{"falcon", "baalzadeen"}`. Managed via `bash mine` (see configuration
doc); adding a keyword also purges already-learned matches from every target list via
`ataxiaBasher_purgeOwnFromTargets()`.

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
- Cooldown: 65 seconds

### Blood Maiden Cloak
- Trigger: 4+ targetable mobs or any boss (3+ after first activation)
- Cooldown: 3 minutes (`ataxiaTemp.bloodshieldTimer`)
- Bosses: configured in `ataxiaBasher.bloodMaidenBosses`

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
