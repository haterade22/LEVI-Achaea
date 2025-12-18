-- Basher module (automated hunting)
-- Placeholder structure - core logic would be migrated from ataxiaBasher

ataxiaBasher = ataxiaBasher or {}

-- Configuration
ataxiaBasher.enabled = false
ataxiaBasher.fleePct = 50        -- Flee at this health percentage
ataxiaBasher.attackCmd = "kill"  -- Default attack command
ataxiaBasher.currentTarget = nil
ataxiaBasher.paused = false

-- Toggle basher on/off
function ataxiaBasher.toggle()
	ataxiaBasher.enabled = not ataxiaBasher.enabled
	if ataxiaBasher.enabled then
		cecho("\n<green>Basher ENABLED")
		ataxiaBasher.scan()
	else
		cecho("\n<red>Basher DISABLED")
		ataxiaBasher.currentTarget = nil
	end
end

-- Pause basher (maintains enabled state)
function ataxiaBasher.pause()
	ataxiaBasher.paused = true
	cecho("\n<yellow>Basher PAUSED")
end

-- Resume basher
function ataxiaBasher.resume()
	ataxiaBasher.paused = false
	cecho("\n<green>Basher RESUMED")
	if ataxiaBasher.enabled then
		ataxiaBasher.scan()
	end
end

-- Scan room for targets
function ataxiaBasher.scan()
	if not ataxiaBasher.enabled or ataxiaBasher.paused then
		return
	end

	-- Check health before attacking
	local hp = ataxia.safeGet(gmcp, "Char", "Vitals", "hp") or 0
	local maxhp = ataxia.safeGet(gmcp, "Char", "Vitals", "maxhp") or 1
	local hpPct = (tonumber(hp) / tonumber(maxhp)) * 100

	if hpPct < ataxiaBasher.fleePct then
		cecho("\n<red>Health low! Fleeing...")
		send("fl")
		return
	end

	-- Get NPCs in room from GMCP
	local items = ataxia.safeGet(gmcp, "Char", "Items", "List", "items")
	if not items then return end

	for _, item in ipairs(items) do
		if item.attrib and item.attrib:find("m") then  -- 'm' = monster/NPC
			ataxiaBasher.currentTarget = item.id
			ataxiaBasher.attack()
			return
		end
	end

	-- No targets found
	ataxiaBasher.currentTarget = nil
end

-- Attack current target
function ataxiaBasher.attack()
	if not ataxiaBasher.currentTarget then return end
	if not ataxia.hasBalance() then return end

	send(ataxiaBasher.attackCmd .. " " .. ataxiaBasher.currentTarget)
end

-- Handle balance regain
local function onBalanceGained(_, balType)
	if balType == "bal" or balType == "eq" then
		if ataxiaBasher.enabled and not ataxiaBasher.paused and ataxia.hasBalance() then
			ataxiaBasher.attack()
		end
	end
end

-- Handle room change
local function onRoomChange()
	if ataxiaBasher.enabled and not ataxiaBasher.paused then
		-- Small delay to let GMCP update
		tempTimer(0.5, function()
			ataxiaBasher.scan()
		end)
	end
end

-- Register event handlers
ataxia.events.register("balance gained", onBalanceGained, "basher_balance")
ataxia.events.register("gmcp.Room.Info", onRoomChange, "basher_room")
