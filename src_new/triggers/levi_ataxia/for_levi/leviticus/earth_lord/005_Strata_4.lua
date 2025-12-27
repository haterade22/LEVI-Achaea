--[[mudlet
type: trigger
name: Strata 4
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Earth Lord
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
- pattern: Magma explodes from the cracks between the plates covering you, forming a cloak of molten stone to enshroud you.
  type: 3
]]--

ataxia.vitals.shaping = 4 
if ataxiaBasher.enabled and not ataxiaBasher.manual then
  deleteFull()
else
  local sColour = {[0] = "grey", [1] = "chat_bg", [2] = "DimGrey", [3] = "NavajoWhite", [4] = "chocolate",}
  selectString(line,1)
  fg(sColour[ataxia.vitals.shaping])
  deselect()
  resetFormat()
end