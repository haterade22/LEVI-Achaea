--[[mudlet
type: alias
name: Do Propagations
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Installation / Configuration
- Sylvan Things
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
