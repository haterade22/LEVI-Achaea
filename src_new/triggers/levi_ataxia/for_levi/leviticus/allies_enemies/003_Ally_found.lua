--[[mudlet
type: trigger
name: Ally found
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Allies/Enemies
- Allies List
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
- pattern: ^(\w+) is an ally
  type: 1
- pattern: ^You feel an unusually strong lust for (\w+)
  type: 1
]]--

if not table.contains(ataxiaTemp.allies, matches[2]) then
  table.insert(ataxiaTemp.allies, matches[2])

  if table.contains(ataxiaTemp.enemies, matches[2]) then
    for n, name in pairs(ataxiaTemp.enemies) do
      if name == matches[2] then
        table.remove(ataxiaTemp.enemies, n)
        break
      end
    end
  end  
end