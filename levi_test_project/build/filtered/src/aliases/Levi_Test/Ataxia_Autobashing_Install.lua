ataxiaBasher = {}

ataxiaBasher = {
	confOpt = {["True"] = true, yes = true, yep = true, y = true,
				["False"] = false, nope = false, no = false, n = false,},

	enabled = false,
	manual = false,
	areabash = false,
	paused = false,
	shielded = false,

	targetList = {},
	ignore = {},
	dangerList = {},
	dangerCount = 5,
	fleeThreshold = 1000,
	noShieldBreak = {mobs = {}, threshold = 0},
	rageraze = false,
}

ataxiaBasherPaths = {},

ataxiaEcho("Bashing systems engaged and ready.")
send(" ")
ataxia_saveSettings(false)