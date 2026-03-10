local tgt = matches[2]
if tgt ~= target then return end
-- Emanation Fire: +2 burns (cap 5), track in magi.offense.state
magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}
magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 2, 5)
tburns = magi.offense.state.burns -- backward compat
tarAffed("burning")
magi.offense.ptRelay(target .. ": Emanation Fire (burns " .. magi.offense.state.burns .. "/5)")
cecho(" <DimGrey>[<red>" .. magi.offense.state.burns .. "/5<DimGrey>]")
selectCurrentLine() bg("cyan")