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

## A `;` chain is not one queue entry (2026-11-01, CONFLICTS #53)

**Older docs said `queue addclear free a;b;c` stores one entry that runs back to back. The logs say otherwise.** Mudlet's
own command separator is `;`, so the client splits the line before it sends it. Only `queue addclear free a` reaches
the queue. `b` and `c` go out as plain commands, and the game's auto-queue (`config usequeueing yes`) catches them if
they are refused. CONFIRMED (live): 615 `Added` and 650 `Running queued` rows hold no `;`. Sample: `G BODY` is added,
and then four refusals (`ours/2026-10-27_112717_Tabethys.log`:111-125).

**What this costs.** MEASURED, in logs up to v4.7.450:
- Setup ran before the attack in only 8 of 71 flushes.
- The auto-queue stops accepting at about 5 held, so the FIRST press after a flush wins. The attack that fired had been
  added a median 2.19 s earlier (Monk) and 1.52 s earlier (Infernal).
- A superseded attack fired in 15% (Monk) and 33% (Infernal) of queue-run attacks.

**Decisions that read state in a chain are still stale,** so "one resource spender per round" remains a good rule.

**The lead fix: one alias, rewritten until it fires.** Eight logs from one player's system use it:
`setalias pk stand/wield staff/combo T ...`, then `queue addclearfull eb!p!w!t pk` (`2N1HTSWZ` rows 87, 152-154). The
queue stores the NAME, and the game reads the alias body when the entry fires, so a rewrite can change the round after
it is queued (strict proof n=2; one rewrite lost a race, `3ys7NuHA` rows 2666, 2677). 309 rewrites drew 0 complaints,
at up to 9 per second. HELP ALIASES: `/` separates commands, names are up to 12 characters, and it states no limit on
count or length. Not proven yet: the method at our higher send rate. Step 3 of the plan tests it behind a flag.

## Moves that fail without leaving the room

Some lines say a move failed although the exit is real. Code that moves us must re-send the move
on these lines, and must not treat the exit as a wall.

| Line | Cause | Balance | Source |
|---|---|---|---|
| `The ground seems to tilt and you fall with a thump.` | dizziness (we fall prone) | the fall TAKES balance; how long is not measured | CONFIRMED (user, 2026-10-15, `kb/raw/players/dizziness-fall-2026-10-15.txt`) |
| `You slip and fall on the ice as you try to leave.` | an icy room | moving needs balance, but a slip does not take it | CONFIRMED (user, 2026-09-30) |

Dizziness can be uncurable (the Mnemosyne boon Poindexter gives "permanent dizziness"), so the fall
can happen on any step of a run. The explorer handles it in `M.onDizzyFall()`
(`src_new/scripts/.../mnemosyne/008_Explorer.lua`, trigger `mnemosyne/109`, v4.7.426): it re-sends
`stand;<dir>` on the free queue, which waits for the balance, and never condemns the exit.
