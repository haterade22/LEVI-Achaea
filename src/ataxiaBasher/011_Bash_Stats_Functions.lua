-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > Bashing > Bash Stats Functions

function resetBashingStats()
cecho("TEST TEST TEST TEST")
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