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
  The one exception is the batch at a class-set switch (below): it is one `send()` for the order it guarantees, charged to the same window.
- **Base and per-stack priorities** (announced 2026-08-19, not in HELP 13.7.8):
  `CURING PRIORITY BURNING 8` sets the base, and `BURNING5 2` overrides at exactly five
  stacks. A bare write never beats an existing per-stack entry.
- Priority 26 = never cure. We use it for blindness, deafness and insomnia, which are kept as
  defences.
- Nothing parses a rejected `curing priority` command. After changing names, check with
  `CURING PRIORITY LIST`.
- **Every stored swap trusts the cache of the active set.** `ataxia.curingprio` mirrors the ACTIVE set only, once a `classDetect` switch or a typed list has refreshed it
  (`719_Affliction_Set.lua`:39-40; a class-set switch empties it, below; after a login it can hold another set's values, Limits below). Since 2026-11-08 `Algedonic.ApplySwaps` also tests it before
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

So each class set keeps its own values. The code is `ataxia/ataxia/002_Prio_Management.lua` (:163-192), called by
`classDetect`. **None of this has run in Mudlet.** The tests are `src_new/tests/test_curingset_priorities.lua`, on a fake
server with one table per set and the real triggers 716-719.

- **What is tracked.** `ataxia.curingprio` mirrors the ACTIVE set, once a switch or a typed list has refreshed it (Limits). `ataxiaPrioSets.baseline[set]` holds a class set's own
  values, read from the game, and `ataxiaPrioSets.live[set]` names the swaps we wrote and have not put back. `ataxiaPrioSets`
  is not saved. A package reload or a connection keeps both tables (`ataxia_prioSetsReset`, :176), because a swap that is up when
  the link drops is still up on the server. A later read treats those names as stale and keeps the old baseline for them (:322-332, :533-536).
- **The switch is one send.** `ataxia_switchCuringsetSend(name, from)` (:368) sends `curing priority a 1 b 2` (the set we leave, back to
  its own values, while it is still active), then `curingset switch <name>`, then `curing priority list`. The server runs a
  send's commands in order, so the list cannot hold a later swap. The three `classDetect` sites call it through `switchSend`
  (`class_detect/001_Class_Detect_Engine.lua`:214). Queued stored writes are dropped at the switch and defence writes kept. If the
  throttle window has no room the read gives way. On a class set with no baseline `readAgain` (:336) asks again; on a repeat visit or on `normal` nothing does (Limits).
- **The cache empties at the switch,** so `ataxia_getPrio` answers 0 until the list arrives. `~= N` and `< 26` guards see 0 and send, and
  the write goes after the batch, so it lands after the list. The two `> N` guards (psionBleed, Magi dehydrated, in `001_Anti_Priorities.lua`)
  wait for the list and act on the next affliction event. If no list comes, they stay closed for that visit (Limits).
- **The read is hidden.** Trigger 716 now matches the real header, `Your affliction curing priorities for the priority set <name>:`
  (`raw/live/curing-priority-list_normal_2026-10-10.txt`). Its old exact pattern could not match that header, so the chain 716/717/718 could not open on it
  since at least that capture. That is one capture; `kb/raw` holds no banner line from 716 or 718, which fits but does not prove it. When the header names a set we asked about within 3 s (`LIST_TIMEOUT`, :194), the triggers and a temporary trigger delete
  the lines and fill that set's baseline (`ataxia_prioListHeader`, :495). A read that is cut off fills nothing. One prompt line after the hidden list still prints.
- **A list the user types** prints the game's own lines and changes no baseline. The chain opens now, so it refreshes the cache and saves the
  settings (718), which it could not do since at least that capture. A wrapped continuation row is not read on that path.
- **The restore rule.** `ataxia_restorePrio` (:281) writes what `ataxia_defaultPrioAff` answers: on a class set, that set's baseline value, and no
  write at all if it is unknown; on `normal`, the table in `ataxia_defaultCuringPrios()`; on the `bash` set the guard drops the write as before.
- **A swap needs a baseline.** On a class set whose list has not been read, `ataxia_setAffPrio` and `ataxia_sendPrioSwap` write nothing, and
  `ApplySwaps` sends again on the next gain. A read that gave way or was lost is asked again, by direct send, at most 3 times, while that set is still active.
- **New stored swaps** go through `ataxia_setAffPrio` or `ataxia_sendPrioSwap` (:270), so a switch puts them back. `ataxia_sendCuringPriority` alone
  is for writes we never undo: the default table and the [+]/[-] links. A value the user types or clicks during a visit is adopted
  into that set's baseline (`ataxia_prioTuned`, :547, from trigger 719), unless a read is due or the name is live.
- **Timers across a switch.** `ataxia_sendDefaultPrios` stops at any set change (`ataxiaPrioGen`, bumped by `ataxia_switchCuringsetSend` and
  `ataxia_bashProfileOn`), and the table stays marked unsent. A write never passes the queue, the drain drops stored writes while the bash
  set is active, and the drain's armed flag is local, so a queue restored from a save cannot block later writes.
- **Login.** `levilogin`'s six switches to normal go through `ataxia_loginCuringsetNormal` (`login/001_Login_Function.lua`:18), so
  `classDetect.state.currentCuringset` moves only where the server moves.

**Limits.** Not measured in game: whether the reply comes contiguous, whether `curing priority list` counts against the 5-a-second limit
(we count it), and how the temporary and permanent triggers order on one line (a test proves the read does not depend on it). A class-set restore does nothing until the first read of
that set since Mudlet started, so a one-shot swap on a first visit is dropped. A swap left behind before this version reads as that set's own
value. A typed `curingset switch` is untracked. Bash profile switches stay raw: the cache and the state are left alone. The client's fixed
one-second window against the server's sliding one can still draw a refusal.

- **The cache comes back from a save.** `ataxia.curingprio` is inside `ataxia`, which is saved whole (`ataxia/001_Save_Load_Settings.lua`:79), so a save during a
  class-set visit keeps that set's list. `ataxia_loginCuringsetNormal` moves the server to normal for six classes with no read and no reset. After a login the cache can
  hold the values of the set active at the last save, until a `classDetect` switch or a typed list refreshes it. Until then a `~= N` guard can skip a swap, and
  `damnationStillEscalated` (`002_Damnation_Defence.lua`:167) can read a class value as a standing escalation. Before v4.7.480 the cache held only confirmed writes, so the
  hidden read makes this larger. Read from the code, not seen in game.
- **A visit with no list.** `readAgain` asks only for a class set with no baseline (:338), and `giveUpReads` goes through it. On a repeat visit or on `normal`, a read that
  gave way to the 5-a-second budget or a lost reply leaves the cache empty for that visit, filled only name by name from the confirmation line (719). `ataxia_getPrio` answers 0,
  so a `~= N` guard sends until the game confirms that name, the two `> N` guards stay closed, and the [+]/[-] links return early (:584, :596). Read from the code, not seen in game.

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
**Class sets** (serpent, apostate, ...) are copies and are never updated by this.

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
