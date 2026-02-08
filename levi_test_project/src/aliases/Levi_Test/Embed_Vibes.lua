if not ataxia_isClass("magi") then
	ataxiaEcho("Class is not currently magi.")
	return
elseif not ataxia.magi.vibes or #ataxia.magi.vibes < 1 then
	ataxiaEcho("No vibes currently set to call.")
	return
end

ataxiaTemp.embeddingVibes = true
ataxiaTemp.vibes = {}

for _, vibe in pairs(ataxia.magi.vibes) do
	table.insert(ataxiaTemp.vibes, vibe)
end

ataxiaEcho("Commencing vibe embedding.")

send("vibes",false)