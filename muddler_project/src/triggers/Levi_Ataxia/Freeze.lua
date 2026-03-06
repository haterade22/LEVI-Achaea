if (line:find("Wheel") and table.contains(ataxia.playersHere, target)) or isTargeted(matches[2]) then
  for _, stage in pairs( {"nocaloric", "shivering", "freezing"}) do
    if not haveAff(stage) then
      tarAffed(stage)
      if applyAffV3 then applyAffV3(stage) end
      break
    end
  end
end