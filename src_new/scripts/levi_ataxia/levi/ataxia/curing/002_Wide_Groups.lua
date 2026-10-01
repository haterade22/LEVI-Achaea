--[[mudlet
type: script
name: Wide Groups
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Curing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- THE target herb-cure table V3 reads first (getCurableAffs in
-- affliction_tracking_core/007 prefers this over curingTableV3, so a herb listed
-- here MASKS the V3 row -- an affliction missing here is never cured by that
-- herb in tracking, whatever V3 says). This file is the runtime winner: the
-- Curing folder's inline copy in _groups.yaml runs first and is overwritten.
-- Reconciled with the game's own WHATCURES output (v4.7.371, via the outside
-- DW audit). Additions are APPENDED: V3 weights candidates 4/2/1 by position,
-- so the existing order -- and every class's tracking -- is unchanged at the
-- top. Deliberately absent: insomnia (goldenseal strips it, but the tracker
-- models it as a target DEFENCE, setTargetDefenseV3), and bloodroot, which
-- falls through to curingTableV3.
curingTable = {
    goldenseal = {"depression", "sandfever", "stupidity", "epilepsy", "dizziness", "dissonance", "shyness", "impatience", "unweavingmind", "fulminated", "shadowmadness", "mycalium"},
    lobelia = {"hypochondria", "recklessness", "fratricide", "vertigo", "spiritburn", "tenderskin", "loneliness", "claustrophobia", "masochism", "agoraphobia", "guilt", "horror", "whisperingmadness"},
    bellwort = {"timeloop", "justice", "lovers", "peace", "pacified", "generosity", "indifference", "retribution", "diminished", "pyre", "stridulating"},
    kelp = {"parasite", "weariness",  "asthma", "healthleech", "clumsiness", "sensitivity", "rebbies"},
    ash = {"confusion", "hypersomnia", "hallucinations", "paranoia", "dementia", "crescendo"},
    ginseng = {"flushings", "lethargy", "haemophilia", "addiction", "nausea", "scytherus", "darkshade", "unweavingbody"},
}

-- Global-ish table to track pending crushedthroat applies
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.crushedCheck = {
    pending = false,
    timer = nil,
    lastApply = 0
}

function haveSmokeAff()
    local smoke = false
    local sAffs = {"deadening", "tension",
        "disloyalty", "hellsight", "manaleech", "slickness", "unweavingspirit"}

    for i=1, #sAffs do
        if haveAff(sAffs[i]) then
            smoke = true
            break
        end
    end

    return smoke
end

function hasSalveAff()
  local salve = false
  local sAffs = {"frozen", "shivering", "anorexia", "burns", "ablaze", "selarnia",
    "damagedleftleg", "damagedrightleg", "mangledleftleg", "mangledrightleg",
    "damagedleftarm", "damagedrightarm", "mangledleftarm", "mangledrightarm",
    "brokenleftarm", "brokenrightarm", "brokenleftleg", "brokenrightleg"}

  for i=1, #sAffs do
    if haveAff(sAffs[i]) then
      salve = true
      break
    end
  end

  return salve
end

function restorePassiveCure()
  cecho("\n<green>+ "..passiveFailsafe.." +")
  tAffs[passiveFailsafe] = true
  passiveFailsafe = nil
end

function taRaged()
	if tAffs.retribution then erAff("retribution") end
	local gAffs = {"timeloop", "justice", "lovers", "peace", "pacified", "generosity", "indifference",}
	for i=1, #gAffs do
		if tAffs[gAffs[i]] then
			erAff(gAffs[i])
			break
		end
	end
end

function tFocused()
	local gAffs = {"stuttering", "stupidity", "recklessness", "hallucinations", "epilepsy", "confusion", "dizziness", "vertigo", "anorexia",  
		"earthdisrupt", "masochism", "agoraphobia", "airdisrupt", "claustrophobia", "dementia", "firedisrupt", "loneliness", "lovers",
		"pacified", "paranoia", "peace", "shyness", "waterdisrupt",}
	-- v4.7.371 (WHATCURES): generosity is bellwort-only, not focus; peace IS focus.

	erAff("impatience")
  erAff("sandfever")
	
	--Readd last goldenseal, if there was any.
	if lastGoldenseal and lastGoldenseal ~= "impatience" then
		tAffs[lastGoldenseal] = true
		lastGoldenseal = nil
		ataxiaEcho("Backtracked impatience being cured with last eat.")
	end

	for i=1, #gAffs do
		if tAffs[gAffs[i]] then
			if gAffs[i] ~= "anorexia" and haveAff("anorexia") then
				anorexiaFailsafe = true
				lastFocus = gAffs[i]
				tempTimer(1.2, [[anorexiaFailsafe = nil; lastFocus = nil]])
			end
			erAff(gAffs[i])
			break
		end
	end
end

function tSingleRandom()
	local gAffs = {"aeon", "pyramides", "flushings", "crushedthroat", "sandfever", "paralysis", "timeloop", "lethargy", "depression", 
    "hypersomnia", "retribution", "confusion", "darkshade", "healthleech", "hypochondria", "manaleech",  "nausea",
    "parasite", "shivering", "frozen", "spiritburn", "clumsiness", "sensitivity", "scytherus", "tenderskin", "stupidity", "haemophilia", 
    "weariness", "hallucinations", "dizziness", "justice", "recklessness", "epilepsy", "addiction", "hallucinations", "loneliness", "shyness", 
    "vertigo", "paranoia", "agoraphobia", "claustrophobia", "generosity", "pacifism", "disloyalty", "selarnia", "frozen","brokenleftleg","brokenrightleg","brokenleftarm","brokenrightarm",}

  --[Experimental passive handling for lock affs]--
  passiveFailsafe = false
  if haveAff("asthma") and haveAff("slickness") then
    table.insert(gAffs, 35, "asthma")
    passiveFailsafe = true
  else
    table.insert(gAffs, 9, "asthma")
  end
  
  if haveAff("anorexia") then
    if haveAff("impatience") or haveAff("sandfever") or haveAff("slickness") then
      table.insert(gAffs, 35, "anorexia")
      passiveFailsafe = true
    else
      table.insert(gAffs, 12, "anorexia")
    end
  end
  
  if haveAff("slickness") and hasSalveAff() then
    table.insert(gAffs, 35, "slickness")
    passiveFailsafe = true
  else
    table.insert(gAffs, 9, "slickness")
  end
  
  if haveAff("impatience") and haveAff("anorexia") then
    table.insert(gAffs, 35, "impatience")
    passiveFailsafe = true
  else
    table.insert(gAffs, 15, "impatience")
  end

  --[Continue on as per the usual curing]--
  
	for i=1, #gAffs do
		if tAffs[gAffs[i]] then
			if gAffs[i] == "haemophilia" then 
				tAffs.bleed = 0
			end
			erAff(gAffs[i])
			cecho("<red> -"..gAffs[i])
      if passiveFailsafe then 
        passiveFailsafe = gAffs[i] 
        tempTimer(0.5, [[passiveFailsafe = nil]])
      end
			break
		end
	end
end

function tMultipleRandom(amt)
	local num = tonumber(amt)
	local gAffs = {"aeon", "anorexia", "pyramides", "flushings", "crushedthroat", "sandfever", "paralysis", "asthma", "timeloop", "lethargy", "depression", "impatience", 
    "hypersomnia", "retribution", "confusion", "darkshade", "healthleech", "hypochondria", "slickness", "manaleech", 
    "parasite", "shivering", "frozen", "spiritburn", "clumsiness", "sensitivity", "nausea", "scytherus", "tenderskin", "stupidity", "haemophilia", 
    "weariness", "hallucinations", "dizziness", "justice", "recklessness", "epilepsy", "addiction", "hallucinations", "loneliness", "shyness", 
    "vertigo", "paranoia", "agoraphobia", "claustrophobia", "generosity", "pacifism", "disloyalty", "selarnia", "frozen","brokenleftleg","brokenrightleg","brokenleftarm","brokenrightarm",}
		
	for i=1, #gAffs do
		if tAffs[gAffs[i]] and num > 0 then
			if gAffs[i] == "haemophilia" then 
				tAffs.bleed = 0
			end
			erAff(gAffs[i])
			num = num - 1
		elseif num == 0 then
			break
		end
	end
end