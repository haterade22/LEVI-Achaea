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
regex: ^bashflourish(?:\s+(on|off|always))?$
command: ''
packageName: ''
]]--

-- `bashflourish [on|off|always]` -- BLADE FLOURISH at every return to FRONT (front -> back,
-- skipping the side hits), boon or no boon. ON (the default since v4.7.312) applies the tempo rule
-- from the 2026-09-16 analysis -- Vivace at any back bonus, Adagio/Moderato only with Shadow
-- Tempo, never Allegro/none -- read from the GAME's tempo line, so an unlearned Tempo keeps it
-- quiet. ALWAYS drops that rule: every return to front, whatever the tempo. OFF leaves flourish to
-- the Deadly Flourish boon alone. See .claude/classes/bard.md, "Tempo: the numbers".
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
elseif arg == "always" then
	ataxia.bardStuff.footworkFlourish = "always"
else
	ataxia.bardStuff.footworkFlourish = not ataxia.bardStuff.footworkFlourish
end
local mode = ataxia.bardStuff.footworkFlourish
if mode == "always" then
	ataxiaEcho("Footwork flourish <green>ALWAYS<reset>: BLADE FLOURISH at every return to front, whatever the tempo.")
elseif mode then
	ataxiaEcho("Footwork flourish <green>ON<reset>: BLADE FLOURISH at every return to front on Vivace (any tempo with Shadow Tempo except Allegro); never on Allegro or with no tempo.")
else
	ataxiaEcho("Footwork flourish <red>OFF<reset>: flourish only for the Deadly Flourish boon.")
end
ataxia_saveSettings(false)
