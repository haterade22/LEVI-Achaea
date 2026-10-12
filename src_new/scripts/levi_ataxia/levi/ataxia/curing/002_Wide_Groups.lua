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
	-- (sandfever is goldenseal-cured, not focus -- WHATCURES; no longer erased here, v4.7.372)
	
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

-- Guess the ONE affliction a single random cure took, erase it, and return it.
-- opts.noErase: return the pick and change nothing. Trigger 389 passes it when V3 has already
-- charged the tree: onTargetTreeV3 branches over every tree-curable affliction, so erasing here as
-- well charged one tree twice (asthma + slickness + blackout read 4/3 afflictions after one tree,
-- where the truth is 2). Skipped with the erase: the bleed reset, the echo, and the passiveFailsafe
-- bookkeeping. That bookkeeping exists only to UNDO this erase: restorePassiveCure() writes the
-- erased affliction back into tAffs when a cure line follows within 0.5 s. With nothing erased
-- there is nothing to restore, and setting it would make that cure line add back an affliction
-- this function never took.
function tSingleRandom(opts)
	local noErase = opts and opts.noErase
	local gAffs = {"aeon", "pyramides", "flushings", "crushedthroat", "sandfever", "paralysis", "timeloop", "lethargy", "depression",
    "hypersomnia", "retribution", "confusion", "darkshade", "healthleech", "hypochondria", "manaleech",  "nausea",
    "parasite", "shivering", "frozen", "spiritburn", "clumsiness", "sensitivity", "scytherus", "tenderskin", "stupidity", "haemophilia",
    "weariness", "hallucinations", "dizziness", "justice", "recklessness", "epilepsy", "addiction", "hallucinations", "loneliness", "shyness",
    "vertigo", "paranoia", "agoraphobia", "claustrophobia", "generosity", "pacifism", "disloyalty", "selarnia", "frozen","brokenleftleg","brokenrightleg","brokenleftarm","brokenrightarm",}

  --[Experimental passive handling for lock affs]--
  -- late: a lock affliction was moved to the back of the list (position 35).
  local late = false
  if haveAff("asthma") and haveAff("slickness") then
    table.insert(gAffs, 35, "asthma")
    late = true
  else
    table.insert(gAffs, 9, "asthma")
  end

  if haveAff("anorexia") then
    if haveAff("impatience") or haveAff("sandfever") or haveAff("slickness") then
      table.insert(gAffs, 35, "anorexia")
      late = true
    else
      table.insert(gAffs, 12, "anorexia")
    end
  end

  if haveAff("slickness") and hasSalveAff() then
    table.insert(gAffs, 35, "slickness")
    late = true
  else
    table.insert(gAffs, 9, "slickness")
  end

  if haveAff("impatience") and haveAff("anorexia") then
    table.insert(gAffs, 35, "impatience")
    late = true
  else
    table.insert(gAffs, 15, "impatience")
  end
  if not noErase then passiveFailsafe = late end

  --[Continue on as per the usual curing]--

	for i=1, #gAffs do
		if tAffs[gAffs[i]] then
			if noErase then return gAffs[i] end
			if gAffs[i] == "haemophilia" then
				tAffs.bleed = 0
			end
			erAff(gAffs[i])
			cecho("<red> -"..gAffs[i])
      if passiveFailsafe then
        passiveFailsafe = gAffs[i]
        tempTimer(0.5, [[passiveFailsafe = nil]])
      end
			return gAffs[i]
		end
	end
end

-- One target tree with V3 on (trigger 389, every class). onTargetTreeV3 (008) charges the tree by
-- branching over the tree pool; this does the two things it leaves undone, through the public API.
--  1. An affliction the tree removes from EVERY branch (in each it was the only one the tree could
--     take) leaves V3 but not tAffs: syncToOldSystemV3 (007:975) only visits afflictions still in
--     some branch. A lone asthma then read 0 to haveAff and true to every tAffs reader, the Shikudo
--     lock's checkSoftlock among them (shikudo/007:85). tSingleRandom's erase used to hide this. So
--     every pool affliction that was there before the tree and is gone after is erased, which also
--     raises "target cured aff" for the cure.
--  2. The four level-1 broken limbs are in the pool (008:273) but simple-tracked (007:80), and
--     onTargetTreeV3 only looks in the branches. When no branch held anything else the tree could
--     take, the tree took a limb: the first present in the pool's order goes (left leg, right leg,
--     left arm, right arm, the order tSingleRandom erased them in). Beside a branch candidate the
--     limb stays, because V3 cannot branch a simple-tracked affliction.
function ataxia_targetTreeV3()
  -- Asked before the tree starts its balance. False: V3 calls this tree an illusion (008:296) and
  -- charges nothing, so the limb is not charged either.
  local accepted = not canTargetCureV3 or canTargetCureV3("tree")
  local simple = {}
  for _, a in ipairs(simpleTrackAffsV3 or {}) do simple[a] = true end
  local had, limb, inBranch = {}, nil, false
  for _, a in ipairs(treeCurableAffsV3) do
    if getAffProbabilityV3(a) > 0 then
      had[#had + 1] = a
      if not simple[a] then
        inBranch = true
      elseif not limb then
        limb = a
      end
    end
  end

  onTargetTreeV3()

  -- ataxia_tarAffFaded, not erAff: it also stops a timed affliction's expiry clock (blackout,
  -- 017), which would otherwise erase it a second time. 0.01 is the sync's own floor (007:982).
  for _, a in ipairs(had) do
    if getAffProbabilityV3(a) < 0.01 then ataxia_tarAffFaded(a) end
  end
  if accepted and not inBranch and limb then ataxia_tarAffFaded(limb) end
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