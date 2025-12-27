--[[mudlet
type: trigger
name: CompassSlash
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes A-J
- Blademaster
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Whispering a prayer to the \w+ winds, you draw \w+ \w+ and unleash a slash towards (\w+)'s (left leg|right leg|left
    arm|right arm|head|torso)\.$
  type: 1
]]--

ataxiaTemp.lastLimbHit = matches[3]

if isTargeted(matches[2]) then
  lastLimbAttack = "bmCompass"
end
