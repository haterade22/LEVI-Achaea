--[[mudlet
type: script
name: RAMPAGE
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- INFERNAL
- I SNB
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function infernalpriosrampage()
local atk = combatQueue()

add_dedication = false
need_raze = false
partyrelay = partyrelay or false



if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
	local	softlock = true
  else
  softlock = false
	
	end
  




--VENOMS

  venoms = {}
  


if not tAffs.slickness and not tAffs.asthma and not tBals.tree then
    table.insert(venoms,"kalmia")
  table.insert(venoms,"gecko")
 
end

if not tAffs.paralysis then
  table.insert(venoms,"curare")

end

if not tAffs.nausea then
  table.insert(venoms,"euphorbia")

end


if not tAffs.clumsiness then
  table.insert(venoms,"xentio")

end

if not tAffs.asthma then
  table.insert(venoms,"kalmia")

end



if not tAffs.darkshade then
  table.insert(venoms,"darkshade")

end

if not tAffs.stupidity then
  table.insert(venoms,"aconite")

end

if not tAffs.addiction then

  table.insert(venoms,"vardrax")

end



--INVESTS


invest = {}

if not tAffs.weariness and tAffs.clumsiness then invest = "exploit"

elseif not tAffs.haemophilia and tAffs.nausea then invest = "torture"

elseif tAffs.haemophilia then invest = "agony" 

elseif getMentalAffCount() >= 2 then invest = "punishment" 

else invest = "agony" end
  
  



--ATTACK


local atk = combatQueue()


if ataxia.afflictions.paralysis and not ataxia.afflictions.prone 
and (tonumber(gmcp.Char.Vitals.hp) >=  tonumber(gmcp.Char.Vitals.maxhp)*.5) 
and (tonumber(gmcp.Char.Vitals.mp) >= tonumber(gmcp.Char.Vitals.maxmp)*.6) and
(ataxiaNDB_getClass(target) ~= "Apostate" or ataxiaNDB_getClass(target)) ~= "Priest" then

add_dedication = true
else 
add_dedication = false
end



if tAffs.rebounding or tAffs.shield then

need_raze = true
else
need_raze = false
end

if tAffs.rebounding and tAffs.shield then
need_shieldraze = true
else
need_shieldraze = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess > 50 and ataxia.vitals.class == 4 then
ferocity_full = true
else 
ferocity_full = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50 and ataxia.vitals.class == 4 then
impale_blackout = true
else
impale_blackout = false
end

if ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 30 then
quash_arc = true
else
quash_arc = false
end


if quash_arc then

atk = "stand/wield shield longsword441711/quash "..target.."/arc "..target.." curare"

elseif need_shieldraze then
atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";raze "..target.." shield"


elseif need_raze then
atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";razeslash "..target.." "..venoms[1]

elseif (invest == "exploit" or invest == "torture") then

atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";envenom scimitar383498 with "..venoms[1]..";dsl "..target

else
atk = atk.."wield scimitar scimitar;wipe scimitar383498;wipe scimitar355418;rampage against "..target..";assess "..target..";hellforge invest "..invest..";dsl "..target.." "..venoms[1].." "..venoms[2]

end


if not ataxia.settings.paused then

if quash_arc then
send("setalias quasharc "..atk)
send("queue addclear eq quasharc")

elseif not engaged then
send("queue addclear free "..atk..";engage "..target..";tyranny")

else

send("queue addclear free "..atk..";tyranny")

end
end


end