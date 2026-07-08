# Basher Configuration

## Namespace

All config stored in the global `ataxiaBasher` table. Persisted to `getMudletHomeDir()/basher` via `table.save/load` with `_ataxia_backup` fallback.

## Core Settings

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `enabled` | bool | false | Master enable/disable |
| `paused` | bool | false | Temporary pause |
| `manual` | bool | false | Manual movement mode |
| `areabash` | bool | false | Auto-pathing mode |

## Thresholds

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `fleeThresholdPct` | number | 25 | HP % to trigger flee |
| `shieldThresholdPct` | number | 40 | HP % to auto-shield |
| `fleeRecoveryPct` | number | 70 | Legacy (now hardcoded 100% for return) |
| `fleeTimeout` | number | 20 | Circuit breaker timeout (seconds) |

## Target Lists

Per-area mob targeting:

```lua
ataxiaBasher.targetList = {
  ["Moghedu"] = { "a mhun guard", "a mhun worker", keyword = "mhun" },
  ["Azdun"]   = { "a zombie", "a skeleton" },
}
```

## Auto-Learn & Own Denizens

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `autoLearn` | bool | true | Auto-add room denizens to the current area's `targetList` on entry |
| `ownDenizens` | table | `{"falcon","baalzadeen"}` | Case-insensitive substring keywords for pets/allies to never auto-add or target |

`autoLearn` (toggle with `ataxia setup basher autolearn on/off`) means you no longer
hand-build a `targetList` per area — walking through populates it. `ownDenizens`
carves out the exceptions: any denizen whose name contains one of these keywords
(e.g. `falcon` matches "a razor-beaked falcon") is skipped by auto-learn, slain
auto-add, target selection, and `bash add`, **without** skipping the room (contrast
`mobIgnore`). Adding a keyword via `bash mine add <kw>` also purges existing matches
from every `targetList`. See safety-systems doc for the exclusion points.

## Safe Rooms

Per-area flee destinations with optional recovery threshold:

```lua
ataxiaBasher.safeRooms = {
  ["The Alcazar"] = { room = 53454, recoveryPct = 100 },
}
```

## No-Flee Areas

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `inMnemosyne` | bool | false | Set by the Mnemosyne SURVEY trigger; marks the current instance as no-flee |

Areas where fleeing is impossible (World Tree, Mnemosyne) shield instead of fleeing
and keep attacking. Detection and behavior are covered in the safety-systems doc.

## Pathfinding

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `stuckTimeout` | number | 15 | Seconds before stuck detection |

Paths stored in `ataxiaBasherPaths[areaName] = {room1, room2, ...}`. Persisted to `getMudletHomeDir()/basherpaths`.

## Combat Options

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `goldPack` | string | "pack436363" | Container for gold auto-pickup |
| `cullingBlade` | bool | false | Enable reap finisher |
| `jabBash` | bool | false | Dragon: jab instead of gut |
| `wotBash` | bool | false | Dragon: whip instead |
| `dragonIncant` | bool | false | Dragon: use incantation |
| `nicator` | bool | false | Draw nicator card pre-combat |
| `gemCloaking` | bool | false | Gemcloaking (Moghedu) |
| `rageraze` | bool | false | Raze during battlerage |
| `rageConserveThreshold` | number | nil | Skip rage if mob HP ≤ this % |

## Safety Options

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `mobIgnore` | table | {} | Mobs that cause room skip |
| `dangerList` | table | {} | Dangerous mob names |
| `dangerCount` | number | 0 | Max dangerous mobs before skip |
| `ignore` | table | {} | Players to allow in room |
| `fleeFromPlayers` | table | {} | Per-area hostile player lists |
| `wandReflection` | bool | false | Use wand of reflection emergency |
| `wandId` | string | "wand" | Wand item ID |
| `bloodMaiden` | bool | false | Blood maiden cloak |
| `bloodMaidenBosses` | table | {} | Boss mobs for cloak trigger |

## Shield Timers

Per-mob shield duration tracking for target-swapping:

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `shieldTimers` | table | {} | Per-mob name → seconds |
| `shieldTimerDefault` | number | 3.1 | Fallback shield duration |

## Battlerage

Per-class rage ability definitions:

```lua
ataxiaBasher.battlerage["Infernal"] = {
  small = "seize " .. target,
  large = "fusillade " .. target,
  raze  = "raze " .. target,
  special = "rampage",
}
```

## Legend Deck Rules

Pre-combat card draws based on room conditions:

```lua
ataxiaBasher.ldeckRules = {
  { condition = function() ... end, cards = {"maran", "matic"} },
}
```

## User Commands

| Command | Purpose |
|---------|---------|
| `bash` | Toggle manual basher |
| `abr` | Toggle auto-bash rotation |
| `bash pause` | Pause/unpause |
| `bash threshold <hp>` | Set flee HP threshold |
| `bash add` | Show room denizens not in the target list; click to add |
| `bash ignore` / `bash unignore` | Manage `mobIgnore` (mobs that cause room skip) |
| `bash mine` | List own denizens (pets/allies); click to remove |
| `bash mine add <keyword>` | Add an own-denizen keyword + purge existing matches from target lists |
| `bash mine rem <keyword>` | Remove an own-denizen keyword |
| `bsi <name>` / `bsi all` | Manage the player `ignore` list (allow in room) |
| `ataxia setup basher` | Setup wizard |
| `ataxia setup basher autolearn <on\|off>` | Toggle auto-learning denizens |
| `ataxiadmg [filter]` | Mob damage database query |
| `resetbashstats` | Reset session kill stats |
| `showbashstats` | Display session stats |
