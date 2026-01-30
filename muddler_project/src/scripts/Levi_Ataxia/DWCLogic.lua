function runiedwckelpstack2()


if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
	local	softlock = true
  else
  softlock = false
	end
  
if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
		treelock = true
  else
    treelock = false
	end


if softlock == true and not tAffs.recklessness then
   envenom1 = "eurypteria"
   end
if softlock == true and not tAffs.stupidity then
   envenom1 = "aconite"
   
   end
   
if softlock == true and not tAffs.brokenleftarm then
	envenom1 = "epteth"
   
   end
   

if softlock == true and not tAffs.brokenrightarm then
	envenom1 = "epteth"
   
   end

if tAffs.prone then
	envenom1 = "epseth"
	envenom2 = "epseth"
 
  end

if tAffs.prone and not tAffs.anorexia and not tBals.salve then
    envenom1 = "slike"

  end

if tAffs.slickness and not tAffs.anorexia and tAffs.asthma then
   envenom1 = "slike"
  
  end

if tAffs.asthma and not tAffs.slickness then
	envenom1 = "gecko"

  end
if not tAffs.addiction and tAffs.weariness then
	envenom1 = "vardrax"

  end

if not tAffs.weariness then
   envenom1 = "vernalius"
  
  end

if not tAffs.asthma then
	envenom1 = "kalmia"
end


if not tAffs.clumsiness then
	envenom1 = "xentio"

  end

end

function envenom2dwc()

if checkAffList({"anorexia", "asthma", "slickness", "bloodfire"},3) then
	local	softlock = true
  else
  softlock = false
	end
  
if checkAffList({"anorexia", "asthma", "slickness", "paralysis"},4) then
		treelock = true
  else
    treelock = false
	end


if not tAffs.paralysis then
	envenom2 = "curare"


elseif tAffs.asthma and not tAffs.slickness and not tAffs.paralysis then
	envenom2 = "curare"
  

elseif softlock == true and not tAffs.recklessness and envenom1 ~= "eurypteria"  then
   envenom2 = "eurypteria"
  
elseif softlock == true and not tAffs.stupidity and envenom1 ~= "aconite" then
   envenom2 = "aconite"
   
  
   
elseif softlock == true and not tAffs.brokenleftarm  and not tAffs.brokenrightarm and envenom1 == "epteth" then
	envenom2 = "epteth"
      
  

elseif tAffs.prone and envenom1 == "epseth" then
	
	envenom2 = "epseth"
 
  

elseif tAffs.prone and not tAffs.anorexia and not tBals.salve and envenom1 ~= "slike" then
    envenom2 = "slike"

  
  
elseif not tAffs.paralysis and envenom1 ~= "curare" then
	envenom2 = "curare"
  
  

elseif tAffs.slickness and not tAffs.anorexia and tAffs.asthma and envenom1 ~= "slike" then
   envenom2 = "slike"
  
 

elseif tAffs.asthma and not tAffs.slickness and envenom1 ~= "slike" then
	envenom2 = "slike"
  
 

elseif not tAffs.addiction and tAffs.weariness and envenom1 ~= "vardrax" then
	envenom2 = "vardrax"

 

elseif not tAffs.paralysis and envenom1 ~= "curare" then
	envenom2 = "curare"

 

elseif not tAffs.weariness and envenom1 ~= "vernalius" then
   envenom2 = "vernalius"
  
 

elseif not tAffs.asthma and envenom1 ~= "kalmia" then
	envenom2 = "kalmia"

 


elseif not tAffs.clumsiness and envenom1 ~= "xentio" then
	envenom2 = "xentio"

 
 end


dwcattack()
end