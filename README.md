# LEVI-Achaea

Mudlet automation scripts for [Achaea](https://www.achaea.com/), an Iron Realms Entertainment MUD.

## Overview

This repository contains the "For Levi" Mudlet package, a comprehensive automation system featuring:

- **Mudlet Mapper (mmp)** - Advanced pathfinding and navigation
- **Ataxia Combat System** - Affliction tracking, defense management, and combat automation
- **Player Database (ataxiaNDB)** - API integration for tracking other players
- **Custom GUI** - Health bars, map display, and tabbed chat

## Features

### Navigation
- Speedwalking with automatic path recalculation
- Fast travel integration (wings, tarot, harness)
- Balance-aware movement
- Multi-game support (Achaea, Aetolia, Lusternia, Imperian)

### Combat
- 100+ affliction tracking with color-coded display
- Limb damage tracking (self and enemy)
- Automatic parrying and defense management
- Automated hunting/bashing with safety features

### Utilities
- Player database with Achaea API integration
- City-based name highlighting
- GMCP-based chat organization
- Persistent settings storage

## Installation

1. Download the compiled `.mpackage` or `.xml` from `packages/` (or build from source — see below)
2. In Mudlet, go to Package Manager
3. Install the package file

## Building from Source

The project uses [Muddler](https://github.com/demonnic/muddler) to build packages. Requires **Java 8+**.

```bash
# Convert source to Muddler format
python tools/convert_to_muddler.py --src ./src_new --output ./muddler_project

# Build with Muddler (set JAVA_HOME first)
set JAVA_HOME=E:\Java
cd muddler_project
E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\bin\muddle.bat
```

Output: `muddler_project/build/Levi_Ataxia.mpackage`

### Building a Custom Package

The conversion script supports building separate standalone packages from the same source tree. Use CLI arguments to override the package name and root group filter:

```bash
python tools/convert_to_muddler.py --src ./src_new --output ./my_package_project \
  --package-name My_Package --package-title "My Package" --include-roots My_Package

set JAVA_HOME=E:\Java
cd my_package_project
E:\muddle-shadow-1.1.0\muddle-shadow-1.1.0\bin\muddle.bat
```

See `python tools/convert_to_muddler.py --help` for all options.

## Visual Studio 2022

Open `LEVI-Achaea.sln` in VS2022 to browse all source files with Solution Explorer and build via Ctrl+B. The solution is a Makefile project that runs the convert + Muddler pipeline automatically.

## Documentation

- [Legend Deck Reference](docs/legend-deck.md) - All cards, effects, and PVE guide
- [Plans](docs/plans/) - Detailed system documentation and reviews

## Technology

- **Language**: Lua
- **Platform**: Mudlet MUD Client
- **Target Game**: Achaea (IRE)

## License

Private use - For Levi
