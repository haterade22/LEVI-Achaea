--[[mudlet
type: trigger
name: Entity Shield Strips
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Other Things Fading
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
- pattern: ^A small brown lemming rips apart the magical shield defence of (\w+)\.$
  type: 1
- pattern: ^A gremlin leaps at (\w+), cackling madly as it delivers blow after blow against \w+ magical shield.$
  type: 1
]]--

if isTargeted(matches[2]) then
  erAff("shield")
  if removeAffV3 then removeAffV3("shield") end
end