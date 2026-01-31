--[[mudlet
type: trigger
name: Temper
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Alchemist
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
- pattern: ^You redirect (\w+)'s internal fluids, tempering \w+ (\w+) humour.$
  type: 1
]]--

local colours = {sanguine = "a_darkred", melancholic = "DeepSkyBlue", phlegmatic = "a_darkmagenta", choleric = "a_brown"}
local humour = matches[3]

selectString(matches[3], 1)
fg(colours[humour])
resetFormat()

tAffs[humour] = tAffs[humour] or 0
tAffs[humour] = tAffs[humour] + 1