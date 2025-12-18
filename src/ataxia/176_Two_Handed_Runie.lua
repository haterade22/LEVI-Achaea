-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > RuneWarden > Two Handed Runie

function twohandedrunie()
tparrying = tparrying or "head"
ltarget = ltarget or "torso"
envenom1 = envenom1 or nil
taffenvenom1 = taffenvenom1 or nil
preport1 = preport1 or ""
envenom2 = evenom2 or nil
taffenvenom2 = taffenvenom2 or nil
omount = omount or ""
engaged = engaged or false
need_raze = false
need_bisect = false
if not php then php = 100 end
if not pm then pm = 100 end
partyrelay = partyrelay or true
if tAffs.rebounding or tAffs.shield then
need_raze = true
  else
need_raze = false
  end
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
getLockingAffliction()
checkTargetLocks()
local atk = combatQueue()

if (lb[target].hits["right leg"] >= 93 ) then 
atk = atk.."wield bastard;falcon slay " ..target.. "wipe bastard;envenom bastard with epseth;hew " ..target.. "right leg;battlefury upset " ..target.. ";assess "..target
 


  end

end