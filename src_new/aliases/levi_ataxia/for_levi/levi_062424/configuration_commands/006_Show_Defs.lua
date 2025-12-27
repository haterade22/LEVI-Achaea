--[[mudlet
type: alias
name: Show Defs
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Defence Stuff
- Configuration Commands
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ashow defup$
command: ''
packageName: ''
]]--

local profile = ataxia.settings.defences.current
local defs = {}
ataxiaEcho("Showing "..profile.." defup:")

for def, boo in pairs(ataxia.settings.defences.defup[profile]) do
	if boo == true then
		defs[def] = {keep = false, defup = true}
		for defence, actual in pairs(ataxiaTables.defences) do
			if ataxia.defences[defence] or ataxia.defences[actual] then
				defs[def].have = true
			else
				defs[def].have = false
			end
		end
	end
end

for def, boo in pairs(ataxia.settings.defences.keepup[profile]) do
	if boo == true then
		defs[def].keep = true
		for defence, actual in pairs(ataxiaTables.defences) do
			if ataxia.defences[defence] or ataxia.defences[actual] then
				defs[def].have = true
			else
				defs[def].have = false
			end
		end
	end
end

for def, tab in pairs(defs) do
	cecho("\n "..(tab.have == true and "<green>" or "<red>")..utf8.char(186).." "..(tab.keep == true and "<green>" or "<red>")..utf8.char(186).." <a_darkcyan>"..def)
end
send(" ")

