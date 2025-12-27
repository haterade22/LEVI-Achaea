--[[mudlet
type: script
name: test
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

function infernalpriostest()
local atk = combatQueue()

add_dedication = false
need_raze = false
partyrelay = partyrelay or false
strikingHigh = false


if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
	local	softlock = true
  else
  softlock = false
	
	end
  


if tAffs.haemophilia then invest = "agony" elseif getMentalAffCount() >= 3 then invest = "punishment" else invest = "agony" end
  
    shieldneed = {}
  if not tAffs.prone then
   table.insert(shieldneed,"trip")

  
elseif tAffs.impatience then
 table.insert(shieldneed,"smash high")


elseif tAffs.slickness and tAffs.asthma then
    table.insert(shieldneed,"smash high")


elseif tAffs.anorexia then
    table.insert(shieldneed,"smash high")


elseif softlock then
    table.insert(shieldneed,"smash high")



elseif not tAffs.paralysis then
    table.insert(shieldneed,"smash mid")
    

elseif not tAffs.asthma then
    table.insert(shieldneed,"drive")


elseif not tAffs.clumsiness then
    table.insert(shieldneed,"smash low")
    
else
    table.insert(shieldneed,"smash high")
end

--SWORDLIST

swordneed = {}

if not tAffs.prone then
    table.insert(swordneed,"hellforge invest "..invest..";combination "..target.." slice epseth")
end

atk = atk.."wield shield longsword441711;assess "..target..";hyena scent;"..swordneed[1].." "..shieldneed[1]

if partyrelay and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 40 then send("pt "..target..": Health is at "..ataxiaTemp.lastAssess.."%")
end
if not ataxia.settings.paused then
 if add_dedication then
 send("queue addclear free dedication;"..atk)
elseif quash_arc then
send("setalias quasharc "..atk)
send("queue addclear eq quasharc")
else

send("queue addclear free "..atk)

end

end
end