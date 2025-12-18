# LEVI - Achaea Combat System

A comprehensive Lua-based combat system for Achaea MUD, designed for use with Mudlet.

## Features

- **Automatic Affliction Tracking**: Real-time monitoring of afflictions on yourself and enemies
- **Balance Management**: Tracks all balance types (equilibrium, balance, class-specific)
- **Smart Curing**: Priority-based curing system with customizable priorities
- **Offense Automation**: Ability queuing and execution system
- **User Interface**: Clean, informative displays for combat information
- **Highly Configurable**: Extensive configuration options to customize behavior

## Installation

### Prerequisites

- [Mudlet](https://www.mudlet.org/) version 4.10 or higher
- An active Achaea character

### Steps

1. Download the latest release from the [Releases](../../releases) page
2. In Mudlet, click on the "Package Manager" icon
3. Click "Install" and select the downloaded `.mpackage` file
4. Restart Mudlet or reload your profile
5. Copy `config.example.lua` to `config/user_config.lua` and customize your settings

### Manual Installation

If you prefer to install from source:

```bash
git clone https://github.com/haterade22/LEVI-Achaea.git
```

Then import the individual Lua files into your Mudlet profile or create a package.

## Quick Start

1. After installation, configure your settings:
   ```lua
   -- Edit config/user_config.lua with your preferences
   ```

2. Initialize the system in-game:
   ```
   /levi init
   ```

3. Basic commands:
   ```
   /levi help          -- Show help
   /levi status        -- Display system status
   /levi toggle        -- Toggle system on/off
   /levi reset         -- Reset all trackers
   ```

## Usage

### Curing System

The curing system automatically handles afflictions based on priority:

```lua
-- Toggle curing on/off
/levi curing on
/levi curing off

-- Adjust priorities
/levi priority <affliction> <priority>
```

### Offense System

```lua
-- Start offense
/levi offense start

-- Stop offense
/levi offense stop

-- Queue abilities
/levi queue <ability>
```

### Tracking

The system automatically tracks:
- Your afflictions
- Enemy afflictions (when visible)
- Balance states (balance, equilibrium, class balances)
- Defenses
- Resources (mana, health, etc.)

## Configuration

Edit `config/user_config.lua` to customize:

- Curing priorities
- Offense settings
- UI preferences
- Trigger sensitivity
- And more...

See `config.example.lua` for all available options.

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System design and structure
- [Contributing](CONTRIBUTING.md) - How to contribute
- [Changelog](CHANGELOG.md) - Version history

## Project Structure

```
LEVI-Achaea/
├── core/          # Core initialization and event handling
├── tracking/      # Affliction and balance tracking
├── curing/        # Curing priorities and logic
├── offense/       # Offensive abilities and queuing
├── ui/            # User interface displays
├── config/        # Configuration files
├── docs/          # Documentation
└── tests/         # Test suite
```

## Contributing

We welcome contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Report bugs or request features via [GitHub Issues](../../issues)
- **Discussions**: Join the conversation in [GitHub Discussions](../../discussions)

## Acknowledgments

- The Achaea community for combat knowledge and testing
- Mudlet development team for the excellent client

## Disclaimer

This is a third-party tool and is not officially affiliated with or endorsed by Iron Realms Entertainment or Achaea.