local name = matches[2]
local space = math.floor((13-string.len(name))/2)

if type(target) == "string" then
	if isTargeted(matches[2]) then
		cecho("\n            <DimGrey>.-'~~~~~~~`-.")
		cecho("\n          <DimGrey>.'             `.")
		cecho("\n          <DimGrey>|   <tomato>R . I . P   <DimGrey>|")
		cecho("\n          <DimGrey>|               |")
		cecho("\n          <DimGrey>| <tomato>"..string.rep(" ", space)..name..string.rep(" ",13-string.len(name)-space).." <DimGrey>|")
		cecho("\n<green>        \\\\<DimGrey>| <purple>* <violet>* <orchid>* <NavajoWhite>* <orchid>* <violet>* <purple>* <DimGrey>|<green>//")
		cecho("\n<green>        ^^^^^^^^^^^^^^^^^^^^^")
		send("cq all")

		tAffs = {blindness = false, deafness = false, shield = false, rebounding = false, curseward = false}
		if resetStatesV3 then resetStatesV3() end
		tBals = {tree = true, focus = true, plant = true, timers = {}}
		tLimbs = {H=0, T=0, RL=0, LL=0, RA=0, LA=0, BP=5}
    if ataxiaTemp.lastAssess then ataxiaTemp.lastAssess = 100 end
    twohanded_resetFractures()
    expandAlias("res")
	end
end

if ataxia_paused() and not ataxia.defences.deliverance then
	ataxiaToggle("on")
  tzantzacurse = false


end
mindlocked = false
wantmindlock = true
lightbind = false
tAffs.bleed = 0
php = 100
pm = 100
tAffs.rebounding = false

if ataxia_isClass("depthswalker") then
dwaeon = true
tspeed = false
end
