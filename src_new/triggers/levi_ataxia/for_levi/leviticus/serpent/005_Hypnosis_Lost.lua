--[[mudlet
type: trigger
name: Hypnosis Lost
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
- pattern: ^You feel your control over (\w+)'s mind fade\.$
  type: 1
- pattern: ^(\w+) has noticed your attempt at hypnosis\!$
  type: 1
- pattern: '^(\w+) is too perceptive for your hypnotic skill. '
  type: 1
]]--

tAffs.hypnotising = false
if removeAffV3 then removeAffV3("hypnotising") end
tAffs.hypnotised = false
if removeAffV3 then removeAffV3("hypnotised") end
tAffs.snapped = false
if removeAffV3 then removeAffV3("snapped") end
tAffs.hypnoseal = false
if removeAffV3 then removeAffV3("hypnoseal") end
ataxiaTemp.hypnoseal = false
