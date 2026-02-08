--Automatically turns on symphony if it's not already enabled.
if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

ataxia.bardStuff.rapierLevel = "L"..tonumber(matches[2])
ataxiaEcho("Rapier level set to: L"..matches[2])

ataxia_saveSettings(false)