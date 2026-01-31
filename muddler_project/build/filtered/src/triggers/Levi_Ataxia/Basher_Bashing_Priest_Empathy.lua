empathyTick = empathyTick or 0
empathyTick = empathyTick + 1

if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
	bashConsoleEcho("curing", "Empathy ticked.")
end
