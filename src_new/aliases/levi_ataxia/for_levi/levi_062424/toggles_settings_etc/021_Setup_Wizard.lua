--[[mudlet
type: alias
name: Setup Wizard
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Toggles
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^levi setup ?(.*)$
command: ''
packageName: ''
]]--

leviSetup.dispatch(matches[2] or "")
