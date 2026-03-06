--[[
    Generic handler: match full card name -> ldm.deck key, store charge count.
    Fixes bugs in original:
      - Stores matches[3] (charge number), not matches[2] (name string)
      - Uses ldm.matchFullName() for generic lookup instead of hardcoded elseif chain
      - Handles all cards including Covenant/Bakios correctly
]]--

if not ldm or not ldm.matchFullName then return end

local fullName = matches[2]
local charges  = tonumber(matches[3]) or 0
local cardKey  = ldm.matchFullName(fullName)

if cardKey and ldm.deck[cardKey] then
    ldm.deck[cardKey].charges = charges
end
