-- Only switch to mana priority if we have Inquisition
-- Kill condition requires INQ + <50% mana, so no INQ = no kill threat
if ataxia.afflictions.inquisition then
    send("curing priority mana", false)
    ataxiaTemp.priestManaPrio = true
    Algedonic.Echo("<cyan>ANGEL SAP + INQ - MANA PRIORITY<white>")

    -- Reset to health when INQ clears (20 sec is INQ duration)
    tempTimer(20, [[
        if not ataxia.afflictions.inquisition then
            send("curing priority health", false)
            ataxiaTemp.priestManaPrio = nil
        end
    ]])
end