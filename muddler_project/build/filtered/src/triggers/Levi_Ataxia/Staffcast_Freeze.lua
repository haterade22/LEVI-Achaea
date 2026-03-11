local tgt = matches[2]
if not tgt or tgt ~= target then return end

tarAffed("horripilation")

magi.offense = magi.offense or {}
if magi.offense.ptRelay then
  magi.offense.ptRelay(target .. ": Staffcast freeze (horripilation)")
end
if magi.offense.debugEcho then
  magi.offense.debugEcho("Staffcast freeze → horripilation")
end
