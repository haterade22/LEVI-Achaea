# Shaman Offense System

## Main File
- `src_new/scripts/levi_ataxia/levi/levi_scripts/shaman/028_Shaman_Offense.lua` — Unified V3-aware offense

## Old Files (DEACTIVATED)
- `shaman/001_*.lua` through `shaman/027_*.lua` — all set `isActive: 'no'`

## Namespace & State
- `shamanOffense` (global), `shamanOffense.state` for mode/strategy
- `shamanOffense.hasAff()` — namespaced V3→V2→V1 routing
- State: `mode`, `strategy`, `dollTarget`, `relapseTarget`, `swiftFired`, `spiritWarningShown`

## Modes
- group (shgroup), lock (shlock), bleed (shbleed), damage (shdmg), tzantza (shtz)
- shstatus, shreset, shspirits — utility aliases

## Delivery Rotation (Lock/Bleed)
1. Curse+relapse (2.2s, tree down + off CD) → charges jinx, swiftFired=false
2. Jinx (2.3s, 2 affs same cure) → consumes charge
3. Swiftcurse (0.8s, 1 aff filler) → swiftFired=true (1 per cycle)
4. Curse+invoke (2.2s, bloodlet/coag/soulrend) → charges jinx, swiftFired=false

## Jinx Pairing Rules
- Pass 1: same cure path (kelp+kelp preferred)
- Pass 2 fallback: same cure CHANNEL (avoid herb+focus pairs via FOCUS_CURABLE table)
- FOCUS_CURABLE: {stupidity, confusion, anorexia, dementia, masochism, recklessness}
- relapseTarget skipped in jinx selection (aff coming back via relapse)

## Priority Tables (Lock)
paralysis > impatience > asthma > clumsiness > anorexia(gated) > weariness > stupidity > manaleech > confusion > ...
- No slickness (coagulation only), no haemophilia (bloodlet only)
- Anorexia gated behind impatience + asthma + slickness
- Manaleech/confusion enable soulrend (replaced nausea/addiction)

## Spirit→Invoke Mapping
- Teraile = bloodlet (haemophilia + bleed)
- Aspar = coagulation (bleed ≥200 + haemophilia gate → aff, prefers slickness w/ asthma)
- Syvis = relapse (cured affs relapse, tree-gated)
- Marak = soulscourge (mana pressure)
- Maligus = soulrend (needs manaleech/confusion/shyness/paranoia/dementia)

## Invoke Priority
1. Soulrend (maligus + mental aff present)
2. Coagulation (aspar + haemophilia + BL ≥ 200)
3. Bloodlet (teraile + off CD)

## Combat Spirit Profile
`sp create combat binds marak teraile aspar syvis maligus attunes marak teraile maligus tether anthius`

## Key Functions
- `dispatch()` → `computeStrategy()` → `buildAttack()` → `sendAttack()`
- `selectGroupCurses()`, `selectLockCurses()`, `selectBleedCurses()` — per-mode aff selection
- `selectInvoke()`, `selectBleedInvoke()` — invoke selection with spirit+haemophilia gates
- `selectRelapseCurse()`, `selectRelapseBleedCurse()` — relapse target selection
- `selectCoagulationAff()` — smart coag aff (slickness w/ asthma, else first missing)
- `canSoulrend()` — maligus + SOULREND_GATE_AFFS check

## Doll Handling
- First `zz` on new target → `fashion doll of target` (early return, no offense)
- Subsequent → normal offense (no wield needed)
- Group mode: no doll

## Triggers (read-only, already V3-integrated)
- `triggers/.../shaman/001_Curses.lua` through `012_Swiftcurse_Charges.lua`
