local classList = {"Alchemist", "Apostate", "Bard", "Blademaster", "Depthswalker", "Dragon", "Druid", "Infernal", "Jester", "Magi", "Monk", "Occultist",
	"Paladin", "Pariah", "Priest", "Psion", "Runewarden", "Sentinel", "Serpent", "Shaman", "Sylvan",
	"Unnamable", "Airlord", "Earthlord", "Firelord", "Waterlord",}
local classes = {}
for _, c in ipairs(classList) do classes[c] = {} end

local cityName = matches[2]:title()
for player, tab in pairs(ataxiaNDB.players) do
	if ((tab.city == cityName) or (tab.city == "None" and cityName == "Rogues")) and tab.class and tab.class ~= "" then
		if not classes[tab.class] then classes[tab.class] = {} end
		table.insert(classes[tab.class], player)
		if tab.level and tab.level >= 99 then
			table.insert(classes.Dragon, player)
		end
	end
end

local hlColour = ataxiaNDB.highlighting[cityName] or ataxiaNDB.highlighting.Rogues
ataxiaEcho("Displaying class count of currently tracked players in <"..hlColour..">"..cityName..".")
for _, class in ipairs(classList) do
	if #classes[class] > 0 then
		cecho("\n <DimGrey>[<NavajoWhite>"..class:title().."<DimGrey>]"..string.rep(" ", math.max(0, 13-string.len(class))).."- <NavajoWhite>"..#classes[class].." tracked people are "..class..".")
	end
end
send(" ")