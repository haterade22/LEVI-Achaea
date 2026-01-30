--[[mudlet
type: alias
name: GRAVEHANDS
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Knight
- RUNIE
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^gh$
command: ''
packageName: ''
]]--


if gmcp.Char.Status.class == "Infernal" then
send("cq all;summon infestation;tyranny")

elseif gmcp.Char.Status.class == "Apostate" then
send("cq all;summon hands of the grave")

end