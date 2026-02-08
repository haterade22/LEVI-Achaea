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
