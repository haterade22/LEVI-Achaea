--[[mudlet
type: alias
name: Muting people
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Other stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(mute|unmute) (\w+)$
command: ''
packageName: ''
]]--

muteList = muteList or {}
local person = matches[3]:title()
if matches[2] == "mute" then
	if person == "Show" then
		ataxia_Echo("Currently muting: ")
		for p, b in pairs(muteList) do
			cecho("\n<red>"..p)
		end
	elseif not muteList[person] then
		ataxia_Echo("Now muting all speech from "..person..".")
		muteList[person] = true
	else
		ataxia_Echo(person.." is already muted.")
	end
else
	if muteList[person] then
		ataxia_Echo(person.." is no longer muted.")
		muteList[person] = nil
	else
		ataxia_Echo(person.." is not muted.")
	end
end