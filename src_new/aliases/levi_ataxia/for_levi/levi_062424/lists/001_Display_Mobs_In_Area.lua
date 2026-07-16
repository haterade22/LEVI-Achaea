--[[mudlet
type: alias
name: Display Mobs In Area
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash room$
command: ''
packageName: ''
]]--

local area = ataxiaBasher_areaKey()
if ataxiaBasher.targetList[area] then
	ataxiaEcho("Displaying valid targets for this area.")
	for i,v in pairs(ataxiaBasher.targetList[area]) do
		cecho("\n")
		fg("a_cyan")
		echoLink(" [E]", [[ataxiaBasher_elevatemob("]]..v..[[")]], "Elevate priority of "..v..".", true)		
		fg("red")
		echoLink(" [R]", [[ataxiaBasher_remmob("]]..v..[[")]], "Remove "..v.." from the target list.", true)
		cecho(" <NavajoWhite>"..v:title())
	end
	send(" ")
else
	ataxiaEcho("Area not currently populated.")
end