local name = matches[2]
local binds = string.split(matches[3], " ")
local attunes = string.split(matches[4], " ")
local tether = matches[5]

if not shaman.checkSpirits(binds) then
  ataxia_Echo("Invalid binds chosen! Try again!")
  return
elseif not shaman.checkSpirits(attunes) then
  ataxia_Echo("Invalid attunes chosen! Try again!")
  return
elseif not shaman.checkSpirits(tether) and tether ~= "none" then
  ataxia_Echo("Invalid tether chosen! Try again, or choose 'none'.")
  return
end

ataxia_Echo("Created new Spiritlore with profile of: "..name..".")
shaman.spiritlore.profiles[name] = {}
ataxia_Echo("Spiritlore binds for "..name.." set to: "..table.concat(binds, ", ")..".")
shaman.spiritlore.profiles[name].bindings = {}
for _, bind in pairs(binds) do
  table.insert(shaman.spiritlore.profiles[name].bindings, bind:title())
end
ataxia_Echo("Spiritlore attunes for "..name.." set to: "..table.concat(attunes, ", ")..".")
shaman.spiritlore.profiles[name].attunements = {}
for _, attune in pairs(attunes) do
  table.insert(shaman.spiritlore.profiles[name].attunements, attune:title())
end
ataxia_Echo("Spiritlore tether for "..name.." set to: "..tether..".")
shaman.spiritlore.profiles[name].tether = tether:title()
send(" ",false)