# Safety Systems

## Danger Level Assessment

Function: `ataxiaBasher_dangerLevel()` in `basher/001_Bashing_Functions.lua`

Returns one of: `"attack"`, `"shield"`, `"flee"`, `"wait"`

### Decision Tree

```
1. bashFlee == true?                → "wait"
2. hpp == 0?                        → "wait" (invalid state)
3. aeon, paralysis, or peace?       → "wait" (can't act)
4. hpp ≤ fleeThresholdPct (25%)?    → "flee" (except World Tree)
5. Extreme damage rate detected?    → "flee"
6. hpp ≤ shieldThresholdPct (40%)?  → "shield" (if can shield)
7. Otherwise                        → "attack"
```

### Extreme Damage Rate Detection

Function: `ataxiaBasher_isDamageRateExtreme()` — returns true if total damage in last 5 seconds exceeds 60% of max HP.

Damage recorded via `ataxiaBasher_recordDamage(amount)` as `{timestamp, amount}` tuples in a rolling window.

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
