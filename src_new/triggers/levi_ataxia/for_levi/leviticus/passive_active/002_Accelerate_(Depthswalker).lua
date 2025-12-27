--[[mudlet
type: trigger
name: Accelerate (Depthswalker)
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
  isMultiline: 'yes'
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
- pattern: ^A look of relief comes over (\w+) as \w+ grows less pale.$
  type: 1
- pattern: '1'
  type: 5
- pattern: (.*)
  type: 1
]]--

local name = multimatches[1][2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(name) and class == "Depthswalker" then
  erAff("recklessness")
	if multimatches[3][1] == name.." grows older before your eyes." and not haveAff("prone") then
    ataxiaTemp.randomCure = 2
	else
		ataxiaTemp.randomCure = 1
	end
	targetIshere = true
end

