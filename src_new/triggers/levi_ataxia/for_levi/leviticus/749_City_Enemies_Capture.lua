--[[mudlet
type: trigger
name: City Enemies Capture
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Ataxia NDB
attributes:
  isActive: 'no'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Enemies of the City of (\w+)\:$
  type: 1
- pattern: ^(\w+), (.+)$
  type: 1
]]--

ataxiaNDB.cityEnemies = {}
table.insert(ataxiaNDB.cityEnemies, multimatches[2][2])
for person in multimatches[2][3]:gmatch("[%w'%-]+") do
	table.insert(ataxiaNDB.cityEnemies, person)
end
table.sort(ataxiaNDB.cityEnemies)
ataxiaEcho("Updated city enemies list.")

disableTrigger("City Enemies Capture")