--[[mudlet
type: trigger
name: Crits
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: ^You have scored (a|an) (.+)!$
  type: 1
]]--

local critFind = matches[1]:lower()
local critTypes = { ["4x"] = "crushing", ["8x"] = "obliterating", ["16x"] = "annihilating", ["32x"] = "shattering", ["64x"] = "plane", }
local critFound = false

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("attack", "Scored a " ..matches[3].." critical!")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

if not ataxiaTemp.ignoreCrits then
	for mult, level in pairs(critTypes) do
		if critFind:find(level) then
			bashStats.criticals[mult] = bashStats.criticals[mult] + 1
			critFound = true
			break
		end
	end
	if not critFound then
		bashStats.criticals["2x"] = bashStats.criticals["2x"] + 1
	end
	bashStats.crits = bashStats.crits + 1
end