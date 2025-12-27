--[[mudlet
type: trigger
name: Unburrowed
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Misc
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
- pattern: You call your swarm back to you. Urgently.
  type: 3
- pattern: That swarm has not currently burrowed into anyone.
  type: 3
- pattern: ^You sense that (\w+) has escaped your burrowing swarm.$
  type: 1
]]--

tAffs.burrow = nil
pariah.burrow = false

selectString(line,1)
fg("green")
deselect()
resetFormat()