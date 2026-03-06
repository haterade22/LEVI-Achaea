if isTargeted(matches[2]) then
    serpent.impulseSuccess = true
    -- Track monkshood ekanelia (impatience) delivery for relapse locking
    if matches[3] == "monkshood" then
        serpent.state.impatienceDelivered = true
    elseif matches[3] == "scytherus" then
        serpent.state.camusDelivered = true
    end
    Algedonic.Echo("<green>EKANELIA SUCCESS<white> (" .. matches[3] .. ")")
end
