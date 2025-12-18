-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Fracture Management > Handle Fracture Counts

ataxiaTables.twohander = ataxiaTables.twohander or {}

function personFocusedPrecision(person)
	ataxiaTables.twohander = ataxiaTables.twohander or {}
	if not ataxiaTables.twohander[person] then
		ataxiaTables.twohander[person] = true
		if ataxiaTables.twohander[person.."timer"] then killTimer(ataxiaTables.twohander[person.."timer"]) end
		ataxiaTables.twohander[person.."timer"] = tempTimer(2.5,
			function() ataxiaTables.twohander[person.."timer"] = nil
				personLostPrecision(person)
			end)
	end
end

function personLostPrecision(person)
	if ataxiaTables.twohander[person.."timer"] then killTimer(ataxiaTables.twohander[person.."timer"]) end
	ataxiaTables.twohander[person] = nil
end

function twohandAddFracture(aff, who)
	ataxia.afflictions[aff] = ataxia.afflictions[aff] or 0
	local count = 1
	if ataxiaTables.twohander[who] then
		count = 2
		personLostPrecision(who)
	end
	 ataxia.afflictions[aff] = ataxia.afflictions[aff] + count
	 if ataxia.afflictions[aff] > 6 then ataxia.afflictions[aff] = 6 end
end