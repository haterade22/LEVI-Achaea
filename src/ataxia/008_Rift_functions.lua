-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Gmcp Related > Rift > Rift functions

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