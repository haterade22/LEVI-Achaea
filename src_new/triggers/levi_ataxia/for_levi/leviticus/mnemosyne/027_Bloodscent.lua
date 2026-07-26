--[[mudlet
type: trigger
name: Mnemosyne Bloodscent
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
- pattern: ^Bloodscent\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Bloodscent is active:
-- "You sense out your prey upon entering a ripple." -- every ripple entry prints
-- one "You sense <mob> (#id) at <room>." row per denizen, parsed into the swarm
-- module's recon by trigger 028. Cleared on Mnemosyne run start/end (mirrors the
-- other boon flags). Type BOONS to re-sync if needed.
mnemBloodscent = true
