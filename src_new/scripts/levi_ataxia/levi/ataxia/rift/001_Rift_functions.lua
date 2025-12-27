--[[mudlet
type: script
name: Rift functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Gmcp Related
- Rift
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxia_riftContents()
	ataxiaTemp.riftContents = {}
	
	for _, tab in pairs(gmcp.IRE.Rift.List) do
		ataxiaTemp.riftContents[tab.name] = tonumber(tab.amount)
	end
end

function ataxia_riftUpdate()
	if not ataxiaTemp.riftContents then
		return
	end
	
	local item = gmcp.IRE.Rift.Change
	ataxiaTemp.riftContents[item.name] = tonumber(item.amount)
end

registerAnonymousEventHandler("gmcp.IRE.Rift.List", "ataxia_riftContents")
registerAnonymousEventHandler("gmcp.IRE.Rift.Change", "ataxia_riftUpdate")