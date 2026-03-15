--[[mudlet
type: trigger
name: Hallelujah (Bard)
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
- pattern: ^A song can be heard on the edge of hearing as the air distorts about (\w+)\.$
  type: 1
- pattern: ^A soft chiming emanates from (\w+)\.$
  type: 1
]]--

local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

local voyriaBlock = ((pariah and pariah.latency) and true or false)

if isTargeted(name) and class == "Bard" then
  if haveAff("voyria") and not voyriaBlock then
    onClassCureV3({"voyria"})
  else
    ataxiaTemp.randomCure = 1
    onClassCureV3(nil, 1)
  end
  if startPassiveCooldownV3 then startPassiveCooldownV3("passive_hallelujah") end
  selectString(line,1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true
end
