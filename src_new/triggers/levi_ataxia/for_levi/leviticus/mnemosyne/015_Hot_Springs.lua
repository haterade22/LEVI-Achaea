--[[mudlet
type: trigger
name: Mnemosyne Hot Springs
hierarchy:
- Levi_Ataxia
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
- pattern: ^Hot Springs\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Hot Springs is active: it makes casting BLOODBOIL also heal
-- 25% of max health + restore 5% willpower on a 30s cooldown (on top of its normal affliction
-- cure). While magiHotSprings is set the Magi basher will fire `cast bloodboil` as a bashing heal
-- when HP is low (like the Shaman's invoke-regeneration) -- see ataxiaBasher_magiShouldBloodboil
-- (basher/001). Cleared on Mnemosyne run start/end (mirrors magiKkractle / bmShatteredStar).
-- Type BOONS to re-sync if needed.
magiHotSprings = true
