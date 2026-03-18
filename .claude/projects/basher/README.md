# Basher / Autobashing System

## Overview

Automated PvE hunting system for Achaea. Handles target selection, attack dispatch, pathfinding, danger detection, flee-heal-return loops, and 22+ class-specific attack implementations.

## Key Files

| File | Purpose |
|------|---------|
| `basher/001_Bashing_Functions.lua` | Attack dispatch, danger levels, flee/recovery, battlerage, emergencies |
| `basher/002_Class_Bashing.lua` | 22+ class-specific attack commands |
| `basher/003_Bash_Stats_Functions.lua` | Session kill/XP statistics |
| `basher/005_Falcon_Cooldowns.lua` | Infernal hyena maul cooldown |
| `basher/006_Pariah_Cooldown.lua` | Pariah swarm devour cooldown |
| `basher/007_Mob_Damage_DB.lua` | SQLite per-mob damage tracking |
| `genrunning/001_Bashing_API.lua` | Path generation, death/PvP handlers, events |
| `genrunning/002_search_targets.lua` | Target selection, stormhammer, legend deck |
| `genrunning/003_Engaged_Disengage.lua` | Enable/disable handlers, auto-rotation |
| `genrunning/004_Autobashing_Functions.lua` | Attack gates, throttle, patterns loop, manual/areabash toggle |
| `010_Prompt_Running.lua` | Prompt dispatch (calls basher functions) |
| `update_stuff/002_ataxia_Room_Update.lua` | Room change handler, flee return detection |

All paths relative to `src_new/scripts/levi_ataxia/levi/ataxia/`.

## Documentation

| Doc | Contents |
|-----|----------|
| [01-architecture.md](01-architecture.md) | State machine, dispatch chain, gate sequence |
| [02-configuration.md](02-configuration.md) | All settings, thresholds, safe rooms, target lists |
| [03-flee-heal-return.md](03-flee-heal-return.md) | Flee-heal-return loop, state vars, edge cases |
| [04-pathfinding.md](04-pathfinding.md) | Area bash, path generation, stuck detection |
| [05-safety-systems.md](05-safety-systems.md) | Danger levels, PvP detection, death handling, circuit breakers |
