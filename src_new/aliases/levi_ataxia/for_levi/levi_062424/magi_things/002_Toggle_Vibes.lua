--[[mudlet
type: alias
name: Toggle Vibes
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Magi Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^vibe (\w+)$
command: ''
packageName: ''
]]--

local vibrations = {
	"dissipate", "palpitation", "alarm", "tremors", "reverberation", "adduction", "harmony",
  "creeps", "silence", "revelation", "oscillate", "disorientation", "energise", "stridulation",
  "gravity", "forest", "dissonance", "plague", "lullaby",
}
local vibe = matches[2]:lower()

if not ataxia_isClass("magi") then
	ataxiaEcho("Class is not currently magi.")
	return
end

ataxia.magi = ataxia.magi or {}
ataxia.magi.vibes = ataxia.magi.vibes or {}

if table.contains(vibrations, vibe) then
	if table.contains(ataxia.magi.vibes, vibe) then
			table.remove(ataxia.magi.vibes, table.index_of(ataxia.magi.vibes, vibe))
			ataxiaEcho("Removed "..vibe.." from wanted vibrations.")
	else
		table.insert(ataxia.magi.vibes, vibe)
		ataxiaEcho("Added "..vibe.." to wanted vibrations.")
	end
else
	ataxiaEcho("Invalid vibe: "..matches[2]..".")
end
