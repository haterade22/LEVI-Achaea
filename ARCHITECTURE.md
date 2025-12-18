# LEVI Architecture Documentation

## Overview

LEVI (Lua Enhanced Virtual Intelligence) is a modular combat system for Achaea MUD, built with maintainability and extensibility in mind. The system is organized into distinct modules, each with a specific responsibility.

## Design Principles

1. **Modularity**: Each module has a single, well-defined purpose
2. **Loose Coupling**: Modules communicate through events and well-defined interfaces
3. **Configurability**: All behavior can be customized through configuration
4. **Testability**: Code is written to be easily testable
5. **Performance**: Optimized for real-time combat scenarios

## Module Architecture

### Core Module (`/core`)

**Purpose**: System initialization, event management, and core utilities.

**Key Components**:
- `init.lua`: Main initialization script, loads all modules
- `events.lua`: Event bus for inter-module communication
- `utils.lua`: Shared utility functions
- `state.lua`: Global state management

**Responsibilities**:
- Initialize all system modules in correct order
- Set up event handlers and communication channels
- Provide logging and debugging capabilities
- Manage system lifecycle (start, stop, reset)

**Event Flow**:
```
Game Event → Core Event Handler → Event Bus → Module Handlers → Actions
```

### Tracking Module (`/tracking`)

**Purpose**: Monitor and track game state changes.

**Key Components**:
- `afflictions.lua`: Track player and enemy afflictions
- `balances.lua`: Monitor balance, equilibrium, and class-specific balances
- `defenses.lua`: Track active defenses and defs
- `resources.lua`: Monitor health, mana, endurance, willpower
- `enemies.lua`: Track enemy states and information

**Data Structures**:
```lua
-- Affliction tracking
afflictions = {
    player = {
        ["asthma"] = {gained = timestamp, source = "enemy"},
        ["paralysis"] = {gained = timestamp, source = "venom"}
    },
    target = {
        ["asthma"] = {given = timestamp, confirmed = true}
    }
}

-- Balance tracking
balances = {
    balance = true,
    equilibrium = true,
    class_balance = {name = "tree", available = true},
    last_recovery = {balance = timestamp, eq = timestamp}
}
```

### Curing Module (`/curing`)

**Purpose**: Automated affliction curing based on priorities.

**Key Components**:
- `priorities.lua`: Affliction cure priority definitions
- `logic.lua`: Curing decision engine
- `methods.lua`: Available curing methods (herbs, pipes, salves, etc.)
- `queue.lua`: Cure action queue management

**Curing Algorithm**:
```
1. Gather current afflictions from tracking
2. Filter available curing methods (check balances)
3. Sort afflictions by priority
4. Select highest priority curable affliction
5. Execute cure action
6. Queue next cure if multiple afflictions present
```

**Priority Tiers**:
- **Critical**: Life-threatening (anorexia, asthma, paralysis while prone)
- **High**: Significant combat impact (impatience, clumsiness)
- **Medium**: Moderate impact (nausea, weariness)
- **Low**: Minor annoyances (lovers, peace)

### Offense Module (`/offense`)

**Purpose**: Automated offense execution and ability queuing.

**Key Components**:
- `abilities.lua`: Class-specific ability definitions
- `queuing.lua`: Ability queue management
- `strategy.lua`: Offense strategy and target selection
- `combos.lua`: Pre-defined ability combinations

**Offense Flow**:
```
Strategy → Target Selection → Ability Queue → Execution (on balance) → Track Results
```

**Queue System**:
```lua
offense_queue = {
    {ability = "dsl", args = {"curare", "kalmia"}, priority = 1},
    {ability = "envenom", args = {"sword", "xentio"}, priority = 2}
}
```

### UI Module (`/ui`)

**Purpose**: Display combat information to the user.

**Key Components**:
- `gauges.lua`: Health, mana, and resource gauges
- `affliction_display.lua`: Shows current afflictions
- `balance_display.lua`: Shows balance states
- `target_display.lua`: Shows target information
- `status_bar.lua`: Overall system status

**Display Types**:
- **Gauges**: Graphical bars for resources
- **Tables**: Structured data (afflictions list)
- **Labels**: Status indicators
- **Notifications**: Event-based alerts

### Config Module (`/config`)

**Purpose**: Store and manage configuration settings.

**Key Components**:
- `default_config.lua`: Default configuration values
- `user_config.lua`: User-specific overrides (gitignored)
- `loader.lua`: Configuration loading and merging

**Configuration Structure**:
```lua
config = {
    curing = {
        enabled = true,
        priorities = {...},
        methods = {...}
    },
    offense = {
        enabled = false,
        strategy = "balance",
        targets = {...}
    },
    ui = {
        theme = "dark",
        positions = {...},
        gauges = {...}
    }
}
```

## Data Flow

### Affliction Tracking Flow

```
[Game Output] 
    → [Trigger Match] 
    → [Tracking.afflictions.add(aff)]
    → [Event: affliction_gained]
    → [Curing.queue_cure(aff)]
    → [UI.update_display()]
```

### Curing Flow

```
[Event: affliction_gained]
    → [Curing.assess()]
    → [Check priorities & balances]
    → [Curing.execute(cure)]
    → [Send cure command]
    → [Wait for cure confirmation]
    → [Event: affliction_cured]
    → [Tracking.afflictions.remove(aff)]
```

### Offense Flow

```
[Event: balance_recovered]
    → [Offense.check_queue()]
    → [Select next ability]
    → [Check prerequisites]
    → [Execute ability]
    → [Track ability use]
    → [Update displays]
```

## Event System

The system uses a publish-subscribe event system for loose coupling:

**Core Events**:
- `system_initialized`: System startup complete
- `balance_gained`, `balance_lost`: Balance state changes
- `equilibrium_gained`, `equilibrium_lost`: Equilibrium state changes
- `affliction_gained`, `affliction_cured`: Affliction tracking
- `defense_gained`, `defense_lost`: Defense tracking
- `target_changed`: Combat target changed
- `offense_action`: Offensive action executed

**Event Registration**:
```lua
-- Subscribe to an event
events.register("affliction_gained", function(affliction)
    -- Handle affliction
end)

-- Publish an event
events.raise("affliction_gained", {name = "asthma", source = "venom"})
```

## Performance Considerations

1. **Lazy Loading**: Modules loaded only when needed
2. **Event Throttling**: Prevent event spam with rate limiting
3. **Efficient Data Structures**: Use hash tables for O(1) lookups
4. **Minimal GMCP Spam**: Batch updates where possible
5. **Cached Calculations**: Store computed values, invalidate on change

## Testing Strategy

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test module interactions
3. **Simulation Tests**: Simulate combat scenarios
4. **Performance Tests**: Measure timing and resource usage

## Extension Points

### Adding New Afflictions

1. Add to `tracking/afflictions.lua`
2. Add cure method to `curing/methods.lua`
3. Add priority to `curing/priorities.lua`
4. Add triggers to detect gain/cure

### Adding New Class

1. Create abilities file in `offense/classes/`
2. Define class-specific balances in `tracking/balances.lua`
3. Add class strategies to `offense/strategy.lua`
4. Add UI elements for class resources

### Custom Strategies

1. Create strategy file in `offense/strategies/`
2. Implement strategy interface
3. Register strategy with offense module
4. Configure via user_config.lua

## Security Considerations

1. **Input Validation**: All user input is validated
2. **No eval()**: No dynamic code execution from game
3. **Safe Defaults**: Fail safely if configuration is invalid
4. **Resource Limits**: Prevent infinite loops and memory leaks

## Future Enhancements

- Machine learning for affliction prediction
- Web-based configuration interface
- Cloud sync for settings
- Team combat coordination
- Replay and analysis tools
