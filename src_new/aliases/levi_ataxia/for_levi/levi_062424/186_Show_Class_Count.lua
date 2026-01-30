--[[mudlet
type: alias
name: Show Class Count
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
- Actions
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^an classes$
command: ''
packageName: ''
]]--

local classList = {"Alchemist", "Apostate", "Bard", "Blademaster", "Depthswalker", "Dragon", "Druid", "Infernal", "Jester", "Magi", "Monk", "Occultist",
	"Paladin", "Pariah", "Priest", "Psion", "Runewarden", "Sentinel", "Serpent", "Shaman", "Sylvan",}
local classes = {
	Alchemist = {},
	Apostate = {},
	Bard = {},
	Blademaster = {},
	Depthswalker = {},
	Dragon = {},
	Druid = {},
	Infernal = {},
	Jester = {},
	Magi = {},
	Monk = {},
	Occultist = {},
	Paladin = {},
  Pariah = {},
	Priest = {},
	Psion = {},
	Runewarden = {},
	Sentinel = {},
	Serpent = {},
	Shaman = {},
	Sylvan = {},
}

for player, tab in pairs(ataxiaNDB.players) do
	if tab.class ~= "" then
		table.insert(classes[tab.class], player)
		if tab.level >= 99 then
		table.insert(classes.Dragon, player)
		end	
	end
end

ataxiaEcho("Displaying class count of currently tracked players.")
for _, class in ipairs(classList) do
	cecho("\n <DimGrey>[<NavajoWhite>"..class:title().."<DimGrey>]"..string.rep(" ", 13-string.len(class)).."- <NavajoWhite>"..#classes[class].." tracked people are "..class..".")
end
send(" ")