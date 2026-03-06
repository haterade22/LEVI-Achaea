-- Prompt trigger: fires at the next prompt after ldeck list output finishes
if ldm and ldm.deckStop and ldm.state and ldm.state.parsing then
    ldm.deckStop()
end
