--[[mudlet
type: trigger
name: Air Lord Passive
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
- pattern: ^The tempestuous form of (\w+) is cleansed by a purifying breeze\.$
  type: 1
]]--

local name = matches[2]

local voyriaBlock = ((pariah and pariah.latency) and true or false)

if isTargeted(name) then
  if haveAff("voyria") and not voyriaBlock then
    onClassCureV3({"voyria"})
  else
    ataxiaTemp.randomCure = 1
    onClassCureV3(nil, 1)
  end
  if startPassiveCooldownV3 then startPassiveCooldownV3("passive_airlord") end
  selectString(line,1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true
end
