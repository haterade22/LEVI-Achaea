--[[mudlet
type: trigger
name: Mnemosyne Survey
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You are in .*Mnemosyne
  type: 1
]]--

-- Mnemosyne is an unmapped tower-climb instance (gmcp.Room.Info.area is ""), so we flag it
-- from its SURVEY line. This line is the AUTHORITY on where we are: SURVEY is free and still
-- reports the truth while DEMENTIA is hallucinating a real environment/area around us, so it
-- both sets the flag and cancels a pending "did we leave?" window opened by ataxia_Room_Update
-- when it saw a (possibly hallucinated) non-empty area. ataxiaBasher_isNoFleeArea() reads it.
if ataxiaBasher_mnemHere then ataxiaBasher_mnemHere("survey") end
