if not tAffs.clumsiness then
  tarAffed("clumsiness")
  if applyAffV3 then applyAffV3("clumsiness") end
   if partyrelay then send("pt "..target..": clumsiness") end
   
end

tempTimer(2.5, [[tarAffed("clumsy"; if applyAffV3 then applyAffV3("clumsy") end]])