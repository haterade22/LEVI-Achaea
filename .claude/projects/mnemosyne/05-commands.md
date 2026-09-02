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

### Keeping the catalogue current (v4.7.295)

A description is shown once, on a screen gone a second later, so the catalogue cannot be rebuilt.

| Command | Effect |
|---|---|
| `mnem boonfill` | contemplate the first `BOON_FILL_BATCH` (8) undescribed boons |
| `mnem boonfill all` | all of them -- opt-in, for a quiet moment |
| `mnem boonfill gaps` | name what is missing, spending no command |

`M.boonGaps()` unions the SEED (which carries every name-only hole), the LIBRARY and the last BOONS
list, then dedupes and sorts. The old version read `boonsOwned` alone, which could only ever reach
boons we were already holding -- the opposite of where the holes are.

**One gap fills itself per boon screen.** The trickle runs only after the offer has been flushed,
waits `BOON_FILL_IDLE` (4s), and refuses if `_captureLines`' single global slot is taken -- the
v4.7.93 / v4.7.279 race. One per screen, never a batch.

### Bonuses panel (`mnemosyne/011_Bonuses.lua` + `012_Bonuses_Window.lua`, v4.7.287)

Guarded by `if B then`, and **not gated on being in the tower** -- unlike the map. Boons persist for
the whole run, so the panel is as useful on the riverbank deciding whether to dive again as it is
mid-ripple; gating it on `inMnem()` would blank it exactly when you are reading it to plan.

| Command | Effect |
|---------|--------|
| `mnem bonuses` | `B.report()` -- **REPORTS to the console**, it does NOT toggle |
| `mnem bonuses on` / `mnem bonuses off` | `B.toggle(true)` / `B.toggle(false)` -- force the panel, persists `bonusesEnabled` (default **off**) |

**Why bare `mnem bonuses` reports rather than toggling** (the one place this diverges from
`mnem map`): the console fallback keeps the aggregation readable with the panel off, and in a
client where Geyser failed to build it is the only surface there is. One source, two surfaces --
`B.report()` and `B.render()` both walk `M.bonusSections()`, so they cannot disagree.

Sections, in render order: AFFIXES, BOONS (rarity-coloured, `INERT` when a Shaman attunement is
missing), STATS, **OFFENSE**, RESISTANCES, DMG BOOSTS, **AUDIT (measured)**, IMMUNE TO,
ON-HIT PROCS, COSTS -- ten of them. AUDIT sits last of the numeric blocks because it is the check,
not the headline; see the AUDIT section above.

**OFFENSE** (v4.7.289) prints `TOTAL +N% damage` followed by the boons that make it up, so the
figure is auditable rather than asserted. Only ALWAYS-ON generic bonuses reach the total:
conditional ones are listed below it with their clause and excluded, and ability-specific ones
(Warmarch's paean +200%, Blossom of Pain's sternum +300%) do not match the parser at all -- they
fire on one ability, not every swing. **RESISTANCES** collapses to one `All types +N%` row when
every type carries the same number, and prints per type otherwise. An empty section is omitted rather
than printed as a bare heading, and a wholly empty panel **says why** -- a blank panel and a broken
panel look identical, and this one is legitimately blank for most of a session.

`B.refresh()` is called from `onBoonClaim` and `onRipple` in `004_Parsers.lua` (both `pcall`'d):
those are the two events that can change the answer -- a new claim, and a new ripple's affixes.

### AUDIT (`mnemosyne/013_Audit.lua` + trigger `078`, v4.7.290)

The game's own accounting -- the only input to the bonuses panel that is MEASURED rather than
derived from a boon's description, and therefore the only one that can prove the rest of it wrong.

| Command | Effect |
|---|---|
| `mnem audit` | Send `AUDIT` and capture the block |
| `mnem audit report` | Print what we already hold -- no command spent |
| `mnem audit reset` | Drop the baseline, so the next capture becomes one (for a run joined late) |

A **baseline** is taken once per RUN from the explorer's wade entry, beside `_wearArmour` /
`_furyCheck` -- once per run rather than per ripple, since it is a run-scoped fact and re-asking
would put an 18-line block in the log at every boon screen. `current - baseline` is then what the
run's boons actually bought, in the game's numbers. **The delta is reported, never modelled**: how
boon resistances combine is exactly what this exists to measure.

The capture is armed by trigger `078` on the `Audit records:` header -- i.e. by the OUTPUT rather
than by our send -- so a manual AUDIT is captured identically and a wrong send fails visibly. It
deliberately does not use `_captureLines`, which holds one global slot that the `GO!` monster
capture is contending for at the same instant.

### Local history (see [06-history.md](06-history.md))

| Command | Effect |
|---------|--------|
| `mnem boons` | `M.reportBoons()` — this run's claimed boons (rarity, echoes, ripple, description) |
| `mnem affixes` | `M.reportAffixes()` — this run's active affixes (ongoing effects) |
| `mnem library` | `M.reportLibrary()` — the all-time affix catalogue |
| `mnem boondb [filter\|export\|import]` | All-time BOON catalogue -- its own file, filter matches name **or** effect text, entries annotated with parsed immunities/costs (v4.7.239) |

### Auto-explorer (see [07-explorer.md](07-explorer.md))

| Command | Effect |
|---------|--------|
| `mnem explore` | `M.exploreToggle()` — start/stop the 4×4 auto-sweep |
| `mnem explore on` / `mnem explore off` | `M.exploreOn()` / `M.exploreOff()` — force state |
| `mnem explore status` | `M.exploreStatus()` — diagnostic (`inMnem`/denizens/moving/next step) |
| `mnem explore why` | `M.exploreWhy()` — **why is the sweep not moving?** Per-exit refusal reasons, grid bounding box, nav-suspension state, and the lava ledger with provenance (v4.7.259/262) |
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


---

## `mnem status` gained two rows (v4.7.278)

* **`Class/Race`** -- what would actually be sent with `/boons_offered`, showing `unread` in red
  when `gmcp.Char.Status` cannot be read. The fields have ridden that endpoint since v4.7.220, but a
  failed read OMITS the key rather than sending `"unknown"` (right for the data), which made a
  broken read indistinguishable from a working one. **A field that is correct and invisible is
  indistinguishable from one that is broken.**
* **`Lives`** -- `Remaining lives` from the WADE STATUS block, with `Wave progress` beside it. Shown
  in red at 1. It also echoes on CHANGE (never on every wade status: a number reprinted each ripple
  is a number nobody reads).

**Still misleading:** the `Contemplate:` row. `M._contemplateNext` is dead code since v4.7.91 took
the enrichment chain off the offer path, so the setting no longer affects offers -- it reaches only
`boonFill`.
