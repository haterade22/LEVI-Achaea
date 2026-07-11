# Parsing & Triggers

Nine triggers (`triggers/.../mnemosyne/001`–`009`) match Mnemosyne game text and call thin handlers in `004_Parsers.lua`. The handlers are pure Lua string logic; the two multi-line blocks (effects, boons) and the per-wave monster line are collected with temporary catch-all line triggers rather than read back after the fact. This doc is the parse layer only — the run lifecycle is [01-architecture.md](01-architecture.md), the HTTP queue and payloads are [02-reporting.md](02-reporting.md).

## Trigger → Handler

Patterns are Mudlet regex (`type: 1`), quoted verbatim from each trigger file.

| # | Trigger | Pattern | Handler call | Gate |
|---|---------|---------|--------------|------|
| 001 | Run Start | `^You begin to wade out into the depths of the Mnemosyne` | `onRunStart()` → `startRun()` | `_auto` |
| 002 | Ripple Level | `^You wade (\d+) ripples? deep into the tides of memory` | `onRipple(tonumber(matches[2]))` | map always; then `_auto` |
| 003 | Effects | `^Ongoing effects:` | `onEffectsHeader()` | `_inRun` |
| 004 | Boons Offered | `flickers of power that may aide you` | `onBoonsOffered()` | `_inRun` |
| 005 | Countdown | `^0$` | `onCountdownZero()` | `_inRun` |
| 006 | Go | `^GO!$` | `onGo()` | `_auto` OR `ataxiaBasher.inMnemosyne` |
| 007 | Death | `^You have been slain by (.+?)\.?$` | `reportDeath(matches[2])` | inline `_inRun` check in trigger body |
| 008 | Objective | `^Objective:\s+(.+)$` | `onObjective(matches[2])` | `_inRun` |
| 009 | Run End | `^The Mnemosyne releases its hold` | `onRunEnd()` → `endRun()` | `_inRun` |

The gate is enforced *inside* each handler (see the gating model in [01-architecture.md](01-architecture.md)); only trigger 007 does its `_inRun()` check in the trigger body before calling the API directly. `onRipple` is the exception to the auto-gate: it first drives the mini-map (`map.onRipple(n)`, unconditional) and only then gates telemetry on `_auto()`.

`BOON CLAIM <name>` is not a trigger but an alias intercept (`002_Boon_Claim`, regex `^(?i)boon claim (.+)$`) that passes the real command through and then calls `onBoonClaim(name)` — detail in [05-commands.md](05-commands.md).

## Multi-line block capture — `_captureLines`

Effects and boons print as wrapped, dashed-divider blocks whose arrival is spread across several game lines, so a start-trigger *arms* a temporary catch-all trigger to collect the following lines until an end condition flushes them. `M._captureLines(opts)` is the generic engine:

```
opts.onLine(line) -> "stop" | "skip" | nil     -- nil = keep this line
opts.timeout      -> seconds of silence before an automatic flush (backstop)
opts.onDone(lines)                              -- pcall-guarded

M._captureLines(opts)
  ├─ if M._capturing: decho + no-op  (reentrancy guard — one block at a time)
  ├─ M._capturing = true
  ├─ tid = tempRegexTrigger([[^.*$]], per-line body)   -- catch-all
  │     res = opts.onLine(line)
  │     res=="stop" -> finish();  res~="skip" -> table.insert(lines, line);  bump()
  ├─ bump(): kill + re-arm tempTimer(opts.timeout, finish)   -- resets each line
  └─ finish(): guard done → M._capturing=false, killTrigger, killTimer, onDone(lines)
```

`bump()` restarts the silence timer on every captured line, so a block that stops emitting (no explicit terminator) still flushes after `timeout` seconds. `finish()` is idempotent (`done` guard) and always clears `M._capturing`, so a parse error in `onDone` can't wedge the guard shut and block the next capture.

### Continuation-line joining — `_parseNamedBlock`

Both blocks use a `Name:  <padded>  description` layout, and long descriptions word-wrap onto un-prefixed continuation lines. `_parseNamedBlock(lines)` rebuilds each entry:

- A new entry matches `^(%S.-):%s%s+(%S.*)$` (name, then **two+ spaces**, then description) and is accepted only when `#name <= MAX_NAME_LEN` (40) — a longer "Name:" match is treated as prose, not a new entry.
- A line with no `Name:` prefix (matched by `^%s*(%S.-)%s*$`) is a wrapped continuation and is appended to the **previous** entry's `description` with a single joining space.
- Blank lines (`^%s*$`) and dashed dividers (`isDivider` = `^%-%-%-+`, matching the game's ~80-dash rules) are skipped.

Result is `{ {name, description}, … }`, with trailing whitespace trimmed off both fields.

### `onEffectsHeader` (trigger 003)

Fires on `Ongoing effects:`. It captures with `timeout = 1.5`, skips the one divider immediately under the header (a `skippedDash` latch), and **stops** on the first blank line or the closing divider. The collected lines go through `_parseNamedBlock`; a non-empty list is sent via `reportEffects`.

### `onObjective` (trigger 008)

A single status line, not a block. `Objective:  defeat <X>` is trimmed and matched against `^defeat (.+)$`; a normal ripple's `defeat N waves of enemies` (matched by `^%d+ waves? of enemies`) is ignored, and only a genuine boss name is sent via `reportBoss`. It arrives after the ripple line in the same `WADE STATUS` output, so `/ripple_level` still precedes `/boss`.

## Boons — offer, enrich, claim

### `onBoonsOffered` (trigger 004)

Fires on `flickers of power that may aide you`. Capture runs with `timeout = 3`; lines before the first divider are skipped, the opening divider is skipped, and capture **stops** at the second divider or the `BOON CLAIM` footer (whichever comes first). The parsed list's names are recorded into `M.run.lastOffered` (so a later `BOON CLAIM` can resolve the game's exact spelling), then handed to `_reportBoonsOfferedEnriched`. The trigger *also* calls `onBoonScreen()` unconditionally (outside the `_inRun` telemetry gate): this line is the de-facto **ripple-complete** marker, and it's the signal the auto-explorer keys on to stop sweeping — see [07-explorer.md](07-explorer.md).

### The `BOON CONTEMPLATE` enrichment state machine

When `cfg.contemplate` is on, each offered boon is `BOON CONTEMPLATE`d to attach rarity/quote/echo detail before the payload goes out. The walk is strictly sequential — one contemplate block in flight at a time, matching the `_captureLines` reentrancy guard:

```
_reportBoonsOfferedEnriched(list)
  ├─ contemplate off? → reportBoonsOffered(list)          (name+description as-is)
  └─ contemplate on?  → _contemplateNext(list, 1)

_contemplateNext(list, i)
  ├─ i > #list → reportBoonsOffered(list)                 (fully enriched → POST)
  └─ else:
       _captureContemplate(cb)                            (arm block capture)
       send("boon contemplate " .. list[i].name)          (issue the command)
       cb(info): _applyContemplate(list[i], info)
                 tempTimer(0.5, → _contemplateNext(list, i+1))
```

- **`_captureContemplate(cb)`** captures with `timeout = 2`. It **never** captures a `BOON CLAIM` line (returns `"skip"`), skips the `<name>:` header and opening divider, and **stops** at the closing divider. `onDone` is one-shot (`called` latch) and passes `_parseContemplate(lines)` to `cb`.
- **`_parseContemplate(lines)`** returns `{ rarity, num_echoes_possible, description, quote }`. It reads `Rarity: <r>`, the authoritative **`Maximum echoes: N`** line (printed only for echo-capable boons → `num_echoes_possible = N`), and `Can echo: <Yes/No>` (`No` → `0`, `Yes` → a floor of `1` that a `Maximum echoes` line refines to `N`) — so an echo-capable boon reports its real cap, not a flat `1`, and the `Maximum echoes` line is consumed as meta rather than leaking into the description. It then advances through sections `meta → desc → quote`: non-blank lines after the meta rows build the description paragraph, a blank line switches to the quote section, and the trailing double-quoted line becomes `quote` (surrounding `"` stripped).
- **`_applyContemplate(boon, info)`** merges **only `rarity`, `quote`, and `num_echoes_possible`** onto the offered entry. It deliberately does **not** take contemplate's `description`: the offered-block description is authoritative and already wrap-joined, and the first boon's contemplate is armed right beside the `BOON CLAIM` offered footer, which was corrupting the first boon's description.

### `onBoonClaim(name)`

Called from the alias. `name` is resolved against `M.run.lastOffered` by `_resolveClaim(name, offered)` — a **slot number** (`boon claim 2` → `offered[2]`), an exact case-insensitive name, or a **unique case-insensitive prefix**. On a hit the claim is recorded to local history (`_recordClaim`, see [06-history.md](06-history.md)) and `reportBoonsSelected` is sent with the **canonical** offered spelling. A typo, an ambiguous prefix, or a stale claim reports nothing and only `decho`s — see [05-commands.md](05-commands.md).

## Deterministic monster capture

The final wave prints three consecutive lines — the countdown `0`, the mob spawn line, then `GO!`:

```
0                    ← trigger 005  (onCountdownZero)
<mob spawn line>     ← e.g. "A host of malagmae joins the fray!"
GO!                  ← trigger 006  (onGo)
```

Reading the spawn line back with `getLines()` at `GO!` was unreliable — word-wrap and prompt timing made "the line above" ambiguous. Instead the middle line is captured **positionally**, as the next physical line the game emits after the `0`:

1. **`onCountdownZero()`** (gate `_inRun`) clears `M._mobCandidate`, kills any stale `M._mobTrig`, and arms a one-shot `tempRegexTrigger([[^.*$]], …)`. That trigger trims the line, ignores blanks (staying armed), and on the first non-blank line kills itself. If that line is `GO!` or all-digits, no mob spawned this wave; otherwise it stores the line in `M._mobCandidate`.
2. **`onGo()`** (gate `_auto` OR `ataxiaBasher.inMnemosyne`) kills the candidate trigger and, when `_inRun()` and a candidate exists, commits it via `onMonsters(M._extractMob(cand) or cand)`. It then always `send("wade status", false)` to pull the status block that drives ripple / objective / effects reporting.

Because `onGo` also runs for the mini-map (`inMnemosyne`) even with reporting off, `WADE STATUS` is still issued; monster *reporting* inside it stays gated on `_inRun()`. `onMonsters` trims, drops empties, and appends to `M.run.pendingMonsters` de-duped — buffered, not sent, so it can be flushed after `/ripple_level` (see [01-architecture.md](01-architecture.md)).

### `_extractMob` — spawn-phrase trimming

`_extractMob(str)` trims a spawn sentence down to the mob's noun phrase, or returns `nil` (the caller then falls back to the whole line — `_extractMob(cand) or cand`). The subject is a noun phrase built around **"of"** and closed by a **mob verb**:

| Spawn line | Extracted phrase |
|------------|------------------|
| "a host of malagmae **joins**…" | `a host of malagmae` |
| "the trolls of Riagath **wade**…" | `the trolls of Riagath` |
| "a ghastly horde of the restless dead **descends**…" | `a ghastly horde of the restless dead` |

Algorithm (word-indexed over `str`):

1. **Pivot on `of`.** For each word whose bare form is `of`, walk **left** up to 6 words to the outermost article (`a` / `an` / `the`) → `leftStart`, breaking early at an `as` clause or a comma-terminated word so flavour clauses don't leak in.
2. **Collect the object** after `of`, up to 5 words, stripping punctuation and stopping at trailing punctuation.
3. **Require a mob verb.** The object is accepted only if the very next word is in `MOB_VERBS` (a large set of movement/appearance verbs and their `-s` forms — join/step/emerge/swarm/wade/surge/…), confirming the phrase is the sentence subject rather than incidental "of" text.
4. **Join** `leftStart..of` + object (punctuation stripped) into the returned phrase.

Both walks are word-capped (6 left, 5 right) so a runaway sentence can't blow up the scan. A spawn line whose verb isn't in `MOB_VERBS` yields `nil`, and the whole trimmed line is reported instead — lossy-but-safe, since wording varies per mob.

### Notable behaviours

- **One capture at a time.** `_captureLines`, `_captureContemplate`, and the monster one-shot each own the single in-flight temp trigger; the `M._capturing` guard and the sequential `_contemplateNext` walk keep effects/boons/contemplate blocks from interleaving.
- **Silence backstop.** Every block has a `timeout` (1.5s effects, 3s boons, 2s contemplate) so a block that never emits an explicit terminator still flushes and never leaves a catch-all trigger armed.
- **Description authority.** `_applyContemplate` never overwrites the offered-block description; contemplate only adds `rarity` / `quote` / `num_echoes_possible`.
