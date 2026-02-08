local minerals = {"antimony", "argentum", "arsenic", "aurum", "azurite", "bisemutum", "calamine", "calcite", "cinnabar", "cuprum", "dolomite", "ferrum", "gypsum", "magnesium", "malachite", "plumbum", "potash", "quartz", "quicksilver", "realgar", "stannum"}
local herbs = {"ash", "bayberry", "bellwort", "bloodroot", "cohosh", "elm", "ginger", "ginseng", "goldenseal", "hawthorn", "kelp", "kola", "lobelia", "skullcap", "valerian", "sileris", "irid", "pear"}

ataxiaTemp.keepout = ataxiaTemp.keepout or {}

function populate_keepOut()
	ataxia.settings.precache = ataxia.settings.precache or {}
	ataxiaTemp.keepout = {}
	
	for i,v in pairs(ataxia.settings.precache) do
		ataxiaTemp.keepout[i] = v
	end
end

function ataxia_precacheSet(item, amount)
	local num = tonumber(amount)
	if table.contains(minerals, item) or table.contains(herbs, item) then
		if num > 0 then
			ataxia.settings.precache[item] = num
			ataxia_precacheShow()
			populate_keepOut()
			ataxia_precacheQueue()
			ataxia_saveSettings(false)
		elseif num == 0 then
			ataxia.settings.precache[item] = nil
			ataxia_precacheShow()
			populate_keepOut()
			ataxia_precacheQueue()
			ataxia_saveSettings(false)			
		else
			ataxiaEcho("Number for precache must be 0 or higher.")
		end
	else
		ataxiaEcho("That is not a valid herb or mineral.")
	end
end

function ataxia_precacheShow()
	ataxiaEcho("System precache settings.")
	local outriftables = {"antimony", "argentum", "arsenic", "aurum", "azurite", "bisemutum", "calamine", "calcite", "cinnabar", "cuprum", 
		"dolomite", "ferrum", "gypsum", "magnesium", "malachite", "plumbum", "potash", "quartz", "quicksilver", "realgar", "stannum",
  	"ash", "bayberry", "bellwort", "bloodroot", "cohosh", "elm", "ginger", "ginseng", "goldenseal", "hawthorn", "kelp", "kola", "lobelia", 
		"skullcap", "valerian", "sileris", "irid", "pear"}
	table.sort(outriftables)
	local x = 0
	for n, item in spairs(outriftables) do
		x = x + 1
		local num = 0
		if ataxia.settings.precache[item] then
			num = ataxia.settings.precache[item]
		end		
		local d = "<a_cyan>[<NavajoWhite>"..num.."<a_cyan>] <DimGrey>"
		if (x-1)%3 == 0 then
			echo("\n")
		end
		cecho(d)
		local nWithSpace = item
		local length = nWithSpace:len() + math.floor(math.log10(math.max(1,num)))
		if length < 25 and (x-1)%3 ~= 2 then
			local pad = 25 - length
			nWithSpace = string.rep(" ", pad)
		else
			nWithSpace = ""
		end
		cecho("<DimGrey>"..item:title())
		echo(" ")

		local increase = "pconfig "..item.." "..num + 1
		local decrease = "pconfig "..item.." "..num - 1
		echoLink("(+)", [[expandAlias("]]..increase..[[")]], "Increase outrift of "..item.." by 1.", true)
		echo(" ")
		echoLink("(-)", [[expandAlias("]]..decrease..[[")]], "Decrease outrift of "..item.." by 1.", true)
		cecho("<DimGrey>"..nWithSpace)
	end
	send(" ")		
end