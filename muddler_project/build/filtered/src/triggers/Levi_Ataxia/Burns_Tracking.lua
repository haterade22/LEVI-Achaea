local line = matches[1]

-- Efreeti burning
if line:find("fiery efreeti spins into") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.burns = (magi.offense.state.burns or 0) + 1
    magi.offense.debugEcho("Efreeti burn → burns:" .. magi.offense.state.burns)
    cecho(" <DimGrey>[<red>" .. magi.offense.state.burns .. "/5<DimGrey>]")
  end

-- Conflagrate ongoing
elseif line:find("conflagration about") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.conflagrated = true
    magi.offense.ptRelay(target .. ": Conflagrate ticking")
    magi.offense.debugEcho("Conflagrate ticking on " .. target)
  end

-- Firestorm (AoE) - this is SELF-DAMAGE, not target burns
-- Firestorm AoE hits everyone in the room including the caster
-- Target burns from firestorm are tracked in 004_Firestorm_tick.lua
elseif line:find("firestorm roars") then
  magi.offense.debugEcho("Firestorm tick (self-damage, not tracking target burns here)")
end
