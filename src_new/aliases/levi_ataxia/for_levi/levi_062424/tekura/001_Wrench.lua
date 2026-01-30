--[[mudlet
type: alias
name: Wrench
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Monks
- Monk
- Monk
- Tekura
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^wr(ra|la|h|t)?$
command: ''
packageName: ''
]]--

if matches[2] then
local limbstable = {
["ra"] = "right arm",
["la"] = "left arm",
["t"] = "torso",
["h"] = "head"
}
 
for k, v in pairs(limbstable) do
    if k == tostring(matches[2]) then
        location = v
        break
    end
end
send("queue add eqbal wrt " .. target .. " " .. location) -- you will want to add the venom part .. " " .. venom)
 
end
