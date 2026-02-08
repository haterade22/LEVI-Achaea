if not tAffs.healhleech then
  tarAffed("healthleech")
  if applyAffV3 then applyAffV3("healthleech") end
   if partyrelay then send("pt "..target..": healthleech") end
   
end

tempTimer(2.5, [[tarAffed("healthleech"; if applyAffV3 then applyAffV3("healthleech") end]])