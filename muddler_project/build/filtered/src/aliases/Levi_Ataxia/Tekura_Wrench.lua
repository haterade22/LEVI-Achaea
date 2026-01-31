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
