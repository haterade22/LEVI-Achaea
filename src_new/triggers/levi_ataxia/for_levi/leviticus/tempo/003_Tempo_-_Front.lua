--[[mudlet
type: trigger
name: Tempo - Front
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Bard
- Bard Rework
- Tempo
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
- pattern: ^Your deadly dance carries you back around to face .+?\.$
  type: 1
]]--

-- MULTI-WORD NAMES (v4.7.313, from a live log). This pattern took `\w+` for the partner's name --
-- fine for a player ("Grulk"), never for a denizen ("a royal guard of Zanzibaar"), so in PvE
-- `bardtempo` was NEVER updated by this line. Everything that reads the position was blind:
-- Shadow Tempo's back-bonus rule (v4.7.241) never saw "back", and the footwork flourish
-- (v4.7.311) saw a "front" that never changed and flourished on every single balance --
-- back -> side -> front -> back, no attack ever landing. `.+?` now, anchored by the fixed text
-- around it.
bardtempo = "front"
bardtemposequence = 0