--[[mudlet
type: script
name: Inkmilling
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Harvesting/Crafting
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--Change this to true if you have an artifact mill.
--Make sure to click 'save profile' after changing it, so it updates.
local have_mill = false
--Change these two if you want to use the secondary reagents for red/blue reagents.
local redReagent = "red clay"
local blueReagent = "lumic moss"

local ink_reagents = {
	yellow = "yellow chitin",
	gold = "gold flakes",
	common = "fish scales",
	uncommon = "buffalo horn",
	scarce = "shark tooth",
	rare = "wyrm tongue",
}
ink_reagents.red = redReagent
ink_reagents.blue = blueReagent

local ink_costs = {
	red = {red = 1, common = 1},
	blue = {blue = 1, uncommon = 1},
	yellow = {yellow = 1, scarce = 1},
	green = {blue = 2, yellow = 1, uncommon = 2, scarce = 1},
	purple = {red = 2, blue = 2, uncommon = 2, common = 2, rare = 1},
	gold = {gold = 1, common = 2, uncommon = 2, scarce = 2, rare = 1},
}

--Print what we can make.
function inkmilling_canMake()
	ataxia_Echo("Listing the inks we can make based on the following reagents:")
	echo("\n")
	local line = 0
	for reagent, longname in pairs(ink_reagents) do
		line = line + 1
	
		if (line-1)%3 == 0 then
			echo("\n")
		end
		
		local count = ataxiaTemp.riftContents[longname] and ataxiaTemp.riftContents[longname] or 0
		cecho("<a_darkgreen>"..longname:title().."<reset>:<NavajoWhite>"..string.rep(" ", 14-string.len(longname))..count)
		
		local spacing = longname..":"..string.rep(" ", 14-string.len(longname))..count	
		cecho(string.rep(" ", 25 - string.len(spacing)))
	end
	echo("\n")	
	for inkType, reagents in pairs(ink_costs) do
		cecho("\n<"..inkType..">"..inkType:title()..":<NavajoWhite>"..string.rep(" ", 8-string.len(inkType))..inkmilling_getAmount(inkType))
	end
	
	send(" ")
end

--This will return whether or not we can actually make the amount specified.
function inkmilling_getAmount(inkcolour)
	local canMake = false
	for reagent, cost in pairs(ink_costs[inkcolour]) do
		local weHave = ataxiaTemp.riftContents[ink_reagents[reagent]] and ataxiaTemp.riftContents[ink_reagents[reagent]] or 0
		if weHave == 0 then
			canMake = 0
		else
			if not canMake then
				canMake = weHave/cost
			elseif (weHave/cost) < canMake then
				canMake = weHave/cost
			end
		end
	end
	return math.floor(canMake)
end

--Now we actually make the inks!
function inkmilling_createInks()
	local perMill = (have_mill and 10 or 5)
	local toMake = ( (ataxiaTemp.inkAmount > perMill) and perMill or ataxiaTemp.inkAmount )
	local sp = ataxia.settings.separator
	if inkmilling_getAmount(ataxiaTemp.inkColour) < ataxiaTemp.inkAmount then
		ataxia_Echo("We cannot make that many "..ataxiaTemp.inkColour.." inks.")
		inkmilling_stopInks()
	else
		for reagent, cost in pairs(ink_costs[ataxiaTemp.inkColour]) do
			local x = ink_reagents[reagent]:gsub(" ", "")
			if x == "lumicmoss" then x = "lumic" end
			send("outr "..(cost*toMake).." "..x..sp.."put group "..x.." in mill",false)
		end
		ataxiaTemp.inkAmount = ataxiaTemp.inkAmount - toMake
		send("mill for "..toMake.." "..ataxiaTemp.inkColour,false)
	end	
end

--Stop making inks.
function inkmilling_stopInks()
	ataxia_Echo("No longer making inks.")
	ataxiaTemp.inkColour = nil
	ataxiaTemp.inkAmount = nil
	ataxiaTemp.inkMaking = nil
	send("clearqueue eqbal",false)
end