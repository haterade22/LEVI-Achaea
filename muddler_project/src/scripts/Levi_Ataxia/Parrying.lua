function ataxia_createParry()
	ataxia.parry = ataxia.parry or "stand"
	ataxia.parrying = ataxia.parrying or {
		limb = "none",
		shouldparry = "right leg",
		modes = {
			"stand", "defend", "manual", "randomarm", "randomleg"
		},
	}
	ataxiaEcho("Parrying initialised.")
end

function ataxia_collapseParry()
	ataxia.parrying = nil
end

function ataxia_parryCheck()
	local change = ""
	local method = ataxia.parry

	if method == "manual" then return end

	--Priority lists for switching.
	local prio_order = {"left leg", "right leg","torso","head","left arm", "right arm"}
	local prio_order_hypemode = {"left leg", "right leg","left arm", "right arm", "torso", "head"}

	local ties = {}

	if method == "none" then
		ataxiaEcho("Defaulting to 'stand' parry method, since it wasn't set.")
		ataxia.parry = "stand"
		method = ataxia.parry
	end
	ataxia.parrying.weights = {
		["left arm"] = 0,	["right arm"] = 0,
		["left leg"] = 0,	["right leg"] = 0,
		["head"] = 0,		["torso"] = 0,
	}

	if method == "defend" then
		for i=1, #prio_order do
			local limb = ataxia.parrying.weights[prio_order_hypemode[i]]
			local toLimb = prio_order_hypemode[i]		
			if selfLimbDamage[toLimb]["damage"] > 75 then
				limb = limb + 2
			elseif selfLimbDamage[toLimb]["damage"] > 50 then
				limb = limb + 1.5
			elseif selfLimbDamage[toLimb]["damage"] > 25 then
				limb = limb + 1
			elseif selfLimbDamage[toLimb]["damage"] > 0 then
				limb = limb + 0.5
			end
			
			if ataxia.afflictions["damaged"..prio_order_hypemode[i]:gsub(" ", "")] then
				limb = limb + 1
			elseif ataxia.afflictions["mangled"..prio_order_hypemode[i]:gsub(" ", "")] then
				limb = limb + 0
			else
				limb = limb + 2
			end
			ataxia.parrying.weights[prio_order_hypemode[i]] = limb
		end

	elseif method == "stand" then
		ataxia.parrying.weights["left leg"] = 2
		ataxia.parrying.weights["right leg"] = 2

		for i=1, #prio_order do
			local limb = ataxia.parrying.weights[prio_order_hypemode[i]]
			local toLimb = prio_order_hypemode[i]		
			if selfLimbDamage[toLimb]["damage"] > 75 then
				limb = limb + 3
			elseif selfLimbDamage[toLimb]["damage"] > 50 then
				limb = limb + 2
			elseif selfLimbDamage[toLimb]["damage"] > 25 then
				limb = limb + 1
			elseif selfLimbDamage[toLimb]["damage"] > 0 then
				limb = limb + 0.5
			end
			
	
			if ataxia.afflictions["damaged"..prio_order_hypemode[i]:gsub(" ", "")] then
				limb = limb - 1
			elseif ataxia.afflictions["mangled"..prio_order_hypemode[i]:gsub(" ", "")] then
				limb = limb + 0
			else
				limb = limb + 2
			end
			ataxia.parrying.weights[prio_order_hypemode[i]] = limb
		end
	elseif method == "randomarm" or method == "randomleg" then
	
		local x = math.random(1, 100)
		if ataxiaTemp.parryTimer then return end
		ataxiaTemp.parryTimer = tempTimer(2.5, [[ ataxiaTemp.parryTimer = nil ]])
		local limb = ( x % 2 == 0 and "left " or "right " ) .. ( method == "randomarm" and "arm" or "leg")

		ataxia.parrying.weights[limb] = 10		
	end

	local highest = ""
	local highest_value = 0

	for i=1, #prio_order do
		local limb = ataxia.parrying.weights[prio_order_hypemode[i]]
		if limb > highest_value then
			ties = {prio_order[i]}
			highest = prio_order[i]
			highest_value = limb
		elseif limb == highest_value then
			table.insert(ties, prio_order[i])
		end
	end

	if highest_value > 0 and #ties == 1 then
		ataxia.parrying.shouldparry = highest
	elseif #ties > 1 and highest_value > 0 and not table.contains(ties, ataxia.parrying.limb) then
		ataxia.parrying.shouldparry = ties[math.random(#ties)]
	else
		ataxia.parrying.shouldparry = ataxia.parrying.shouldparry or "head"
	end
  
end