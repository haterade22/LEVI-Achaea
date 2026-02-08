runietwohandlogic()
hammerweapon()

-- Raze Attacks/Carve
if (targreb == true) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus speed|splinter " ..target.. " |assess " ..target)
elseif (targreb == true) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|discipline|battlefury perceive " ..target.. " |battlefury focus speed|splinter " ..target.. " |assess " ..target)
elseif (targreb == false) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus speed|splinter " ..target.. " |assess " ..target)
elseif (targreb == false) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|discipline|battlefury perceive " ..target.. " |battlefury focus speed|splinter " ..target.. " |assess " ..target)
elseif (targreb == true) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus speed|splinter " ..target.. " |assess " ..target)
elseif (targreb == true) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|discipline|battlefury perceive " ..target.. " |battlefury focus speed|splinter " ..target.. " |assess " ..target)
-- Left Leg
elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " left leg|assess " ..target)
elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " left leg|assess " ..target)

elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " left leg|assess " ..target)
elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " left leg|assess " ..target)

elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " left leg|assess " ..target)
elseif matches[2] == "ll" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " left leg|assess " ..target)

--Right Leg

elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " right leg|assess " ..target)
elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess)  then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " right leg|assess " ..target)

elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess)  then -- torment
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " right leg|assess " ..target)
elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " right leg|assess " ..target)

elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " right leg|assess " ..target)
elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " right leg|assess " ..target)

--Right Arm
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " right arm|assess " ..target)
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess)  then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " right arm|assess " ..target)

elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " right arm|assess " ..target)
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " right arm|assess " ..target)

elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " right arm|assess " ..target)
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " right arm|assess " ..target)

-- Left Arm
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " left arm|assess " ..target)
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " left arm|assess " ..target)

elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " left arm|assess " ..target)
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " left arm|assess " ..target)

elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |pulverise " ..target.. " left arm|assess " ..target)
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|pulverise " ..target.. " left arm|assess " ..target)

--Head
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |overhand " ..target)
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|overhand " ..target.. " |assess " ..target)

elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |overhand " ..target.. " |assess " ..target)
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|overhand " ..target.. " |assess " ..target)

elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |overhand " ..target.. "|assess " ..target)
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|overhand " ..target.. " |assess " ..target)

-- Torso
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |underhand " ..target.. " |assess " ..target)
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|underhand " ..target.. "|assess " ..target)

elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |underhand " ..target.. " |assess " ..target)
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|underhand " ..target.. " |assess " ..target)

elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |underhand " ..target.. " |assess " ..target)
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |battlefury focus " ..bfury.. " |discipline|underhand " ..target.. " |assess " ..target)
end
