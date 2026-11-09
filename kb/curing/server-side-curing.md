---
topic: server-side-curing
confidence: CONFIRMED (HELP 13.7.8) + CONFIRMED-in-code where marked
sources:
  - kb/raw/help/13.7.8_server-side-curing.txt
code:
  - src_new/scripts/levi_ataxia/levi/ataxia/ataxia/002_Prio_Management.lua   # ataxia_sendCuringPriority
  - src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua
  - src_new/scripts/levi_ataxia/levi/ataxia/ataxia/008_Bash_Curing_Profile.lua
  - src_new/scripts/levi_ataxia/levi/ataxia/ataxia/009_Curingset_State.lua
  - src_new/scripts/levi_ataxia/levi/levi_scripts/class_detect/001_Class_Detect_Engine.lua   # calls ataxia_switchCuringsetSend
  - src_new/scripts/levi_ataxia/levi/ataxia/login/001_Login_Function.lua   # ataxia_loginCuringsetNormal, the login read
last_verified: 2026-10-10
---

# Server-side curing (SSC)

SSC is the game's built-in curing. It cures at a rate that simulates **average latency**, so
very low-latency players can be slightly faster client-side. **Our package does not cure
client-side. It configures SSC** (priorities, curingsets, toggles) and overrides it at the
right moments. The full command list is the raw HELP file. This page covers what matters for
our code.

## Toggles and thresholds

| Command | What it does |
|---|---|
| `CURING ON/OFF` | The whole system |
| `CURING AFFLICTIONS / DEFENCES / SIPPING / TRANSMUTATION ON/OFF` | Each part separately |
| `CURING SIPHEALTH / SIPMANA <pct>` | Sip thresholds |
| `CURING MOSSHEALTH / MOSSMANA <pct>` | Moss/potash thresholds (their own clock, not the eat's: [CONFLICTS](../CONFLICTS.md), Resolved 2026-11-07) |
| `CURING PRIORITY HEALTH / MANA` | Which pool to favour when regenerating |
| `CURING FOCUS ON/OFF`, `CURING FOCUS FIRST/SECOND` | Use FOCUS, and whether before or after herbs |
| `CURING TREE ON/OFF [CUSTOM]` | Use the tree; `CUSTOM` enables tree scenarios |
| `CURING USECLOT ON/OFF`, `CURING CLOTAT <n>` | Clot bleeding above n |
| `CURING FALLBACK ON/OFF` | Use the herb/mineral alternative when out of one |
| `CURING MOUNT <mount>`, `CURING USEVAULT ON/OFF` | Mount for the vault ability |
| `CURING KAIDOTRANSMUTE` | Monk TRANSMUTE; skipped while you know you have recklessness |
| `CURING BATCH ON/OFF` | Send several cures at once. We turn it **off under aeon/retardation**, one action at a time (`misc_scripts/004_Retardation_Management.lua` `retardationOn`). |
| `CURING HEALTHAFFSABOVE <n>` | Health threshold above which the health elixir is used for curing |

## Priorities (the main lever)

| Command | Notes |
|---|---|
| `CURING PRIORITY LIST` | Show the affliction order |
| `CURING PRIORITY <aff1> <p1> [<aff2> <p2> ...]` | Several in one command (the MULTI-SET form: use it for bulk changes). **Writes a STORED priority into the ACTIVE curingset.** |
| `CURING PRIORITY INSERT <aff> <p> [all]` | Insert |
| `CURING PRIORITY RESET` | Back to the default |
| `CURING PRIORITY DEFENCE LIST` / `<name> <1-25>` / `<name> RESET` | Defence upkeep order. **No default is provided.** |
| `CURING PRIOAFF <aff>` / `NONE` | **Temporary** priority until cured. Writes nothing stored, so it is always safe. |

Rules from our code and history (CONFIRMED-in-code; details in CLAUDE.md, "Server-Side Curing"):
- **At most 5 `CURING PRIORITY` commands a second** (Announce #5450). Over it, the server answers "You have exceeded the spam threshold for curing priority. Please see Announce #5450 for details." and DROPS the write. Bulk changes must use the multi-set form; our table goes out as about 8 commands of 20 pairs (v4.7.403), and trigger 787 re-sends it if a refusal is ever seen.
- **Route every write through `ataxia_sendCuringPriority()`.** It throttles to 4 commands per
  second (the server allows 5) and refuses stored writes while the PvE `bash` set is active.
  A swap we will undo goes through `ataxia_setAffPrio` or `ataxia_sendPrioSwap`, which use it and record the swap.
  The one exception is the batch at a `classDetect` switch (below): it is one `send()` for the order it guarantees, charged to the same window.
- **Base and per-stack priorities** (announced 2026-08-19, not in HELP 13.7.8):
  `CURING PRIORITY BURNING 8` sets the base, and `BURNING5 2` overrides at exactly five
  stacks. A bare write never beats an existing per-stack entry.
- Priority 26 = never cure. We use it for blindness, deafness and insomnia, which are kept as
  defences.
- Nothing parses a rejected `curing priority` command. After changing names, check with
  `CURING PRIORITY LIST`.
- **Every stored swap trusts the cache of the active set.** `ataxia.curingprio` mirrors the ACTIVE set only, once a `classDetect` switch, a login read of a class set or a typed list has refreshed it
  (`719_Affliction_Set.lua`:39-40; a `classDetect` switch empties it, below; after a login it can hold another set's values, Limits below). Since 2026-11-08 `Algedonic.ApplySwaps` also tests it before
  WATER, paraAst, astWear and fratLock (`algedonic_defense_1.0/001_Anti_Priorities.lua`:168-227),
  so a gain no longer re-sends a write the server holds (the write throttle is the point).
  The swaps key on our TARGET's class, not our attacker's ([CONFLICTS](../CONFLICTS.md) #75).

## Curingsets

`CURINGSET NEW / LIST / SWITCH / DELETE / RENAME / CLONE <from>`, and `CURINGSET EXPAND`
(25 credits, non-refundable). Each set holds its own affliction and defence priorities.
**There is a hard cap.** A live capture showed 22 of 22 in use, so `CURINGSET NEW` can fail
silently. `ataxia/009_Curingset_State.lua` reads `CURINGSET LIST` before creating anything.

### One priority list per set (v4.7.480)

The user, 2026-11-08: "The purpose of curing sets is to set priorities based on the class you are facing. Classes through skills can only give specific afflictions. So we do curing  sets for them. If Infernal can never give impatience. no need for Impatience to be curing priority impatience 2"

So each class set keeps its own values. The code is `ataxia/ataxia/002_Prio_Management.lua` (:163-258), called by
`classDetect`. **None of this has run in Mudlet.** The tests are `src_new/tests/test_curingset_priorities.lua` (227), on a fake
server with one table per set and the real triggers 716-719. Fuzz runs on that fake server (scratch scripts, not in the repo; up to 1500 seeds a run, the last two 800 seeds each on the final code, over swaps, switches, lost replies, lag, reloads and refused writes) ended with no wrong value. What the real server does is under Limits.

- **What is tracked.** `ataxia.curingprio` mirrors the ACTIVE set, once a switch, a login read or a typed list has refreshed it (Limits). `ataxiaPrioSets` holds per set `baseline` (its own values, read from the game), `live` (swaps we wrote that the game has not confirmed back),
  `restoring` (a single restore on its way) and `seeded` (own values from the file, below). `echoes` holds the confirmation lines still to come, per name. `ataxiaPrioSets`
  is not saved with `ataxia`. A package reload or a connection keeps all of it but the reads in flight (`ataxia_prioSetsReset`, :234), because a swap that is up when
  the link drops is still up on the server. A later read treats those names, and names still on their way back, as stale and keeps the old baseline for them (`swappedNames`, :541; :555, :770-774). Names swapped after the read was asked count too (:773).
- **The switch is one send.** `ataxia_switchCuringsetSend(name, from)` (:595) sends `curing priority a 1 b 2` (the set we leave, back to
  its own values, while it is still active), then `curingset switch <name>`, then `curing priority list`. The server runs a
  send's commands in order, so the list cannot hold a later swap. The three `classDetect` sites call it through `switchSend`
  (`class_detect/001_Class_Detect_Engine.lua`:214). Queued stored writes are dropped at the switch and defence writes kept. If the
  throttle window has no room the read gives way. On a class set with no baseline `readAgain` (:562) asks again; on a repeat visit or on `normal` nothing does (Limits). The first switch after a login with the set unknown puts nothing back, because the set we would leave is a guess. With the bash profile active the switch goes out alone and `bashcuring.restoreTo` moves to that set (:603-608), so bash off leads where the server now is. Only the two-attackers path can get there (`class_detect/001`:356), because `switchCuringset` and `resetToNormal` return while the profile is active. The server then leaves the bash set while the profile still reads active, and that switch empties no cache and reads no list.
- **The cache empties at the switch,** so `ataxia_getPrio` answers 0 until the list arrives. `~= N` and `< 26` guards see 0 and send, and
  the write goes after the batch, so it lands after the list. The two `> N` guards (psionBleed, Magi dehydrated, in `001_Anti_Priorities.lua`)
  wait for the list and act on the next affliction event. If no list comes, they stay closed for that visit (Limits).
- **The read is hidden.** Trigger 716 now matches the real header, `Your affliction curing priorities for the priority set <name>:`
  (`raw/live/curing-priority-list_normal_2026-10-10.txt`). Its old exact pattern could not match that header, so the chain 716/717/718 could not open on it
  since at least that capture. That is one capture; `kb/raw` holds no banner line from 716 or 718, which fits but does not prove it. When the header names a set we asked about within 3 s (`LIST_TIMEOUT`, :226), the triggers and a temporary trigger delete
  the lines and fill that set's baseline (`ataxia_prioListHeader`, :729). A read that is cut off fills nothing. What the game prints for the restore and the switch is not hidden, and neither is the prompt after the list. A reply slower than 3 s is no longer expected: it prints and fills the cache, like a list the user typed.
- **A list the user types** prints the game's own lines and changes no baseline. The chain opens now, so it refreshes the cache and saves the
  settings (718), which it could not do since at least that capture. A wrapped continuation row is not read on that path. The one exception is under Limits.
- **The restore rule.** `ataxia_restorePrio` (:469) writes what `ataxia_defaultPrioAff` (:313) answers: on a class set, that set's baseline value, else the value the file kept for a name left up at a restart, and no
  write at all if neither is known; on `normal`, the table in `ataxia_defaultCuringPrios()`; on the `bash` set the guard drops the write as before. While the set is unknown the answer is nil, and with no link nothing is sent.
- **A restore counts when the game confirms it.** The name stays live until trigger 719 prints that name with that value (`restoring`, :485-487; `ataxia_prioTuned`, :788). A write that was refused or dropped from the queue leaves the swap up, and the next switch puts it back. A new swap over a restore still on its way keeps its live mark.
- **What a line means** (:366-409). "You have set the 'x' affliction to the N priority." can arrive from the set we just left, at any lag. `echoes` lists the lines we expect, per name, so none is adopted by the set we are in, across a reload too. There are three kinds of entry. A **leaving** entry (`from`, `seq`) is a name leaving that set at a switch: its line takes it off for good, and if the batch's replies end without it (the header of the read sent after that batch, or 3 s), the name goes back to `live[from]`, because the restore did not land, and stays as a plain entry. A **cancelled** entry is a single restore overtaken by a newer swap: its line is old news and takes neither a leaving name nor a newer restore's token. A **plain** entry is a swap's own line, recorded when the swap is marked live (`markLive`, :412), or a line we no longer wait for.
  A line is matched to a cancelled entry first, then a leaving one, then the oldest plain one (`takeEcho`, :393). A name's list is trimmed to 8 by dropping its oldest entries that are not leaving, cancelled ones included; a leaving entry is never dropped (`addEcho`, :382). A line whose entry was dropped this way counts as a line with no entry. An entry that never gets its line (a refused swap, one dropped from the queue) costs at most one non-adoption of an equal value or one extra restore.
- **The quiet window.** Until `quietUntil` a line with no entry is not adopted (:803). It opens for 3 s when reads are overdue: a read that gave up, a read that gave way at a switch, a reload with a read due (`holdLateLines`, :230, which never shortens a longer window). It survives a reload. A bash install opens one for its whole length (`008_Bash_Curing_Profile.lua`:281-283), because the state still names the set we came from while those confirmations belong to the bash set.
- **A swap needs a baseline.** On a class set whose list has not been read, `ataxia_setAffPrio` and `ataxia_sendPrioSwap` write nothing, and
  `ApplySwaps` sends again on the next gain. The same holds on any set while it is unknown (Login). A read that gave way or was lost is asked again, by direct send, at most 3 times (a wait for throttle room uses up a try), while that set is still active.
- **New stored swaps** go through `ataxia_setAffPrio` or `ataxia_sendPrioSwap` (:458), so a switch puts them back. `ataxia_sendCuringPriority` alone
  is for writes we never undo: the default table and the [+]/[-] links. On a class set, a value the user types or clicks during a visit is adopted
  into that set's baseline (`ataxia_prioTuned`, :788, from trigger 719), unless the line is one we expect, the set is unknown, a read is due, the quiet window is open or the name is live. `normal` has no baseline, so a restore there still writes the table.
- **Timers across a switch.** `ataxia_sendDefaultPrios` stops at a `classDetect` switch or bash on (`ataxiaPrioGen`, bumped by `ataxia_switchCuringsetSend` and
  `ataxia_bashProfileOn`), and the table stays marked unsent. A typed switch, a login's switch or bash off does not stop it. A write through `ataxia_sendCuringPriority` never passes the queue, the drain drops stored writes while the bash
  set is active, and the drain's armed flag is local, so a queue restored from a save cannot block later writes.
- **`reset prios` asks the game first** (`ataxia_resetPrios`, `001_Default_Curing_Prios.lua`:187), because the table belongs in `normal` and the tracked state cannot see a typed `curingset switch`. It writes only when the game says `normal` and no `classDetect` switch or bash on has gone out since the ask. Otherwise it writes nothing and prints "Priorities NOT reset: the active curing set is ...". While bashing it does not ask, and `ataxia_sendDefaultPrios` leaves the bash set first, as it always did (Limits). `ataxia_prioSyncCheck` (:156) has the same stop for a switch made during the ask.
- **Login.** `levilogin` first calls `ataxia_prioLoginStart` (:812): the link is back, and which set the server is on is not known. A new Lua state starts with the state on `normal`, whatever the server is on. Until the set is known (`ataxiaPrioSets.unknown`) no swap and no restore goes out, `ataxia_defaultPrioAff` answers nil, and no line is adopted.
  `levilogin`'s six switches to normal go through `ataxia_loginCuringsetNormal` (`login/001_Login_Function.lua`:19), which moves the state, makes the set known and, if the bash profile is active, moves `bashcuring.restoreTo` to `normal`, so bash off leads where the server now is.
  Last in `levilogin`, `ataxia_prioLoginRead` (:822) asks the game with `CURINGSET LIST` and sends no switch. The answer is adopted unless a switch went out since the ask or the bash profile holds the set: the state moves to the `(current)` set, the cache empties if that changed it, and a class set gets a hidden read even when it has a baseline. While the set is still unknown, a lost reply asks once more, then prints "Could not read the active curing set. Priority swaps stay off until the next class switch.", and the set stays unknown until a `classDetect` switch or bash off.
  The login's list is hidden (`ataxia_curingsetRefresh(cb, quiet)`, `009_Curingset_State.lua`:157). Only list-shaped lines from the header through the total line are deleted, so a game line inside the window still prints. The flag is a local in 009, so it is never saved. A typed `curingsets` and `reset prios` still print the list, and so does a login capture that a caller joins without `quiet`.
- **A login during a hunt.** With the bash profile active the answer is not adopted and the set stays unknown. Bash off names the set it goes to, so `ataxia_prioBashReleased` (:862, called from `ataxia_bashProfileOff`, `008_Bash_Curing_Profile.lua`:386) ends unknown, moves the state to that set, empties the cache if the set changed, and asks for a hidden read if it is a class set. It sends no extra switch, and with no link it does nothing. If the server answers the bash set with the profile off, swaps stay off and one line says so, only while the set is still unknown: "The server is on the bash curing set. Priority swaps stay off until the next class switch."
- **A link drop.** `sysDisconnectionEvent` sets `offline` (`ataxia_prioLinkDown`, :265) and `levilogin` ends it. Until then a send would be lost, so `switchSend` moves no state (`class_detect/001`:216), a switch and a restore send nothing, and a confirmation that arrives after the event does not clear a name.
- **A Mudlet restart** loses `ataxiaPrioSets`, so the names left up and each one's own value go to `ataxia_curingset_swaps.lua` in the profile folder (:179; `liveSnapshot`, :331). A name on its way back counts until the game confirms it. The profile folder is synced by OneDrive, so a change arms one 1-second timer and the file is written only if its content differs. Only a Lua state with no `ataxiaPrioSets` reads it (:256). Those values (`seeded`) answer a restore or a switch until that set's first read. They are never a baseline, so they open no swap and do not stop that read. A missing or damaged file costs only what it would have restored, and prints nothing.
- **A save taken during a `CURINGSET LIST` read** kept `_csCallbacks` as an empty table, which `ataxia_curingsetRefresh` would take for a capture in flight, for good. `ataxia_loadSettings` drops the `_cs*` fields after the merge (`001_Save_Load_Settings.lua`:343).

**Limits.** **Nothing has run in Mudlet or against the real server.** Unproven there: `deleteLine()` from the temporary triggers in 009 and 002 (the login's hidden list, and the read's empty and continuation rows, checked only on the mock), the order of the server's lines, and refusal behaviour (the bench refuses only what a test tells it to). Not measured in game: whether the reply comes contiguous, whether `curing priority list` counts against the 5-a-second limit
(we count it), and how the temporary and permanent triggers order on one line (a test proves the read does not depend on it). A class-set restore with no baseline and no value from the file does nothing, and a swap needs a baseline, so a one-shot swap on a first visit is dropped. A swap left behind before this version reads as that set's own
value. A typed `curingset switch` is untracked. A list the user types within 3 s of a lost read of the same set answers that read: it is hidden and fills the baseline, with the names swapped since kept at their own values. `reset prios` while bashing still lands the global table in the set it returns to, which can be a class set. Bash on and off switch with a raw send and leave the cache and the state alone, except that bash off ends an unknown set. The client's fixed
one-second window against the server's sliding one can still draw a refusal.

- **The set can stay unknown.** After two lost login replies, or a login that found the server on the bash set with the profile off, swaps and restores stay off until the next `classDetect` switch or bash off. In a party, `classDetect` stays on `normal`, so that switch may not come. The login's line says so.
- **The cache comes back from a save, and a login can keep it.** `ataxia.curingprio` is inside `ataxia`, which is saved whole (`ataxia/001_Save_Load_Settings.lua`:79), so a save during a
  class-set visit keeps that set's list. The login read empties it only when the answer moves the state, and refills it only on a class set. `ataxia_loginCuringsetNormal` moves the server to normal for six classes with no read and no reset. So after a login that lands on `normal` the cache can
  hold another set's values, until a `classDetect` switch or a typed list refreshes it. Until then a `~= N` guard can skip a swap, and
  `damnationStillEscalated` (`002_Damnation_Defence.lua`:167) can read a class value as a standing escalation. Before v4.7.480 the cache held only confirmed writes, so the
  hidden read makes this larger. Read from the code, not seen in game.
- **A visit with no list.** `readAgain` asks only for a class set with no baseline, or when a login forces it (:564), and `giveUpReads` goes through it unforced. On a repeat visit or on `normal`, a read that
  gave way to the 5-a-second budget or a lost reply leaves the cache empty for that visit, filled only name by name from the confirmation line (719). `ataxia_getPrio` answers 0,
  so a `~= N` guard sends until the game confirms that name, the two `> N` guards stay closed, and the [+]/[-] links return early (:905, :917). Read from the code, not seen in game.
- **The reply to a multi-pair write.** The restore at a switch is multi-pair, and its leaving entries expect one `You have set the 'x' affliction to the N priority.` line per pair, which is what the fake server prints. The multi-pair sends we could find in `kb/raw` are another player's, for example `curing priority Paralysis 20 Clumsiness 26` (`raw/logs/2026-11-01_elmer_alchemist-vs-serpent_loss_Z5cyffxx.txt`:38), answered by `[Prio]: Paralysis (20)` and `[Prio]: Clumsiness (26)` (:40-41). That log has no `You have set` line at all, so that client seems to reword the game's line: it supports one reply per pair and says nothing about the text. If the real reply does not match trigger 719, each restored name settles back to live at the next header or after 3 s. It is sent again at every later switch from that set, and a value tuned on it is not adopted.
- **A stacked name on the confirmation line.** No capture shows how the game names a stack there. `ataxia_prioTuned` (:791) folds `burning(5)` to `burning5` in case it is the form the list prints.
- **The cache takes every confirmation line.** Trigger 719 writes `ataxia.curingprio` (`719_Affliction_Set.lua`:40) before `ataxia_prioTuned` decides anything, whichever set the line came from. A bash install's lines and a late line from the set we left stay in the cache until the next list.
- **A restart within a second of a swap.** The file is written a second after the change (`LIVE_WRITE_DELAY`, :328), so a restart inside that second loses the name, and the next read takes the swap for the set's own value.

## Tree scenarios

`CURING TREE SCENARIO NEW / DELETE / LIST / SHOW / ENABLE / DISABLE <name>`, plus:
- `... AFFLICTIONS <name> <aff1> [aff2...]`: touch the tree when these are present
- `... NOBAL <name> <SALVE|HERB|SIP|FOCUS|SMOKE>`: touch the tree when off that balance
- `... AFFCOUNT <name> <n>`: touch the tree at n+ afflictions

These only take effect with `CURING TREE ON CUSTOM`. **Not used by our package yet.** They
could replace some client-side tree logic, for example "tree when off the salve balance with
anorexia".

## Manual queue and predictions

| Command | Use |
|---|---|
| `CURING QUEUE ADD <cure>` / `INSERT <1-20> <cure>` / `REMOVE` / `RESET` / `LIST` | Force a cure ahead of all priorities |
| `CURING PREDICT <aff>` / `UNPREDICT` / `PREDICTIONS` | Tell SSC you think you have an affliction it cannot see (hidden afflictions, illusions) |

## Your live curing state (captured 2026-10-10)

Sources: `kb/raw/live/curing-status_2026-10-10.txt`, `curingset-list_2026-10-10.txt`,
`curing-priority-list_normal_2026-10-10.txt`, `curing-priority-defence-list_normal_2026-10-10.txt`.

**CURING STATUS** shows several settings HELP 13.7.8 does not document (CONFIRMED live):

| Setting | Value | Notes |
|---|---|---|
| Curing Method | **Transmutation** | Uses minerals (aurum, ferrum, ...), not herbs |
| Fallback Curing | Yes | Switches to the herb when out of the mineral |
| Health/Mana Priority | Health | |
| Sip health / mana at | 80% / 75% | |
| Eat moss below health / mana | 70% / 70% | Moss and potash have their own clock, not the eat's (kb/CONFLICTS.md Resolved 2026-11-07, was #11) |
| Use focus / Focus over herbs | Yes / Yes | FOCUS is tried before herbs for mental afflictions |
| Use tree / Use clot | Yes / Yes | |
| Clot at / Clot to | 100 bleeding / 0 bleeding | `CLOT TO` is not in HELP 13.7.8 |
| Use insomnia | Yes | Keeps insomnia up |
| **Will cure fractures above** | 70% health | Below 70% it skips fracture cures. Not in HELP. |
| **Will use mana above** | 45% mana | Not in HELP |
| **Will clot health until** | 20% health | Not in HELP |
| Batch actions | Yes | |
| Use Kaido Transmute | No | |

**Curingsets:** 21 of 22 used (`normal` current, plus slowcuring, infernal, waterlord, general,
depthswalker, sentinel, occultist, alchemist, apostate, **bashing**, knights, paladin, serpent,
pariah, druid, shikudo, runewarden, priest, unnamable, blademaster). The PvE `bash` set was
created after that capture: `aconfig bashcuring status` later showed it installed, existing,
and **0 free slots (22/22)**.

**Priority drift.** `python tools/kb_prio_diff.py <capture>` compares a captured
`CURING PRIORITY LIST` with `ataxia_defaultCuringPrios()`. On 2026-10-10 the `normal` set held
**January's table**, not the current one: broken arms at 1 (ours 10), broken legs at 2 (ours 7),
weariness 7 (ours 6), horror 10 (ours 9), crescendo 6 (ours 9), healthleech 9 (ours 8),
scytherus 2 (ours 3). **Why:** the table is only sent by the `reset prios` alias
(`combat_aliases/008`). Nothing sent it at login (`ataxia_resetOnLogin` has no caller), so no
table change since v4.7.276 (2026-08-19) had reached the server. **Fixed in v4.7.397:** sending the
table stores a fingerprint (`ataxia.settings.prioSentSig`), and 20s after login
`ataxia_prioSyncCheck()` re-sends a changed table, but only after the game confirms the active
set is `normal`. In any other set it tells you to `reset prios` from `normal` instead of writing.
Since v4.7.480 `reset prios` asks the same question first. **Class sets** (serpent, apostate, ...) are copies and are never updated by this.

**Orphan per-stack rows.** The live set still holds `horror2-5`, `burning2/3`, `pyre2`,
`unweavingbody2`, `unweavingmind2` from older tables. Deleting a key from our table never deletes
the server row (CLAUDE.md, base + per-stack). Each one equals or is close to its base today.

**Every curable affliction is now in our table (v4.7.402).** Of the 85 the game lists that the table never named, 71 cannot be cured by SSC (60 wear off, 11 have no cure). The other 14 are set: 11 at the server's own value, plus three changes: `tonguetied` 7 -> 18 (it only blocks the stuttering cure, and at 7 it took the head restoration ahead of a damaged head), `latched` and `icebound` 1 -> 2 (slot 1 is reserved for emergency swaps), and `dazzled` added at 7 (halves damage resistance; it had no priority). `kb/afflictions/database.md` reports this coverage after every capture.

**Live afflictions our table did not set** (before v4.7.402; they kept the server default): latched 1,
icebound 1, calcifiedskull 2, calcifiedtorso 2, grievouswounds 3, mindravaged 4, dazed 5,
kkractlebrand 5, frostbite 5, tonguetied 7, internalbleeding 8, fulminated 8, earworm 8,
burning2/3 9, horror2-5 9, pyre2 9, diminished 12, unweavingbody2 25, unweavingmind2 25.

**Defence upkeep (`normal`):** 27 defences at 25: insomnia, nightsight, ghost, lipreading,
boartattoo, grookbubble, density, blindness, lifevision, speed, coldresist, cloak,
electricresist, weaving, mindseye, temperance, groundwatch, insulation, fireresist, scales,
thirdeye, kola, moontattoo, deafness, fangbarrier, poisonresist, magicresist.
