--[[mudlet
type: alias
name: ^t (.+)$
hierarchy:
- Levi_Ataxia
- Combat
- Limb
attributes:
  isActive: 'no'
  isFolder: 'no'
regex: ^t (.+)$
command: ''
packageName: ''
]]--

send("settarget " .. matches[2])
target = matches[2]:lower():title()

-- This is an example target alias. Note that the target variable has to be properly capitalised.