--[[mudlet
type: trigger
name: Passives
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
- Passive/Active
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
- pattern: ^(\w+) surrounds \w+ with a translucent achromatic aura.$
  type: 1
- pattern: ^(\w+) is surrounded in a cool, refreshing mist.$
  type: 1
- pattern: ^The air shudders about (\w+), a keening whine on the edge of hearing.$
  type: 1
]]--

local name = matches[2]
local voyriaBlock = ((pariah and pariah.latency) and true or false)

if isTargeted(matches[2]) then
  if haveAff("voyria") and not voyriaBlock then
    onClassCureV3({"voyria"})
    if startPassiveCooldownV3 then startPassiveCooldownV3("passive_generic") end
  else
    ataxiaTemp.randomCure = 1
    onClassCureV3(nil, 1)
    if startPassiveCooldownV3 then startPassiveCooldownV3("passive_generic") end
  end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
 
 tBals.passive = false
 tempTimer(14.9,[[tBals.passive = true]])
  
end
