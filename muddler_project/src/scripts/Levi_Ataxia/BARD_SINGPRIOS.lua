function bardvenompriossing()
getLockingAffliction()
bardvenom = {}
bardsong = {}

if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
		softlock = true
  else
  softlock = false
	
	end
	if softlock and checkAffList({"impatience", "sandfever"},1) then
		hardlock = true
   hardlock = false
  end
	
if checkAffList({"healthleech", "asthma", "weariness", "sensitivity", "clumsiness", "hypochondria", "parasite", "rebbies"},3) then
		kelpstack = true
  else
  kelpstack = false

	end
if checkAffList({"addiction", "nausea", "lethargy", "scytherus", "darkshade", "haemophilia", "flushings", "unweavingbody"},3) then
		ginstack = true
  else
  ginstack = false

	end
  
if checkAffList({"impatience", "stupidity", "epilepsy", "vertigo", "confusion", "dizziness", "paranoia", "claustrophobia", "agoraphobia", "paranoia", "dementia"},3) then
		mentalstack = true
  else
  mentalstack = false

	end

	if hardlock and haveAff("paralysis") then
	local	truelock = true
 truelock = false
	
	end

 


if truelock and not tAffs.voyria  then

    table.insert(bardvenom,"voyria")
end



--if not tAffs.paralysis and tBals.tree and not softlock and ataxia.vitals.voice == "No" and bardsong[1] ~= "recite epic" then
 --   table.insert(bardvenom,"curare")
--end

--if not tAffs.paralysis and hardlock and ataxia.vitals.voice == "No" and bardsong[1] ~= "recite epic" then
 --   table.insert(bardvenom,"curare")
 --   end
  
if not tAffs.paralysis and not tAffs.asthma and not tAffs.slickness and not mentalstack and not kelpstack and not softlock then
       table.insert(bardvenom,"curare")
end

if not tAffs.paralysis and softlock and tBals.tree == true then

       table.insert(bardvenom,"curare")
end

if not tAffs.paralysis and hardlock then

       table.insert(bardvenom,"curare")
end

if not tAffs.anorexia and tAffs.slickness and tAffs.asthma then
  table.insert(bardvenom,"slike")
      table.insert(bardsong,"sing qasida")
      end

if kelpstack and tAffs.asthma and not tAffs.slickness then 
  table.insert(bardvenom,"gecko")
    
  end

if (mentalstack or not kelpstack) and not tAffs.asthma then
    table.insert(bardvenom,"kalmia")
end

if not tAffs.clumsiness then
          table.insert(bardvenom,"xentio")

     table.insert(bardsong,"sing maqam")
end

if not tAffs.weariness and bardvenom[1] ~= "curare" then
    table.insert(bardvenom,"vernalius")
end

if not tAffs.sensitivity then
          table.insert(bardvenom,"prefarar")

end


if not tAffs.impatience then
    table.insert(bardsong,"sing limerick")
end



if not tAffs.confusion and (tAffs.impatience or tBals.focus == false) then
     table.insert(bardsong,"recite haiku")

end

if not tAffs.epilepsy and (tAffs.impatience or tBals.focus == false) then
     table.insert(bardsong,"sing ditty")

end

if not tAffs.vertigo and (tAffs.impatience or tBals.focus == false) then
     table.insert(bardsong,"sing pastorale")

end


if not tAffs.stupidity and (tAffs.impatience or tBals.focus == false) then
        table.insert(bardsong,"sing passion")

end




if tAffs.impatience then
if not tAffs.dizziness then
    table.insert(bardvenom,"larkspur")
end

if not tAffs.recklessness then
    table.insert(bardvenom,"eurypteria")
    
end

if not tAffs.shyness then
    table.insert(bardvenom,"digitalis")
    
end
end









    







if not tAffs.addiction then
    table.insert(bardvenom,"vardrax")
     table.insert(bardsong,"recite ode")
end

if not tAffs.nausea then
    table.insert(bardvenom,"euphorbia")
     table.insert(bardsong,"recite poem")
end







singattack()
end


