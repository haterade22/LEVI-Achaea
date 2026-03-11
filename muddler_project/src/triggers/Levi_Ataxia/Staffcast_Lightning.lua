local tgt = matches[2]
if not tgt or tgt ~= target then return end

-- Staffcast lightning delivers stupidity (handled by 009_Transfix_Stupidity already)
-- This trigger tracks the cast itself for relay purposes
magi.offense = magi.offense or {}
if magi.offense.ptRelay then
  magi.offense.ptRelay(target .. ": Staffcast lightning")
end
if magi.offense.debugEcho then
  magi.offense.debugEcho("Staffcast lightning hit")
end
