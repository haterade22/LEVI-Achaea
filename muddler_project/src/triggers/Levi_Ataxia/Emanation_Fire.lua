if isTargeted(matches[2]) then
  tarAffed("burning")
  -- Emanation fire applies 2 burn stacks
  magi = magi or {}
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 2, 5)
  tburns = magi.offense.state.burns
end
