--[[mudlet
type: alias
name: Serpent Attack First
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aconfig serpent attackfirst(?: (on|off))?$
command: ''
packageName: ''
]]--

-- `aconfig serpent attackfirst`      -- show the setting.
-- `aconfig serpent attackfirst on`   -- the Serpent round sends its attack as the FIRST command
--                                       (serpent/002 buildRound). A wield goes before it only when
--                                       GMCP shows the weapon is not in hand, and a stand only when
--                                       we are prone. Purge, the adder order and g body / g gold /
--                                       stand go after it.
-- `aconfig serpent attackfirst off`  -- the order the rounds had before (the default).
-- Why: in the 2026-11-07 spar the game answered the second and later commands of a send about
-- 0.09 s after the first, so the attack, sent after six commands, landed about 0.12 s later on our
-- clock. Whether it also lands later at the server is not known. A spar with this on settles it.
local arg = matches[2]
if arg then
	ataxia.settings.serpentattackfirst = (arg == "on")
	ataxia_saveSettings(false)
end
local v = ataxia.settings.serpentattackfirst
ataxiaEcho("Serpent attack first: " .. (v and "<green>on<NavajoWhite> (the attack is the first command of each round)"
	or "<red>off<NavajoWhite> (purge, the adder order and g body / g gold / stand go before the attack)"))
