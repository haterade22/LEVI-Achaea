--[[mudlet
type: trigger
name: Mnemosyne Rage-Fuelled
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Rage-Fuelled\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "When slaying a denizen, your next battlerage attack will cost no resource."
--
-- A kill banks ONE free battlerage. That is a STATE, not a timer -- the charge sits until
-- a battlerage actually goes out -- so it is mirrored as `ataxiaTemp.brFreeCharge`, armed
-- by the kill trigger (340_Slain, already denizen-gated on a numeric target) and spent by
-- `ataxiaBasher_brSent()` at the moment a rotation commits to sending one.
--
-- The payoff is entirely in `ataxiaBasher_rageAfford`, the single gate all 40 rotation
-- call sites already run through: a banked charge short-circuits both the cost AND the
-- rage floor, so every class benefits from one change. Culling reap is handled separately
-- (`rage >= 36 or ataxiaBasher_brFree()`) because it deliberately bypasses rageAfford to
-- stay floor-exempt -- and a free AoE execute is the single best thing to spend a charge
-- on, so it must not be the one path that misses out.
--
-- Cleared on run start and on the confirmed run end, along with the charge itself.
mnemRageFuelled = true
