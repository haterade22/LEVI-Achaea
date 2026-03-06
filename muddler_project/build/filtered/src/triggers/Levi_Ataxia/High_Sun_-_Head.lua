local person = target

if multimatches[3][1] == "The attack rebounds back onto you!" then
  tarAffed("rebounding")
  if applyAffV3 then applyAffV3("rebounding") end
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
  if tAffs.clumsiness and tAffs.weariness then
    tarAffed("recklessness")
    if applyAffV3 then applyAffV3("recklessness") end
  elseif tAffs.clumsiness and not tAffs.weariness then
    tarAffed("weariness")
    if applyAffV3 then applyAffV3("weariness") end
  elseif not tAffs.clumsiness then
    tarAffed("clumsiness")
    if applyAffV3 then applyAffV3("clumsiness") end
  end
elseif bardtempo == "side" then
  if tAffs.addiction and tAffs.generosity then
    tarAffed("confusion")
    if applyAffV3 then applyAffV3("confusion") end
  elseif tAffs.addiction and not tAffs.generosity then
    tarAffed("generosity")
    if applyAffV3 then applyAffV3("generosity") end
  elseif not tAffs.addiction then
    tarAffed("addiction")
    if applyAffV3 then applyAffV3("addiction") end
  end
elseif bardtempo == "back" then
  if tAffs.paralysis and tAffs.generosity and not tAffs.diminished then
    tarAffed("diminished")
    if applyAffV3 then applyAffV3("diminished") end
  elseif tAffs.paralysis and not tAffs.generosity then
    tarAffed("generosity")
    if applyAffV3 then applyAffV3("generosity") end
  elseif not tAffs.paralysis then
    tarAffed("paralysis")
    if applyAffV3 then applyAffV3("paralysis") end
  end
end
end


bardtemposequence = bardtemposequence + 1

