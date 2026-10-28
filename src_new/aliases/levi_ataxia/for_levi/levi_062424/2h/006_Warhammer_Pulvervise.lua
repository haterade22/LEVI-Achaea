--[[mudlet
type: alias
name: Warhammer Pulvervise
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- RUNIE
- 2H
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^a(ll|rl|ra|la|hh|tt)$
command: ''
packageName: ''
]]--

-- a<limb>: a manual warhammer hit on that limb (ll rl la ra hh tt), focus by the rw2h rule (SPEED until they sip, PRECISION after).
-- Until v4.7.465 this called runietwohandlogic() and hammerweapon(), which were never defined.
if gmcp.Char.Status.class ~= "Runewarden" then return end
rw2h.manual(matches[2], "warhammer")
