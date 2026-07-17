--[[mudlet
type: script
name: Bash Stats Functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Bash Stats Functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function resetBashingStats(silent)
	bashStats = {
		criticals = { ["2x"] = 0, ["4x"] = 0, ["8x"] = 0, ["16x"] = 0, ["32x"] = 0, ["64x"] = 0 },
		attacks = 0,
		loginGold = tonumber(gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.gold) or 0,
		gainedGold = 0,
		crits = 0,
		slain = 0,
		mobhits = 0,
		blockedhits = 0,
		-- Damage/DPS fields were added lazily elsewhere (nil until first hit), so combat triggers
		-- that increment them (337_Our_Attacks, denizen_attacks/007+008) crashed on a fresh session.
		-- Initialise them here so bashStats is always complete.
		totalDamage = 0,
		damageByType = {},
		currentBalanceDamage = 0,
		lastBalanceDamage = 0,
		lastBalanceTime = 0,
		lastHitWasCrit = false,
		dpsSessionStart = getEpoch(),
	}
	if not silent then ataxiaEcho("Bashing statistics have been reset.") end
end

-- Initialise at LOAD so `bashStats` is NEVER nil. It used to be created only by an explicit
-- resetBashingStats() call, so on a fresh login or a SYSUPDATE reload the combat triggers hit
-- `attempt to index global 'bashStats' (a nil value)` on the first attack. Silent (no "reset"
-- echo), and only when absent so a live reload keeps the running counts.
if not bashStats then resetBashingStats(true) end

function bashStats_getDPS()
	if not bashStats then return "0", "0" end
	-- Session DPS: total damage / elapsed time
	local elapsed = getEpoch() - (bashStats.dpsSessionStart or getEpoch())
	local sDPS = "0"
	if elapsed > 0 and bashStats.totalDamage and bashStats.totalDamage > 0 then
		sDPS = string.format("%.1f", bashStats.totalDamage / elapsed)
	end
	-- Per-balance DPS: last balance damage / last balance time
	local bDPS = "0"
	if bashStats.lastBalanceTime and bashStats.lastBalanceTime > 0
		and bashStats.lastBalanceDamage and bashStats.lastBalanceDamage > 0 then
		bDPS = string.format("%.1f", bashStats.lastBalanceDamage / bashStats.lastBalanceTime)
	end
	return sDPS, bDPS
end