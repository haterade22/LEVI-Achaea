if matches[2] == target then
  if matches[3] == "left" and matches[4] == "leg" then
    lb[target].hits["left leg"] = lb[target].hits["left leg"] + 15
  elseif matches[3] == "right" and matches[4] == "leg" then
    lb[target].hits["right leg"] = lb[target].hits["right leg"] + 15
  elseif matches[3] == "left" and matches[4] == "arm" then
    lb[target].hits["left arm"] = lb[target].hits["left arm"] + 15
  elseif matches[3] == "right" and matches[4] == "arm" then
    lb[target].hits["right arm"] = lb[target].hits["right arm"] + 15
  end
end