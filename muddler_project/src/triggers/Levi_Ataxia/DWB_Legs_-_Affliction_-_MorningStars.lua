if target == matches[2] then
  if wieldweapons == "morningstars" then
      if not tAffs.lethargic then
        tarAffed("lethargy")
        if applyAffV3 then applyAffV3("lethargy") end
       if partyrelay then send("pt "..target..": prone and lethargy") end
   
      end
      tarAffed("prone")
      if applyAffV3 then applyAffV3("prone") end
  end
end