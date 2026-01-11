# V2 Architecture Design

## Design Principles

1. **Parallel System** - V2 runs alongside V1, not replacing it
2. **Toggle Control** - Single setting enables/disables V2
3. **Backward Compatible** - Syncs to old tAffs for existing offense code
4. **Fail Safe** - Disable V2 instantly to fall back to old system
5. **AK-Inspired** - Based on patterns from AK 8.6.5 (see [06-ak-analysis.md](06-ak-analysis.md))

## Data Structures

### tAffsV2 - Certainty-Based Tracking with Stacking

```lua
tAffsV2 = {
    -- affliction = certainty level (multiples of 2 = stacks)
    asthma = 2,        -- 2 = 1 confirmed instance
    clumsiness = 4,    -- 4 = 2 stacked instances
    sensitivity = 1,   -- 1 = 1 likely instance (uncertain)
    weariness = 0,     -- 0 = Absent/unknown
}
```

**Certainty Levels with Stacking**:
- `0` = **Absent** - Never applied or definitely cured
- `1` = **Likely** - 1 instance, but might be cured (uncertain)
- `2` = **Confirmed** - 1 confirmed instance
- `3` = **2 stacks, 1 uncertain** - 2 instances, one might be cured
- `4` = **2 confirmed stacks** - 2 confirmed instances
- etc.

**Stack Interpretation**:
- Even values (2, 4, 6) = all stacks confirmed
- Odd values (1, 3, 5) = one stack is uncertain
- `getStackCountV2(aff)` returns `math.floor(certainty / 2)`

### affTimersV2 - Timestamps

```lua
affTimersV2 = {
    asthma = 1234567890.123,  -- getEpoch() when last confirmed
}
```

Used for:
- Future decay implementation
- Debugging (how long since confirmed?)

### randomCuresV2 - Random Cure Counter

```lua
randomCuresV2 = 0  -- Expected random cures (tree/focus queued)
```

Tracks expected passive cures. When target uses tree/focus:
- If counter > 0: Expected, decrement counter
- If counter = 0: Unexpected, reduce certainty of a tracked aff

### lastGuessV2 - Backtracking Data

```lua
lastGuessV2 = {
    removed = "weariness",           -- Which aff we guessed was cured
    candidates = {"weariness", "clumsiness"},  -- All possibilities at time of guess
    herb = "kelp",                   -- Which herb triggered the guess
    timestamp = 1234567890.123       -- When guess was made (expires after 5s)
}
```

## Core Functions

### Certainty Management

| Function | Purpose |
|----------|---------|
| `confirmAffV2(aff)` | Sets certainty to 2, updates timestamp, syncs, raises "tar afflicted" |
| `removeAffV2(aff)` | Sets certainty to 0, clears timestamp, syncs, raises "target cured aff" |
| `uncertainAffV2(aff)` | Decrements certainty by 1, raises cure event if reaches 0 |
| `haveAffV2(aff)` | Returns true if certainty >= 1 |
| `haveConfirmedAffV2(aff)` | Returns true if certainty >= 2 |

### Stack Tracking

| Function | Purpose |
|----------|---------|
| `stackAffV2(aff)` | Increments certainty by 2 (adds a stack) |
| `unstackAffV2(aff)` | Decrements certainty by 2 (removes a stack) |
| `getStackCountV2(aff)` | Returns number of stacks: `math.floor(certainty / 2)` |
| `hasMultipleStacksV2(aff)` | Returns true if stack count >= 2 |

### Random Cure Tracking

| Function | Purpose |
|----------|---------|
| `addRandomCureCounterV2()` | Increment expected cures counter |
| `onTargetTreeV2(target)` | Handle tree usage (decrement or reduce certainty) |
| `onTargetFocusV2(target)` | Handle focus usage (decrement or reduce certainty) |
| `reduceRandomAffCertaintyV2()` | Reduce certainty of one tracked affliction |
| `resetRandomCuresV2()` | Reset counter (on target change) |

### Sync Function

| Function | Purpose |
|----------|---------|
| `syncToOldSystem(aff, certainty)` | Updates `tAffs[aff] = (certainty >= 1)` |

## Herb Priority Lists

All 7 herbs have priority lists ordered by verifiability (unverifiable first):

```lua
herbRemovalPriority = {
    kelp = {"hypochondria", "parasite", "weariness", "healthleech",
            "sensitivity", "clumsiness", "asthma"},
    ginseng = {"addiction", "lethargy", "haemophilia", "darkshade",
               "nausea", "scytherus"},
    goldenseal = {"depression", "shyness", "dizziness", "stupidity",
                  "epilepsy", "impatience"},
    ash = {"hypersomnia", "hallucinations", "dementia", "paranoia",
           "confusion"},
    bellwort = {"retribution", "lovers", "justice", "generosity",
                "pacifism"},
    lobelia = {"fratricide", "hypochondria", "loneliness", "claustrophobia",
               "agoraphobia", "vertigo", "masochism", "recklessness"},
    bloodroot = {"slickness", "paralysis"},
}
```

**Priority Rationale**:
- Unverifiable affs first (assume cured, we can't prove otherwise)
- Verifiable affs last (we can confirm via behavioral signals)
- Lock-critical affs last (keep tracking as long as possible)

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

### Random Cure Flow (Tree/Focus/Passive)

```
Target uses Tree/Focus/Passive
        ↓
    randomCuresV2 > 0?
    ┌────┴────┐
   Yes        No
    ↓          ↓
Decrement   reduceRandomAffCertaintyV2()
counter           ↓
             Find first tracked aff
                   ↓
             uncertainAffV2(aff)
```

### Backtracking Flow

```
Target fumbles (proves clumsiness)
        ↓
onTargetFumbleV2(target)
        ↓
    lastGuessV2.removed == "clumsiness"?
    ┌────────┴────────┐
   Yes                No
    ↓                  ↓
backtrackKelpCureV2   confirmAffV2("clumsiness")
    ↓
Put clumsiness back (certainty=2)
Remove next candidate
Clear lastGuessV2
```

## Module Responsibilities

### 001_Core.lua
- Data structures (`tAffsV2`, `affTimersV2`, `randomCuresV2`)
- Core functions (`confirmAffV2`, `removeAffV2`, etc.)
- Stack tracking functions (`stackAffV2`, `unstackAffV2`, etc.)
- Random cure tracking (`onTargetTreeV2`, `onTargetFocusV2`, etc.)
- Sync to old system
- Event handler to catch affliction applications
- Debug function (`debugAffsV2()`)

### 002_Herb_Cures.lua
- `herbRemovalPriority` table (all 7 herbs)
- `targetAteWrapper()` - routes to V2 or old
- `targetAteV2()` - V2 herb cure logic
- `removeByPriorityV2()` - uses herb-specific priority
- `storeGuessV2()` - stores guess for backtracking
- Smoke disambiguation timer

### 003_Backtracking.lua
- `lastGuessV2` tracking (generic for all herbs)
- `hasPendingGuessV2()` - check if guess pending
- `backtrackKelpCureV2()` - reverses wrong guesses
- `clearPendingGuessesV2()` - cleanup on target change

### 004_Verification.lua
- `onTargetFumbleV2()` - handles fumble detection (confirms clumsiness)
- `onTargetSmokeV2()` - handles smoke detection (confirms no asthma)
- `onTargetAttackV2()` - tracks non-fumbles for uncertainty
- Target change event handler

## Sync Strategy

V2 syncs TO the old system, not FROM it:

```
V2 Update → syncToOldSystem() → tAffs updated
```

This ensures:
- Old offense code still works (reads tAffs)
- V2 is the source of truth when enabled
- No conflicts between systems

## Trigger Integration

### Core Triggers
| Trigger | V2 Call |
|---------|---------|
| `368_Tree(U).lua` | `onTargetTreeV2(name)` |
| `369_Smoked.lua` | `onTargetSmokeV2(matches[2])` |
| `377_Focus_(UNK).lua` | `onTargetFocusV2(name)` |
| `378_Focus_(known).lua` | `onTargetFocusV2(name)` or specific `removeAffV2()` |

### Class Passive/Active Cures
16 triggers in `passive_active/` folder, each calling:
- `removeAffV2(aff)` for specific known cures
- `reduceRandomAffCertaintyV2()` for random cures
- `resetAffsV2()` for full resets (Phoenix)
