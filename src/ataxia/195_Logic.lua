-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Blademaster > Logic

tstrike = tstrike or ""
tmounted = tmounted or false
timpaleslash = false
tparrying = tparrying or "none"

function getshinn()

-- mykaii = tonumber(string.match(gmcp.Char.Vitals.charstats[3],"Kai\: (%d+)"))
bmshin = tonumber(gmcp.Char.Vitals.charstats[3]:match("(%d+)"))

end

function tbleeding()
  tAffs.bleed = 0
end

function bmstriking()

if not tAffs.hamstring then
tstrike = "hamstring"
  end
if tmounted == true then
tstrike = "feet"
  end
if tmounted == false then
  tstrike = "knees"
  end  
if not tAffs.paralysis then
tstrike = "neck"
  end
bm_attack()
end

function bmstriking2()

if not tAffs.hamstring then
tstrike = "hamstring"
  end
if tmounted == true then
tstrike = "feet"
  end
if tmounted == false then
  tstrike = "knees"
  end  
if not tAffs.paralysis then
tstrike = "neck"
  end
bm_attackjew()
end


function bmstriking4()

if not tAffs.hamstring then
tstrike = "hamstring"
 
elseif not tAffs.airfist and ataxia.vitals.class >= 20 then
tstrike = "airfist" 

elseif tmounted == true then
tstrike = "feet"

elseif tAffs.paralysis and tAffs.hypochondria and not tAffs.asthma then
tstrike = "throat"

elseif tAffs.paralysis and not tAffs.hypochondria then
tstrike = "chest"

elseif not tAffs.paralysis then
tstrike = "neck"

  end
end

function bmgrouplock()
getLockingAffliction()
checkTargetLocks()

if not tAffs.hamstring then
  tstrike = "hamstring"
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.anorexia and tAffs.weariness and tAffs.recklessness then
	tstrike = "eyes"
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.anorexia and tAffs.weariness and not tAffs.recklessness then
  tstrike = "groin"
elseif tAffs.slickness and tAffs.asthma and tAffs.anorexia and not tAffs.impatience then
	tstrike = "chest"
elseif tAffs.asthma and tAffs.impatience and tAffs.anorexia and not tAffs.slickness then
  tstrike = "underarm"
elseif tAffs.asthma and tAffs.impatience and tAffs.slickness and not tAffs.anorexia then
  tstrike = "stomach"
elseif tAffs.slickness and tAffs.asthma then
  tstrike = "eyes"
elseif tAffs.prone and not tAffs.slickness and tAffs.asthma then
  tstrike = "underarm"
elseif not tAffs.slickness and tAffs.asthma and tAffs.paralysis then
	tstrike = "underarm"
elseif not tAffs.paralysis then
  tstrike = "neck"
elseif not tAffs.hypochondria then
  tstrike = "chest"
elseif not tAffs.asthma then
	tstrike = "throat"
elseif not tAffs.weariness then
  tstrike = "vernalius"

  end


end


function levibmtruelock()
if not tAffs.hamstring then
  tstrike = "hamstring"
elseif not tAffs.airfist and ataxia.vitals.class >= 20 then
  tstrike = "airfist" 
elseif truelock == true then
  if getLockingAffliction(target) == "paralyse" and not tAffs.paralysis then
    tstrike = "neck"
  elseif getLockingAffliction(target) == "weariness" and not tAffs.weariness then
    tstrike = "shoulder"
  --elseif getLockingAffliction(target) == "haemophilia" then
  elseif getLockingAffliction(target) == "plague" and not tAffs.plague then
    tstrike = "eyes"
  elseif getLockingAffliction(target) == "stupid" and not tAffs.stupidity then
    tstrike = "temple"
  elseif getLockingAffliction(target) == "reckless" and not tAffs.recklessness then
    tstrike = "groin"
  end
elseif hardlock == true and not tAffs.paralysis then
  tstrike = "neck"
elseif softlock == true and not tAffs.paralysis then
  tstrike = "neck"
elseif softlock == true and tAffs.paralysis and not tAffs.impatience then
  tstrike = "chest"
elseif tAffs.asthma and tAffs.impatience and tAffs.slickness and not tAffs.anorexia then
  tstrike = "stomach"
elseif tAffs.asthma and tAffs.impatience and not tAffs.slickness then
  tstrike = "underarm"
elseif not tAffs.paralysis then
  tstrike = "neck"
elseif tAffs.paralysis then
  if tAffs.slickness and tAffs.asthma and tAffs.impatience and not tAffs.anorexia then
    tstrike = "stomach"
  elseif tAffs.slickness and tAffs.asthma and not tAffs.impatience then
    tstrike = "chest"
  elseif not tAffs.slickness and tAffs.asthma and tAffs.impatience then
    tstrike = "underarm"
  elseif not tAffs.slickness and tAffs.asthma then
    tstrike = "underarm"
  elseif tAffs.asthma and not tAffs.impatience then
    tstrike = "chest"
  elseif not tAffs.asthma then
    tstrike = "throat"
  elseif not tAffs.weariness then
    tstrike = "shoulder"
  end
end
end
