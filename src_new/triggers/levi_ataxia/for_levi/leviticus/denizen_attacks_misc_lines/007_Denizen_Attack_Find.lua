--[[mudlet
type: trigger
name: Denizen Attack Find
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
attributes:
  isActive: 'no'
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
- pattern: ^(.*).$
  type: 1
]]--

local linefind = matches[2]:lower()
local xyz = ""
linefind = linefind:gsub("-", " ")
for _, mob in pairs(ataxiaBasher.targetList[gmcp.Room.Info.area]) do
	xyz = mob:lower()
	xyz = xyz:gsub("-", " ")
	if linefind:find(xyz) and not haveBeenHit then
		haveBeenHit = tempTimer(1, [[ haveBeenHit = nil ]])
		bashConsoleEcho("denizen", "Denizen attacked us!")
		bashStats.mobhits = bashStats.mobhits + 1
		if not ataxiaBasher.manual then
			deleteFull()
		end
	elseif linefind:find(xyz) and haveBeenHit then
		if not ataxiaBasher.manual then
			deleteFull()
		end
	end
end