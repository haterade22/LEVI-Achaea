if isTargeted(matches[2]) then
  for _, aff in pairs({"nocaloric", "shivering", "frozen"}) do
    if not haveAff(aff) then
      tarAffed(aff)
      break
    end
  end
end