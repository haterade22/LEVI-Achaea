--[[mudlet
type: alias
name: Install
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Autobashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^abinstall$
command: ''
packageName: ''
]]--

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