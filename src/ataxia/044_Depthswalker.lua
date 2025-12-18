-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Class Things > Depthswalker

ataxiaTables.depthswalker = {
		usedPreempt = false,
		canPreempt = true,
		age = 0,
		wordBal = true,
		causalityBal = true,
	}
	

function ataxia_depthswalkerReset()
	ataxiaTables = ataxiaTables or {}
	ataxiaTables.depthswalker = {
		usedPreempt = false,
		canPreempt = true,
		age = 0,
		wordBal = true,
		causalityBal = true,
	}
	
	updating_terminus_abilities = true
	sendAll("config pagelength 200", "Ab terminus", "config pagelength 60",false)
end

function haveWord(word)
	if ataxiaTables.depthswalker.abilities and ataxiaTables.depthswalker.abilities[word:lower()] then
		return true
	else
		return false
	end
end

function getAgeColour()
	local num = ataxiaTables.depthswalker.age
	local col = "DimGrey"
	if num <= 250 then
		col = "DimGrey"
	elseif num <= 400 then
		col = "yellow"
	elseif num <= 600 then
		col = "orange"
	else
		col = "red"
	end
	return col
end