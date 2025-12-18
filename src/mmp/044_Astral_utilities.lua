-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Lusternia > Astral utilities

local astralExits = {
	{5079,5175,"n"},
	{4072,5065,"w"},
	{5088, 5132, "e"},
	{5145, 5176, "s"},
	{5138, 5146, "e"},
	{5158, 5192, "s"},
	{5152, 5041, "e"},
	{5031, 5042, "e"},
	{5022, 5131, "n"},
	{5116, 5198, "w"},
	{5130, 5096, "e"},
	{5089, 5058, "n"},
	{5102, 5115, "e"},
	{5111, 5159, "e"},	
	{5103, 5071, "n"},
	{5059, 5053, "w"},
	{5187, 5169, "w"},
	{5190, 5204, "e"},
	{5065,5072,"e"},
}
local mirrorExits = {
	n="s",
	ne="sw",
	e="w",
	se="nw",
	s="n",
	sw="ne",
	w="e",
	nw="se",
	u="d",
	d="u",
	out="in",
	["in"]="out",
}
function mmp.astroboots(create)
	if mmp.game ~= "lusternia" then return end
	for k, v in pairs(astralExits) do
		if create then
			addSpecialExit(v[1],v[2],"astrojump")
			setExitWeight(v[1],"astrojump",5)
			addSpecialExit(v[2],v[1],"astrojump")
			setExitWeight(v[2],"astrojump",5)
		else
			removeSpecialExit(v[1],"astrojump")
			removeSpecialExit(v[2],"astrojump")
		end
	end
end

function mmp.wildnodes(create)
	if mmp.game ~= "lusternia" then return end
	for k, v in pairs(astralExits) do
		if create then
			setExit(v[1],v[2],v[3])
			setExit(v[2],v[1],mirrorExits[v[3]])
		else
			setExit(v[1],-1,v[3])
			setExit(v[2],-1,mirrorExits[v[3]])
		end
	end
end