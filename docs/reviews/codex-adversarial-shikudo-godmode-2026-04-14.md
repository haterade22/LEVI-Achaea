# Adversarial Code Review: Shikudo God Mode
**File:** `009_CC_Shikudo_GodMode.lua` (958 lines)  
**Review Date:** 2026-04-14  
**Reviewer:** Claude Sonnet 4.6 (adversarial)  
**Supporting files reviewed:** `008_CC_Shikudo_Offense_ALL.lua`, `006_CC_Shikudo_Dispatch.lua`, `monk.md`

---

## Summary Verdict

The system is structurally sound and stateless-by-design in the right places. Two confirmed bugs and one confirmed design gap were found. Three of the six known suspects are real problems; the other three are either working correctly or defensible design choices.

---

## Known Suspect Verdicts

---

### Suspect 1 — Missing nil guard on `ataxiaTables.limbData`

**Verdict: CONFIRMED BUG**  
**Severity: CRITICAL**  
**File:** `009_CC_Shikudo_GodMode.lua`, line 71–93  

**What's wrong:**

`calcLimbs()` opens with:

```lua
local ld = ataxiaTables.limbData
```

There is no nil guard on `ataxiaTables` itself, nor on `ataxiaTables.limbData`. If either is nil — which can happen before `shikudo_breakPoint(5000)` has been called, or if the limb-data script hasn't loaded yet — this line performs a table index on nil and Lua 5.1 throws a hard error, crashing the entire tick.

`run()` calls `shikudo_breakPoint(5000)` at line 702 as a lazy-init guard, but `calcLimbs()` at line 713 is called unconditionally immediately after. The lazy-init only protects `shikudo_limbDamage`; it does not guarantee `ataxiaTables.limbData` is populated, because `ataxiaTables` is a separate global populated by a different script.

The same nil-dereference exists in `willowPrios()` (line 162), `rainPrios()` (line 190), `oakPrios()` (line 332), and `gaitalPrios()` (line 408) — each locally binds `ld = ataxiaTables.limbData` without a guard.

By contrast, `status()` at line 904 correctly guards before calling `calcLimbs()`:

```lua
if ataxiaTables and ataxiaTables.limbData then
    shikudo.godmode.calcLimbs()
end
```

The same guard must be applied in `run()`.

**What to do:**

Add an early-return guard at the top of `run()`, just before `calcLimbs()` is called:

```lua
if not ataxiaTables or not ataxiaTables.limbData then
    cecho("\n<red>[Shikudo GM] limbData not loaded yet")
    return
end
```

This matches the existing guard pattern in `status()`.

---

### Suspect 2 — Hyperfocus drop on sweep uses wrong variable

**Verdict: CONFIRMED BUG**  
**Severity: HIGH**  
**File:** `009_CC_Shikudo_GodMode.lua`, lines 740, 839–843  

**What's wrong:**

The system has two separate variables tracking hyperfocus state:

- `ataxiaTemp.hyperLimb` — populated by a game trigger when the server echoes a hyperfocus confirmation. This is the source of truth for what the *server* thinks.
- `shikudo.state.hyperfocus` — populated by `shikudo.setHyperfocus()` in `008_CC_Shikudo_Offense_ALL.lua` line 338/347 and in `006_CC_Shikudo_Dispatch.lua` line 285/295.

`run()` checks `ataxiaTemp.hyperLimb` at line 740 to decide whether hyperfocus is already active:

```lua
local hyperOk = ataxiaTemp.hyperLimb == "head"
```

The sweep handler at line 839 also reads `ataxiaTemp.hyperLimb` when deciding whether to drop hyperfocus:

```lua
local hyperLimb = ataxiaTemp.hyperLimb
if hyperLimb and hyperLimb ~= "none" and hyperLimb ~= "" then
    atk = atk .. "hyperfocus none" .. sp
    ataxiaTemp.hyperNeedsRaise = true
end
```

This is consistent and correct — both reads come from the same variable. However, `ataxiaTemp.hyperNeedsRaise` is set to `true` here but **never consumed**. There is no code anywhere in the codebase that reads `ataxiaTemp.hyperNeedsRaise` and re-issues `hyperfocus head`. The flag is written once and ignored forever.

The intended flow is:
1. Combo 1 (sweep): drop hyperfocus so needle can break head in combo 3.
2. After combo 3 (needle): raise hyperfocus back to head.

Step 2 is never implemented. After the execute sequence the system will attempt to rebuild in Gaital or transition to Rain for a lock fork, and the next call to `run()` will immediately re-raise hyperfocus via the `hyperOk` check at line 740 — so the behaviour is accidentally correct for the happy path. But if the player presses the attack key manually during the mid-execute phase (between combos 1 and 3), `run()` will see `hyperOk == false` (hyperfocus was dropped) and spend the entire balance budget on `hyperfocus head` instead of firing combo 2 or 3. This stalls the execute completely.

**What to do:**

Either remove `ataxiaTemp.hyperNeedsRaise` (the flag is never consumed; it's dead code) or implement it. If the intent is to suppress the hyperfocus re-raise between execute combos, add a check in `run()`:

```lua
local hyperOk = ataxiaTemp.hyperLimb == "head"
-- Suppress re-raise during mid-execute phase
local midExecute = haveAff("prone") and (gm.bothLegsBroken or gm.bothArmsBroken)
if not hyperOk and not midExecute and f ~= "Gaital" then
    send("queue addclear eqbal " .. atk .. "hyperfocus head")
    return
end
```

The existing condition `f ~= "Gaital"` already prevents re-raise during the entire Gaital form stay, which is a reasonable proxy. The dead `hyperNeedsRaise` flag should be removed to avoid confusion.

---

### Suspect 3 — Execute combo 1 kata check too strict (`k == 0`)

**Verdict: CONFIRMED BUG**  
**Severity: HIGH**  
**File:** `009_CC_Shikudo_GodMode.lua`, line 484  

**What's wrong:**

```lua
if gm.executeReady and not haveAff("prone") and k == 0 then
```

The system transitions to Gaital from Oak only when `k >= 5` (line 630 or 634), which resets kata to 0. So immediately after a clean Gaital transition, kata will indeed be 0, and combo 1 fires correctly.

However, the `formswap()` function at line 644 also has a safety valve for Gaital:

```lua
if k >= 10 and not gm.executeReady and not killReady
and not gm.lockForkReady and not midExecute then
    targetForm = "Rain"
```

This means Gaital will transition back to Rain if kata reaches 10 without being execute-ready. After returning from Rain and re-entering Gaital the kata will again be 0, so this path is safe.

The real problem is **in-fight kata drift**. Consider this sequence:

1. System is in Gaital building (not yet execute-ready).
2. One or two combos fire, incrementing kata to 1 or 2.
3. The last piece of prep finishes — `gm.executeReady` becomes true.
4. `k == 0` is now false (kata is 1 or 2).
5. Combo 1 never fires. The system falls through to the "STILL BUILDING" branch, fires more build combos, advances kata further, eventually hits the `k >= 10` guard and transitions back to Rain — wasting the entire prep window.

This is a real scenario any time prep completes mid-Gaital-stay rather than on the exact Gaital entry tick. Given that Gaital's STILL BUILDING path (lines 499–556) is active and generates 1–2 combos per tick, this will happen regularly.

**What to do:**

Change the condition to `k <= 2` (or simply remove the kata check):

```lua
if gm.executeReady and not haveAff("prone") and k <= 2 then
```

There is no game mechanic reason combo 1 (sweep + flashheel) requires kata to be exactly 0. Kata 1 or 2 is safe. The upper bound of `k <= 4` would also be acceptable to allow the form-transition window to settle, but the current `k == 0` is too tight.

---

### Suspect 4 — Lock fork aff list missing key affs

**Verdict: WORKING AS DESIGNED — but with caveats**  
**Severity: MEDIUM (design question)**  
**File:** `009_CC_Shikudo_GodMode.lua`, lines 109–117  

**What's in the list:**

```lua
local lockAffs = {
    "slickness", "asthma", "addiction", "weariness",
    "paralysis", "anorexia", "impatience", "confusion"
}
```

**Analysis:**

The system counts how many of these 8 affs are present and uses `lockCount >= 3` as the threshold for triggering the lock fork. This is a general "enough lock pressure" check, not a strict riftlock prerequisite check. For riftlock specifically (slickness + asthma + addiction + weariness + 2 broken arms), all four riftlock affs are represented in the list.

The list is reasonable as a general soft-lock indicator: 3 of these 8 affs being present does indicate the target is under significant aff pressure. The concern from the review brief — that riftlock-specific affs might be missing — is unfounded; all four are present.

**Actual caveat:** The lock fork triggers on `gm.bothArmsBroken and lockCount >= 3`. A target with anorexia + paralysis + confusion (all 3 curable with a single eat or plant) would trigger the lock fork prematurely. This is not a bug but a tuning question: should the 3-aff threshold only count *hard-to-cure* affs (weariness, slickness, addiction) rather than instantaneously curable ones (paralysis, confusion)?

**Recommendation:** Not a blocking bug. Document the intent. Consider separating "sticky" affs from the count if false positives prove to be a problem in practice.

---

### Suspect 5 — `tAffs.damagedleftarm` vs `haveAff("brokenleftarm")`

**Verdict: WORKING AS DESIGNED**  
**Severity: LOW**  
**File:** `009_CC_Shikudo_GodMode.lua`, lines 98–101  

**What the code does:**

```lua
gm.bothLegsBroken = (haveAff("brokenleftleg") or tAffs.damagedleftleg)
               and (haveAff("brokenrightleg") or tAffs.damagedrightleg)
gm.bothArmsBroken = (haveAff("brokenleftarm") or tAffs.damagedleftarm)
               and (haveAff("brokenrightarm") or tAffs.damagedrightarm)
```

**Analysis:**

Looking at `016_Targeting_Functions.lua`, the `tAffs` table defines:
- `brokenleftleg`, `brokenrightleg`, `brokenleftarm`, `brokenrightarm` — set via `haveAff()` / V3 tracker (level 1: broken)
- `damagedleftleg`, `damagedrightleg`, `damagedleftarm` — direct boolean fields (level 2+: mangled/damaged)

The code correctly ORs both levels: a limb that is broken-level-1 OR damaged-level-2 is treated as "broken enough to proceed." This is exactly correct for the execute sequence — once a limb is at any broken level, you should proceed with the kill sequence rather than waste more hits on it.

The `haveAff("brokenleftleg")` / `tAffs.damagedleftleg` duality is intentional and correct. No bug here.

---

### Suspect 6 — Combo 2 hardcodes `ruku left + ruku right + flashheel right`

**Verdict: DESIGN QUESTION — partially mitigated, residual risk**  
**Severity: MEDIUM**  
**File:** `009_CC_Shikudo_GodMode.lua`, lines 473–480  

**What the code does:**

```lua
local leftLegBroken = tAffs.damagedleftleg or haveAff("brokenleftleg")
if haveAff("prone") and leftLegBroken and not gm.bothArmsBroken then
    gm.staff = {}
    table.insert(gm.staff, "ruku left")
    table.insert(gm.staff, "ruku right")
    gm.kick = "flashheel right"
    return
end
```

**Analysis:**

Combo 2 fires when: target is prone AND left leg is broken AND both arms are not yet broken. This is correct — it doesn't blindly assume combo 1 always broke the left leg; it *checks* whether the left leg is actually broken before proceeding.

The residual risk: if combo 1 (sweep + flashheel left) fails to break the left leg because the target restored it between the command being sent and the tick landing, the left leg will not be broken. In that case combo 2 is skipped, and the system falls through to the STILL BUILDING path, which will attempt to prep the left leg again. This is the correct fallback.

The right arm is not checked before issuing `ruku right` — if the right arm was already broken going into combo 2 (e.g., target had a pre-existing broken arm), `ruku right` wastes a staff slot. This is a minor inefficiency, not a safety issue.

**Recommendation:** Not a blocking bug. The condition check on `leftLegBroken` is the critical safety valve and it is present. The pre-existing broken arm case is edge-case enough to accept.

---

## Additional Findings

---

### Finding A — Dead code: `gm.staff[1] == "hyperfocus head"` branch is unreachable

**Severity: LOW**  
**File:** `009_CC_Shikudo_GodMode.lua`, lines 799–802  

```lua
if gm.staff[1] == "hyperfocus head" then
    send("queue addclear eqbal " .. atk .. "hyperfocus head")
    return
end
```

No form prios function ever sets `gm.staff[1] = "hyperfocus head"`. The string is only used as a comment-sentinel in the original dispatch-mode code (006). In godmode, hyperfocus is managed exclusively via the `hyperOk` check at line 740. This branch is dead code and should be removed to avoid future confusion.

---

### Finding B — Oak combo order violates Rain kick-first rule for non-clumsiness case

**Severity: MEDIUM**  
**File:** `009_CC_Shikudo_GodMode.lua`, lines 856–857  

```lua
local kickFirst = (f == "Rain") or (f == "Oak" and haveAff("clumsiness"))
```

The review brief states: "Oak kicks go last (staff first for paralysis before parry check)." The code correctly puts Oak kick last by default (kickFirst is false for Oak without clumsiness). The clumsiness exception — kick first in Oak when target has clumsiness — means the paralysis-applying nervestrike can go before the kick when the kick-first rule would otherwise apply.

However, the clumsiness exception inverts the normal Oak order. With clumsiness active, the kick fires before nervestrike. This means: if the target parries the kick, the nervestrike still fires (which is correct). But with clumsiness the target is less accurate, not less likely to parry — parry is not a dodge check. The clumsiness exception for kick-first ordering doesn't appear to have a mechanical justification. This may be a copy-paste from another mode.

**Recommendation:** Verify whether clumsiness actually changes the optimal combo ordering for Oak. If not, remove the clumsiness exception and let Oak always be staff-first.

---

### Finding C — `shikudo.reset()` does not reset `gm` or `ataxiaTemp.hyperLimb`

**Severity: MEDIUM**  
**File:** `008_CC_Shikudo_Offense_ALL.lua`, lines 1020–1027  

```lua
function shikudo.reset()
    shikudo.state.blackoutActive = false
    shikudo.state.lastBlackout = 0
    shikudo.state.phase = "PREP"
    shikudo.state.lockPhase = "SOFTLOCK"
    shikudo.state.riftPhase = "OAK_SETUP"
end
```

`gm` is a module-level `local` table in `009`. It is re-populated on every `calcLimbs()` call, so it is effectively stateless between ticks. No issue there.

`ataxiaTemp.hyperNeedsRaise` (written in the sweep handler) is never consumed and never cleared. If a fight ends mid-execute (target dies after combo 1 sweep), `hyperNeedsRaise = true` persists into the next fight and may confuse any future consumer of that flag.

`ataxiaTemp.hyperLimb` is populated by a server-trigger (not by the client), so it self-corrects on next hyperfocus trigger. No issue there.

`shikudo.state.hyperfocus` — set by `shikudo.setHyperfocus()` in `008` — is not reset by `shikudo.reset()`. This means if a fight ends with hyperfocus dropped (post-combo-1), and the player calls `skreset()`, the next fight starts with `shikudo.state.hyperfocus == nil` while `ataxiaTemp.hyperLimb` may still say `"head"` (from server echo). The two variables diverge. Since godmode reads `ataxiaTemp.hyperLimb` (not `shikudo.state.hyperfocus`) this divergence doesn't cause a bug in godmode specifically, but it corrupts the state for other modes that read `shikudo.state.hyperfocus`.

**What to do:** Add to `shikudo.reset()`:

```lua
ataxiaTemp.hyperNeedsRaise = nil
```

---

### Finding D — Dispatch check in `run()` fires before prios (double-check issue)

**Severity: LOW**  
**File:** `009_CC_Shikudo_GodMode.lua`, lines 748–759  

There is a dispatch check at line 748 in `run()` before any prios are computed, and also inside `gaitalPrios()` at line 418. The early check in `run()` is correct and fast-paths to dispatch without requiring a form prios call. The duplicate check inside `gaitalPrios()` (which sets `gm.staff[1] = "dispatch"`) is then handled at line 824. This means dispatch is checked twice per tick when in Gaital with kill conditions met. The second check in `gaitalPrios()` is unreachable from `run()` because `run()` already returned at line 758.

The `gm.staff[1] == "dispatch"` handler at line 824 is therefore dead code in the current flow. It exists as a fallback but the early-return at line 758 always wins first. Not a bug, but dead code that adds confusion.

---

### Finding E — `healthleech` in `haveAff()` is a V3 affliction name concern

**Severity: LOW**  
**File:** `009_CC_Shikudo_GodMode.lua`, line 291  

```lua
if k >= 10 and not haveAff("healthleech") then
```

Cross-referencing `016_Targeting_Functions.lua` and `008_Affliction_Colouring.lua`: `healthleech` is a valid internal name in this codebase (confirmed at `tAffs` default table line 369 and colouring table line 57). The `haveAff()` function delegates to `haveAffV3()` which uses internal names. This call is correct.

---

### Finding F — Lock fork in `rainPrios()` has a slot1/slot2 logic gap

**Severity: MEDIUM**  
**File:** `009_CC_Shikudo_GodMode.lua`, lines 193–213  

The lock fork slot picker in `rainPrios()`:

```lua
if not haveAff("weariness") then
    slot1 = "kuro left"
elseif not haveAff("lethargy") then
    slot1 = "kuro right"
elseif not haveAff("clumsiness") then
    slot1 = "ruku torso"
end
if not haveAff("slickness") and not slot1 then
    slot1 = "ruku torso"
elseif not haveAff("slickness") then
    slot2 = "ruku torso"
end
if not slot1 then slot1 = "kuro left" end
if not slot2 then slot2 = "kuro right" end
```

When `weariness` is absent, `slot1 = "kuro left"` and the slickness block sets `slot2 = "ruku torso"` if slickness is absent. So far correct.

When `weariness`, `lethargy`, AND `clumsiness` are all present, `slot1` remains nil after the first block. Then the slickness check can set `slot1 = "ruku torso"` (if slickness also absent), or `slot1` stays nil, falling through to `slot1 = "kuro left"`.

If ALL four affs are present (weariness, lethargy, clumsiness, slickness), the code reaches `slot1 = "kuro left"` at the fallback and `slot2 = "kuro right"`. This correctly hammers legs to maintain weariness/lethargy, which is appropriate when all lock affs are already applied.

The gap: when clumsiness is present but slickness is not, `slot1 = nil` after the first block, then `slot1 = "ruku torso"` via the slickness check, and `slot2 = "kuro right"` via fallback. The result is `ruku torso + kuro right`, which is correct.

When weariness and lethargy are present but clumsiness is NOT (and slickness is also not), `slot1 = "ruku torso"` (correct for clumsiness) and `slot2 = "kuro right"` (fallback leg hit). This is acceptable.

No outright bug, but the multi-condition fallback chain is difficult to reason about. A truth table or explicit multi-condition if-else would be safer to maintain.

---

### Finding G — Combo 3 needle combo includes `jinzuku` as a filler but jinzuku's affliction is unknown

**Severity: LOW**  
**File:** `009_CC_Shikudo_GodMode.lua`, lines 440–443, 460–462  

```lua
elseif not haveAff("addiction") then
    table.insert(gm.staff, "jinzuku")
```

`jinzuku` is listed in `monk.md` as a valid Gaital staff attack but its affliction is not documented in `monk.md`. The code uses it as a filler to apply addiction. Since `addiction` is a real aff in `tAffs` (confirmed in `016_Targeting_Functions.lua` line 290), this is plausibly correct if jinzuku does apply addiction. If jinzuku applies a *different* affliction, the addiction check is wrong filler logic. The `ataxiaTables.limbData` would need a `shikJinzuku` entry confirmed in the damage table.

Cross-referencing `005_Shikudo_Needle_Logic.lua` line 35: `shikJinzuku = ataxiaTables.limbData.shikJinzuku` — the damage value exists. The affliction association (jinzuku → addiction) should be verified against game documentation.

---

### Finding H — Race condition: `gm` is module-level, not reentrant

**Severity: LOW (Mudlet single-threaded)**  

The `gm` table is declared `local gm = {}` at module scope (line 66) and is reset by `gm.staff = {}` and `gm.kick = "none"` at the top of each prios function. Mudlet's Lua environment is single-threaded (no coroutines firing simultaneously from timers in this context), so there is no true race condition. However, if a timer trigger calls `calcLimbs()` independently (e.g., from a status update trigger), it would overwrite `gm` mid-tick. Currently no such timer exists, but this is a fragile pattern. Consider moving `gm` to a function-local in `run()` and passing it as a parameter to `calcLimbs()` and the prios functions for true encapsulation.

---

## State Leak Analysis

**Between fights:** `ataxiaTemp.hyperNeedsRaise` is the only identified state leak (Finding C). The `gm` table is overwritten each tick. `shikudo.state` fields are reset by `shikudo.reset()` except `hyperfocus`.

**Mid-execute interrupt:** If the target leaves the room or dies after combo 1 (prone established) but before combo 3, the next fight starts with `gm.executeReady` computed fresh (it will be false, limbs not prepped on new target), so no state carries over. The `ataxiaTemp.hyperLimb` from the dropped hyperfocus will cause `run()` to re-raise it on the first tick of the next fight, which is correct.

---

## Edge Case Analysis

**Target shields mid-execute:** The shield check at line 762 fires before form prios, so `shatter` will be sent even mid-execute (e.g., after combo 1). This pauses the combo sequence for one tick but the sequence will resume correctly on the next tick because gaitalPrios() reads live state.

**Target dies mid-execute:** Mudlet will stop calling `run()` on death. No issue.

**Target leaves room:** Same as death — `run()` stops being called. On target return, the system restarts at the current form; if still in Gaital with a broken left leg and prone target, it will correctly enter combo 2. No issue.

**Infinite form swap loop:** `formswap()` for Gaital returns `Rain` only when `k >= 10 and not gm.executeReady and not killReady and not gm.lockForkReady and not midExecute`. This cannot loop because each call to `run()` either sends a combo (advancing kata toward 10) or issues a transition. The Gaital→Rain→Oak→Gaital cycle converges. No infinite loop.

---

## Confirmed Bugs Summary

| # | Severity | Line | Description |
|---|----------|------|-------------|
| S1 | CRITICAL | 71 | No nil guard on `ataxiaTables.limbData` in `calcLimbs()` — crashes if limbData not loaded |
| S3 | HIGH | 484 | `k == 0` in combo 1 gate too strict — execute misfires when kata is 1–4 after mid-Gaital prep completion |
| S2 | HIGH | 839–842 | `ataxiaTemp.hyperNeedsRaise` written but never consumed — dead flag that does not re-raise hyperfocus after execute |
| A | LOW | 799 | Dead code: `gm.staff[1] == "hyperfocus head"` branch never reached |
| D | LOW | 824 | Dead code: `gm.staff[1] == "dispatch"` handler never reached (early return at line 758) |
| C | MEDIUM | reset() | `ataxiaTemp.hyperNeedsRaise` not cleared on reset — state leak between fights |

## Design Questions

| # | Severity | Description |
|---|----------|-------------|
| S4 | MEDIUM | Lock fork aff list includes fast-curable affs (paralysis, confusion); may trigger prematurely |
| S6 | MEDIUM | Combo 2 assumes left leg will be broken by combo 1; mitigated by condition check but right arm pre-break not handled |
| B | MEDIUM | Oak clumsiness exception for kick-first ordering lacks mechanical justification |
| F | MEDIUM | Rain lock fork slot picker multi-fallback chain is hard to audit; no outright bug |
| G | LOW | jinzuku→addiction association not confirmed in docs |
