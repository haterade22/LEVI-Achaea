--[[mudlet
type: alias
name: Show City Count
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
regex: ^an cclasses (\w+)$
command: ''
packageName: ''
]]--


local classList = {"Alchemist", "Apostate", "Bard", "Blademaster", "Depthswalker", "Dragon", "Druid", "Infernal", "Jester", "Magi", "Monk", "Occultist",
	"Paladin", "Pariah", "Priest", "Psion", "Runewarden", "Sentinel", "Serpent", "Shaman", "Sylvan"}
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
	if (( tab.city == matches[2]:title() ) or (tab.city == "None" and matches[2]:title() == "Rogues")) and tab.class ~= "" then
		table.insert(classes[tab.class], player)
		if tab.level >= 99 then
			table.insert(classes.Dragon, player)
		end	
	end
end

ataxiaEcho("Displaying class count of currently tracked players in <"..ataxiaNDB.highlighting[matches[2]:title()]..">"..matches[2]:title()..".")
for _, class in ipairs(classList) do
	if #classes[class] > 0 then
		cecho("\n <DimGrey>[<NavajoWhite>"..class:title().."<DimGrey>]"..string.rep(" ", 13-string.len(class)).."- <NavajoWhite>"..#classes[class].." tracked people are "..class..".")
	end
end
send(" ")