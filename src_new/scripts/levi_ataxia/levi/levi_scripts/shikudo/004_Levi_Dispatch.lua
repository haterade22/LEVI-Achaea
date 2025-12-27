--[[mudlet
type: script
name: Levi Dispatch
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

function levishikudodispatch()
--Get Stance
shikudostance = string.match(gmcp.Char.Vitals.charstats[4],"Form\: (%w+)")
--Get Kata Chain
katachain = tonumber(string.match(gmcp.Char.Vitals.charstats[5],"Kata\: (%d+)"))

--Call Other Functions
kickshikudoattack()
shikudostaffstrike()
shikudostafftwo()

-- If using Romaen's Limb Counter then the limb prep will be if lb[target].hits["right leg"] >= 90
-- Lowest Damage Point is 10.1 damage per limb

-- For dispatch we will need prone, level 2 head and needle. So at the very least it would be break right leg in Oak, switch to Gaital, Break second leg/prone/, Spinkick break head/needle, dispatch
-- Only use spinkick as a level 2 to level 3 break due to balance
if tAffs.shield then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " shatter " ..kicked.. " ;assess " ..target)
--All variables for Dispatch are true
-- We have to check the number for level 3 Head break
elseif shikudostance == "Gaital" and tAffs.prone and (lb[target].hits["head"] >= 100 or tAffs.damagedhead) and tneedle >= 50 then
send("queue addclear free stand;stand;wield staff489282;dispatch " ..target)
--Target is prone, but head is not broke nor crushedthroat, this needs to be done in Gaital form and parry doesn't matter because of prone
-- Needle is 18 Head Damage for me
elseif shikudostance == "Gaital" and tAffs.prone and (lb[target].hits["head"] >= 70 ) and tneedle <= 50 then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " needle needle spinkick ;assess " ..target)

-- If target is prone and one leg is level 2. The other limb is prepped and head is prepped
elseif shikudostance == "Gaital" and tAffs.prone and (lb[target].hits["right leg"] >= 89 and lb[target].hits["left leg"] <= 100) and (lb[target].hits["head"] >= 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " needle kuro right flashheel right ;assess " ..target)
elseif shikudostance == "Gaital" and tAffs.prone and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] <= 100) and (lb[target].hits["head"] >= 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " needle kuro left flashheel left ;assess " ..target)

--If Target is NOT prone, one leg is broke and one is prepped legs and head are prepped and parry doesn't matter due to sweep. This has to be done in Gaital form as Oak form doesn't have a prone ability
elseif shikudostance == "Gaital" and not tAffs.prone and (lb[target].hits["left leg"] >= 100 and lb[target].hits["right leg"] >= 89 ) and (lb[target].hits["head"] >= 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " sweep flashheel right ;assess " ..target)
--If Target is NOT prone, but both legs and head are prepped and parry doesn't matter due to sweep. This has to be done in Gaital form as Oak form doesn't have a prone ability
elseif shikudostance == "Gaital" and not tAffs.prone and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] >= 89 ) and (lb[target].hits["head"] >= 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " sweep flashheel right ;assess " ..target)
-- IF Oak Stance and all limbs are prepped and kata is higher than 5 then transition
elseif shikudostance == "Oak" and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] >= 89 ) and (lb[target].hits["head"] >= 89) and katachain >= 5 then
send("queue addclear free stand;stand;wield staff489282;transition to the Gaital form;combo " ..target.. " sweep flashheel left ;assess " ..target)
-- If Oak Stance and we will need a limb but have to transition
elseif shikudostance == "Oak" and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] >= 89 ) and (lb[target].hits["head"] <= 89) and katachain >= 10 then
send("queue addclear free stand;stand;wield staff489282;transition to the Gaital form;combo " ..target.. " needle ruku left flashheel left ;assess " ..target)

-- Nervestrike is head damage
elseif shikudostance == "Oak" and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] <= 77) and (lb[target].hits["head"] < 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " kuro right kuro right risingkick head;assess " ..target)
elseif shikudostance == "Oak" and (lb[target].hits["left leg"] <= 77 and lb[target].hits["right leg"] >= 89) and (lb[target].hits["head"] < 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " kuro left kuro left risingkick head;assess " ..target)
elseif shikudostance == "Oak" and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] <= 80) and (lb[target].hits["head"] >= 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " livestrike kuro right risingkick torso;assess " ..target)
elseif shikudostance == "Oak" and (lb[target].hits["left leg"] <= 80 and lb[target].hits["right leg"] >= 89) and (lb[target].hits["head"] >= 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " livestrike kuro left risingkick torso;assess " ..target)
elseif shikudostance == "Oak" and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] >= 89) and (lb[target].hits["head"] <= 70) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " nervestrike ruku torso risingkick head;assess " ..target)
elseif shikudostance == "Oak" and (lb[target].hits["left leg"] < 89 and lb[target].hits["right leg"] < 89) and (lb[target].hits["head"] < 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " kuro right kuro left risingkick head;assess " ..target)
elseif shikudostance == "Oak" and (lb[target].hits["head"] <= 50) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " livestrike livestrike risingkick head;assess " ..target)
elseif shikudostance == "Oak" and (lb[target].hits["head"] <= 88) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " livestrike nervestrike risingkick torso;assess " ..target)
-- If Rain stance and not prepped and at 24 kata
elseif shikudostance == "Rain" and (lb[target].hits["left leg"] <= 89 or lb[target].hits["right leg"] <= 89) and (lb[target].hits["head"] <= 89) and katachain >= 22 then
send("queue addclear free stand;stand;wield staff489282;transition to the Oak form;combo " ..target.. " nervestrike nervestrike risingkick head ;assess " ..target)
--if Rain Stance and all everything is met and kata at 5
elseif shikudostance == "Rain" and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] >= 89) and (lb[target].hits["head"] >= 89) and katachain >= 5 then
send("queue addclear free stand;stand;wield staff489282;transition to the Oak form;combo " ..target.. " livestrike livestrike risingkick torso ;assess " ..target)
--if Rain Stance Legs and Head Not Prepped Do it
elseif shikudostance == "Rain" and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] <= 70) and (lb[target].hits["head"] < 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " frontkick left kuro right kuro right ;assess " ..target)
elseif shikudostance == "Rain" and (lb[target].hits["left leg"] <= 75 and lb[target].hits["right leg"] >= 89) and (lb[target].hits["head"] < 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " frontkick right kuro left kuro left;assess " ..target)
elseif shikudostance == "Rain" and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] <= 80) and (lb[target].hits["head"] >= 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " frontkick left ruku torso kuro right;assess " ..target)
elseif shikudostance == "Rain" and (lb[target].hits["left leg"] <= 80 and lb[target].hits["right leg"] >= 89) and (lb[target].hits["head"] >= 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " frontkick left ruku torso kuro left;assess " ..target)
elseif shikudostance == "Rain" and (lb[target].hits["left leg"] >= 89 and lb[target].hits["right leg"] >= 89) and (lb[target].hits["head"] <= 70) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " frontkick left hiru hiru ;assess " ..target)
elseif shikudostance == "Rain" and (lb[target].hits["left leg"] < 89 and lb[target].hits["right leg"] < 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " frontkick left kuro right kuro left ;assess " ..target)
elseif shikudostance == "Rain" and (lb[target].hits["head"] < 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " frontkick left hiru hiru;assess " ..target)


-- If Willow Stance and at 10 or above kata
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] < 89) and (lb[target].hits["right leg"] < 89) and (lb[target].hits["head"] < 89) and katachain >= 10 then
send("queue addclear free stand;stand;wield staff489282;transition to the Rain form;combo " ..target.. " kuro right kuro left frontkick left;assess " ..target)
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] < 89) and (lb[target].hits["right leg"] < 89) and (lb[target].hits["head"] > 89) and katachain >= 10 then
send("queue addclear free stand;stand;wield staff489282;transition to the Rain form;combo " ..target.. " kuro right kuro left frontkick left;assess " ..target)
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] < 89) and (lb[target].hits["right leg"] < 89) and katachain >= 10 then
send("queue addclear free stand;stand;wield staff489282;transition to the Rain form;combo " ..target.. " kuro right kuro left frontkick left;assess " ..target)
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] > 89) and (lb[target].hits["right leg"] > 89) and (lb[target].hits["head"] > 70) and katachain >= 10 then
send("queue addclear free stand;stand;wield staff489282;transition to the Rain form;combo " ..target.. " hiru hiru frontkick left;assess " ..target)
elseif shikudostance == "Willow" and  katachain >= 10 then
send("queue addclear free stand;stand;wield staff489282;transition to the Rain form;combo " ..target.. " ruku left ruku left frontkick left;assess " ..target)
--If Willow Stance
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] < 60) and (lb[target].hits["right leg"]) < 60 and (lb[target].hits["head"] > 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " dart right dart right flashheel left;assess " ..target)
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] < 62) and (lb[target].hits["right leg"]) > 89 and (lb[target].hits["head"] > 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " dart left dart left flashheel left;assess " ..target)
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] > 89) and (lb[target].hits["right leg"]) < 62 and (lb[target].hits["head"] > 89) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " dart right dart right flashheel right;assess " ..target)
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] > 89) and (lb[target].hits["right leg"]) < 70 and (lb[target].hits["head"] < 70) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " hiru hiraku flashheel right;assess " ..target)
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] < 70) and (lb[target].hits["right leg"]) > 89 and (lb[target].hits["head"] < 70) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " hiru hiraku flashheel left;assess " ..target)
elseif shikudostance == "Willow" and (lb[target].hits["left leg"] < 88) and (lb[target].hits["right leg"]) < 88 and (lb[target].hits["head"] < 88) then
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " hiru hiraku flashheel left;assess " ..target)

-- Else attack light where I can
else
send("queue addclear free stand;stand;wield staff489282;combo " ..target.. " " ..kicked.. " " ..staff.. " light " ..stafftwo.. " light;assess " ..target)

end

end