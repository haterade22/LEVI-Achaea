# Parsing & Triggers

Triggers (`triggers/.../mnemosyne/001`–`009`) match game text and call thin handlers in `004_Parsers.lua`. The parsers are mostly pure string logic; the two multi-line blocks (effects, boons) are captured with a temporary catch-all line trigger.

## Trigger → Pattern → Handler

| # | Trigger | Pattern (regex, type 1) | Handler | Gate |
|---|---------|--------------------------|---------|------|
| 001 | Run Start | `^You begin to wade out into the depths of the Mnemosyne` | `onRunStart()` → `startRun()` | `_auto` |
| 002 | Ripple Level | `^You wade (\d+) ripples? deep into the tides of memory` | `onRipple(n)` | `_auto` (+ map always) |
| 003 | Effects | `^Ongoing effects:` | `onEffectsHeader()` | `_inRun` |
| 004 | Boons Offered | `flickers of power that may aide you` | `onBoonsOffered()` | `_inRun` |
| 005 | Countdown | `^0$` | `onCountdownZero()` | `_inRun` |
| 006 | Go | `^GO!$` | `onGo()` | `_auto` OR `inMnemosyne` |
| 007 | Death | `^You have been slain by (.+?)\.?$` | `reportDeath(m2)` (inline `_inRun` check) | `_inRun` |
| 008 | Objective | `^Objective:\s+(.+)$` | `onObjective(text)` | `_inRun` |
| 009 | Run End | `^The Mnemosyne releases its hold` | `onRunEnd()` → `endRun()` | `_inRun` |

Plus alias **`002_Boon_Claim`** (`^(?i)boon claim (.+)$`): passes the real `boon claim <name>` through with `send()`, then calls `onBoonClaim(name)`.

## Deterministic Monster Capture

The wave prints three consecutive lines:

```
0                    ← countdown, trigger 005
<mob spawn line>     ← the spawn, e.g. "A host of malagmae joins the fray!"
GO!                  ← trigger 006
```

Rather than reading back with `getLines` (fragile), it captures the middle line positionally:

1. **`onCountdownZero()`** (on the `0`): clears `M._mobCandidate`, arms a one-shot `tempRegexTrigger([[^.*$]], …)`. The trigger skips blank lines and keeps waiting; on the first non-blank line it kills itself. If that line is `GO!` or all-digits, no mob spawned this wave; otherwise the line is stored in `M._mobCandidate`.
2. **`onGo()`** (on `GO!`): kills the candidate trigger, and if `_inRun()` and a candidate exists, calls `onMonsters(_extractMob(cand) or cand)`. Then it always `send("wade status", false)` to pull the status block that drives ripple/objective/effects reporting.

`onGo()` is gated on `_auto()` **OR** `ataxiaBasher.inMnemosyne`, so `WADE STATUS` is issued (for the mini-map's ripple reset) even with reporting off. Monster *reporting* inside it still requires `_inRun()`.

`onMonsters(str)` trims, ignores empties, and appends to `M.run.pendingMonsters` de-duped. Buffered, not sent immediately — flushed after `/ripple_level` (see [01](01-architecture.md#key-ordering-guarantees)).

## `_extractMob` — spawn phrase extraction

Trims a spawn line down to the mob's noun phrase, or returns nil (caller falls back to the whole line). The subject is a noun phrase containing **"of"** followed by a **mob verb**:

- "a host of malagmae **joins**" → `a host of malagmae`
- "the trolls of Riagath **wade**" → `the trolls of Riagath`
- "a ghastly horde of the restless dead **descends**" → `a ghastly horde of the restless dead`

Algorithm (word-indexed):

1. For each `of` in the words, walk **left** (up to 6 words) to the outermost article (`a`/`an`/`the`), stopping at an `as` clause or a comma boundary → `leftStart`.
2. Collect the object **after** `of` (up to 5 words), stopping at punctuation.
3. Accept only if a **mob verb** immediately follows the object (`MOB_VERBS` — a large set of movement/appearance verbs and their `-s` forms: join/step/emerge/swarm/wade/surge/…). This confirms the phrase is the sentence subject, not flavour text.
4. Join `leftStart..of` + object (punctuation stripped) into the phrase.

Because wording varies per mob, the spawn line is **positional** (line above `GO!`); `_extractMob` is a best-effort trim with a whole-line fallback.

## Block Capture: `_captureLines`

Generic reentrancy-guarded (`M._capturing`) helper for multi-line blocks. Arms a catch-all `tempRegexTrigger([[^.*$]], …)` and a silence-timeout backstop timer:

```
opts.onLine(line) -> "stop" | "skip" | nil   (nil = keep the line)
opts.timeout      -> seconds of silence before flushing
opts.onDone(lines)                            (pcall-guarded)
```

`bump()` resets the timeout each captured line. `finish()` kills the trigger + timer, clears `_capturing`, and calls `onDone`.

### `_parseNamedBlock(lines)`

Both effects and boons use a `Name:  <padded>  description` layout with word-wrapped continuation lines. Parses `^(%S.-):%s%s+(%S.*)$` (name ≤ `MAX_NAME_LEN=40`); un-prefixed continuation lines are appended to the previous entry's `description`. Blank lines and dashed dividers (`isDivider` = `^%-%-%-+`) are skipped. Returns `{ {name, description}, … }`.

### `onEffectsHeader()`

Captures after `Ongoing effects:`; skips the first divider, collects effect lines, **stops** on a blank line or the closing divider (`timeout=1.5`). Parsed via `_parseNamedBlock` → `reportEffects`.

### `onObjective(text)`

From the `Objective:  defeat <X>` status line. Reports `/boss` **only** when `X` is a boss name; a normal ripple reads `defeat N waves of enemies` (matched by `^%d+ waves? of enemies` and ignored). Fires after `onRipple` in the same `WADE STATUS` output, so `/ripple_level` precedes `/boss`.

## Boons: Offer, Enrich, Claim

### `onBoonsOffered()`

Captures the offer block (between dividers, `timeout=3`), **stopping** at the `BOON CLAIM …` footer. Parses to a list, records canonical names into `M.run.lastOffered`, then `_reportBoonsOfferedEnriched(list)`.

### Enrichment (`contemplate` on)

`_reportBoonsOfferedEnriched` → if `contemplate` off, report as-is. Otherwise `_contemplateNext(list, i)` walks the list sequentially: `send("boon contemplate <name>")`, capture the block via `_captureContemplate`, merge detail via `_applyContemplate`, wait 0.5s, next. After the last, `reportBoonsOffered(list)`.

- **`_parseContemplate(lines)`** → `{ rarity, num_echoes_possible, description, quote }`. Layout: `Rarity: <r>`, `Can echo: <Yes/No>` (Yes→1, No→0, else numeric), description paragraph, blank line, then a double-quoted quote (quotes stripped). Sections advance `meta → desc → quote`.
- **`_applyContemplate`** merges **rarity/quote/echoes only** — the description is kept from the offered block (authoritative and already wrap-joined). Contemplate's description is deliberately dropped: it's redundant, and the first boon's contemplate is armed right beside the offered footer, which was corrupting the first boon's description (fixed v4.7.41).

### `onBoonClaim(name)` (from alias 002)

Matches `name` case-insensitively against `M.run.lastOffered`. Reports `/boons_selected` with the **canonical spelling** the game used; a typo or stale claim (not in the offered set) reports nothing (`decho` only).
