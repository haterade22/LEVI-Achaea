--[[mudlet
type: trigger
name: Latency
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Fire Lord
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
- pattern: ^The brand twists and writhes, fiery tendrils radiating outwards beneath the skin of (\w+).$
  type: 1
]]--

if ataxiaTemp.firelord.brand >= 1 then
  selectString(line, 1)
  fg("DodgerBlue")
  deselect()
  ataxiaTemp.firelord.brand = nil
  ataxiaTemp.firelord.latency = tempTimer(10, [[ ataxiaTemp.firelord.latency = nil ]])
end