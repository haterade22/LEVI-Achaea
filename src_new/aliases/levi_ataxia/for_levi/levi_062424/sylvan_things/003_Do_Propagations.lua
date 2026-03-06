--[[mudlet
type: alias
name: Do Propagations
hierarchy:
- Levi_Ataxia
- Ataxia
- Config
- Sylvan
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^prop$
command: ''
packageName: ''
]]--

if not ataxia_isClass("Sylvan") then 
	return
end
ataxiaTemp.propagating = true
ataxiaTemp.currentProps = {
	arms = false,
	legs = false,
	body = false,
	head = false,
}
ataxia_nextPropagation()
