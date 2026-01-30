if isTargeted(matches[2]) then
	local rem = {"prone", "paralysis", "brokenleftleg", "damagedleftleg", "brokenrightleg", "damagedrightleg"}
	if tLimbs.LL >= 100 then tLimbs.LL = 0 end
	if tLimbs.RL >= 100 then tLimbs.RL = 0 end
  if lb[target].hits["left leg"] >= 100 then lb[target].hits["left leg"] = 0 end
  if lb[target].hits["right leg"] >= 100 then lb[target].hits["right leg"] = 0 end
	for _, aff in pairs(rem) do
		erAff(aff)
	end
end