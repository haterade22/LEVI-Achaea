--[[mudlet
type: trigger
name: Picked Up Gold
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
- pattern: ^You pick up (\d+) gold sovereigns.$
  type: 1
]]--

zData.char.gold = zData.char.gold + matches[2]
zData.char.ogold = tonumber(gmcp.Char.Status.gold)