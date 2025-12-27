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
		"earthdisrupt", "masochism", "agoraphobia", "airdisrupt", "claustrophobia", "dementia", "firedisrupt", "generosity", "loneliness", "lovers", 
		"pacified", "paranoia", "shyness", "stuttering", "waterdisrupt",}

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