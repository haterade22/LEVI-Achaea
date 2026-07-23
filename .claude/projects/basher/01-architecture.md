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
3. gmcp.Char.Items.List event → populate ataxia.denizensHere
   - Auto-learn (if enabled): add new denizens to targetList[area], skipping own denizens
     (`ataxiaBasher_isOwnDenizen`) — pets/allies like falcons/Baalzadeen
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

**Bar sources:** HP/WP/EP read straight from `gmcp.Char.Vitals` (`hp/maxhp`, `wp/maxwp`, `ep/maxep`; XP from `.nl`) — the live values, not the derived `ataxia.vitals` copy (v4.7.96). The **Mob** bar reads the denizen-state HP `ataxiaBasher_dsGet(target).hpp`, which `010_Prompt_Running` feeds every prompt from `gmcp.IRE.Target.Info.hpperc`, falling back to the live GMCP field for a just-acquired target (v4.7.97) — this is what makes it render reliably in Mnemosyne, where the raw field is briefly nil right after a retarget. **Refresh:** `tarc.write` fires on `"targets updated"` and on `"gmcp.IRE.Target.Info"` (pushed each combat round), so the Mob/vitals bars track the fight live; handlers are registered once behind a `tarc._refreshHandlers` flag to avoid stacking on reload.
