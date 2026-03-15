--[[mudlet
type: alias
name: Set Parry Mode
hierarchy:
- Levi_Ataxia
- Combat
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^parryy (\w+)$
command: ''
packageName: ''
]]--

local x = matches[2]
if not ataxia.parrying then
	ataxia_createParry()
end

local validModes = {stand = true, defend = true, manual = true, randomarm = true, randomleg = true, auto = true}

if x == "none" then
	ataxiaEcho("Disabled parry usage.")
	ataxia.settings.use.parry = false
elseif not validModes[x] then
	ataxiaEcho("Invalid parrying method.")
	cecho("\n<white>AUTO  :            <green>Class-aware auto parry (adapts to enemy attack patterns).")
	cecho("\n<white>STAND :            <green>Focus on parrying what will get/keep you standing.")
	cecho("\n<white>DEFEND:            <green>Focus on parrying what's closest to breaking, with weights.")
	cecho("\n<white>MANUAL:            <green>Manually set your parrying.")
	cecho("\n<white>RANDOM (ARM|LEG):  <green>Parries a random arm/leg. Has a 'cooldown' timer of 2.5 seconds between swaps.")
else
	ataxia.settings.use.parry = true
	ataxia.parry = x
	ataxiaEcho("Parrying method switched to "..ataxia.parry..".")
end