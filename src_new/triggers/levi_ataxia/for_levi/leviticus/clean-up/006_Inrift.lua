--[[mudlet
type: trigger
name: Inrift
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Clean-up
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
- pattern: ^You store (\d+) (.+), bringing the total in the rift to (\d+).$
  type: 1
]]--

if type(target) == "number" and ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
else
	deleteLine()
	cecho("\n<NavajoWhite>[RIFT]: <green>+<white>"..matches[2].." <grey>"..matches[3]:title()..". Total: <white>"..matches[4]..".")
end

if tonumber(matches[4]) > 50 and riftMsgList[matches[3]] then
	riftMsgList[matches[3]] = nil
end
