--[[mudlet
type: alias
name: Evade Direction
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- BladeMaster
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^e(e|w|n|so|o|i|nw|ne|se|sw)$
command: ''
packageName: ''
]]--

if gmcp.Char.Status.class == "Blademaster" then
if matches[2] == "e" then
send("queue addclear free shin meditate;evade east")
elseif matches[2] == "w" then
send("queue addclear free shin meditate;evade west")
elseif matches[2] == "n" then
send("queue addclear free shin meditate;evade north")
elseif matches[2] == "nw" then
send("queue addclear free shin meditate;evade northwest")
elseif matches[2] == "so" then
send("queue addclear free shin meditate;evade south")
elseif matches[2] == "ne" then
send("queue addclear free shin meditate;evade northeast")
elseif matches[2] == "se" then
send("queue addclear free shin meditate;evade southeast")
elseif matches[2] == "sw" then
send("queue addclear free shin meditate;evade southwest")
elseif matches[2] == "i" then
send("queue addclear free shin meditate;evade in")
elseif matches[2] == "o" then
send("queue addclear free shin meditate;evade out")
end
end