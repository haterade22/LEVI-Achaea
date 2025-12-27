--[[mudlet
type: trigger
name: Enemy found
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Allies/Enemies
- Enemies List
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
- pattern: ^(\w+)
  type: 1
]]--

if not table.contains(ataxiaTemp.enemies, matches[2]) and ataxiaNDB_Exists(matches[2]) then
  table.insert(ataxiaTemp.enemies, matches[2])
  
  if table.contains(ataxiaTemp.allies, matches[2]) then
    for n, name in pairs(ataxiaTemp.allies) do
      if name == matches[2] then
        table.remove(ataxiaTemp.allies, n)
        break
      end
    end
  end
end