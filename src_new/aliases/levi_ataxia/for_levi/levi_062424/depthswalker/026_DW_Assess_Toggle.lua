--[[mudlet
type: alias
name: DW Assess Toggle
hierarchy:
- Levi_Ataxia
- Classes
- Depthswalker
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dwassess(?: (on|off))?$
command: ''
packageName: ''
]]--

-- `dwassess on|off` -- whether every DW attack ends with `assess <target>`.
-- ASSESS is balanceless only with the HEALTH INSPECTOR trait; a Depthswalker
-- without it pays for an assess on every attack. Cull and Mutilate read the
-- target's health from these assesses. Bare `dwassess` shows the setting.
if matches[2] == "on" then
    depthswalker.config.assess = true
elseif matches[2] == "off" then
    depthswalker.config.assess = false
end
if ataxiaEcho then
    ataxiaEcho("[DW] Assess on every attack: " .. (depthswalker.config.assess and "<green>ON" or "<red>OFF")
        .. "<reset> (free only with the Health Inspector trait)")
end
