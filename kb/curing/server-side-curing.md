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
| `CURING MOSSHEALTH / MOSSMANA <pct>` | Moss/potash thresholds (eating balance!) |
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
| `CURING PRIORITY <aff1> <p1> [<aff2> <p2> ...]` | Several in one command. **Writes a STORED priority into the ACTIVE curingset.** |
| `CURING PRIORITY INSERT <aff> <p> [all]` | Insert |
| `CURING PRIORITY RESET` | Back to the default |
| `CURING PRIORITY DEFENCE LIST` / `<name> <1-25>` / `<name> RESET` | Defence upkeep order. **No default is provided.** |
| `CURING PRIOAFF <aff>` / `NONE` | **Temporary** priority until cured. Writes nothing stored, so it is always safe. |

Rules from our code and history (CONFIRMED-in-code; details in CLAUDE.md, "Server-Side Curing"):
- **Route every write through `ataxia_sendCuringPriority()`.** It throttles to 4 commands per
  second (the server allows 5) and refuses stored writes while the PvE `bash` set is active.
- **Base and per-stack priorities** (announced 2026-08-19, not in HELP 13.7.8):
  `CURING PRIORITY BURNING 8` sets the base, and `BURNING5 2` overrides at exactly five
  stacks. A bare write never beats an existing per-stack entry.
- Priority 26 = never cure. We use it for blindness, deafness and insomnia, which are kept as
  defences.
- Nothing parses a rejected `curing priority` command. After changing names, check with
  `CURING PRIORITY LIST`.

## Curingsets

`CURINGSET NEW / LIST / SWITCH / DELETE / RENAME / CLONE <from>`, and `CURINGSET EXPAND`
(25 credits, non-refundable). Each set holds its own affliction and defence priorities.
**There is a hard cap.** A live capture showed 22 of 22 in use, so `CURINGSET NEW` can fail
silently. `ataxia/009_Curingset_State.lua` reads `CURINGSET LIST` before creating anything.

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
