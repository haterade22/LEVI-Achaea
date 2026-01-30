if ataxia.afflictions.unknown and ataxia.afflictions.unknown > 0 then
		ataxia.afflictions.unknown = ataxia.afflictions.unknown - 1
		if ataxia.afflictions.unknown == 0 then ataxia.afflictions.unknown = nil end
		send("curing predict brokenleftleg")
end