# Achaea Limb Damage Mechanics Reference

Comprehensive reference for limb damage, restoration, and break mechanics in Achaea PvP combat.

---

## Damage Levels

| Level | Damage % | State | Cure Method |
|-------|----------|-------|-------------|
| 0 | 0% | Healthy | N/A |
| 1 | 1-99% | Damaged (minor) | Restoration salve (4s) |
| 2 | 100% | Broken/Crippled | Restoration salve (4s) + Mending salve (1.1s) |
| 3 | 200%+ | Mangled | Cannot use Restore ability; requires multiple applications |

---

## Per-Hit Damage Cap

**Rule:** Any single hit that would push a limb's damage **above 100%** will only bring it to **exactly 100%**. Excess damage from that hit is lost.

```
Example: Limb at 95% + 20% hit = 100% (not 115%)
         15% wasted
```

**Subsequent hits bypass this cap.** Once a limb is at 100%+, further hits add normally up to **200% maximum**.

```
Example: Limb at 100% + 20% hit = 120%
         Limb at 180% + 30% hit = 200% (hard cap)
```

### Implementation Pattern

All limb tracking systems should apply this after damage addition:

```lua
local oldDmg = tLimbs[code]
tLimbs[code] = tLimbs[code] + damage
-- Per-hit cap: single hit can't push past 100%, subsequent hits stack to 200%
if oldDmg < 100 and tLimbs[code] > 100 then tLimbs[code] = 100 end
tLimbs[code] = math.min(tLimbs[code], 200)
```

### Implications for Offense

- **Prep efficiently:** Hitting a limb at 95% with a 25% kick wastes 20%. Better to use a smaller attack or target a different limb.
- **Overkill has value:** Hitting an already-broken limb stacks toward 200%, increasing the number of restoration applications needed to heal.
- **Break thresholds vary by class:** Knight swords detect at 97%, maces at 98%, Psion/Magi at 98%, Tekura at 99.99%, Shikudo at 99.8%.

---

## Restoration Healing

### Timing

- Applying restoration salve to a body area takes **4 seconds** before the limb actually heals
- During this 4-second window, the limb remains broken
- The target's salve balance is consumed immediately; the heal resolves at the end of the timer

### Left-Limb Priority

**Rule:** When restoration is applied to a paired area (arms or legs), the game **always heals the LEFT limb first**.

```
Example: Both legs broken, target applies restoration to legs
         → 4 seconds later, LEFT leg heals
         → Right leg remains broken (needs a second application)
```

This applies dynamically during the 4-second window:

```
Example: Right leg broken, target applies restoration to legs
         → 2 seconds later, attacker breaks LEFT leg
         → 2 seconds later (4s total), LEFT leg heals (not right!)
         → Right leg remains broken
```

### Implications for Offense

| Strategy | Why |
|----------|-----|
| Break RIGHT limbs last | Restoration heals left first, so right stays broken longer |
| Target LEFT limb for re-breaks | If enemy restores, the left limb is the one that healed |
| Exploit the 4s window | Breaking the left limb during restoration wastes their application |
| Stack damage on broken limbs | Forces multiple restoration applications (200% = 2 applications) |

### Salve Balance

- Restoration: **4.0s** salve balance cooldown
- Mending: **1.1s** salve balance cooldown
- Mending heals broken state (Level 2 → Level 1), restoration heals the damage itself

### Recovery Progression (Per Limb)

| State | Cure | Balance Cost | Time |
|-------|------|-------------|------|
| 100% (Broken) | Mending | 1.1s | Immediate |
| Then: Damaged | Restoration | 4.0s | 4s timer |
| 200% (Mangled) | Mending → Restoration → Mending → Restoration | Multiple | 10+ seconds |

---

## Tracking Systems

### Enemy Limb Tracking

Two parallel systems track enemy (target) limb damage:

#### `tLimbs` — Simulated Tracking (Per-Class Counters)

Used by class-specific offense systems that calculate damage per hit.

```lua
tLimbs = { H=0, T=0, LA=0, RA=0, LL=0, RL=0 }
```

| System | File | Per-Hit Damage Source |
|--------|------|---------------------|
| Tekura | `monk/001_Tekura_Limb_Counter.lua` | `tekura_limbDamage[attack]` (health-based) |
| Shikudo | `monk/002_Shikudo_Limb_Counter.lua` | `shikudo_limbDamage[attack]` (health-based, hyperfocus halves) |
| Knight SnB | `limb_management/008_Knight_Limbcounting.lua` | `ataxiaTemp.swordHit` (health-formula) |
| Knight DWB | `limb_management/008_Knight_Limbcounting.lua` | `ataxiaTemp.maceHit` (health-tier) |
| Psion | `limb_management/006_Psion_Limb_Tracking.lua` | Fixed: legs 20%, others 25% |
| Magi | `limb_management/004_Magi-Specific.lua` | `tLimbs.staff` / `tLimbs.airstrike` (health-tier) |

#### `lb[target].hits` — Event-Based Tracking (Romaen's Limb Counter)

Used by advanced offense systems (TK6, DWC, DWB-Runie, Shikudo dispatch) that receive actual damage values from GMCP/combat events.

```lua
lb[target].hits = {
  head = 0, torso = 0,
  ["left arm"] = 0, ["right arm"] = 0,
  ["left leg"] = 0, ["right leg"] = 0,
}
```

**Key functions:**
- `lb.addHit(name, limb, amount)` — Add damage, per-hit capped
- `lb.resetLimb(name, limb)` — Reset to 0
- `lb.salve(name, area)` — 4.0s timer, heals left first, resets on break detection
- `lb.resetAll(name)` — Reset all limbs

#### `lb.salve()` Healing Logic

When the target applies restoration, `lb.salve()` fires a 4.0s timer:

```lua
-- Iterates left before right (respects game's left-first priority)
arms = {[1] = "left arm", [2] = "right arm"}
legs = {[1] = "left leg", [2] = "right leg"}
-- Resets the FIRST limb found >= 100%, then stops (break keyword)
```

### Self Limb Tracking (SLC)

Tracks damage to the player's own limbs for defensive reactions.

```lua
selfLimbDamage[limb] = { damage, lastHit, hitCount, threshold }
```

- Per-hit cap at 100%, subsequent hits stack to **200%**
- `ataxia_selfHitsToBreak(limb)` — Hits remaining before break
- `ataxia_selfRestorationsNeeded(limb)` — Estimated restoration applications needed (`math.ceil(damage/100)`)
- GUI shows `[2x REST]` indicator when damage > 100%

---

## Enemy Restoration Detection

### Trigger Pattern

```
^(\w+) takes some salve from a vial and rubs it on \w+ (arms|legs|head|torso|body)\.$
```

### Processing Flow (`target_appliedTo()`)

```
1. Check if previous apply was MENDING (2s detection window)
   → If yes: clear break affliction (left first), short salve bal (1.1s)
2. Check for damaged/mangled LEFT limb first
   → If yes: set 4.0s checkBreak timer, set 4.0s salve bal
3. Else check RIGHT limb
   → If yes: same timers
4. Else check for broken LEFT limb
   → Clear broken aff, short salve bal (1.1s)
5. Else clear broken RIGHT limb
```

**Key:** The conditional order (left before right) mirrors the game's left-first healing priority.

---

## Class-Specific Break Thresholds

| Class/System | Break Detection | Notes |
|-------------|----------------|-------|
| Tekura (tLimbs) | > 99.99% | Very strict |
| Shikudo (tLimbs) | > 99.8% | Slightly lenient |
| Knight Sword (tLimbs) | >= 97% | Early detection for SnB |
| Knight DWB (tLimbs) | >= 98% | Mace-based |
| Psion (tLimbs) | >= 98% | Fixed per-hit values |
| Magi (tLimbs) | >= 98% | Staff-based |
| TK6 (lb) | >= 100% | Exact threshold |
| DWC (lb) | >= 100% | Exact threshold |
| DWB-Runie (lb) | >= 100% | Exact threshold |
| Blademaster (tLimbs) | > 99.99% | Compass slash prediction |

---

## Offense System Integration

### Systems That Exploit Left-First Healing

| System | Strategy | File |
|--------|----------|------|
| Blademaster Ice | Always breaks RIGHT leg ("curing applies left first") | `blademaster/005_CC_BM_Ice.lua` |
| DWB-Runie | Breaks right leg first in execute sequences | `dwb_runie/001_DWB_Runie_Logic.lua` |
| Apostate | R→L→R→L rotation (right first by default) | `apostate/015_CC_Apostate.lua` |
| TK6 | Right-limb tiebreaker in `findSafeLimb()` | `tekura/002_Tekura_6Limb_Offense.lua` |
| DWC | 4s salve lock from undercut covers the window | `dwc/001_Infernal_DWC_Vivisect.lua` |

### TK6 Right-Limb Tiebreaker

When two limbs have equal damage, `findSafeLimb()` prefers right limbs:

```lua
local function limbSort(a, b)
  local da, db = (simDmg[a] or 0), (simDmg[b] or 0)
  if da == db then
    return a:find("right") and not b:find("right")
  end
  return da < db
end
```

**Effect:** Right limbs get hit more → left limbs get prepped first → when enemy restores, left heals first → right stays broken longer.

### DWC Salve Lock

The DWC execute sequence exploits the 4-second salve lock from undercut:

```
Step 0: UNDERCUT left leg → Breaks leg + 4s salve lock (can't mend)
Step 1: DSL right arm epteth epseth → Breaks right arm + L1 to other limbs
```

During the 4s salve lock, the target cannot apply restoration, making left-first priority irrelevant for this sequence.
