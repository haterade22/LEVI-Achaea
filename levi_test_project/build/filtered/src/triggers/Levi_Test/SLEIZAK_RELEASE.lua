tarAffed("weariness")
  if applyAffV3 then applyAffV3("weariness") end
  if not tAffs.nausea then
  tarAffed("nausea")
  if applyAffV3 then applyAffV3("nausea") end
  if partyrelay then send("pt "..target..": nausea")
      end
  else 
    tarAffed("voyria")
    if applyAffV3 then applyAffV3("voyria") end
     if partyrelay then send("pt "..target..": voyria")
      end
    end
    
