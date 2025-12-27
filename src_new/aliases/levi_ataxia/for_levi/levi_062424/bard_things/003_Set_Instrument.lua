--[[mudlet
type: alias
name: Set Instrument
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Bard Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bins (\w+)
command: ''
packageName: ''
]]--

local instruments = {
	"flute", "mandolin", "harp", "lute", "lyre",
}
local x = matches[2]

if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

if not table.contains(instruments, x) then
	ataxiaEcho("Invalid instrument type: "..x..".")
else
	ataxia.bardStuff.instrument = x
	ataxiaEcho("Instrument set to "..x..".")
end

ataxia_saveSettings(false)