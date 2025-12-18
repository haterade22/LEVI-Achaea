# LEVI-Achaea Project Summary

## Project Overview
LEVI (Lua Enhanced Virtual Intelligence) is a comprehensive combat system for Achaea MUD, built for use with the Mudlet client.

## Repository Structure

### Core Directories
- **/core** - System initialization, event management, state management, and utilities
- **/tracking** - Affliction tracking, balance tracking, and game state monitoring
- **/curing** - Automated curing system with priority-based logic
- **/offense** - Offensive abilities and queuing system
- **/ui** - User interface displays and gauges
- **/config** - Configuration management and example files
- **/docs** - Additional documentation and guides
- **/tests** - Test suite for system validation

### Key Files Created

#### Documentation
- **README.md** - Comprehensive project overview with installation and usage
- **ARCHITECTURE.md** - Detailed system architecture documentation
- **CONTRIBUTING.md** - Contribution guidelines and development process
- **CHANGELOG.md** - Version history tracking
- **LICENSE** - MIT License
- **docs/README.md** - Documentation index
- **docs/QUICK_START.md** - Quick start guide for new users

#### Configuration
- **config.example.lua** - Extensive example configuration with all options
- **config/loader.lua** - Configuration loading and management system
- **.gitignore** - Lua/Mudlet specific gitignore rules

#### Core System (Lua Modules)
- **core/init.lua** - Main initialization and module loading
- **core/events.lua** - Event bus for inter-module communication
- **core/utils.lua** - Common utility functions
- **core/state.lua** - Global state management

#### Tracking System
- **tracking/afflictions.lua** - Player and enemy affliction tracking
- **tracking/balances.lua** - Balance, equilibrium, and class-specific balance tracking

#### Curing System
- **curing/priorities.lua** - Affliction cure priority definitions
- **curing/logic.lua** - Main curing decision engine

#### Offense System
- **offense/abilities.lua** - Ability definitions and execution
- **offense/queuing.lua** - Action queue management

#### UI System
- **ui/display.lua** - Display management and updates

#### Testing
- **tests/run_tests.lua** - Test suite and test runner

#### GitHub Integration
- **.github/ISSUE_TEMPLATE/bug_report.md** - Bug report template
- **.github/ISSUE_TEMPLATE/feature_request.md** - Feature request template
- **.github/workflows/lua-lint.yml** - GitHub Actions workflow for Lua linting
- **.github/workflows/markdown-link-check-config.json** - Markdown link validation config

## Features Implemented

### System Architecture
- Modular design with clear separation of concerns
- Event-driven architecture for loose coupling
- Configurable and extensible framework

### Tracking
- Real-time affliction tracking (self and enemies)
- Balance state monitoring (balance, equilibrium, class-specific)
- Resource tracking (health, mana, etc.)

### Curing
- Priority-based automatic curing
- Configurable cure priorities
- Balance-aware cure execution

### Offense
- Ability queuing system
- Priority-based action execution
- Class-specific ability definitions

### UI
- Modular display system
- Event-based updates
- Configurable layouts

### Configuration
- Comprehensive example configuration
- User-specific config override support
- Runtime configuration loading

### Testing
- Test framework with assertions
- Core module tests
- Expandable test suite

### Development Tools
- GitHub Actions for automated Lua linting
- Issue templates for bug reports and features
- Comprehensive contribution guidelines

## Code Quality

### Documentation
- Inline LDoc-style documentation in all modules
- Comprehensive README with installation and usage
- Architecture documentation explaining design decisions
- Contributing guidelines for new developers

### Standards
- Consistent code style (2-space indentation, snake_case)
- Clear module structure
- Event-driven communication
- Error handling with pcall

## Getting Started

1. Clone the repository
2. Copy config.example.lua to config/user_config.lua
3. Customize your configuration
4. Install in Mudlet
5. Initialize with `/levi init`

## Next Steps

Future enhancements could include:
- Additional class-specific modules
- Advanced AI strategies
- Machine learning integration
- Web-based configuration UI
- Replay and analysis tools
- Cloud configuration sync

## License
MIT License - See LICENSE file for details
