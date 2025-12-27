--[[mudlet
type: trigger
name: Ash (Spiritburn)
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
- pattern: ^\"And you shall be naught but cinders,\" you decree, focus?sing your holy might upon (\w+)\.$
  type: 1
- pattern: ^\"Return to ash\,\" you decree, focus?sing your holy might upon (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarZealHit("spiritburn")
	
	ataxiaTemp.prayerList = ataxiaTemp.prayerList or {}
	table.insert(ataxiaTemp.prayerList, "ash")
end
