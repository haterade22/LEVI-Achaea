if type(target) == "number" and ataxiaBasher.enabled then
	if not bashElixirSub then
   if zgui then
      cecho("bashDisplay", "\n<purple>SIP| <violet>Used sip balance!")	
    else   
		  ataxiagui.bashConsole:cecho("\n<purple>SIP| <violet>Used sip balance!")		
    end
		bashElixirSub = tempTimer(1, [[ bashElixirSub = nil ]])
	end
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

ataxia.vitals.sipbal = false