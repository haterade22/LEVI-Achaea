--[[mudlet
type: trigger
name: Fool (Occultist/Jester)
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
- pattern: ^(\w+) presses a tarot to \w+ forehead, producing a wan smile.$
  type: 1
]]--

local name = matches[2]

local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) then
  erAff("paralysis")
  -- V2 integration: Fool cures paralysis + 3 random
  if removeAffV2 then removeAffV2("paralysis") end
	if class == "Jester" or class == "Occultist" then
		ataxiaTemp.randomCure = 3
		if reduceRandomAffCertaintyV2 then
			reduceRandomAffCertaintyV2()
			reduceRandomAffCertaintyV2()
			reduceRandomAffCertaintyV2()
		end
		selectString(line,1)
		fg("goldenrod")
		resetFormat()
		targetIshere = true
	end
end