--[[mudlet
type: trigger
name: Mnemosyne Borrowed Power
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
- pattern: ^Borrowed Power\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "Your critical hits can now reach plane-razing level without requiring paragons
-- or the Psion class. This does not stack with those effects, however."
--
-- The last sentence is the actionable part: while this is up, the paragon that buys crit TIER
-- is dead weight sitting in an embrasure. User instruction (2026-08-03): put the willpower or
-- shifting-damage paragon there instead.
--
-- Plane-razing is a crit TIER, so the redundant paragon is `crucious` (crit multiplier).
-- `icosagon` is crit CHANCE -- how OFTEN we crit, which the boon does not grant -- so it is
-- left alone. `ataxia.armour.config.borrowedRedundant` holds that judgement if it turns out
-- to be wrong.
--
-- The swap itself runs through ataxia.armour.borrowedPower (gear_system/002), which builds a
-- `borrowed` profile from the bash one and hands it to the existing swap machinery. It is
-- reverted on the confirmed run end -- the boon is per-RUN, and leaving the swap in place
-- would quietly cost the crit paragon everywhere outside the tower.
--
-- Fires from the BOONS list; the claim alias does the same thing at the moment of claiming,
-- which is a boon screen -- out of combat, with the explorer paused. That is the right time
-- to be prying armour apart.
mnemBorrowedPower = true
if ataxia and ataxia.armour and ataxia.armour.borrowedPower then
  ataxia.armour.borrowedPower(true)
end
