--[[mudlet
type: trigger
name: Strata 1
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
- pattern: The rock plates covering your form rapidly thicken, sharp spikes of stone sprouting from them in an instant.
  type: 3
- pattern: You feel the magma contained within your hallowed form cooling, your thoughts growing more sluggish.
  type: 3
]]--

ataxia.vitals.shaping = 1 
if ataxiaBasher.enabled and not ataxiaBasher.manual then
  deleteFull()
else
  local sColour = {[0] = "grey", [1] = "chat_bg", [2] = "DimGrey", [3] = "NavajoWhite", [4] = "chocolate",}
  selectString(line,1)
  fg(sColour[ataxia.vitals.shaping])
  deselect()
  resetFormat()
end