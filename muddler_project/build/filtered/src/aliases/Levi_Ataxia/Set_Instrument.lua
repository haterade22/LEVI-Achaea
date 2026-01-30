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