--[[mudlet
type: alias
name: Composition (Gives Shield to All)
hierarchy:
- Levi_Ataxia
- Artefacts
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^comp$
command: ''
packageName: ''
]]--

send("PERFORM COMPOSITION")
if partyrelay and not ataxia.afflictions.aeon then 
send("pt I GAVE EVERYONE SHIELD")
end