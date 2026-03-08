local person = target

if multimatches[3][1] == "The attack rebounds back onto you!" then
  tarAffed("rebounding")
elseif multimatches[3][1] == person .. " dodges nimbly out of the way." 
		or multimatches[3][1] == person .. " parries the attack with a deft manoeuvre." 
		or multimatches[3][1] == person .. " steps into the attack, grabs your arm, and throws you violently to the ground." 
		or multimatches[3][1] == person .. " quickly jumps back, avoiding the attack."  
		or multimatches[3][1] == "A reflection of " .. person .. " blinks out of existence." 
		or multimatches[3][1] == person .. " moves into your attack, knocking your blow aside before viciously countering with a strike to your head." 
		or multimatches[3][1] == person .. " twists his body out of harm's way."
		or multimatches[3][1] == person .. " twists her body out of harm's way."
	then
		if multimatches[3][1] == person .. " parries the attack with a deft manoeuvre." then
      if numbedLeft then killTimer(numbRight) end
      tAffs.numbedleftarm = nil
      ataxiaTemp.parriedLimb = ataxiaTemp.lastLimbHit
      cecho("<green> -> "..ataxiaTemp.parriedLimb)       
		end 
else

if bardtempo == "front" then
  tarAffed("nausea")
elseif bardtempo == "side" then
  tarAffed("asthma")
elseif bardtempo == "back" then
  tarAffed("anorexia")
end
if bardsunset == true then
  tarAffed("asthma")
end
end



bardtemposequence = bardtemposequence + 1



