-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > BARD > TEST LIMB PRIOS

function bardvenomprioslimb()
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
	
if tAffs.asthma and checkAffList({"healthleech", "weariness", "sensitivity", "hypochondria", "parasite", "rebbies"},1) then
		kelpstack = true
  else
  kelpstack = false

	end
if checkAffList({"addiction", "nausea", "lethargy", "scytherus", "darkshade", "haemophilia", "flushings", "unweavingbody"},3) then
		ginstack = true
  else
  ginstack = false

	end
  
if checkAffList({"impatience", "stupidity", "epilepsy", "vertigo", "confusion", "dizziness", "paranoia", "claustrophobia", "agoraphobia", "paranoia", "dementia"},4) then
		mentalstack = true
  else
  mentalstack = false

	end

	if hardlock and haveAff("paralysis") then
		truelock = true
 truelock = false
	
	end

 if tAffs.rebounding and tAffs.shield then
        table.insert(bardsong,"cantata")
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
  
if tAffs.asthma and not tAffs.paralysis and not tAffs.slickness and not mentalstack and not softlock then
       table.insert(bardvenom,"curare")

end

if not tAffs.paralysis and softlock and tBals.tree == true then

       table.insert(bardvenom,"curare")
end

if not tAffs.paralysis and hardlock then

       table.insert(bardvenom,"curare")
end

if not tAffs.anorexia and tAffs.slickness and tAffs.impatience then
  table.insert(bardvenom,"slike")
      table.insert(bardsong,"sing qasida")
      end



  if not tAffs.impatience then
    table.insert(bardsong,"sing limerick")
end
if kelpstack and not tAffs.slickness and tAffs.impatience then 
  table.insert(bardvenom,"gecko")
    
  end


if not tAffs.asthma then
    table.insert(bardvenom,"kalmia")
end

if not tAffs.weariness and bardvenom[1] ~= "curare" then
    table.insert(bardvenom,"vernalius")
end

if not tAffs.clumsiness then
          table.insert(bardvenom,"xentio")

end

if not tAffs.sensitivity then
          table.insert(bardvenom,"prefarar")

end
























if not tAffs.vertigo and (tAffs.impatience or tBals.focus == false) and tAffs.anorexia then
     table.insert(bardsong,"sing pastorale")

end

if not tAffs.confusion and (tAffs.impatience or tBals.focus == false) and tAffs.anorexia then
     table.insert(bardsong,"recite haiku")

end

if not tAffs.epilepsy and (tAffs.impatience or tBals.focus == false) and tAffs.anorexia then
     table.insert(bardsong,"sing ditty")

end

if not tAffs.stupidity and (tAffs.impatience or tBals.focus == false) and tAffs.anorexia then
        table.insert(bardsong,"sing passion")

end



if not tAffs.stupidity then
    table.insert(bardvenom,"aconite")
    
end


if not tAffs.recklessness then
    table.insert(bardvenom,"eurypteria")
    
end

if not tAffs.shyness then
    table.insert(bardvenom,"digitalis")
    
end




if not tAffs.dizziness then
    table.insert(bardvenom,"larkspur")
end






    







if not tAffs.addiction and tAffs.impatience and tAffs.clumsiness then
    table.insert(bardvenom,"vardrax")
     table.insert(bardsong,"recite ode")
end

if not tAffs.nausea and tAffs.impatience and tAffs.clumsiness then
    table.insert(bardvenom,"euphorbia")
     table.insert(bardsong,"recite poem")
end








bardlimbattack()
end


