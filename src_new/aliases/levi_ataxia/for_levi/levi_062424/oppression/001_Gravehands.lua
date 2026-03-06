--[[mudlet
type: alias
name: Gravehands
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- Infernal
- Oppression
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^gr$
command: ''
packageName: ''
]]--

if ataxiaTemp.class == "Infernal" then
send("summon infestation;tyranny")
elseif ataxiaTemp.class == "Apostate" then
send("summon hands of the grave")
end