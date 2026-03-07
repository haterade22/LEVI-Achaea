function lb.prompt()
  if not lb[target] then return "" end
  local hasHits = false
  for _, v in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do
    if lb[target].hits[v] > 0 then hasHits = true; break end
  end
  if not hasHits then return "" end
  local ret = {}
  -- CHANGE ORDER BELOW! CHANGE ORDER BELOW! CHANGE ORDER BELOW! CHANGE ORDER BELOW! CHANGE ORDER BELOW! CHANGE ORDER BELOW! --
  for _, v in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do 
  -----------------------------------------------------------------------------------------------------------------------------
    table.insert(ret, ((lb[target].hits[v] > 100 and "<red>") or ((lb[target].hits[v] > 0 and "<orange>") or "<grey>")) .. lb[target].hits[v])
  end
  return "<DimGrey>[" .. table.concat(ret, "<DimGrey>|") .. "<DimGrey>]"
end