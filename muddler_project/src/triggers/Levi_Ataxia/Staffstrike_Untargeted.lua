local element = multimatches[1][2]
local person = multimatches[1][3]
local maybemiss = multimatches[3][1]
local water = {"nocaloric", "shivering", "frozen"}
local aff = false

if isTargeted(person) then
  targetIshere = true
	if maybemiss == person .. " dodges nimbly out of the way." 
		or maybemiss == person .. " quickly jumps back, avoiding the attack." 
		or maybemiss == "A reflection of " .. target .. " blinks out of existence." 
	then
		--Do nothing, because it didn't hit.
	elseif maybemiss == "The attack rebounds onto you!" then
		tAffs.rebounding = true
		selectString(line, 1)
		fg("yellow")
		resetFormat()
	else
		if element == "Sllshya" then
      for _, step in pairs(water) do
        if not haveAff(step) then
          aff = step
          break
        end
      end
      if not aff then aff = "frozen" end 
    elseif element == "Kkractle" then
      aff = "ablaze"    
    end
    
    if aff then
      moveCursor(0, getLineNumber()-1)
			tarAffed(aff)
			moveCursorEnd() 
    end
		tAffs.rebounding = false
		tAffs.shield = false
	end
  tempTimer(0.7, [[ if tempGarash then tempGarash = nil end ]])  
end