--[[mudlet
type: trigger
name: Brand Hit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Fire Lord
- Brand Lines
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
- pattern: ^The twisting flesh upon the brow of (\w+) suddenly bursts into flame, the skin charring beneath the ravenous fires.$
  type: 1
- pattern: ^The seared flesh of (\w+)'s brow writhes and splits, the burning brand reforming in an instant, though its ominous
    glow is diminished.$
  type: 1
]]--

if isTargeted(matches[2]) then
  firelord_Branded()
end

