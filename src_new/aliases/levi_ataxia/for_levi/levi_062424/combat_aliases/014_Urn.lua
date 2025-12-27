--[[mudlet
type: alias
name: Urn
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^urnx?$
command: ''
packageName: ''
]]--

local mountid = ataxia.mountid or "urn/"..ataxiaTemp.me
if mountid == 0 then
  mountid = "urn/"..ataxiaTemp.me
end
local sp = ataxia.settings.separator

if command:find("x") then 
  dontMount = true 
  ataxia_Echo("Not setting vault on call.")
end

local act = "dismount impastus"..sp.."tell impastus come here"..sp.."concentrate"..sp.."stand"..sp.."rub urn"..sp.."vault "..mountid..sp.."order "..mountid.." go home"
send("queue addclear free "..act,false)
