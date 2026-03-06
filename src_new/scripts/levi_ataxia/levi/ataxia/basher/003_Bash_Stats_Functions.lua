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

function resetBashingStats()
	bashStats = {}
	bashStats = {
		criticals = { ["2x"] = 0, ["4x"] = 0, ["8x"] = 0, ["16x"] = 0, ["32x"] = 0, ["64x"] = 0 },
		attacks = 0,
		loginGold = tonumber(gmcp.Char.Status.gold),
		gainedGold = 0,
		crits = 0,
		slain = 0,
		mobhits = 0,
		blockedhits = 0,
	}
	ataxiaEcho("Bashing statistics have been reset.")
end

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