--[[mudlet
type: alias
name: Attack
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Knight
- Infernal
- SNB
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^sr$
command: ''
packageName: ''
]]--

snblogic()
shieldlogic()
-- Raze 
if (targreb == true) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) then
send("cq all|stand|stand|vault " ..mounter.. "|raze " ..target.. " |smash " ..shieldatt.. " |assess " ..target)
elseif (targreb == true) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and svo.affl.paralysis then
send("cq all|stand|stand|vault " ..mounter.. "|target nothing|dedication|raze " ..target.. " |smash " ..shieldatt.. " | assess " ..target)

elseif (targreb == true) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) then
send("cq all|stand|stand|vault " ..mounter.. "|combination " ..target.. " raze " ..tarlimb.." smash " ..shieldatt.. " | assess " ..target)
elseif (targreb == true) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and svo.affl.paralysis then
send("cq all|stand|stand|vault " ..mounter.. "|dedication|combination " ..target.. " raze " ..tarlimb.." smash " ..shieldatt.. "| assess " ..target)

elseif (targreb == false) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) then
send("cq all|stand|stand|vault " ..mounter.. "|combination " ..target.. " raze " ..tarlimb.." smash " ..shieldatt.. "| assess " ..target)
elseif (targreb == false) and (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and svo.affl.paralysis then
send("cq all|stand|stand|vault " ..mounter.. "|dedication|combination " ..target.. " raze " ..tarlimb.." smash " ..shieldatt.. "| assess " ..target)


-- Exploit
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and envenom1 == "exploit" and tarlimb == "nothing" then
send("cq all|stand|stand|vault " ..mounter.. "|hellforge invest exploit|target nothing|combination " ..target.. " slice smash " ..shieldatt.. "| assess " ..target)
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and svo.affl.paralysis and envenom1 == "exploit" and tarlimb == "nothing" then
send("cq all|stand|stand|vault " ..mounter.. "|dedication|hellforge invest exploit|target nothing|combination " ..target.. " slice smash " ..shieldatt.. "| assess " ..target)

elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and envenom1 == "exploit" then
send("cq all|stand|stand|vault " ..mounter.. "|hellforge invest exploit|combination " ..target.. " slice " ..tarlimb.. " smash " ..shieldatt.. "| assess " ..target)
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and svo.affl.paralysis and envenom1 == "exploit" then
send("cq all|stand|stand|vault " ..mounter.. "|dedication|hellforge invest exploit|combination " ..target.. " slice " ..tarlimb.. " smash " ..shieldatt.. "| assess " ..target)


--Torment
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and envenom1 == "exploit" and tarlimb == "nothing" then
send("cq all|stand|stand|vault " ..mounter.. "|hellforge invest exploit|target nothing|combination " ..target.. " slice smash " ..shieldatt.. "| assess " ..target)
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and svo.affl.paralysis and envenom1 == "exploit" and tarlimb == "nothing" then
send("cq all|stand|stand|vault " ..mounter.. "|dedication|hellforge invest exploit|target nothing|combination " ..target.. " slice smash " ..shieldatt.. "| assess " ..target)

elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and envenom1 == "torment" then
send("cq all|stand|stand|vault " ..mounter.. "|hellforge invest torment|combination " ..target.. " slice " ..tarlimb.. " smash " ..shieldatt.. "| assess " ..target)
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and svo.affl.paralysis and envenom1 == "torment" then
send("cq all|stand|stand|vault " ..mounter.. "|dedication|hellforge invest torment|combination " ..target.. " slice " ..tarlimb.. " smash " ..shieldatt.. "| assess " ..target)

--Normal
  -- Normal Target Nothing
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) and tarlimb == "nothing" then
send("cq all|stand|stand|vault " ..mounter.. "|target nothing|combination " ..target.. " slice "..envenom1.. " smash high|assess " ..target)
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and svo.affl.paralysis and tarlimb == "nothing" then
send("cq all|stand|stand|vault " ..mounter.. "|dedication|target nothing||combination " ..target.. " slice " ..tarlimb.. " "..envenom1.. " smash high|assess " ..target)


-- Normal Target Limb
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) then
send("cq all|stand|stand|vault " ..mounter.. "|combination " ..target.. " slice " ..tarlimb.. " "..envenom1.. " smash " ..shieldatt.. "| assess " ..target)
elseif (targreb == false) and (targshield == false) and (svo.bals.balance and svo.bals.equilibrium) and svo.affl.paralysis then
send("cq all|stand|stand|vault " ..mounter.. "|dedication|combination " ..target.. " slice " ..tarlimb.. " "..envenom1.. " smash high|assess " ..target)

end




