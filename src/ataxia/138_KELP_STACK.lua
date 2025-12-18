-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > APOSTATE > KELP STACK

function apostate_kelp()
getLockingAffliction()
checkTargetLocks()

curses = {}


ataxiaTemp.tarTumble = ataxiaTemp.tarTumble or false


 if tAffs.curseward  then

    table.insert(curses,"breach")
end

if ataxiaTemp.tarTumble then
 table.insert(curses,"cowardice")
end

if truelock and not tAffs.voyria  then

    table.insert(curses,"plague")
end


if tAffs.slickness and not tAffs.anorexia and (tAffs.impatience or curses[2] == "impatience") and curses[1] ~= "breach" then
    table.insert(curses,"anorexia")
end

if  tAffs.slickness and not tAffs.anorexia  and tAffs.asthma and tAffs.impatience and curses[1] ~= "breach" then
    table.insert(curses,"anorexia")
end

if tAffs.manaleech and tAffs.slickness and not tAffs.anorexia  and tAffs.asthma and not tAffs.impatience and curses[1] ~= "breach" and not tBals.tree then
    table.insert(curses,"anorexia")
    table.insert(curses,"impatience")
end




if tAffs.deafness and bloodworm() == true then
 table.insert(curses,"sensitivity")
end


if maretick and maretick == true and not tAffs.hellsight and tAffs.hypersomnia and not tAffs.dementia and tAffs.asthma and tAffs.impatience then
   table.insert(curses,"dementia")
end



if tAffs.asthma and not tAffs.slickness then
   table.insert(curses,"sicken")
     table.insert(curses,"sicken")
end



if not tAffs.paralysis then
    table.insert(curses,"paralysis")
end

if not tAffs.impatience  then
    table.insert(curses,"impatience")
end

if not tAffs.clumsiness then
    table.insert(curses,"clumsy")
end



if not tAffs.weariness  then
    table.insert(curses,"weariness")
end




if not tAffs.asthma then
    table.insert(curses,"asthma")
end


if not tAffs.deafness and not tAffs.sensitivity then
 table.insert(curses,"sensitivity")
end




if tAffs.impatience and not tAffs.stupidity  then
    table.insert(curses,"stupid")
end




if getLockingAffliction() ~= "weariness" and  getLockingAffliction() ~= "plague" and getLockingAffliction() ~= "stupid" and getLockingAffliction() ~= "haemophilia" and
 not tAffs[getLockingAffliction()] 
then    table.insert(curses,getLockingAffliction())
end





if not tAffs.nausea  then
    table.insert(curses,"vomiting")
end


if not tAffs.addiction then
    table.insert(curses,"addiction")
end









if not tAffs.confusion  then
    table.insert(curses,"confusion")
end







if not tAffs.epilepsy  then
    table.insert(curses,"epilepsy")
end



if not tAffs.dementia  then
    table.insert(curses,"dementia")
end

if not tAffs.vertigo then
    table.insert(curses,"vertigo")
end



if not tAffs.dizziness  then
    table.insert(curses,"dizzy")
end



if not tAffs.recklessness  then
table.insert(curses,"reckless")
end

if not tAffs.masochism  then
    table.insert(curses,"masochism")
end
















apostate_lock()
end

