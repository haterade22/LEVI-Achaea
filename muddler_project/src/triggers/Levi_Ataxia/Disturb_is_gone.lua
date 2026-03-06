if gmcp.Char.Status.class == "Sylvan" then
	ataxiaEcho("Clouds are gone! Put them back!")
else
	return
end
tAffs.disturb = false
if removeAffV3 then removeAffV3("disturb") end
tAffs.feedback = false
if removeAffV3 then removeAffV3("feedback") end