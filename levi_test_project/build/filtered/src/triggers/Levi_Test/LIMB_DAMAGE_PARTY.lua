if isTargeted(matches[3]) then
if matches[4] == "head" then tLimbs.H = tLimbs.H + matches[5] end
if matches[4] == "torso" then tLimbs.T = tLimbs.T + matches[5] end
if matches[4] == "right" and matches[5] == "leg" then tLimbs.RL = tLimbs.RL + matches[6] end
if matches[4] == "right" and matches[5] == "arm" then tLimbs.RA = tLimbs.RA + matches[6] end
if matches[4] == "left" and matches[5] == "leg" then tLimbs.LL = tLimbs.LL + matches[6] end
if matches[4] == "left" and matches[5] == "arm" then tLimbs.LA = tLimbs.LA + matches[6] end

end


