--[[mudlet
type: alias
name: Show Settings
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^anss$
command: ''
packageName: ''
]]--

local count = 0
for i,v in pairs(ataxiaNDB.players) do
	count = count + 1
end

ataxiaEcho("    Ataxia Name Database Settings")
echo("\n ")
ataxiaEcho((ataxiaNDB.highlightNames and "<green>We are" or "<red>We are not").."<NavajoWhite> currently highlighting names.")
cecho("\n       <NavajoWhite>     Total of <white>"..count.."<NavajoWhite> names!\n\n")

ataxiaEcho("    Highlight settings:")
for city, colour in pairs(ataxiaNDB.highlighting) do
	cecho("\n <"..colour..">"..city.."<white>"..string.rep(" ", 12-string.len(city)).."citizens will be highlighted in <"..colour..">"..colour..".")
end

cecho("\n ")
ataxiaEcho("     Enemy settings:")
cecho("\n "..(ataxiaNDB.highlightPriority == "enemies" and "<green>Prioritising" or "<red>Not prioritising").."<NavajoWhite> highlighting of enemies.")
cecho("\n <LightSkyBlue>Enemies will be highlighted in <"..ataxiaNDB.highlighting.Enemies..">"..ataxiaNDB.highlighting.Enemies..".")
cecho("\n    <LightSkyBlue>-Special-")
cecho("\n  "..(ataxiaNDB.enemySettings.bold and "<green>" or "<red>")..utf8.char(186).." <NavajoWhite>Bolded letters.")
cecho("\n  "..(ataxiaNDB.enemySettings.underline and "<green>" or "<red>")..utf8.char(186).." <NavajoWhite>Underlined letters.")
cecho("\n  "..(ataxiaNDB.enemySettings.italics and "<green>" or "<red>")..utf8.char(186).." <NavajoWhite>Italicized letters.")

send(" ")