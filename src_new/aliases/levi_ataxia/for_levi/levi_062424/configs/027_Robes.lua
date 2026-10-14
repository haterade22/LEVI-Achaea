--[[mudlet
type: alias
name: Robes
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig robes(?: (.+))?$
command: ''
packageName: ''
]]--

-- Alchemist robes (class_things/004_Alchemist_Robes.lua).
-- `aconfig robes`                  -- mode, the next imbue, and what we last imbued.
-- `aconfig robes auto`             -- the four damage types that hit hardest (default).
-- `aconfig robes lead iron gold mercury` -- a fixed set (up to four symbols).
-- `aconfig robes off`              -- defup/login no longer summon or imbue.
-- `aconfig robes now` / `summon`   -- imbue now / summon a new set and imbue it.
-- Not a bare `robes`: that would swallow the game command.
ataxia_setRobes(matches[2])
if matches[2] and matches[2] ~= "now" and matches[2] ~= "summon" then ataxia_saveSettings(false) end
