--[[mudlet
type: alias
name: Toggle Footwork Flourish
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Bard
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bashflourish(?:\s+(on|off))?$
command: ''
packageName: ''
]]--

-- `bashflourish [on|off]` -- flourish at every return to FRONT (front -> back, skipping the side
-- hits), boon or no boon. Pays on Vivace at any back bonus, on Adagio/Moderato only with Shadow
-- Tempo, never on Allegro/none -- `ataxiaBasher_bardFootworkFlourishPays` (basher/002) applies
-- that rule from the GAME's tempo line, so switching this on with no Tempo learned does nothing.
-- Off by default: Flourish is a 1924-lesson ability and the back bonus is unmeasured outside
-- Shadow Tempo. See .claude/classes/bard.md, "Tempo: the numbers".
if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

ataxia.bardStuff = ataxia.bardStuff or {}
local arg = matches[2]
if arg == "on" then
	ataxia.bardStuff.footworkFlourish = true
elseif arg == "off" then
	ataxia.bardStuff.footworkFlourish = false
else
	ataxia.bardStuff.footworkFlourish = not ataxia.bardStuff.footworkFlourish
end
if ataxia.bardStuff.footworkFlourish then
	ataxiaEcho("Footwork flourish <green>ON<reset>: BLADE FLOURISH at every return to front (Vivace always; Adagio/Moderato with Shadow Tempo; never Allegro/none).")
else
	ataxiaEcho("Footwork flourish <red>OFF<reset>: flourish only for the Deadly Flourish boon.")
end
ataxia_saveSettings(false)
