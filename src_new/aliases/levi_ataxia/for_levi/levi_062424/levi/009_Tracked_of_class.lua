--[[mudlet
type: alias
name: Tracked of class
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
regex: ^an class (\w+)$
command: ''
packageName: ''
]]--

local classList = {"Alchemist", "Apostate", "Bard", "Blademaster", "Depthswalker", "Dragon", "Druid", "Infernal", "Jester", "Magi", "Monk", "Occultist",
	"Paladin", "Priest", "Psion", "Runewarden", "Sentinel", "Serpent", "Shaman", "Sylvan"}
	
	ataxiaEcho("Displaying tracked people as "..matches[2].." class:")
	local people = {}
	for i,v in pairs(ataxiaNDB.players) do
		if v.class == matches[2]:title() then
			table.insert(people, v.name)
		elseif matches[2]:title() == "Classless" then
			if not table.contains(classList, v.class) then
				table.insert(people, v.name)
			end
		end
	end
	table.sort(people)
  cecho("\n ")
  for _, person in pairs(people) do
    cecho("<"..ataxiaNDB_getColour(person)..">"..person..", ")
  end


