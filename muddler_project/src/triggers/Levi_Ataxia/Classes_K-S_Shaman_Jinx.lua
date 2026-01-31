can_jinx = false
if type(target) ~= "string" then return end

if isTargeted(matches[4]) then
	ataxiaTemp.jinxone, ataxiaTemp.jinxtwo = curseConvert(matches[2]), curseConvert(matches[3])
  
  if ataxiaTemp.jinxone ~= "bleed" and ataxiaTemp.jinxtwo == "bleed" then
    tarAffed(ataxiaTemp.jinxone)
  elseif ataxiaTemp.jinxone ~= "bleed" and ataxiaTemp.jinxtwo ~= "bleed" then
    tarAffed(ataxiaTemp.jinxone, ataxiaTemp.jinxtwo)
   if partyrelay then send("pt "..target..": "..ataxiaTemp.jinxone.." "..ataxiaTemp.jinxtwo) end
  end
	
	if ataxiaTemp.jinxone ~= "breach" and not tzantzacurse and ataxiaTemp.jinxone ~= "tzantza" and ataxiaTemp.jinxtwo ~= "tzantza" then
		send("Discern "..target)
	end

	if ataxiaTemp.jinxtwo == "inflame" then
		tempTimer(2, [[tAffs.inflame = false]])
	end
	targetIshere = true

	if tAffs.bleed == nil then tAffs.bleed = 0 end
  if not tAffs.haemophilia then
  tAffs.bleed = 0
  end
	if tAffs.haemophilia then
  tAffs.bleed = tAffs.bleed + 80
	cecho(" <white>[<red>"..tAffs.bleed.."<white>]")
  end
end