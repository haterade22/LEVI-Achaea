--[[mudlet
type: alias
name: MIND LOCK TOGGLE
hierarchy:
- Levi_Ataxia
- Classes
- Monk
- TELEPATHY
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^min$
command: ''
packageName: ''
]]--

wantmindlock = wantmindlock or false

if wantmindlock then wantmindlock = false
ataxia_boxEcho("NOT MIND LOCKING ANYMORE", "red")
elseif not wantmindlock then wantmindlock = true
send("mind lock "..target)
ataxia_boxEcho("ATTEMPTING MIND LOCK", "white")

end