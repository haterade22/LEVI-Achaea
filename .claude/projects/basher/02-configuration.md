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
| `ownDenizens` | table | `{"falcon","baalzadeen","ashbeast","hyena"}` | Case-insensitive substring keywords for pets/allies to never auto-add or target |
| `notOwnDenizens` | table | `{"a slope-backed hyena"}` (backfilled) | Real denizens exempted from the above — checked FIRST, wins over the pet keywords |

`autoLearn` (toggle with `ataxia setup basher autolearn on/off`) means you no longer
hand-build a `targetList` per area — walking through populates it. `ownDenizens`
carves out the exceptions: any denizen whose name contains one of these keywords
(e.g. `falcon` matches "a razor-beaked falcon") is skipped by auto-learn, slain
auto-add, target selection, and `bash add`, **without** skipping the room (contrast
`mobIgnore`). Adding a keyword via `bash mine add <kw>` also purges existing matches
from every `targetList`. See safety-systems doc for the exclusion points.

`notOwnDenizens` (v4.7.169) is the inverse list, and it is a full denizen name rather
than a keyword. The substring match that makes one `hyena` keyword cover every pet
variant also shields any **real** mob whose name happens to contain a pet's word;
`ataxiaBasher_isOwnDenizen` (`basher/001_Bashing_Functions.lua:348`) therefore scans
this list before the pet keywords and returns false on a hit. It is seeded by
**backfill** in `002_Check_For_Any_Missing_Variables.lua:172`, not as a fresh-install
default — existing saves already carry the bare `hyena` keyword, so a default would
have fixed nobody who hit the bug. Managed with `bash notmine [add|rem] <name>`
(alias `lists/013_Not_Own_Denizens.lua`), mirroring `bash mine`. No un-purge is
needed after adding one: auto-learn re-adds the mob on the next sighting. See the
safety-systems doc for why this is a hard stall in Mnemosyne rather than lost xp.

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
| `brAlerts` | bool | true | Highlight battlerage effects (charm/recklessness/aeon/weakness/stun) on the game line and echo a `(BR):` tag to the bash console |

### Knight Pet Attacks (cooldown-tracked)

Free pet hits prepended to the bash when off cooldown, tracked via message triggers in
`basher/005_Falcon_Cooldowns.lua`:

| Class | Command | Ready flag | Cooldown |
|-------|---------|-----------|----------|
| Infernal | `hyena maul <target>` | `hyenaMaulReady` | ~30s (message-driven, triggers 367–369) |
| Runewarden | `falcon rake <target>` | `falconRakeReady` | `falconRakeCooldownSec` (default 30s), message-driven via triggers 370–371 with a timer fallback |

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

## Mnemosyne Legend Deck (state-driven)

`ldeckRules` above is **mob-name** driven, which cannot work in Mnemosyne — the denizen
roster is different every ripple. `basher/010_Mnemosyne_Legend_Deck.lua` (v4.7.165) is the
tower layer and keys off state instead: hp, denizen count, bindings, affordable battlerage.
Gated to `ataxiaBasher.inMnemosyne`; at most one card per round.

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `mnemLdeck.enabled` | bool | true | Master switch for the card layer |
| `mnemLdeck.maranAt` | number | 20 | HP % that draws Maran (5000hp room barrier, 60s) |
| `mnemLdeck.seasoneAt` | number | 35 | HP % that draws Seasone `FOR ELIXIR` (+10% health elixir, 5 min) |
| `mnemLdeck.maticAt` | number | 3 | Denizens in the room that draw Matic (guaranteed high-end crit) |
| `mnemLdeck.conserveAt` | number | 25 | Mob-HP floor for the OFFENSIVE cards only (Matic/Covenant/Xylthus) |
| `mnemLdeckBindings` | table | `{"webbed","entangled","transfixation","constricted","snared","roped"}` | Afflictions that draw Morimbuul |

Morimbuul, Covenant and Xylthus have no threshold to tune: Morimbuul fires while any
binding in `mnemLdeckBindings` is up, and Covenant/Xylthus fire when the class can
**afford and immediately use** the battlerage that cashes in the affliction they plant
(recklessness → Blademaster Headstrike / Magi Firefall, stun → Runewarden Etch, all 25
rage). A class with no such payoff never draws them at all — planting an affliction
nothing can spend burns an hourly-regenerating charge for nothing.

`conserveAt` is the `rageConserveThreshold` idiom applied to charges, and it matters more
here: rage refills in seconds, these charges refill once an hour, so a guaranteed crit on a
mob at 5% is the purest waste in the layer. Defensive draws (Maran/Seasone/Morimbuul) are
never gated on it. Set it to 0 to disable the check; a missing GMCP mob-HP reading also
never blocks.

`mnemLdeckBindings` defaults to the whole binding family rather than webbed alone — the
card covers "denizen ropes or bindings" and every one of these is in the basher's attack
gate. Narrow it by editing the table if a charge ever feels wasted.

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
| `bash notmine` | List real denizens exempted from the pet keywords; click to remove |
| `bash notmine add <name>` | Exempt a real denizen that a pet keyword shadows |
| `bash notmine rem <name>` | Drop an exemption |
| `mnem cards [on\|off\|maran <hp%>\|seasone <hp%>\|matic <n>]` | Mnemosyne legend-deck auto-draw; bare form prints charges, intervals and whether this class has a Covenant/Xylthus payoff |
| `bash shinprobe [report\|on\|off\|dump <n>\|clear\|status]` | Measured SHIN AUGMENT duration curve (basher/012); bare form prints per-spend mean/min/max and seconds-per-shin |
| `bash augment <n>` | Shin to spend on `SHIN AUGMENT`; bare form prints the current value |
| `bsi <name>` / `bsi all` | Manage the player `ignore` list (allow in room) |
| `ataxia setup basher` | Setup wizard |
| `ataxia setup basher autolearn <on\|off>` | Toggle auto-learning denizens |
| `ataxiadmg [filter]` | Mob damage database query |
| `resetbashstats` | Reset session kill stats |
| `showbashstats` | Display session stats |


## Class-resource budgets (v4.7.264-271)

Config added after this document's original v4.7.169 pass. **Coverage note:** the tables above were
written at v4.7.169 and have not been swept since -- keys added between then and v4.7.263 may be
missing, so treat the code (`basher/001`, `basher/002`) as authoritative and this as a reading guide.

### Blademaster shin (`ataxiaBasher_blademasterBashing`, basher/002)

| Key | Type | Default | Meaning |
|-----|------|---------|---------|
| `bmInfusePrefs` | table | `{"lightning","fire","ice","void"}` | Infuse element preference; lightning-first since v4.7.269 (was fire, and that was only ever for byte-compatibility with the hardcoded `infuse fire`) |
| `bmInfuseAt` | number | 90 | **Tower only.** Minimum shin to spend on an infuse. DERIVED: Phoenix needs 80, so 90 leaves >80 afterwards -- an infuse can never be the action that takes Phoenix off the table |
| `phoenixAt` | number | 10 | HP % that fires `SHIN PHOENIX` (80 shin, consumes ALL of it, cleanses + **full heal**). `hpp > 0` is also required, since 0 means BLACKOUT rather than nearly-dead |
| `bmAugmentAmount` | number | 20 | Shin spent on `SHIN AUGMENT` (Bladed Reflexes boon). Provisional middle, not an optimum -- the duration curve is unknown and `bash shinprobe` measures it |
| `shinProbe` | table | `{on=true, samples={}}` | Accumulated (spend -> measured duration) samples, capped at 200. On the SAVED namespace deliberately: a curve needs collecting across sessions |

**Priority within a round is hardcoded POSITION, not a planner:** Phoenix (whole pool) > augment >
storm > infuse, threaded through a local `shinSpent`. Inserting anything into that order is a
breaking change -- see AGENTS.md.

### Depthswalker age (`ataxiaBasher_dwAeonicCashIn`, basher/002)

| Key | Type | Default | Meaning |
|-----|------|---------|---------|
| `dwAeonic` | bool | *(unset = on)* | Set `false` to stop the deteriorate/degenerate cash-in. **No alias exists** -- v4.7.265 documented `bash dwaeonic off`, which was never a real command |
| `dwAgeCap` | number | 400 | Age floor below which age-spending bashing abilities stand down, so bashing cannot price out the chrono kit |
