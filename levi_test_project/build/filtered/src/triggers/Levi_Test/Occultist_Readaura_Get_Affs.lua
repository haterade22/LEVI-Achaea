local affcount = tonumber(matches[3]) + tonumber(matches[4])
local instillables = {
	"paralysis", "healthleech", "clumsiness", "darkshade",  "haemophilia", "sensitivity", "asthma", "slickness",
}
readAuraAffs.count = tonumber(matches[3])
if isTargeted(matches[2]) then
	if readAuraAffs.count == 0 then
		for _, aff in pairs(instillables) do
			erAff(aff)
			if removeAffV3 then removeAffV3(aff) end
		end
	end
end

if tonumber(matches[4]) == 0 then
  erAff("addiction")
  if removeAffV3 then removeAffV3("addiction") end
else
  tAffs.addiction = true
  if applyAffV3 then applyAffV3("addiction") end
end