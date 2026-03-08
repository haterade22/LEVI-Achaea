local LIMB_LIST = {"head", "torso", "left arm", "right arm", "left leg", "right leg"}

function ataxia_createParry()
	ataxia.parry = ataxia.parry or (selfLimbDamage.config and selfLimbDamage.config.parryMode or "stand")
	ataxia.parrying = ataxia.parrying or {
		limb = "none",
		shouldparry = "right leg",
	}
end

function ataxia_collapseParry()
	ataxia.parrying = nil
end

function ataxia_parryCheck()
	local cfg = selfLimbDamage.config
	if not cfg or not cfg.enabled or not cfg.autoParry then return end

	local mode = cfg.parryMode
	if mode == "manual" then return end

	-- Anti-Shikudo: override mode when fighting a Shikudo monk
	local isShikudo = cfg.antiShikudo
		and classDetect and classDetect.state
		and (classDetect.state.attackerClass == "Shikudo"
			or (classDetect.state.attackerClass == "Monk" and shikudostance and shikudostance ~= ""))

	if isShikudo then
		ataxia_shikudoParry()
		return
	end

	local pw = cfg.parryWeights
	local weights = {}

	if mode == "randomarm" or mode == "randomleg" then
		-- Random mode: pick a random side, heavily weight it
		if not ataxiaTemp then ataxiaTemp = {} end
		if ataxiaTemp.parryTimer then return end
		ataxiaTemp.parryTimer = tempTimer(2.5, function() ataxiaTemp.parryTimer = nil end)

		local x = math.random(1, 100)
		local side = (x % 2 == 0) and "left " or "right "
		local limbType = (mode == "randomarm") and "arm" or "leg"
		local chosen = side .. limbType

		for _, limb in ipairs(LIMB_LIST) do
			weights[limb] = (limb == chosen) and 10 or 0
		end
	else
		-- Standard weighted mode (stand / defend)
		for _, limb in ipairs(LIMB_LIST) do
			local w = 0
			local data = selfLimbDamage[limb]
			if not data then
				weights[limb] = 0
			else
				local hitsLeft = ataxia_selfHitsToBreak(limb)
				local isBroken = ataxia_selfLimbBroken(limb)

				if isBroken then
					w = pw.broken
				elseif hitsLeft <= cfg.criticalHits then
					w = pw.critical
				elseif hitsLeft <= cfg.warningHits then
					w = pw.warning
				elseif hitsLeft <= 3 then
					w = pw.moderate
				elseif data.damage > 0 then
					w = pw.minor
				end

				-- Mode modifiers
				if mode == "stand" then
					if limb:find("leg") and not isBroken then
						w = w + pw.legBias
					end
				elseif mode == "defend" then
					if not limb:find("leg") and not isBroken then
						w = w + pw.nonLegBias
					end
				end

				weights[limb] = w
			end
		end
	end

	-- Select highest weight, break ties
	local best, bestWeight, ties = nil, -math.huge, {}
	for _, limb in ipairs(LIMB_LIST) do
		local w = weights[limb] or 0
		if w > bestWeight then
			best = limb
			bestWeight = w
			ties = {limb}
		elseif w == bestWeight then
			ties[#ties + 1] = limb
		end
	end

	if #ties > 1 and ataxia.parrying and table.contains(ties, ataxia.parrying.limb) then
		-- Keep current parry if it's among the ties (don't spam switches)
		ataxia.parrying.shouldparry = ataxia.parrying.limb
	elseif #ties > 1 then
		ataxia.parrying.shouldparry = ties[math.random(#ties)]
	else
		ataxia.parrying.shouldparry = best
	end

	ataxia.parrying.weights = weights
end

-- Anti-Shikudo dynamic parry intelligence
-- Shikudo monks can only target specific limbs depending on their stance/form.
-- We exploit this knowledge to parry optimally per stance.
function ataxia_shikudoParry()
	local form = shikudostance
	local hyperLimb = ataxiaTemp and ataxiaTemp.hyperLimb or nil

	if form == "willow" then
		-- Willow targets legs only. Parry the highest-damage leg.
		-- When that leg is 2 hits from break, switch to the LOWEST leg
		-- (if they hit our parry they'll switch limbs, so we can catch up).
		local ll = selfLimbDamage["left leg"]
		local rl = selfLimbDamage["right leg"]
		local llDmg = ll and ll.damage or 0
		local rlDmg = rl and rl.damage or 0
		local llHits = ataxia_selfHitsToBreak("left leg")
		local rlHits = ataxia_selfHitsToBreak("right leg")

		local highLeg = (llDmg >= rlDmg) and "left leg" or "right leg"
		local lowLeg = (llDmg >= rlDmg) and "right leg" or "left leg"
		local highHits = (highLeg == "left leg") and llHits or rlHits

		if highHits <= (selfLimbDamage.config.warningHits or 2) then
			-- High leg is near break — switch to low leg to force them to swap
			ataxia.parrying.shouldparry = lowLeg
		else
			-- Parry the highest damage leg
			ataxia.parrying.shouldparry = highLeg
		end

	elseif form == "rain" then
		-- Rain targets arms. Parry highest-damage arm to prevent dismount/knockdown.
		-- Same threshold logic as willow but for arms.
		local la = selfLimbDamage["left arm"]
		local ra = selfLimbDamage["right arm"]
		local laDmg = la and la.damage or 0
		local raDmg = ra and ra.damage or 0
		local laHits = ataxia_selfHitsToBreak("left arm")
		local raHits = ataxia_selfHitsToBreak("right arm")

		local highArm = (laDmg >= raDmg) and "left arm" or "right arm"
		local lowArm = (laDmg >= raDmg) and "right arm" or "left arm"
		local highHits = (highArm == "left arm") and laHits or raHits

		if highHits <= (selfLimbDamage.config.warningHits or 2) then
			ataxia.parrying.shouldparry = lowArm
		else
			ataxia.parrying.shouldparry = highArm
		end

	elseif form == "oak" or form == "gaital" then
		-- Oak/Gaital target head. Parry head by default.
		-- If they hyperfocus head (hit through our parry), they bypass parry entirely
		-- on that limb — switch to legs instead (secondary threat).
		if hyperLimb == "head" then
			-- They're hyperfocusing head — parrying head is useless, protect legs
			local llHits = ataxia_selfHitsToBreak("left leg")
			local rlHits = ataxia_selfHitsToBreak("right leg")
			local llDmg = (selfLimbDamage["left leg"] and selfLimbDamage["left leg"].damage or 0)
			local rlDmg = (selfLimbDamage["right leg"] and selfLimbDamage["right leg"].damage or 0)
			ataxia.parrying.shouldparry = (llDmg >= rlDmg) and "left leg" or "right leg"
		else
			ataxia.parrying.shouldparry = "head"
		end

	else
		-- Tykonos, Maelstrom, or unknown form — fall back to standard weighted parry
		-- Temporarily disable antiShikudo to avoid recursion, run standard logic
		local cfg = selfLimbDamage.config
		cfg.antiShikudo = false
		local ok, err = pcall(ataxia_parryCheck)
		cfg.antiShikudo = true
		if not ok then
			cecho("\n<red>[SLC] Parry fallback error: " .. tostring(err))
		end
		return
	end
end
