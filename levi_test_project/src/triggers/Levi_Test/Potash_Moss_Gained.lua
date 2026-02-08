if type(target) == "number" and ataxiaBasher.enabled then
  
  if zgui then
    cecho("bashDisplay","\n<green>MOSS| <DarkGreen>Got moss balance!")	
  else
    ataxiagui.bashConsole:cecho("\n<green>MOSS| <DarkGreen>Got moss balance!")		
  end
	if not ataxiaBasher.manual then
		deleteFull()
	end
end
