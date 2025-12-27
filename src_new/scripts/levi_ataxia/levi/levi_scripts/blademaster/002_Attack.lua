--[[mudlet
type: script
name: Attack
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Blademaster
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function bm_attack()
attk = attk or ""
tside = tside or ""

if tparrying == false then

attk = "centreslash"
tside = "up"
  end

if tparrying == "head" then
attk = "legslash"
tside = "left"
  end
  
if tparrying == "torso" then
attk = "legslash"
tside = "left"
  end  
  
if tparrying == "left leg" then
attk = "legslash"
tside = "right"
  end

if tparrying == "right leg" then
attk = "legslash"
tside = "left"
  end
  
if tparrying == "left leg" then
attk = "legslash"
tside = "right"
  end
  
if (tAffs.bleed == nil or tAffs.bleed == false) then tAffs.bleed = 0 end


--BrokenStar or Bladetwist or Impaleslash or Impale

if ataxiaNDB.players[target].city == "Mhaldor" and (tAffs.bleed >= 600) then
send("say BrokenStarrrrrrr")
end
if ataxiaNDB.players[target].city ~= "Mhaldor" and (tAffs.bleed >= 600) then
send("queue addclear free withdraw blade;sheathe sword;brokenstar " ..target)
end
if tAffs.impaled and timpaleslash == true then
send("queue addclear free assess "..target..";bladetwist;discern " ..target)
end

if tAffs.impaled and timpaleslash == false then
send("queue addclear free assess "..target..";impaleslash")
end

if tAffs.paralysis and not tAffs.impaled then
send("queue addclear free assess "..target..";impale " ..target)
end


--Rebounding or Shield and Hamstring
if tAffs.rebounding and not tAffs.hamstring then
send("queue addclear free assess "..target..";parry " ..ataxia.parrying.shouldparry.. ";raze " ..target.. " hamstring; assess " ..target)
end
if tAffs.shield and not tAffs.hamstring then
send("queue addclear free assess "..target..";parry " ..ataxia.parrying.shouldparry.. ";raze " ..target.. " hamstring; assess " ..target)
end
if tAffs.rebounding and tAffs.hamstring then
send("queue addclear free assess "..target..";parry " ..ataxia.parrying.shouldparry.. ";raze " ..target.. " throat; assess " ..target)
end

if tAffs.shield and tAffs.hamstring then
send("queue addclear free assess "..target..";parry " ..ataxia.parrying.shouldparry.. ";raze " ..target.. " " ..tstrike.. " ;assess " ..target)
end

if not tAffs.impaled and tAffs.clumsiness then
send("queue addclear free infuse ice;parry " ..ataxia.parrying.shouldparry.. ";assess "..target.. ";" ..attk.. " " ..target.. " " ..tside.. " " ..tstrike.. " ;assess " ..target)
end

if not tAffs.impaled and not tAffs.clumsiness then
send("queue addclear free infuse lightning;parry " ..ataxia.parrying.shouldparry.. ";assess "..target..";" ..attk.. " " ..target.. " " ..tside.. " " ..tstrike.. " ;assess " ..target)
  end
  


end










