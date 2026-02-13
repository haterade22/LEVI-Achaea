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
		totalDamage = 0,
		damageByType = {},
		dpsSessionStart = getEpoch(),
		lastBalanceTime = 0,
		lastBalanceDamage = 0,
		currentBalanceDamage = 0,
	}
	ataxiaEcho("Bashing statistics have been reset.")
end

function bashStats_getDPS()
	local totalDmg = bashStats.totalDamage or 0
	local elapsed = getEpoch() - (bashStats.dpsSessionStart or getEpoch())
	local sessionDPS = elapsed > 0 and math.floor(totalDmg / elapsed) or 0
	local balTime = bashStats.lastBalanceTime or 0
	local balDmg = bashStats.lastBalanceDamage or 0
	local balanceDPS = balTime > 0 and math.floor(balDmg / balTime) or 0
	return sessionDPS, balanceDPS
end