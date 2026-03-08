--[[mudlet
type: alias
name: Show Class Count
hierarchy:
- Levi_Ataxia
- Ataxia
- NDB
- Actions
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^an classes$
command: ''
packageName: ''
]]--

local classList = {"Alchemist", "Apostate", "Bard", "Blademaster", "Depthswalker", "Dragon", "Druid", "Infernal", "Jester", "Magi", "Monk", "Occultist",
	"Paladin", "Pariah", "Priest", "Psion", "Runewarden", "Sentinel", "Serpent", "Shaman", "Sylvan",
	"Unnamable", "Airlord", "Earthlord", "Firelord", "Waterlord",}
local classes = {}
for _, c in ipairs(classList) do classes[c] = {} end

for player, tab in pairs(ataxiaNDB.players) do
	if tab.class and tab.class ~= "" then
		if not classes[tab.class] then classes[tab.class] = {} end
		table.insert(classes[tab.class], player)
		if tab.level and tab.level >= 99 then
			table.insert(classes.Dragon, player)
		end
	end
end

ataxiaEcho("Displaying class count of currently tracked players.")
for _, class in ipairs(classList) do
	cecho("\n <DimGrey>[<NavajoWhite>"..class:title().."<DimGrey>]"..string.rep(" ", math.max(0, 13-string.len(class))).."- <NavajoWhite>"..#classes[class].." tracked people are "..class..".")
end
send(" ")