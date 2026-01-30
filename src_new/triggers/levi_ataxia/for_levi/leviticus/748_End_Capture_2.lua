--[[mudlet
type: trigger
name: End Capture
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Ataxia NDB
- Explorers Rankings
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
- pattern: ''
  type: 7
]]--

setTriggerStayOpen("Explorers Rankings", 0)
if explorersUnchecked[1] then
	ataxiaEcho(#explorersUnchecked.." new names identified, grabbing their info.")
	cecho("\n<a_darkgrey> - "..table.concat(explorersUnchecked, ", ")..".")
	ataxiaNDB_NameList(explorersUnchecked)
end