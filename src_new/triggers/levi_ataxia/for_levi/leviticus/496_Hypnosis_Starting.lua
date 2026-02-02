--[[mudlet
type: trigger
name: Hypnosis Starting
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
- pattern: ^You prepare yourself to hypnotise your victim, (\w+)\.$
  type: 1
]]--

tAffs.hypnotising = true
if applyAffV3 then applyAffV3("hypnotising") end
tAffs.hypnoseal = false
if removeAffV3 then removeAffV3("hypnoseal") end
ataxiaTemp.hypnoseal = false
ataxia_boxEcho("HYPNOTIZNG - TARGET!", "red:white")
