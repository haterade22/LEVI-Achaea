--[[mudlet
type: alias
name: DW Attune Toggle
hierarchy:
- Levi_Ataxia
- Classes
- Depthswalker
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dwattune(?: (on|off))?$
command: ''
packageName: ''
]]--

-- `dwattune on|off` -- whether every DW attack re-sends `shadow attune`.
-- ATTUNE is free with Gattan'lier; without it each one costs ~2.2s of
-- equilibrium. OFF re-attunes only when the target or the wanted directive
-- changes, or every attuneRefresh seconds (30) as a backstop. Bare `dwattune`
-- shows the setting.
if matches[2] == "on" then
    depthswalker.config.attuneEvery = true
elseif matches[2] == "off" then
    depthswalker.config.attuneEvery = false
end
if ataxiaEcho then
    ataxiaEcho("[DW] Attune on every attack: " .. (depthswalker.config.attuneEvery and "<green>ON" or "<red>OFF")
        .. "<reset> (free only with Gattan'lier)")
end
