-- Card is out of charges — set to 0 via generic lookup
if ldm and ldm.matchFullName then
    local fullName = matches[2]
    local cardKey = ldm.matchFullName(fullName)
    if cardKey and ldm.deck[cardKey] then
        ldm.deck[cardKey].charges = 0
    end
end
