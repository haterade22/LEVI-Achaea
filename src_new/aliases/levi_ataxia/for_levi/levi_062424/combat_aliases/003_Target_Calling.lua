--[[mudlet
type: alias
name: Target Calling
hierarchy:
- Levi_Ataxia
- Combat
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^tcal$
command: ''
packageName: ''
]]--

if target_calling then
	target_calling = false
	send("pt Target calling disabled.")
else
	target_calling = true
	send("pt Target calling has been enabled.")
end