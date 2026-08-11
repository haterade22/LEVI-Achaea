--[[mudlet
type: alias
name: Curingsets
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^curingsets$
command: ''
packageName: ''
]]--

-- `curingsets` -- what the GAME says exists, not what we assume.
--
-- Deliberately NOT named `curingset` (no s): that is a real in-game command and shadowing it
-- with an alias would swallow every CURINGSET NEW/SWITCH/LIST the user types.
--
-- Sends `curingset list`, parses the reply (ataxia/009_Curingset_State.lua) and reports:
-- free slots against the cap, which set is current, any name listed more than once (each copy
-- eats one of a hard-capped allowance and makes `curingset switch` ambiguous), and whether the
-- PvE bash profile's configured set actually exists.
--
-- That last line is the one worth having: the profile silently switches to
-- `ataxia.settings.bashcuring.setname` on every basher enable, and until v4.7.247 nothing
-- anywhere would tell you that set was never created.
if ataxia_curingsetReport then
	ataxia_curingsetReport()
elseif ataxiaEcho then
	ataxiaEcho("Curingset state module not loaded.")
end
