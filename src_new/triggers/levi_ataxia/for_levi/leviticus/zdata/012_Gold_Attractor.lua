--[[mudlet
type: trigger
name: Gold Attractor
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
- pattern: ^.+ from the corpse\, flying into your hands before they can reach the ground\.$
  type: 1
]]--

if zData.char.ogold ~= tonumber(gmcp.Char.Status.gold) then
  zData.char.gold = zData.char.gold + (tonumber(gmcp.Char.Status.gold) - zData.char.ogold)
  zData.char.ogold = tonumber(gmcp.Char.Status.gold)
end