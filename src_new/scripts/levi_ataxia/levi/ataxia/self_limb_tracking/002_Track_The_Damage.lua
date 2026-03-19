--[[mudlet
type: script
name: Track The Damage
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
-- CONFIGURATION — Every feature independently toggleable
-------------------------------------------------------------------

selfLimbDamage = selfLimbDamage or {}

-- Preserve existing config across reloads, merge in defaults for new keys
local defaultConfig = {
	-- Feature toggles
	enabled = true,
	autoParry = true,
	autoShield = false,
	sscPriority = true,
	partyCallout = true,
	warningAlerts = true,
	criticalAlerts = true,
	guiWindow = true,

	-- Tunable thresholds
	torsoBreakThreshold = 100,
	warningHits = 2,
	criticalHits = 1,
	shieldCooldown = 4,
	parrySpamCooldown = 3,

	-- Parry mode
	parryMode = "stand",
	antiShikudo = true,
	anti2H = true,

	-- Parry weight tuning
	parryWeights = {
		critical = 10,
		warning = 7,
		moderate = 4,
		minor = 1,
		broken = -10,
		legBias = 2,
		nonLegBias = 1,
	},

	-- Class-specific defensive abilities
	classDefenses = {},
}

selfLimbDamage.config = selfLimbDamage.config or {}
for k, v in pairs(defaultConfig) do
	if selfLimbDamage.config[k] == nil then
		selfLimbDamage.config[k] = v
	end
end
-- Merge parryWeights sub-keys
if type(defaultConfig.parryWeights) == "table" then
	selfLimbDamage.config.parryWeights = selfLimbDamage.config.parryWeights or {}
	for k, v in pairs(defaultConfig.parryWeights) do
		if selfLimbDamage.config.parryWeights[k] == nil then
			selfLimbDamage.config.parryWeights[k] = v
		end
	end
end

-------------------------------------------------------------------
-- LIMB DATA STRUCTURE
-------------------------------------------------------------------

local LIMB_LIST = {"head", "torso", "left arm", "right arm", "left leg", "right leg"}
local SHORT_NAMES = {
	["head"] = "HEAD ",
	["torso"] = "TORSO",
	["left arm"] = "L.ARM",
	["right arm"] = "R.ARM",
	["left leg"] = "L.LEG",
	["right leg"] = "R.LEG",
}

-- Initialize limb data
for _, limb in ipairs(LIMB_LIST) do
	selfLimbDamage[limb] = selfLimbDamage[limb] or {}
	selfLimbDamage[limb].damage = selfLimbDamage[limb].damage or 0
	selfLimbDamage[limb].lastHit = selfLimbDamage[limb].lastHit or 0
	selfLimbDamage[limb].hitCount = selfLimbDamage[limb].hitCount or 0
	selfLimbDamage[limb].threshold = selfLimbDamage[limb].threshold or "safe"
end

selfLimbDamage.timers = selfLimbDamage.timers or {}
selfLimbDamage.lasthit = selfLimbDamage.lasthit or "none"
selfLimbDamage.hitHistory = selfLimbDamage.hitHistory or {}

-------------------------------------------------------------------
-- CORE FUNCTIONS
-------------------------------------------------------------------

-- Check if a limb is "prepped" (one hit away from breaking)
function ataxia_selfLimbPrepped(limb)
	limb = limb:lower()
	if not selfLimbDamage[limb] then return false end

	local data = selfLimbDamage[limb]
	local lastHit = data.lastHit or 0
	if lastHit == 0 then lastHit = 12.5 end

	return (data.damage + lastHit >= 100)
end

-- Calculate how many hits remaining to break the limb
function ataxia_selfHitsToBreak(limb)
	limb = limb:lower()
	if not selfLimbDamage[limb] then return 99 end

	local data = selfLimbDamage[limb]
	local remaining = 100 - data.damage
	local lastHit = data.lastHit or 0
	if lastHit == 0 then lastHit = 12.5 end

	if remaining <= 0 then return 0 end

	return math.ceil(remaining / lastHit)
end

-- Estimate how many restorations needed to heal (damage > 100 = multiple applications)
function ataxia_selfRestorationsNeeded(limb)
	limb = limb:lower()
	if not selfLimbDamage[limb] then return 0 end
	local dmg = selfLimbDamage[limb].damage
	if dmg <= 0 then return 0 end
	return math.ceil(dmg / 100)
end

-- Compute threshold state from hits-to-break
local function computeThreshold(hitsLeft)
	local cfg = selfLimbDamage.config
	if hitsLeft <= cfg.criticalHits then
		return "critical"
	elseif hitsLeft <= cfg.warningHits then
		return "warning"
	else
		return "safe"
	end
end

-- Check if a limb is broken via afflictions
function ataxia_selfLimbBroken(limb)
	if not ataxia or not ataxia.afflictions then return false end
	local key = limb:gsub(" ", "")
	return ataxia.afflictions["damaged"..key]
		or ataxia.afflictions["mangled"..key]
		or (limb == "torso" and (ataxia.afflictions.mildtrauma or ataxia.afflictions.serioustrauma))
end

-- Get a summary of limb status
function ataxia_selfLimbStatus(limb)
	limb = limb:lower()
	if not selfLimbDamage[limb] then return nil end

	local data = selfLimbDamage[limb]
	local hitsLeft = ataxia_selfHitsToBreak(limb)
	local broken = ataxia_selfLimbBroken(limb)
	return {
		damage = data.damage,
		lastHit = data.lastHit,
		hitCount = data.hitCount,
		hitsToBreak = hitsLeft,
		prepped = ataxia_selfLimbPrepped(limb),
		threshold = broken and "broken" or data.threshold,
		broken = broken,
	}
end

-------------------------------------------------------------------
-- DAMAGE TRACKING
-------------------------------------------------------------------

function ataxia_raiseLimbDamage(limb, num)
	if not selfLimbDamage.config.enabled then return end

	-- Clear target defenses when we take a hit (existing behavior)
	if type(target) == "number" then
		tAffs.shield = false
		tAffs.rebounding = false
		tAffs.paralysis = false
		tAffs.prone = false
	end

	selfLimbDamage.lasthit = limb

	-- Track hit history for auto-parry focus detection (rolling window of 6)
	local hist = selfLimbDamage.hitHistory
	hist[#hist + 1] = limb
	if #hist > 6 then table.remove(hist, 1) end

	-- Update damage data
	selfLimbDamage[limb].lastHit = num
	selfLimbDamage[limb].hitCount = (selfLimbDamage[limb].hitCount or 0) + 1
	local oldDmg = selfLimbDamage[limb].damage
	selfLimbDamage[limb].damage = selfLimbDamage[limb].damage + num

	-- Per-hit cap: single hit can't push past 100%, subsequent hits stack to 200%
	if oldDmg < 100 and selfLimbDamage[limb].damage > 100 then
		selfLimbDamage[limb].damage = 100
	elseif selfLimbDamage[limb].damage > 200 then
		selfLimbDamage[limb].damage = 200
	end

	-- Reset timer (180s auto-decay)
	selfLimbDamage.timers[limb] = selfLimbDamage.timers[limb] or {}
	if selfLimbDamage.timers[limb].timer then
		killTimer(selfLimbDamage.timers[limb].timer)
	end
	selfLimbDamage.timers[limb].timer = tempTimer(180, function()
		ataxia_resetLimbDamage(limb)
	end)

	-- Compute threshold transition
	local hitsLeft = ataxia_selfHitsToBreak(limb)
	local oldThreshold = selfLimbDamage[limb].threshold
	local newThreshold = computeThreshold(hitsLeft)

	-- Torso break detection
	if limb == "torso" and selfLimbDamage[limb].damage >= selfLimbDamage.config.torsoBreakThreshold then
		newThreshold = "broken"
		ataxia_boxEcho("TORSO IS BROKEN!", "black:red")
		send("curing predict mildtrauma")
	end

	-- Threshold transition alerts + events
	if newThreshold ~= oldThreshold then
		selfLimbDamage[limb].threshold = newThreshold
		raiseEvent("self limb threshold", limb, newThreshold, hitsLeft)

		if newThreshold == "warning" and selfLimbDamage.config.warningAlerts then
			ataxia_boxEcho(limb:upper().." is 2 HITS from break!", "black:yellow")
		elseif newThreshold == "critical" and selfLimbDamage.config.criticalAlerts then
			ataxia_boxEcho(limb:upper().." is PREPPED! (1 hit)", "black:orange")
		end
	end

	-- Raise the general damage event
	raiseEvent("self limb damaged", limb, num, selfLimbDamage[limb].damage)
end

-- Parse the "dealt X% damage to your [limb]" line
function ataxia_parseLimbDamageLine(line)
	local damage, limb = line:match("dealt (%d+%.?%d*)%% damage to your (.+)%.")
	if damage and limb then
		local dmg = tonumber(damage)
		limb = limb:lower()
		if selfLimbDamage[limb] then
			ataxia_raiseLimbDamage(limb, dmg)
			return true
		end
	end
	return false
end

-------------------------------------------------------------------
-- RESET / CLEAR
-------------------------------------------------------------------

function ataxia_clearLimbDamage(limb)
	selfLimbDamage[limb].damage = 0
	selfLimbDamage[limb].lastHit = 0
	selfLimbDamage[limb].hitCount = 0
	selfLimbDamage[limb].threshold = "safe"
	if selfLimbDamage.timers[limb] and selfLimbDamage.timers[limb].timer then
		killTimer(selfLimbDamage.timers[limb].timer)
	end
	selfLimbDamage.timers[limb] = nil
	-- Update GUI
	if selfLimbDamage.gui and selfLimbDamage.gui.console then
		ataxia_updateSelfLimbWindow()
	end
	-- Reset threshold event so defensive reactions can clear their flags
	raiseEvent("self limb threshold", limb, "safe", 99)
end

function ataxia_resetLimbDamage(limb)
	ataxia_clearLimbDamage(limb)
	ataxiaEcho("Our <green>"..limb.."<NavajoWhite> has been reset.")
end

function ataxia_clearAllLimbDamage()
	for _, limb in ipairs(LIMB_LIST) do
		ataxia_clearLimbDamage(limb)
	end
	selfLimbDamage.hitHistory = {}
	cecho("\n<DodgerBlue> -= All self limb damage cleared =-")
end

-------------------------------------------------------------------
-- BROKEN LIMB DETECTION (aff events)
-------------------------------------------------------------------

function ataxia_brokenLimbFound(event, affliction)
	if event == "aff gained" then
		if affliction == "damagedleftarm" or affliction == "mangledleftarm" then
			ataxia_clearLimbDamage("left arm")
			ataxia_boxEcho("LEFT ARM HAS BEEN BROKEN", "black:yellow")
		elseif affliction == "damagedrightarm" or affliction == "mangledrightarm" then
			ataxia_clearLimbDamage("right arm")
			ataxia_boxEcho("RIGHT ARM HAS BEEN BROKEN", "black:yellow")
		elseif affliction == "damagedleftleg" or affliction == "mangledleftleg" then
			ataxia_clearLimbDamage("left leg")
			ataxia_boxEcho("LEFT LEG HAS BEEN BROKEN", "black:DarkOrange")
			if not affed("damagedleftarm") and not affed("damagedrightarm") and ataxiaTemp.salvelockWait then
				killTimer(ataxiaTemp.salvelockWait)
				ataxiaTemp.salvelockWait = nil
				send("queue addclear free restore", false)
			end
		elseif affliction == "damagedrightleg" or affliction == "mangledrightleg" then
			ataxia_clearLimbDamage("right leg")
			ataxia_boxEcho("RIGHT LEG HAS BEEN BROKEN", "black:DarkOrange")
			if not affed("damagedleftarm") and not affed("damagedrightarm") and ataxiaTemp.salvelockWait then
				killTimer(ataxiaTemp.salvelockWait)
				ataxiaTemp.salvelockWait = nil
				send("queue addclear eqbal restore", false)
			end
		elseif affliction == "damagedhead" or affliction == "mangledhead" then
			ataxia_clearLimbDamage("head")
			ataxia_boxEcho("HEAD HAS BEEN BROKEN", "black:goldenrod")
		elseif affliction == "mildtrauma" or affliction == "serioustrauma" then
			ataxia_clearLimbDamage("torso")
			ataxia_boxEcho("TORSO HAS BEEN BROKEN", "black:red")
		end
	elseif event == "aff cured" then
		if affliction == "mildtrauma" or affliction == "serioustrauma" then
			ataxia_clearLimbDamage("torso")
		end
	end
end

-- Clean up old handlers on reload, then register fresh
if selfLimbDamage._handlerAffGained then killAnonymousEventHandler(selfLimbDamage._handlerAffGained) end
if selfLimbDamage._handlerAffCured then killAnonymousEventHandler(selfLimbDamage._handlerAffCured) end
selfLimbDamage._handlerAffGained = registerAnonymousEventHandler("aff gained", "ataxia_brokenLimbFound")
selfLimbDamage._handlerAffCured = registerAnonymousEventHandler("aff cured", "ataxia_brokenLimbFound")

-------------------------------------------------------------------
-- DISPLAY STATUS (text)
-------------------------------------------------------------------

function ataxia_showSelfLimbStatus()
	cecho("\n<DodgerBlue> -= Self Limb Damage Status =-")
	for _, limb in ipairs(LIMB_LIST) do
		local status = ataxia_selfLimbStatus(limb)
		if status then
			local color
			if status.broken then color = "dark_red"
			elseif status.threshold == "critical" then color = "red"
			elseif status.threshold == "warning" then color = "yellow"
			elseif status.damage > 0 then color = "green"
			else color = "gray"
			end

			local stateStr = ""
			if status.broken then
				stateStr = " <dark_red>[BROKEN]"
			elseif status.threshold == "critical" then
				stateStr = " <red>[PREPPED]"
			elseif status.threshold == "warning" then
				stateStr = " <yellow>[WARNING]"
			end

			cecho(string.format("\n  <%s>%s<white>: %.1f%% | Last: %.1f%% | Hits: %d | To Break: %d%s",
				color, limb:upper(), status.damage, status.lastHit, status.hitCount, status.hitsToBreak, stateStr))
		end
	end

	-- Show config toggles
	local cfg = selfLimbDamage.config
	cecho("\n<DodgerBlue> -= SLC Config =-")
	cecho(string.format("\n  <white>Parry: <%s>%s<white> | Shield: <%s>%s<white> | SSC: <%s>%s<white> | Party: <%s>%s",
		cfg.autoParry and "green" or "red", cfg.autoParry and "ON" or "OFF",
		cfg.autoShield and "green" or "red", cfg.autoShield and "ON" or "OFF",
		cfg.sscPriority and "green" or "red", cfg.sscPriority and "ON" or "OFF",
		cfg.partyCallout and "green" or "red", cfg.partyCallout and "ON" or "OFF"))
	cecho(string.format("\n  <white>Parry Mode: <cyan>%s<white> | Warnings: <%s>%s<white> | Critical: <%s>%s",
		cfg.parryMode,
		cfg.warningAlerts and "green" or "red", cfg.warningAlerts and "ON" or "OFF",
		cfg.criticalAlerts and "green" or "red", cfg.criticalAlerts and "ON" or "OFF"))
	cecho(string.format("\n  <white>Anti-Shikudo: <%s>%s<white> | Anti-2H: <%s>%s<white> | GUI: <%s>%s",
		cfg.antiShikudo and "green" or "red", cfg.antiShikudo and "ON" or "OFF",
		cfg.anti2H and "green" or "red", cfg.anti2H and "ON" or "OFF",
		cfg.guiWindow and "green" or "red", cfg.guiWindow and "ON" or "OFF"))
end

-------------------------------------------------------------------
-- TRIGGER REGISTRATION
-------------------------------------------------------------------

function ataxia_registerLimbDamageTrigger()
	if selfLimbDamage.triggerId then
		killTrigger(selfLimbDamage.triggerId)
	end

	selfLimbDamage.triggerId = tempRegexTrigger(
		[[dealt (\d+\.?\d*)% damage to your (head|torso|left arm|right arm|left leg|right leg)]],
		function()
			local damage = tonumber(matches[2])
			local limb = matches[3]:lower()
			if damage and limb and selfLimbDamage[limb] then
				ataxia_raiseLimbDamage(limb, damage)
			end
		end
	)
end

-- Auto-register on load
ataxia_registerLimbDamageTrigger()

-------------------------------------------------------------------
-- GEYSER GUI WINDOW
-------------------------------------------------------------------

selfLimbDamage.gui = selfLimbDamage.gui or {}
selfLimbDamage.gui.fontSize = 9

function ataxia_buildSelfLimbWindow()
	if selfLimbDamage.gui.window then
		selfLimbDamage.gui.window:hide()
		selfLimbDamage.gui.window = nil
	end

	local savedPos = selfLimbDamage.gui.savedPosition or {x = 100, y = 100, width = 300, height = 216}

	selfLimbDamage.gui.window = Adjustable.Container:new({
		name = "selfLimbDamageWindow",
		x = savedPos.x,
		y = savedPos.y,
		width = savedPos.width,
		height = savedPos.height,
		adjLabelstyle = zgui and zgui.adjLabelstyle or [[
			background-color: rgba(30,30,30,100%);
			border: 1px solid rgb(60,60,60);
		]],
		buttonstyle = [[
			QLabel{ border-radius: 3px; background-color: rgba(100,100,100,80%);}
			QLabel::hover{ background-color: rgba(140,140,140,80%);}
		]],
		buttonFontSize = 8,
		buttonsize = 12,
		titleText = "Self Limb Damage",
		titleTxtColor = "white",
	})
	selfLimbDamage.gui.window:changeMenuStyle("dark")

	selfLimbDamage.gui.container = Geyser.Container:new({
		name = "selfLimbDamageContainer",
		x = 0, y = 0,
		width = "100%",
		height = "100%",
	}, selfLimbDamage.gui.window)

	selfLimbDamage.gui.console = Geyser.MiniConsole:new({
		name = "selfLimbDamageConsole",
		x = 2, y = 2,
		width = "100%-4",
		height = "100%-4",
		color = "black",
		autoWrap = true,
	}, selfLimbDamage.gui.container)

	setFontSize("selfLimbDamageConsole", selfLimbDamage.gui.fontSize)
	selfLimbDamage.gui.window:attachToBorder("top")
	selfLimbDamage.gui.window:show()
	ataxia_updateSelfLimbWindow()
end

function ataxia_updateSelfLimbWindow()
	if not selfLimbDamage.gui.console then return end

	clearWindow("selfLimbDamageConsole")

	-- Determine current parry target for [P] marker
	local parryTarget = ataxia and ataxia.parrying and ataxia.parrying.shouldparry or nil

	for _, limb in ipairs(LIMB_LIST) do
		local status = ataxia_selfLimbStatus(limb)
		if status then
			local color
			if status.damage > 100 then
				color = "firebrick"
			elseif status.broken then
				color = "dark_red"
			elseif status.threshold == "critical" then
				color = "red"
			elseif status.threshold == "warning" then
				color = "orange"
			elseif status.damage > 0 then
				color = "green"
			else
				color = "gray"
			end

			-- Status indicator
			local indicator = ""
			if status.damage > 100 then
				local restores = math.ceil(status.damage / 100)
				indicator = string.format(" <firebrick>[%dx REST]", restores)
			elseif status.broken then
				indicator = " <dark_red>BROKEN"
			elseif status.threshold == "critical" then
				indicator = " <red>[!!]"
			elseif status.threshold == "warning" then
				indicator = " <orange>[!]"
			end

			-- Parry marker
			local parryMark = (parryTarget == limb) and " <cyan>[P]" or ""

			-- Hits display
			local hitsStr
			if status.broken then
				hitsStr = "  ---"
			elseif status.damage == 0 then
				hitsStr = " safe"
			elseif status.hitsToBreak == 1 then
				hitsStr = "1 hit"
			else
				hitsStr = string.format("%d hts", status.hitsToBreak)
			end

			cecho("selfLimbDamageConsole",
				string.format("<%s>%s<white>: %5.1f%% <dim_gray>%s%s%s\n",
					color, SHORT_NAMES[limb], status.damage, hitsStr, indicator, parryMark))
		end
	end
end

function ataxia_saveSelfLimbWindowPosition()
	if selfLimbDamage.gui.window then
		selfLimbDamage.gui.savedPosition = {
			x = selfLimbDamage.gui.window.x,
			y = selfLimbDamage.gui.window.y,
			width = selfLimbDamage.gui.window.width,
			height = selfLimbDamage.gui.window.height,
		}
		selfLimbDamage.gui.window:savePosition()
	end
end

function ataxia_toggleSelfLimbWindow()
	if not selfLimbDamage.gui.window then
		ataxia_buildSelfLimbWindow()
	elseif selfLimbDamage.gui.window:isVisible() then
		selfLimbDamage.gui.window:hide()
	else
		selfLimbDamage.gui.window:show()
		ataxia_updateSelfLimbWindow()
	end
end

function ataxia_lockSelfLimbWindow(lock)
	if not selfLimbDamage.gui.window then return end
	if lock then
		selfLimbDamage.gui.window:lockContainer()
	else
		selfLimbDamage.gui.window:unlockContainer()
	end
end

function ataxia_setSelfLimbWindowFontSize(size)
	selfLimbDamage.gui.fontSize = size or 9
	if selfLimbDamage.gui.console then
		setFontSize("selfLimbDamageConsole", selfLimbDamage.gui.fontSize)
		ataxia_updateSelfLimbWindow()
	end
end

function ataxia_closeSelfLimbWindow()
	if selfLimbDamage.gui.window then
		selfLimbDamage.gui.window:hide()
	end
end

-- Auto-update GUI on damage events (debounced, with reload cleanup)
if selfLimbDamage._handlerGuiUpdate then killAnonymousEventHandler(selfLimbDamage._handlerGuiUpdate) end
selfLimbDamage._guiDirty = false
selfLimbDamage._handlerGuiUpdate = registerAnonymousEventHandler("self limb damaged", function()
	if not selfLimbDamage._guiDirty then
		selfLimbDamage._guiDirty = true
		tempTimer(0, function()
			selfLimbDamage._guiDirty = false
			ataxia_updateSelfLimbWindow()
		end)
	end
end)
