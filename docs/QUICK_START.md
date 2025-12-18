# Quick Start Guide

This guide will help you get started with LEVI quickly.

## Installation

1. **Download LEVI**
   - Download the latest release from the [Releases page](https://github.com/haterade22/LEVI-Achaea/releases)
   - Or clone the repository: `git clone https://github.com/haterade22/LEVI-Achaea.git`

2. **Install in Mudlet**
   - Open Mudlet
   - Go to Package Manager
   - Click "Install" and select the downloaded `.mpackage` file
   - Restart Mudlet or reload your profile

3. **Configure**
   - Copy `config.example.lua` to `config/user_config.lua`
   - Edit `config/user_config.lua` with your preferences

## First Steps

### Initialize the System

After installation, initialize LEVI in-game:

```
/levi init
```

### Check System Status

Verify everything is working:

```
/levi status
```

### Configure Your Class

Edit `config/user_config.lua` and set your character's class:

```lua
config.general = {
  character_class = "runewarden",  -- Change to your class
  auto_start = true,
}
```

## Basic Usage

### Curing System

The curing system works automatically once enabled:

```
/levi curing on     -- Enable automatic curing
/levi curing off    -- Disable automatic curing
/levi curing status -- Check curing status
```

### Target Management

Set and manage combat targets:

```
/levi target <name>  -- Set target
/levi target clear   -- Clear target
```

### View Afflictions

Your afflictions are automatically tracked and displayed in the UI. You can also check them manually:

```
/levi affs           -- Show your current afflictions
```

## Customization

### Adjust Cure Priorities

Edit `config/user_config.lua` to customize cure priorities:

```lua
config.curing = {
  priorities = {
    anorexia = 95,    -- Critical
    asthma = 92,      -- Critical
    paralysis = 85,   -- High
    clumsiness = 60,  -- Medium
    lovers = 30,      -- Low
  }
}
```

### Configure UI

Adjust UI settings in your config:

```lua
config.ui = {
  enabled = true,
  theme = "dark",  -- or "light"
  show_afflictions = true,
  show_balances = true,
  show_target = true,
}
```

## Getting Help

- Type `/levi help` for a list of commands
- Check the [full documentation](README.md)
- Report issues on [GitHub](https://github.com/haterade22/LEVI-Achaea/issues)

## Next Steps

- Read the [Architecture](../ARCHITECTURE.md) to understand how LEVI works
- Explore advanced features like offense automation
- Join the community to share strategies and get help

## Troubleshooting

### System Not Starting

1. Check that all files are properly installed
2. Verify your Mudlet version is 4.10 or higher
3. Check the Mudlet error console for messages

### Curing Not Working

1. Verify curing is enabled: `/levi curing status`
2. Check your cure priorities in the config
3. Ensure you have the necessary items (herbs, etc.)

### UI Not Showing

1. Check that UI is enabled in config
2. Verify window positions are visible on your screen
3. Try resetting the UI: `/levi ui reset`
