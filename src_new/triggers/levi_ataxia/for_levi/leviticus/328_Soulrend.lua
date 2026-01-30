--[[mudlet
type: trigger
name: Soulrend
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Vodun
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
- pattern: ^Focusing upon the link between your doll and \w+, you find \w+ sufficiently weakened to enhance your construct
    with (\d+) more fashions.$
  type: 1
]]--

ataxiaTemp.dollFashions = ataxiaTemp.dollFashions + tonumber(matches[2])
deleteLine()
cecho("\n<a_brown>[<purple>Doll<a_brown>]: <DimGrey>Soulrend gained us <red>"..matches[2].."<DimGrey> fashions. Total: <yellow>"..ataxiaTemp.dollFashions..".")