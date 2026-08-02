# Codex Adversarial Review -- v4.7.165-192

## Summary
CRITICAL: 0 | HIGH: 3 | MEDIUM: 1 | LOW: 1

The shipped fixes addressed the obvious free-charge leak and serialized-state mistakes, but the range still has a few real queue-composition hazards. The confirmed high-value failures are localized: Blademaster and Depthswalker can put two same-resource commands into one `addclearfull` line, and Infernal can stamp a per-room command as used before the shield branch discards it. The rest of the suspect space was mostly better than expected: most replay tables are short-lived `ataxiaTemp` state, most changed trigger `type:` values are correct, and `brCommit` not arming the battlerage global cooldown is intentional for replayable queued commands.

## Findings

### [HIGH] Blademaster queues `SHIN AUGMENT` and `SHIN THUNDERSTORM` in the same line
- **File**: `src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua:429`
- **Code**:
```lua
command = "shin augment "..amt..sp
...
local storm = ataxiaBasher_bmThunderstorm(sp)
...
ataxiaTemp.bmThunderstormAt = nowT
return "shin thunderstorm"..sp
...
command = command..storm..brage..sp.."infuse "..ataxiaBasher_bmInfuse().." "..sp.." "..slash
```
- **Failure scenario**: Blademaster is in Mnemosyne with `bmBladedReflexes == true`, lacks `ataxia.defences.bodyaugment`, has not set `ataxiaTemp.bmAugmentAttempted`, has at least 30 shin, has the Divine Thunder boon, is unshielded, and sees enough denizens to pass `bmThunderstormThreshold`. The rotation builds a line like `shin augment 3;shin thunderstorm;...;infuse <element>;drawslash <target>`. `shin augment` and `shin thunderstorm` both consume the same equilibrium/shin slot, so the server rejects the second command. The client has already stamped `ataxiaTemp.bmThunderstormAt`, so the thunderstorm is suppressed for four seconds even though it did not land.
- **Why it was missed**: The nearby comments acknowledge that thunderstorm shares resources with other Blademaster commands, but the actual queue behavior is worse than "try again next prompt" because the send-side stamp records a cooldown before the same-line rejection happens.
- **Remediation**: Make Blademaster choose one equilibrium/shin spender per round. If augment is queued, skip thunderstorm for that build; alternatively move both through a single round planner that tracks queued equilibrium and queued shin before stamping `bmThunderstormAt`.

### [HIGH] Depthswalker keeper words can collide with Boinad word balance
- **File**: `src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua:729`
- **Code**:
```lua
{ key = "boinad",  cmd = "intone boinad",  cost = 17, cd = 22, aoe = true, word = true, ... },
...
return k.cmd..sp
...
if ab.word then
   if ataxiaBasher.shielded then gated = true end
   if ataxiaTables and ataxiaTables.bals and ataxiaTables.bals.wordBal == false then gated = true end
end
...
ataxiaTemp.dwBrAt[ab.key] = nowT
ataxiaTemp.dwBrPending = { verb = ab.key, cmd = cmd, at = nowT }
return ataxiaBasher_brSent(cmd)
...
command = ff..ataxiaBasher_dwKeeper(sp)..ataxiaBasher_dwBattlerage(sp)..primary
```
- **Failure scenario**: Depthswalker has `wordBal == true`, is unshielded, is missing a keeper defence such as Precision so `ataxiaBasher_dwKeeper(sp)` returns `intone trusad;`, has `ataxiaBasher.dwBoinad == true`, sees at least two denizens, and Boinad is ready/affordable. The assembled command becomes `intone trusad;intone boinad <target>;shadow reap <target>`. The first `intone` consumes word balance, so `intone boinad` is rejected. The client already stamped `ataxiaTemp.dwBrAt.boinad`, armed `dwBrPending`, armed `brGlobalReadyAt`, and possibly consumed `brFreeCharge`.
- **Why it was missed**: `dwKeeper` and `dwBattlerage` each check current `wordBal` correctly in isolation. The bug appears only after concatenation, because the battlerage gate does not know that the keeper already reserved word balance for this queued line.
- **Remediation**: Track a `wordQueued` flag in the Depthswalker round. Either run Boinad before keeper by explicit priority or pass the keeper result into `dwBattlerage` and gate `ab.word` when a keeper word has already been appended.

### [HIGH] Infernal stamps Tyranny room usage before the shield branch discards the command
- **File**: `src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua:773`
- **Code**:
```lua
if ataxiaTemp.infTyrannyRoom == room then return "" end
ataxiaTemp.infTyrannyRoom = room
local cmd = (ataxiaBasher.infArmyOfDeadCommand or "tyranny")
return cmd..sp
...
local graveHands = ataxiaBasher_infGravehands(sp)
...
if ataxiaBasher.shielded then
   ...
   command = aura..quash..raze..sp..brage
elseif graveHands ~= "" then
   command = aura..maul..brage..graveHands:gsub(sp.."$", "")
```
- **Failure scenario**: Infernal has the Army of Dead boon active, enough essence, enough denizens for the threshold, and enters room `R` with a shielded target. `ataxiaBasher_infGravehands(sp)` stamps `ataxiaTemp.infTyrannyRoom = R` and returns `tyranny;`, but the later shielded branch ignores `graveHands` and sends only shield handling. After the shield drops, the helper returns `""` because the room was already latched, so Tyranny never fires in that room for the rest of the run.
- **Why it was missed**: The room latch lives inside a helper that looks like an idempotence guard, while the branch that actually decides whether the helper output is used is several dozen lines later.
- **Remediation**: Do not stamp `infTyrannyRoom` inside the helper until the command is actually included in the outgoing line. A small fix is to call `ataxiaBasher_infGravehands(sp)` only in the non-shielded branch; a stronger fix is to return `{cmd, room}` and stamp after assembly commits the command.

### [MEDIUM] Generic Culling Blade ignores Rage-Fuelled free battlerage charges
- **File**: `src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua:1183`
- **Code**:
```lua
function ataxiaBasher_rageAfford(rage, cost)
   if ataxiaBasher_brFree() then return true end
   return (tonumber(rage) or 0) >= (tonumber(cost) or 0)
end
...
if ataxia.vitals.rage >= bigRage then
   command = command.."reap "..target..sp
end
```
- **Failure scenario**: Alchemist uses the generic battlerage assembler, has `ataxiaBasher.cullingBlade == true`, has a Rage-Fuelled charge in `ataxiaTemp.brFreeCharge`, is unshielded, has 0 rage, and is not in a World Tree room. The free charge makes normal `ataxiaBasher_rageAfford()` checks pass, but the shared Culling Blade branch bypasses that helper and requires raw rage to be at least 36 or 54. The rotation skips free `reap` and may spend the free charge on a lower-value generic battlerage later in the same function.
- **Why it was missed**: The global affordability helper was fixed, and class-owned Culling Blade implementations were updated to check free charges, but the older shared culling path still uses a raw rage comparison.
- **Remediation**: Let the shared culling branch explicitly honor `ataxiaBasher_brFree()`, for example `if (tonumber(ataxia.vitals.rage) or 0) >= bigRage or ataxiaBasher_brFree() then`. Keep the existing `ataxiaBasher_brCommit(command)` wrapper so the charge is consumed exactly when a command is returned.

### [LOW] Psion ready lines do not clear Psion pending replays
- **File**: `src_new/scripts/levi_ataxia/levi/ataxia/basher/011_Battlerage_Ready_Lines.lua:112`
- **Code**:
```lua
ataxiaTemp.psionBrPending = { verb = ab.cmd, at = nowT }
...
if pend and pend.verb == field then ataxiaTemp[pendingField] = nil end
```
- **Failure scenario**: Psion queues `weave barbedblade`, so `ataxiaTemp.psionBrPending.verb` is `"weave barbedblade"`. If the server emits the ready line for Barbedblade while that pending window is still active, `BR_READY_MAP` normalizes the line to field `"barbedblade"` and clears `psionBrAt.barbedblade`, but the pending table survives because `"weave barbedblade" ~= "barbedblade"`. The next prompt replays the stale pending command for the rest of its three-second window, despite the release line having arrived. If the first command already fired, the replay is rejected by battlerage global or per-ability cooldown before trigger 329 can clean up.
- **Why it was missed**: Runewarden and Depthswalker store pending `verb` as the table key, and Golden Dragon command strings happen to match their keys. Psion is the only new replay table storing the full command prefix as `verb`.
- **Remediation**: Store both `key` and `cmd` in Psion pending state and compare the ready field against `pending.key`, or normalize the release comparison with a class-specific mapping instead of comparing raw command text.

## Suspects checked and REFUTED

### S1 -- Other assembled-line double spends
Runewarden's `bisect` replaces the normal bashing attack rather than being appended beside it, Monk chooses `choke or numb` for its equilibrium slot, Magi uses Deepfreeze/Bloodboil as replacements for the normal equilibrium staff bash, and Infernal's Arc/Tyranny balance spenders replace the swing path when used. I did not find a general "everything collides" bug beyond the Blademaster and Depthswalker cases reported above.

### S2 -- In-flight replay tables as a class
The main replay lifecycles are short-lived `ataxiaTemp` state. Legend-deck pending has arm/replay/reject/lapse/reset paths and is reset on ripple/run end. Runewarden and Depthswalker battlerage pending records store replayable commands and are released by confirmation, refusal, global cooldown rejection, or the short expiry window. The one non-total release mapping I found is the Psion key/command mismatch reported above.

### S3 -- Most un-nilled `ataxiaTemp` additions
Most listed fields are monotonic cooldown stamps or tables where staleness only reads as "ready" after enough epoch time: `rwBrAt`, `dwBrAt`, `psionBrAt`, `gdragonBrAt`, `bmThunderstormAt`, `mnemLdeckAt`, `dragonRampageAt`, `infDeathauraAt`, `infQuashAt`, and `kaiUnleashedAt`. `mnemLdeckRoom` is reset through the legend-deck reset path on ripple/run end; `reaperKills` and `kaiUnleashedAt` are cleared on run end. The actively wrong state lifetime I could make concrete is `infTyrannyRoom`, reported above, because it is stamped before the command is actually sent.

### S4 -- `ataxiaBasher_brCommit` not arming `brGlobalReadyAt`
This is fine for the paths it was added to. `brCommit` consumes the Rage-Fuelled charge without blocking replay; arming the global cooldown at assembly time would make `addclearfull` erase a battlerage command that had been selected but not yet executed. The rotations that intentionally do send-side global suppression (`brSent`) still route through it: Depthswalker/Runewarden owned battlerage do so inside their pickers, and Blademaster/Magi special battlerage do so before the shared wrapper clears the free charge. I did not find a zero-or-double `brCommit`/`brSent` path except the shared Culling Blade affordability hole reported above, which is not a global-cooldown issue.

### S5 -- Silent trigger failures in the changed Mnemosyne/boon layer
The two changed exact-match trigger patterns I checked are full-line matches, not fragments: battlerage global cooldown and the broken-arm/leg lines. The BOONS row triggers for Bladed Reflexes, Cursed Relic, Army of Dead, Divine Thunder, and Winter's Heart write the same bare globals consumed by the rotations. The WADE STATUS damage-null parser uses the expected capture indices. I did not find another dead `type: 3` fragment in the reviewed trigger range.

## Coverage
Read fully: `basher/001_Bashing_Functions.lua`, `basher/002_Class_Bashing.lua`, `basher/010_Mnemosyne_Legend_Deck.lua`, `basher/011_Battlerage_Ready_Lines.lua`, `mnemosyne/004_Parsers.lua`, `mnemosyne/008_Explorer.lua`, and `mnemosyne/009_Swarm_Tactics.lua`.

Read the changed trigger files under `src_new/triggers/levi_ataxia/for_levi/leviticus/`, including `328`, `329`, `340`, `344`, `345`, `370`, `375`, `376`, `377`, `legenddeck_cards/008`, `legenddeck_cards/009`, and `mnemosyne/001`, `032`, `049` through `054`.

Checked the changed-file list from `git diff --name-only v4.7.164..v4.7.192`, grepped the related `src_new/tests/test_*.lua` coverage, and used `CLAUDE.md`, `.claude/AGENTS.md`, `.claude/projects/basher/battlerage-pve.md`, and `.claude/projects/mnemosyne/07-explorer.md` only as claims to verify against code. I did not run the Lua test suite because this was a read-only review request, and I did not exhaustively inspect unrelated unchanged trigger directories outside the scoped changed set.
