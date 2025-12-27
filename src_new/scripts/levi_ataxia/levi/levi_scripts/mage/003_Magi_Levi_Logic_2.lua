--[[mudlet
type: script
name: Magi Levi Logic 2
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

tarAblaze = 0 --tAffs.burns?
targetlostfrost = false --tAffs.nocaloric
twaterbond = false
timmolation = false
magi.firestorm = false
tAffs.burns = 0





--Air:
--Minor resonance: gives asthma.
--Moderate resonance: gives sensitivity.
--Major resonance: gives healthleech.

--Earth:
--Minor resonance: breaks a random limb (it will always pick an unbroken limb).
--Moderate resonance: stuns the target for a short time and gives paralysis.
--Major resonance: gives cracked ribs (it does not increase the number of cracked ribs a target has - only ever gives the base affliction).

--Fire:
--Minor resonance: both strips and gives an effect which prevents the raising of the temperance defence.
--Moderate resonance: scalds the target. If the target is already scalded, sets the target ablaze and deals some damage.
--Major resonance: gives the blistered affliction. If they're already blistered, gives a stack of the ablaze affliction.

--Water:
--Minor resonance: gives the frostbite affliction. If it is already present, does some damage.
--Moderate resonance: gives the stuttering affliction and deals some cold damage.
-- Major resonance: gives the anorexia affliction.


function MagiWaterFocus()
get_resonance() --Use this in Aliases

local atk = combatQueue()

if php <= 25 and ataxiaNDB.players[target].city == "Mhaldor" then
  send("Stormhammer") 
elseif php <= 25 then
  atk = "cast stormhammer at " ..target
end

--if not tAffs.waterbond or not tAffs.blistered then
 -- atk = " staffcast horripilation at " ..target
--end

if tAffs.frozen and tAffs.hypothermia then
    atk = " cast glaciate at " ..target
  elseif tAffs.frozen and not tAffs.hypothermia then
    atk = " cast hypothermia at " ..target
  elseif tAffs.shivering and tAffs.nausea and not tAffs.frozen then
    atk = " cast dehydrate at " ..target
  elseif tAffs.shivering then
   atk = "cast dehydrate at " ..target 
  elseif magi.resonance.water == 0 and magi.resonance.fire == 2 and magi.resonance.earth <= 1 then
    atk = "cast dehydrate at " ..target 
  elseif magi.resonance.water == 3 and magi.resonance.fire == 2 and magi.resonance.earth <= 1 then
    atk = "cast emanation at " ..target.. " water"
  elseif tAffs.calcifiedskull and magi.resonance.water == 3 and magi.resonance.earth == 1 then
    atk = "cast dehydrate at " ..target 
  elseif tAffs.calcifiedskull and magi.resonance.water == 3 and magi.resonance.earth == 0 then
    atk = "cast mudslide at " ..target 
  --CalcifySkull - Take that Restoration
  elseif tAffs.scalded and magi.resonance.water == 3 and magi.resonance.earth == 3 and timmolation == false then
    atk = "staff cast scintilla at " ..target
  elseif not tAffs.scalded and magi.resonance.water == 3 and magi.resonance.earth == 3 and timmolation == false and magi.resonance.fire < 1 then
    atk = "cast magma at" ..target
  elseif not tAffs.scalded and magi.resonance.water == 3 and magi.resonance.earth == 3 and timmolation == false and magi.resonance.fire > 1 then
    atk = "cast fulminate at" ..target
  elseif magi.resonance.water == 3 and magi.resonance.earth == 3 then
    atk = "cast emanation at " ..target.. " earth"
  --Cracked Ribs and Asthma
  elseif magi.resonance.water == 3 and magi.resonance.earth == 2 then
    atk = "cast bombard at " ..target
  -- Prone | Slickness | Paralysis | Anorexia | Fulminated 
  elseif magi.resonance.water == 2 and magi.resonance.earth == 1 and magi.resonance.air == 1 then
    atk = "cast mudslide at " ..target
  -- Prone | Slickness | Break Random Limb | Stuttering 
  elseif magi.resonance.water == 2 and magi.resonance.earth == 1 and magi.resonance.fire == 1 then
    atk = "cast fulminate at " ..target
  elseif magi.resonance.water == 1 and magi.resonance.earth == 0 then
    atk = "cast mudslide at " ..target
  elseif magi.resonance.water == 0 then
    atk = "cast dehydrate at " ..target
  else 
    atk = "highfive " ..target
    
end

  
  
--ATTACK
if tAffs.shield then
send("queue addclear freestand wield shield;wield staff569815; cast erode at " ..target.. " ;assess " ..target)
else
send("queue addclear freestand wield shield;wield staff569815; " ..atk.. " ;assess " ..target)
end

end

function MagiFireNew()
get_resonance() 
local atk = combatQueue()


  --If target has a shield, remove it
  if tAffs.shield then
   atk = atk.." cast erode at " .. target .. " shield"
  -- If target has 25 percent health, Stormhammer
  elseif php <= 25 and ataxiaNDB.players[target].city ~= "Mhaldor" then
    atk = atk.." cast stormhammer at " .. target
  -- If burning is 2 or greater and conflagrate is true than stack burning
  elseif tburns >= 2 and tAffs.conflagrate then
        --If I have ashbeast and target is 40 percent or below, kill
      if php <= 40 and ashbeast == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
       atk = atk.." elemental destroy " .. target
        -- If fire is 0 than Firelash to get Fire up
      elseif magi.resonance.fire == 0 then
        atk = atk.." cast firelash at " .. target
        -- If fire is 3 than emanation for 2 burning
      elseif magi.resonance.fire == 3 then
        atk = atk.." cast emanation at " .. target .. " fire"
        -- If target has weariness than cast dehydrate at them for burning
      elseif tAffs.weariness then
        atk = atk.." cast dehydrate at " ..target 
        --If none of the above are true than magma 
      else
       atk = atk.." cast magma at " .. target
      end
  --if I have burning at 2 and fire and air at 2 than conflagrate
  elseif tburns >= 2 and not tAffs.conflagrate and magi.resonance.fire >= 2 and magi.resonance.air >= 2 then
      atk = atk.." cast conflagrate at " ..target
  --if I dont cast fulminate to get air and fire
  elseif tburns >= 2 and not tAffs.conflagrate and magi.resonance.fire < 2 and magi.resonance.air < 2 then
      atk = atk.." cast fulminate at " ..target
  --if I dont have magi.firestorm than get it
  elseif not magi.firestorm then
    if magi.resonance.air >= 2 and magi.resonance.fire >= 2 then
      atk = atk.." cast firestorm"
    else
      atk = atk.." cast fulminate at " .. target
    end
  -- Get burning on target
  --Get scalded
  elseif not tAffs.scalded then
    atk = atk.." cast magma at " ..target
  elseif magi.resonance.fire == 3 then
    atk = atk.." cast emanation at " ..target.. " fire"
  elseif tAffs.healthleech or tAffs.clumsiness or tAffs.asthma or tAffs.sensitivity then
    atk = atk.." cast dehydrate at " ..target
  -- Stack Burning with Dehydrate
  elseif tAffs.weariness then
    atk = atk.." cast dehydrate at " ..target
  elseif magi.resonance.air == 3 then
    atk = atk.." cast emanation at " ..target.. " air"
  elseif magi.resonance.earth == 2 and not magi.shalestorm then
    atk = atk.." cast shalestorm at " ..target
  elseif magi.resonance.earth == 1 then
    atk = atk.." cast bombard at " ..target
  elseif magi.resonance.earth == 0 then
    atk = atk.."cast mudslide at " ..target
  elseif tburns < 2 then
    atk = atk.."cast fulminate at " ..target
  
end  
 
 
 --ATTACK
if tAffs.shield then
  send("queue addclear freestand wield right shield;wield left staff569815; cast erode at " ..target.. " ;assess " ..target)
else
  send("queue addclear freestand wield right shield;wield left staff569815; " ..atk.. " ;assess " ..target)
end
end



function MagiSalveFocus()
getLockingAffliction()
checkTargetLocks()
get_resonance() --Use this in Aliases

local atk = combatQueue()

if checkAffList({"asthma", "clumsiness", "healthleech", "sensitivity"},2) then
	local	tkelpstack = true
  else
  tkelpstack = false
end




--if not tAffs.waterbond or not tAffs.blistered then
 -- atk = " staffcast horripilation at " ..target
--end

 --If target has a shield, remove it
  if tAffs.shield then
   atk = atk.." cast erode at " .. target .. " shield"
  -- If target has 25 percent health, Stormhammer
  elseif php <= 25 and ataxiaNDB.players[target].city ~= "Mhaldor" then
    atk = atk.." cast stormhammer at " .. target
  -- If burning is 2 or greater and conflagrate is true than stack burning
  elseif tburns >= 2 and tAffs.conflagrate then
        --If I have ashbeast and target is 40 percent or below, kill
      if php <= 40 and ashbeast == true and ataxiaNDB.players[target].city ~= "Mhaldor" then
       atk = atk.." elemental destroy " .. target
        -- If fire is 0 than Firelash to get Fire up
      elseif magi.resonance.fire == 0 then
        atk = atk.." cast firelash at " .. target
        -- If fire is 3 than emanation for 2 burning
      elseif magi.resonance.fire == 3 then
        atk = atk.." cast emanation at " .. target .. " fire"
        -- If target has weariness than cast dehydrate at them for burning
      elseif tAffs.weariness then
        atk = atk.." cast dehydrate at " ..target 
        --If none of the above are true than magma 
      else
       atk = atk.." cast magma at " .. target
      end
  --if I have burning at 2 and fire and air at 2 than conflagrate
  elseif tburns >= 2 and not tAffs.conflagrate and magi.resonance.fire >= 2 and magi.resonance.air >= 2 then
      atk = atk.." cast conflagrate at " ..target
  --if I dont cast fulminate to get air and fire
  elseif tburns >= 2 and not tAffs.conflagrate and magi.resonance.fire < 2 and magi.resonance.air < 2 then
      atk = atk.." cast fulminate at " ..target 
  elseif tkelpstack == true then
    atk = atk.. "cast dehydrate at " ..target
  elseif tAffs.calcifiedskull and magi.resonance.fire == 3 and tfirelash == false then
    atk = atk.. "cast emanation at " ..target.. " fire"
  --Conflag
  elseif tAffs.calcifiedskull and tfirelash == true then
    atk = atl.. "cast conflagerate at " ..target
  --Get Ablaze Two
  elseif tAffs.calcifiedskull then
    atk = atk.. "cast firelash at " ..target 
  --CalcifySkull - Take that Restoration
  elseif magi.resonance.earth == 3 and tAffs.scalded and timmolation == true then
    atk = atk.. "cast emanation at " ..target.. " earth"
  elseif tAffs.scalded and magi.resonance.earth == 3 and timmolation == false then
    atk = atk.. "staff cast scintilla at " ..target
  elseif not tAffs.scalded and magi.resonance.earth == 3 and timmolation == false and magi.resonance.fire > 2 then
    atk = atk.. "cast magma at" ..target
  elseif not tAffs.scalded and magi.resonance.earth == 3 and timmolation == false and magi.resonance.fire == 1 then
    atk = atk.. "cast dehydrate at" ..target
  elseif not tAffs.scalded and magi.resonance.earth == 3 and timmolation == false and magi.resonance.fire > 1 then
    atk = atk.. "cast fulminate at" ..target
  elseif magi.resonance.earth == 2 and magi.resonance.water == 1 then
     atk = atk.. "cast bombard at" ..target
  elseif magi.resonance.earth == 1 and magi.resonance.fire == 3 and magi.resonance.water == 0 then
     atk = atk.. "cast mudslide at" ..target
  elseif magi.resonance.earth == 0 and magi.resonance.fire == 2 and magi.firestormm == true then
    atk = atk.. "cast magma at" ..target
 elseif not magi.firestorm then
    if magi.resonance.air >= 2 and magi.resonance.fire >= 2 then
      atk = atk.." cast firestorm"
    else
      atk = atk.." cast fulminate at " .. target
    end
  
  else 
    atk = atk.. "highfive " ..target
    
end

  
  
--ATTACK
if tAffs.shield then
send("queue addclear freestand wield shield;wield staff569815; cast erode at " ..target.. " ;assess " ..target)
else
send("queue addclear freestand wield shield;wield staff569815; " ..atk.. " ;assess " ..target)
end

end

