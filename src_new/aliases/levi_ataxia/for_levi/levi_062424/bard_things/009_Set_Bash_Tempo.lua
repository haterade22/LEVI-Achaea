--[[mudlet
type: alias
name: Set Bash Tempo
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Bard
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bashtempo (\w+)
command: ''
packageName: ''
]]--

local tempos = {
	"adagio", "moderato", "allegro", "vivace", "none",
}
local x = string.lower(matches[2])

if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

if not table.contains(tempos, x) then
	ataxiaEcho("Invalid bash tempo: "..matches[2]..". Use vivace, adagio, moderato, allegro, or none.")
else
	ataxia.bardStuff = ataxia.bardStuff or {}
	ataxia.bardStuff.bashTempo = x
	ataxiaEcho("Bash tempo set to "..x.." (vivace = most back-position hits, 5 of 12 -- 5 of 6 with bashflourish; moderato 2 of 7; allegro reaches back fastest on squishy denizens; none = leave tempo unmanaged).")
	ataxia_saveSettings(false)
end
