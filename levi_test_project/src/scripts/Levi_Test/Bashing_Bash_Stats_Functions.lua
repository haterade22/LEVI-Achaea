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