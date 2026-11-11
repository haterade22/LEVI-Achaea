--[[mudlet
type: alias
name: Serpent Auto Evade
hierarchy:
- Levi_Ataxia
- Classes
- Serpent
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^srevade(?: (on|off))?$
command: ''
packageName: ''
]]--

-- `srevade` shows the Serpent auto-evade setting; `srevade on|off` sets it (serpent/003_Auto_Evade).
-- Saved with the rest of serpent.config only if that table is saved; otherwise it is on after a load.
if not (serpent and serpent.evade) then
  cecho("\n<red>srevade: the Serpent auto-evade script is not loaded.")
  return
end
local want = matches[2]
if want == "on" then
  serpent.config.autoEvade = true
elseif want == "off" then
  serpent.config.autoEvade = false
end
local E = serpent.evade
cecho("\n<white>Serpent auto-evade: " .. (serpent.config.autoEvade == false and "<red>OFF" or "<green>ON")
  .. "<white> -- " .. E.NEEDED .. " attackers within " .. E.WINDOW .. " s, with balance, not "
  .. table.concat(E.BLOCKERS, "/") .. ".")
