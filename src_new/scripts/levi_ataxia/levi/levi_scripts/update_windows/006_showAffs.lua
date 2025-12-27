--[[mudlet
type: script
name: showAffs
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Update Windows
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function zgui.showAffs()
  if zgui.afflictionlock then
  	setBackgroundColor("pronAff", 0, 20, 0, 255)
	  setBackgroundColor("paraAff", 0, 20, 0, 255)
	  setBackgroundColor("impaAff", 0, 20, 0, 255)
	  setBackgroundColor("asthAff", 0, 20, 0, 255)
	  setBackgroundColor("anorAff", 0, 20, 0, 255)
	  setBackgroundColor("slicAff", 0, 20, 0, 255)
		if affed("prone") then setBackgroundColor("pronAff", 255, 0, 0, 255) end
		if affed("paralysis") then setBackgroundColor("paraAff", 255, 0, 0, 255) end
		if affed("impatience") then setBackgroundColor("impaAff", 255, 0, 0, 255) end
		if affed("asthma") then setBackgroundColor("asthAff", 255, 0, 0, 255) end
		if affed("anorexia") then setBackgroundColor("anorAff", 255, 0, 0, 255) end
		if affed("slickness") then setBackgroundColor("slicAff", 255, 0, 0, 255) end
  end
  
  if zgui.affliction then
    clearUserWindow("afflictionDisplay")
    cecho("afflictionDisplay", ataxia_promptAffs())
  end
end

function zgui.showTarAffs()
if type(target) ~= "number" then
	local ignoreAffs = {"curseward", "blindness", "deafness", "rebounding", "shield"}
	local str = "<a_brown>[<NavajoWhite>"..target:title().."<a_brown>]: "
	for aff, boo in pairs(tAffs) do
		if boo ~= false and not table.contains(ignoreAffs, aff) then
			if affs_to_colour[aff] then
				str = str.."<"..affs_to_colour[aff][1]..">"..affs_to_colour[aff][2].." "
			else
				str = str.."<DimGrey>"..string.sub(aff, 1, 3).." "
			end	
		end
	end
	clearUserWindow("targetafflictionDisplay")
  cecho("targetafflictionDisplay", str)
end
end