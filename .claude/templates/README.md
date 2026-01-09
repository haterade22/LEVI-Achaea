# Lua Code Templates

This directory contains Lua code templates for Claude AI to use when generating Achaea combat systems.

## Available Templates

### offense_template.lua
**Purpose:** Generic offense system template for any class

**Includes:**
- Mudlet script header with hierarchy
- Namespace initialization pattern
- Configuration and state structures
- Lock detection functions (softlock → truelock)
- Venom selection logic with priorities
- Pre-attack actions (shield strip, rebounding)
- Combo builder
- Main dispatch function
- Status display
- Convenience aliases

**How to use:**
1. Copy the file to `src_new/scripts/levi_ataxia/levi/levi_scripts/yourclass/`
2. Rename to `001_YourClass_Offense.lua`
3. Replace all instances of "classname" with your class (lowercase)
4. Replace all instances of "ClassName" with your class (TitleCase)
5. Customize the `selectAttack()` function
6. Add class-specific abilities

### limb_tracking_template.lua
**Purpose:** Limb damage tracking for limb-based kill routes

**Includes:**
- Limb damage storage (tLimbs table)
- Damage calculation from formulas
- Hyperfocus handling
- Prep threshold calculations
- Break detection with events
- Limb selection helpers (focus leg, off leg)
- Riftlock support (arm break tracking)
- Status display

**Classes that need this:**
- Monk (Shikudo/Tekura)
- Blademaster
- Knights (DWB spec)
- Any class with limb-break kills

**How to use:**
1. Include in your class offense directory
2. Customize `limbTracker.attackDamage` for your attacks
3. Call `limbTracker.addDamage(attack, limb)` on hit
4. Use `limbTracker.isLimbPrepped()` for decisions

### lock_strategy_template.lua
**Purpose:** Affliction lock progression strategies

**Includes:**
- All lock type checks (softlock, venomlock, hardlock, truelock)
- Alternative locks (focuslock, riftlock, aeonlock)
- Class-specific lock affliction mapping
- Venom selection for each strategy
- Mental stack tracking for focuslock
- Arm break tracking for riftlock
- Strategy switching
- Status display

**Strategies supported:**
- **Truelock:** Standard progression (softlock → truelock)
- **Focuslock:** Mental stack instead of impatience
- **Riftlock:** Broken arms + slickness + asthma
- **Aeonlock:** Aeon + kelp stack

**How to use:**
1. Include in your class offense
2. Call `lockStrategy.selectVenom()` for next venom
3. Use `lockStrategy.getLockLevel()` for status
4. Switch with `lockStrategy.setStrategy("focuslock")`

## Template Patterns

All templates follow consistent patterns:

### Namespace Pattern
```lua
classname = classname or {}
classname.config = classname.config or {}
classname.state = classname.state or {}
```

### Configuration Pattern
```lua
classname.config = {
  debug = false,
  mode = "lock",
  -- class-specific options
}
```

### State Pattern
```lua
classname.state = {
  phase = "SETUP",
  lastAction = nil,
  -- class-specific state
}
```

### Function Pattern
```lua
--[[
  Brief description of function purpose.

  @param paramName (type) - Description
  @return (type) - Description
]]--
function classname.functionName(param)
  -- implementation
end
```

### Status Display Pattern
```lua
function classname.status()
  cecho("\n<cyan>╔══════════════════════════════════════════════╗")
  cecho("\n<cyan>║         <white>TITLE<cyan>                              ║")
  cecho("\n<cyan>╠══════════════════════════════════════════════╣")
  -- content
  cecho("\n<cyan>╚══════════════════════════════════════════════╝")
end
```

## Integration Points

Templates integrate with LEVI-Achaea globals:

| Global | Purpose |
|--------|---------|
| `target` | Current target name |
| `tAffs` | Target affliction table |
| `tLimbs` | Target limb damage table |
| `tClass` | Target's class |
| `ataxia.vitals` | Player vitals (HP, form, kata, etc.) |
| `ataxia.balances` | Balance/equilibrium state |
| `ataxiaTemp` | Temporary combat state |

## Creating New Templates

When creating new templates:

1. Include Mudlet script header with hierarchy placeholder
2. Use namespace pattern for all code
3. Include config and state structures
4. Add TODO comments for customization points
5. Include status display function
6. Add convenience aliases
7. Include initialization message

## Database References

Templates should reference the database files:
- `.claude/databases/venoms.yaml` - Venom data
- `.claude/databases/afflictions.yaml` - Affliction data
- `.claude/databases/locks.yaml` - Lock definitions
- `.claude/databases/forms.yaml` - Shikudo forms
