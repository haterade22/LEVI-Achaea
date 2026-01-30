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

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Self Limb Tracking > Track The Damage

-- Initialize enhanced selfLimbDamage structure if not already present
selfLimbDamage = selfLimbDamage or {
	["head"] = {damage = 0, lastHit = 0, hitCount = 0},
	["torso"] = {damage = 0, lastHit = 0, hitCount = 0},
	["left arm"] = {damage = 0, lastHit = 0, hitCount = 0},
	["right arm"] = {damage = 0, lastHit = 0, hitCount = 0},
	["left leg"] = {damage = 0, lastHit = 0, hitCount = 0},
	["right leg"] = {damage = 0, lastHit = 0, hitCount = 0},
	timers = {},
	lasthit = "none",
}

-- Ensure existing limb entries have the new fields
for _, limb in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do
	selfLimbDamage[limb] = selfLimbDamage[limb] or {}
	selfLimbDamage[limb].damage = selfLimbDamage[limb].damage or 0
	selfLimbDamage[limb].lastHit = selfLimbDamage[limb].lastHit or 0
	selfLimbDamage[limb].hitCount = selfLimbDamage[limb].hitCount or 0
end

-- Parse the "dealt X% damage to your [limb]" line and track damage
-- Pattern: "dealt 12.6% damage to your right arm"
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

-- Check if a limb is "prepped" (one hit away from breaking)
-- Returns true if the next hit of the same damage would break the limb
function ataxia_selfLimbPrepped(limb)
	limb = limb:lower()
	if not selfLimbDamage[limb] then return false end

	local data = selfLimbDamage[limb]
	local lastHit = data.lastHit or 0

	-- If we don't have hit data yet, use a reasonable default (12.5%)
	if lastHit == 0 then lastHit = 12.5 end

	return (data.damage + lastHit >= 100)
end

-- Calculate how many hits remaining to break the limb at 100%
-- Returns number of hits based on last hit damage
function ataxia_selfHitsToBreak(limb)
	limb = limb:lower()
	if not selfLimbDamage[limb] then return 0 end

	local data = selfLimbDamage[limb]
	local remaining = 100 - data.damage
	local lastHit = data.lastHit or 0

	-- If we don't have hit data yet, use a reasonable default (12.5%)
	if lastHit == 0 then lastHit = 12.5 end

	if remaining <= 0 then return 0 end

	return math.ceil(remaining / lastHit)
end

-- Get a summary of limb status
function ataxia_selfLimbStatus(limb)
	limb = limb:lower()
	if not selfLimbDamage[limb] then return nil end

	local data = selfLimbDamage[limb]
	return {
		damage = data.damage,
		lastHit = data.lastHit,
		hitCount = data.hitCount,
		hitsToBreak = ataxia_selfHitsToBreak(limb),
		prepped = ataxia_selfLimbPrepped(limb)
	}
end

-- Display limb status for all limbs
function ataxia_showSelfLimbStatus()
	local limbs = {"head", "torso", "left arm", "right arm", "left leg", "right leg"}
	cecho("\n<DodgerBlue> -= Self Limb Damage Status =-")
	for _, limb in ipairs(limbs) do
		local status = ataxia_selfLimbStatus(limb)
		if status then
			local preppedStr = status.prepped and " <red>[PREPPED]" or ""
			local color = status.damage >= 75 and "red" or (status.damage >= 50 and "yellow" or (status.damage > 0 and "green" or "gray"))
			cecho(string.format("\n  <%s>%s<white>: %.1f%% | Last Hit: %.1f%% | Hits: %d | To Break: %d%s",
				color, limb:upper(), status.damage, status.lastHit, status.hitCount, status.hitsToBreak, preppedStr))
		end
	end
end

function ataxia_raiseLimbDamage(limb, num)
	if type(target) == "number" then
		tAffs.shield = false
		tAffs.rebounding = false
		tAffs.paralysis = false
		tAffs.prone = false
	end

	selfLimbDamage.lasthit = limb

	-- Track the last hit damage and increment hit count
	selfLimbDamage[limb].lastHit = num
	selfLimbDamage[limb].hitCount = (selfLimbDamage[limb].hitCount or 0) + 1

	selfLimbDamage[limb]["damage"] = selfLimbDamage[limb]["damage"] + num
	if selfLimbDamage[limb]["damage"] > 95 then selfLimbDamage[limb]["damage"] = 100 end
	selfLimbDamage.timers[limb] = selfLimbDamage.timers[limb] or {}
	if selfLimbDamage.timers[limb].timer then killTimer( selfLimbDamage.timers[limb].timer ) end
	selfLimbDamage.timers[limb].timer = tempTimer( 180, [[ ataxia_resetLimbDamage("]]..limb..[[")]])

	-- Check if limb is prepped and alert
	if ataxia_selfLimbPrepped(limb) then
		local shortLimb = ataxia_shortLimb and ataxia_shortLimb(limb) or limb:upper():sub(1,2)
		ataxia_boxEcho(limb:upper().." is PREPPED! (1 hit)", "black:orange")
	end

	if limb == "torso" and selfLimbDamage.torso["damage"] >= 97 then
		ataxia_boxEcho("Torso is likely broken!", "red")
		send("curing predict mildtrauma")
	end

	-- Raise custom event for other systems to listen to
	raiseEvent("self limb damaged", limb, num, selfLimbDamage[limb].damage)
end

function ataxia_resetLimbDamage(limb)
	ataxia_clearLimbDamage(limb)
	ataxiaEcho("Our <green>"..limb.."<NavajoWhite> has been reset.")
end

function ataxia_clearLimbDamage(limb)
	selfLimbDamage[limb]["damage"] = 0
	selfLimbDamage[limb].lastHit = 0
	selfLimbDamage[limb].hitCount = 0
	if selfLimbDamage.timers[limb] and selfLimbDamage.timers[limb].timer then killTimer( selfLimbDamage.timers[limb].timer ) end
	selfLimbDamage.timers[limb] = nil
	-- Update GUI if it exists
	if selfLimbDamage.gui and selfLimbDamage.gui.console then
		ataxia_updateSelfLimbWindow()
	end
end

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
				send("queue addclear free restore",false)
			end
		elseif affliction == "damagedrightleg" or affliction == "mangledrightleg" then
			ataxia_clearLimbDamage("right leg")
			ataxia_boxEcho("RIGHT LEG HAS BEEN BROKEN", "black:DarkOrange")
			if not affed("damagedleftarm") and not affed("damagedrightarm") and ataxiaTemp.salvelockWait then
				killTimer(ataxiaTemp.salvelockWait) 
				ataxiaTemp.salvelockWait = nil			
				send("queue addclear eqbal restore",false)
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

registerAnonymousEventHandler("aff gained", "ataxia_brokenLimbFound")
registerAnonymousEventHandler("aff cured", "ataxia_brokenLimbFound")

-- Reset all limb damage
function ataxia_clearAllLimbDamage()
	for _, limb in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do
		ataxia_clearLimbDamage(limb)
	end
	cecho("\n<DodgerBlue> -= All self limb damage cleared =-")
end

-- Register the trigger for parsing limb damage lines
-- Call this once to set up the trigger
function ataxia_registerLimbDamageTrigger()
	if selfLimbDamage.triggerId then
		killTrigger(selfLimbDamage.triggerId)
	end

	-- Regex pattern: "dealt X% damage to your [limb]"
	-- Example: "As Proficy's blow crunches into you, you perceive that he has dealt 12.6% damage to your right arm."
	selfLimbDamage.triggerId = tempRegexTrigger(
		[[dealt (\d+\.?\d*)% damage to your (head|torso|left arm|right arm|left leg|right leg)]],
		[[
			local damage = tonumber(matches[2])
			local limb = matches[3]:lower()
			if damage and limb and selfLimbDamage[limb] then
				ataxia_raiseLimbDamage(limb, damage)
			end
		]]
	)
	ataxiaEcho("Self limb damage trigger registered.")
end

-- Auto-register the trigger when the script loads
ataxia_registerLimbDamageTrigger()

-------------------------------------------------------------------
-- GEYSER GUI WINDOW FOR SELF LIMB DAMAGE
-------------------------------------------------------------------

selfLimbDamage.gui = selfLimbDamage.gui or {}
selfLimbDamage.gui.fontSize = 9

-- Build the self limb damage window
function ataxia_buildSelfLimbWindow()
	-- Clean up existing window if it exists
	if selfLimbDamage.gui.window then
		selfLimbDamage.gui.window:hide()
		selfLimbDamage.gui.window = nil
	end

	-- Get saved position or use defaults
	local savedPos = selfLimbDamage.gui.savedPosition or {x = 100, y = 100, width = 280, height = 180}

	-- Create the Adjustable Container (moveable, resizable, lockable)
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

	-- Create container inside
	selfLimbDamage.gui.container = Geyser.Container:new({
		name = "selfLimbDamageContainer",
		x = 0, y = 0,
		width = "100%",
		height = "100%",
	}, selfLimbDamage.gui.window)

	-- Create the MiniConsole for display
	selfLimbDamage.gui.console = Geyser.MiniConsole:new({
		name = "selfLimbDamageConsole",
		x = 2, y = 2,
		width = "100%-4",
		height = "100%-4",
		color = "black",
		autoWrap = true,
	}, selfLimbDamage.gui.container)

	setFontSize("selfLimbDamageConsole", selfLimbDamage.gui.fontSize)

	-- Add callback to save position when window is moved/resized
	selfLimbDamage.gui.window:attachToBorder("top")

	-- Show the window
	selfLimbDamage.gui.window:show()

	-- Initial update
	ataxia_updateSelfLimbWindow()

	ataxiaEcho("Self limb damage window created. Right-click title bar for options.")
end

-- Update the limb damage window display
function ataxia_updateSelfLimbWindow()
	if not selfLimbDamage.gui.console then return end

	local console = selfLimbDamage.gui.console
	clearWindow("selfLimbDamageConsole")

	local limbs = {"head", "torso", "left arm", "right arm", "left leg", "right leg"}
	local shortNames = {
		["head"] = "HEAD",
		["torso"] = "TORSO",
		["left arm"] = "L.ARM",
		["right arm"] = "R.ARM",
		["left leg"] = "L.LEG",
		["right leg"] = "R.LEG",
	}

	for _, limb in ipairs(limbs) do
		local status = ataxia_selfLimbStatus(limb)
		if status then
			local color
			if status.damage >= 85 then
				color = "red"
			elseif status.damage >= 70 then
				color = "orange"
			elseif status.damage >= 50 then
				color = "yellow"
			elseif status.damage > 0 then
				color = "green"
			else
				color = "gray"
			end

			local preppedStr = status.prepped and " <red>*PREP*" or ""

			-- Format: LIMB: 50.0% (4 hits) [PREP]
			cecho("selfLimbDamageConsole",
				string.format("<%s>%-6s<white>: %5.1f%% <dim_gray>(%d to brk)%s\n",
					color, shortNames[limb], status.damage, status.hitsToBreak, preppedStr))
		end
	end
end

-- Save window position
function ataxia_saveSelfLimbWindowPosition()
	if selfLimbDamage.gui.window then
		selfLimbDamage.gui.savedPosition = {
			x = selfLimbDamage.gui.window.x,
			y = selfLimbDamage.gui.window.y,
			width = selfLimbDamage.gui.window.width,
			height = selfLimbDamage.gui.window.height,
		}
		selfLimbDamage.gui.window:savePosition()
		ataxiaEcho("Self limb window position saved.")
	end
end

-- Toggle window visibility
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

-- Lock/unlock the window
function ataxia_lockSelfLimbWindow(lock)
	if not selfLimbDamage.gui.window then return end

	if lock then
		selfLimbDamage.gui.window:lockContainer()
		ataxiaEcho("Self limb window locked.")
	else
		selfLimbDamage.gui.window:unlockContainer()
		ataxiaEcho("Self limb window unlocked.")
	end
end

-- Set font size
function ataxia_setSelfLimbWindowFontSize(size)
	selfLimbDamage.gui.fontSize = size or 9
	if selfLimbDamage.gui.console then
		setFontSize("selfLimbDamageConsole", selfLimbDamage.gui.fontSize)
		ataxia_updateSelfLimbWindow()
	end
end

-- Close the window
function ataxia_closeSelfLimbWindow()
	if selfLimbDamage.gui.window then
		selfLimbDamage.gui.window:hide()
	end
end

-- Listen to damage events to auto-update the window
registerAnonymousEventHandler("self limb damaged", function()
	ataxia_updateSelfLimbWindow()
end)