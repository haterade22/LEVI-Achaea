--[[mudlet
type: script
name: Parrying
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Self Limb Tracking
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

local LIMB_LIST = {"head", "torso", "left arm", "right arm", "left leg", "right leg"}

-- Classes whose kill route depends on prepping/breaking specific limbs
local LIMB_CLASSES = {
	["Infernal"] = true, ["Paladin"] = true, ["Runewarden"] = true, ["Unnamable"] = true,
	["Monk"] = true, ["Tekura"] = true, ["Shikudo"] = true,
	["Blademaster"] = true, ["Sentinel"] = true, ["Druid"] = true,
	["Earthlord"] = true,
}

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

	-- Denizen pattern parry (005): while bashing a mob with a known fixed swing cycle,
	-- parry the PREDICTED next limb -- damage-weighted parry only reacts after damage has
	-- already landed. Basher-gated inside the predictor, so PvP parry is never touched.
	-- Wins over every mode except manual.
	local predicted = ataxia_denizenParryPredict and ataxia_denizenParryPredict()
	if predicted then
		ataxia.parrying.shouldparry = predicted
		return
	end

	-- Auto mode: class-aware + hit-pattern parry
	if mode == "auto" then
		ataxia_autoParry()
		return
	end

	-- Anti-2H: always parry head against Two-Handed knights
	if cfg.anti2H
		and classDetect and classDetect.state
		and classDetect.state.attackerSpec == "2H" then
		ataxia.parrying.shouldparry = "head"
		return
	end

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

-------------------------------------------------------------------
-- AUTO PARRY MODE — class-aware + hit-pattern detection
-------------------------------------------------------------------

-- Detect which limb group the enemy is focusing based on recent hit history
function ataxia_detectLimbFocus()
	local hist = selfLimbDamage.hitHistory
	if not hist or #hist < 2 then return nil end

	local legHits, armHits, headHits = 0, 0, 0
	local n = math.min(#hist, 4)
	for i = #hist - n + 1, #hist do
		local limb = hist[i]
		if limb:find("leg") then legHits = legHits + 1
		elseif limb:find("arm") then armHits = armHits + 1
		elseif limb == "head" then headHits = headHits + 1
		end
	end

	if legHits >= 2 then return "legs" end
	if armHits >= 2 then return "arms" end
	if headHits >= 2 then return "head" end
	return nil
end

-- Auto parry: adapts strategy based on enemy class and attack patterns
function ataxia_autoParry()
	local cfg = selfLimbDamage.config
	local pw = cfg.parryWeights

	-- Anti-2H takes highest priority
	if cfg.anti2H
		and classDetect and classDetect.state
		and classDetect.state.attackerSpec == "2H" then
		ataxia.parrying.shouldparry = "head"
		return
	end

	-- Anti-Shikudo takes priority (same check as standard modes)
	local isShikudo = cfg.antiShikudo
		and classDetect and classDetect.state
		and (classDetect.state.attackerClass == "Shikudo"
			or (classDetect.state.attackerClass == "Monk" and shikudostance and shikudostance ~= ""))

	if isShikudo then
		ataxia_shikudoParry()
		return
	end

	-- Compute base damage weights (no mode bias yet)
	local weights = {}
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

			weights[limb] = w
		end
	end

	-- Determine bias based on enemy class and attack patterns
	local attackerClass = classDetect and classDetect.state and classDetect.state.attackerClass
	local isLimbClass = attackerClass and LIMB_CLASSES[attackerClass]

	-- Auto bias: legs 4, torso 3, head 2 (staying standing > torso breaks > head breaks)
	local autoBias = { leg = 4, torso = 3, head = 2 }

	if isLimbClass then
		-- Limb class: detect focus and bias parry toward threatened group
		local focus = ataxia_detectLimbFocus()
		if focus == "legs" then
			for _, limb in ipairs(LIMB_LIST) do
				if limb:find("leg") and not ataxia_selfLimbBroken(limb) then
					weights[limb] = weights[limb] + autoBias.leg
				end
			end
		elseif focus == "arms" then
			for _, limb in ipairs(LIMB_LIST) do
				if limb:find("arm") and not ataxia_selfLimbBroken(limb) then
					weights[limb] = weights[limb] + autoBias.leg
				end
			end
		elseif focus == "head" then
			if not ataxia_selfLimbBroken("head") then
				weights["head"] = weights["head"] + autoBias.head
			end
		else
			-- No focus detected yet — apply default priority (legs > torso > head)
			for _, limb in ipairs(LIMB_LIST) do
				if not ataxia_selfLimbBroken(limb) then
					if limb:find("leg") then
						weights[limb] = weights[limb] + autoBias.leg
					elseif limb == "torso" then
						weights[limb] = weights[limb] + autoBias.torso
					elseif limb == "head" then
						weights[limb] = weights[limb] + autoBias.head
					end
				end
			end
		end
	else
		-- Affliction class or unknown — apply default priority (legs > torso > head)
		for _, limb in ipairs(LIMB_LIST) do
			if not ataxia_selfLimbBroken(limb) then
				if limb:find("leg") then
					weights[limb] = weights[limb] + autoBias.leg
				elseif limb == "torso" then
					weights[limb] = weights[limb] + autoBias.torso
				elseif limb == "head" then
					weights[limb] = weights[limb] + autoBias.head
				end
			end
		end
	end

	-- Select highest weight, break ties (same logic as standard modes)
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
		ataxia.parrying.shouldparry = ataxia.parrying.limb
	elseif #ties > 1 then
		ataxia.parrying.shouldparry = ties[math.random(#ties)]
	else
		ataxia.parrying.shouldparry = best
	end

	ataxia.parrying.weights = weights
end
