local convert = {
  head = "head",
  hh = "head",
  h = "head",
   
  torso = "torso",
  tt = "torso",
  t = "torso",
  
  ["right arm"] = "right arm",
  ra = "right arm",
  rarm = "right arm",
  
  ["left arm"] = "left arm",
  la = "left arm",
  larm = "left arm",
  
  ["right leg"] = "right leg",
  rl = "right leg",
  rleg = "right leg",
  
  ["left leg"] = "left leg",
  ll = "left leg",
  lleg = "left leg",
}

if convert[matches[2]] and target and lb[target] then
  lb.resetLimb(target, convert[matches[2]])
end