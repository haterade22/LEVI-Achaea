--[[mudlet
type: trigger
name: Mnemosyne Death Stare
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
- pattern: ^Death Stare\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Death Stare is active: CONSIDER costs
-- 3s of equilibrium and instantly kills a non-boss denizen, once per ripple. The basher prepends
-- `consider <target>` to the round at 2+ denizens, or on a lone target after
-- `ataxiaBasher.deathStareAfter` seconds into the ripple (`ataxiaBasher_deathStare`, basher/001).
-- Cleared on Mnemosyne run start/end, like every other boon flag. Type BOONS to re-sync if needed.
mnemDeathStare = true
