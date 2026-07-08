# Commands

## `mnem` alias

Alias `001_Mnemosyne.lua` (regex `^mnem(?:osyne)?(?:\s+(.*))?$`) forwards the argument to `ataxia.mnemosyne.command(rest)` in `003_Commands.lua`, which splits `<cmd> <arg>` and dispatches. Bare `mnem` (or `mnem status`) shows status.

### Config

| Command | Effect |
|---------|--------|
| `mnem status` | Show URL, token set?, auto on/off, contemplate on/off, and current run state (active, ripple, id) |
| `mnem token <token>` | Save the API token; persists via `ataxia_saveSettings(false)` |
| `mnem on` | Enable auto-reporting, then `runExists()` to resync in case you enabled mid-run |
| `mnem off` | Disable auto-reporting |
| `mnem contemplate` | Toggle boon enrichment via `BOON CONTEMPLATE` |
| `mnem debug` | Toggle verbose debug echoes (`M.decho`) |
| `mnem test` (or `mnem health`) | Ping `GET /health` to check connectivity |
| `mnem help` | Command reference (any unknown subcommand also shows help) |

### Ripple map

| Command | Effect |
|---------|--------|
| `mnem map` | Toggle the mini-map (`MAP.toggle()`) |
| `mnem map on` / `mnem map off` | Force the map on/off (persists `mapEnabled`) |
| `mnem map status` | Diagnostic echo — see [04-ripple-map.md](04-ripple-map.md#diagnostics) |

### Run lifecycle & manual overrides

These call the Reporter API directly (they only require a token, not `_auto`/`_inRun`), so they double as test tools and a fallback when game wording changes.

| Command | Effect |
|---------|--------|
| `mnem start` | `startRun()` → `POST /run_start` |
| `mnem end` | `endRun()` → flush monsters + `POST /run_end` |
| `mnem check` | `runExists()` → `POST /run_exists`, resync with an in-progress run |
| `mnem ripple <n>` | `setRipple(n)` → `POST /ripple_level` (guarded: only if `n > run.ripple`) |
| `mnem boss <name>` | `reportBoss(name)` → `POST /boss` |
| `mnem monsters <text>` | `reportMonsters(text)` → `POST /monsters` |
| `mnem death [killer]` | `reportDeath(killer)` → `POST /death` (defaults killer to `"unknown"`) |

## `BOON CLAIM <name>` intercept

Alias `002_Boon_Claim.lua` (regex `^(?i)boon claim (.+)$`) is a passthrough intercept, **not** a `mnem` subcommand:

```lua
send("boon claim " .. matches[2])          -- forward the real command
ataxia.mnemosyne.onBoonClaim(matches[2])   -- then report the selection
```

`onBoonClaim` reports `/boons_selected` only if the name matches a boon from the last offered set (see [03-parsing-triggers.md](03-parsing-triggers.md#onboonclaimname-from-alias-002)), so playing the game normally auto-reports your boon choices.

## Setup wizard

`ataxia setup reporting` (in the setup wizard, `misc_scripts/020_Setup_Wizard.lua`) exposes the same token / auto on-off / test controls as a guided menu.
