if tAffs.rebounding == false then
send("pt " ..target..": Rebounding Down")
end
if tAffs.shield == false then
send("pt " ..target..": Shield Down")
end

removeAffV3("rebounding")
removeAffV3("shield")
local aff2 = envenomListTwo[1] and venom_to_aff(envenomListTwo[1]) or nil
if aff2 then
	tarAffed(aff2)
	table.remove(envenomListTwo,1)
	if partyrelay and not ataxia.afflictions.aeon then
		send("pt "..target..": "..aff2)
	end
end