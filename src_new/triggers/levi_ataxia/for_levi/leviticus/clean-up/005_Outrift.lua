--[[mudlet
type: trigger
name: Outrift
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
- pattern: ^You remove (\d+) (.+), bringing the total in the rift to (\d+).$
  type: 1
]]--

if not ataxiaTemp.ignoreOutrift then outrifted(matches[3], matches[2]) end

if not riftMsgList then riftMsgList = {} end
if type(target) == "number" and ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
else
	deleteLine()
	cecho("\n<NavajoWhite>[RIFT]: <red>-<white>"..matches[2].." <grey>"..matches[3]:title()..". Remaining: <white>"..matches[4]..".")
end

if tonumber(matches[4]) <= 1 and not riftMsgList[matches[3]] then
	send("msg "..gmcp.Char.Name.name.." We likely ran out of "..matches[3]..". Should probably buy some more.")
	riftMsgList[matches[3]] = true
end