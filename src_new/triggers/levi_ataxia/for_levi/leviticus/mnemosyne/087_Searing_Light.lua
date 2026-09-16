--[[mudlet
type: trigger
name: Mnemosyne Searing Light
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
- pattern: ^Searing Light\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Searing Light is active: conjuring a
-- lightwall deals fire damage to every denizen in the room. The Serpent basher conjures one,
-- first in the round, at 2+ denizens -- once per room, on the first free planar exit
-- (`ataxiaBasher_searingLightwall`, basher/002). Cleared on Mnemosyne run start/end, like every
-- other boon flag. Type BOONS to re-sync if needed.
mnemSearingLight = true
