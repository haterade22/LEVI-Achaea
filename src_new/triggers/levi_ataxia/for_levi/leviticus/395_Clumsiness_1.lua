--[[mudlet
type: trigger
name: Clumsiness
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^(\w+) stumbles clumsily as the blow lands.$
  type: 1
- pattern: (?:\w+) smashes the edge of (?:.*) into the kneecaps of (\w+), causing (?:\w+) to stumble.
  type: 1
- pattern: ^(\w+) barely clips you with .+ as \w+ fumbles her attack.$
  type: 1
- pattern: ^(\w+) misses you with \w+ dirk by a hair.$
  type: 1
- pattern: ^(\w+) stumbles, \w+ attack going wide.$
  type: 1
- pattern: ^\w+ severs the muscles in the \w+ arm of (\w+) with a precise blow of \w+ a translucent sword\.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("clumsiness")
end