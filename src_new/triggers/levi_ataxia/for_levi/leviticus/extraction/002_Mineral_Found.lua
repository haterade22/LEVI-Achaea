--[[mudlet
type: trigger
name: Mineral Found
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Harvesting
- Extraction
- Extraction Mineral List
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

local minList = {
  "ferrum", "stannum", "dolomite", "antimony", "bisemutum", "cuprum",
  "magnesium", "calamine", "malachite", "azurite", "plumbum",
  "realgar", "arsenic", "gypsum", "argentum", "calcite", "potash",
  "quicksilver", "aurum", "quartz", "cinnabar",
}
if table.contains(minList, matches[2]:lower()) then
  ataxiaExtraction[gmcp.Room.Info.area] = matches[2]:lower()
end