if isTargeted(matches[2]) then
	Target_Instill = "degeneration"
if not haveAff("clumsiness") then
  tarAffed("clumsiness")
  if applyAffV3 then applyAffV3("clumsiness") end
      if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and clumsiness") end
      if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and clumsiness") end
elseif tAffs.clumsiness and not tAffs.weariness then
  tarAffed("weariness")
  if applyAffV3 then applyAffV3("weariness") end
      if partyrelay and tloop == false and tloop2 == false then send("pt "..target..": " ..envenomList[1].. " and weariness") end
      if partyrelay and (tloop == true or tloop2 == true) then send("pt "..target..": timeloop and weariness") end
elseif tAffs.clumsiness and tAffs.weariness and not tAffs.paralysis then
  tarAffed("paralysis")
  if applyAffV3 then applyAffV3("paralysis") end
end
end
