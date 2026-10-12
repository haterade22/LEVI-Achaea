--[[mudlet
type: trigger
name: Deadeyes
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Apostate
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
- pattern: ^You stare at (\w+), giving \w+ the evil eye.$
  type: 1
]]--

-- v4.7.416: SICKEN gives manaleech first, then slickness once manaleech is up, never paralysis (an
-- Apostate's own commands in Mystor's log, 2026-10-11; the wiki's paralysis-first text is outdated).
-- With both up, what it gives is unknown, so nothing is recorded.
local getSicken = {"manaleech", "slickness"}
local s = false
for _, aff in ipairs(getSicken) do
	if not haveAff(aff) then
		s = aff
		break
	end
end

if isTargeted(matches[2]) then
	if ataxiaTemp.deadeyesOne then
		if ataxiaTemp.deadeyesOne == "breach" then
			erAff("curseward")
		else
			if ataxiaTemp.deadeyesOne == "sicken" then
				if s then tarAffed(s) end
			else
				tarAffed(ataxiaTemp.deadeyesOne)
			end
		end
		ataxiaTemp.deadeyesOne = nil
	else
		if ataxiaTemp.deadeyesTwo == "sicken" then
			if s then tarAffed(s) end
		else
			tarAffed(ataxiaTemp.deadeyesTwo)
		end
		ataxiaTemp.deadeyesTwo = nil
		if not ataxiaTemp.contemplate then
			send("contemplate "..target)
		end
	end
	
	if haveAff("curseward") then erAff("curseward") end
	targetIshere = true
end