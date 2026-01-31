--[[mudlet
type: script
name: DISPTACH PRIOS
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- MONK
- SHIKUDO
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--


  function dispatch_base_priosGROUP()
  
  
preplimb = preplimb or "right leg"
shistick = {}

if tAffs.prone or tAffs.paralysis then ataxiaTemp.parriedLimb = "none" end


 
 
-- TYKONOS --
-- THRUST, SWEEP, RISINGKICK
-- WILLOW



if ataxia.vitals.form == "Tykonos" then

 table.insert(shistick,"sweep")
 shikick = "risingkick head"
 end






-- WILLOW --
-- DART, SWEEP, HIRU, FLASHHEEL, HIRAKU
-- RAIN



if ataxia.vitals.form == "Willow" then



shikick = "flashheel left"


 
  table.insert(shistick,"hiraku")
  table.insert(shistick,"hiru")
 



end
 
 
  -- OAK --
-- LIVESTRIKE, NERVESTRIKE, RUKU, RISINGKICK, KURO
-- WILLOW GAITAL


if ataxia.vitals.form == "Oak" then

    shikick = "risingkick torso"


if (ataxiaTemp.parriedLimb ~= "head" or ataxiaTemp.hyperLimb == "head") then
      table.insert(shistick,"nervestrike")
end




if not tAffs.asthma then
      table.insert(shistick,"livestrike")
end

if not tAffs.slickness and (tAffs.paralysis or shistick[1] == "nervestrike") then
        table.insert(shistick,"ruku torso")
end


if tAffs.slickness and tAffs.asthma then

       table.insert(shistick,"kuro left")
       table.insert(shistick,"kuro left")

end

if  tAffs.weariness and tAffs.lethargy then 

  table.insert(shistick,"ruku left")
    table.insert(shistick,"ruku left")
      
end


 end
-- RAIN --
-- RUKU, KURO, HIRU, FRONTKICK
-- TYKONOS OAK



 if ataxia.vitals.form == "Rain" then
 

if  (ataxiaTemp.parriedLimb ~= "left arm" or ataxiaTemp.hyperLimb == "left arm") then
  shikick = "frontkick left"
  end
if (ataxiaTemp.parriedLimb == "left arm" or ataxiaTemp.hyperLimb ~= "left arm") then
shikick = "frontkick right" 
 end
 



if tAffs.asthma and not tAffs.weariness and not tAffs.slickness then

       table.insert(shistick,"kuro left")
        table.insert(shistick,"ruku torso")

end

if not tAffs.weariness and not tAffs.lethargy then

       table.insert(shistick,"kuro left")
       table.insert(shistick,"kuro left")

end

if  tAffs.weariness and tAffs.lethargy then


  table.insert(shistick,"ruku left")
         table.insert(shistick,"ruku right")
end


   
end


dispatch_base_attackGROUP()


end

