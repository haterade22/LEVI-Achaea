if not tAffs.asthma then
  tarAffed("asthma")
  if applyAffV3 then applyAffV3("asthma") end
   if partyrelay then send("pt "..target..": asthma") end

end


tempTimer(2.5, [[tarAffed("asthma"); if applyAffV3 then applyAffV3("asthma") end]])