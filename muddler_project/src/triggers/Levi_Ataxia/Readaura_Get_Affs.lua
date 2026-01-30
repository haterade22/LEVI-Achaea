local affcount = tonumber(matches[3]) + tonumber(matches[4])
local instillables = {
	"paralysis", "healthleech", "clumsiness", "darkshade",  "haemophilia", "sensitivity", "asthma", "slickness",
}
readAuraAffs.count = tonumber(matches[3])
if isTargeted(matches[2]) then
	if readAuraAffs.count == 0 then
		for _, aff in pairs(instillables) do
			erAff(aff)
		end
	end
end

if tonumber(matches[4]) == 0 then
  erAff("addiction")
else
  tAffs.addiction = true
end