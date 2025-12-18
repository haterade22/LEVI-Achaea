# LEVI-Achaea Project

## Project Overview
This repository contains Mudlet automation scripts for **Achaea** (an Iron Realms Entertainment MUD). The primary package is "For Levi" which includes the Mudlet Mapper and Ataxia combat system.

## Technology Stack
- **Language**: Lua (Mudlet scripting)
- **Platform**: Mudlet MUD Client
- **Target Game**: Achaea (with support for other IRE games)
- **Data Format**: XML (Mudlet package format)

## Key Components

### Mudlet Mapper (mmp)
- Pathfinding and navigation automation
- Speedwalking with balance detection
- Fast travel integration (wings, tarot, etc.)
- Multi-game support

### Ataxia Combat System
- Affliction tracking (100+ afflictions)
- Limb damage tracking
- Automated hunting/bashing
- Custom GUI with Geyser
- Player database (ataxiaNDB)

## File Structure
```
LEVI-Achaea/
├── .claude/
│   └── commands/           # Custom Claude Code slash commands
├── docs/
│   └── plans/              # Project plans and reviews
├── CLAUDE.md               # This file
└── README.md               # Project readme
```

## Development Guidelines

### Lua Code Style
- Use proper namespacing (`mmp`, `ataxia`, `ataxiagui`, `ataxiaNDB`)
- Register event handlers with `registerAnonymousEventHandler()`
- Use GMCP for game data integration
- Validate settings with type checks

### Mudlet Patterns
- Scripts go in `<Script>` tags with `<eventHandlerList>` for events
- Triggers use regex or substring matching
- Aliases handle user input commands
- Use `tempTimer()` for delayed actions

## Plans Location
All project plans and reviews are stored in `docs/plans/`

## External Resources
- [Mudlet Documentation](https://wiki.mudlet.org)
- [Achaea API](http://api.achaea.com)
- [IRE Mapping Script Wiki](http://wiki.mudlet.org/w/IRE_mapping_script)
