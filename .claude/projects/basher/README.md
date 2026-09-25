# Basher / Autobashing System

## Overview

Automated PvE hunting system for Achaea. Handles target selection, auto-learning of area denizens (with own-denizen exclusion for pets/allies), attack dispatch, pathfinding, danger detection, flee-heal-return loops (with no-flee areas that shield instead), and 22+ class-specific attack implementations.

## Key Files

| File | Purpose |
|------|---------|
| `basher/001_Bashing_Functions.lua` | Attack dispatch, danger levels, flee/recovery, battlerage, emergencies |
| `basher/002_Class_Bashing.lua` | 22+ class-specific attack commands |
| `basher/003_Bash_Stats_Functions.lua` | Session kill/XP statistics |
| `basher/005_Falcon_Cooldowns.lua` | Knight pet cooldowns: Infernal hyena maul + Runewarden falcon rake (~30s each) |
| `basher/006_Pariah_Cooldown.lua` | Pariah swarm devour cooldown |
| `basher/007_Mob_Damage_DB.lua` | SQLite per-mob damage tracking |
| `basher/008_Denizen_State.lua` | Per-denizen combat state (`ataxiaTemp.denizenState[id]`) + `ataxiaBasher_BR_AFFS` battlerage-affliction model; PvP-inert. Fed by `denizen_attacks_misc_lines/011-020` (charm/recklessness/aeon/weakness/stun applied+ended), the `010` HP feed / `003` sync. Drives the `ataxiaBasher_blademasterBattlerage` rotation (in `001`). Stages 1-2 of the [basher overhaul](denizen-lines-catalog.md) |
| `basher/013_Mounts.lua` | Our mounts: learned by ID from the mounts listing and skipped as targets (never by name -- "a massive dire wolf" is also a real denizen); VAULT makes that mount active; the MOUNTED belief (`ataxiaTemp.mounted`) and the jump verb (`mountjump` vs `leap`), with both refusal recoveries (v4.7.335-351) |
| `basher/014_Dead_Breath.lua` | The necromancy boon riders: BELCH (Dead Breath) and SOULSTORM (Deathtempest), both equilibrium riders on any class's round (v4.7.336-343) |
| `genrunning/001_Bashing_API.lua` | Path generation, death/PvP handlers, events; `onDeath` also forgets the mount belief (v4.7.351) |
| `genrunning/002_search_targets.lua` | Target selection, stormhammer, legend deck |
| `genrunning/003_Engaged_Disengage.lua` | Enable/disable handlers, auto-rotation |
| `genrunning/004_Autobashing_Functions.lua` | Attack gates, throttle, patterns loop, manual/areabash toggle; `ataxiaBasher_requeueNow` re-queues the round when the state it was built from changes (v4.7.352) |
| `010_Prompt_Running.lua` | Prompt dispatch (calls basher functions) |
| `update_stuff/002_ataxia_Room_Update.lua` | Room change handler, flee return detection, Mnemosyne no-flee flag clear |
| `update_stuff/003_ataxia_RoomContents_Update.lua` | Denizen list population, auto-learn (skips own denizens) |

All paths relative to `src_new/scripts/levi_ataxia/levi/ataxia/`.

## Documentation

| Doc | Contents |
|-----|----------|
| [01-architecture.md](01-architecture.md) | State machine, dispatch chain, gate sequence |
| [02-configuration.md](02-configuration.md) | All settings, thresholds, safe rooms, target lists |
| [03-flee-heal-return.md](03-flee-heal-return.md) | Flee-heal-return loop, state vars, edge cases |
| [04-pathfinding.md](04-pathfinding.md) | Area bash, path generation, stuck detection |
| [05-safety-systems.md](05-safety-systems.md) | Danger levels, PvP detection, death handling, circuit breakers |
| [battlerage-pve.md](battlerage-pve.md) | **Battlerage for PvE** — rage mechanics + global cooldown, all 10 denizen afflictions (what each does + tactical value, mitigation-first), how the rotation uses them, Blademaster's kit |
| [denizen-lines-catalog.md](denizen-lines-catalog.md) | Better-Blademaster-basher overhaul: our-attack / battlerage / denizen-affliction line catalog + BR spec; per-denizen state model; staged rollout |
