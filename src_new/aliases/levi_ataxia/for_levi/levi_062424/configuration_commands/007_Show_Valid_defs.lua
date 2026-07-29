--[[mudlet
type: alias
name: Show Valid defs
hierarchy:
- Levi_Ataxia
- Ataxia
- Defence Config
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(defs valid|valid defs)$
command: ''
packageName: ''
]]--

if not ataxia.settings or not ataxia.settings.defences then return end
local cur = ataxia.settings.defences.current
if not cur or cur == "" or not ataxia.settings.defences.defup[cur] then
	ataxiaEcho("No active profile. Create one with: aconfig profile create <name>, then: defswitch <name>")
	return
end
buildDefsTable()
sortedDefenceShow()
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

-- Column width follows the WIDEST label so the grid stays aligned once the
-- raising-command suffixes are added (Depthswalker's "Bodyaugment (mainaas)" is 21
-- chars against a bare "Blur"); wider labels also mean fewer columns per row.
local labelWidth, perLine = 0, 4
for _, defence in pairs(defTable) do
	local word = ataxia_defenceWord and ataxia_defenceWord(defence) or nil
	local len = string.len(defence) + (word and (string.len(word) + 3) or 0)
	if len > labelWidth then labelWidth = len end
end
labelWidth = labelWidth + 2
if labelWidth > 18 then perLine = 3 end

ataxiaEcho("Valid defences to defup with are:")
echo("\n\n")

for _, defence in pairs(defTable) do
	linecount = linecount + 1
	supportedDefs = supportedDefs + 1
	if linecount > perLine then
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

	-- Show the command that RAISES the defence beside its protocol name, where the two
	-- differ (Depthswalker: "Precision (trusad)" -- nothing about the SSC name tells you
	-- to INTONE TRUSAD). Display only; defadd/keepadd still use the protocol name.
	local word = ataxia_defenceWord and ataxia_defenceWord(defence) or nil
	local labelLen = string.len(defence) + (word and (string.len(word) + 3) or 0)
	cecho("<NavajoWhite> "..defence:title()..(word and ("<DimGrey> ("..word..")") or "").." ")
	echo(string.rep(" ", math.max(1, labelWidth - labelLen)))

end
echo("\n")
ataxiaEcho("Total supported defences: "..supportedDefs)

ataxiaEcho("[D] pertains to defup, [K] to keepup. Green is add, red is remove.")