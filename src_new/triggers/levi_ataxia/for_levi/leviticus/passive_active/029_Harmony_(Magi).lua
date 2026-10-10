--[[mudlet
type: trigger
name: Harmony (Magi)
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
- pattern: ^A soft chiming emanates from (\w+)\.$
  type: 1
]]--

-- HARMONY (Crystalism) -- the Magi passive cure: about every 12s it cures one affliction,
-- voyria first. Its line used to be the second pattern of 025_Hallelujah_(Bard), whose body
-- requires class == "Bard", so against a Magi it never fired (found 2026-10-10, see
-- kb/afflictions/class-cures.md).
local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

local voyriaBlock = ((pariah and pariah.state and pariah.state.latencyTimer) and true or false)

if isTargeted(name) and class == "Magi" then
  if haveAff("voyria") and not voyriaBlock then
    onClassCureV3({"voyria"})
  else
    ataxiaTemp.randomCure = 1
    onClassCureV3(nil, 1)
  end
  if startPassiveCooldownV3 then startPassiveCooldownV3("passive_harmony") end
  selectString(line,1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true
end
