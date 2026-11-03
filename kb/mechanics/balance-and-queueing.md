---
topic: balance-and-queueing
confidence: CONFIRMED (HELP 4.6 / 4.6.1)
sources:
  - kb/raw/help/4.6_equilibrium-and-balance.txt
  - kb/raw/help/4.6.1_queueing.txt
last_verified: 2026-11-03
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
- Setup ran before the attack in only 8 of 71 flushes. ([scoreboard.md](scoreboard.md) counts 8 of 68 on the same two logs: a
  flush there ends at a prompt, and KAI CHOKE counts as an attack. The study's grouping is not recorded.)
- The auto-queue stops accepting at about 5 held, so the FIRST press after a flush wins. The attack that fired had been
  added a median 2.19 s earlier (Monk) and 1.52 s earlier (Infernal).
- A superseded attack fired in 15% (Monk) and 33% (Infernal) of queue-run attacks.

**Decisions that read state in a chain are still stale,** so "one resource spender per round" remains a good rule.

**The lead fix: one alias, rewritten until it fires.** Eight logs from one player's system use it:
`setalias pk stand/wield staff/combo T ...`, then `queue addclearfull eb!p!w!t pk` (`2N1HTSWZ` rows 87, 152-154). The
queue stores the NAME, and the game reads the alias body when the entry fires, so a rewrite can change the round after
it is queued. **CONFIRMED live on our seat:** queued while the alias said "one", rewritten to "two" 6 ms later, and "Two."
fired when equilibrium returned (`raw/live/probes_2026-11-01.txt`). With three commands in one alias, the first ran first,
and all three replies came before one prompt. The second and third gave the same say-like refusal, so their order cannot be
seen. The first alias fights answered what an off-balance spender inside an alias does: the game holds it (below).
The logs add two more strict cases, and one rewrite
that lost a race (`3ys7NuHA` rows 2666, 2677). 309 rewrites drew 0 complaints, at up to 9 per second. HELP ALIASES: `/`
separates commands, names are up to 12 characters, and it states no limit on count or length. The game echoes
each rewrite (`Alias "x" will now execute: ...`), so a live use needs a gag; `006_GAG` and `011_GAG2` already gag such
lines for other names. Not proven yet: the method at our higher send rate. Step 3 of the plan tests it behind a flag.

## Our shim: `aconfig rounds` (2026-11-01)

**Shipped in v4.7.470: off by default and Monk only. Its first fight with people attacking us was on 2026-11-03.** `aconfig rounds alias` turns it on for
the class, and the setting is saved per class. With the flag off, every send is byte-identical to before. It never applies while the basher
is on. Bashing is a later step.

`ataxia_roundDeliver` (`ataxia/ataxia/003_Queueing_Related.lua`) sits in the send wrapper (`misc_scripts/031`), after the
trait filter, so ASSESS never reaches an alias without its trait:

    send("queue addclear free g body;stand;combo T a b c")
      -> setalias lvfree stand/g body/combo T a b c      (only if the text changed)
      -> queue addclear free lvfree

| Rule | Why |
|---|---|
| `stand` goes first and once; nothing else moves | A `free` entry has no upright condition, so it can fire while prone. The offence still owns the spender's place |
| `queue addclear freestand stand;x;y` becomes `queue addclear free lvfree` | A `freestand` entry cannot fire while prone, so that chain would wait for ever |
| `full` with a `stand` stays raw | `free` would lose the class balance condition |
| Passes through unchanged: `/`, `%`, `{`; a command ending in a direction (`stand;n`, `stand;tumble sw`); `queue add`, `insert`, `prepend`; a custom type such as `eb!p!w!t`; one command; text over 138 characters | 138 is a cautious cap. The longest alias text in our logs is 142 (`2026-10-11_shikudo-vs-runewarden-snb_attacker.txt` rows 1319, 1364, 1400). The 250-character probe is still open |
| A chain with `touch shield`, `curseward` or `reject <name>` stays raw | The next attack press rewrites the alias, and the game reads it when it fires, so a defensive key in that slot would run only if recovery came before that press. Raw, it goes at once or the auto-queue holds it. So `ts` and `cwd` send what they send with the flag off |
| A chain with `mind blackout` stays raw | It must run before the combo it hides, and that combo goes by `queue add`, raw. In an alias, the two would wait in different queues |
| `touch tentacle` ends the round; the next press sends the attack | It spends equilibrium, so the game holds each later command in the alias, past `queue addclear`. The chase lasts about 2.3 s (trigger 640) |
| A new target clears the queue: `clearqueue <type>`, or `clearqueue all` if a held command named the target in the last 6 s | The alias keeps the old name until the next press, and only ALL reaches a held command. A held `touch shield` names no target, so it does not cost a full clear. A repeat of the same name clears nothing |
| In retardation (v4.7.474): one command per round, and a press inside 1.2 s sends nothing | See [Retardation](#retardation-only-the-last-command-happens) |
| A line that replaces the round clears an alias waiting in ANOTHER queue (`clearqueue <type>`) | ADDCLEAR clears only its own queue, so that alias would still fire. A run line does not mark the queue empty, because it cannot say which press it answers: a newer round may wait there. The cost is one extra `clearqueue` when the queue type changes |

**Names:** `lv<type>` for `eq`, `bal`, `eqbal`, `class`, `free`, `freestand`, `full`. The longest, `lvfreestand`, is 11 of the
game's 12 characters. Trigger 800 gags exactly these, so a test alias such as `lvprobe` still shows.

**The gag is `deleteLine()`, not `deleteFull()`.** All 371 echoes of `pk` in our logs have a prompt right after them, but that
prompt can close other output too: `Your lungs have recovered enough...`, then the echo, then one prompt
(`3ys7NuHA` rows 1975-1977). `deleteFull` would eat it. The cost is one more prompt on screen per rewrite, and those logs
draw 12.5 prompts per rewrite anyway (4,643 prompts, 371 echoes).

**A hazard to watch in the first alias fight.** A flush has one prompt: three commands in one alias drew one
(`raw/live/probes_2026-11-01.txt`, part 3). `006_GAG` and `011_GAG2` use `deleteFull`, so if the LAST reply of a flush is one of
their refusals (`You must regain balance first.`), that round's prompt goes too. `001_QUEUE_COLOR_BALANCE` and
`007_QUEQUE_COLOR_EQUILIBRIUM` also use `deleteFull`, on `was added to your ... queue`, so an auto-queued rider would eat the
prompt in the same way. A round that ends with its spender does not do this. A round with a rider after the spender (`013` in
Rain) can.

**Readers.** We expect the run line to name the alias, until the first alias fight confirms it. `ataxia_roundRan` gives
`queue_Scan`, `shikudoLock.onQueueRan` and `shikudo.onTeleQueueRan` the chain the offence built. `aconfig rounds alias` clears
007's and 011's `runLine`, so they count a round at the press until a run line matches on this path. If the wording differs,
the MIND cap and the prelude count still move. `ataxia_roundSentText` gives the fight log and monk/004's send watcher
the alias text. The fight log header ends with `rounds raw|alias`, and a `# alias lvfree holds: ...` row gives the text at the start.

**Reload and login.** The text lives on `ataxiaTemp`, so a restart sets the alias again. So does a login: `levilogin()` clears
`ataxiaTemp.roundSend`, because a press during a dropped link records text the server never got. `misc_scripts/031` now
installs a new wrapper on a reload, around Mudlet's own `send`. The old guard kept the old wrapper until a restart.

**Answered by the first alias fight (2026-11-02, `fightlogs/2026-11-02_122916_Antoninus.log`, rows 1949-3190, v4.7.470).** The
target, Titonus, did not fight back: 0 afflictions gained and full health throughout. It tested delivery, not pressure.
- **The run line:** `[System]: Added LVFREE to your free queue.`, then `[System]: Running queued free command: LVFREE`. CONFIRMED
  live, 25 flushes. A new press first prints `[System]: Queued free commands cleared.`
- **`setalias` was never refused:** 22 sent, 22 echoed, 0 complaints. The rate was low, about 1 every 4 s.
- **`clearqueue free` with nothing queued** prints `[System]: Queued free commands cleared.` (row 3148).
- **A manual `touch tree`** prints `You touch the tree of life tattoo.` with no `[Curing]` row. Ready 14.07 s later.
- **An off-balance spender inside an alias is refused and then HELD** (row 2685). A combo spends balance, so the `srd` rider `mind
  crush` drew `You must regain balance first.` and `mind crush Titonus was added to your balance queue.` It ran 2.06 s later, at the
  next recovery (row 2715), and spent 2.45 s of equilibrium. `free` needs equilibrium, so the next combo waited: 4.46 s from combo
  to combo, against about 2.1 s. The balance queue is not cleared by `queue addclear free`, so a held rider can fire after a
  target switch.
- **The other order fails too (live test, 2026-11-02).** With both up, `mind crush <t>;combo <t> ...` spent equilibrium, and the combo
  ran only when equilibrium returned, 2.43 s later. **A Shikudo combo needs equilibrium up, and MIND CRUSH needs balance up**, so a
  balance attack and an equilibrium attack cannot share a flush in either order. A pair takes about 4.5 s (2.1 + 2.45, in Rain).
  Evidence: one sample in each order. `vv` already sends mind attacks as separate rounds. The user says KAI CHOKE behaves the same way
  (`raw/players/kai-choke-2026-11-02.txt`); 2 logged rows show it held for equilibrium. So `srd` no longer chains them.

**Answered by the group fight (2026-11-03, `ours/2026-11-03_081009_Froedine.log`, v4.7.471).** People attacked us, and the screen log has 22 `has been slain` rows. All three recordings
are on [scoreboard.md](scoreboard.md). Together: refusals 7 of 76 recoveries (0.09, against 0.77 on the raw path), `was added` 7, setup first 99 of 102, superseded 1 of 110,
no complaint. `setalias` was refused 0 of 98. The 24 s recording reaches only 2 fired rewrites and the 271 s only 3, under that bar's 5; together they make 16.
- **The game holds a command that is off balance inside an alias.** `touch tentacle` spent equilibrium, so `wield` and `combo` drew `You must regain equilibrium first.` and
  `... was added to your equilibrium queue.` (rows 428-433). The tentacle costs equilibrium even at a target that is gone: `Nothing can be seen here by that name.`,
  `Equilibrium used: 1.53s.` (rows 3239-3244).
- **`queue addclear` does not remove a held command.** Six presses cleared the free queue after that hold, and the held commands still ran (rows 434-548).
- **Held commands run BEFORE the alias, and their run line says `free`** although the game added them to the equilibrium queue: `Running queued free command: WIELD
  STAFF489282`, `...: COMBO FROEDINE ...`, `...: LVFREE` (rows 546-550). A balance hold does the same (rows 3136, 3180).
- **`CLEARQUEUE ALL` removes a held command.** The reply is `[System]: All queued commands cleared.` In `ours/`, 82 held commands came before one such row, and 0 ran after it
  unless sent again: 28 never ran, 54 were sent again.
- **An alias keeps its target until the next press.** It fired at the old target 52 ms after a switch (row 550) and 1.35 s after one (row 3838). All 4 wrong-target rows failed
  only because that person had left the room.

## Retardation: only the last command happens

MEASURED, 8 runs, 24.2 s, an inference from rows, and no HELP file states it (`ours/2026-11-03_081009_Froedine.log`, after "Kaden gestures grandly, and causes a deepfreeze",
which may or may not be the cause).
- `You move sluggishly into action.` prints once per command, when the run fires.
- **Only the last command of the last run happens,** about 1.05 s later (1.02 to 1.09): 7 of 8 runs.
- **A new run replaces the waiting one and starts the delay again.** Runs at rows 2059, 2087 and 2099 gave one combo at row 2113, 1.03 s after the last. Balance and equilibrium
  are still up while a command waits, so each press fires at once. A held key could keep an attack from ever happening.
- **`transition to oak form` was lost,** so the Oak combo behind it was refused from the old form, 3 of 3 (runs at rows 2152, 2736, 2765). Outside retardation, the
  transition worked each time a reply showed.
- `setalias` and `queue addclear` print no sluggish line.

**Our rule (v4.7.474, alias path only).** The shim sends ONE command: `stand` if prone, the staff if GMCP says it is not in hand (with no item id or no GMCP list, it assumes
the staff is in hand), the transition, and then the attack. `g body`, `g gold`, `parry` and `assess` do not take the slot. A press inside 1.2 s (1.05 s plus a send's 0.13 s) sends nothing. A target switch
lifts the gap, and shield keys and movement never wait. `ataxia.retardation` is saved, so the shim also asks for the 5 s timer of `retardationOn`: a restart cannot leave the
rounds slowed. The first slowed run of each spell still goes out whole, because the flag rises on its sluggish lines. The raw path has no such rule. **None of this has run in a fight yet.**

**Not known yet:**
- Whether a rewrite beats recovery reliably. **Group fight: 16 fired the new text, 1 the old, and 12 did not show (2026-11-03).** The first strict case on our seat (`fightlogs/2026-11-02_131934_Titonus.log`, rows 216-231):
  `sr;zz` while balance was down queued `mind impatience`, the rewrite arrived 91 ms before recovery, and `zz`'s combo fired. A press
  with balance UP fires at once, so `sr;zz` then runs `sr` now and `zz` at the next recovery (rows 88-161). That is correct, and the
  scoreboard counts it as superseded (row 95), as it does a recording's first round (row 8). The bar of 5 needs presses with balance down.
- A refused `setalias`: we would record text the server never took, and only a login or a changed round would set it again. None in 120 sends so far.
- Whether the v4.7.474 fixes hold the pass bars in a fight. `python tools/fightlog_import.py --score` prints the bars beside the
  numbers, and [scoreboard.md](scoreboard.md) holds every log. It splits a log at its first `setalias lv...` row or queue line naming a round alias, so one recording scores as a raw part and an alias part.

**Still raw on purpose:** `queue add free <chain>`, and MIND BLACKOUT's whole press with the combo it hides (`011`, off by
default). The plan's shim covers ADDCLEAR only.

**A raw-path fault, pinned and not fixed.** The raw run line shows only the chain's first command (`G BODY`), so `011` sees no
`combo` in it, and a combo that ran does not end vv's burst. Once a run line has matched, `comboQueued` does not end it either,
so at the cap (4) Rain's burst stays over. The alias path reads the whole chain and does not have this fault
(`test_shikudo_telepathy.lua`).

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
