--[[mudlet
type: alias
name: Bastard Hew
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- RUNIE
- 2H
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^q(ll|rl|ra|la|hh|tt)$
command: ''
packageName: ''
]]--

-- q<limb>: a manual bastard-sword hit on that limb (ll rl la ra hh tt), focus by the rw2h rule (SPEED until they sip, PRECISION after).
-- Disembowel/bisect/raze still come first. The automatic offence is the attack alias (rw2h).
-- Until v4.7.465 this called runietwohandlogic(), wieldingweapons() and bastardweapon(), which
-- were never defined, so the alias errored before it sent anything.
if gmcp.Char.Status.class ~= "Runewarden" then return end
rw2h.manual(matches[2], "bastard")
