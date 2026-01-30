--[[mudlet
type: trigger
name: Clotting
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
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
- pattern: You exert superior mental control and your wounds clot before your eyes.
  type: 3
]]--

if type(target) == "number" and ataxiaBasher.enabled then
	if not bashClotSub then 
		bashConsoleEcho("curing", "Clotted bleeding")	
		bashClotSub = tempTimer(1, [[ bashClotSub = nil ]])
	end
end

if ataxia.settings.gagclot then
	deleteFull()
end