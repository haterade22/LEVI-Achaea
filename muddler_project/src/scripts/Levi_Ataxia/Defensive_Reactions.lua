-------------------------------------------------------------------
-- DEFENSIVE REACTIONS — Listens to threshold events and acts
-- Every feature is gated by selfLimbDamage.config toggles
-------------------------------------------------------------------

local limbToAff = {
	["left arm"] = "damagedleftarm",
	["right arm"] = "damagedrightarm",
	["left leg"] = "damagedleftleg",
	["right leg"] = "damagedrightleg",
	["head"] = "damagedhead",
	["torso"] = "mildtrauma",
}

-- Track what we've already sent (avoid spamming per-prompt)
selfLimbDamage.reactions = selfLimbDamage.reactions or {
	sscPrioSent = {},
	partyCalloutSent = {},
	shieldCooldown = false,
	classDefCooldowns = {},
}

-------------------------------------------------------------------
-- SSC PRIORITY — Tell server-side curing to prioritize a limb
-------------------------------------------------------------------

local function handleSSCPriority(limb, threshold)
	local cfg = selfLimbDamage.config
	if not cfg.sscPriority then return end

	local reactions = selfLimbDamage.reactions

	if threshold == "warning" or threshold == "critical" then
		if not reactions.sscPrioSent[limb] then
			local aff = limbToAff[limb]
			if aff then
				send("curing prioaff " .. aff)
				reactions.sscPrioSent[limb] = true
			end
		end
	elseif threshold == "safe" then
		reactions.sscPrioSent[limb] = nil
	end
end

-------------------------------------------------------------------
-- AUTO-SHIELD — Touch shield when a limb is 1 hit from break
-------------------------------------------------------------------

local function handleAutoShield(limb, threshold)
	local cfg = selfLimbDamage.config
	if not cfg.autoShield then return end
	if threshold ~= "critical" then return end

	local reactions = selfLimbDamage.reactions
	if reactions.shieldCooldown then return end

	-- Don't shield if already shielded or under aeon
	if ataxia and ataxia.afflictions then
		if ataxia.afflictions.shield then return end
		if ataxia.afflictions.aeon then return end
	end

	send("touch shield")
	reactions.shieldCooldown = true
	tempTimer(cfg.shieldCooldown, function()
		selfLimbDamage.reactions.shieldCooldown = false
	end)
end

-------------------------------------------------------------------
-- PARTY CALLOUT — Alert party when a limb is critical
-------------------------------------------------------------------

local function handlePartyCallout(limb, threshold)
	local cfg = selfLimbDamage.config
	if not cfg.partyCallout then return end

	local reactions = selfLimbDamage.reactions

	if threshold == "critical" then
		if not reactions.partyCalloutSent[limb] then
			if partyrelay and (not ataxia or not ataxia.afflictions or not ataxia.afflictions.aeon) then
				send("pt [SLC] My " .. limb .. " is 1 hit from break!")
				reactions.partyCalloutSent[limb] = true
			end
		end
	elseif threshold == "safe" then
		reactions.partyCalloutSent[limb] = nil
	end
end

-------------------------------------------------------------------
-- CLASS-SPECIFIC DEFENSES — Configurable per-class abilities
-------------------------------------------------------------------

local function handleClassDefenses(limb, threshold)
	local cfg = selfLimbDamage.config
	if not cfg.classDefenses then return end

	-- Determine current class
	local currentClass = ataxia and ataxia.settings and ataxia.settings.class
	if not currentClass then return end

	local classDefs = cfg.classDefenses[currentClass:lower()]
	if not classDefs then return end

	local reactions = selfLimbDamage.reactions

	for _, def in ipairs(classDefs) do
		if def.toggle and threshold == (def.threshold or "critical") then
			local cdKey = currentClass .. "_" .. def.ability
			if not reactions.classDefCooldowns[cdKey] then
				-- Check balance gate if provided
				if def.gate and type(def.gate) == "function" and not def.gate() then
					-- Gate function returned false, skip
				else
					send(def.ability)
					reactions.classDefCooldowns[cdKey] = true
					tempTimer(def.cooldown or 10, function()
						selfLimbDamage.reactions.classDefCooldowns[cdKey] = nil
					end)
				end
			end
		end
	end
end

-------------------------------------------------------------------
-- EVENT HANDLER — Central dispatcher for all reactions
-------------------------------------------------------------------

local function onThresholdChange(event, limb, threshold, hitsLeft)
	if not selfLimbDamage.config.enabled then return end

	handleSSCPriority(limb, threshold)
	handleAutoShield(limb, threshold)
	handlePartyCallout(limb, threshold)
	handleClassDefenses(limb, threshold)
end

if selfLimbDamage._handlerThreshold then killAnonymousEventHandler(selfLimbDamage._handlerThreshold) end
selfLimbDamage._handlerThreshold = registerAnonymousEventHandler("self limb threshold", onThresholdChange)
