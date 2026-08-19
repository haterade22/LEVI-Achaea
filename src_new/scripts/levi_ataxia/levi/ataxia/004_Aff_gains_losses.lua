--[[mudlet
type: script
name: Aff gains/losses
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > System-related > Curing Stuff > Aff gains/losses

-- Darkshade Duration Tracker
-- Auto-prioritizes darkshade cure after threshold seconds to prevent prolonged sunlight damage
ataxia.darkshadeTracker = ataxia.darkshadeTracker or {
    timerId = nil,
    threshold = 17,  -- seconds before auto-prioritize
    prioritized = false
}

function confirmedUnknownAff()
	if line:match("You feel your allergy to the sun going into temporary remission.")
		or line:match("Your insomnia has cleared up.")
		or line:match("Your insulating unguent dissolves as it ameliorates the extreme cold.")
		or line:match("You gasp as your fine-tuned reflexes disappear into a haze of confusion.") 
		or line:match("Your hearing is suddenly restored.") then
	else
		if ataxia.afflictions.unknown == nil then ataxia.afflictions.unknown = 0 end
		ataxia.afflictions.unknown = ataxia.afflictions.unknown + 1
		if ataxiaBasher and ataxiaBasher.enabled and ataxia.afflictions.unknown >= 2 and not sent_diagnose then
			send("queue addclear free diagnose", false)
			sent_diagnose = tempTimer(3, [[sent_diagnose = nil]])
		end
	end
end

-- TRUTHSEEKER (Mnemosyne boon, uncommon, v4.7.257): "The God of Darkness allows your eyes to
-- perceive the truth of all hidden afflictions that may befall you."
--
-- User: "When we have this boon, the ? in our prompt isnt true." Exactly right -- there are no
-- hidden afflictions to count while it is held, so every `?` is a phantom.
--
-- The cosmetic half is the least of it. `ataxia.afflictions.unknown` is a COUNTER that only
-- ever goes up here, and it is read as a real affliction by `S._afflicted()` (mnemosyne/009):
--
--     if k == "unknown" then if type(v) == "number" and v > 0 then return true end
--
-- So a phantom count makes us permanently "afflicted" -- `S._reenterReady()` can never pass and
-- every recovery hover burns its full 60s cap. The screenshot shows roughly twenty of them
-- accumulated, which is that gate wedged shut for the rest of the run. Same shape as the
-- manaleech bug (v4.7.252), and worse, because nothing ever decrements this.
--
-- It also spams `diagnose` -- the `>= 2` branch below fires a queued diagnose to resolve
-- afflictions that were never hidden in the first place.
--
-- Refused at the SOURCE rather than filtered at each reader: the boon means the input is
-- wrong, so nothing downstream should have to know about it.
function gotUnknownAff()
	if mnemTruthseeker then
		-- Also drop anything banked before the boon was latched (claimed mid-run, or re-latched
		-- from the BOONS list after a reload), so the prompt clears rather than keeping its
		-- phantoms until the next full cure.
		ataxia.afflictions.unknown = nil
		return
	end
	if ataxia.vitals.hp == ataxia.vitals.maxhp and ataxia.vitals.mp == ataxia.vitals.maxmp then
		send("curing predict recklessness")
	elseif not ataxiaTemp.lokiCheck then
		tempLineTrigger(1, 1, [[confirmedUnknownAff()]])
	end
end

function affed(what)
	local v = ataxia.afflictions[what:lower()]
	-- 0 IS TRUTHY IN LUA. Every stacking affliction sits at 0 once cured (lostAff zeroes
	-- rather than nils, so the prompt's numeric renderer and checkDamnationThreat's
	-- `or 0` both keep working), and setafflictionstackslevi plants sixteen zeroes on
	-- reset -- so a bare truthiness test reported a burn we had just put out.
	if v == nil or v == false then return false end
	if type(v) == "number" then return v > 0 end
	return true
end

-- Stacking afflictions arrive from GMCP as <base><count>: burning3, horror5, pyre2.
-- ONE owner for the list -- 015_Set_Affliction_Stacks_to_Zero.lua resets the same names
-- and test_combat_tables.lua pins them, so a third copy is a drift waiting to happen.
-- Deliberately a file-local behind an accessor rather than a field on ataxiaTables: that
-- namespace is assigned wholesale in places, and a list that can be silently emptied by an
-- unrelated `ataxiaTables = {...}` would turn the reset below into a quiet no-op.
local STACK_AFFS = {
  "horror", "pyre", "unweavingspirit", "unweavingmind", "unweavingbody",
  "temperedsanguine", "temperedcholeric", "temperedmelancholic", "temperedphlegmatic",
  "pressure", "crackedribs", "torntendons", "skullfractures", "wristfractures",
  "burning", "crescendo",
}

-- Returns a COPY. The point of a single owner is that nobody else can change it, and
-- handing out the live table would let any caller empty the list that drives
-- setafflictionstackslevi.
function ataxia_stackAffs()
	local out = {}
	for i, v in ipairs(STACK_AFFS) do out[i] = v end
	return out
end

-- The afflictions that can change a Damnation verdict: both kill routes plus the broken
-- head they share. Kept beside the stack list because the burn route IS a stack level.
DAMNATION_AFFS = {
  pyre = true, burning = true, guilt = true, spiritburn = true,
  damagedhead = true, brokenhead = true, mangledhead = true,
}

-- Returns base, count -- or nil when the name is not a stacking affliction.
-- A bare name decodes to count 1: that is what the server sends at one stack.
--
-- The old test was `tonumber(string.sub(aff, -2, -2))` -- the SECOND-TO-LAST character --
-- which is nil for every single-digit suffix ("burning3" tests "g") and returns the TENS
-- digit for a two-digit one. So the stack path never ran for the names Achaea actually
-- sends, and gotAff stored a BOOLEAN under the suffixed key instead. Three silent
-- consequences, none of which announced itself:
--   * the prompt burn counter never rendered -- numericAffDisplay (005) keys on the BARE
--     name, so `afflictions.burning3 = true` matched nothing;
--   * checkDamnationThreat read `ataxia.afflictions.burning or 0` as permanently 0, i.e.
--     the Paladin kill-condition alarm was blind at the source;
--   * S._afflicted (mnemosyne/009) counts `v == true` and parkedAff cannot excuse a
--     suffixed key, so one `burning3 = true` held the recovery hover to its full 60s cap
--     for the rest of a fire ripple -- the manaleech bug a third time.
--
-- Matching the base by EQUALITY rather than the old `aff:find(x)` substring scan also
-- removes an ordering hazard: that loop kept the LAST match, so any future affliction
-- whose name merely CONTAINED a stack name would have been decoded as one.
function ataxia_stackAff(aff)
	if type(aff) ~= "string" then return nil end
	local base, digits = aff:lower():match("^(%a+)(%d*)$")
	if not base then return nil end
	for _, x in ipairs(STACK_AFFS) do
		if base == x then return base, tonumber(digits) or 1 end
	end
	return nil
end

-- `zero` is retained for the tests and for any caller that wants the reset shape, but
-- lostAff deliberately does NOT use it: the removal rule there is conditional (zero only
-- when the removed count is the one still held), which a boolean flag cannot express.
function setStackAff(aff, zero)
	local base, count = ataxia_stackAff(aff)
	-- An unrecognised name used to fall through with tow = "" and write
	-- ataxia.afflictions[""] -- a key rTabSize counts, so the prompt's affliction bracket
	-- printed forever off a name we did not even model.
	if not base then return end
	ataxia.afflictions[base] = zero and 0 or count
end

function afflictionList()
	local affs = gmcp.Char.Afflictions.List
  local ignore = {"blindness", "deafness", "insomnia","deathsickness",}
 
	
 
	ataxia.afflictions = {}
	sent_diagnose = nil

	-- The herb-stack counters are DERIVED from ataxia.afflictions, and Stack_My_Affs only
	-- ever steps them by one. This handler is the single place the affliction table is
	-- rebuilt from scratch, so without a matching reset every cure that follows decrements a
	-- count whose gain was never recorded and the numbers walk away from reality. Latent
	-- until v4.7.274 -- lostAff used to hand Stack_My_Affs the gmcp TABLE, which matched
	-- nothing, so the decrement path had never run.
	if Algedonic and Algedonic.mystack then
		for herb in pairs(Algedonic.mystack) do Algedonic.mystack[herb] = 0 end
	end

	ataxia.affCures = ataxia.affCures or {} -- reference: server's cure command per affliction (Char.Afflictions.cure)
	for _, affl in pairs(affs) do
		local aff = affl.name
		if affl.cure then ataxia.affCures[aff:lower()] = affl.cure end
		if not table.contains(ignore, aff:lower()) then
			local base = ataxia_stackAff(aff)
			if base then
				setStackAff(aff)
			else
				base = aff:lower()
				ataxia.afflictions[base] = true
				raiseEvent("aff gained", base)
			end
			-- Counted ONCE per affliction, not once per stack: the herb counters measure how
			-- many afflictions contend for a cure balance, and a five-stack burn is still one.
			if Algedonic and Algedonic.Stack_My_Affs then Algedonic.Stack_My_Affs(true, base) end
		end
  Algedonic.AffCount = Algedonic.Count_My_Affs() 
	end
  
  -- Attack dispatch now handled by unified tryAttack() gate in prompt handler
  if zgui then zgui.showAffs() end
end

function gotAff()
	local ignore = {"blindness", "deafness", "insomnia"}
	local aff = gmcp.Char.Afflictions.Add.name
	if gmcp.Char.Afflictions.Add.cure then
		ataxia.affCures = ataxia.affCures or {}
		ataxia.affCures[aff:lower()] = gmcp.Char.Afflictions.Add.cure
	end
	if not table.contains(ignore, aff) then
  	if ataxia_stackAff(aff) then
			setStackAff(aff)
		else
			ataxia.afflictions[aff:lower()] = true
      local parAff = "incoming_"..aff
      ataxia.afflictions[parAff] = nil
		end
	end

	if aff == "guilt" then
		send("curing focus off")
	elseif aff == "amnesia" then
		send("touch friends")
  elseif aff == "paralysis" then
   send("endure")
  elseif aff == "prone" and not ataxia.afflictions.aeon then
  --Smoke for Rebounding - Serverside doesn't put it up
    send("smoke malachite") 
  ---AUTO TUMBLER
  --If we have the below afflictions then tumble
    if ataxia.afflictions.damagedrightleg and ataxia.afflictions.damagedleftleg and ataxiaNDB_getClass(target) ~= "Blademaster" then
    getdirectionn()
    send("tumble " ..random_direction)
    elseif ataxia.afflictions.damagedrightleg and ataxia.afflictions.damagedleftleg and ataxiaNDB_getClass(target) == "Blademaster" then
    expandAlias("hh")
    elseif ataxia.afflictions.brokenrightarm and ataxia.afflictions.brokenleftarm then
    local cls = ataxiaNDB_getClass(target)
    if cls == "Infernal" or cls == "Apostate" then
      send("restore")
    end
    end
  --Sentinel Restore to Prevent Rift Lock
  --elseif aff == "brokenrightarm" or aff == "brokenleftarm" and ataxia.afflictions.prone and ataxiaNDB_getClass(target) == "Sentinel" then
    --send("restore")
  -- Sentinel Touch Shield to Prevent Rift Lock
  
  
  --Druid Nonsense
  elseif aff == "damagedrightarm" or aff == "damagedleftarm" and not ataxia.afflictions.prone and ataxiaNDB_getClass(target) == "Druid" then
    send("cq all;goto 11090")
    ataxia_boxEcho("EMBRACE DANGER NEED TO RUN", "goldenrod")
    ataxia_boxEcho("EMBRACE DANGER NEED TO RUN", "goldenrod")

  elseif aff == "entangled" and ataxiaNDB_getClass(target) == "Druid" then
    getdirectionn()
    send("apply mass to arms")
    send("curing queue insert 1 restoration to legs")
    ataxia_boxEcho("WE ARE PREAPPLYING", "yellow")
    send("tumble " ..random_direction)
   elseif aff == "damagedrightleg" or aff == "damagedleftleg" and ataxia.afflictions.prone and ataxiaNDB_getClass(target) == "Druid" then
    getdirectionn()
    send("tumble " ..random_direction)
    
  -- This is to prepare for DISEMBOWEL from /BM
	elseif aff == "internalbleeding" then
    tempTimer(2, [[send("curing queue insert 1 restoration to legs"), ataxia_boxEcho("WE ARE PREAPPLYING", "yellow")]])
    ataxia_boxEcho("PREPARE THINE ANUS FOR ENTRY", "a_darkred")
  -- Handle Blackout
	elseif aff == "blackout" then
  
		if ataxiaBasher.enabled and ataxiaBasher.treeblackout then
			send("touch tree")
		elseif type(target) == "string" and ataxiaNDB_getClass(target) == ("Runewarden" or "Infernal" or "Paladin") then
			tempTimer(2.5, [[send("curing predict impaled",false)]])
		end
	elseif aff == "prone" then
		if ataxiaBasher.enabled then
			send("queue prepend eqbal stand")
		end
	elseif aff == "corruption" then
		send("curing clotat 9999",false)
		ataxia_boxEcho("CORRUPTION ON US - MANUAL CLOT", "a_darkred")
	elseif (aff == "entangled" or aff == "webbed") then
    if (gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class or ""):find("Dragon") then
      -- DRAGONFLEX (AB 1534: self, 2.00s balance) snaps through bindings -- one
      -- action instead of repeated writhes. Prepend so it fires the instant balance
      -- allows (the prone -> stand idiom); SSC writhing still backstops it.
      send("queue prepend eqbal dragonflex", false)
    elseif ataxia_isClass("bard") then
		  send("queue addclear class recite haidar",false)
    elseif ataxia_isClass("pariah") then
      send("accursed reconstitute", false)
    end
  -- Handle Retardation or Aeon
  elseif aff == "aeon" and ataxia.afflictions.asthma then
    send("curing prioaff asthma")
    partyrelay = false
    retardationOn()
  elseif aff == "aeon" and not ataxia.retardation then
    send("curing prioaff aeon")
    partyrelay = false
    retardationOn()
  -- Asthma gained while aeon active - prioritize asthma so we can smoke elm
  elseif aff == "asthma" and ataxia.afflictions.aeon then
    send("curing prioaff asthma")
  elseif aff == "impatience" and ataxiaNDB_getClass(target) == "Serpent" then
    myaeon = true
  -- Darkshade duration tracking - auto-prioritize after threshold
  elseif aff == "darkshade" then
    -- `ataxia.darkshadeTracker` was NEVER created anywhere in the package (v4.7.194) -- the
    -- only definitions were the two unit-test fixtures, which hand-build it. So on a real
    -- profile this indexed a nil field and THREW, and because an error aborts the handler,
    -- `ataxia_lockBreak()` and `raiseEvent("aff gained", aff)` at the bottom of affsAdd
    -- never ran for darkshade either. Against a Serpent that is the affliction whose 26s
    -- of uptime IS the kill route.
    ataxia.darkshadeTracker = ataxia.darkshadeTracker or {}
    local threshold = tonumber(ataxia.darkshadeTracker.threshold) or 17

    -- The timer id and the one-shot latch are TRANSIENT and must not live under `ataxia`,
    -- which is serialized wholesale and deepMerged back with `dst[k] = v` -- a saved
    -- `prioritized = true` would come back true with no timer alive to ever reset it, and
    -- a saved `timerId` would be a stale integer that `killTimer` might aim at somebody
    -- else's timer. Only `threshold` (user config) belongs on the saved namespace.
    ataxiaTemp = ataxiaTemp or {}
    if ataxiaTemp.darkshadeTimer then killTimer(ataxiaTemp.darkshadeTimer) end
    ataxiaTemp.darkshadePrioritized = nil

    -- Start timer to auto-prioritize after threshold
    ataxiaTemp.darkshadeTimer = tempTimer(threshold, function()
        if ataxia.afflictions.darkshade and not ataxiaTemp.darkshadePrioritized then
            send("curing prioaff darkshade")
            ataxiaTemp.darkshadePrioritized = true
            ataxia_boxEcho("Darkshade persisting - prioritizing cure", "yellow")
        end
    end)
  elseif aff == "shivering" or aff == "frozen" then
    ataxia_tryVultureTalon()
	end
  --Are we close to being locked where we need to hit our active ability?
	ataxia_lockBreak()

-- Downstream consumers key on the BARE name. ApplySwaps tests `aff == "burning"` and
-- Stack_My_Affs looks the name up in the herb tables (002_Wide_Groups lists bare names
-- only), so every one of them was dead for stacking affs while we passed "burning3".
local base = ataxia_stackAff(aff) or aff:lower()

-- DAMNATION lives on the SELF path, and until v4.7.276 nothing put it there. Both the alarm
-- (checkDamnationThreat) and the Paladin auto-detect hung off pali_addPyre/pali_addBurns,
-- whose only reachable caller was tarAffed -- the TARGET path, driven by our own attack
-- lines. So taking a burn or a pyre OURSELVES armed neither, and the "SHIELD NOW OR DIE"
-- box could not fire however correct the burn level was.
if base == "pyre" then
  -- Only a Paladin can apply pyre (PERFORM PYRE), so this is a reliable class tell -- and
  -- the one that still works when the target is not in NDB.
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.fightingPaladin = true
end
if DAMNATION_AFFS[base] and checkDamnationThreat then checkDamnationThreat() end

	raiseEvent("aff gained", base)
  if zgui then zgui.showAffs() end

-- Generic swaps first (persistent prio changes), then class-specific (one-shot prioaff)
Algedonic.ApplySwaps(base)
Algedonic.Prioritize()
-- Calculate Stacks (Kelp/Goldenseal/Bloodroot/etc)
Algedonic.Stack_My_Affs(true, base)
end

function lostAff()
	local ignore = {"blindness", "deafness", "insomnia"}
	local aff = gmcp.Char.Afflictions.Remove

	local base, count = ataxia_stackAff(aff[1])
	-- `table.contains(ignore, aff)` tested the gmcp TABLE against strings, so the ignore
	-- list has never matched anything here. Inert either way (the same three are ignored on
	-- the ADD side, so they are never in the table to remove) -- corrected rather than left
	-- knowingly wrong.
	if not table.contains(ignore, aff[1]) then
		if base and aff[1]:lower() ~= base then
			-- A SUFFIXED remove ends the stack only if it names the level we still hold.
			-- Achaea sends Remove(old) + Add(new) when a stack CHANGES and the order is not
			-- guaranteed, so zeroing unconditionally kills a live stack whenever the Add lands
			-- first. `== count` is correct under both orderings; `<= count` is not -- it would
			-- zero a real 3-stack on a 5 -> 3 drop. A missed Add leaves a stale value until the
			-- next full Char.Afflictions.List push, which rebuilds the table from scratch.
			if ataxia.afflictions[base] == count then ataxia.afflictions[base] = 0 end
		elseif base then
			ataxia.afflictions[base] = 0  -- a BARE remove is the full-cure signal
		else
			ataxia.afflictions[aff[1]:lower()] = nil
		end
	end

	if aff[1] == "guilt" then
		send("curing focus on")
  elseif aff[1] == "voyria" or aff[1] == "latency" then
    stoplatency = false
	elseif aff[1] == "blackout" then
		if not ataxia.vitals.eq then
			send("curing predict disrupted",false)
		end
		send("allies",false)
	elseif aff[1] == "corruption" then
		send("curing clotat 180",false)
		ataxia_boxEcho("CORRUPTION IS GONE - SAFE", "white")
  elseif aff[1] == "brokenrightarm" or aff[1] == "brokenleftarm" then
    preventriftlock = false
  elseif aff[1] == "paralysis" then
    send("endure stop")
  elseif aff[1] == "haemophilia" or aff[1] == "flushings" then
    stopscourge = false
  elseif aff[1] == "aeon" and ataxia.retardation then
    retardationOff()
    myaeon = false
    partyrelay = true
  elseif aff[1] == "impatience" then
     myaeon = false
  -- impSnap removed: Serpents no longer deliver impatience via SNAP, they use Impulse instead
  -- unweavingmind/body/spirit and crescendo used to be zeroed here by name. The generic
  -- stack branch above does exactly that for all sixteen stacking affs, and a second owner
  -- of the same state is what drifts.
  -- Darkshade cleanup - stop timer when cured. Same nil-index crash as the gain path
  -- (`ataxia.darkshadeTracker` was never created outside the two test fixtures), and here
  -- it aborted `raiseEvent("aff cured", ...)` and `Algedonic.RestoreSwaps` below -- so the
  -- anti-Serpent priority swaps darkshade had applied were never restored either.
  elseif aff[1] == "darkshade" then
    ataxiaTemp = ataxiaTemp or {}
    if ataxiaTemp.darkshadeTimer then
        killTimer(ataxiaTemp.darkshadeTimer)
        ataxiaTemp.darkshadeTimer = nil
    end
    ataxiaTemp.darkshadePrioritized = nil
  end

-- Same base-name rule as gotAff. Stack_My_Affs was also handed the gmcp TABLE rather than
-- aff[1] -- a pre-existing bug that made the cure-stack count wrong for EVERY affliction.
local cured = base or aff[1]:lower()
	raiseEvent("aff cured", cured)
  if zgui then zgui.showAffs() end
Algedonic.RestoreSwaps(cured)
Algedonic.Prioritize()
Algedonic.Stack_My_Affs(false, cured)
end

registerAnonymousEventHandler("gmcp.Char.Afflictions.List", "afflictionList")
registerAnonymousEventHandler("gmcp.Char.Afflictions.Add", "gotAff")
registerAnonymousEventHandler("gmcp.Char.Afflictions.Remove", "lostAff")