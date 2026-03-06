--[[mudlet
type: alias
name: Remove Ignore
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash unignore$
command: ''
packageName: ''
]]--

if ataxiaBasher.mobIgnore then
	ataxiaEcho("Displaying currently ignored mobs. Click to remove them.")
	for i,v in pairs(ataxiaBasher.mobIgnore) do
		cecho("\n  <red>- ")
		fg("white")
		echoLink(v, [[ataxiaBasher_unignoremob("]]..v..[[")]], "Remove "..v.." from ignore list.", true)
		cecho(" <red>-")
	end
	send(" ")
else
	ataxiaEcho("Area not currently populated.")
end