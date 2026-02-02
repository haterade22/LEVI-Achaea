--[[mudlet
type: trigger
name: Snapped
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
- pattern: ^You snap your fingers in front of (\w+)\.$
  type: 1
]]--

tAffs.hypnotising = false
if removeAffV3 then removeAffV3("hypnotising") end
tAffs.hypnotised = false
if removeAffV3 then removeAffV3("hypnotised") end
tAffs.snapped = true
if applyAffV3 then applyAffV3("snapped") end
tAffs.hypnoseal = false
if removeAffV3 then removeAffV3("hypnoseal") end
ataxiaTemp.hypnoseal = false
serpentsuggest = false
tempTimer(3, [[tAffs.snapped = false;ataxiaTemp.suggestions = nil; if removeAffV3 then removeAffV3("snapped") end]])

snapTarget = false