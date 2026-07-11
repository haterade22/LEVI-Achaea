# Local History & Reports

A local, persisted mirror of what each run parses — boons offered, boons claimed, and ongoing-effect "affixes" — so runs can be reviewed in-client and an all-time affix catalogue is kept. It is entirely separate from the remote run tracker ([02-reporting.md](02-reporting.md)): the same parser points that POST to the server also feed this store, but the history functions never talk to the network and never gate on a token themselves. All of it lives in `007_History.lua` under `ataxia.mnemosyne` (aliased `local M`).

## Data model

Everything hangs off a single table, `M.history`, seeded on load:

```lua
M.history = { run = 0, claims = {}, offers = {}, affixes = {}, library = {} }
```

| Key | Type | Meaning |
|-----|------|---------|
| `run` | number | Local run counter; bumped once per run (see below). Tags every record so reports can filter to "this run" |
| `offers` | array | Every boon seen offered, one record per boon per offer |
| `claims` | array | Every boon the player claimed, one record per claim |
| `affixes` | array | Ongoing effects seen active, de-duped per run |
| `library` | map | All-time affix catalogue: `[affixName] = description` |

`claims`, `offers`, and `affixes` are **flat per-record lists** — not nested per run — so each record carries its own `run` field and reports scan-and-filter. The record shapes differ:

| Field | offer | claim | affix |
|-------|:-----:|:-----:|:-----:|
| `run` | ✓ | ✓ | ✓ |
| `ripple` | ✓ | ✓ | — |
| `name` | ✓ | ✓ | ✓ |
| `description` | ✓ | ✓ | ✓ |
| `rarity` | ✓ | ✓ | — |
| `echoes` | — | ✓ | — |

`library` is the one non-list structure: keyed by affix name, valued by the description captured the **first time that name is ever seen** (`if not library[name] then library[name] = desc or "" end` — key-presence only, so the value can be `""` and is never updated afterwards). It is **never scoped to a run** — it only grows.

## Persistence

State is written to `<profile>/mnemosyne_history.lua` via Mudlet's `table.save` / `table.load`. `histFile()` builds the path from `getMudletHomeDir()`; both load and save are guarded so the module still loads clean in a bare or test environment where those globals are absent:

```
histFile():
  if getMudletHomeDir is not a function: return nil     -- bare/test env
  return getMudletHomeDir() .. "/mnemosyne_history.lua"

_historyLoad():                                          -- runs once at module load (last line of the file)
  fn = histFile(); if not fn or table.load absent: return
  pcall(table.load, fn, M.history)
  coerce M.history.run -> number; default claims/offers/affixes/library to {}

_historySave():                                          -- called after every mutation
  fn = histFile(); if not fn or table.save absent: return
  pcall(table.save, fn, M.history)
```

Every recording function calls `M._historySave()` on its way out, so the on-disk file always reflects the latest parse. Both I/O calls are wrapped in `pcall`, so a save failure never bubbles up into the parser that triggered it. Unlike the remote run state (in-memory only, re-synced from the server), the history file is the source of truth for local review and survives reloads.

## The run counter

`M.history.run` is bumped by `M._historyNewRun()`, which increments it and saves. It is called from **two** places so that every genuine run gets its own bucket:

| Bump site | File | Condition |
|-----------|------|-----------|
| `M.startRun()` | `002_Reporter_API.lua` | The normal path — `startRun` bumps right after its optimistic local reset (it has already bailed if there's no token) |
| `M.onRipple(n)` bootstrap | `004_Parsers.lua` | Only when `not M.run.active` and we're in-Mnemosyne context — a run whose start line was missed still gets a fresh bucket the first time WADE STATUS reports a ripple |

```lua
-- onRipple, after the context guard:
if not M.run.active and M._historyNewRun then M._historyNewRun() end  -- bootstrapped run gets its own bucket
```

Because the counter only ever increments (and is coerced back to a number on load), run numbers are stable across reloads and monotonic across the life of the profile.

## Recording

Three functions do the recording, each called from a parser hook in `004_Parsers.lua` right beside the matching remote report:

| Function | Called from | Alongside |
|----------|-------------|-----------|
| `M._recordOffers(list, ripple)` | `M._reportBoonsOfferedEnriched` (contemplate off) and `M._contemplateNext` (contemplate on, once enrichment finishes) | `M.reportBoonsOffered` |
| `M._recordClaim(name)` | `M.onBoonClaim` (after `_resolveClaim` yields a canonical name) | `M.reportBoonsSelected` |
| `M._recordAffixes(list)` | `M.onEffectsHeader` | `M.reportEffects` |

```
onBoonsOffered (_inRun) -> _parseNamedBlock -> _reportBoonsOfferedEnriched
    contemplate off:  _recordOffers(list)                 ; reportBoonsOffered
    contemplate on :  _contemplateNext(list,1) ...
                      (at completion) _recordOffers(list) ; reportBoonsOffered   -- list now enriched with rarity

onBoonClaim (_inRun)    -> _resolveClaim -> _recordClaim(canonical) ; reportBoonsSelected

onEffectsHeader (_inRun) -> _parseNamedBlock -> _recordAffixes(list) ; reportEffects
```

Wiring the calls into `_recordOffers` at **both** contemplate paths means offer records carry rarity whenever enrichment ran, and still get recorded (name + description only) when it didn't.

### Offers

`_recordOffers(list, ripple)` appends one record per named boon. `ripple` defaults to `M.run.ripple` (then `0`) when the caller passes none, which is the usual case. Offers are the authoritative carrier of `rarity` and `description`; claims borrow from them.

### Claims — echo counting and info borrowing

`_recordClaim(name)` does two things a raw claim line can't:

- **Borrows rarity + description** from the offers already recorded this profile via `M._histBoonInfo(name)`, which scans `M.history.offers` for that name and returns the latest non-empty `rarity`/`description`. A claim line itself carries neither, so without this the claim record would be bare.
- **Counts echoes within the run** — it walks existing claims, and for each one matching `run == M.history.run` and the same `name`, increments `echoes` (starting at 1). So claiming the same boon a second time this run records `echoes = 2`, and so on.

```
_recordClaim(name):
  rarity, description = _histBoonInfo(name)          -- from recorded offers
  echoes = 1
  for c in history.claims:
    if c.run == history.run and c.name == name: echoes += 1
  append { run, ripple, name, rarity, echoes, description }
  save
  if not _quiet(): echo  Claimed <name> (rarity) -- now <echoes> echo(es)
```

### Affixes — per-run de-dupe + growing library

`_recordAffixes(list)` handles the "Ongoing effects:" block. Each named affix is recorded **at most once per run** (it scans `M.history.affixes` for a matching `run` + `name` before inserting), and independently seeds the all-time library the first time a name is ever seen:

```
_recordAffixes(list):
  run = history.run
  for a in list:
    if not already recorded this run (run + name match):
      append { run, name, description }
      if not _quiet(): echo  Affix <name>
    if not library[a.name]:                          -- all-time, never run-scoped
      library[a.name] = a.description or ""
  save
```

The per-run de-dupe keeps a re-read of the status block from spamming duplicate affix rows and echoes, while the library grows the first time each distinct affix appears — even if the same affix was already logged for a previous run.

## Reports

Three read-only `mnem` subcommands print the store. They are dispatched by `M.command` in `003_Commands.lua` and covered as commands in [05-commands.md](05-commands.md); the rendering lives in `007_History.lua`.

| Command | Function | Shows |
|---------|----------|-------|
| `mnem boons` | `M.reportBoons()` | This run's claimed boons — each with rarity, echo count (`xN`), the ripple it was claimed at, and its borrowed description |
| `mnem affixes` | `M.reportAffixes()` | This run's active affixes — name + description, filtered to `run == M.history.run` |
| `mnem library` | `M.reportLibrary()` | The all-time affix catalogue — every `library` name sorted alphabetically, with its description and a total count |

`reportBoons` and `reportAffixes` both filter the flat lists to the current `M.history.run`; `reportLibrary` ignores runs entirely and sorts `library`'s keys. Each prints a `(none recorded yet)` / `(empty)` placeholder when there's nothing to show.

## Quiet toggle

`_recordClaim` and `_recordAffixes` echo a one-line confirmation as they record (`Claimed ...` / `Affix ...`). `mnem quiet [on|off]` silences those automatic echoes **without** stopping the recording:

```lua
-- 003_Commands.lua
c.quiet = M._toggleState(arg, M._quiet())
ataxia_saveSettings(false)
```

`M._quiet()` reads `M._cfg().quiet == true` — i.e. `ataxia.settings.reporting.quiet`, persisted in the same reporting settings block as `enabled`/`token`. When it's on, both recorders skip their `M.echo` but still `table.insert` + save, so history keeps accruing silently. The manual reports (`mnem boons` / `affixes` / `library`) are never affected by quiet.

## Caveat: recording rides the `_inRun` hooks

Recording is honest about its coverage: it only happens at parser hooks that are gated on `M._inRun()` (`onEffectsHeader`, `onBoonClaim`, and — upstream of the offer recorders — `onBoonsOffered`), and the run counter is bumped from `startRun` (which requires a token) or the `onRipple` bootstrap (which requires `_auto()` and in-Mnemosyne context). In practice that means **history is captured only during tracked runs — auto-reporting on and a token set**. Play a Mnemosyne run with reporting off and nothing is recorded locally; this store is a mirror of the tracked pipeline, not an independent observer. The remote and local sides always move together.

---

See also: [01-architecture.md](01-architecture.md) (run lifecycle, `_auto`/`_inRun` gating), [02-reporting.md](02-reporting.md) (the remote endpoints these calls sit beside), [03-parsing-triggers.md](03-parsing-triggers.md) (the block parsers that feed the recorders), [05-commands.md](05-commands.md) (the `mnem` command surface).
