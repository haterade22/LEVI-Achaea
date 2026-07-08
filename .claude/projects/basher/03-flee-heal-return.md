# Flee-Heal-Return Loop

## Overview

When the basher flees a room due to low health, it saves the combat room, heals to 100% HP, auto-navigates back, and resumes attacking. The cycle repeats until the room is cleared.

> **No-flee areas** (World Tree, Mnemosyne) bypass this loop entirely — `ataxiaBasher_dangerLevel()` never returns `"flee"` there, so `executeFlee()` is never called. See [05-safety-systems.md](05-safety-systems.md#no-flee-areas) for the shield-instead-of-flee behavior.

## State Variables

| Variable | Type | Purpose | Set In | Cleared In |
|----------|------|---------|--------|------------|
| `ataxiaTemp.fleeOriginRoom` | number | Room ID we fled from | `executeFlee()` | Room arrival, death, disable, PvP |
| `ataxiaTemp.fleeReturning` | bool | Navigating back to origin | `checkFleeRecovery()` | Room arrival, death, disable, PvP |
| `ataxiaTemp.fleeReturnTimer` | timer | 15s return navigation timeout | `checkFleeRecovery()` | Room arrival, death, disable, PvP |

## Flow Diagram

```
Fighting in room X
  │
  ▼ HP drops below 25%
executeFlee()
  ├─ Save gmcp.Room.Info.num → fleeOriginRoom
  ├─ Set bashFlee=true, paused=true
  ├─ Start 20s circuit breaker timer
  └─ Navigate to: safe room > previous room > random exit > shield
  │
  ▼ Arrived at safe room (healing via auto-sip)
checkFleeRecovery() [called every prompt]
  ├─ hpp < 100%? → wait
  └─ hpp >= 100%? → proceed:
     ├─ Clear bashFlee, paused
     ├─ Kill circuit breaker timer
     ├─ Set fleeReturning=true
     ├─ expandAlias("goto " .. fleeOriginRoom)
     └─ Start 15s return timeout timer
  │
  ▼ Room changes during navigation
ataxia_Room_Update()
  ├─ Not at origin room? → continue navigating
  └─ At origin room? →
     ├─ Clear fleeOriginRoom, fleeReturning
     ├─ Kill return timer
     └─ Echo "Returned to bashing room. Resuming."
  │
  ▼ Next prompt
search_targets() → finds mobs → tryAttack() → attack
  │
  ├─ HP drops again? → executeFlee() saves same room → loop repeats
  └─ No mobs left? → nextRoom() (areabash) or wait (manual)
```

## Attack Gates During Return

Both `tryAttack()` and `patterns()` check `fleeReturning` and return early, preventing:
- Attacks in intermediate rooms during navigation
- Room advancement to the next areabash room

## Cleanup Points

The three state vars are cleaned up in ALL basher disable paths:

| Function | File | Trigger |
|----------|------|---------|
| `ataxiaBasher_onDeath()` | genrunning/001_Bashing_API.lua | Player death event |
| `ataxiaBasher_onAttacked()` | genrunning/001_Bashing_API.lua | PvP attack detected |
| `ataxiaBasher_areaoff()` | genrunning/004_Autobashing_Functions.lua | Explicit disable |
| `ataxiaBasher_manual()` (toggle-off) | genrunning/004_Autobashing_Functions.lua | Manual toggle |
| Room arrival at origin | update_stuff/002_ataxia_Room_Update.lua | Normal return |
| Return timeout (15s) | basher/001_Bashing_Functions.lua | Navigation stuck |

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| HP drops during return | `fleeReturning` gate prevents attacks; won't re-flee from transit rooms |
| Origin room cleared by others | Arrive, `search_targets()` finds nothing, `nextRoom()` advances |
| Manual mode + room cleared | Arrive, no targets, basher waits for user movement |
| Return navigation stuck | 15s timer clears state, resumes normal bashing |
| Multiple flees from same room | `executeFlee()` re-saves same room ID, no accumulation |
| Circuit breaker fires (20s) | Disables basher entirely via `areaoff()`, cleans up all state |
| Flee to random exit | `goto fleeOriginRoom` navigates back via mapper pathfinding |

## Timing

| Component | Duration | Notes |
|-----------|----------|-------|
| Flee circuit breaker | 20s | Configurable via `ataxiaBasher.fleeTimeout` |
| Return navigation timeout | 15s | Hardcoded safety |
| Recovery threshold | 100% HP | Hardcoded (was 70%) |
