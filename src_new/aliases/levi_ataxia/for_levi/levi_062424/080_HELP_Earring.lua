--[[mudlet
type: alias
name: HELP Earring
hierarchy:
- Levi_Ataxia
- Artefacts
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^h(pro|ent|ant|axi|aeg|pha|zyl|vit|tab|xar|ils)$
command: ''
packageName: ''
]]--

local locationMap = {
  axi = "axios",
  aeg = "aegoth",
  pro = "proficy",
  pha = "pharaus",
  zyl = "zylvith",
  ant = "antoninus",
  ent = "entaro",
  xar = "xarthus",
  tab = "tabethys",
}

local function travelEarring(location)
  local earring = ataxia.getEarring(location)
  if earring then
    send("clearqueue all;queue add free travel to "..location.." with "..earring)
  else
    ataxia_Echo("Earring for "..location.." not configured. Use: ataxia setup earrings")
  end
end

local location = locationMap[matches[2]]
if location then
  travelEarring(location)
end
