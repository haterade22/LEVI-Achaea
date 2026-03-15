--[[mudlet
type: alias
name: Install
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^abinstall$
command: ''
packageName: ''
]]--

local defaults = {
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

ataxiaBasher = ataxiaBasher or {}
for k, v in pairs(defaults) do
	if ataxiaBasher[k] == nil then
		ataxiaBasher[k] = v
	end
end

ataxiaBasherPaths = ataxiaBasherPaths or {}

ataxiaEcho("Bashing systems engaged and ready.")
send(" ")
ataxia_saveSettings(false)
