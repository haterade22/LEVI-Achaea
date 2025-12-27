--[[mudlet
type: trigger
name: Hypnotised Success
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: You fix (\w+) with an entrancing stare, and smile in satisfaction as you realise that \w+ mind is yours.
  type: 1
]]--

tAffs.hypnotising = nil
tAffs.hypnotised = true
tAffs.hypnoseal = false
ataxiaTemp.hypnoseal = false

selectString(line,1)
fg("DarkSlateBlue")
setBold(true)
resetFormat()
ataxia_boxEcho("HYPNOTIZED - BEGIN SUGGESTING!", "orange:white")