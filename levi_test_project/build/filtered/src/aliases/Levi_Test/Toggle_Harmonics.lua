local harmonics = {
	"continuo", "anthem", "hallelujah", "gigue", "canticle", "wassail", "lament",
	"rondo", "contradanse", "bagatelle", "partita", "berceuse", "reel",
}
local harm = matches[2]

if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
end

if table.contains(harmonics, harm) then
	if table.contains(ataxia.bardStuff.harmsList, harm) then
			table.remove(ataxia.bardStuff.harmsList, table.index_of(ataxia.bardStuff.harmsList, harm))
			ataxiaEcho("Removed "..harm.." from wanted harmonics.")
	else
		table.insert(ataxia.bardStuff.harmsList, harm)
		ataxiaEcho("Added "..harm.." to wanted harmonics.")
	end
else
	ataxiaEcho("Invalid harmonic: "..matches[2]..".")
end

ataxia_saveSettings(false)