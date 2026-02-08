if ataxiaBasher.enabled then
  ataxiaBasher.shielded = false
end

if matches[2] == "the rotting nest" then pariah.lastLogograph = "nest" end
if matches[2] == "the striking serpent" then pariah.lastLogograph = "serpent" end
if matches[2] == "the leaping jackal" then pariah.lastLogograph = "jackal" end
if matches[2] == "the hungering scarab" then pariah.lastLogograph = "scarab" end
if matches[2] == "the savage bear" then pariah.lastLogograph = "bear" end
if matches[2] == "the balanced scales" then pariah.lastLogograph = "scales" end
if matches[2] == "the shining sun" then pariah.lastLogograph = "sun" end
if matches[2] == "the skein" then pariah.lastLogograph = "skein" end
if matches[2] == "the striking scorpion" then pariah.lastLogograph = "scorpion" end





--the savage bear
if pariah.lastLogograph == nil then
local logSearch = matches[2]
for _, logo in pairs({"serpent", "bear", "sun", "nest", "scales", "skein", "scarab", "jackal", "scorpion"}) do
  if logSearch:find(logo) then
    pariah.lastLogograph = logo
    break
  end
end
if logoTimer then killTimer(logoTimer) end
logoTimer = tempTimer(6, [[ logoTimer = nil; pariah.lastLogograph = nil ]])    
end
