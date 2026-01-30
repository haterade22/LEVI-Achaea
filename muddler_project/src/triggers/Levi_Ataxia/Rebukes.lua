local rebukes = {
	chaos = "hallucinations",
	darkness = "paranoia",
	evil = "masochism"
}
local rtype = matches[5]:lower()

if isTargeted(matches[2]) then
	tarZealHit(rebukes[rtype])
	ataxiaTemp.prayerList = {}
end

