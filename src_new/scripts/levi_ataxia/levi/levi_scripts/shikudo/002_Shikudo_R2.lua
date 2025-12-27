--[[mudlet
type: script
name: Shikudo R2
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Shikudo Script - Levi
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

---what is my shikudo stance
shikudostance = shikudostance or ""

--what is my katachain

katachain= 0

--target shield = false



--Make sure to set this in triggers when people parry!
tpla = false
tpll = false
tph = false
tpto = false
tpra = false
tprl = false

-- Set the Kick in the Shikudo Combo per stance
function kickshikudoattack()
kicked = kicked or ""

-- Rain Stance
if shikudostance == "rain" then

 if tpla == false then
 kicked = "frontkick left"
 else
   kicked = "frontkick right"
   end
end

-- Oak Stance
if shikudostance == "oak" then
 if tph == false then
  kicked = "risingkick head"
 else
  kicked = "risingkick torso"
 end
end

--Willow Stance
if shikudostance == "willow" then
 if tpll == false then
  kicked = "flashheel left"
 else
  kicked = "flashheel right"
 end
end

--Gaital Stance
if shikudostance == "gaital" then
  if tAffs.prone then
    kicked = "spinkick"
  elseif tpll == false then
  kicked = "flashheel left"
 else
  kicked = "flashheel right"
  end
end

--Maelstrom Stance
if shikudostance == "maelstrom" then
if tph == false then
  kicked = "risingkick head"
 else
  kicked = "risingkick torso"
 end
 
 --Tykonos
 if shikudostance == "tykonos" then
if tph == false then
  kicked = "risingkick head"
 else
  kicked = "risingkick torso"
 end
end
end
  

-- Set Staff Attack Number One or First Arm Strike
function shikudostaffstrike()
staff = staff or ""

-- Rain Stance
 if shikudostance == "rain" then
 if tAffs.asthma and tpto == false then
  staff = "ruku torso"
 elseif tAffs.weariness and tpll == false then
  staff = "kuro left"
 elseif tAffs.weariness and tpll == true then
  staff = "kuro right"
  
 elseif tAffs.lethargy and tpll == false then
  staff = "kuro left"
 elseif tAffs.lethargy and tpll == true then
  staff = "kuro right"
  
 elseif tAffs.clumsiness and tpla == true then
  staff = "ruku right"
 elseif tAffs.clumsiness and tpla == false then
  staff = "ruku left"
  
 elseif tAffs.healthleech and tpla == false then
  staff = "ruku left"
 elseif tAffs.healthleech  and tpla == true then
  staff = "ruku right"
  
 elseif tAffs.dizziness then
  staff = "hiru"
  
 elseif tAffs.slickness and tpto == false then
  staff = "ruku torso"
 
 else
  staff = "kuro left"
   end
 end
 
 
 if shikudostance == "oak" then
  if tAffs.paralysis then
   staff = "nervestrike"
   
  elseif tAffs.asthma then
   staff = "livestrike"
  
   elseif tAffs.slickness and tpto == false then
   staff = "ruku torso"
   
  elseif tAffs.weariness and tpll == false then
   staff = "kuro left"
  elseif tAffs.weariness and tpll == true then
   staff = "kuro right"
  
  elseif tAffs.lethargy and tpll == false then
   staff = "kuro left"
  elseif tAffs.lethargy and tpll == true then
   staff = "kuro right"
   
  elseif tAffs.clumsiness and tpla == true then
   staff = "ruku right"
  elseif tAffs.clumsiness and tpla == false then
   staff = "ruku left"
      
  elseif tAffs.healthleech and tpla == false then
   staff = "ruku left"
  elseif tAffs.healthleech and tpla == true then
   staff = "ruku right"
  else
   staff = "ruku torso"
  end
 end
 
 if shikudostance == "willow" then
  if tAffs.anorexia  then
   staff = "hiraku"
  elseif tAffs.anorexia then
   staff = "hiraku"
  else
   staff = "hiru"
  end
 end
 
 if shikudostance == "gaital" then
  if tAffs.slickness and tpto == false then
   staff = "ruku torso"
   
  elseif tAffs.weariness and tpll == false then
   staff = "kuro left"
  elseif tAffs.weariness and tpll == true then
   staff = "kuro right"
  
  elseif tAffs.lethargy and tpll == false then
   staff = "kuro left"
  elseif tAffs.lethargy and tpll == true then
   staff = "kuro right"
  elseif tAffs.clumsiness and tpla == true then
   staff = "ruku right"
  elseif tAffs.clumsiness and tpla == false then
   staff = "ruku left"
    
  
  elseif tAffs.healthleech and tpla == false then
   staff = "ruku left"
  elseif tAffs.healthleech and tpla == true then
   staff = "ruku right"
  else
   staff = "needle"
   end
  end
  
 if shikudostance == "maelstrom" then
  if tAffs.asthma then
   staff = "livestrike"
  elseif tAffs.addiction then
   staff = "jinzuku"
  elseif tAffs.slickness then
   staff = "ruku torso"
  elseif tAffs.clumsiness and tpla == true then
   staff = "ruku right"
  elseif tAffs.clumsiness and tpla == false then
   staff = "ruku left"
  elseif tAffs.healthleech and tpla == false then
   staff = "ruku left"
  elseif tAffs.healthleech and tpla == true then
   staff = "ruku right"
  else
   staff = "jinzuku"
  end
 end
end



-- Set Second Staff Attack or Second Arm Balance
function shikudostafftwo()
stafftwo = stafftwo or ""

--Rain Stance
 if shikudostance == "rain" then
 
if tAffs.clumsiness and (staff ~= "ruku right" or staff ~= "ruku left") and tpla == true then
   stafftwo = "ruku right"
  elseif tAffs.clumsiness and (staff ~= "ruku right" or staff ~= "ruku left") and tpla == false then
   stafftwo = "ruku left"
  
  elseif tAffs.lethargy and tpll == false then
   stafftwo = "kuro left"
  elseif tAffs.lethargy and tpll == true then
   stafftwo = "kuro right"
  
  elseif tAffs.healthleech and tpla == false then
   stafftwo = "ruku left"
  elseif tAffs.healthleech and tpla == true then
   stafftwo = "ruku right"
   
elseif tAffs.weariness and (staff ~= "kuro right" or staff ~= "kuro left") and tpll == false then
   stafftwo = "kuro left"
elseif tAffs.weariness and (staff ~= "kuro right" or staff ~= "kuro left") and tpll == true then
   stafftwo = "kuro right"
elseif tAffs.dizziness and staff ~= "hiru" then
   stafftwo = "hiru"
  
elseif tAffs.slickness and staff ~= "ruku torso" and tpto == false then
   stafftwo = "ruku torso"
else
   stafftwo = "ruku torso"
   end
  end
  
if shikudostance == "oak" then
     
  if tAffs.paralysis and staff ~= "nervestrike" then
   stafftwo = "nervestrike"
elseif tAffs.asthma and staff ~= "livestrike" then
   stafftwo = "livestrike"
  
elseif tAffs.slickness and tpto == false and staff ~= "ruku torso" then
   stafftwo = "ruku torso"
   
elseif tAffs.weariness and (staff ~= "kuro right" or staff ~= "kuro left") and tpll == false then
   stafftwo = "kuro left"
elseif tAffs.weariness and (staff ~= "kuro right" or staff ~= "kuro left") and tpll == true then
   stafftwo = "kuro right"

elseif tAffs.lethargy and tpll == false then
   stafftwo = "kuro left"
elseif tAffs.lethargy and tpll == true then
   stafftwo = "kuro right"
   
elseif tAffs.clumsiness and (staff ~= "ruku right" or staff ~= "ruku left") and tpla == true then
   stafftwo = "ruku right"
elseif tAffs.clumsiness and (staff ~= "ruku right" or staff ~= "ruku left") and tpla == false then
   stafftwo = "ruku left"
    
elseif tAffs.healthleech and tpla == false then
   stafftwo = "ruku left"
elseif tAffs.healthleech and tpla == true then
   stafftwo = "ruku right"
 
else
   stafftwo = "ruku torso"
  end
 end
 
if shikudostance == "willow" then
  if tAffs.anorexia and staff ~= "hiraku" then
   stafftwo = "hiraku"
  elseif staff ~= "hiru" then
   stafftwo = "hiru"
  end
 end
 
if shikudostance == "gaital" then
if tAffs.slickness and tpto == false and staff ~= "ruku torso" then
   stafftwo = "ruku torso"
  elseif tAffs.lethargy and tpll == false then
   stafftwo = "kuro left"
  elseif tAffs.lethargy and tpll == true then
   stafftwo = "kuro right"   
elseif tAffs.clumsiness and (staff ~= "ruku right" or staff ~= "ruku left") and tpla == true then
   stafftwo = "ruku right"
elseif tAffs.clumsiness and (staff ~= "ruku right" or staff ~= "ruku left") and tpla == false then
   stafftwo = "ruku left"
    
  
  elseif tAffs.healthleech and tpla == false then
   stafftwo = "ruku left"
  elseif tAffs.healthleech and tpla == true then
   stafftwo = "ruku right"
   
elseif tAffs.weariness and (staff ~= "kuro right" or staff ~= "kuro left") and tpll == false then
   stafftwo = "kuro left"
elseif tAffs.weariness and (staff ~= "kuro right" or staff ~= "kuro left") and tpll == true then
   stafftwo = "kuro right"
else
   stafftwo = "needle"
   end
 end
  
 if shikudostance == "maelstrom" then
  if tAffs.asthma and staff ~= "livestrike" then
   stafftwo = "livestrike"
  elseif tAffs.addiction and staff ~= "jinzuku" then
   stafftwo = "jinzuku"
  elseif tAffs.slickness and staff ~= "ruku torso" then
   stafftwo = "ruku torso"
   
  elseif tAffs.healthleech and tpla == false then
   stafftwo = "ruku left"
  elseif tAffs.healthleech and tpla == true then
   stafftwo = "ruku right"
   
elseif tAffs.clumsiness and (staff ~= "ruku right" or staff ~= "ruku left") and tpla == true then
   stafftwo = "ruku right"
elseif tAffs.clumsiness and (staff ~= "ruku right" or staff ~= "ruku left") and tpla == false then
   stafftwo = "ruku left"
  else
   stafftwo = "jinzuku"
  end
 end

end
end



