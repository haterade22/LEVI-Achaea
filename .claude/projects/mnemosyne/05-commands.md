# Commands & Boon-Claim Intercept

The `mnem` alias is the operator surface for the run tracker: config toggles, a map control, and a manual override for every reporter endpoint. A second alias silently intercepts the player's own `BOON CLAIM` and auto-reports the selection. Run lifecycle and payloads live in [01-architecture.md](01-architecture.md) and [02-reporting.md](02-reporting.md); this doc is just the command layer.

## The alias layer

Alias `001_Mnemosyne.lua` (regex `^mnem(?:osyne)?(?:\s+(.*))?$`) matches `mnem` or `mnemosyne` and forwards the captured remainder into the dispatcher:

```lua
ataxia.mnemosyne.command(matches[2])
```

`M.command(rest)` (in `003_Commands.lua`) trims the line, splits it into `<cmd> <arg>` via `^(%S*)%s*(.-)$`, lowercases `cmd`, and runs one big `if/elseif` chain. Bare `mnem` (or `mnem status`) shows status; any unrecognised subcommand falls through to `M.help()`.

## `mnem` subcommands

Every row below is a branch that `M.command` actually dispatches — nothing else is a command.

### Config

| Command | Effect |
|---------|--------|
| `mnem status` (or bare `mnem`) | `M.status()` — echoes URL, token set?, auto on/off, contemplate on/off, and current run state (active, ripple, id) |
| `mnem token <token>` | Save `cfg.token`; persists via `ataxia_saveSettings(false)`. Empty arg prints usage |
| `mnem on` | `cfg.enabled = true`, save, then `M.runExists()` to resync in case you enabled mid-run |
| `mnem off` | `cfg.enabled = false`, save |
| `mnem contemplate` | Toggle `cfg.contemplate` (boon enrichment via `BOON CONTEMPLATE`), save |
| `mnem debug` | Toggle `cfg.debug` (verbose `M.decho` echoes) — **not persisted** |
| `mnem quiet [on\|off]` | Toggle/force `cfg.quiet` (silences the automatic boon/affix history echoes; still records), save. See [06-history.md](06-history.md) |
| `mnem test` (or `mnem health`) | `M.testHealth()` — ping `GET /health` for connectivity |
| `mnem help` | Any unknown subcommand also lands here — prints the command reference |

`on`/`off`/`quiet` (and the map/explore toggles below) resolve their argument through `M._toggleState(arg, current)` — `"on"→true`, `"off"→false`, anything else → a plain toggle — so `mnem quiet off` genuinely forces off rather than toggling.

### Ripple map

Guarded by `if ataxia.mnemosyne.map then`; see [04-ripple-map.md](04-ripple-map.md).

| Command | Effect |
|---------|--------|
| `mnem map` | `map.toggle(nil)` — flip the mini-map |
| `mnem map on` / `mnem map off` | `map.toggle(true)` / `map.toggle(false)` — force state (persists `mapEnabled`) |
| `mnem map status` | `map.status()` — diagnostic echo |

### Local history (see [06-history.md](06-history.md))

| Command | Effect |
|---------|--------|
| `mnem boons` | `M.reportBoons()` — this run's claimed boons (rarity, echoes, ripple, description) |
| `mnem affixes` | `M.reportAffixes()` — this run's active affixes (ongoing effects) |
| `mnem library` | `M.reportLibrary()` — the all-time affix catalogue |

### Auto-explorer (see [07-explorer.md](07-explorer.md))

| Command | Effect |
|---------|--------|
| `mnem explore` | `M.exploreToggle()` — start/stop the 4×4 auto-sweep |
| `mnem explore on` / `mnem explore off` | `M.exploreOn()` / `M.exploreOff()` — force state |
| `mnem explore status` | `M.exploreStatus()` — diagnostic (`inMnem`/denizens/moving/next step) |
| `mnem swarm` | `M.swarm.status()` — swarm-tactics state/threshold/recon |
| `mnem swarm on` / `off` | Toggle multi-mob tactics (persisted, `swarm.enabled`) |
| `mnem swarm assess <n>` | Pull threshold (default 3) |
| `mnem swarm deep <ripple> <n>` / `deep off` | Depth-scaled threshold at/past a ripple |
| `mnem swarm icewall on\|off` / `kite on\|off` / `panic on\|off` / `escape on\|off` | Per-branch toggles (all branches LIVE) |
| `mnem swarm panicat <hp%>` | Roll Hide panic threshold (default **35** since v4.7.218; also fires on the absolute `panicHp` floor, 3000, whichever is crossed first) |
| `mnem swarm escapeat <hp%>` | Low-HP escape threshold (default 35) |
| `mnem swarm recoverat <hp%>` | Recovery hover lands at this HP (default 95; also requires aff-free) |
| `mnem sense` | `M.swarm.sense()` — manual fullsense recon (Sleuth boon reveals all denizens; Bloodscent auto-recons every ripple entry unprompted — trigger 028 parses either source's `You sense <mob> (#id) at <room>.` rows into per-room counts) |

### Legend deck auto-draw

The state-keyed legend-deck layer lives in the basher (`basher/010_Mnemosyne_Legend_Deck.lua`, config table `ataxiaBasher.mnemLdeck`) and is driven from the attack build (`ataxiaBasher_mnemLdeck`, called out of `basher/001_Bashing_Functions.lua`); only its **operator surface** is here, since the layer only ever runs in the tower. The whole branch is guarded on that table existing — without it the command echoes `Legend deck layer not loaded.` and does nothing.

| Command | Effect |
|---------|--------|
| `mnem cards` | `ataxiaBasher_mnemLdeckStatus()` — ON/OFF and the three thresholds, then one row per card: charges left (`ldm.getCharges`), its minimum redraw interval, and for the affliction cards whether this class has a battlerage payoff at all (`-- stun, 25 rage`, `(payoff on cooldown)`, or `-- no stun payoff as <class>`) |
| `mnem cards on` / `mnem cards off` | `mnemLdeck.enabled` — the master switch (default on) |
| `mnem cards maran <hp%>` | HP at or below which the 5000hp room barrier is drawn (default `20`; accepted `5`–`90`) |
| `mnem cards seasone <hp%>` | HP at or below which `SEASONE FOR ELIXIR` (+10% health elixir) is drawn (default `35`; accepted `5`–`90`) |
| `mnem cards matic <n>` | Denizen count at or above which the guaranteed-crit card is drawn (default `3`; accepted `n >= 2`) |

Only the master switch and these three thresholds are tunable, because the remaining conditions are fixed by what the card *does*: Morimbuul is drawn while bound (the binding family is the table `ataxiaBasher.mnemLdeckBindings`, edited in code, not by command), and Covenant/Xylthus only when the class has a battlerage that reads the affliction *and* the rage to pay for it. All four setters persist via `ataxia_saveSettings(false)`.

Two departures from the `mnem` house style, both deliberate:

- **`cards` has no toggle form.** Unlike `on`/`off`/`quiet`/`map`/`explore` it does *not* go through `M._toggleState` — `on` and `off` are compared literally — so bare `mnem cards` prints the status block instead of flipping the switch. Status is the thing you actually want to read before spending a charge.
- **An unrecognised sub-word does not reach `M.help()`.** `cards` is a matched top-level command, and anything after it that isn't `on`/`off`/`maran`/`seasone`/`matic` falls into the same status branch as the bare form.

Card economy, the design constraint behind every gate above, is in [`docs/legend-deck.md`](../../../docs/legend-deck.md).

### Manual endpoint overrides

These call the Reporter API directly. The API functions guard only on `M._hasToken()` — **not** `_auto()`/`_inRun()` — so they work as a manual fallback and test tool even when auto-reporting is off (or when game wording drifts and a trigger stops firing). Payload shapes are in [02-reporting.md](02-reporting.md#reporter-api-002_reporter_apilua).

| Command | Dispatch | Endpoint |
|---------|----------|----------|
| `mnem start` | `M.startRun()` | `POST /run_start` |
| `mnem end` | `M.endRun()` | flush monsters + `POST /run_end` |
| `mnem check` | `M.runExists()` | `POST /run_exists` — resync with an in-progress run |
| `mnem ripple <n>` | `M.setRipple(tonumber(arg))` | `POST /ripple_level` (guarded: only if `n > run.ripple`) |
| `mnem boss <name>` | `M.reportBoss(arg)` | `POST /boss` |
| `mnem monsters <text>` | `M.reportMonsters(arg)` | `POST /monsters` |
| `mnem death [killer]` | `M.reportDeath(arg)` | `POST /death` (killer defaults to `"unknown"`) |

### Notable behaviours

- **`ripple`/`boss`/`monsters` require an argument** — an empty arg prints a `Usage:` line instead of posting. `death` accepts an empty arg (falls through to the `"unknown"` default).
- **`debug` is session-only.** Unlike `token`/`on`/`off`/`contemplate`, the `debug` toggle does not call `ataxia_saveSettings`, so it resets on reload.
- **`on` and `check` both resync.** Enabling mid-run (`mnem on`) fires `runExists()` so an already-live server run is picked up without restarting it.

## `BOON CLAIM <name>` intercept

Alias `002_Boon_Claim.lua` (regex `^(?i)boon claim (.+)$`) is a passthrough intercept of the player's *own* command, **not** a `mnem` subcommand — so playing normally auto-reports boon choices:

```lua
send("boon claim " .. matches[2])          -- forward the real game command
ataxia.mnemosyne.onBoonClaim(matches[2])   -- then report the selection
```

`M.onBoonClaim(name)` (in `004_Parsers.lua`) gates on `_inRun()`, trims the name, then resolves it against `M.run.lastOffered` (the canonical boon names from the last offered block) via `M._resolveClaim(name, offered)` — a **slot number** (`boon claim 2` → the 2nd offered boon), an exact case-insensitive name, or a **unique case-insensitive prefix** (`boon claim ham`). On a match it records the claim to local history (`M._recordClaim`, see [06-history.md](06-history.md)) and calls `M.reportBoonsSelected(canonical)` with the game's exact spelling; on no match (or an ambiguous prefix) it `decho`s a diagnostic and reports nothing, so a typo or stale claim never posts a bogus selection. The resolution ladder and how `lastOffered` is populated are covered in [03-parsing-triggers.md](03-parsing-triggers.md#onboonclaimname-from-alias-002).

## Setup wizard entry point

`ataxia setup reporting` (in `misc_scripts/020_Setup_Wizard.lua`, `leviSetup.setupReporting`) is the guided front door to the same controls — token, auto on/off, and the `/health` test — for players who don't want to learn the raw `mnem` verbs.
