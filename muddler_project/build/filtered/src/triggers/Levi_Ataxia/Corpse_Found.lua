local corpseTypes = {
	"a shaggy buffalo", "a rugged buffalo",
	"a hideous, writhing squid", 
	"a black sea bass", "a school of clownfish", "a school of fish",
	"a giant red scorpion", "a yellow scorpion",
	"a man-eating shark", "a spearhead shark", "a large bull shark", "a fearsome tiger shark",
	"a fire wyrm", "an ancient wyrm", "a pregnant wyrm", "the Wyrm Lord",
}
local corpseid = string.trim(matches[2])
local corpse = matches[3]

if table.contains(corpseTypes, corpse) then
	table.insert(ataxiaTemp.toButcher, corpseid)
end