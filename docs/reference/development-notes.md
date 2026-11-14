# Development notes: the general reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Development Guidelines

### Naming Conventions

**Functions** — use `snake_case` with the owning namespace as a prefix:

| Namespace | Prefix | Example |
|-----------|--------|---------|
| Core system | `ataxia_` | `ataxia_saveSettings()`, `ataxia_promptAffs()` |
| Basher | `ataxiaBasher_` | `ataxiaBasher_assembleAttack()` |
| NDB | `ataxiaNDB_` | `ataxiaNDB_getClass()` |
| GUI | `ataxiagui_` | `ataxiagui_createMap()` |
| MMP | `mmp.*` | `mmp.gotoRoom()` |

**Module tables** — `camelCase` no underscore: `ataxia`, `ataxiaNDB`, `ataxiaBasher`, `ataxiaTables`, `mmp`.

**Private / module-internal helpers** — declare `local`, no prefix required.

**Files** — `NNN_Descriptive_Name.lua` (three-digit numeric prefix for load order).

**Directories** — `snake_case`.

**What to avoid**:
- camelCase public functions (`ataxiaCheckForMissing` → prefer `ataxia_checkForMissing`)
- Unprefixed globals (`haveDef`, `needToSalt`) — make `local` or add namespace prefix
- Mixed conventions within a single file

Migration is gradual: apply the standard to new code and any file touched significantly.

### Namespace Pattern
```lua
-- All system code under namespaces
ataxia = ataxia or {}
ataxia.afflictions = ataxia.afflictions or {}
ataxia.balance = ataxia.balance or {}
ataxia.defense = ataxia.defense or {}

mmp = mmp or {}
mmp.settings = mmp.settings or {}

ataxiagui = ataxiagui or {}
ataxiaNDB = ataxiaNDB or {}
```

### Initialization Pattern
```lua
function ataxia.initialize()
  -- Setup file paths
  ataxia.filepath = getMudletHomeDir() .. "/AtaxiaSaves"
  if not io.exists(ataxia.filepath) then
    lfs.mkdir(ataxia.filepath)
  end

  -- Request GMCP data
  sendGMCP([[ Core.Supports.Add [ "Comm.Channel 1" ] ]])
  sendGMCP([[ Core.Supports.Add ["IRE.Target 1"] ]])
  sendGMCP("IRE.Rift.Request")
  sendGMCP("Char.Items.Inv")

  -- Initialize subsystems
  ataxia.loadSettings()
  ataxia.balance.reset()

  raiseEvent("ataxia system loaded")
end

registerAnonymousEventHandler("gmcp.Char.Name", "ataxia.initialize")
```

### Event-Driven Architecture
```lua
-- Raise custom events for inter-module communication
raiseEvent("aff gained", "paralysis")
raiseEvent("aff lost", "paralysis")
raiseEvent("ataxia system loaded")

-- Other modules listen
registerAnonymousEventHandler("aff gained", "updateUI")
```

### Echo/Debug Pattern

**THIS SECTION TAUGHT A HELPER THAT DOES NOT EXIST (corrected v4.7.281).** It presented
`ataxia.echo` as the idiom, and `ataxia.echo` is defined nowhere in the tree -- which is precisely
how **17 call sites** came to be written against it and silently die (`attempt to call field 'echo'
(a nil value)`), including every echoing branch of `bash shinprobe` and all nine in `ataxiabars`.
A pattern in this guide gets copied without checking, so a wrong one here becomes a bug everywhere.

**The real helper is the global `ataxiaEcho`**, defined in a `_groups.yaml` inline script:

```lua
-- The user-facing echo. GLOBAL, not a namespace field:
ataxiaEcho("shin augment probe -- samples cleared.")
-- renders: (LEVI): shin augment probe -- samples cleared.

-- Colour tags pass straight through, since it is cecho underneath:
ataxiaEcho("<gold>SHIN AUGMENT<reset> -- measured duration by spend")

-- Quiet commands (no local echo of the command itself):
send(command, false)
```

Module-scoped alternatives that DO exist, where a subsystem wants its own prefix: `shecho`
(Shaman), `ataxia.mnemosyne.echo` / `.decho` (Mnemosyne, `M.echo` internally), and
`ataxiaBasher_dsAlert` (basher denizen-state alerts, gated on `ataxiaBasher.brAlerts`).

`ataxia.decho` is likewise undefined. Its six guarded calls in `affliction_tracking_core/008_V3_Integration.lua`
therefore never printed a `[V3] ILLUSION:` line, until v4.7.479 sent them through `illusionEcho` (008:76).
**Guard an optional helper or use a real one; never assume.**

`tools/check_orphans.py` now fails CI on a namespace field that is called but assigned nowhere, so
this class of mistake cannot ship silently again.

**Echo strings must be pure ASCII** (2026-07-26): typographic characters (em-dashes `—`,
arrows `→`, ellipses `…`, curly quotes) mojibake through the packaging/display pipeline
(`—` rendered as `â€"` in-game). Use `--`, `->`, `...`, `'` in any string passed to
echo/cecho/send. Decorative box-drawing borders in status screens are currently
tolerated; never add new non-ASCII to user-visible strings.

---

---

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Testing Approach

### Mock GMCP Data
```lua
gmcp = gmcp or {}
gmcp.Char = gmcp.Char or {}
gmcp.Char.Vitals = {bal="1", eq="1", hp=5000, maxhp=5000}
gmcp.Char.Afflictions = {List = {}}
```

### Test files share one Lua state
`src_new/tests/test_runner.lua` runs every `test_*.lua` in ONE Lua state, in filename order, so a
global that a test file replaces (`send`, `io.open`, `tempTimer`, `getEpoch`, `ataxiaEcho`, a
module stub) is still replaced for every file after it. Restore it at the end of the file, and
inside a test restore it under `pcall` so a failing `expect` cannot leak it. Two real cases:
`test_settings.lua` mocked `io.open` (a write handle for any path opened without a mode) and never
restored it, so a later test reading a trigger file got a table with no `read` (fixed v4.7.321);
`test_swarm_tactics.lua` restores `send` part-way down the file, so blocks after that point capture
sends locally. A fixture that rewinds a mock clock must also clear every stamp taken on that clock,
or an earlier test's stamp sits in this test's future and reads as fresh.

### Performance Considerations
- **Sub-second response times critical**
- Optimize trigger patterns (use specific strings over wildcards)
- Cache frequently accessed data
- Minimize table creation in hot paths (balance/prompt triggers)
- Use stopwatches for precise timing
- Avoid expensive operations in prompt triggers

---

---

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Important Considerations

### Things to Remember
- Achaea has 26 classes (21 base + 4 Elemental Lords + Dragon) with unique mechanics
- Server-side curing exists but custom systems provide advantages
- Illusions and hidden afflictions are common (use diagnosis)
- Combat logs can be several hundred lines per second
- System must handle disconnections/reconnections gracefully
- Blackout hides all vitals and afflictions (special handling required)
- Aeon/retardation slow down actions (disable batching). Only the last command of the last run happens, so a slowed alias round is one command (`kb/mechanics/balance-and-queueing.md`)
- Some afflictions prevent certain actions (paralysis, stun, etc.)

### Things to Avoid
- Hardcoded delays (server-side timing varies by ping)
- Assuming affliction order from attacks
- Trusting all game output without verification (illusions exist)
- Over-automating (ToS compliance concerns)
- Blocking the main thread with heavy processing
- Creating tables in hot paths (prompt/vitals triggers)
- Using wildcards excessively in triggers
- Global variable pollution (use namespaces)

---

---

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Technical Context

### What is Achaea?
- Text-based multiplayer game with real-time combat
- Complex affliction system (30+ different afflictions per class)
- Class-based combat with unique abilities per class (26 classes)
- Each class has at most 3 class skills; each skill has many abilities
- Requires sub-second reaction times
- Combat involves illusions that can fake afflictions
- Multiple balance types (balance, equilibrium, class-specific)
- Server-side curing (SSC) exists but custom systems provide competitive advantages

### Mudlet Platform
- Lua 5.1 based MUD client with event system
- **Triggers**: Fire on incoming game text (regex/substring/exact match)
- **Aliases**: User command shortcuts
- **Timers**: Delayed action execution
- **Scripts**: Lua code modules
- **Event system**: Named/anonymous event handlers for inter-module communication
- **GMCP**: JSON-based game data feed (Game.Core.MCP)
- **GUI components**: Gauges, labels, miniconsoles for displays

### Mudlet Package Structure (XML Format)
```xml
<MudletPackage>
  <TriggerPackage>      <!-- Trigger groups and individual triggers -->
  <TimerPackage>        <!-- Timer definitions -->
  <AliasPackage>        <!-- Command aliases -->
  <ScriptPackage>       <!-- Lua script modules -->
  <ActionPackage>       <!-- Buttons/UI actions -->
  <KeyPackage>          <!-- Keybindings -->
</MudletPackage>
```

---

---

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Key Concepts

### Afflictions

**Moved (2026-11-13).** Game facts about afflictions and cures: `kb/afflictions/` (start at `kb/afflictions/README.md`; `catalog.md` is generated and wins on a conflict). Lock types: `.claude/classes/lock_types.md`. How OUR code steers server-side curing (curingsets, base and per-stack priorities, the bashing profile), with the tables that were here: `.claude/projects/curing/README.md`. Read it before any change to curing or priorities.

### Combat Strategies
Classes generally focus on one of two kill paths:

**Affliction-Based**: Stack afflictions to achieve a lock or kill condition
- Build toward Soft Lock → Tree Lock → True Lock
- Use class-specific affliction to complete the lock
- Examples: Serpent, Shaman, Apostate

### Serpent Combat System (Ekanelia + Impulse)

**Moved (2026-11-13).** See `.claude/classes/serpent.md` (the section of this name, at the end of that file).

### Offensive System Development Guidelines

**CRITICAL**: Before coding ANY offensive combat system, agents MUST read:
1. `.claude/classes/lock_types.md` - Lock definitions and escape routes
2. `.claude/classes/<class>.md` - Target class kill routes and vulnerabilities
3. `.claude/classes/README.md` - Affliction stacking reference

**Lock knowledge is essential for:**
- Building toward softlock → venomlock → truelock
- Understanding which afflictions to prioritize
- Knowing gating requirements for key afflictions (e.g., paralysis needs nausea + weariness + asthma for Waterlord)
- Anticipating defender cure priorities and escape routes

**When creating offensive Lua files, include this header:**
```lua
--[[
  OFFENSIVE SYSTEM - <Class Name>

  REQUIRED READING before modifying:
  - .claude/classes/lock_types.md (lock definitions)
  - .claude/classes/<class>.md (class mechanics)

  Lock progression: Softlock → Venomlock → Truelock
  See lock_types.md for affliction requirements and escape routes.
]]--
```

### Balances
- **Balance**: Physical action cooldown (~2-4 seconds)
- **Equilibrium**: Mental action cooldown (~2-4 seconds)
- **Cure balances**: herb, salve, mineral, smoke, focus, tree, sip, moss
- **Class-specific**: kai (Monk), blood (Praenomen), devotion (Priest), etc.
- Tracked via GMCP (`gmcp.Char.Vitals.bal/eq`) and text triggers

**Example Pattern:**
```lua
ataxia.balance = ataxia.balance or {}
ataxia.balance.stopwatches = ataxia.balance.stopwatches or {}

function ataxia.balance.lost(bal)
  if not ataxia.balance.stopwatches[bal] then
    ataxia.balance.stopwatches[bal] = createStopWatch()
  end
  ataxia.bals[bal] = false
  startStopWatch(ataxia.balance.stopwatches[bal], true)
end

function ataxia.balance.regained(bal)
  ataxia.bals[bal] = true
  if ataxia.balance.stopwatches[bal] then
    local time = stopStopWatch(ataxia.balance.stopwatches[bal])
    cecho(" <dark_turquoise>(<plum>"..(math.floor(time*100)/100).."<dark_turquoise>)")
  end
end
```

### Server-Side Curing (SSC)
- Built-in Achaea curing system
- Configurable via `CURING` commands
- Can be integrated with custom systems

```lua
-- Initialize with custom curingset
send("curingset new ataxia", false)
send("curingset switch ataxia", false)
send("curing priority defence list reset", false)
```

**Confused AND disrupted (v4.7.373, `curing/004_Confusion_Disrupted.lua`, user-directed).** Disrupted takes equilibrium and only CONCENTRATE returns it, and concentrate fails while confused -- but SSC holds disrupted at 2 and confusion at 8 (12 in the `bash` set), so with both up it never got equilibrium back. On "aff gained" with both up: `curing prioaff confusion` (one-shot, no stored-priority write); on "aff cured" confusion while still disrupted: `concentrate`. Each throttled 1.5s. The older `conDis` swap (swaps/002) is off by default, also needs impatience, and rewrites the stored priority.

### Queue System
- Achaea has built-in ability queuing
- Commands: `QUEUE ADD`, `QUEUE INSERT`, `QUEUE PREPEND`
- Executes on balance recovery
- Multiple queue types (bal, eq, eqbal, free)

---

---

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## GMCP Data Reference

### Vitals (fires on prompt)
```lua
gmcp.Char.Vitals = {
  hp = "5000",
  maxhp = "5000",
  mp = "4500",
  maxmp = "4500",
  bal = "1",  -- "1" = have balance, "0" = don't have
  eq = "1",
  charstats = {"Endurance: 18500/18500", "Willpower: 18500/18500", ...}
}
```

### Afflictions
```lua
gmcp.Char.Afflictions.List = {
  {name = "asthma", cure = "kelp"},
  {name = "clumsiness", cure = "kelp"}
}
gmcp.Char.Afflictions.Add = {name = "paralysis", cure = "bloodroot"}
gmcp.Char.Afflictions.Remove = {"asthma"}
```

### Room Info
```lua
gmcp.Room.Info = {
  num = 12345,
  name = "A dark alley",
  area = "Ashtan"
}
```

---

---

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Resources & References

- **Achaea Wiki**: https://wiki.achaea.com/
- **Mudlet Documentation**: https://wiki.mudlet.org/
- **Lua 5.1 Reference**: https://www.lua.org/manual/5.1/
- **Achaea API**: http://api.achaea.com
- **IRE Mapping Script Wiki**: http://wiki.mudlet.org/w/IRE_mapping_script
- **Achaea Forums**: https://forums.achaea.com/
- **Agent Teams Guide**: `docs/ai-includes/agent-teams.md` - Multi-agent team coordination for parallel development

---

---

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Questions to Ask When Developing

### Correctness
- Does this handle illusions correctly?
- What happens during blackout?
- How does aeon/retardation affect this?
- Does it work when stunned/asleep/dead?

### Performance
- Is this timing-sensitive code optimized?
- Are we creating unnecessary tables?
- Should this be cached?
- Can triggers be more specific?

### Compatibility
- Does this work for all classes or just one?
- Are there class-specific edge cases?
- How does this behave with different artifacts?

### Reliability
- How does this behave when offline/reconnecting?
- What if GMCP data is delayed?
- Is there graceful degradation?
- Are errors handled properly?

---
