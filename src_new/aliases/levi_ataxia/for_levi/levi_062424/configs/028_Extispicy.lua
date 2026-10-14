--[[mudlet
type: alias
name: Extispicy
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig extispicy(?: (on|off))?$
command: ''
packageName: ''
]]--

-- `aconfig extispicy`        -- on/off, and whether the defence is up.
-- `aconfig extispicy on|off` -- dissect rat corpses after rat kills (Alchemist, class_things/005).
ataxia_setExtispicy(matches[2])
if matches[2] then ataxia_saveSettings(false) end
