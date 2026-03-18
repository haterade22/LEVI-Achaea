# Basher Architecture

## State Machine

The basher has 7 states controlled by flag combinations:

| State | `enabled` | `paused` | `manual` | `areabash` | `bashFlee` | `fleeReturning` |
|-------|-----------|----------|----------|------------|------------|-----------------|
| Idle | false | false | false | false | false | false |
| Manual | true | false | true | false | false | false |
| Areabash | true | false | false | true | false | false |
| Paused | true | true | * | * | false | false |
| Fleeing | true | true | * | * | true | false |
| Returning | true | false | * | * | false | true |
| Shielded | true | false | * | * | false | false |

### State Transitions

```
Idle → Manual:    ataxiaBasher_manual()
Idle → Areabash:  ataxiaBasher_areabash()
Any → Idle:       ataxiaBasher_areaoff() or manual() toggle-off
Any → Fleeing:    ataxiaBasher_executeFlee() (HP ≤ 25%)
Fleeing → Returning: ataxiaBasher_checkFleeRecovery() (HP = 100%)
Returning → Manual/Areabash: Room_Update arrival at origin room
Any → Idle:       ataxiaBasher_onDeath() or ataxiaBasher_onAttacked()
```

## Dispatch Chain

```
Prompt (GMCP vitals)
  └─ ataxia_promptCommands()          [010_Prompt_Running.lua:57]
     ├─ ataxiaBasher_scanRoom()       [if need_roomCheck]
     ├─ search_targets()              [genrunning/002:100]
     ├─ ataxiaBasher_checkFleeRecovery() [basher/001:256]
     └─ ataxiaBasher_patterns()       [genrunning/004:162]
        └─ ataxiaBasher_tryAttack()   [genrunning/004:107]
           └─ ataxiaBasher_attack()   [basher/001:70]
              ├─ dangerLevel()        → "flee" → executeFlee()
              ├─ dangerLevel()        → "shield" → touch shield
              ├─ dangerLevel()        → "wait" → return
              └─ dangerLevel()        → "attack" → assembleAttack()
                 ├─ Emergency checks  (wand, maran barrier)
                 ├─ assembleBattlerage()
                 ├─ Gold pickup
                 ├─ Legend deck draws
                 ├─ Blood maiden cloak
                 └─ Class-specific bashing function
```

## Gate Sequence (tryAttack)

All attack requests flow through `tryAttack()`. This is the ONLY function that calls `ataxiaBasher_attack()`.

```
1. ataxiaBasher_atk        → cooldown active (0.3s anti-spam)
2. ataxiaTemp.bashFlee     → currently fleeing
3. ataxiaBasher.paused     → manually paused
4. ataxiaTemp.fleeReturning → navigating back to combat room
5. canBals() + canStand()  → GMCP balance/standing check
6. ataxiaBasher_skipRoom   → room flagged to skip (dangerous mob, player, etc.)
7. found_target            → target exists in room (if not, advance room)
8. throttleCheck()         → max 5 attacks/sec safety valve
```

## Room Arrival Flow

```
1. gmcp.Room event fires
2. ataxia_Room_Update() runs:
   a. Remove current room from ataxiaBasher_path (areabash)
   b. If fleeReturning + arrived at fleeOriginRoom → clear return state
   c. Else if bashFlee → re-insert previous room into path
3. gmcp.Char.Items.List event → populate ataxia.denizensHere
4. Next prompt:
   a. scanRoom() → clears need_roomCheck, checks for danger/players
   b. search_targets() → finds target in denizensHere
   c. patterns() → tryAttack() → attack()
```

## Supported Classes (22+)

All class bashing functions in `basher/002_Class_Bashing.lua`:

Alchemist, Apostate, Bard, Blademaster, Depthswalker, Druid, Infernal, Jester, Magi, Monk, Occultist, Paladin, Pariah, Priest, Psion, Runewarden, Sentinel, Serpent, Shaman, Sylvan, Unnamable, Air/Fire/Water/Earth Elemental, Blue/Black/Green/Gold/Red/Silver Dragon

## Event Integration

**Events Raised:**
- `"basher enabled"` — after entering manual/areabash mode
- `"basher disabled"` — after any disable path
- `"changed target"` — after target selection
- `"targets updated"` — debounced denizen list change

**Events Listened:**
- `"mmapper failed path"` → `ataxiaBasher_pathFail()`
- `"mmapper arrived"` → `ataxiaBasher_arrived()`
- `"player death"` → `ataxiaBasher_onDeath()`
- `"attacker class detected"` → `ataxiaBasher_onAttacked()`
- `"basher enabled"` → `basher_engaged()` (GUI, armour swap, legend deck)
- `"basher disabled"` → `basher_disengaged()` (GUI, armour swap)
