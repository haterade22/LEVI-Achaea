--[[mudlet
type: alias
name: Shin Augment
hierarchy:
- Levi_Ataxia
- For Levi
- levi_062424
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
regex: ^bash (?:shinprobe|augment)(?:\s+(\w+))?(?:\s+(.+))?$
]]--

-- `bash shinprobe [report|on|off|dump <n>|clear|status]` -- the measured SHIN AUGMENT duration
-- curve, and `bash augment <n>` to set the spend once the curve says what it should be.
--
-- Why a probe at all: AB 316 states no numbers, and the duration SCALES with the shin spent --
-- roughly 10s at the bottom to ~1.5 minutes at the top, and explicitly NOT one shin per second.
-- So `ataxiaBasher.bmAugmentAmount` is a guess until measured, exactly as the rage threshold was
-- before `bash probe` (basher/009). Same approach: record what live play actually shows.
--
-- One shared regex for both verbs because they answer one question -- what should the spend be,
-- and what did that spend buy.
local verb = matches[1]:match("bash (%a+)")
local arg, rest = matches[2], matches[3]

if verb == "augment" then
	local n = tonumber(arg)
	if not n or n < 1 then
		ataxia.echo("<gold>bash augment <n><reset> -- shin to spend on SHIN AUGMENT. Currently <white>"
			.. tostring(tonumber(ataxiaBasher.bmAugmentAmount) or 20)
			.. "<reset>. See <white>bash shinprobe<reset> for what each spend actually buys.")
	else
		ataxiaBasher.bmAugmentAmount = n
		ataxia.echo("<gold>shin augment spend<reset> -> <white>" .. n .. "<reset> shin."
			.. " <DimGrey>(cooldown equals the duration, so uptime cannot exceed 50% whatever you pick.)")
	end
elseif ataxiaBasher_shinProbeCommand then
	ataxiaBasher_shinProbeCommand(arg, rest)
end
