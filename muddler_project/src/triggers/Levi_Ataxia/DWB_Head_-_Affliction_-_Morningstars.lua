if target == matches[2] then
  if wieldweapons == "morningstars" then
      if not tAffs.unblind then
        tarAffed("unblind")
        if partyrelay then send("pt "..target..": unblind") end
      end
      if tAffs.prone then
       tarAffed("unblind")
        if ataxiaTemp.fractures.skullfractures == 0 or ataxiaTemp.fractures.skullfractures == nil then
          ataxiaTemp.fractures.skullfractures = 1
          twohanded_headHit()
        else
         ataxiaTemp.fractures.skullfractures = ataxiaTemp.fractures.skullfractures + 1
        ataxiaTemp.fractures.skullfractures = math.min(7, ataxiaTemp.fractures.skullfractures + 1)
         twohanded_headHit()
        end
         if partyrelay and not ataxia.afflictions.aeon  then send("pt "..target..": prone") end
         if partyrelay and not ataxia.afflictions.aeon  then send("pt "..target..": unblind and " ..ataxiaTemp.fractures.skullfractures.. " skullfractures") end
      end
  end
end