-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Wings and other fast travel > Aetolia

registerAnonymousEventHandler("mmp link externals", "mmp.addWingsAetolia")



function mmp.addWingsAetolia()
  if mmp.game ~= "aetolia" then return end
  
  --Check plane / continent
  if mmp.aetoliaPlane == "the Prime Material Plane" and mmp.aetoliaContinent == "the Continent of Sapience" and
  --health check
  tonumber(gmcp.Char.Vitals.hp)/tonumber(gmcp.Char.Vitals.maxhp)>.95 and 
  --mana check
  tonumber(gmcp.Char.Vitals.mp)/tonumber(gmcp.Char.Vitals.maxmp)>.95 then
  
      --eagle wings
      if mmp.settings.duanathar or mmp.settings.duanatharan then
        mmp.tempSpecialExit(3885, "say duanathar")
      end
      --atavian wings
      if mmp.settings.duanatharan then
        mmp.tempSpecialExit(4882, "say duanatharan")
      end
      
      if mmp.settings.voltda or mmp.settings.voltdaran then
        mmp.tempSpecialExit(19911,"say voltda")
      end
      
      if mmp.settings.voltdaran then
        mmp.tempSpecialExit(19912,"say voltdaran")
      end
      
      
  
  end
end