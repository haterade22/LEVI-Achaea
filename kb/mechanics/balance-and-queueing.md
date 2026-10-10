---
topic: balance-and-queueing
confidence: CONFIRMED (HELP 4.6 / 4.6.1)
sources:
  - kb/raw/help/4.6_equilibrium-and-balance.txt
  - kb/raw/help/4.6.1_queueing.txt
last_verified: 2026-10-10
---

# Balance, equilibrium and the server queue

## Balance and equilibrium (HELP 4.6)

- **Balance** is physical: after a swing, punch or kick you must recover it before the next.
- **Equilibrium** is mental: after a spell or mental ability you must recover it.
- **Usually you need both.** "In most cases, not having balance prevents you from using an
  ability that requires equilibrium, and vice versa. There are many exceptions." This is why an
  equilibrium "rider" that fires beside a balance attack has to go in the same queued line.
- Recovery is generally **2-5 seconds**, varying by ability, race and artefacts.
- Other balances exist: per limb, sipping, salves, voice.
- Equilibrium can be lost for longer than it should be. **CONCENTRATE** regains it (see the
  confused + disrupted fix, `curing/004`).

## The server queue (HELP 4.6.1)

**Automatic queueing** (`CONFIG USEQUEUEING ON|OFF`): a command tried off balance/eq is queued
and runs on recovery. `CONFIG SHOWQUEUEALERTS ON|OFF` toggles the queue messages.

| Command | Effect |
|---|---|
| `QUEUE ADD <q> <cmd>` | Append to that queue |
| `QUEUE ADDCLEAR <q> <cmd>` | Clear **that** queue, then add |
| `QUEUE ADDCLEARFULL <q> <cmd>` | Clear **every** queue, then add at the front |
| `QUEUE INSERT <q> <i> <cmd>` / `PREPEND` / `REPLACE` / `REMOVE <i>` | Positional edits |
| `QUEUE LIST`, `CLEARQUEUE <q>`, `CLEARQUEUE ALL` (= `QUEUE CLEAR`) | Inspect and clear |

**Limits that matter to our code:**
- **At most 10 queued commands across ALL queues together**, not 10 per queue. INSERT or
  PREPEND past the limit **drops the last queued command, from any queue**. ADDCLEAR **fails**
  if clearing its own queue still leaves no room.
- **ADDCLEARFULL wipes everything**, every queue type included. That is why the basher's
  `queue addclearfull` round deletes anything else we queued, and why balanceless commands
  (lily drops, corpse eats, CONSIDER) are sent directly instead (see CLAUDE.md).

**Queue types:**

| Type | Waits for |
|---|---|
| `eq`, `bal`, `eqbal` | equilibrium / balance / both |
| `class` | any class balance |
| `ship` | ship command balance |
| `para` / `unbound` / `stun` | not paralysed / not bound / not stunned |
| `free` | eqbal, unbound, not paralysed, not stunned |
| `freestand` | free, plus standing |
| `full` | freestand, plus class balance |

**Custom types** combine flags, with `!` to negate: `e` eq, `b` balance, `c` class balance,
`s` ship balance, `p` paralysis, `w` bound, `u` upright, `t` stunned. HELP's own examples:
`QUEUE ADD c!p!tu <cmd>` (class balance, not paralysed, not stunned, standing) and
`QUEUE ADD eb!w!p!t <cmd>` (the same as `free`).

**`freestand` needs you STANDING** (CLAUDE.md, Blademaster): an entry that cannot fire while you
are prone waits until the next `addclear` replaces it.
