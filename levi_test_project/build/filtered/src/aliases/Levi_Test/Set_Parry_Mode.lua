local x = matches[2]
if not ataxia.parrying then
	ataxia_createParry()
end

if x == "none" then
	ataxiaEcho("Disabled parry usage.")
	ataxia.settings.use.parry = false
elseif not table.contains(ataxia.parrying.modes, x) then
	ataxiaEcho("Invalid parrying method. Options are manual, stand or defend.")
	cecho("\n<white>STAND :            <green>Focus on parrying what will get/keep you standing.")
	cecho("\n<white>DEFEND:            <green>Focus on parrying what's closest to breaking, with weights.")
	cecho("\n<white>MANUAL:            <green>Manually set your parrying.")
	cecho("\n<white>RANDOM (ARM|LEG):  <green>Parries a random arm/leg. Has a 'cooldown' timer of 2.5 seconds between swaps.")
else
	ataxia.settings.use.parry = true
	ataxia.parry = x
	ataxiaEcho("Parrying method switched to "..ataxia.parry..".")
end