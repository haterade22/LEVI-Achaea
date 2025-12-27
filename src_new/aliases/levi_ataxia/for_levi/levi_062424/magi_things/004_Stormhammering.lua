--[[mudlet
type: alias
name: Stormhammering
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Magi Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(shrt|shre)$
command: ''
packageName: ''
]]--

local toHit = {}
local hitType = (matches[2] == "shrt" and "city" or "enemies")

--First compile a list of possible targets, based on 'ataxia.playersHere'
for _, person in pairs(ataxia.playersHere) do
  --If 't' then match target's city
  if hitType == "city" and ataxiaNDB_getCitizenship(target) == ataxiaNDB_getCitizenship(person) then
    table.insert(toHit, person)
  --Otherwise add if in enemies list
  elseif hitType == "enemies" and table.contains(ataxiaTemp.enemies, person) then
    table.insert(toHit, person)
  end
end

--Check if it can hit at least two targets (including the primary)
local secondary, tertiary = false, false
if not table.contains(toHit, target) then
  ataxia_boxEcho("primary target missing for stormhammer", "gold")
else
  for _, tar in pairs(toHit) do
    if tar ~= target then
      if not secondary then
        secondary = tar
      elseif not tertiary and secondary ~= tar then
        tertiary = tar  
      end
    end
  end
  
  if not secondary then
    ataxia_boxEcho("secondary target missing for stormhammer", "gold")
  elseif not tertiary then
    ataxiaEcho("Queued stormhammer for "..target.." and "..secondary..".")
    send("queue addclear free cast stormhammer at "..target.." and "..secondary,false)
  else
    ataxiaEcho("Queued stormhammer for "..target..", "..secondary.." and "..tertiary..".")
    send("queue addclear free cast stormhammer at "..target.." and "..secondary.." and "..tertiary,false)
  end 
end