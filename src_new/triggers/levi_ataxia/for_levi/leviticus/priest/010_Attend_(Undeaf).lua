--[[mudlet
type: trigger
name: Attend (Undeaf)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Priest
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
- pattern: ^\"Attend me,\" you intone to (\w+)\.$
  type: 1
- pattern: ^\"So listen well,\" you intone to (\w+)\.$
  type: 1
]]--

if isTargeted(matches[2]) then
	selectString(line,1)
	fg("DimGrey")
	tAffs.deafness = false
	if removeAffV3 then removeAffV3("deafness") end
	deselect()
	
	ataxiaTemp.prayerList = ataxiaTemp.prayerList or {}
	table.insert(ataxiaTemp.prayerList, "attend")
end