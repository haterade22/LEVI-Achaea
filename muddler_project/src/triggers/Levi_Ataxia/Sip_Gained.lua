if type(target) == "number" and ataxiaBasher.enabled then
  if zgui then
    cecho("bashDisplay", "\n<violet>SIP| <purple>Gained sip balance!")
  else
    ataxiagui.bashConsole:cecho("\n<violet>SIP| <purple>Gained sip balance!")		
  end
	if not ataxiaBasher.manual then
		deleteFull()
	end
end
ataxia.vitals.sipbal = true

if ataxia.afflictions.kkractlebrand or ataxia.afflictions.latched then
send("sip health")
end