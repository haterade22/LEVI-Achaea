--[[mudlet
type: trigger
name: Catch Stats
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- zData
- zData
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
- pattern: ^Your (\w+) is (\d+).$
  type: 1
]]--

deleteLine()
if matches[2] == "strength" then
  zData.char.str = matches[3]
elseif matches[2] == "dexterity" then
  zData.char.dex = matches[3]
elseif matches[2] == "intelligence" then
  zData.char.int = matches[3]
elseif matches[2] == "constitution" then
  zData.char.con = matches[3]
end