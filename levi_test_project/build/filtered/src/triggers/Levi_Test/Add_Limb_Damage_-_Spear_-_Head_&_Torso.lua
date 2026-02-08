if matches[2] == target then
  if matches[3] == "head" then
    lb[target].hits["head"] = lb[target].hits["head"] + 15
  elseif matches[3] == "torso" then
    lb[target].hits["torso"] = lb[target].hits["torso"] + 15
  
  end
end