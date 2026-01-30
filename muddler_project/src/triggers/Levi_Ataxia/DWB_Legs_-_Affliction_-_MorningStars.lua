if target == matches[2] then
  if wieldweapons == "morningstars" then
      if not tAffs.lethargic then
        tarAffed("lethargy")
       if partyrelay then send("pt "..target..": prone and lethargy") end
   
      end
      tarAffed("prone")
  end
end