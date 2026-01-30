function ataxia_raiseLimbDamage(limb, num)
	if type(target) == "number" then
		tAffs.shield = false
		tAffs.rebounding = false
		tAffs.paralysis = false
		tAffs.prone = false
	end
	
	selfLimbDamage.lasthit = limb
	
	selfLimbDamage[limb]["damage"] = selfLimbDamage[limb]["damage"] + num
	if selfLimbDamage[limb]["damage"] > 95 then selfLimbDamage[limb]["damage"] = 100 end
	selfLimbDamage.timers[limb] = selfLimbDamage.timers[limb] or {}
	if selfLimbDamage.timers[limb].timer then killTimer( selfLimbDamage.timers[limb].timer ) end
	selfLimbDamage.timers[limb].timer = tempTimer( 180, [[ ataxia_resetLimbDamage("]]..limb..[[")]])
	
	if limb == "torso" and selfLimbDamage.torso["damage"] >= 97 then
		ataxia_boxEcho("Torso is likely broken!", "red")
		send("curing predict mildtrauma")
	end
end

function ataxia_resetLimbDamage(limb)
	ataxia_clearLimbDamage(limb)
	ataxiaEcho("Our <green>"..limb.."<NavajoWhite> has been reset.")
end

function ataxia_clearLimbDamage(limb)
	selfLimbDamage[limb]["damage"] = 0
	if selfLimbDamage.timers[limb] and selfLimbDamage.timers[limb].timer then killTimer( selfLimbDamage.timers[limb].timer ) end
	selfLimbDamage.timers[limb] = nil
end

function ataxia_brokenLimbFound(event, affliction)
	if event == "aff gained" then
		if affliction == "damagedleftarm" or affliction == "mangledleftarm" then
			ataxia_clearLimbDamage("left arm")
			ataxia_boxEcho("LEFT ARM HAS BEEN BROKEN", "black:yellow")
		elseif affliction == "damagedrightarm" or affliction == "mangledrightarm" then
			ataxia_clearLimbDamage("right arm")
			ataxia_boxEcho("RIGHT ARM HAS BEEN BROKEN", "black:yellow")
		elseif affliction == "damagedleftleg" or affliction == "mangledleftleg" then
			ataxia_clearLimbDamage("left leg")
			ataxia_boxEcho("LEFT LEG HAS BEEN BROKEN", "black:DarkOrange")
			if not affed("damagedleftarm") and not affed("damagedrightarm") and ataxiaTemp.salvelockWait then
				killTimer(ataxiaTemp.salvelockWait) 
				ataxiaTemp.salvelockWait = nil
				send("queue addclear free restore",false)
			end
		elseif affliction == "damagedrightleg" or affliction == "mangledrightleg" then
			ataxia_clearLimbDamage("right leg")
			ataxia_boxEcho("RIGHT LEG HAS BEEN BROKEN", "black:DarkOrange")
			if not affed("damagedleftarm") and not affed("damagedrightarm") and ataxiaTemp.salvelockWait then
				killTimer(ataxiaTemp.salvelockWait) 
				ataxiaTemp.salvelockWait = nil			
				send("queue addclear eqbal restore",false)
			end			
		elseif affliction == "damagedhead" or affliction == "mangledhead" then
			ataxia_clearLimbDamage("head")
			ataxia_boxEcho("HEAD HAS BEEN BROKEN", "black:goldenrod")
		elseif affliction == "mildtrauma" or affliction == "serioustrauma" then
			ataxia_clearLimbDamage("torso")
			ataxia_boxEcho("TORSO HAS BEEN BROKEN", "black:red")
		end	
	elseif event == "aff cured" then
		if affliction == "mildtrauma" or affliction == "serioustrauma" then
			ataxia_clearLimbDamage("torso")
		end	
	end
end

registerAnonymousEventHandler("aff gained", "ataxia_brokenLimbFound")
registerAnonymousEventHandler("aff cured", "ataxia_brokenLimbFound")