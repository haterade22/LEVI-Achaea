local tgt = matches[2]
if tgt ~= target then return end
-- Emanation earth STARTS calcification process, not completes it
-- Actual calcify success tracked in 026_Calcify.lua
magi.calcifying_head = true
magi.offense.ptRelay(target .. ": Emanation Earth (calcifying)")
selectCurrentLine() bg("cyan")

