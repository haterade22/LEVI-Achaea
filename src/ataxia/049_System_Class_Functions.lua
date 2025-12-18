-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Misc Scripts > System Class Functions

function ataxia_isClass(what)
	local x = gmcp.Char.Status.class:lower()
	local y = what:lower()

  if y == "knight" and (x == "runewarden" or x == "infernal" or x == "paladin") then
    return true
	elseif x == y then
		return true
	else
		return false
	end
end

function getClassArmour()
	local com = ""
	local armours = {
		Alchemist = "ringmail",
		Apostate = "ringmail",
		Bard = "leather",
		Blademaster = "ringmail",
		Depthswalker = "scalemail",
		Druid = "chainmail",
		Infernal = "fullplate",
		Jester = "scalemail",
		Monk = "leather",
		Occultist = "scalemail",
		Paladin = "fullplate",
		Priest = "splintmail",
		Runewarden = "fullplate",
		Sentinel = "chainmail",
		Serpent = "scalemail",
		Shaman = "scalemail",
		Sylvan = "chainmail",
    Unnamable = "fullplate",
	}
	local class = gmcp.Char.Status.class
	local race = gmcp.Char.Status.race
	if race ~= "Horkval" then
		if armours[class] then
			com = "wear "..armours[class]
		end
	end
	return com
end