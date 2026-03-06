if gmcp.Char.Status.class == "Infernal" then
    if saffliction ~= "none" then
  
		tarAffed(saffliction)
		if applyAffV3 then applyAffV3(saffliction) end
    if partyrelay then send("pt "..target..": "..saffliction)
    end
		  
	  end

end
 

