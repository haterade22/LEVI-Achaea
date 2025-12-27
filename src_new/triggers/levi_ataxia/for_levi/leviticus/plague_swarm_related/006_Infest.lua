--[[mudlet
type: trigger
name: Infest
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Plague/Swarm Related
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 5
mStayOpen: 1
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You direct your swarm to infest (\w+)\.$
  type: 1
]]--

  tAffs.burrow = false
  pariah.burrow = false

if pariah.infest then killTimer(pariah.infest) end
pariah.infest = tempTimer(13, [[ pariah.infest = nil ]])


  selectString(line,1)
  fg("orange")
  deselect()
  resetFormat()