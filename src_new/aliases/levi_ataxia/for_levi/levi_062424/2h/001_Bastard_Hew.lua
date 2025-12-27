--[[mudlet
type: alias
name: Bastard Hew
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Knight
- RUNIE
- 2H
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^q(ll|rl|ra|la|hh|tt)$
command: ''
packageName: ''
]]--

runietwohandlogic()
wieldingweapons()
bastardweapon()

-- Raze Attacks/Carve
if need_raze then
send("queue addclear free stand;falcon track "..target.. ";falcon slay " ..target.. ";battlefury perceive " ..target.. ";wipe bastard;envenom bastard with epseth;assess " ..target.. ";carve " ..target.. ";battlefury upset " ..target)
-- Left Leg
if matches[2] == "ll" then
send("queue addclear free stand;battlefury perceive " ..target.. ";wipe bastard;envenom bastard with " ..envenomList[1].. ";assess " ..target.. ";battlefury focus " ..bfury.. ";hew " ..target.. ";battlefury upset " ..target)

--Right Leg

elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |hew " ..target.. " right leg|assess " ..target)
elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right leg|assess " ..target)

elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |hew " ..target.. " right leg|assess " ..target)
elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right leg|assess " ..target)

elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |hew " ..target.. " right leg|assess " ..target)
elseif matches[2] == "rl" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right leg|assess " ..target)

--Right Arm
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |envenom bastard with " ..renvenom1.. " |envenom bastard with " ..renvenom1.. " |envenom bastard with " ..renvenom1.. " battlefury focus " ..bfury.. " |hew " ..target.. " right arm|assess " ..target)
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |envenom bastard with " ..renvenom1.. " |envenom bastard with " ..renvenom1.. " battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right arm|assess " ..target)

elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |envenom bastard with " ..renvenom1.. " battlefury focus " ..bfury.. " |hew " ..target.. " right arm|assess " ..target)
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right arm|assess " ..target)

elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |hew " ..target.. " right arm|assess " ..target)
elseif matches[2] == "ra" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " right arm|assess " ..target)

-- Left Arm
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |hew " ..target.. " left arm|assess " ..target)
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " left arm|assess " ..target)

elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |hew " ..target.. " left arm|assess " ..target)
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " left arm|assess " ..target)

elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |hew " ..target.. " left arm|assess " ..target)
elseif matches[2] == "la" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|hew " ..target.. " left arm|assess " ..target)

--Head
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |overhand " ..target)
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|overhand " ..target.. " |assess " ..target)

elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |overhand " ..target.. " |assess " ..target)
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|overhand " ..target.. " |assess " ..target)

elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |overhand " ..target.. "|assess " ..target)
elseif matches[2] == "hh" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|overhand " ..target.. " |assess " ..target)

-- Torso
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- exploit
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |underhand " ..target.. " |assess " ..target)
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then -- exploit/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|underhand " ..target.. "|assess " ..target)

elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |underhand " ..target.. " |assess " ..target)
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then -- torment/clumsiness
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|underhand " ..target.. " |assess " ..target)

elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (not svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |underhand " ..target.. " |assess " ..target)
elseif matches[2] == "tt" and (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and (svo.affl.cluminess) then
send("cq all|battlefury perceive " ..target.. " |envenom bastard with " ..renvenom1.. " |battlefury focus " ..bfury.. " |discipline|underhand " ..target.. " |assess " ..target)
end
