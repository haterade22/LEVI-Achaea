--[[mudlet
type: trigger
name: Close Capture
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Reagent Butchering
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
- pattern: 'You are wearing:'
  type: 3
]]--

setTriggerStayOpen("Reagent Butchering", 0)
if ataxiaTemp.toButcher[1] and ataxiaTemp.butchering then
	sendAll("wield cleaver", "queue addclear free butcher "..ataxiaTemp.toButcher[1].." for reagent",false)
elseif ataxiaTemp.butchering then
	ataxiaTemp.butchering = nil
end