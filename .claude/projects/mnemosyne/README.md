# Mnemosyne Mod System

## Overview

Mnemosyne (the "tides of memory") is an endless tower-climb PvE mod in Achaea: each *ripple* is a fresh 4×4 room layout you fight through, choosing *boons* between waves, until you die or `WADE LEAVE` (there is no victory). This subsystem does four things as you play: (1) **reports run telemetry** — ripple depth, monsters, boss, ongoing effects, boons offered/selected, deaths — to an external community run tracker via HTTP POST; (2) draws a **per-ripple mini-map** built from the room exit graph, with click-to-walk; (3) keeps a **local run history** you can review in-client, plus an all-time affix library; and (4) can **auto-sweep the 4×4** — clearing each room and stopping at the boon screen. Everything lives under the `ataxia.mnemosyne` namespace and is driven by triggers on the game's Mnemosyne text.

This is distinct from the basher's Mnemosyne handling: the basher treats Mnemosyne as a **no-flee bashing area** (`ataxiaBasher.inMnemosyne`, trigger `351_Mnemosyne_Survey`), covered in the [basher safety-systems doc](../basher/05-safety-systems.md#no-flee-areas). This subsystem is the telemetry + mapping + history + auto-explore layer; the auto-explorer *drives* the basher (in manual mode) rather than replacing it.

## Key Files

| File | Purpose |
|------|---------|
| `mnemosyne/001_HTTP_Client.lua` | Serial POST queue, config helpers, gating (`_auto`/`_inRun`), health check |
| `mnemosyne/002_Reporter_API.lua` | One function per endpoint + in-memory run state (buffers, ripple, offered boons) |
| `mnemosyne/003_Commands.lua` | `mnem` command dispatch (config + manual endpoint overrides) |
| `mnemosyne/004_Parsers.lua` | Game-text parsers: block capture, `_extractMob`, monster capture, boon enrichment |
| `mnemosyne/005_Ripple_Map.lua` | Per-ripple room graph (data model + movement/room hooks) |
| `mnemosyne/006_Ripple_Map_Window.lua` | Draggable grid widget, render, click-to-walk |
| `mnemosyne/007_History.lua` | Local per-run history + reports (boons/affixes/library) |
| `mnemosyne/008_Explorer.lua` | Auto-sweep the 4×4 (drives the basher in manual mode) |

Script paths relative to `src_new/scripts/levi_ataxia/levi/ataxia/`. Triggers live in `src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/` (`001`–`009` + `011_Ice_Slip`); aliases in `src_new/aliases/levi_ataxia/for_levi/levi_062424/mnemosyne/` (`001`–`002`).

## Documentation

| Doc | Contents |
|-----|----------|
| [01-architecture.md](01-architecture.md) | Run lifecycle, event flow, run-state model, gating (`_auto`/`_inRun`) |
| [02-reporting.md](02-reporting.md) | HTTP client (serial queue, watchdog, error recovery) + Reporter API endpoints and payloads |
| [03-parsing-triggers.md](03-parsing-triggers.md) | Trigger→handler table, block capture, deterministic monster capture, `_extractMob`, boon claim/contemplate |
| [04-ripple-map.md](04-ripple-map.md) | Room graph build, grid placement, BFS pathfinding, the widget + click-to-walk |
| [05-commands.md](05-commands.md) | `mnem` subcommands and the `BOON CLAIM` intercept |
| [06-history.md](06-history.md) | Local run history, the affix library, and the `mnem boons/affixes/library/quiet` reports |
| [07-explorer.md](07-explorer.md) | The `mnem explore` auto-sweep: state machine, navigation, basher integration |

## Persistence

Config lives in `ataxia.settings.reporting` (`enabled`, `contemplate`, `token`, `url`, `debug`, `mapEnabled`, `quiet`) — saved inside the main `ataxia` settings file via `ataxia_saveSettings()`, no new disk file. **Run state is in-memory only** (`ataxia.mnemosyne.run`); on load it re-syncs via `/run_exists` (the server is the source of truth). The **local history** (`ataxia.mnemosyne.history`) is the one thing persisted to its own file, `<profile>/mnemosyne_history.lua` (see [06-history.md](06-history.md)).
