--[[mudlet
type: trigger
name: Mnemosyne Winters Heart
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
- pattern: ^Winter's Heart\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Winter's Heart is active: "Your deepfreeze spell can
-- now be used against denizens and deals cold damage to all denizens in the location."
-- DEEPFREEZE is Elementalism but also comes from the Bracers of Frost artefact, so the
-- basher helper is class-agnostic: it is an EQUILIBRIUM cast, so on balance-attack classes
-- it rides free beside the swing, and for Magi it takes the eq slot horripilation would
-- have used. Fires at 2+ denizens (ataxiaBasher_winterDeepfreeze, basher/002 --
-- ataxiaBasher.deepfreezeAt to tune). Cleared on run start/end; type BOONS to re-sync.
mnemWintersHeart = true
