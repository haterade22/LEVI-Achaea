--[[mudlet
type: script
name: WAR BASIC
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- INFERNAL
- INFERNAL
- TWO HANDED
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function infernaltwohandhammer()
			--	ataxia_breakLock()

local atk = combatQueue()
--INVESTS

devastated = devastated or false
if precision_hit then bfocus = "precision" 
elseif not tBals.salve then bfocus = "precision" else bfocus = bfocus end
can_brain = ataxiaTemp.fractures.skullfractures
if can_brain == 1 then can_brain = 10 end
if can_brain == 2 then can_brain = 20 end
if can_brain == 3 then can_brain = 30 end
if can_brain == 4 then can_brain = 40 end
if can_brain == 5 then can_brain = 50 end
if can_brain == 6 then can_brain = 60 end
if can_brain == 7 then can_brain = 70 end
if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess - can_brain  <= 20 and not battlefury_overwhelm then
need_overwhelm = true else need_overwhelm = false end

if tAffs.sensitivity and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess - can_brain  <= 40 and not battlefury_overwhelm then
need_overwhelm2 = true else need_overwhelm2 = false end





 venoms = {}


if not tAffs.slickness and tAffs.asthma then
  table.insert(venoms,"gecko")

end

if not tAffs.paralysis then
  table.insert(venoms,"curare")

end

if not tAffs.asthma then
  table.insert(venoms,"kalmia")

end








invest = {}


if not tAffs.healthleech then invest = "torment"


elseif not tAffs.weariness then invest = "exploit"





elseif not tAffs.haemophilia then invest = "torture"


elseif getMentalAffCount() >= 4 then invest = "punishment" 

else invest = "torment" end




--ATTACK



if tAffs.impaled then
disembowel = true
else
disembowel = false
end




if tAffs.rebounding then

need_raze = true
else
need_raze = false
end

if tAffs.shield then

need_raze2 = true
else
need_raze2 = false
end




if (tAffs.brokenrightleg or tAffs.damagedrightleg) and (tAffs.brokenleftleg or tAffs.damagedleftleg)
 and (tAffs.brokenleftarm or tAffs.damagedleftarm)  and  (tAffs.brokenrightarm or tAffs.damagedrightarm) then
vivisect = true
else
vivisect = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 20 then
quash_arc = true
else
quash_arc = false
end




if quash_arc then

atk = "stand/wield shield longsword/assess "..target.."/quash "..target.."/arc curare"

elseif vivisect then
atk = atk.."assess "..target..";wipe "..wield_weapon..";hellforge invest "..invest..";dismount;vivisect "..target..";battlefury perceive "..target

elseif disembowel then 

atk = atk.."battlefury focus speed;hellforge invest "..invest..";disembowel "..target..";battlefury perceive "..target..";assess "..target

elseif tAffs.prone and devastated then

atk = atk.."wield bastard;wipe bastard;battlefury perceive "..target..";hellforge invest "..invest..";battlefury focus speed;impale "..target..";assess "..target


elseif need_raze or need_raze2 then
bfocus = "speed"
atk = atk.."wield warhammer;wipe warhammer;battlefury perceive "..target..";battlefury focus "..bfocus..";hellforge invest "..invest..";splinter "..target..";assess "..target


elseif battlefury_overwhelm == true then

atk = atk.."wield warhammer;wipe warhammer;assess "..target..";hellforge invest "..invest..";battlefury focus speed;brain "..target


elseif need_overwhelm or need_overwhelm2 then

atk = atk.."wield warhammer;wipe warhammer;assess "..target..";hellforge invest "..invest..";battlefury overwhelm "..target..";fury"





elseif can_devastate_legs then

atk = atk.."wield warhammer;wipe warhammer;hellforge invest "..invest..";devastate "..target.." legs;battlefury upset "..target..";assess "..target



elseif leg_prep and not tAffs.prone and ataxiaTemp.parriedLimb == "head" then

atk = atk.."wield warhammer;wipe warhammer;hellforge invest "..invest..";pulverise "..target.." right leg;battlefury upset "..target..";assess "..target


elseif full_prep then

atk = atk.."wield warhammer;wipe warhammer;hellforge invest "..invest..";pulverise "..target.." "..targetlimb..";battlefury upset "..target..";assess "..target



elseif can_devastate_arms then

atk = atk.."wield "..wield_weapon..";wipe "..wield_weapon..";devastate "..target.." arms;battlefury upset "..target..";assess "..target


elseif wield_weapon == "bastard" and targetlimb[1] == "right leg" or targetlimb[1] == "left leg" or targetlimb[1] == "left arm" or targetlimb[1] == "right arm" then

atk = atk.."wield bastard;wipe bastard;battlefury perceive "..target..";battlefury focus "..bfocus..";hew "..target.." "..targetlimb[1].." "..venoms[1]..";assess "..target




elseif wield_weapon == "warhammer" and targetlimb[1] == "right leg" or targetlimb[1] == "left leg" or targetlimb[1] == "left arm" or targetlimb[1] == "right arm" then

atk = atk.."wield warhammer;wipe warhammer;battlefury perceive "..target..";battlefury focus "..bfocus..";hellforge invest "..invest..";pulverise "..target.." "..targetlimb[1]..";assess "..target

elseif targetlimb[1] == "torso" and wield_weapon == "bastard"  then

atk = atk.."wield bastard;wipe bastard;battlefury perceive "..target..";battlefury focus "..bfocus..";underhand "..target.." "..venoms[1]..";assess "..target


elseif targetlimb[1] == "torso" and wield_weapon == "warhammer" then

atk = atk.."wield warhammer;wipe warhammer;battlefury perceive "..target..";battlefury focus "..bfocus..";hellforge invest "..invest..";underhand "..target..";assess "..target


elseif    targetlimb[1] == "head" and wield_weapon == "bastard"  then

atk = atk.."wield bastard;wipe bastard;battlefury perceive "..target..";battlefury focus "..bfocus..";overhand "..target.." "..venoms[1]..";assess "..target




elseif    targetlimb[1] == "head" and wield_weapon == "warhammer"  then

atk = atk.."wield warhammer;wipe warhammer;battlefury perceive "..target..";battlefury focus "..bfocus..";hellforge invest "..invest..";overhand "..target..";assess "..target


else
atk = atk.."wield warhammer;wipe warhammer;battlefury perceive "..target..";battlefury focus "..bfocus..";hellforge invest "..invest..";slaughter "..target..";battlefury perceive "..target..";assess "..target


end
if bfocus == "precision" then wield_weapon = "warhammer" elseif bfocus == "speed" then wield_weapon = "bastard" 
else wield_weapon = "warhammer" 

end


if not ataxia.afflictions.aeon then
if table.contains(ataxia.playersHere, target) then

if gmcp.Char.Vitals.bal == "0"
or gmcp.Char.Vitals.eq == "0"
then
send("cq all")
end

if gmcp.Char.Vitals.bal == "1"
and gmcp.Char.Vitals.eq == "1" then

if quash_arc then
send("setalias quasharc "..atk)
send("queue addclear free quasharc")

elseif not engaged then
send("queue addclear freestand discipline;"..atk..";engage "..target..";tyranny;order hyena kill "..target)

else

send("queue addclear freestand discipline;"..atk..";tyranny")

end
end

end

end
end
