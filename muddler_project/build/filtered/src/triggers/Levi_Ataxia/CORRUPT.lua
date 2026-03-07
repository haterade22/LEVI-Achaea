if isTargeted(matches[2]) then
  expandAlias("res")

  -- Reset V2 affliction tracking
  if resetAffsV2 then resetAffsV2() end

  -- Reset V3 branching state tracker
  if resetStatesV3 then resetStatesV3() end

  corrupted = tempTimer(4.5, [[corrupted = true; corrupted = nil]])
end