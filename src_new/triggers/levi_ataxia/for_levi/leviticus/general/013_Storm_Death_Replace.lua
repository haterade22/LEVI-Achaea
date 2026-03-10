--[[mudlet
type: trigger
name: Storm Death Replace
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^\w+ has culled (\w+) from the ranks of the living\.$
  type: 1
- pattern: ^Kill breakdown for (\w+)
  type: 1
]]--

if magi and magi.storm and magi.storm.targets then
  local deadName = matches[2]
  if table.contains(magi.storm.targets, deadName) then
    magi.storm.replaceDead(deadName)
  end
end
