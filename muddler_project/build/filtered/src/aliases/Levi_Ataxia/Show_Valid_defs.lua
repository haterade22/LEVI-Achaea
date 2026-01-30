buildDefsTable()
sortedDefenceShow()
local cur = ataxia.settings.defences.current
local defTable = {}
local ourClass = gmcp.Char.Status.class:lower()

for def, tab in pairs(ataxiaTables.defences) do
	if ataxiaTables.classDefences.curatives[def] or ataxiaTables.classDefences.shared[def] or ataxiaTables.classDefences.tattoos[def] then
		table.insert(defTable, def)
	elseif (ourClass:find("dragon") or ourClass:find("elemental")) and ataxiaTables.classDefences.endgame[def] then
		table.insert(defTable, def)
	elseif ataxiaTables.classDefences[ourClass] and ataxiaTables.classDefences[ourClass][def] then
		table.insert(defTable, def)
	end
end


table.sort(defTable)
local supportedDefs = 0
local linecount = 0
ataxiaEcho("Valid defences to defup with are:")
echo("\n\n")

for _, defence in pairs(defTable) do
	linecount = linecount + 1
	supportedDefs = supportedDefs + 1
	if linecount > 4 then
		linecount = 1
		echo("\n")
	end
	if not ataxia.settings.defences.defup[cur][defence] then
		fg("a_green")
		echoLink("[D]", [[expandAlias("defadd ]]..defence..[[")]], "Add "..defence.." to "..cur.."'s defup list.", true)
	else
		fg("a_red")
		echoLink("[D]", [[expandAlias("defremove ]]..defence..[[")]], "Remove "..defence.." from "..cur.."'s defup list.", true)
	end

	if not ataxia.settings.defences.keepup[cur][defence] then
		fg("a_darkgreen")
		echoLink("[K]", [[expandAlias("keepadd ]]..defence..[[")]], "Add "..defence.." to "..cur.."'s keepup list.", true)
	else
		fg("a_darkred")
		echoLink("[K]", [[expandAlias("keepremove ]]..defence..[[")]], "Remove "..defence.." from "..cur.."'s keepup list.", true)
	end

	cecho("<NavajoWhite> "..defence:title().." ")
	echo(string.rep(" ", 18-string.len(defence)))
	
end
echo("\n")
ataxiaEcho("Total supported defences: "..supportedDefs)

ataxiaEcho("[D] pertains to defup, [K] to keepup. Green is add, red is remove.")