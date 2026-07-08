# Mnemosyne Architecture

## Namespace & Modules

Everything hangs off `ataxia.mnemosyne` (aliased `local M` in each script file):

| Table | Owner | Purpose |
|-------|-------|---------|
| `ataxia.mnemosyne` | 001–004 | HTTP client, reporter API, commands, parsers |
| `ataxia.mnemosyne.run` | 002 | In-memory per-run state (see below) |
| `ataxia.mnemosyne.map` | 005–006 | Per-ripple room graph + widget (own state) |

### Run-state model (`M.run`)

Initialised in `002_Reporter_API.lua` and reset by `M._resetRun()`:

| Field | Type | Meaning |
|-------|------|---------|
| `active` | bool | A run is in progress (gates `_inRun()`) |
| `publicId` | string/nil | Server-assigned run id (from `/run_start` response) |
| `ripple` | number | Highest ripple level reported so far (monotonic guard) |
| `pendingMonsters` | table | Buffered mob spawn lines, flushed after `/ripple_level` |
| `lastOffered` | table | Canonical boon names from the last boons-offered block |

`M._resetRun()` zeroes `ripple`, clears `publicId`, and empties `pendingMonsters`/`lastOffered`. It is called **synchronously** at run start and end so a fast first `GO!`/`WADE STATUS` can never hit a stale ripple guard or flush a previous run's monsters.

## Gating Model

Two predicates decide whether a trigger handler actually reports. This is the core safety mechanism — Mnemosyne game phrases ("Ongoing effects:", boon offers) are generic enough to fire outside a run.

| Predicate | Definition | Gates |
|-----------|-----------|-------|
| `M._auto()` | `cfg.enabled` AND token set | Run-establishing events: run start, ripple, GO! |
| `M._inRun()` | `M._auto()` AND `run.active == true` | Everything else: monsters, effects, boons, boss, death |

Reporter API functions themselves only check `M._hasToken()` — so manual `mnem` commands work even with auto-reporting off. The **triggers** enforce `_auto`/`_inRun`; the API is just the mechanism.

The ripple map (`ataxia.mnemosyne.map`) uses a separate gate `MAP.inMnem()` — true when `ataxiaBasher.inMnemosyne` is set OR a telemetry run is active — so the map works even with reporting disabled.

## Event Flow (one run)

```
"You begin to wade out into the depths of the Mnemosyne"   [trig 001]
  └─ onRunStart() → _auto? → startRun()
       └─ POST /run_start → run.active=true, _resetRun(), publicId set

──────────────  per wave/ripple loop  ──────────────

countdown "0"                                              [trig 005]
  └─ onCountdownZero() → arm one-shot capture of the NEXT line → M._mobCandidate
<mob spawn line>            (captured into _mobCandidate, not yet reported)
"GO!"                                                      [trig 006]
  └─ onGo()
       ├─ commit _mobCandidate: onMonsters(_extractMob(cand) or cand)  → buffered
       └─ send("wade status")     (auto-issued to pull the status block)

WADE STATUS output:
  "You wade N ripples deep into the tides of memory:"      [trig 002]
    └─ onRipple(N)
         ├─ map.onRipple(N)  (reset mini-map on level change)
         ├─ setRipple(N)     → POST /ripple_level  (guarded: only if N > run.ripple)
         └─ _flushMonsters() → POST /monsters   (AFTER ripple, ordering holds)
  "Objective:  defeat <X>"                                 [trig 008]
    └─ onObjective → boss case only → POST /boss
  "Ongoing effects:"                                       [trig 003]
    └─ onEffectsHeader() → capture block → POST /effects

boons offer: "...flickers of power that may aide you..."   [trig 004]
  └─ onBoonsOffered() → capture block → lastOffered set
       └─ (contemplate on) BOON CONTEMPLATE each → enrich → POST /boons_offered
"BOON CLAIM <name>"                          [alias 002, user command]
  └─ onBoonClaim(name) → match against lastOffered → POST /boons_selected

──────────────  end conditions  ──────────────

"You have been slain by <killer>."                         [trig 007]
  └─ _inRun? → reportDeath(killer) → POST /death   (run CONTINUES — Mnemosyne
                                                    death loses a life, not the run)
"The Mnemosyne releases its hold, weaving N ... threads..."[trig 009]
  └─ onRunEnd() → _flushMonsters() → POST /run_end → run.active=false, _resetRun()
```

### Key ordering guarantees

- **Monsters after ripple.** Spawn lines arrive just before `GO!`, which triggers `WADE STATUS`; monsters are buffered and only flushed inside `onRipple()` *after* `setRipple()` enqueues `/ripple_level`. Because the HTTP queue is serial (see [02-reporting.md](02-reporting.md)), `/ripple_level` lands before `/monsters`.
- **Boss/effects after ripple.** `Objective:` and `Ongoing effects:` are lines *within* the same `WADE STATUS` output, printed after the ripple line, so `/boss` and `/effects` naturally follow `/ripple_level`.
- **Offered before selected.** `/boons_offered` is enqueued when the offer block closes; `/boons_selected` only on the user's `BOON CLAIM`, necessarily later.

## Death vs. Run End

Mnemosyne is an endless climb with **no win condition**. A "slain by" line (trigger 007) is an in-run life loss and reports `/death` but keeps `run.active` true. The run only closes on the reward line *"The Mnemosyne releases its hold, weaving N shimmering threads into your possession."* (trigger 009), which fires on true death or `WADE LEAVE`.

## Resume-on-load

`002_Reporter_API.lua` registers a `sysLoadEvent` handler that waits 6s (mirroring `ataxia.updater`) then, if `_auto()`, calls `runExists()` → `POST /run_exists`. If the server says a run is live, it restores `run.active` and syncs `run.ripple`. This is why run state need not be persisted to disk.
