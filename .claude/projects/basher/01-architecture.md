# Basher Architecture

## State Machine

The basher has 7 states controlled by flag combinations:

| State | `enabled` | `paused` | `manual` | `areabash` | `bashFlee` | `fleeReturning` |
|-------|-----------|----------|----------|------------|------------|-----------------|
| Idle | false | false | false | false | false | false |
| Manual | true | false | true | false | false | false |
| Areabash | true | false | false | true | false | false |
| Paused | true | true | * | * | false | false |
| Fleeing | true | true | * | * | true | false |
| Returning | true | false | * | * | false | true |
| Shielded | true | false | * | * | false | false |

### State Transitions

```
Idle → Manual:    ataxiaBasher_manual()
Idle → Areabash:  ataxiaBasher_areabash()
Any → Idle:       ataxiaBasher_areaoff() or manual() toggle-off
Any → Fleeing:    ataxiaBasher_executeFlee() (HP ≤ 25%)
Fleeing → Returning: ataxiaBasher_checkFleeRecovery() (HP = 100%)
Returning → Manual/Areabash: Room_Update arrival at origin room
Any → Idle:       ataxiaBasher_onDeath() or ataxiaBasher_onAttacked()
```

## Dispatch Chain

```
Prompt (GMCP vitals)
  └─ ataxia_promptCommands()          [010_Prompt_Running.lua:57]
     ├─ ataxiaBasher_scanRoom()       [if need_roomCheck]
     ├─ search_targets()              [genrunning/002:100]
     ├─ ataxiaBasher_checkFleeRecovery() [basher/001:256]
     └─ ataxiaBasher_patterns()       [genrunning/004:162]
        └─ ataxiaBasher_tryAttack()   [genrunning/004:107]
           └─ ataxiaBasher_attack()   [basher/001:70]
              ├─ dangerLevel()        → "flee" → executeFlee()  (never in no-flee areas)
              ├─ dangerLevel()        → "shield" → touch shield
              ├─ dangerLevel()        → "wait" → return
              └─ dangerLevel()        → "attack" → assembleAttack()
                 ├─ Emergency checks  (wand, maran barrier)
                 ├─ assembleBattlerage()  → per-class rotation (e.g. blademasterBattlerage); see battlerage-pve.md
                 ├─ Gold pickup
                 ├─ Legend deck draws
                 ├─ Blood maiden cloak
                 └─ Class-specific bashing function
```

## Gate Sequence (tryAttack)

All attack requests flow through `tryAttack()`. This is the ONLY function that calls `ataxiaBasher_attack()`.

```
1. ataxiaBasher_atk        → cooldown active (0.3s anti-spam)
2. ataxiaTemp.bashFlee     → currently fleeing
3. ataxiaBasher.paused     → manually paused
4. ataxiaTemp.fleeReturning → navigating back to combat room
5. canBals() + canStand()  → GMCP balance/standing check
6. ataxiaBasher_skipRoom   → room flagged to skip (dangerous mob, player, etc.)
7. found_target            → target exists in room (if not, advance room)
8. throttleCheck()         → max 5 attacks/sec safety valve
```

## Room Arrival Flow

```
1. gmcp.Room event fires
2. ataxia_Room_Update() runs:
   a. Remove current room from ataxiaBasher_path (areabash)
   b. If fleeReturning + arrived at fleeOriginRoom → clear return state
   c. Else if bashFlee → re-insert previous room into path
3. gmcp.Char.Items.List event → populate ataxia.denizensHere (`003_ataxia_RoomContents_Update.lua`)
   - The item `attrib` field is a flag-SET string, tested by **membership** (not whole-string
     equality): a room item enters `denizensHere` only if attrib lacks `x` (should-not-be-targeted —
     loyal to city/player) and `d` (dead monster/corpse), isn't a plain takeable (`t`), and isn't a
     guard icon. Applies to both the `List` loop and the `Add` path (which also nil-guards attrib).
   - Auto-learn (if enabled): add new denizens to targetList[area], skipping own denizens
     (`ataxiaBasher_isOwnDenizen`) — pets/allies like falcons/Baalzadeen. Because the `x` filter runs
     first, loyal/protected NPCs never reach the persistent targetList.
4. Next prompt:
   a. scanRoom() → clears need_roomCheck, checks for danger/players
   b. search_targets() → finds target in denizensHere (own denizens excluded)
   c. patterns() → tryAttack() → attack()
```

## Reload Safety (Load-Time Inits)

Several combat globals were created **only** inside `levilogin()` (login/001). A package reinstall/reload (e.g. `SYSUPDATE`) does **not** re-fire the "logged in" event, so on a reload they stayed `nil` while always-live code — prompt triggers, `gmcp.Char.Vitals` handlers, the attack loop — indexed or incremented them, crashing on the first prompt/attack. Each is now seeded **idempotently** (`X = X or …`) at script **load**, before any trigger fires, so a genuine `nil` is filled while a live mid-session value is preserved (cooldowns/counts not wiped):

| Global | Seeded in | Crashing sink |
|--------|-----------|---------------|
| `battleRage_Timers` | top of `basher/001` | every battlerage rotation reads `.small`/`.large`/`.special` |
| `tBals` (full shape: `tree`/`focus`/`plant`/`salve`/`timers`/`passive`) | top of `basher/001` | prompt `@tarbals` tag (012), focus-knock, Anti_Priorities, Magi bloodboil gate — `tBals.timers` is indexed |
| `shape` | top of `basher/001` | Earth Lord `121_SHAPE_PLUS` does `shape = shape + 1` unguarded |
| `bashStats` (full shape incl. DPS/damage fields) | bottom of `basher/003` | combat/DPS triggers increment `totalDamage`/`slain`/… on the first hit |

## Supported Classes (22+)

All class bashing attack functions in `basher/002_Class_Bashing.lua` (a few classes add custom helpers elsewhere — e.g. Bard's `ataxiaBasher_bardBattlerage` and Blademaster's `ataxiaBasher_blademasterBattlerage` both live in `basher/001`, and Bard's `ataxiaBasher_bardCompose` performance helper in `002`; Magi's `ataxiaBasher_magiShouldBloodboil` (`basher/001`) is a self-cure gate — **not** a battlerage — that `magiBashing` fires from its **EQUILIBRIUM slot** (the staff-bash slot) at 3+ real affs while our own tree tattoo is on balance, or as a low-HP heal under the Hot Springs Mnemosyne boon):

Alchemist, Apostate, Bard, Blademaster, Depthswalker, Druid, Infernal, Jester, Magi, Monk, Occultist, Paladin, Pariah, Priest, Psion, Runewarden, Sentinel, Serpent, Shaman, Sylvan, Unnamable, Air/Fire/Water/Earth Elemental, Blue/Black/Green/Gold/Red/Silver Dragon

## Event Integration

**Events Raised:**
- `"basher enabled"` — after entering manual/areabash mode
- `"basher disabled"` — after any disable path
- `"changed target"` — after target selection
- `"targets updated"` — debounced denizen list change

**Events Listened:**
- `"mmapper failed path"` → `ataxiaBasher_pathFail()`
- `"mmapper arrived"` → `ataxiaBasher_arrived()`
- `"player death"` → `ataxiaBasher_onDeath()`
- `"attacker class detected"` → `ataxiaBasher_onAttacked()`
- `"basher enabled"` → `basher_engaged()` (GUI, armour swap, legend deck)
- `"basher disabled"` → `basher_disengaged()` (GUI, armour swap)

## Live Bashing HUD (`tarc`)

`windows/001_Limb_Counter_Window.lua` (`tarc.write`) doubles as the basher HUD. For a **denizen** target (numeric id) it shows the mob NAME (`ataxia.denizensHere[target]`), colored Mob-health + HP/WP/EP BARS, a Rage + XP line, DPS Now/Avg/Total, and a SESSION block (Kills/Crits/Gold/Time + kills-per-hour, from `bashStats`). The PvP lock/aff readout is suppressed for numeric targets. The whole panel is gated on **`ataxiaBasher.enabled`** (not `gmcp.IRE.Target.Info`, which hid it inside Mnemosyne).

**Taken table (v4.7.211/216):** below DPS, every damage TYPE dealt to us this session, ranked,
with amount and share -- `bashStats_incomingRanked()` over `bashStats.incomingByType`, fed by
trigger 351 parsing `Health lost: N (physical cutting)`. Rows are coloured **by damage type**
(`TAKEN_COLOUR`, 18 ordered substring rules) so the table can be scanned by colour rather than
read: you are usually looking for whether the blue one is growing, not reading numbers. The
percentage stays grey so it never competes. **All types, not a top-N** (v4.7.216) -- the
leaders are unremarkable (a Bard bashing physical denizens takes physical cutting) and the tail
is where the surprises live: a 1% type that has no business being there means something is
hitting us we did not know was in the room, which `+N more` hid. `ataxiaBasher.takenTop`
survives as an opt-in cap (0 = all, the default) and still renders its `+N more` tail when set.

**Top-alignment (v4.7.214):** a Mudlet MiniConsole SCROLLS, so a buffer shorter than the window
renders BOTTOM-anchored and the panel floats down with dead space above it. There is no padding
to remove -- the behaviour is inherent. `tarc:cecho` counts the newlines it writes into
`tarc._lines`, and `tarc:padToTop()` appends blanks BELOW the content at the end of each
render. Derived from `getRowCount`, never a fixed count (a fixed number is wrong the moment the
window is drag-resized), and `pcall`-guarded, since that API returns nil for a console not yet
laid out and a HUD that errors is worse than one that sits low.

> **This file is NOT unit-tested** -- it needs Geyser, so the suite cannot load it.
> Syntax-check it by hand after every edit. An edit that wrote a literal newline into a Lua
> string literal nearly shipped and would have killed the entire HUD.

**Bar sources:** HP/WP/EP read straight from `gmcp.Char.Vitals` (`hp/maxhp`, `wp/maxwp`, `ep/maxep`; XP from `.nl`) — the live values, not the derived `ataxia.vitals` copy (v4.7.96). The **Mob** bar reads the denizen-state HP `ataxiaBasher_dsGet(target).hpp`, which `010_Prompt_Running` feeds every prompt from `gmcp.IRE.Target.Info.hpperc`, falling back to the live GMCP field for a just-acquired target (v4.7.97) — this is what makes it render reliably in Mnemosyne, where the raw field is briefly nil right after a retarget. **Refresh:** `tarc.write` fires on `"targets updated"` and on `"gmcp.IRE.Target.Info"` (pushed each combat round), so the Mob/vitals bars track the fight live; handlers are registered once behind a `tarc._refreshHandlers` flag to avoid stacking on reload.
