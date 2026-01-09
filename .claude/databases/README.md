# Claude Skill Files

This directory contains structured data files and code templates for Claude AI to use when developing Achaea combat systems.

## Directory Structure

```
.claude/
├── databases/           # Structured YAML data files
│   ├── venoms.yaml      # All venoms, their afflictions, and cure methods
│   ├── afflictions.yaml # All afflictions with cures and properties
│   ├── locks.yaml       # Lock types, progressions, and escape routes
│   ├── forms.yaml       # Shikudo stances, transitions, and attacks
│   └── README.md        # This file
├── templates/           # Lua code templates
│   ├── offense_template.lua      # Generic offense system template
│   ├── limb_tracking_template.lua # Limb damage tracking system
│   └── lock_strategy_template.lua # Lock progression strategies
└── classes/             # Per-class reference files
    ├── README.md
    ├── lock_types.md
    └── [class].md       # 26 class files
```

## Databases

### venoms.yaml
Complete reference for all Achaea venoms including:
- Affliction delivered by each venom
- Cure method (herb/mineral/salve/smoke)
- Role in lock strategies
- Priority levels
- Ekanelia transformations for Serpent

**Example usage:**
```lua
-- Claude can reference venom data like:
-- kalmia -> asthma (kelp cure, softlock component, priority: critical)
```

### afflictions.yaml
Comprehensive affliction database including:
- Cure method and herb/salve/smoke required
- Effect on the target
- Delivery methods (which attacks/venoms)
- Lock component role
- Priority for curing
- Class-specific notes

**Categories:**
- Eating cures (kelp, bloodroot, ginseng, goldenseal, lobelia, ash, bellwort)
- Salve cures (epidermal, mending, restoration)
- Smoke cures (elm, valerian)
- Writhe afflictions
- Special (focus, tree, clot, sip)

### locks.yaml
Lock type definitions including:
- Required afflictions for each lock level
- Escape routes and vulnerabilities
- Check functions (Lua code)
- Class-specific lock afflictions
- Alternative lock strategies (focuslock, riftlock, aeonlock)

**Lock Progression:**
1. Softlock (asthma + anorexia + slickness)
2. Venomlock (+ paralysis)
3. Hardlock (+ impatience)
4. Truelock (+ class-specific affliction)

### forms.yaml
Shikudo stance system for Monks including:
- All 6 forms (Tykonos, Willow, Rain, Oak, Gaital, Maelstrom)
- Available attacks per form
- Transition rules
- Damage values
- Telepathy abilities
- Kill conditions

## Templates

### offense_template.lua
Generic template for building a class offense system. Includes:
- Namespace initialization pattern
- Configuration structure
- Lock detection functions
- Venom selection logic
- Attack building
- Status display

**Usage:**
1. Copy to your class directory
2. Replace "classname" with your class
3. Customize attack selection logic
4. Add class-specific abilities

### limb_tracking_template.lua
Template for limb damage tracking. Includes:
- Damage calculation formulas
- Prep threshold helpers
- Break detection
- Limb selection logic
- Riftlock support

**Usage:**
1. Include in any limb-based offense
2. Customize damage values for your class
3. Integrate with offense system

### lock_strategy_template.lua
Complete lock strategy implementation. Includes:
- All lock type checks
- Class-specific lock afflictions
- Venom selection for each strategy
- Multiple lock strategies (truelock, focuslock, riftlock, aeonlock)
- Status display

## Usage Guidelines

### For Claude AI

When developing offense systems:

1. **Read the databases first** to understand game mechanics
2. **Use templates as starting points** - don't reinvent patterns
3. **Follow the namespace pattern** (`classname = classname or {}`)
4. **Include lock detection** from locks.yaml
5. **Reference venoms.yaml** for venom selection

### Key Patterns

**Namespace initialization:**
```lua
classname = classname or {}
classname.config = classname.config or {}
classname.state = classname.state or {}
```

**Lock checking:**
```lua
function classname.checkSoftlock()
  return tAffs.asthma and tAffs.anorexia and tAffs.slickness
end
```

**Venom selection:**
```lua
function classname.selectVenom()
  if not tAffs.asthma then return "kalmia" end
  if not tAffs.slickness then return "gecko" end
  -- etc.
end
```

**Attack queuing:**
```lua
send("queue addclear free " .. cmd)
```

## Integration with Existing Code

The skill files integrate with existing LEVI-Achaea systems:

- `tAffs` - Target affliction tracking table
- `tLimbs` - Target limb damage tracking
- `ataxia.vitals` - Player vitals from GMCP
- `ataxia.balances` - Balance/equilibrium tracking
- `target` - Current target name

## Updating These Files

When Achaea mechanics change:
1. Update the relevant YAML database
2. Update any affected templates
3. Commit with clear changelog

## Reference

- **CLAUDE.md** - Main AI development guide
- **AGENTS.md** - AI agent guidelines
- **classes/lock_types.md** - Detailed lock documentation
