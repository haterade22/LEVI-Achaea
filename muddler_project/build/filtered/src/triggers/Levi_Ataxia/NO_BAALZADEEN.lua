send("cq all;summon baalzadeen")

-- Reset the summoned flag so dispatch can re-summon if needed
if apostate and apostate.state then
  apostate.state.baalzadeenSummoned = false
end