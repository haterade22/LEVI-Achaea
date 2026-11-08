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

-- A party member called an affliction on the target (triggers 426, 428, 436). The called word can
-- be a venom ("curare"), so it is turned into its affliction first. It goes in through tarAffed,
-- which gives it to V3 as well as tAffs. Until the 2026-11-08 deep review (H2) this wrote tAffs
-- alone: V3 never held the affliction, so no herb, tree or focus cure could take it off again, and
-- haveAff (which reads V3) said the target did not have what tAffs said it had. The callers also
-- passed the raw word to tarAffed / confirmAffV2, which put "curare" into V3 as an affliction of
-- its own; they now pass every word through here instead. A call is a confirmation, so it is
-- applied even when the affliction is already believed (it raises a branch-split one to certain);
-- the " +aff+" echo still shows only a new one.
function paAff(affGave)
	if type(affGave) ~= "string" then return end
	local word = affGave:lower()
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
		if i == word then
			affC = v
			break
		end
	end

	local aff = affC or word
	if not haveAff(aff) then
		cecho(" <green>+"..aff.."+")
	end
	tarAffed(aff)
end

-- A KNOWN CURE LINE RIGHT AFTER A RANDOM ONE (2026-11-08 deep review, F14 and F43).
--
-- Some cures print a second line that names what they took:
--   Archaeon eats a plumbum flake.
--   Lucidity returns to the eyes of Archaeon.
-- (kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt:536-537, 1643-1644 and
-- 5877-5878, always on the very next line). The eat trigger charges V3's random cure on its own
-- line, branching over every affliction the herb cures; the known-cure trigger then erased the
-- named one from every branch as well. One eat took two afflictions: a target with stupidity and
-- shadowmadness was left at stupidity 0.33 and shadowmadness 0, where the truth is 1 and 0.
--
-- The random cure still runs on its own line, so a reader between the two lines sees the eat
-- (deferring the whole eat to the next line, as herbs/009 and 010 do, would make the prompt
-- trigger read the target from before the eat). The known line now REPLACES that random cure:
--
--   ataxia_randomCureV3(kind, who, cure)  runs cure() (the V3 random cure) and keeps a copy of the
--                                         branches from before it and after it. kind is the herb
--                                         ("goldenseal"), "smoke" or "focus".
--   ataxia_knownCureV3(kind, who, aff)    a line named the cure: put the "before" branches back,
--                                         take out what the action itself proved (anorexia for an
--                                         eat, asthma for a smoke, impatience for a focus) and aff,
--                                         and drop the action's pending negative confirmation.
--                                         Returns true when it did.
--
-- It does nothing (and returns false) unless the random cure was `who`'s, of this kind, under
-- KNOWN_CURE_WINDOW seconds ago, and nothing has changed the branches since, leaving aff aside: a
-- hit that landed between the two lines must not be undone. The caller still erases aff with
-- erAff (tAffs, the "target cured aff" event, the display), or leaves that to a trigger that
-- already does it on the same line (other_things_fading/002 for lovers). Either order works,
-- because aff is left out of the comparison.
ataxia_KNOWN_CURE_WINDOW = 0.5

local function knownCureCopy(states)
	local out = {}
	for i, s in ipairs(states) do
		local affs = {}
		for k, v in pairs(s.affs) do affs[k] = v end
		out[i] = { affs = affs, prob = s.prob }
	end
	return out
end

-- The branches as a set: each distinct affliction set with its summed weight, `skip` left out. So
-- two branches that differ only in `skip` and were merged after it was erased still compare equal.
local function knownCureKey(states, skip)
	local sums, keys = {}, {}
	for _, s in ipairs(states) do
		local list = {}
		for aff in pairs(s.affs) do
			if aff ~= skip then list[#list + 1] = aff end
		end
		table.sort(list)
		local h = table.concat(list, "|")
		if not sums[h] then
			sums[h] = 0
			keys[#keys + 1] = h
		end
		sums[h] = sums[h] + s.prob
	end
	table.sort(keys)
	for i, h in ipairs(keys) do keys[i] = h .. "=" .. string.format("%.4f", sums[h]) end
	return table.concat(keys, ";")
end

-- What the action proves absent whatever it cured, and the negative confirmation it starts.
local function knownCureKind(kind)
	if kind == "focus" then return "impatience", nil end
	if kind == "smoke" then return "asthma", "smoke_negconf" end
	return "anorexia", "herb_negconf"
end

function ataxia_randomCureV3(kind, who, cure)
	ataxiaTemp = ataxiaTemp or {}
	if type(afflictionStatesV3) ~= "table" then
		ataxiaTemp.lastRandomCure = nil
		return cure()
	end
	local before = knownCureCopy(afflictionStatesV3)
	cure()
	ataxiaTemp.lastRandomCure = {
		kind = kind,
		who = type(who) == "string" and who:lower() or nil,
		at = getEpoch(),
		before = before,
		after = knownCureCopy(afflictionStatesV3),
	}
end

function ataxia_knownCureV3(kind, who, aff)
	local r = ataxiaTemp and ataxiaTemp.lastRandomCure
	if not r then return false end
	ataxiaTemp.lastRandomCure = nil
	if r.kind ~= kind or type(who) ~= "string" or r.who ~= who:lower() then return false end
	if getEpoch() - r.at > ataxia_KNOWN_CURE_WINDOW then return false end
	if type(afflictionStatesV3) ~= "table" then return false end
	if knownCureKey(afflictionStatesV3, aff) ~= knownCureKey(r.after, aff) then return false end

	local proved, negconf = knownCureKind(kind)
	for _, s in ipairs(r.before) do
		s.affs[proved] = nil
		s.affs[aff] = nil
	end
	afflictionStatesV3 = r.before
	if negconf and negativeConfirmTimersV3 and negativeConfirmTimersV3[negconf] then
		killTimer(negativeConfirmTimersV3[negconf])
		negativeConfirmTimersV3[negconf] = nil
		if lastGuessV3 and lastGuessV3.cureType and lastGuessV3.cureType .. "_negconf" == negconf then
			lastGuessV3 = nil
		end
	end
	deduplicateStatesV3()
	pruneStatesV3()
	rebuildCacheV3()
	syncToOldSystemV3()
	updateAffDisplayV3()
	return true
end