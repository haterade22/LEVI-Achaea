--[[mudlet
type: script
name: Miscellaneous Aff Tracking Methods
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Miscellaneous Aff Tracking Methods
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--In-testing function for Psion bleed tracking. May or may not work.
function psion_bleedAdd(num)
	local tobleed = tonumber(num)
	tAffs.bleed = tAffs.bleed or 0
	tAffs.bleed = tAffs.bleed + tobleed
	
	if not haveAff("haemophilia") and tAffs.bleed >= 100 then
		tAffs.bleed = tAffs.bleed - 50
    if tAffs.bleed < 0 then
      tAffs.bleed = 0
    end
	end
end	

--For the purpose of enlighten tracking.
function checkInstills()
  local x = 0
  for _, aff in pairs({"asthma", "clumsiness", "slickness", "darkshade", "healthleech", "paralysis", "sensitivity"}) do
    if haveAff(aff) then
      x = x + 1
    end
  end
  return x
end

function checkEnlighten()
	local enlightenAffs = {
    "claustrophobia", "agoraphobia", "lovers", "dementia", "epilepsy", "hallucinations", "confusion", "stupidity",
    "paranoia", "vertigo", "shyness", "addiction", "recklessness", "masochism"  
  }

	local c = 0
	local need = (haveAff("whisperingmadness") and 4 or 5)
  
	for _, aff in pairs(enlightenAffs) do
		if haveAff(aff) then
			c = c + 1
		end
	end
	
	if c >= need then 
    return true 
	else 
		return false 
	end
	
end

function getTzantzaAffs()
	local c = 0
	local tzantza = {"agoraphobia", "amnesia", "claustrophobia", "confusion", "dementia", "dizziness", "epilepsy", "impatience",
		"masochism", "paranoia", "recklessnesS", "stupidity", "vertigo", "addiction"}

	for i,v in pairs(tzantza) do
		if haveAff(v) then
			c = c + 1
		end
	end
	return c
end

function getLatchAffs()
	local c = 0
	local latch = {"addiction", "haemophilia", "nausea", "lethargy"}
	
	for _, aff in pairs(latch) do
		if haveAff(aff) then
			c = c + 1
		end
	end
	return c
end

function getMentalAffCount()
	local c = 0
	local mentals = {"agoraphobia", "anorexia", "claustrophobia", "confusion", "dementia", "dizziness", "epilepsy", "hallucinations", 
		"impatience", "loneliness", "masochism", "paranoia", "recklessness", "shyness", "stupidity", "vertigo"}

	for _, aff in pairs(mentals) do
		if haveAff(aff) then
			c = c + 1
		end
	end
	return c
end

function getAffsFromTree(tree)
  if not curingTable[tree] then return 0 end
  local c = 0
  for _, aff in pairs(curingTable[tree]) do
    if haveAff(aff) then
      c = c + 1
    end
  end
  return c  
end

function checkAffList(afflictions, number)
  if number == 0 then return true end
  if type(afflictions) ~= "table" then return false end
  if not number then number = 1 end
  
  local count = 0
  for _, aff in pairs(afflictions) do
    if haveAff(aff) then
      count = count + 1
    end
  end
  if count >= number then
    return true
  else
    return false
  end
end

function tarNeedsWeariness()
	local wc = {"Monk", "Runewarden", "Infernal", "Paladin", "Blademaster", "Serpent"}
	if ataxiaNDB and ataxiaNDB_Exists(target) then
		local gClass = ataxiaNDB_getClass(target)
		if table.contains(wc, gClass) then
			return true
		else
			return false
		end
	else
		return false
	end
end

--Works both ways. curseConvert("clumsy") will return clumsiness.
-- curseConvert("clumsiness") will return clumsy.
function toCurse(curse)
	local curses = {
		paralyse = "paralysis",
		vomiting = "nausea",
		stupid = "stupidity",
		clumsy = "clumsiness",
		dizzy = "dizziness",
		plague = "voyria",
    reckless = "recklessness",
	}
  for a, c in pairs(curses) do
    if a == curse then
      return c
    elseif c == curse then
      return a
    end
  end
  return curse
end
--Merely for the triggers. The above is for aliases.
function curseConvert(curse)
	local curses = {
		paralyse = "paralysis",
		vomiting = "nausea",
		stupid = "stupidity",
		clumsy = "clumsiness",
		dizzy = "dizziness",
		plague = "voyria",
    reckless = "recklessness",
	}
  for a, c in pairs(curses) do
    if a == curse then
      return c
    end
  end
  return curse
end

function venom_to_aff(venom)
	local affC
	local venom_to_affliction = {
		xentio = "clumsiness",			eurypteria = "recklessness",
		kalmia = "asthma",					digitalis = "shyness",
		darkshade = "darkshade",			curare = "paralysis",
		prefarar = "sensitivity",		monkshood = "disloyalty",
		euphorbia = "nausea",				vernalius = "weariness",
		larkspur = "dizziness",			slike = "anorexia",
		notechis = "haemophilia",		vardrax = "addiction",
		aconite = "stupidity",			gecko = "slickness",
		voyria = "voyria",					delphinium = "sleep",
		nechamandra = "shivering",	scytherus = "scytherus",
		epseth = "legbreak",				epteth = "armbreak",
    selarnia = "selarnia",
    -- Hellforge abilities
    torment = "healthleech",
    torture = "haemophilia",
    exploit = "weariness",
    punishment = "punishment",
	}
	for i,v in pairs(venom_to_affliction) do
		if i == venom then
			affC = v
			break
		elseif v == venom then
			affC = i
			break
		end
	end
	
	if affC == "epseth" or affC == "legbreak" then
		if haveAff("brokenleftleg") or tAffs.damagedleftleg then
			affC = "brokenrightleg"
		else
			affC = "brokenleftleg"
		end
	
  elseif affC == "epteth" or affC == "armbreak" then
		if haveAff("brokenleftarm") or tAffs.damagedleftarm then
			affC = "brokenrightarm"
		else
			affC = "brokenleftarm"
		end
	end
	
	return affC
end

function psionBlastCount()
	local cnt = 0
	local dis = {"impatience", "stupidity", "blackout", "dizziness", "epilepsy", "unweavingmind"}
	for i,v in pairs(dis) do
		if tAffs[v] then
			cnt = cnt + 1
		end
	end
	return cnt
end

function petrifyCount()
	local cnt = 0
	local dis = {"dizziness", "recklessness", "confusion", "epilepsy", "impatience", "hallucinations", "paranoia"}
	for i,v in pairs(dis) do
		if tAffs[v] then
			cnt = cnt + 1
		end
	end
	return cnt
end

function paAff(affGave)
	local affC = false
	local venom_to_affliction = {
		xentio = "clumsiness",			eurypteria = "recklessness",
		kalmia = "asthma",					digitalis = "shyness",
		darkshade = "darkshade",			curare = "paralysis",
		prefarar = "sensitivity",		monkshood = "disloyalty",
		euphorbia = "nausea",				vernalius = "weariness",
		larkspur = "dizziness",			slike = "anorexia",
		notechis = "haemophilia",		vardrax = "addiction",
		aconite = "stupidity",			gecko = "slickness",
		voyria = "voyria",					delphinium = "sleep",
    selarnia = "selarnia",
	}

	for i,v in pairs(venom_to_affliction) do
		if i == affGave:lower() then
			affC = v
			break
		end
	end

	if not affC then
		if not tAffs[affGave] then
			tAffs[affGave] = true
			cecho(" <green>+"..affGave.."+")
		end
	else
		if not tAffs[affC] then
			tAffs[affC] = true
			cecho(" <green>+"..affC.."+")
		end
	end
end