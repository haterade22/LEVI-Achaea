local getSicken = {"paralysis", "manaleech", "slickness"}
local s = false
for _, aff in pairs(getSicken) do
	if not haveAff(aff) then
		s = aff
		break
	end
end
if not s then s = "paralysis" end

if isTargeted(matches[2]) then
	if ataxiaTemp.deadeyesOne then
		if ataxiaTemp.deadeyesOne == "breach" then
			tAffs.curseward = false
		else
			if ataxiaTemp.deadeyesOne == "sicken" then
				tarAffed(s)
			else
				tarAffed(ataxiaTemp.deadeyesOne)
			end
		end
		ataxiaTemp.deadeyesOne = nil
	else
		if ataxiaTemp.deadeyesTwo == "sicken" then
			tarAffed(s)
		else
			tarAffed(ataxiaTemp.deadeyesTwo)
		end
		ataxiaTemp.deadeyesTwo = nil
		if not ataxiaTemp.contemplate then
			send("contemplate "..target)
		end
	end
	
	if haveAff("curseward") then erAff("curseward") end
	targetIshere = true
end