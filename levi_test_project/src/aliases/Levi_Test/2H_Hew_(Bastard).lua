twohandlogic()

-- Raze Attacks/Carve
if (targreb == true) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|envenom bastard with epseth|battlefury perceive " ..target.. " |carve " ..target.. " |battlefury upset " ..target.. " |assess " ..target)
elseif (targreb == true) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|envenom bastard with epseth|discipline|battlefury perceive " ..target.. " |carve " ..target.. " |battlefury upset " ..target.. " |assess " ..target)
elseif (targreb == false) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|envenom bastard with epseth|battlefury perceive " ..target.. " |carve " ..target.. " |battlefury upset " ..target.. " |assess " ..target)
elseif (targreb == false) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|envenom bastard with epseth|discipline|battlefury perceive " ..target.. " |carve " ..target.. " |battlefury upset " ..target.. " |assess " ..target)
elseif (targreb == true) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|envenom bastard with epseth|battlefury perceive " ..target.. " |carve " ..target.. " |battlefury upset " ..target.. " |assess " ..target)
elseif (targreb == true) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|envenom bastard with epseth|discipline|battlefury perceive " ..target.. " |carve " ..target.. " |battlefury upset " ..target.. " |assess " ..target)
-- Left Leg
elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "exploit" then -- exploit
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |hew " ..target.. " left leg|assess " ..target)
elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) and evenom1 == "exploit" then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " left leg|assess " ..target)

elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |hew " ..target.. " left leg|assess " ..target)
elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " left leg|assess " ..target)

elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |hew " ..target.. " left leg|assess " ..target)
elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |discipline|hew " ..target.. " left leg|assess " ..target)

--Right Leg

elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "exploit" then -- exploit
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |hew " ..target.. " right leg|assess " ..target)
elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) and evenom1 == "exploit" then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right leg|assess " ..target)

elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |hew " ..target.. " right leg|assess " ..target)
elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right leg|assess " ..target)

elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |hew " ..target.. " right leg|assess " ..target)
elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |discipline|hew " ..target.. " right leg|assess " ..target)

--Right Arm
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "exploit" then -- exploit
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |hew " ..target.. " right arm|assess " ..target)
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) and evenom1 == "exploit" then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right arm|assess " ..target)

elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |hew " ..target.. " right arm|assess " ..target)
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right arm|assess " ..target)

elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |hew " ..target.. " right arm|assess " ..target)
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |discipline|hew " ..target.. " right arm|assess " ..target)

-- Left Arm
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "exploit" then -- exploit
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |hew " ..target.. " left arm|assess " ..target)
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) and evenom1 == "exploit" then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " left arm|assess " ..target)

elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |hew " ..target.. " left arm|assess " ..target)
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " left arm|assess " ..target)

elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |hew " ..target.. " left arm|assess " ..target)
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |discipline|hew " ..target.. " left arm|assess " ..target)

--Head
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "exploit" then -- exploit
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |overhand " ..target)
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) and evenom1 == "exploit" then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|overhand " ..target.. " |assess " ..target)

elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |overhand " ..target.. " |assess " ..target)
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|overhand " ..target.. " |assess " ..target)

elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |overhand " ..target.. "|assess " ..target)
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|stand|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |discipline|overhand " ..target.. " |assess " ..target)

-- Torso
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "exploit" then -- exploit
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |underhand " ..target.. " |assess " ..target)
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) and evenom1 == "exploit" then -- exploit/clumsiness
send("cq all|stand|stand|wield bastard|grip|hellforge invest exploit|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|underhand " ..target.. "|assess " ..target)

elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment
send("cq all|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |underhand " ..target.. " |assess " ..target)
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) and evenom1 == "torment" then -- torment/clumsiness
send("cq all|stand|wield bastard|grip|hellforge invest torment|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|underhand " ..target.. " |assess " ..target)

elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |underhand " ..target.. " |assess " ..target)
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|stand|wield bastard|grip|hellforge invest agony|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |envenom bastard with " ..evenom1.. " |discipline|underhand " ..target.. " |assess " ..target)


end
