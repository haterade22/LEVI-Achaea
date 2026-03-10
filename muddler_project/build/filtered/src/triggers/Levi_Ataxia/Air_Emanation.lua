local tgt = matches[2]
if tgt ~= target then return end

tarAffed("paralysis")
tarAffed("dizziness")
magi.offense = magi.offense or {}
magi.offense.ptRelay(target .. ": Emanation Air (Paralysis + Dizziness)")
selectCurrentLine() bg("cyan")