local tzAffs = {"agoraphobia", "claustrophobia", "dementia", "epilepsy", "masochism", "recklessness",
	"vertigo", "confusion", "dizziness", "impatience", "paranoia", "stupidity", "addiction"}

if line:find("not adequately prepared") then
	for i,v in pairs(tzAffs) do
		if haveAff(v) then
			erAff(v)
			if removeAffV3 then removeAffV3(v) end
		end
	end
	selectString(line,1)
	fg("red")
	resetFormat()
end

tzantzacurse = false
send("curing on")
ataxiaEcho("System has been <green>unpaused.")