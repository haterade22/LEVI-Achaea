local person = multimatches[1][3]
local maybemiss = multimatches[3][1]

if isTargeted(person) then
if not wearicheck and haveAff("weariness") then
erAff("weariness")
end
  targetIshere = true
  tAffs.shield = false

	ataxiaTemp.ignoreShield = false
if gmcp.Char.Status.class == "Runewarden" then
    if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
     local affstruck = envenomList[1]
			table.remove(envenomList, 1)
			moveCursorEnd()
       if partyrelay then send("pt "..target..": "..affstruck)
      end
    end
  end
	if gmcp.Char.Status.class == "Infernal" then
    if invest ~= "agony" then
    envenomList = {}
    else
		if next(envenomList) then
			moveCursor(0, getLineNumber()-1)
			tarAffed(envenomList[1])
     local affstruck = envenomList[1]
			table.remove(envenomList, 1)
			moveCursorEnd()
       if partyrelay then send("pt "..target..": "..affstruck)
         end
		    end
	   end
    end
  end

if swordneed[1] == "combination "..target.." slice "..targetlimb.." gecko "..shieldneed[1]..";shieldstrike "..target.." low" or "combination "..target.." slice gecko "..shieldneed[1]..";shieldstrike "..target.." low"
then
paraslick = true
else paraslick = false
end
