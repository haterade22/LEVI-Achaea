# V2 Architecture Design

## Design Principles

1. **Parallel System** - V2 runs alongside V1, not replacing it
2. **Toggle Control** - Single setting enables/disables V2
3. **Backward Compatible** - Syncs to old tAffs for existing offense code
4. **Fail Safe** - Disable V2 instantly to fall back to old system

## Data Structures

### tAffsV2 - Certainty-Based Tracking

```lua
tAffsV2 = {
    -- affliction = certainty level
    asthma = 2,        -- 2 = Confirmed (we saw apply message)
    clumsiness = 1,    -- 1 = Likely (applied but might be cured)
    sensitivity = 0,   -- 0 = Absent/unknown
}
```

**Certainty Levels**:
- `2` = **Confirmed** - We applied it and haven't seen a definite cure
- `1` = **Likely** - Applied but a random cure happened (kelp with multiple affs)
- `0` = **Absent** - Never applied or definitely cured

### affTimersV2 - Timestamps

```lua
affTimersV2 = {
    asthma = 1234567890.123,  -- getEpoch() when last confirmed
}
```

Used for:
- Future decay implementation
- Debugging (how long since confirmed?)

### lastKelpGuessV2 - Backtracking Data

```lua
lastKelpGuessV2 = {
    removed = "weariness",           -- Which aff we guessed was cured
    candidates = {"weariness", "clumsiness"},  -- All possibilities at time of guess
    timestamp = 1234567890.123       -- When guess was made (expires after 5s)
}
```

## Core Functions

### confirmAffV2(aff)
- Sets certainty to 2
- Updates timestamp
- Syncs to old system
- Raises "tar afflicted" event

### removeAffV2(aff)
- Sets certainty to 0
- Clears timestamp
- Syncs to old system
- Raises "target cured aff" event

### uncertainAffV2(aff)
- Decrements certainty by 1
- If reaches 0, raises cure event
- Used when a random cure might have affected this aff

### haveAffV2(aff)
- Returns true if certainty >= 1
- Used for offense decisions

### haveConfirmedAffV2(aff)
- Returns true if certainty >= 2
- Used for high-confidence decisions

### syncToOldSystem(aff, certainty)
- Updates tAffs[aff] = (certainty >= 1)
- Keeps old system in sync for backward compatibility

## Flow Diagrams

### Affliction Application Flow

```
Venom hit trigger fires
        ↓
tarAffed("asthma")  ← Old system (unchanged)
        ↓
Event: "tar afflicted"
        ↓
V2 event handler (if enabled)
        ↓
confirmAffV2("asthma")
        ↓
tAffsV2["asthma"] = 2
syncToOldSystem("asthma", 2)
```

### Herb Cure Detection Flow (Kelp)

```
Target eats aurum flake
        ↓
targetAteWrapper("kelp")
        ↓
    ┌───────────────────────────────────┐
    │ ataxia.settings.useAffTrackingV2? │
    └───────────────────────────────────┘
         │                    │
        Yes                   No
         ↓                    ↓
  targetAteV2("kelp")    targetAte("kelp")
         ↓                (unchanged)
    Has asthma?
    ┌────┴────┐
   Yes        No
    ↓          ↓
  Wait 2.5s   Use priority
  for smoke   removal now
    ↓
  Smoke?
  ┌──┴──┐
 Yes    No
  ↓      ↓
Remove  Remove highest
asthma  priority non-asthma
        + store for backtrack
```

### Backtracking Flow

```
Target fumbles (proves clumsiness)
        ↓
onTargetFumbleV2(target)
        ↓
    lastKelpGuessV2.removed == "clumsiness"?
    ┌────────┴────────┐
   Yes                No
    ↓                  ↓
backtrackKelpCureV2   confirmAffV2("clumsiness")
    ↓
Put clumsiness back (certainty=2)
Remove next candidate
Clear lastKelpGuessV2
```

## Module Responsibilities

### 001_Core.lua
- Data structures (tAffsV2, affTimersV2)
- Core functions (confirmAffV2, removeAffV2, etc.)
- Sync to old system
- Event handler to catch affliction applications

### 002_Herb_Cures.lua
- targetAteWrapper() - routes to V2 or old
- targetAteV2() - V2 herb cure logic
- Priority lists (kelpRemovalPriority, etc.)
- Smoke disambiguation timer

### 003_Backtracking.lua
- lastKelpGuessV2 tracking
- backtrackKelpCureV2() - reverses wrong guesses

### 004_Verification.lua
- onTargetFumbleV2() - handles fumble detection
- onTargetSmokeV2() - handles smoke detection
- onTargetAttackV2() - tracks non-fumbles for uncertainty

## Sync Strategy

V2 syncs TO the old system, not FROM it:

```
V2 Update → syncToOldSystem() → tAffs updated
```

This ensures:
- Old offense code still works (reads tAffs)
- V2 is the source of truth when enabled
- No conflicts between systems
