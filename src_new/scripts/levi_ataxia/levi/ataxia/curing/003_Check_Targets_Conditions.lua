--[[mudlet
type: script
name: Check Targets Conditions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Curing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function checkTargetLocks()
  if lockEchoTimer then return end

	softlock, hardlock, truelock, toecho = false, false, false, ""

	if checkEnlighten() and ataxia_isClass("Occultist") then
		cecho("\n<yellow> ~ ~ [ <a_darkmagenta>TARGET CAN BE ENLIGHTENED <yellow>] ~ ~")
	end

	if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
		softlock = true
	else
		return
	end

	if softlock and checkAffList({"impatience", "sandfever"},1) then
		hardlock = true
	end

	if hardlock and haveAff("paralysis") then
		truelock = true
	end

	toecho = "<purple>   [<NavajoWhite>LOCKS<purple>]:  <yellow>soft"
	if hardlock then toecho = toecho..", <orange>hard" end
	if truelock then toecho = toecho..", <red>true" end
	toecho = toecho.."<NavajoWhite>."

	cecho("\n"..toecho)	
  lockEchoTimer = tempTimer(15, [[ lockEchoTimer = nil ]])
end

function tarIsTempered()
	if tAffs.sanguine or tAffs.phlegmatic or tAffs.choleric or tAffs.melancholic then
		return true
	else
		return false
	end
end

function restoreLastKelp()
	local kelps = {"hypochondria", "parasite", "weariness", "healthleech", "clumsiness", "sensitivity"}
	if lastKelp and lastKelp == "asthma" then
		-- They smoked, proving asthma is still there - restore confidence to 1.0
		tAffs.asthma = true
		if tAffConfidence then
			tAffConfidence.asthma = 1.0
		end
		ataxiaEcho("Doesn't look like that kelp got asthma.")
		-- They must have cured one of the other kelp afflictions
		for i=1, #kelps do
			if haveAff(kelps[i]) then
				erAff(kelps[i])
				break
			end
		end
	end
	lastKelp = nil
end

function affDuration(aff)
  local g = getEpoch()
  if not affTimers or not affTimers[aff] then
    return 0
  else
    return tonumber( string.format("%2.3f", (g-affTimers[aff])) )
  end
end