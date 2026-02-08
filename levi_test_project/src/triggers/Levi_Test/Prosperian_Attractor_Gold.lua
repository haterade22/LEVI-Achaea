if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", "Yoinked their gold!")
  ataxiaTemp.goldinhand = true
  if not ataxiaBasher.manual then
  	deleteFull()
  end
end
