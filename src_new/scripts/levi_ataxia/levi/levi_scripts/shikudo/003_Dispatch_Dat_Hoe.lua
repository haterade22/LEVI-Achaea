--[[mudlet
type: script
name: Dispatch Dat Hoe
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Shikudo Script - Levi
- Shikudo
attributes:
  isActive: 'no'
  isFolder: 'no'
packageName: ''
]]--

function dispatchdatass()
-- If using Romaen's Limb Counter then the limb prep will be if lb[target].hits["right leg"] >= 90
-- Lowest Damage Point is 10.1 damage per limb

-- For dispatch we will need prone, level 2 head and needle. So at the very least it would be break right leg in oak, switch to gaital, Break second leg/prone/, Spinkick break head/needle, dispatch

--All variables for Dispatch are true
sform = ""

if affstrack.score.prone >= 100 and (lb[target].hits["head"] >= 100) and tneedle >= 50 then
tdispatch = true
--Target is prone, but head is not broke nor crushedthroat, this needs to be done in gaital form and parry doesn't matter because of prone
elseif affstrack.score.prone >= 100 and (lb[target].hits["head"] < 100) and tneedle <= 50 then
aneedle = true
aspinkick = true
-- We broke left level 2 before
akuroright = true
sform = "gaital"
--If Target is NOT prone, but both legs and head are prepped and parry doesn't matter due to sweep. This has to be done in Gaital form as Oak form doesn't have a prone ability
elseif affstrack.score.prone<100 and (lb[target].hits["right leg"] >= 90 or lb[target].hits["left leg"] >= 90 and lb[target].hits["head"] >= 90) then
asweep = true
-- Break Left First
aflashheelleft = true
sform = "gaital"
elseif (lb[target].hits["right leg"] <= 89 and lb[target].hits["left leg"] <= 89 and lb[target].hits["head"] <= 90) then


  end
end

-- We may want to just manual the prep 
-- without a target parrying
-- Spinkick gives 40 percent limb damage to head when on ground -- only need to prep head to 60 before spinkick

-- Willow gives me 3 full combos - at the end 61.8 Head and 42 Left Leg | combo totto flashheel left hiru hiraku x 3 | transition at 9 to rain

-- Rain gives me 8 Full combos (if you want) - at the end Head 97.2 and Left Leg 94.5 and right leg 60
-- combo totto flashheel left hiru  x 1 for Head
-- combo aegoth frontkick left kuro left kuro left
-- combo aegoth frontkick left kuro right kuro right x 3