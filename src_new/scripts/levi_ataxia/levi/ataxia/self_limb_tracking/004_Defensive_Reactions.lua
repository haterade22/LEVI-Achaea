--[[mudlet
type: script
name: Defensive Reactions
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
-- BOTH ARMS BROKEN FLEE — Run when both arms are broken
-- Strategy: flee 3+ rooms + fly to prevent the monk breaking legs.
-- Parry the less-damaged leg while fleeing and healing.
-------------------------------------------------------------------

-- Choose which leg to parry: the one with less current damage
local function selectFleeParryLeg()
	local ll = selfLimbDamage["left leg"] and selfLimbDamage["left leg"].damage or 0
	local rl = selfLimbDamage["right leg"] and selfLimbDamage["right leg"].damage or 0
	return (ll <= rl) and "left leg" or "right leg"
end

-- Check movement-blocking afflictions
local function canMove()
	if not ataxia or not ataxia.afflictions then return true end
	local a = ataxia.afflictions
	return not (a.paralysis or a.entangled or a.webbed or a.impaled
				or a.transfixation or a.stun or a.constricted or a.snared)
end

-- Send a burst of movement: tumble first (evasion), then raw dir, then fly
local function doFleeBurst()
	if not selfLimbDamage.bothArmsFlee then return end
	if not canMove() then
		cecho("\n<red>[SLC FLEE]<reset> Both arms broken but can't move (afflicted). Waiting...")
		return
	end
	local dir = selfLimbDamage.config.fleeDir
	local rooms = selfLimbDamage.config.fleeRooms
	local delay = selfLimbDamage.config.fleeBurstDelay
	-- First move: tumble (has evasion component)
	tempTimer(0, function()
		if selfLimbDamage.bothArmsFlee then send("tumble " .. dir) end
	end)
	-- Subsequent moves
	for i = 2, rooms do
		tempTimer(i * delay, function()
			if selfLimbDamage.bothArmsFlee then send(dir) end
		end)
	end
	-- Fly after running
	tempTimer((rooms + 1) * delay, function()
		if selfLimbDamage.bothArmsFlee then
			send("fly")
			cecho("\n<yellow>[SLC FLEE]<reset> Flying - waiting for arms to heal...")
		end
	end)
end

-- Repeating check: if arms still broken after interval, flee again (monk caught up)
local function onFleeRepeat()
	if not selfLimbDamage.bothArmsFlee then return end
	-- Arms healed? Stop.
	if not ataxia_selfLimbBroken("left arm") or not ataxia_selfLimbBroken("right arm") then
		selfLimbDamage.bothArmsFlee = false
		if selfLimbDamage._fleeTimerID then
			killTimer(selfLimbDamage._fleeTimerID)
			selfLimbDamage._fleeTimerID = nil
		end
		cecho("\n<green>[SLC FLEE]<reset> Arms healed - resuming combat!")
		return
	end
	-- Still broken: run again (monk may have followed)
	doFleeBurst()
	selfLimbDamage._fleeTimerID = tempTimer(selfLimbDamage.config.fleeRepeatInterval, onFleeRepeat)
end

local function handleBothArmsBrokenFlee(limb, threshold)
	local cfg = selfLimbDamage.config
	if not cfg.bothArmsFlee then return end
	-- Never inside the Mnemosyne: this flees a FIXED direction (blind runs into unexplored
	-- tower rooms) and fights the explorer/swarm machinery. The swarm module's low-HP
	-- escape (mnemosyne/009) owns tower escapes -- fly/retreat with validated routes.
	if ataxiaBasher and ataxiaBasher.inMnemosyne then return end
	-- Only react when an arm reaches broken
	if limb ~= "left arm" and limb ~= "right arm" then return end
	if threshold ~= "broken" then return end
	-- Check: are BOTH arms now broken?
	if not ataxia_selfLimbBroken("left arm") or not ataxia_selfLimbBroken("right arm") then return end
	-- Already fleeing?
	if selfLimbDamage.bothArmsFlee then return end

	-- Both arms broken: start flee
	selfLimbDamage.bothArmsFlee = true
	cecho("\n<red>[SLC FLEE]<reset> Both arms broken - <yellow>RUNNING!</reset>")

	-- Parry the less-damaged leg to protect it
	if ataxia and ataxia.parrying then
		local legToParry = selectFleeParryLeg()
		ataxia.parrying.shouldparry = legToParry
		cecho("\n<cyan>[SLC FLEE]<reset> Parrying " .. legToParry .. " while fleeing.")
	end

	-- Start flee burst
	doFleeBurst()

	-- Set up repeating re-flee timer (handles monk following)
	if selfLimbDamage._fleeTimerID then killTimer(selfLimbDamage._fleeTimerID) end
	selfLimbDamage._fleeTimerID = tempTimer(cfg.fleeRepeatInterval, onFleeRepeat)
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
	handleBothArmsBrokenFlee(limb, threshold)
end

if selfLimbDamage._handlerThreshold then killAnonymousEventHandler(selfLimbDamage._handlerThreshold) end
selfLimbDamage._handlerThreshold = registerAnonymousEventHandler("self limb threshold", onThresholdChange)
