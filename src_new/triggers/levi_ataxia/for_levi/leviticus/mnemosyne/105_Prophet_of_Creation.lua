--[[mudlet
type: trigger
name: Prophet of Creation
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
- pattern: ^Prophet of Creation\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Prophet of Creation is active (v4.7.358):
--
--   "Your foresight ability now works against denizens and causes the next attack against you to
--    miss."
--
-- PSI FORESIGHT <target> <TREE|SHIELD>. Only inside the tower (the gate every boon row carries since
-- v4.7.351). Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
if ataxiaBasher and ataxiaBasher.inMnemosyne then psionProphet = true end
