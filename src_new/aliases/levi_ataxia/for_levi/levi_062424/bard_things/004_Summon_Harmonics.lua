--[[mudlet
type: alias
name: Summon Harmonics
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Bard Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^harms$
command: ''
packageName: ''
]]--

if not ataxia_isClass("bard") then
	ataxiaEcho("Class is not currently bard.")
	return
elseif #ataxia.bardStuff.harmsList < 1 then
	ataxiaEcho("No harmonics currently set to call.")
	return
end
send("wield rapier lyre")
ataxiaTemp.summoningHarms = true
ataxiaTemp.harmsSummoned = false
ataxiaTemp.harms = {}

for _, harm in pairs(ataxia.bardStuff.harmsList) do
	table.insert(ataxiaTemp.harms, harm)
end

ataxiaEcho("Commencing harmonics summoning.")

ataxia_nextHarmonic()