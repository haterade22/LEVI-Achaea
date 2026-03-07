local args = matches[2] and matches[2]:lower():trim() or ""
local cfg = selfLimbDamage and selfLimbDamage.config

if not cfg then
	cecho("\n<red>[SLC] selfLimbDamage.config not initialized.")
	return
end

local function toggle(key, label)
	cfg[key] = not cfg[key]
	local state = cfg[key] and "<green>ON" or "<red>OFF"
	cecho("\n<DodgerBlue>[SLC] <white>" .. label .. ": " .. state)
end

if args == "" then
	-- Show full status
	ataxia_showSelfLimbStatus()

elseif args == "on" then
	cfg.enabled = true
	cecho("\n<DodgerBlue>[SLC] <green>System ENABLED")

elseif args == "off" then
	cfg.enabled = false
	cecho("\n<DodgerBlue>[SLC] <red>System DISABLED")

elseif args == "autoparry on" then
	cfg.autoParry = true
	cecho("\n<DodgerBlue>[SLC] <white>Auto Parry: <green>ON")

elseif args == "autoparry off" then
	cfg.autoParry = false
	cecho("\n<DodgerBlue>[SLC] <white>Auto Parry: <red>OFF")

elseif args == "shield on" then
	cfg.autoShield = true
	cecho("\n<DodgerBlue>[SLC] <white>Auto Shield: <green>ON")

elseif args == "shield off" then
	cfg.autoShield = false
	cecho("\n<DodgerBlue>[SLC] <white>Auto Shield: <red>OFF")

elseif args == "party on" then
	cfg.partyCallout = true
	cecho("\n<DodgerBlue>[SLC] <white>Party Callout: <green>ON")

elseif args == "party off" then
	cfg.partyCallout = false
	cecho("\n<DodgerBlue>[SLC] <white>Party Callout: <red>OFF")

elseif args == "ssc on" then
	cfg.sscPriority = true
	cecho("\n<DodgerBlue>[SLC] <white>SSC Priority: <green>ON")

elseif args == "ssc off" then
	cfg.sscPriority = false
	cecho("\n<DodgerBlue>[SLC] <white>SSC Priority: <red>OFF")

elseif args == "warn on" then
	cfg.warningAlerts = true
	cecho("\n<DodgerBlue>[SLC] <white>Warning Alerts: <green>ON")

elseif args == "warn off" then
	cfg.warningAlerts = false
	cecho("\n<DodgerBlue>[SLC] <white>Warning Alerts: <red>OFF")

elseif args == "crit on" then
	cfg.criticalAlerts = true
	cecho("\n<DodgerBlue>[SLC] <white>Critical Alerts: <green>ON")

elseif args == "crit off" then
	cfg.criticalAlerts = false
	cecho("\n<DodgerBlue>[SLC] <white>Critical Alerts: <red>OFF")

elseif args:find("^parry ") then
	local mode = args:match("^parry (.+)")
	local validModes = {stand = true, defend = true, manual = true, randomarm = true, randomleg = true}
	if validModes[mode] then
		cfg.parryMode = mode
		ataxia.parry = mode
		cecho("\n<DodgerBlue>[SLC] <white>Parry Mode: <cyan>" .. mode)
	else
		cecho("\n<DodgerBlue>[SLC] <red>Invalid mode. Use: stand, defend, manual, randomarm, randomleg")
	end

elseif args == "shikudo on" then
	cfg.antiShikudo = true
	cecho("\n<DodgerBlue>[SLC] <white>Anti-Shikudo Parry: <green>ON")

elseif args == "shikudo off" then
	cfg.antiShikudo = false
	cecho("\n<DodgerBlue>[SLC] <white>Anti-Shikudo Parry: <red>OFF")

elseif args == "reset" then
	ataxia_clearAllLimbDamage()

elseif args == "gui" then
	cfg.guiWindow = not cfg.guiWindow
	ataxia_toggleSelfLimbWindow()
	local state = cfg.guiWindow and "<green>ON" or "<red>OFF"
	cecho("\n<DodgerBlue>[SLC] <white>GUI Window: " .. state)

else
	cecho("\n<DodgerBlue>[SLC] <white>Commands:")
	cecho("\n  <cyan>slc            <dim_gray>- Show status + config")
	cecho("\n  <cyan>slc on/off     <dim_gray>- Master toggle")
	cecho("\n  <cyan>slc autoparry on/off")
	cecho("\n  <cyan>slc shield on/off")
	cecho("\n  <cyan>slc party on/off")
	cecho("\n  <cyan>slc ssc on/off")
	cecho("\n  <cyan>slc warn on/off")
	cecho("\n  <cyan>slc crit on/off")
	cecho("\n  <cyan>slc shikudo on/off <dim_gray>- Anti-Shikudo dynamic parry")
	cecho("\n  <cyan>slc parry <mode> <dim_gray>- stand/defend/manual/randomarm/randomleg")
	cecho("\n  <cyan>slc reset      <dim_gray>- Clear all limb damage")
	cecho("\n  <cyan>slc gui        <dim_gray>- Toggle GUI window")
end
