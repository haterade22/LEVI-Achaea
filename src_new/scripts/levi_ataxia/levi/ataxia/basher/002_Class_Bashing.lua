--[[mudlet
type: script
name: Class Bashing
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Class Bashing
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxiaBasher_dragonBashing()
  local command, sp = "", ataxia.settings.separator
  -- Golden Dragon owns its battlerage (aeon/amnesia control rotation below); the other
  -- colours still go through the generic assembler. LAZY on purpose (review MEDIUM):
  -- the golden rotation stamps cooldowns when it picks, so it must only be called on
  -- branches that actually SEND the pick -- the shielded+rageraze round spends its
  -- rage on the raze and emits no battlerage, and an eager call there would burn a
  -- 35-41s control stamp unsent.
  local function brage()
    if gmcp.Char.Status.class == "Golden Dragon" then
      return ataxiaBasher_brCommit(ataxiaBasher_goldenDragonBattlerage(sp))
    end
    return ataxiaBasher_assembleBattlerage()
  end
  local colour = string.match(gmcp.Char.Status.class, "%w+")
  local raze = ataxiaBasher.battlerage[colour.." Dragon"].raze
  -- Breath element is derived from the dragon's colour (Blue = ice, Silver = lightning,
  -- Red = dragonfire, Green = venom, Black = acid, Golden = psi). No hardcoded default.
  local ele = getDragonBreath()

  -- The bal primary only (no breath weave): jab / whip / incantation / gut
  local function balAttack()
    if ataxiaBasher.jabBash then
      return "jab " ..target
    elseif ataxiaBasher.wotBash then
      return "whip " ..target
    elseif ataxiaBasher.dragonIncant then
      return "incantation " ..target
    else
      return "gut " ..target
    end
  end

  -- Normal-rotation primary. When the blast weave is enabled (bash blast on) and we're using a
  -- real primary (incantation/gut, not the low-wp jab or wotBash whip), fold in a breath blast:
  --   breath up   -> blast (eq, damage + breaks shields/lyres) ; re-summon ; bal attack
  --   breath down -> summon so it's ready next hit ; bal attack
  -- balOverride swaps the balance swing (e.g. the Draconic Rampage trample) while the
  -- eq-based blast weave still rides beside it.
  local function primary(balOverride)
    local bal = balOverride or balAttack()
    local weaveable = not ataxiaBasher.jabBash and not ataxiaBasher.wotBash
    if ataxiaBasher.dragonBlast and weaveable and ele then
      if ataxia.defences.dragonbreath then
        -- Might of Sycaerunax (Mnemosyne boon): +25% blast damage AND the breath
        -- weapon PERSISTS through BLAST (AB Blast: "Requires summoned breath") --
        -- the re-summon is pure waste while it's up.
        if dragonMightSycaerunax then
          return "blast " ..target.. ";" ..bal
        end
        return "blast " ..target.. ";summon " ..ele.. ";" ..bal
      else
        return "summon " ..ele.. ";" ..bal
      end
    end
    return bal
  end

  if ataxiaBasher.shielded then
    if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
      command = command..raze..sp..primary()
    else
      -- Shield MUST be broken: blast unconditionally, re-summon the colour's breath, add bal damage.
      -- Under Might of Sycaerunax the breath persists -- skip the re-summon here too.
      local reblast
      if dragonMightSycaerunax then
        reblast = "blast " ..target.. ";"
      else
        reblast = ele and ("blast " ..target.. ";summon " ..ele.. ";") or ("blast " ..target.. ";")
      end
      command = command..sp..reblast..balAttack()..sp..brage()
    end
  else
    -- Draconic Rampage (Mnemosyne boon): at 2+ denizens, off the 40s proc cooldown,
    -- the balance swing becomes TRAMPLE (room-wide cutting nuke). Shield-break
    -- rounds skip it -- break the shield first, like the Kai Choke rule.
    command = command..sp..brage()..sp..primary(ataxiaBasher_dragonRampagePick())
  end
  return command
end

-- Draconic Rampage pick: "Your draconic trample now deals a large amount of cutting
-- damage to all denizens in your room. This effect has a 40 seconds cooldown." AB
-- Trample (1564): TRAMPLE, room, 2.75s of balance. Off the proc, plain trample only
-- hits prone targets -- so the swing is spent ONLY when the proc is ready and 2+
-- denizens share the room (user-directed). Send-side stamp with the v4.7.129
-- in-flight hold (the trample round replays verbatim across the 0.3s re-queue loop);
-- upgrade to a confirmed proc line once captured.
-- Rampage proc CONFIRMED (trigger highlighting/033, "Iron-sharp claws rip and tear
-- into all around you..."): restart the 40s proc cooldown from the LANDED moment
-- (the queued trample can land seconds after the pick's send stamp) and release the
-- in-flight trample hold.
function ataxiaBasher_dragonRampageProc()
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.dragonRampageAt = nowT
  ataxiaTemp.dragonRampagePendingAt = nil
end

function ataxiaBasher_dragonRampagePick()
  if not dragonRampage then return nil end
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp = ataxiaTemp or {}
  local pend = ataxiaTemp.dragonRampagePendingAt
  if pend and (nowT - (tonumber(pend) or 0)) < 3 then return "trample" end
  ataxiaTemp.dragonRampagePendingAt = nil
  local M = ataxia.mnemosyne
  local n = (M and M._denizenCount and M._denizenCount()) or 0
  if n < 2 then return nil end
  if (nowT - (tonumber(ataxiaTemp.dragonRampageAt) or 0)) < 40 then return nil end
  ataxiaTemp.dragonRampageAt = nowT
  ataxiaTemp.dragonRampagePendingAt = nowT
  return "trample"
end

-- Golden Dragon OWNS its battlerage (the Psion lesson, v4.7.128): the generic
-- fallback gates small behind battleRage_Timers.small, which trigger 330 never sets
-- for Golden Dragon (no Overwhelm fire-line) -- so Overwhelm was re-sent into its own
-- 16s cooldown every swing AND, because small always won the elseif, Psiblast could
-- NEVER fire. Deaden/Psidaze weren't wired at all. Timer-free send-side epoch stamps
-- with the AB cooldowns. Priority is CONTROL first (user-directed -- denizen aeon and
-- amnesia gut incoming damage): Deaden 24r/35s (AEON: every action slowed) >
-- Psidaze 28r/41s (AMNESIA: recurring forgets) > Psiblast 36r/23s > Overwhelm
-- 14r/16s filler. When a control cast is off cooldown but rage can't cover it yet,
-- the damage fillers are SKIPPED so the rage banks toward the control cast instead
-- of Overwhelm starving it 14 rage at a time.
-- RAGE-FUELLED PICK ORDER (v4.7.189). Each owned rotation's table is ordered by VALUE PER
-- RAGE -- cheap reliable fillers sit near the top precisely because they are affordable.
-- With a Rage-Fuelled charge banked that ordering answers the wrong question: the ability is
-- FREE, so cost stops being a constraint and the only thing that matters is getting the
-- biggest ability we are actually allowed to fire. Spend the charge on the most EXPENSIVE
-- ready ability; the cheap ones we can afford out of pocket anyway.
--
-- Returns the table UNTOUCHED when no charge is banked, so normal play is byte-identical --
-- the pre-existing rotation suites are the proof of that.
--
-- Ties break on the table's own priority rather than being left to table.sort, which is NOT
-- stable in Lua: several rotations have two abilities at the same cost (RW onslaught 36 vs
-- culling's 36, PSION devastate 36), and an unstable sort would make the pick vary between
-- otherwise identical rounds -- which the in-flight replay would then faithfully repeat.
--
-- Culling reap needs no help here: it is checked ahead of these loops and is already the
-- joint-most-expensive thing most rotations own.
local function brPickOrder(tbl)
  local base = tbl
  if ataxiaBasher_brFree and ataxiaBasher_brFree() then
    local ranked = {}
    for i, ab in ipairs(tbl) do ranked[i] = { ab = ab, i = i } end
    table.sort(ranked, function(a, b)
      local ra, rb = tonumber(a.ab.rage) or 0, tonumber(b.ab.rage) or 0
      if ra ~= rb then return ra > rb end
      return a.i < b.i
    end)
    base = {}
    for i, e in ipairs(ranked) do base[i] = e.ab end
  end

  -- CONTROL-FIRST DENIZENS (v4.7.198). Against a mob on `ataxiaBasher.controlMobs` the
  -- threat is its own attacks, so float every `slows` ability to the front -- the ones that
  -- spend ITS balance rather than its health.
  --
  -- `slows`, NOT `control`: in dwBattlerage and goldenDragonBattlerage `control` already
  -- means "BANK rage until this is affordable", and v4.7.145 removed that from chrono curse
  -- after measuring aeon at ~5.6s against a 35s cooldown (~16% uptime -- banking lost more
  -- damage than the mitigation was worth). Overloading the key would have silently restored
  -- it; the existing Depthswalker test caught exactly that.
  --
  -- Layered ON TOP of the free-charge sort rather than replacing it, and stable within each
  -- group, so the two compose: with a Rage-Fuelled charge banked we still take the DEAREST
  -- control ability, and only then fall through to the dearest damage one.
  if not (ataxiaBasher_controlFirst and ataxiaBasher_controlFirst()) then return base end
  local out, rest = {}, {}
  for _, ab in ipairs(base) do
    if ab.slows then out[#out + 1] = ab else rest[#rest + 1] = ab end
  end
  for _, ab in ipairs(rest) do out[#out + 1] = ab end
  return out
end

local GDRAGON_BR = {
  { key = "deaden",    cmd = "deaden",    rage = 24, cd = 35, control = true, slows = true },
  { key = "psidaze",   cmd = "psidaze",   rage = 28, cd = 41, control = true, slows = true },
  { key = "psiblast",  cmd = "psiblast",  rage = 36, cd = 23 },
  { key = "overwhelm", cmd = "overwhelm", rage = 14, cd = 16 },
}
-- Fire-line confirmation (the Monk-ripplestrike direction): a captured fire line
-- proves the cast LANDED, so (a) the cooldown restarts from the confirmed moment
-- (send stamps are pick-time -- the queued cast can fire seconds later) and (b) the
-- in-flight pick hold is released early, letting the rotation advance on the next
-- rebuild instead of re-sending a cast that already fired. Wired so far: PSIDAZE
-- (trigger highlighting/028). Wire the other three as their lines are captured.
function ataxiaBasher_gdragonConfirm(key)
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp.gdragonBrAt = ataxiaTemp.gdragonBrAt or {}
  ataxiaTemp.gdragonBrAt[key] = nowT
  local pend = ataxiaTemp.gdragonBrPending
  if pend and pend.verb == key then ataxiaTemp.gdragonBrPending = nil end
end

function ataxiaBasher_goldenDragonBattlerage(sp)
  local rage = tonumber(ataxia.vitals.rage) or 0
  -- Rage conservation: same rule the generic assembler applies. Clears any in-flight
  -- pick so a stale cast can't resume on the NEXT mob.
  if ataxiaBasher.rageConserveThreshold then
    local mobhp = tonumber(((gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", ""))) or 100
    if mobhp > 0 and mobhp <= ataxiaBasher.rageConserveThreshold then
      ataxiaTemp.gdragonBrPending = nil
      return ""
    end
  end
  local nowT = (getEpoch and getEpoch()) or os.time()
  -- In-flight pick REPLAY (review HIGH): the basher REBUILDS this command every
  -- prompt/vitals event (0.3s addclearfull re-queue loop) while a swing's balance is
  -- down, and each rebuild wipes the previously queued line. Stamping a fresh pick
  -- per rebuild burned the whole rotation phantom-style -- the top-priority controls
  -- got stamped-then-wiped and only the LAST rebuild's filler ever fired (priority
  -- inversion). So a pick stays PENDING for ~one balance round and is replayed
  -- verbatim (the bloodboil stability rule: the returned command must stay stable
  -- across the re-queue loop); the rotation only advances once the hold expires.
  local pend = ataxiaTemp.gdragonBrPending
  if pend and pend.verb and (nowT - (tonumber(pend.at) or 0)) < 3 then
    return pend.verb.." "..target..sp
  end
  ataxiaTemp.gdragonBrPending = nil
  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and ataxiaBasher_cullAfford(rage, 36)
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    return "reap "..target..sp
  end
  ataxiaTemp.gdragonBrAt = ataxiaTemp.gdragonBrAt or {}
  for _, ab in ipairs(brPickOrder(GDRAGON_BR)) do
    if (nowT - (tonumber(ataxiaTemp.gdragonBrAt[ab.key]) or 0)) >= ab.cd then
      -- Rage floor (v4.7.141): with ataxiaBasher.rageFloor = N an ability costing C
      -- needs C + N, so gear paying a bonus above N keeps paying. Composes with the
      -- banking rule below: a control simply banks until cost + floor.
      if ataxiaBasher_rageAfford(rage, ab.rage) then
        ataxiaTemp.gdragonBrAt[ab.key] = nowT
        ataxiaTemp.gdragonBrPending = { verb = ab.cmd, at = nowT }
        return ab.cmd.." "..target..sp
      elseif ab.control then
        return "" -- bank rage for the pending aeon/amnesia cast
      end
    end
  end
  return ""
end

function ataxiaBasher_fEleBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage["Fire Elemental"].raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = command..raze..sp.."ignite flamewhip "..target
		else
			command = command..sp.."manifest superheat "..target..sp..brage
		end
	else
		command = command..brage..sp.."ignite flamewhip "..target	
	end
	return command  

end

function ataxiaBasher_eEleBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage["Earth Elemental"].raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = command..raze..sp.."terran pulverise "..target
		else
			command = command..sp.."terran crunch "..target..sp..brage
		end
	else
		command = command..brage..sp.."terran pulverise "..target	
	end
	return command  

end


function ataxiaBasher_aEleBashing()
   local command = ""   
   if ataxiaBasher.shielded then
      command = command.."manifest gale "..target..ataxia.settings.separator
   end
   
   command = command..ataxiaBasher_assembleBattlerage()
   
   if not ataxiaBasher.shielded then   
      command = command.."manifest buffet "..target
   end
   
   return command   
end

function ataxiaBasher_alchemistBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Alchemist.raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = raze..sp.."educe iron "..target
		else
			command = "educe copper "..target..sp..brage
		end
	else
		command = brage..sp.."educe iron "..target
	end
	    
	return command  
end

function ataxiaBasher_apostateBashing()
	local command, sp = "", ataxia.settings.separator 
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Apostate.raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = raze..sp.."deadeyes "..target.." bleed bleed; "
		else
			command = "deadeyes "..target.." bleed bleed; "
		end
	else
		command = brage..sp.."deadeyes "..target.." bleed bleed; "
	end
	    
	return command	
end

-- Wield the lyre and (re)compose the bash performance, then (re)start the 15-min
-- "Bard Performance" timer. Called at bash start (basher_engaged), when the 15-min timer
-- expires, and off the "not performing" / performance-ended lines.
--
-- THE ATTACK WAS EATING THE LYRE (v4.7.232). Live log:
--
--   (LEVI): Bard bash: composed paean prelude scherzo sonata maqam
--   You aren't wearing a Lasallian lyre.
--   How are you going to perform a song without your instrument wielded?
--
-- The three commands went out RAW, and the basher dispatches an attack on the very next
-- prompt -- sub-second. That attack re-wields the SHIELD into the left hand (the comment this
-- replaces said so itself), so the lyre was pulled back out between `wield` and `compose`, and
-- compose landed with nothing in hand. The echo still claimed success, which is why this went
-- unnoticed: we announced a performance that never started.
--
-- Two changes, and both are needed -- either alone still loses the race:
--
--   1. ONE QUEUED LINE. `queue addclear free` keeps remove -> wield -> compose in order and
--      lets each wait for what it needs, instead of three raw commands racing the attack
--      dispatch. (One queued line is ONE queue entry -- the commands run in sequence.)
--   2. HOLD THE ATTACK across it (user: "this should be done before bashing attack").
--      ataxiaTemp.bardComposeHold gates ataxiaBasher_attack the same way swarmHold does, so
--      nothing re-wields the shield mid-sequence. Bounded by a timer and cleared by the
--      performance-duration line, so it can never wedge the basher: worst case is
--      BARD_COMPOSE_HOLD seconds of not swinging, which is the cost of a round we would have
--      wasted unbuffed anyway.
--
-- `wield lyre`, not `wield left lyre` (user's wording): let the game pick the free hand rather
-- than forcing the slot the shield lives in.
ataxiaBasher_BARD_COMPOSE_HOLD = 3

function ataxiaBasher_bardCompose()
   -- Debounce: rapid "not performing" lines (repeated battlerage 'play' commands fire before the
   -- compose lands) can call this several times; the extras are just redundant. Allow one per 2s.
   if bardComposePending then return end
   bardComposePending = true
   tempTimer(2, [[bardComposePending = false]])
   local c = (ataxia.bardStuff and ataxia.bardStuff.bashCompose) or "paean prelude scherzo sonata maqam"
   local sep = (ataxia.settings and ataxia.settings.separator) or ";"

   -- Hold BEFORE sending, or the dispatch this is racing can slip in first.
   ataxiaTemp = ataxiaTemp or {}
   ataxiaTemp.bardComposeHold = true
   if ataxiaBasher_bardComposeT then pcall(killTimer, ataxiaBasher_bardComposeT) end
   ataxiaBasher_bardComposeT = tempTimer(tonumber(ataxiaBasher_BARD_COMPOSE_HOLD) or 3, function()
      ataxiaBasher_bardComposeT = nil
      if ataxiaTemp then ataxiaTemp.bardComposeHold = nil end
   end)

   send("queue addclear free remove lyre"..sep.."wield lyre"..sep.."compose "..c)
   enableTimer("Bard Performance")
   ataxiaEcho("<green>Bard bash:<reset> composing <cyan>"..c.."<reset> (holding the swing)")
end

-- The performance-duration line proves one is actually running, so release the hold early
-- rather than serving out the timer. Called from performance_tracking/001.
function ataxiaBasher_bardComposeDone()
   if ataxiaBasher_bardComposeT then
      pcall(killTimer, ataxiaBasher_bardComposeT)
      ataxiaBasher_bardComposeT = nil
   end
   if ataxiaTemp then ataxiaTemp.bardComposeHold = nil end
end

-- SONGSTEP (Mnemosyne legendary boon, v4.7.200): "Your dances gain additional bonuses.
-- Hawkstep: Gain 25% resistance to damage. Wavedance: Ignore 75% of a denizen's resistance.
-- Harrying: Deal 50% bonus damage."
--
-- THE COST IS THE WHOLE DESIGN. AB Hawkstep (3193) is "3.00 seconds of BALANCE", and the AB
-- spells out that "you can only dance one thing at a time" -- the dances are mutually
-- exclusive. So a dance is not a rider like the thunderstorm (equilibrium, free alongside the
-- swing); it is a STATE, and every switch costs a full attack. That makes the goal to switch
-- RARELY and correctly, never to re-assert per round -- a naive "keep the right dance up"
-- rider would simply never attack.
--
-- Which dance, per the user (2026-08-03):
--   Wavedance  -- against BOSSES. Ignoring 75% of resistance is the answer to the one
--                 denizen whose resistance actually matters.
--   Hawkstep   -- higher ripples and ANY room with multiple denizens. 25% damage resistance
--                 is a survival stat, and those are the rooms that kill.
--   Harrying   -- lower ripples, i.e. the default. +50% damage when nothing is threatening.
--
-- Boss beats crowd: a boss room may hold adds, but the boss is what the round is about.
--
-- KNOWING WHAT IS ALREADY DANCED. `harrying` is a GMCP-tracked defence (see the bard block in
-- deffing/004), so the dances surface as defences and that is the authority. `hawkstep` and
-- `wavedance` are assumed to follow the same naming -- consistent with `harrying`, but NOT
-- verified against a live capture, so an attempt-hold backs it up: if the defence never
-- appears we still stop re-dancing after one try instead of burning a swing every round. If a
-- capture shows different names, only DANCE_DEFENCE below needs changing.
local BARD_DANCES = {
  hawkstep  = { cmd = "dance hawkstep",  def = "hawkstep"  },
  wavedance = { cmd = "dance wavedance", def = "wavedance" },
  harrying  = { cmd = "dance harrying",  def = "harrying"  },
}

-- Which dance does the situation call for? Pure decision, unit-tested.
function ataxiaBasher_bardWantDance()
  if not mnemSongstep then return nil end
  local M = ataxia and ataxia.mnemosyne

  -- Boss first (most specific rule).
  local boss = M and M.run and M.run.boss
  local nm = secondTarget
  if type(boss) == "string" and boss ~= "" and type(nm) == "string" and nm ~= "" then
    local first = boss:lower():match("[%a]+")
    if first and #first >= 4 and nm:lower():find(first, 1, true) then return "wavedance" end
  end

  -- Crowd, or a deep ripple. Both numbers are the user's: "any room with multiple denizens",
  -- and RIPPLE 25 as the point where the tower's difficulty actually steps up (2026-08-03).
  -- The first cut guessed 5 by anchoring on the boss cadence -- every 5th ripple is a boss --
  -- which was the wrong reasoning entirely: boss frequency is not difficulty, and at 5 the
  -- bard would have sat in defensive hawkstep for twenty ripples of easy rooms, giving up
  -- Harrying's +50% damage for a resistance bonus against nothing.
  local n = (M and M._denizenCount and M._denizenCount()) or 0
  if n >= (tonumber(ataxiaBasher.bardHawkstepAt) or 2) then return "hawkstep" end
  local ripple = tonumber(M and M.run and M.run.ripple) or 0
  if ripple >= (tonumber(ataxiaBasher.bardHawkstepRipple) or 25) then return "hawkstep" end

  return "harrying"
end

-- The command to switch dance this round, or "" to just keep swinging.
function ataxiaBasher_bardDance(sp)
  if not mnemSongstep then return "" end
  if ataxiaBasher.shielded then return "" end -- break the shield first
  if type(target) ~= "number" then return "" end
  local want = ataxiaBasher_bardWantDance()
  if not want then return "" end
  local d = BARD_DANCES[want]
  if not d then return "" end

  -- Already dancing it? Then there is nothing to buy and the swing stays ours.
  if ataxia.defences and ataxia.defences[d.def] then return "" end

  -- Attempt-hold: one try per window. Without it an unconfirmed dance (wrong defence name,
  -- eaten command, a refusal we have not captured) would cost EVERY balance from here on.
  ataxiaTemp = ataxiaTemp or {}
  local nowT = (getEpoch and getEpoch()) or os.time()
  local hold = tonumber(ataxiaBasher.bardDanceHold) or 8
  if ataxiaTemp.bardDanceWant == want and (nowT - (tonumber(ataxiaTemp.bardDanceAt) or 0)) < hold then
    return ""
  end
  ataxiaTemp.bardDanceWant = want
  ataxiaTemp.bardDanceAt = nowT
  return d.cmd..sp
end

function ataxiaBasher_bardBashing()
   local command = ""
   if bardNeedRapierWield then
      bardNeedRapierWield = false
      command = command.."wield right rapier;wield left shield"..ataxia.settings.separator
   end
   if ataxiaBasher.shielded then
      command = command.."wield right rapier;wield left shield;blade punctuate "..target.. " paean;"
   end
    command = command..ataxiaBasher_assembleBattlerage()

    -- Attack: flick (psychic) by default; punctuate for psychic-resistant denizens
    -- (manual 'bashpunctuate' toggle). Compose/tempo are handled at bash start + timer.
    --
    -- v4.7.187: a Mnemosyne ripple can suppress a whole damage type --
    --     Blank Mind:  All psychic damage you deal is reduced by 33%.
    -- and FLICK is psychic while PUNCTUATE is not, so the branch that already existed for
    -- psychic-resistant denizens is exactly the right response to the affix too. This is the
    -- Bard twin of the Blademaster infuse picker: same query
    -- (ataxia.mnemosyne.damageNulled), same idea -- most affixes are things to survive, a
    -- damage-type suppression is a thing to route around.
    --
    -- Placed in the FIRST branch on purpose, so it also overrides the Warmarch flick below:
    -- that boon's value is +100% PSYCHIC on the paean refrain, which is precisely what a
    -- psychic-nulling ripple is taxing. The manual toggle stays authoritative by sitting
    -- alongside it -- a user who asked for punctuate gets punctuate regardless.
    local M = ataxia and ataxia.mnemosyne
    local psychicNulled = (M and M.damageNulled and M.damageNulled("psychic")) and true or false
    local atk
    if (ataxia.bardStuff and ataxia.bardStuff.bashPunctuate) or psychicNulled then
       atk = "blade punctuate "..target.." nomos"
    elseif bardWarmarch then
       atk = "blade flick "..target.." paean"  -- Warmarch boon: paean refrain now hits denizens (+100% psychic)
    else
       atk = "blade flick "..target.. " nomos"
    end
    -- Songstep: a dance costs 3s of BALANCE, so on a switching round it REPLACES the swing
    -- (the battlerage above still rides -- that is rage, not balance). Returns "" on every
    -- other round, which is almost all of them: the dance is a state we hold, not a rider.
    local dance = ataxiaBasher_bardDance(ataxia.settings.separator)
    if dance ~= "" then
       return command..dance:gsub(ataxia.settings.separator.."$", "")
    end

    command = command.."wield right rapier;wield left shield;"..atk

   return command
end

function ataxiaBasher_blademasterBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Blademaster.raze
	-- Has something in this round already claimed the shin/equilibrium slot? See the
	-- Divine Thunder block below for why one round may only ever hold one of them.
	local shinSpent = false

	-- White Heaven's Shattered Star boon (Mnemosyne): multislash strikes 3 EXTRA times
	-- (6 total), so it out-damages the single drawslash -- swap to it while the boon is up.
	-- Straight verb swap (same "sternum" target part): bmShatteredStar is set by the BOONS-list
	-- trigger / boon-claim alias and reset each run (mirrors bardWarmarch); nil/false -> drawslash.
	local slash = bmShatteredStar and ("multislash "..target.." sternum") or ("drawslash "..target.." sternum")

	-- Bladed Reflexes boon (Mnemosyne): 20% reduced damage while the Shindo AUGMENT state is
	-- up. SHIN AUGMENT <ALL|amount> channels shin into the reflex augment (tracked as the
	-- bodyaugment defence); spend the MINIMUM (1) -- augment with 0 shin just fails, and
	-- infuse fire competes for the same resource. Gated on the GMCP-tracked defence (expiry
	-- arrives via Char.Defences.Remove, no duration guessing) plus a short attempt-hold so
	-- the channel wind-up ("beginning the process...") isn't respammed every swing. Flag
	-- mirrors bmShatteredStar (claim alias + BOONS row trigger 019, reset each run).
	if bmBladedReflexes and not (ataxia.defences and ataxia.defences.bodyaugment)
		 and not ataxiaTemp.bmAugmentAttempted then
		local shin = (blademaster and blademaster.getShin and blademaster.getShin())
			or (ataxia.vitals and tonumber(ataxia.vitals.class)) or 0
		-- Live log 2026-07-26: "shin augment 1" channeled and DISSIPATED 12ms later, twice --
		-- one shin buys ~zero duration, so the boon's 20% DR was never actually up. Spend a
		-- real chunk (duration appears to scale with the amount); tune via bmAugmentAmount.
		local amt = tonumber(ataxiaBasher.bmAugmentAmount) or 3
		if shin >= amt then
			ataxiaTemp.bmAugmentAttempted = true
			tempTimer(5, [[ataxiaTemp.bmAugmentAttempted = nil]])
			command = "shin augment "..amt..sp
			shinSpent = true
		end
	end

	-- Divine Thunder Cataclysm: an EQUILIBRIUM room nuke, so it rides ahead of the balance
	-- swing and costs us nothing off it. Self-gates on the boon, the crowd, shin and its
	-- own cooldown, returning "" whenever any of those says no.
	--
	-- ONE SHIN SPENDER PER ROUND (v4.7.193, Codex). The previous note here said the storm
	-- "sits queued behind the augment channel and can be wiped by the next addclearfull",
	-- and called that tolerable. That model was wrong in a way that mattered: the whole
	-- `;`-chain is ONE queue entry, so when it fires both commands execute back to back in
	-- the same instant. `shin augment` takes the equilibrium and `amt` shin, and the storm
	-- lands on the very next command with neither -- a DETERMINISTIC rejection, not a race
	-- we sometimes lose. And the shin arithmetic fails even where the equilibrium would
	-- not: the storm's `shin >= 30` gate reads the pool BEFORE the augment spends from it,
	-- so at 32 shin both pass their own gate and only the first can actually pay.
	--
	-- Worse, `bmShinStormAt` is stamped on SEND, so the rejected cast still bought a 4s
	-- cooldown. Skipping the call entirely (rather than discarding its result) is the point
	-- -- the stamp lives inside the helper, so calling it at all is what costs us.
	-- ONE shin/equilibrium spender per round (v4.7.193), and as of v4.7.195 the storm itself
	-- is a CHOICE of damage type -- thunderstorm (electric) or blizzard (cold), identical in
	-- cost, so the picker takes whichever the ripple is not suppressing.
	local storm = (not shinSpent) and ataxiaBasher_bmShinStorm(sp) or ""

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = command..raze..sp.."infuse "..ataxiaBasher_bmInfuse().." "..sp.." "..slash
		else
			command = command.."raze "..target..sp..brage
		end
	else
		command = command..storm..brage..sp.."infuse "..ataxiaBasher_bmInfuse().." "..sp.." "..slash
	end

	return command
end

-- BLADEMASTER INFUSE PICKER (v4.7.186). Shindo INFUSE sets the damage type our slashes
-- deal, and the tower can suppress a damage type for a whole ripple:
--     Null Magic:   All magic damage you deal is reduced by 33%.
-- Losing a third of our damage for the whole wave is a lot to pay for a hardcoded element,
-- and unlike most affixes this one we can simply step around -- there are four infuses and
-- the affix only nulls one type.
--
--   infuse fire      -> fire damage
--   infuse void      -> MAGIC damage
--   infuse lightning -> ELECTRICITY damage
--   infuse ice       -> COLD damage
--
-- Note the two that do not match their own name: VOID deals magic and ICE deals cold, so a
-- "Null Magic" ripple must move us off VOID, not off some element called magic. Mapping
-- element -> damage type here rather than assuming they are the same word is the whole
-- point of the function.
--
-- Synonyms are accepted per type because only the "magic" wording has been seen live; the
-- others are inferred from the damage types Achaea uses, and a miss would silently leave us
-- infusing the suppressed element.
local BM_INFUSE = {
  fire      = { "fire" },
  lightning = { "electricity", "electric", "lightning" },
  ice       = { "cold", "ice", "frost" },
  void      = { "magic", "void" },
}

-- Preference order. `fire` stays first so an unaffected ripple behaves exactly as before
-- (this replaced a hardcoded `infuse fire`); the rest are fallbacks, tunable via
-- ataxiaBasher.bmInfusePrefs.
local BM_INFUSE_ORDER = { "fire", "lightning", "ice", "void" }

function ataxiaBasher_bmInfuse()
  local M = ataxia and ataxia.mnemosyne
  local nulled = M and M.damageNulled
  local order = ataxiaBasher.bmInfusePrefs or BM_INFUSE_ORDER
  local first
  for _, element in ipairs(order) do
    local types = BM_INFUSE[element]
    if types then
      first = first or element
      local suppressed = false
      if nulled then
        for _, t in ipairs(types) do
          if M.damageNulled(t) then suppressed = true; break end
        end
      end
      if not suppressed then return element end
    end
  end
  -- Every element suppressed (or a garbage prefs list): fall back to the first valid one
  -- rather than returning nil, which would drop the infuse from the attack string entirely.
  return first or "fire"
end

-- Depthswalker OWNS its battlerage (the Psion/Golden Dragon pattern). Unlike those two
-- this was NOT the missing-fire-line bug -- triggers 330:43 and 331:43 do carry the
-- Shadow Drain / Shadow Lash lines. The rotation was dead for a different reason: the
-- SHARED culling branch (001_Bashing_Functions) heads the elseif chain and excludes only
-- Bard/Blademaster/Magi/Psion, so with `bash culling on` Depthswalker returned "" on
-- every round below 36 rage and neither drain nor lash ever fired. Owning the rotation
-- (plus excluding DW there) fixes that, and wires the FOUR denizen-legal abilities the
-- old two-ability config never touched.
--
-- Every ability in the DW battlerage kit is "Works on: Denizens" (AB) -- unusually, the
-- whole kit is PvE-legal:
--   Drain 14r/16s  Nakail 17r (raze)  Curse 24r/35s (AEON)  Erasure 25r/23s
--   Boinad 32r/38s (CHARM 5s)  Lash 36r/23s
--
-- Priority: culling reap > Erasure (only when the mob actually carries weakness/amnesia
-- -- it CONSUMES one for a damage spike, and DW can apply neither itself, so solo it
-- costs nothing and never fires; it lights up beside a Blademaster's Nerveslash or a
-- Golden Dragon's Psidaze) > Curse (denizen AEON = every mob action slowed = the biggest
-- incoming-damage cut in the kit) > Boinad (opt-in crowd charm) > Lash > Drain filler.
local DW_BR = {
  { key = "erasure", cmd = "chrono erasure", rage = 25, cd = 23, needsAff = true },
  -- NO banking for curse (v4.7.145, measured): the live log timed denizen aeon at ~5.6s
  -- against curse's 35s cooldown -- about 16% uptime. Holding 24 rage back and skipping
  -- the cheap filler to guarantee that window loses more damage than the mitigation
  -- saves, so curse fires when affordable and otherwise yields to Lash/Drain.
  -- `control`: chrono curse applies AEON -- the mob acts once per lengthy balance. The
  -- archetypal attack-slower, so it leads the rotation against a control-first denizen.
  { key = "curse",   cmd = "chrono curse",   rage = 24, cd = 35, skipIfAff = "aeon", slows = true },
  { key = "boinad",  cmd = "intone boinad",  rage = 32, cd = 38, optIn = true, word = true, multi = true, skipIfAff = "charm" },
  { key = "lash",    cmd = "shadow lash",    rage = 36, cd = 23 },
  { key = "drain",   cmd = "shadow drain",   rage = 14, cd = 16 },
}

-- Confirmation hook (the gdragonConfirm shape): a captured fire line restarts the
-- cooldown from the LANDED moment and releases the in-flight hold.
function ataxiaBasher_dwConfirm(key)
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp.dwBrAt = ataxiaTemp.dwBrAt or {}
  ataxiaTemp.dwBrAt[key] = nowT
  local pend = ataxiaTemp.dwBrPending
  if pend and pend.verb == key then ataxiaTemp.dwBrPending = nil end
end

local function dwHasAff(aff)
  return ataxiaBasher_dsHasAff and ataxiaBasher_dsHasAff(target, aff) or false
end

-- `wordUsed` says a keeper word has ALREADY been appended to this round's chain
-- (v4.7.193, Codex). The intoned-word gate below reads `ataxiaTables.depthswalker.wordBal`,
-- which is the word balance we hold RIGHT NOW -- and that is still true while the keeper is
-- only a string in the buffer. The whole `;`-chain is one queue entry, so both intones run
-- back to back the instant it fires: the keeper takes the word balance and boinad is
-- rejected, having already stamped a 38s cooldown, armed the pending replay, armed the
-- global battlerage cooldown and possibly spent a Rage-Fuelled charge. Current-state gates
-- cannot see what the same round has already claimed; the caller has to tell us.
function ataxiaBasher_dwBattlerage(sp, wordUsed)
  local rage = tonumber(ataxia.vitals.rage) or 0
  -- Rage conservation: same rule the generic assembler applies; clears any in-flight
  -- pick so a stale cast can't resume on the NEXT mob.
  if ataxiaBasher.rageConserveThreshold then
    local mobhp = tonumber(((gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", ""))) or 100
    if mobhp > 0 and mobhp <= ataxiaBasher.rageConserveThreshold then
      ataxiaTemp.dwBrPending = nil
      return ""
    end
  end
  local nowT = (getEpoch and getEpoch()) or os.time()
  -- In-flight pick REPLAY (v4.7.129 lesson): the basher rebuilds this command every
  -- prompt/vitals event and each rebuild's `queue addclearfull` wipes the previously
  -- queued line, so a pick stays pending ~one balance round and is replayed verbatim.
  local pend = ataxiaTemp.dwBrPending
  if pend and pend.cmd and (nowT - (tonumber(pend.at) or 0)) < 3 then
    return pend.cmd
  end
  ataxiaTemp.dwBrPending = nil
  -- Shared ~1s global battlerage cooldown (as Blademaster/Magi): queueing another BR
  -- while it is up gets it rejected and the rage goes unspent. AFTER the replay so a
  -- held command stays byte-stable.
  if getEpoch and getEpoch() < (ataxiaTemp.brGlobalReadyAt or 0) then return "" end

  -- Culling reap, owned here (never floored -- an execute beats a per-swing multiplier).
  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and ataxiaBasher_cullAfford(rage, 36)
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    ataxiaBasher_brSent()
    return "reap "..target..sp
  end

  ataxiaTemp.dwBrAt = ataxiaTemp.dwBrAt or {}
  for _, ab in ipairs(brPickOrder(DW_BR)) do
    local ready = (nowT - (tonumber(ataxiaTemp.dwBrAt[ab.key]) or 0)) >= ab.cd
    local gated = false
    if ab.optIn and not ataxiaBasher.dwBoinad then gated = true end
    -- Erasure consumes an existing weakness/amnesia; without one it is wasted rage.
    if ab.needsAff and not (dwHasAff("weakness") or dwHasAff("amnesia")) then gated = true end
    if ab.skipIfAff and dwHasAff(ab.skipIfAff) then gated = true end
    -- Intoned words share ONE word balance with the nakail shield-break, which always
    -- outranks them: never spend it on a charm while a shield is standing.
    if ab.word then
      if ataxiaBasher.shielded then gated = true end
      if wordUsed then gated = true end -- a keeper already claimed it in THIS chain
      if ataxiaTables and ataxiaTables.depthswalker
         and ataxiaTables.depthswalker.wordBal == false then gated = true end
    end
    -- Crowd abilities want a SECOND denizen, and charm the one we are not killing.
    local tgt = target
    if ab.multi then
      if not (ataxiaBasher_validTargets and ataxiaBasher_validTargets() >= 2) then gated = true end
      tgt = (stormhammerTargets and stormhammerTargets[2]) or target
    end
    if ready and not gated then
      if ataxiaBasher_rageAfford(rage, ab.rage) then
        local cmd = ab.cmd.." "..tgt..sp
        ataxiaTemp.dwBrAt[ab.key] = nowT
        ataxiaTemp.dwBrPending = { verb = ab.key, cmd = cmd, at = nowT }
        ataxiaBasher_brSent()
        if ab.key == "boinad" then ataxiaTemp.brCharmTgt = tgt end
        return cmd
      elseif ab.control then
        return "" -- bank rage for the pending aeon cast instead of trickling it away
      end
    end
  end
  return ""
end

-- Terminus PvE buffs (user's live AB TERMINUS, 2026-07-29). Terminus words are almost
-- all ONE-TIME defences -- you intone them once and they persist (only the ones with a
-- "Works against" field, e.g. Laiad vs denizens, are repeatable actions). So this is NOT
-- a rotation rider that re-asserts on a timer: it re-ups a buff only when GMCP says the
-- defence actually DROPPED. Raising them in the first place is `dw setup`, which chains
-- the full list off the word-balance-returned line.
--
-- Only GMCP-tracked words belong here, because only they can be observed to have fallen:
--   trusad   -- raises critical-hit chance vs DENIZENS   (defence: precision)
--   tsuura   -- reduces damage taken from DENIZENS       (defence: durability)
--   mainaas  -- augments skin vs cutting/blunt           (defence: bodyaugment)
-- The weapon augments (mainaad/balateth) have no defence flag to watch, so re-asserting
-- them mid-bash would be blind spam -- they live in `dw setup` only.
local DW_KEEPERS = {
  { word = "trusad",   cmd = "intone trusad",  def = "precision" },
  { word = "tsuura",   cmd = "intone tsuura",  def = "durability" },
  { word = "mainaas",  cmd = "intone mainaas", def = "bodyaugment" },
}

function ataxiaBasher_dwKeeper(sp)
  if ataxiaBasher.dwKeepers == false then return "" end
  if ataxiaBasher.shielded then return "" end -- the word balance belongs to nakail
  -- Not while we're in trouble (v4.7.145, live log): the keeper intoned MAINAAS at 12%
  -- HP, prone, with two mobs on us. A standing buff is worth having BEFORE a fight, not
  -- during the part where we are losing one -- and in a no-flee area every action spent
  -- not-killing is an action that prolongs the damage. `dangerLevel()` already encodes
  -- the shield/flee thresholds.
  if ataxiaBasher_dangerLevel then
    local ok, lvl = pcall(ataxiaBasher_dangerLevel)
    if ok and lvl and lvl ~= "attack" then return "" end
  end
  local dw = ataxiaTables and ataxiaTables.depthswalker
  if not dw or dw.wordBal == false then return "" end
  -- Fail CLOSED on an unknown word list is wrong (ataxia_depthswalkerReset wipes it and
  -- only the `Ab terminus` scrape refills it), but a word we KNOW we lack is skipped.
  local known = dw.abilities
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp.dwKeepAt = ataxiaTemp.dwKeepAt or {}
  for _, k in ipairs(DW_KEEPERS) do
    local haveIt = (not known) or known[k.word] == true
    local upAlready = k.def and ataxia.defences and ataxia.defences[k.def]
    local held = (nowT - (tonumber(ataxiaTemp.dwKeepAt[k.word]) or 0)) < (k.hold or 20)
    if haveIt and not upAlready and not held then
      ataxiaTemp.dwKeepAt[k.word] = nowT
      return k.cmd..sp
    end
  end
  return ""
end

-- Flashforward (Mnemosyne boon): "You deal 20% bonus damage while you possess the chrono
-- blur defence." `blur` is GMCP-tracked, so this is a straight keep-it-up job -- but
-- CHRONO BLUR is an Aeonics command paid in AGE and equilibrium, NOT the word balance, so
-- it rides beside the balance swing instead of competing with nakail and the Terminus
-- buffs. It fires on shielded rounds too: the buff is on US, and a shield round still
-- ends with a swing.
--
-- Age is the class's PvP currency, so the re-up is capped (`ataxiaBasher.dwAgeCap`,
-- default 400 = the yellow/orange boundary in getAgeColour) -- bashing must not price out
-- the chrono kit. The 8s attempt-hold covers the lag before the defence line lands.
function ataxiaBasher_dwFlashforward(sp)
  if not dwFlashforward then return "" end
  if ataxia.defences and ataxia.defences.blur then return "" end
  local dw = ataxiaTables and ataxiaTables.depthswalker
  local age = tonumber(dw and dw.age) or 0
  if age > (tonumber(ataxiaBasher.dwAgeCap) or 400) then return "" end
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp = ataxiaTemp or {}
  if (nowT - (tonumber(ataxiaTemp.dwBlurAt) or 0)) < 8 then return "" end
  ataxiaTemp.dwBlurAt = nowT
  return "chrono blur"..sp
end

function ataxiaBasher_depthswalkerBashing()
	local command, sp = "", ataxia.settings.separator
	-- Equilibrium rider: rides every round, shielded or not (see above).
	local ff = ataxiaBasher_dwFlashforward(sp)
	-- `shadow cull` is the slow/high-damage swing, `shadow reap` the fast/low one; the
	-- wiki gives numbers for neither, so reap stays the default until measured
	-- (`bash dwcull on` flips it -- see the A/B note in the class doc).
	local primary = (ataxiaBasher.dwCull and "shadow cull " or "shadow reap ")..target

	if ataxiaBasher.shielded then
		-- RAGE IS NEVER SPENT ON SHIELDS (user doctrine, v4.7.143; the same reason Magi
		-- never fires Disintegrate and Monk never fires Splinterkick). Depthswalker's
		-- only razer is NAKAIL, a 17-rage battlerage, so the default answer to a
		-- shielded denizen is: keep swinging and let it lapse. Trigger 336 sets
		-- `shielded` with a ~3.1s self-clearing timer and retargets outright when
		-- `shieldswap` is on with another mob available, so nothing stalls.
		-- `bash rageraze on` is the explicit opt-in for people who want the rage spent.
		if ataxiaBasher.rageraze then
			local rage = tonumber(ataxia.vitals.rage) or 0
			local dw = ataxiaTables and ataxiaTables.depthswalker
			if rage >= 17 and not (dw and dw.wordBal == false) then
				return ff.."intone nakail "..target..sp..primary
			end
		end
		return ff..primary
	end

	-- Battlerage computed LAZILY, only on branches that SEND it (the Psion rule): the
	-- rotation stamps cooldowns when it picks, and the shielded branch above emits no
	-- battlerage -- an eager call there would burn a 23-38s stamp unsent.
	-- Keeper FIRST, and its result is passed on: whichever of the two claims the single
	-- word balance, the other must stand down for this chain (see ataxiaBasher_dwBattlerage).
	-- The keeper wins the tie because it only ever fires when a defence has actually
	-- dropped, and it holds 20s between attempts -- boinad gets every other round.
	local keeper = ataxiaBasher_dwKeeper(sp)
	command = ff..keeper..ataxiaBasher_dwBattlerage(sp, keeper ~= "")..primary
	return command
end

-- Army of the Dead (Mnemosyne boon): "When summoning the hands of the grave, you will
-- deal damage to all denizens in the location."
--
-- IMPORTANT (user, v4.7.149): for INFERNAL the ability is **TYRANNY**, not the literal
-- "summon hands of the grave" (that phrasing is the APOSTATE command -- see the two
-- branches in aliases/.../118_GRAVEHANDS). And it is a **ONE-TIME** summon: the hands
-- persist, so it is cast once rather than re-cast on a cooldown. It costs **3% life
-- essence**, which is a slowly-recovering resource -- spamming it is genuinely expensive,
-- which is exactly what the first cut of this function did.
--
-- So: cast once, gated on a crowd being present (the boon's damage wants targets), an
-- essence floor, and a long re-arm that only exists as a backstop in case the summon is
-- lost. Capture the "hands expire/die" line to make the re-arm precise.
function ataxiaBasher_infGravehands(sp)
	if not infArmyOfDead then return "" end
	-- SHIELDED SELF-GUARD (v4.7.193, Codex). This is not a nicety, it is what keeps the
	-- once-per-room latch honest. `ataxiaBasher_infernalBashing` calls this eagerly and
	-- then DISCARDS the result on its shielded branch -- but the stamp below had already
	-- burned `infTyrannyRoom` for this room. Because that latch is only ever overwritten
	-- by a DIFFERENT room number and is never reset, one shielded first contact meant
	-- Tyranny never fired in that room again for the whole session.
	--
	-- Every sibling helper already self-guards this way (rwSowulu, rwBisect,
	-- bmThunderstorm, winterDeepfreeze); this one was the exception. The rule: a helper
	-- that STAMPS must refuse on exactly the conditions its caller refuses on, because
	-- the caller's branch is far away from the stamp.
	if ataxiaBasher.shielded then return "" end
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	-- RESOURCEFUL boon (user, v4.7.162): "defeating a denizen restores 10% of your class
	-- resources" -- for Infernal that resource is LIFE ESSENCE, so every kill refunds more
	-- than three Tyrannies cost. The essence economy that justified holding back for a
	-- crowd stops applying: cast in EVERY room that has a denizen at all.
	local need = tonumber(ataxiaBasher.infTyrannyAt)
		or ((infArmyOfDead and mnemResourceful) and 1 or 2)
	if n < need then return "" end
	-- 3% life essence a cast: never dip below the floor for a bashing nicety. Resourceful
	-- pays that back on every kill, so the floor drops with it.
	local essence = tonumber(ataxia.vitals and ataxia.vitals.essence)
	local floor = tonumber(ataxiaBasher.infEssenceFloor) or (mnemResourceful and 10 or 20)
	if essence and essence < floor then return "" end
	ataxiaTemp = ataxiaTemp or {}
	-- ONCE PER ROOM (user, v4.7.161): the gravehands belong to the room they were summoned
	-- in, so every new room can have its own. Not once per session (the v4.7.149 cut used a
	-- 600s timer, which skipped rooms) and not on a rotation cooldown (v4.7.148 re-cast
	-- every 20s, burning 3% essence each time). The last-cast room IS the gate; walking
	-- somewhere new re-arms it.
	--
	-- A nil room (gmcp blind) collapses to one "unknown" slot rather than casting every
	-- round while we cannot tell rooms apart.
	local room = (gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.num) or "unknown"
	if ataxiaTemp.infTyrannyRoom == room then return "" end
	ataxiaTemp.infTyrannyRoom = room
	local cmd = (gmcp.Char.Status.class == "Apostate") and "summon hands of the grave" or "tyranny"
	return cmd..sp
end

-- Fury of Ages (Mnemosyne boon): "You can now use your fury ability for 45 minutes out of
-- every hour, and it grants an additional 8 strength and 20% faster balance recovery, but
-- endurance costs are quadrupled under its effect."
--
-- Base FURY is +2 strength, 500 willpower after the first daily use, capped at 4 uses per
-- Achaean day -- which is why it is deliberately NOT automated normally. The boon changes
-- the economics completely: 45 minutes of every hour, +8 more strength and 20% faster
-- balance. That is a bashing buff worth holding up almost permanently.
--
-- The catch is QUADRUPLED ENDURANCE. Endurance is what runs out on a long grind, so this
-- watches EP and drops fury before it strands us:
--   * ON  at EP >= infFuryOnAt   (default 60%)
--   * OFF at EP <  infFuryOffAt  (default 25%)
-- The gap between the two is hysteresis on purpose -- flapping would be worse than not
-- using it, because each activation may cost 500 willpower. A 30s minimum between toggles
-- backs that up. State is optimistic (`ataxiaTemp.infFuryOn`) because no fury on/off game
-- line has been captured yet -- if one shows up, confirm from it instead.
function ataxiaBasher_infFury(sp)
	if not infFuryOfAges then return "" end
	local gv = (gmcp.Char and gmcp.Char.Vitals) or {}
	local ep, maxep = tonumber(gv.ep), tonumber(gv.maxep)
	if not ep or not maxep or maxep <= 0 then return "" end
	local pct = (ep / maxep) * 100
	local nowT = (getEpoch and getEpoch()) or os.time()
	ataxiaTemp = ataxiaTemp or {}
	if (nowT - (tonumber(ataxiaTemp.infFuryAt) or 0)) < 30 then return "" end
	local onAt = tonumber(ataxiaBasher.infFuryOnAt) or 60
	local offAt = tonumber(ataxiaBasher.infFuryOffAt) or 25
	if not ataxiaTemp.infFuryOn and pct >= onAt then
		ataxiaTemp.infFuryOn, ataxiaTemp.infFuryAt = true, nowT
		return "fury on"..sp
	elseif ataxiaTemp.infFuryOn and pct < offAt then
		ataxiaTemp.infFuryOn, ataxiaTemp.infFuryAt = nil, nowT
		return "fury off"..sp
	end
	return ""
end

-- Necrotic Aura (Mnemosyne boon): "While you are empowered by an aura of death, your
-- attacks will infect the body of your enemy, inhibiting them from healing."
--
-- The "aura of death" is the DEATHAURA defence (GMCP-tracked, `ataxia.defences.deathaura`,
-- raised by the bare `deathaura` command). So the boon turns an ordinary standing defence
-- into a damage multiplier against every self-healing denizen -- exactly the mobs that
-- otherwise out-heal a slow kill ("...ceases tending to his wounds"). Keep it up.
--
-- Defence-gated, so it re-ups ONLY when GMCP says it actually dropped, with a 10s
-- attempt-hold for the defence line to land. Not gated on danger level: unlike a word-
-- balance buff this is the thing making our attacks land harder, and it costs nothing
-- per swing once standing.
function ataxiaBasher_infDeathaura(sp)
	if not infNecroticAura then return "" end
	if ataxia.defences and ataxia.defences.deathaura then return "" end
	local nowT = (getEpoch and getEpoch()) or os.time()
	ataxiaTemp = ataxiaTemp or {}
	if (nowT - (tonumber(ataxiaTemp.infDeathauraAt) or 0)) < 10 then return "" end
	ataxiaTemp.infDeathauraAt = nowT
	return "deathaura"..sp
end

-- Indiscriminate (Mnemosyne boon): "Your Arc is now effective against denizens."
--
-- ARC is WEAPONMASTERY, not an Infernal ability -- so it belongs to EVERY knight
-- (Infernal, Paladin, Runewarden, Unnamable) and to all four specs. It shipped
-- Infernal-only in v4.7.145 purely because that was the class in the tower when the boon
-- was first captured, which left the other three knights holding a boon that did nothing
-- (user, 2026-08-10: "When a knight class, and this boon, if denizens is more than 2
-- please use arc instead"). Renamed from `ataxiaBasher_infArc` to match what it covers.
-- The boon FLAG keeps its legacy `infIndiscriminate` name: it is reset in three separate
-- places (run start, confirmed run end, the claim alias) and a missed rename there would
-- silently leave arc armed outside the tower, where it is a 4.75s swing that does nothing.
--
-- Arc normally reads "Works on: Adventurers and room", so it is dead weight in PvE; the
-- boon is what makes it hit denizens. The UNTARGETED form damages EVERYONE in the room
-- for 4.75s of balance; naming a target hits only them for 3.00s. We always want the room
-- form -- one wide swing instead of several narrow ones.
--
-- THE THRESHOLD IS 3, NOT 2 (v4.7.244, user-directed: "more than 2"). It spends BALANCE,
-- so like Tyranny it REPLACES the round's swing rather than riding alongside it, and the
-- arithmetic says the same thing the user did: 4.75s of arc against a ~2s dsl is 2.375
-- normal swings, so at TWO denizens arc lands 2 hits where focused swinging lands ~2.4 --
-- a loss. At three it lands 3 and wins, and the margin widens with every extra mob. Two
-- was the old default and was one denizen short of paying for itself.
--
-- `ataxiaBasher.arcAt` tunes it; the old `ataxiaBasher.infArcAt` is still honoured so an
-- existing hand-tuned value is not silently discarded. Neither is ever WRITTEN, so this is
-- a pure read-time default change with no migration to get wrong.
function ataxiaBasher_knightArc()
	if not infIndiscriminate then return "" end
	if ataxiaBasher.shielded then return "" end -- break the shield first
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	if n < (tonumber(ataxiaBasher.arcAt or ataxiaBasher.infArcAt) or 3) then return "" end
	-- PROOF OF LIFE (v4.7.245). Arc has no cooldown and no in-flight replay, so nothing here
	-- ever knew whether it actually fired -- and v4.7.244 handed it to three knights that have
	-- never run it. A silent refusal (wrong spec, nothing wielded, some prerequisite we do not
	-- know about) would spend EVERY round at 3+ denizens on nothing, in a crowded tower room:
	-- the exact "a feature that quietly never fires" shape this codebase keeps getting bitten
	-- by, in the exact situation v4.7.243 exists to survive.
	--
	-- The fire line (highlighting/046) sets `arcOk`, and that short-circuits this for good --
	-- once arc is proven for this character we stop policing it.
	--
	-- COUNT ATTEMPTS, NOT CALLS. This function runs on every 0.3s `queue addclearfull` rebuild,
	-- so a naive counter would reach three before the first arc had left the queue -- the same
	-- phantom-stamp trap that burned the battlerage rotations. The 4s gate (one arc's 4.75s
	-- balance, minus slack) collapses a round's rebuilds into a single attempt, and a gap
	-- between fights simply reads as the next attempt, which is correct.
	--
	-- It WARNS and does not disable: the diagnosis is a guess until the user confirms it, and
	-- a wrong auto-disable would silently remove a working ability. Worst case is one echo.
	if not ataxiaTemp.arcOk then
		local nowT = (getEpoch and getEpoch()) or os.time()
		if (nowT - (tonumber(ataxiaTemp.arcTryAt) or 0)) > 4 then
			ataxiaTemp.arcTryAt = nowT
			ataxiaTemp.arcTries = (tonumber(ataxiaTemp.arcTries) or 0) + 1
			if ataxiaTemp.arcTries >= 3 and not ataxiaTemp.arcWarned then
				ataxiaTemp.arcWarned = true
				ataxiaEcho("ARC swung 3 times with no fire line -- it may not be landing for this "
					.. "spec. Check it, or set <a_darkmagenta>ataxiaBasher.arcAt = 99<reset> to park it.")
			end
		end
	end
	-- No venom: denizens ignore the affliction, and a venom-less arc keeps the line short.
	return "arc"
end

-- QUASH (Oppression): "Adventurers and denizens", 4.00 seconds of EQUILIBRIUM, deals
-- damage and strips magical shields. That makes it the right answer to a shielded denizen
-- for Infernal -- it costs equilibrium, which is otherwise idle while every Infernal
-- attack spends balance, so it strips the shield WITHOUT spending rage (the standing
-- doctrine) and without costing us the swing. Shielded rounds only; short attempt-hold
-- because the eq cost means one per round at most.
function ataxiaBasher_infQuash(sp)
	if not ataxiaBasher.shielded then return "" end
	if ataxiaBasher.infQuash == false then return "" end
	local nowT = (getEpoch and getEpoch()) or os.time()
	ataxiaTemp = ataxiaTemp or {}
	if (nowT - (tonumber(ataxiaTemp.infQuashAt) or 0)) < 4 then return "" end
	ataxiaTemp.infQuashAt = nowT
	return "quash "..target..sp
end

function ataxiaBasher_infernalBashing()
	local command, sp = "", ataxia.settings.separator
	local raze, bash, spec = "", "", ataxia.vitals.knight
	local brage = ataxiaBasher_assembleBattlerage()
	local braze = ataxiaBasher.battlerage.Infernal.raze
	-- Boon-gated room nuke; rides ahead of the swing (see above).
	local graveHands = ataxiaBasher_infGravehands(sp)
	-- Necrotic Aura keeper: re-raises the deathaura defence when it drops, so every
	-- attack keeps inhibiting denizen healing. Prefixed to whatever the round does.
	-- Winter's Heart deepfreeze rides here too: it is an EQUILIBRIUM cast (from the
	-- Bracers of Frost, so it is not Magi-only) and every Infernal attack spends balance,
	-- so the room-wide cold is free alongside the swing.
	local aura = ataxiaBasher_infDeathaura(sp)..ataxiaBasher_infFury(sp)
		..ataxiaBasher_winterDeepfreeze(sp)

	-- HYENA MAUL is a PET order -- it costs us no balance and no equilibrium, so the only
	-- thing limiting it is its own cooldown. It used to be baked INSIDE each spec's swing
	-- string, which meant every round that replaces the swing silently dropped it:
	-- Tyranny rounds, Arc rounds, shielded-without-rageraze rounds, and Dual Blunt (which
	-- never had it at all). Hoisted into its own rider so it rides EVERY round (user:
	-- "hyena maul should be used as much as it can be").
	--
	-- The one exception is a shielded denizen: the maul would splash off the shield and
	-- burn the full cooldown for nothing, so we hold it the ~3s until the shield lapses.
	-- Skipping there is what MAXIMISES landed mauls.
	local maul = ""
	if ataxiaBasher.hyenaMaulReady and not ataxiaBasher.shielded then
		maul = "hyena maul "..target..sp
	end

	if spec == "Dual Cutting" then
		-- RAZESLASH, spelled out (user, v4.7.151): `rsl` is a personal server-side alias,
		-- not a game command -- the same class of bug as the old `st` vs `settarget`
		-- retarget failure, which silently did nothing for months.
		raze = "razeslash "..target
		bash = "dsl "..target..sp
	elseif spec == "Two Handed" then
		raze = "battlefury focus speed"..sp.."splinter "..target
		bash = "battlefury focus speed"..sp.."slaughter "..target..sp
	elseif spec == "Dual Blunt" then
		raze = "fracture "..target
		bash = "doublewhirl "..target
	else
		raze = "combination "..target.." raze smash"
		bash = "combination "..target.." slice smash"
	end
	
	if ataxiaBasher.shielded then
		-- QUASH rides the equilibrium here (strips the shield + damages, works on
		-- denizens) while the balance razer does its own job -- see ataxiaBasher_infQuash.
		local quash = ataxiaBasher_infQuash(sp)
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = aura..quash..braze..sp..bash
		else
			command = aura..quash..raze..sp..brage
		end
	elseif graveHands ~= "" then
		-- TYRANNY spends 3.00s of BALANCE, so it IS the round -- it cannot ride alongside
		-- the swing the way an eq ability would. The battlerage still goes with it (rage
		-- is its own resource). One-time, so it only pre-empts the swing once. The maul
		-- still rides: it is a pet order, not one of OUR balances.
		command = aura..maul..brage..graveHands:gsub(sp.."$", "")
	else
		-- ARC (Indiscriminate boon) likewise spends balance and so replaces the swing --
		-- one 4.75s room-wide hit instead of several single-target ones. The maul still
		-- rides: it is a pet order, not one of OUR balances.
		local arc = ataxiaBasher_knightArc()
		command = aura..maul..brage..sp..((arc ~= "") and arc or bash)
	end

	return command
end

function ataxiaBasher_jesterBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Jester.raze
	local wield = "wield blackjack;wield shield"..sp
	local rawhp = (gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", "")
	local mobhp = tonumber(rawhp) or 100
	local attack = (mobhp < 50) and "gallowshumour " or "bop "

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = wield..raze..sp..attack..target
		else
			command = wield.."badjoke "..target..sp..brage
		end
	else
		command = wield..brage..sp..attack..target
	end

	return command
end

-- Stormhammer/GUI prep, split out of magiBashing. The autobash loop pre-calls this once BEFORE
-- the attack (genrunning/004) so stormhammerTargets/GUI are current. It must NOT run the
-- battlerage: magiBashing is invoked twice per cycle (that pre-call + the real assembleAttack
-- call), and now that magiBattlerage ARMS its cooldowns on fire, a full pre-call would arm them
-- and the real call would then return "" -- Magi would send no battlerage at all. So the pre-call
-- does prep only; the send-path magiBashing does prep + battlerage. Cache-gated, so running the
-- prep in both is cheap.
function ataxiaBasher_magiStormPrep()
   -- GUI updates only when room contents have changed (dirty flag set by stormhammer invalidation)
   if ataxiaBasher_stormhammerDirty then
      ataxia_Update_RoomContents()
      if zgui then zgui.showRoomInfo() end
   end
   ataxiaBasher_stormhammer()
end

-- Winter's Heart (Mnemosyne boon): "Your deepfreeze spell can now be used against denizens
-- and deals cold damage to all denizens in the location."
--
-- DEEPFREEZE is Elementalism, but it is ALSO granted by the Bracers of Frost artefact --
-- the same bracers the swarm module points for icewalls -- so this is not Magi-only and
-- the helper is deliberately class-agnostic.
--
-- It is an equilibrium CAST, which is what makes it cheap here: for classes whose attacks
-- spend balance it rides free alongside the swing, and for Magi it takes the same eq slot
-- horripilation/elemental surge would have used. No client cooldown: one cast per
-- equilibrium is its own limit, exactly as Kkractle's elemental surge works.
--
-- Crowd-gated at 2+ (user-directed): the whole value is hitting the room, and against a
-- lone denizen an ordinary attack is better than a spread nuke.
-- DIVINE THUNDER CATACLYSM (Mnemosyne boon, v4.7.190): "Your Shindo thunderstorm ability
-- now deals electric damage to all denizens in your location." SHIN THUNDERSTORM is already
-- a room ability (AB 314, "Works on/against: Room"); the boon is what makes it hurt
-- DENIZENS, turning it into free crowd damage while we bash.
--
-- IT RIDES, IT DOES NOT REPLACE. AB says 4.00s of EQUILIBRIUM -- the balance swing is
-- untouched, so unlike the Thunderclap bisect (4s BALANCE, which displaces the swing) this
-- is prefixed alongside and costs us no attack. That resource-type distinction is the whole
-- reason these two crowd abilities are wired so differently.
--
-- Gated at 3+ denizens (user rule), higher than the 2+ used for the balance-spending crowd
-- swings, and the reason is the OTHER resource: 30 Shin energy is a large chunk of a pool
-- that infuse and the Bladed Reflexes SHIN AUGMENT are both drawing on. At two mobs a
-- room nuke does not repay emptying the pool the rest of the round depends on.
--
-- Cooldown is stamped on SEND and then RE-STAMPED from the confirmed strike line (trigger
-- 054 -> ataxiaBasher_bmThunderstormConfirm), so the 4s runs from the moment it actually
-- landed rather than from the moment we queued it. The send-side stamp is still the
-- backstop: an eaten cast then costs us one window instead of jamming the loop.
--
-- Not modelled: "likely to jangle the nerves of those struck" is presumably epilepsy on the
-- denizens, but ataxiaBasher_BR_AFFS carries no epilepsy entry and the apply line is
-- uncaptured, so nothing reads it yet.
function ataxiaBasher_bmThunderstorm(sp)
	if not mnemDivineThunder then return "" end
	if ataxiaBasher.shielded then return "" end -- break the shield first
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	if n < (tonumber(ataxiaBasher.thunderstormAt) or 3) then return "" end

	-- 30 Shin, and the pool is contested (infuse, SHIN AUGMENT). `thunderstormReserve`
	-- keeps a configurable buffer back for them; 0 by default, i.e. spend down to empty.
	local shin = (blademaster and blademaster.getShin and blademaster.getShin())
		or (ataxia.vitals and tonumber(ataxia.vitals.class)) or 0
	if shin < (30 + (tonumber(ataxiaBasher.thunderstormReserve) or 0)) then return "" end

	local nowT = (getEpoch and getEpoch()) or os.time()
	ataxiaTemp = ataxiaTemp or {}
	if nowT - (tonumber(ataxiaTemp.bmShinStormAt) or 0) < 4 then return "" end
	ataxiaTemp.bmShinStormAt = nowT
	return "shin thunderstorm"..sp
end

-- MIDNIGHT SNOW'S ICY HEART (Mnemosyne boon, v4.7.195): "Your Shindo blizzard ability now
-- deals cold damage to all denizens in your location." The exact twin of Divine Thunder
-- Cataclysm, and AB BLIZZARD (315) confirms it down to the numbers -- SHIN BLIZZARD,
-- "Works on/against: Room", 4.00s of EQUILIBRIUM, 30 Shin energy. Only the damage TYPE
-- differs: cold, where the thunderstorm is electric.
--
-- Because every cost is identical, these two are not two riders -- they are ONE slot with a
-- choice of damage type, which is why the picker below exists rather than a second copy of
-- the crowd gate. Casting both in a round would be the v4.7.193 same-resource collision:
-- 60 shin, two 4s equilibrium spends, one of them rejected outright.
--
-- Not modelled, deliberately: the AB says blizzard also "destroys any heat vibration" and
-- leaves "a temporary obscuring snowstorm" in the room. Whether that snowstorm hinders our
-- own targeting or denizen visibility has never been observed, so nothing here reads it --
-- but it is the first thing to check if the basher starts losing track of mobs in rooms it
-- has just blizzarded. (Heat-vibration destruction is a Magi crystalism concern, not ours.)
function ataxiaBasher_bmBlizzard(sp)
	if not mnemIcyHeart then return "" end
	if ataxiaBasher.shielded then return "" end -- break the shield first
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	if n < (tonumber(ataxiaBasher.blizzardAt) or tonumber(ataxiaBasher.thunderstormAt) or 3) then return "" end

	local shin = (blademaster and blademaster.getShin and blademaster.getShin())
		or (ataxia.vitals and tonumber(ataxia.vitals.class)) or 0
	if shin < (30 + (tonumber(ataxiaBasher.thunderstormReserve) or 0)) then return "" end

	local nowT = (getEpoch and getEpoch()) or os.time()
	ataxiaTemp = ataxiaTemp or {}
	if nowT - (tonumber(ataxiaTemp.bmShinStormAt) or 0) < 4 then return "" end
	ataxiaTemp.bmShinStormAt = nowT
	return "shin blizzard"..sp
end

-- Damage-type synonyms, matching the BM_INFUSE table: the tower's suppression affixes name
-- the TYPE in their sentence ("All cold damage you deal is reduced by 33%"), not the ability.
local BM_STORM = {
	lightning = { cmd = ataxiaBasher_bmThunderstorm, types = { "electricity", "electric", "lightning" } },
	ice       = { cmd = ataxiaBasher_bmBlizzard,     types = { "cold", "ice", "frost" } },
}
-- Thunderstorm first so a player who only owns Divine Thunder behaves exactly as before.
local BM_STORM_ORDER = { "lightning", "ice" }

-- ONE shin room-nuke per round, choosing the damage type the ripple is NOT suppressing.
--
-- This is the payoff for owning both boons: Iceproof ("All cold damage you deal is reduced
-- by 33%") makes us thunderstorm, and an electric-suppressing ripple makes us blizzard. It
-- is the same trick ataxiaBasher_bmInfuse plays with the four infuses, and it works for the
-- same reason -- the affix nulls a damage TYPE, and we happen to have two ways to deal it.
--
-- If both are suppressed, or neither, the preference order decides. Each helper self-gates
-- (boon, shield, crowd, shin, cooldown) and stamps only when it actually returns a command,
-- so calling them in order costs nothing on a round where the first says no.
function ataxiaBasher_bmShinStorm(sp)
	local M = ataxia and ataxia.mnemosyne
	local order = ataxiaBasher.bmStormPrefs or BM_STORM_ORDER
	local fallback
	for _, element in ipairs(order) do
		local entry = BM_STORM[element]
		if entry then
			fallback = fallback or entry
			local suppressed = false
			if M and M.damageNulled then
				for _, t in ipairs(entry.types) do
					if M.damageNulled(t) then suppressed = true; break end
				end
			end
			if not suppressed then
				local cmd = entry.cmd(sp)
				if cmd ~= "" then return cmd end
				-- That storm's own gate said no (boon not held, shin short, on cooldown);
				-- try the next damage type rather than forfeiting the round's nuke.
			end
		end
	end
	-- Everything suppressed: a 33% reduction still beats no AoE at all, so cast anyway.
	return (fallback and fallback.cmd(sp)) or ""
end

-- Fire-line confirmation for the storm (trigger 054, captured live 2026-08-01). Restamps the
-- cooldown from the LANDED moment. Every owned rotation ability wants both a fire line to
-- confirm and a refusal line to cancel; this is the confirm half. No refusal line has been
-- seen yet -- the send-side stamp covers that gap in the meantime.
-- Restamps the SHARED shin-storm slot: thunderstorm and blizzard cost the same 30 shin and
-- the same 4s of equilibrium, so one stamp covers both (v4.7.195). No blizzard fire line has
-- been captured yet -- when it is, point its trigger here too.
function ataxiaBasher_bmThunderstormConfirm()
	ataxiaTemp = ataxiaTemp or {}
	ataxiaTemp.bmShinStormAt = (getEpoch and getEpoch()) or os.time()
end

function ataxiaBasher_winterDeepfreeze(sp)
  if not mnemWintersHeart then return "" end
  if ataxiaBasher.shielded then return "" end -- break the shield first
  local M = ataxia.mnemosyne
  local n = (M and M._denizenCount and M._denizenCount()) or 0
  if n < (tonumber(ataxiaBasher.deepfreezeAt) or 2) then return "" end
  return "cast deepfreeze"..sp
end

function ataxiaBasher_magiBashing()
   local command, sp = "", ataxia.settings.separator
   local brage = ataxiaBasher_assembleBattlerage()
   ataxiaBasher_magiStormPrep()

   -- Active self-cure (Bloodboil) takes the equilibrium slot when afflictions have piled up (3+)
   -- and the Tree of Life tattoo -- the passive cure -- is on balance. It is a main skill, not a
   -- battlerage, so it replaces the eq staff-bash for this cycle; battlerage (rage) still fires
   -- alongside. addclearfull-queued, so it self-dedups and just waits for eq. See
   -- ataxiaBasher_magiShouldBloodboil (basher/001).
   if ataxiaBasher_magiShouldBloodboil() then
      return brage..sp.."cast bloodboil"
   end

   if ataxiaBasher.shielded then
      -- erode is Magi's free shield strip (why Disintegrate is never fired -- see magiBattlerage).
      -- Strip FIRST, then battlerage -- a still-up denizen shield absorbs the BR otherwise
      -- (matches blademasterBashing's raze..sp..brage order).
      command = "cast erode at "..target..sp..brage
   elseif ataxiaBasher_winterDeepfreeze(sp) ~= "" then
      -- Winter's Heart boon: DEEPFREEZE hits every denizen in the room for cold. Same eq
      -- slot as horripilation/elemental surge, and it outranks Kkractle only in that it is
      -- checked first -- if you hold both, keep whichever you prefer by disabling the
      -- other's flag. Crowd-gated inside the helper.
      command = brage..sp.."cast deepfreeze"
   elseif magiKkractle then
      -- Aspect of Kkractle boon (Mnemosyne): ELEMENTAL SURGE deals fire to ALL denizens in the
      -- room (AoE, no target), out-clearing single-target horripilation and stormhammer's 3-cap.
      -- Set by the BOONS-list trigger / boon-claim alias, reset each run (mirrors bmShatteredStar).
      -- Same eq-cast slot horripilation used, so no extra spam vs the old unconditional attack.
      -- Needs a summoned ashbeast up (kept off the target list via ownDenizens = ...ashbeast).
      command = brage..sp.."elemental surge"
   elseif ataxiaBasher.stormhammer and ataxiaBasher_validTargets() > 2 and #stormhammerTargets >= 3 then
      command = brage..sp.."cast stormhammer at "..stormhammerTargets[1].. " and " ..stormhammerTargets[2].. " and " ..stormhammerTargets[3]
   else
      command = brage..sp.."staff cast horripilation at "..target
   end
   return command
end


-- Willow is the damage form (speed is king), and Willow -> Rain -> Oak -> Willow is the
-- shortest legal cycle back to it (see shikudo.transitions), so ride Willow to its 12-kata
-- cap and leave Rain/Oak as soon as a transition is LEGAL.
--
-- leaveAt is the kata the chain must ALREADY be at, read *before* this combo is sent.
-- A TRANSITION needs a chain of at least 5 ("A kata of at least 5 must be performed in order
-- to flow from the Live Oak to another") and a REJECTED transition RESETS the chain to 0.
-- That reset is why leaveAt must be >= 5 and not 2: the old value bet on the queued combo's
-- 3 actions landing first (2+3=5), but in game the transition was evaluated while the chain
-- was still 3, got rejected, reset the chain, and the next pass repeated it -- an infinite
-- fail loop that never transitioned at all. Gate on a chain that is legal on its own and the
-- loop cannot form, whatever the combo contributes.
--
-- Combos are 3 actions, so the chain steps 0,3,6,9,12 and first satisfies >= 5 at 6.
-- That gives 4 combos in Willow (0,3,6,9) and 3 in each of Rain/Oak (0,3,6) -- ~40% Willow.
-- Tykonos is where a stumble dumps you, and it transitions straight back to Willow.
local SHIKUDO_BASH_ROTATION = {
  Willow    = {nextForm = "Rain",   leaveAt = 9},
  Rain      = {nextForm = "Oak",    leaveAt = 5},
  Oak       = {nextForm = "Willow", leaveAt = 5},
  Tykonos   = {nextForm = "Willow", leaveAt = 5},
  Gaital    = {nextForm = "Rain",   leaveAt = 5},
  Maelstrom = {nextForm = "Oak",    leaveAt = 5},
}

-- shieldbreak variants swap a hit for shatter. Gaital/Maelstrom combos are built from
-- shikudo.formAttacks rather than copied from known-good code — verify in game.
local SHIKUDO_BASH_COMBOS = {
  Willow    = {normal = "hiru hiraku flashheel left",             shieldbreak = "shatter hiru flashheel left"},
  Rain      = {normal = "ruku torso kuro left frontkick left",    shieldbreak = "shatter hiru frontkick left"},
  Oak       = {normal = "livestrike nervestrike risingkick head", shieldbreak = "shatter livestrike risingkick head"},
  Tykonos   = {normal = "thrust head thrust head risingkick head", shieldbreak = "shatter thrust head risingkick head"},
  Gaital    = {normal = "ruku torso kuro left dawnkick left",     shieldbreak = "shatter ruku dawnkick left"},
  Maelstrom = {normal = "ruku torso livestrike risingkick head",  shieldbreak = "shatter ruku risingkick head"},
}

-- Kai Unleashed boon (Mnemosyne, legendary): "Kai choking a denizen deals a burst of
-- magic damage to all denizens in its location, including itself. This effect has a
-- 30 seconds cooldown before it can trigger again." User doctrine: RAIN form only,
-- off cooldown, priority when 2+ denizens share the room (the burst hits them all).
-- AB Kaichoke (ID 896) facts: KAI CHOKE <target>, 4.00s of EQUILIBRIUM, 10 kai +
-- 50 mana -- but **against a denizen it requires and consumes NO kai** (same-room
-- only, which bashing always is), so there is no kai gate here, just a small mana
-- floor. Because it rides EQ -- idle while Shikudo combos spend balance -- the choke
-- PREPENDS to the round's combo rather than replacing it: burst and swing land
-- together. The rotation re-visits Rain every cycle, so no form-forcing. Cooldown
-- (the BOON's 30s burst, not the ability's 4s eq) stamped at send into ataxiaTemp
-- (survives a SYSUPDATE reload; cleared on run end).
local KAI_UNLEASHED_CD = 30 -- the boon burst's cooldown, from the CONFIRMED burst line
local KAI_CHOKE_RETRY = 6   -- unconfirmed choke (eaten/wiped/no proc): retry this often
function ataxiaBasher_kaiUnleashedChoke(useShieldbreak)
  if not mnemKaiUnleashed then return nil end
  if useShieldbreak then return nil end -- shielded target: let shatter land first
  if ataxia.vitals.form ~= "Rain" then return nil end
  if (tonumber(ataxia.vitals.mp) or 9999) < 250 then return nil end -- 50-mana cost; never scrape a dry pool
  local M = ataxia.mnemosyne
  local n = (M and M._denizenCount and M._denizenCount()) or 0
  if n < 2 then return nil end
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp = ataxiaTemp or {}
  if (nowT - (tonumber(ataxiaTemp.kaiUnleashedAt) or 0)) < KAI_UNLEASHED_CD then return nil end
  if (nowT - (tonumber(ataxiaTemp.kaiChokePendingAt) or 0)) < KAI_CHOKE_RETRY then return nil end
  ataxiaTemp.kaiChokePendingAt = nowT
  return "kai choke "..target.."; "
end

-- Burst CONFIRMED (trigger 031, live-captured 2026-07-27): "Your surroundings ripple
-- like a lake's surface struck as a transparent wave of kai energy surges outwards
-- from <mob>, wracking mind and body." (8472 magical in the capture). The line only
-- prints with the boon up (self-proving, like the Reaper tithe), so it also sets the
-- flag. The REAL 30s cooldown starts HERE, not at send -- an eaten/wiped choke must
-- not lock the burst out; it just retries after KAI_CHOKE_RETRY.
function ataxiaBasher_kaiUnleashedBurst()
  mnemKaiUnleashed = true
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.kaiUnleashedAt = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp.kaiChokePendingAt = nil
end

-- Senseless Flurry boon (Mnemosyne): "Your balance recovers 30% faster while you
-- have the numbness defence." AB Numbness (ID 894): NUMB, self-only, 3.00s of
-- EQUILIBRIUM -- the same idle-during-combos channel Kai Choke rides -- and it
-- DEFERS incoming damage (delivered later in one blow at -40%: strictly good while
-- bashing, and the swarm module's per-prompt vitals watchdog already covers the
-- deferred hit landing). User doctrine: keep numbness up in RAIN form. Gated on
-- the GMCP-tracked defence (expiry arrives via Char.Defences.Remove -- no duration
-- guessing; fire line "You grit your teeth and will your pain out of existence."
-- live-captured 2026-07-27) + the bmAugment-style 5s attempt-hold against respam.
-- Kai Choke OUTRANKS it for a round's eq (see the call site): the 30s AoE burst
-- is worth more than a numb refresh. Self-targeted, so shielded rounds still numb.
function ataxiaBasher_senselessFlurryNumb()
  if not mnemSenselessFlurry then return nil end
  if ataxia.vitals.form ~= "Rain" then return nil end
  if ataxia.defences and ataxia.defences.numbness then return nil end
  -- CROWD GATE (review HIGH): while numb is up HP does not move, so EVERY HP-based
  -- safety goes blind -- the damage-rate watchdog records nothing, danger levels
  -- never trip, and the swarm escape ladder (HP-gated) stays silent -- then the
  -- deferred lump lands as ONE blow (-40%) that in a deep-ripple crowd can exceed
  -- max HP: death from "full HP" with every alarm quiet. Numb only in THIN rooms,
  -- where the lump is survivable and the next prompt's huge hp-delta trips the
  -- rate-shield normally; in swarm-threshold crowds (or mid-tactic) live HP data
  -- is worth more than 30% balance.
  local M = ataxia.mnemosyne
  local n = (M and M._denizenCount and M._denizenCount()) or 0
  local thr = (M and M.swarm and M.swarm.threshold and M.swarm.threshold()) or 3
  if n >= thr then return nil end
  if M and M.swarm and M.swarm.state and M.swarm.state ~= "idle" then return nil end
  ataxiaTemp = ataxiaTemp or {}
  if ataxiaTemp.numbAttempted then return nil end
  ataxiaTemp.numbAttempted = true
  tempTimer(5, [[ataxiaTemp.numbAttempted = nil]])
  return "numb; "
end

-- These fire from the attack path, which runs on every prompt — latch them so an
-- unrecognised form or spec warns once rather than flooding the screen.
local shikudoWarnedForm = nil
local monkWarnedNoSpec = false

local function shikudoBashCombo(tar, useShieldbreak)
  local form = ataxia.vitals.form
  local combos, rot = SHIKUDO_BASH_COMBOS[form], SHIKUDO_BASH_ROTATION[form]
  if not combos or not rot then
    if shikudoWarnedForm ~= form then
      shikudoWarnedForm = form
      ataxiaEcho("Shikudo: don't know how to bash in '"..tostring(form).."' form.")
    end
    return ""
  end
  shikudoWarnedForm = nil

  local cmd = "combo "..tar.." "..(useShieldbreak and combos.shieldbreak or combos.normal)
  -- COMBO takes an inline TRANSITION suffix -- per AB SHIKUDO COMBO:
  --   COMBO <target> <attack1> [limb] [attack2] [limb] [attack3] [limb] [TRANSITION <form>]
  -- Use that rather than a separate `transition to the <form> form` command: the inline form
  -- resolves inside the combo's own flow instead of racing the three attacks that build the
  -- chain it depends on. kata is absent from charstats until a chain starts, hence `or 0`.
  if (ataxia.vitals.kata or 0) >= rot.leaveAt then
    cmd = cmd.." transition "..rot.nextForm:lower()
    -- A successful TRANSITION resets the chain to 0, but charstats keeps reporting the OLD
    -- kata for a tick. Without zeroing it here the very next prompt still reads the pre-
    -- transition kata (e.g. 6), re-appends a transition, and that one resolves against a
    -- chain of only 3 -> "A kata of at least 5 must be performed..." -> a wasted attempt after
    -- every single form change. Zero it optimistically; charstats re-reports the true value on
    -- its next tick, and 002_Reset_Failsafe also zeroes it if the transition is rejected, so a
    -- wrong guess here self-corrects within one tick either way.
    ataxia.vitals.kata = 0
  end
  return cmd.."; "
end

function ataxiaBasher_monkBashing2()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
  -- Resolve the spec by charstats *key* via the vitals parser, not by the positional
  -- index charstats[4]: a shifted index silently made both flags false (= no attack).
  -- ataxia.vitals.stance is reset to false every vitals tick, so it is a safe discriminator.
  local tekura = ataxia.vitals.stance and true or false
  local shikudo = not tekura and ataxia.vitals.form ~= nil

  -- Transmute is a GAP-FILLER, not a top-up. Health sipping is server-side (CURING SIPHEALTH,
  -- default 80), so while sip balance is UP the server is already healing us -- transmuting back
  -- to 90% on every single balance (the old behaviour) just burned the mana that Regeneration
  -- converts into health anyway, plus everything else that needs mana. Only fire in the window
  -- sipping cannot cover: sip balance DOWN and actually low on health.
  --   transmuteat : hp% at/below which transmute may fire  (default 70)
  --   transmuteto : hp% to top back up to                  (default 99)
  --   manause     : mp% floor we never spend past          (default 30)
  -- `sipbal == false` and NOT `not sipbal`: ataxia.vitals is reset to {} on login and only the
  -- sip triggers (balances/002,003) ever set it, so it is nil until the first sip of a session
  -- -- nil must not read as "off balance" or we would transmute with sip balance in hand.
  local sip = ataxia.settings.sipping or {}
  local maxhp, maxmp = ataxia.vitals.maxhp or 0, ataxia.vitals.maxmp or 0
  if ataxia.vitals.sipbal == false and maxhp > 0
     and (ataxia.vitals.hp / maxhp * 100) <= (sip.transmuteat or 70) then
    local xmute = math.ceil(maxhp * ((sip.transmuteto or 99) / 100))
    local mpl = ataxia.vitals.mp - (maxmp * ((sip.manause or 30) / 100))
    local hpl = xmute - ataxia.vitals.hp
    if hpl > 1 then
      -- floor(): the mana floor is fractional, so the min can be too, and `transmute 1234.5`
      -- is not a valid command.
      local tomute = math.floor(hpl < mpl and hpl or mpl)
      if tomute > 100 then
        command = command.."transmute "..tomute..ataxia.settings.separator
      end
    end
  end

  -- Monk NEVER spends rage to break a denizen shield: both specs carry a free shield breaker
  -- (Shikudo `shatter` -- uniquely usable in the flow of ANY form -- and Tekura `rhk`), so the
  -- 17-rage Splinterkick raze (battlerage.Monk.raze = "spk") is always the worse trade; that
  -- rage is worth more on damage/afflictions. `ataxiaBasher.rageraze` is deliberately ignored
  -- here -- it still governs every other class. Shielded => skip battlerage and let the combo
  -- break the shield itself.
  -- CAVEAT: the crushbash branch below ignores useShieldbreak -- `mind crush` neither breaks a
  -- shield nor spends rage, so a shielded mob in crushbash mode is only handled if mind crush
  -- (being mental) bypasses shielding. Pre-existing; unconfirmed in game.
  local useShieldbreak = ataxiaBasher.shielded and true or false
  if not useShieldbreak then
    command = command..brage..sp
  end

  if ataxia.settings.crushbash then
    command = command.."mind crush "..target.."; "
  elseif tekura then
    monkWarnedNoSpec = false
    command = command.."unwield all"..sp.."combo "..target..(useShieldbreak and " rhk ucp ucp; " or " sdk ucp ucp; ")
  elseif shikudo then
    monkWarnedNoSpec = false
    -- EQ riders alongside the balance combo (both land the same round). One eq
    -- spender per round: Kai Unleashed's 30s AoE burst outranks the Senseless
    -- Flurry numb refresh when both are eligible.
    local choke = ataxiaBasher_kaiUnleashedChoke(useShieldbreak)
    command = command..(choke or ataxiaBasher_senselessFlurryNumb() or "")
    command = command..shikudoBashCombo(target, useShieldbreak)
  elseif not monkWarnedNoSpec then
    monkWarnedNoSpec = true
    ataxiaEcho("Monk: no Stance or Form in charstats -- can't tell Tekura from Shikudo, not bashing.")
  end

	return command   
end









function ataxiaBasher_occultistBashing()
   local command = ""   
   
   command = command..ataxiaBasher_assembleBattlerage()
   command = command.."warp "..target

   return command   
end

function ataxiaBasher_pariahBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Pariah.raze

	if ataxiaBasher.shielded then
		-- Target is shielded, use raze to break it
		command = "trace fissure "..target
	elseif ataxiaBasher.swarmDevourReady then
		-- Swarm devour ready - unwield shield, devour, then epitaph advance
		command = "unwield shield"..sp.."swarm devour flushings "..target..sp..brage.."epitaph advance "..target
	else
		-- Swarm devour on cooldown - wield shield and epitaph advance
		command = "wield shield"..sp..brage.."epitaph advance "..target
	end

	return command
end

function ataxiaBasher_paladinBashing()
	local command, sp = "", ataxia.settings.separator
	local raze, bash, spec = "", "", ataxia.vitals.knight
	local brage = ataxiaBasher_assembleBattlerage()
	local braze = ataxiaBasher.battlerage.Paladin.raze

	if spec == "Dual Cutting" then
		raze = "razeslash "..target
		bash = "dsl "..target
	elseif spec == "Two Handed" then
		raze = "battlefury focus speed"..sp.."carve "..target
		bash = "battlefury focus speed"..sp.."slaughter "..target
	elseif spec == "Dual Blunt" then
		raze = "fracture "..target
		bash = "doublewhirl "..target
	else
		raze = "combination "..target.." raze smash"
		bash = "combination "..target.." slice smash"
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = braze..sp..bash
		else
			command = raze..sp..brage
		end
	else
		-- ARC (Indiscriminate boon): Weaponmastery, so Paladin gets it too. Spends balance,
		-- therefore REPLACES the swing rather than riding it. The battlerage still goes --
		-- rage is its own resource.
		local arc = ataxiaBasher_knightArc()
		command = brage..sp..((arc ~= "") and arc or bash)
	end

	return command
end

-- Psion OWNS its battlerage (the Blademaster/Magi pattern): the generic assembler's
-- old Psion branch gated Barbedblade/Whirlwind behind `battleRage_Timers.special`,
-- but triggers 330-332 have NO Psion fire-lines -- the timers were never set, so the
-- rotation was Regrowth-only forever. This is timer-FREE: send-side epoch stamps with
-- the wiki cooldowns (Devastate/Whirlwind 23s, Barbedblade 16s, Regrowth 35s), so it
-- depends on nothing unwired. Priority: reap (culling) > Devastate (the 36-rage nuke
-- the old table lacked) > Whirlwind > Barbedblade filler. Regrowth (anti-heal vines)
-- only pays vs self-healing denizens ("tending his wounds"), so it is OPT-IN via
-- `ataxiaBasher.psionRegrowth` and takes priority when enabled.
local PSION_BR = {
  { key = "regrowth",   cmd = "enact regrowth",   rage = 24, cd = 35, optIn = true },
  { key = "devastate",  cmd = "psi devastate",    rage = 36, cd = 23 },
  { key = "whirlwind",  cmd = "weave whirlwind",  rage = 25, cd = 23 },
  { key = "barbedblade", cmd = "weave barbedblade", rage = 14, cd = 16 },
}
function ataxiaBasher_psionBattlerage(sp)
  local rage = tonumber(ataxia.vitals.rage) or 0
  -- Rage conservation: same rule the generic assembler applies. Clears any in-flight
  -- pick so a stale cast can't resume on the NEXT mob.
  if ataxiaBasher.rageConserveThreshold then
    local mobhp = tonumber(((gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", ""))) or 100
    if mobhp > 0 and mobhp <= ataxiaBasher.rageConserveThreshold then
      ataxiaTemp.psionBrPending = nil
      return ""
    end
  end
  local nowT = (getEpoch and getEpoch()) or os.time()
  -- In-flight pick REPLAY (v4.7.129 review HIGH, found on the Golden Dragon copy of
  -- this pattern): the basher rebuilds this command every prompt/vitals event while
  -- balance is down, and each rebuild's addclearfull wipes the previously queued
  -- line -- stamping per rebuild burned the rotation phantom-style. A pick stays
  -- pending ~one balance round and is replayed verbatim (command stability across
  -- the 0.3s re-queue loop); the rotation advances only after the hold expires.
  local pend = ataxiaTemp.psionBrPending
  if pend and pend.cmd and (nowT - (tonumber(pend.at) or 0)) < 3 then
    return pend.cmd
  end
  ataxiaTemp.psionBrPending = nil
  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and ataxiaBasher_cullAfford(rage, 36)
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    return "reap "..target..sp
  end
  ataxiaTemp.psionBrAt = ataxiaTemp.psionBrAt or {}
  for _, ab in ipairs(brPickOrder(PSION_BR)) do
    -- Rage floor (v4.7.141): see ataxiaBasher_rageAfford (001).
    if (not ab.optIn or ataxiaBasher.psionRegrowth) and ataxiaBasher_rageAfford(rage, ab.rage)
       and (nowT - (tonumber(ataxiaTemp.psionBrAt[ab.key]) or 0)) >= ab.cd then
      ataxiaTemp.psionBrAt[ab.key] = nowT
      -- `verb` must be the ROTATION KEY, not the command (v4.7.193, Codex). The ready-line
      -- feed (011) releases a held pick with `pend.verb == field`, where field is the map
      -- key ("barbedblade"). Storing "weave barbedblade" here meant that comparison never
      -- matched for ANY of the four Psion abilities, so a pick kept being replayed for the
      -- rest of its 3s window after the game had already said the ability was ready again.
      -- `cmd` is carried alongside so the replay stays byte-stable. Golden Dragon dodged
      -- this only because its four commands happen to equal their keys; Runewarden and
      -- Depthswalker always stored the key.
      ataxiaTemp.psionBrPending = { verb = ab.key, cmd = ab.cmd.." "..target..sp, at = nowT }
      return ab.cmd.." "..target..sp
    end
  end
  return ""
end

function ataxiaBasher_psionBashing()
  local command, sp = "", ataxia.settings.separator
  -- NOTE: the battlerage is computed LAZILY below, after the shielded early-return
  -- (v4.7.129 review): psionBattlerage stamps cooldowns when it picks, and the
  -- shielded branch emits no battlerage -- an eager call there burned the pick's
  -- cooldown stamp unsent every shielded round.

  -- Panoply boon (Mnemosyne, legendary): "The damage dealt by your weaving flurry
  -- ability scales directly to the number of strikes landed, randomly dealing 60% to
  -- 200% of its damage with each attack." AB Flurry (ID 2704): WEAVE FLURRY <target>,
  -- works on denizens, 2.60s of balance. With the boon up it out-damages the deathblow
  -- bash, so it becomes the primary (user-directed). Straight verb swap mirroring
  -- bmShatteredStar; psi shatter keeps its transcendence slot.
  local weave = psionPanoply and ("weave flurry "..target) or ("weave deathblow "..target)

  -- EQ riders (equilibrium is idle while weaves spend balance -- the Kai Choke lesson):
  -- Roth is the sub-50% emergency heal (AB: 1.30s eq, 3-min cooldown, grants clarity +
  -- rupture free) -- it belongs BEFORE any shield/flee response fires.
  ataxiaTemp.psionRothAt = ataxiaTemp.psionRothAt or 0
  local nowT = (getEpoch and getEpoch()) or os.time()
  if (tonumber(ataxia.vitals.hpp) or 100) < 50
     and (nowT - (tonumber(ataxiaTemp.psionRothAt) or 0)) >= 185 then
    ataxiaTemp.psionRothAt = nowT
    command = command.."enact roth"..sp
  end
  -- Transcendence keeper: the shatter loop assumes PSI TRANSCEND is active, but
  -- nothing ever re-upped it after a drop/death. The psitranscend defence is
  -- GMCP-tracked; re-up on eq (rides the swing) with a 10s attempt-hold.
  if not (ataxia.defences and ataxia.defences.psitranscend)
     and not ataxiaTemp.psionTranscendAttempted then
    ataxiaTemp.psionTranscendAttempted = true
    tempTimer(10, [[ataxiaTemp.psionTranscendAttempted = nil]])
    command = command.."psi transcend"..sp
  end

  if ataxiaBasher.shielded then
    -- Review fix: this branch could build an EMPTY command (no cleave fallback
    -- without rageraze) or DOUBLE-break (pulverise + cleave, wasting the balance).
    -- Pulverise breaks on RAGE -- no balance -- so pair it with the damage weave in
    -- the same round; otherwise cleave (balance) is the always-available breaker.
    if ataxiaBasher.rageraze and (tonumber(ataxia.vitals.rage) or 0) >= 17 then
      command = command.."weave pulverise "..target..sp..weave
    else
      command = command.."weave cleave "..target
    end
    return command
  end

  -- Battlerage only from here down -- every remaining branch sends it, so the pick's
  -- cooldown stamp can no longer burn unsent.
  local brage = ataxiaBasher_brCommit(ataxiaBasher_psionBattlerage(sp))

  -- Secondskin keeper: resistance to ALL damage types; it drops rarely, so spending
  -- one round's balance re-weaving it (3.00s bal -- it REPLACES the swing) is cheap
  -- insurance. Skipped on shielded rounds above (break the shield first).
  if not (ataxia.defences and ataxia.defences.secondskin)
     and not ataxiaTemp.psionSecondskinAttempted then
    ataxiaTemp.psionSecondskinAttempted = true
    tempTimer(10, [[ataxiaTemp.psionSecondskinAttempted = nil]])
    return command..brage.."weave secondskin"
  end

  if ataxiaTemp.transcendence and ataxiaTemp.transcendence == 100 then
    command = command..brage.."psi shatter "..target..sp..weave
  else
    command = command..brage..weave
    --Deathblow does 3 percent to elite mhun keeper
  end
  return command
end

function ataxiaBasher_priestBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Priest.raze
	
	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = raze..sp.."smite "..target
		else
			command = "smite "..target
		end
	else
		command = brage..sp.."smite "..target
	end
	if empathyTick and empathyTick >= 2 then
		command = command..sp.."angel power"
	end   
	return command 
end

function ataxiaBasher_knightBashing()
	local command, sp = "", ataxia.settings.separator
	local raze, bash, spec = "", "", ataxia.vitals.knight
	local brage = ataxiaBasher_assembleBattlerage()
	local braze = ataxiaBasher.battlerage[ataxiaTemp.class].raze

	if spec == "Dual Cutting" then
		raze = "razeslash "..target
		bash = "dsl "..target
	elseif spec == "Two Handed" then
		raze = "battlefury focus speed"..sp.."carve "..target
		bash = "battlefury focus speed"..sp.."slaughter "..target
	elseif spec == "Dual Blunt" then
		raze = "fracture "..target
		bash = "doublewhirl "..target
	else
		raze = "combination "..target.." raze smash"
		bash = "combination "..target.." slice smash"
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = braze..sp..bash
		else
			command = raze..sp..brage
		end
	else
		-- ARC (Indiscriminate boon): this is the generic knight path -- Unnamable today, and
		-- whatever else routes here later. Weaponmastery is shared, so the boon is too.
		local arc = ataxiaBasher_knightArc()
		command = brage..sp..((arc ~= "") and arc or bash)
	end

	return command
end

-- Hammer and Nail (Mnemosyne boon, Runewarden): "While a sowulu rune is present, your
-- attacks will cause damage to another random denizen in the location." So the rune turns
-- every ordinary swing into a two-target hit -- worth laying BEFORE we start attacking,
-- and only worth it with something else in the room to splash onto.
--
-- ONCE PER ROOM, gated on the room number exactly like Tyranny: the rune sits on this
-- room's ground, so a new room needs its own and re-entering a room re-sketches. Sketching
-- is a FREE-queue action (see the rune aliases, `queue add free sketch ...`), so it costs
-- no balance and can ride ahead of the swing.
function ataxiaBasher_rwSowulu(sp)
	if not mnemHammerAndNail then return "" end
	if ataxiaBasher.shielded then return "" end -- break the shield first
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	if n < (tonumber(ataxiaBasher.sowuluAt) or 2) then return "" end
	ataxiaTemp = ataxiaTemp or {}
	local room = (gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.num) or "unknown"
	if ataxiaTemp.rwSowuluRoom == room then return "" end
	ataxiaTemp.rwSowuluRoom = room
	return "sketch sowulu on ground"..sp
end

-- Runewarden OWNS its battlerage (the Psion/Golden Dragon pattern).
--
-- CORRECTION (v4.7.164): this was NOT the missing-fire-line bug. Runewarden's lines DO
-- exist and DO set the shared timers -- collide at 330:47 ("You charge at <t>, slamming
-- into him and throwing him back.") and onslaught at 331:47 ("You unleash a ferocious
-- onslaught on <t>...") -- their trigger bodies are class-AGNOSTIC. The v4.7.163 claim
-- that onslaught could never fire was wrong; it came from grepping those files for the
-- word "Runewarden", which only appears in class-gated blocks.
--
-- What was genuinely broken, and what this rotation buys:
--   * BULWARK sat behind `validTargets() >= 2` in standardBattlerage, so the class's
--     headline mitigation was skipped in every single-mob fight. It is Self-targeted --
--     mob count is irrelevant.
--   * ETCH was not wired AT ALL (the config only has small/large/raze/special), so its
--     aeon/stun bonus damage was never taken.
--   * Real AB cooldowns instead of the shared 17s/24s trigger timers, plus the rage
--     floor, the in-flight pick replay, and owned culling.
--
-- AB values (all "Works on/against: Denizens" except Bulwark, which is Self):
--   Bulwark  28r / 45s cd -- negates 25% of ALL damage for 15s   <- the 15s is the
--            DURATION, not the cooldown; 45s is as often as it can be held.
--   Etch     25r / 23s -- ETCH RUNE AT <t>, "Afflictions Used: Aeon or Stun": bonus
--            damage only when the mob cannot dodge, so it is gated on the denizen
--            actually carrying one (the Depthswalker Erasure rule -- solo it simply
--            never fires and costs nothing).
--   Onslaught 36r / 23s -- big damage.
--   Collide   14r / 16s -- filler.
local RW_BR = {
  -- `control` is a slight stretch here and deliberately so: Runewarden has NO battlerage
  -- that slows a DENIZEN (etch CONSUMES aeon/stun rather than applying it, onslaught and
  -- collide are pure damage). Bulwark is the nearest equivalent -- negate 25% of ALL
  -- damage for 15s -- and against a control-first mob that mitigation must not be
  -- displaced by the Rage-Fuelled "spend the dearest first" rule, which would otherwise
  -- pick onslaught (36r) over it.
  { key = "bulwark",   cmd = "bulwark",       rage = 28, cd = 45, noTarget = true, slows = true },
  { key = "etch",      cmd = "etch rune at",  rage = 25, cd = 23, needsAff = { "aeon", "stun" } },
  { key = "onslaught", cmd = "onslaught",     rage = 36, cd = 23 },
  { key = "collide",   cmd = "collide",       rage = 14, cd = 16 },
}

-- Fire-line confirmation (trigger 332 already matches the bulwark line for Runewarden):
-- restart the cooldown from the LANDED moment and release the in-flight hold.
function ataxiaBasher_rwConfirm(key)
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp.rwBrAt = ataxiaTemp.rwBrAt or {}
  ataxiaTemp.rwBrAt[key] = nowT
  local pend = ataxiaTemp.rwBrPending
  if pend and pend.verb == key then ataxiaTemp.rwBrPending = nil end
end

function ataxiaBasher_rwBattlerage(sp)
  local rage = tonumber(ataxia.vitals.rage) or 0
  if ataxiaBasher.rageConserveThreshold then
    local mobhp = tonumber(((gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", ""))) or 100
    if mobhp > 0 and mobhp <= ataxiaBasher.rageConserveThreshold then
      ataxiaTemp.rwBrPending = nil
      return ""
    end
  end
  local nowT = (getEpoch and getEpoch()) or os.time()
  -- In-flight pick replay: the basher rebuilds this command every prompt while balance is
  -- down and each rebuild's addclearfull wipes the queued line, so a pick is held ~one
  -- balance round and replayed verbatim (see the v4.7.129 lesson).
  local pend = ataxiaTemp.rwBrPending
  if pend and pend.cmd and (nowT - (tonumber(pend.at) or 0)) < 3 then return pend.cmd end
  ataxiaTemp.rwBrPending = nil
  if getEpoch and getEpoch() < (ataxiaTemp.brGlobalReadyAt or 0) then return "" end

  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and ataxiaBasher_cullAfford(rage, 36)
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    ataxiaBasher_brSent()
    return "reap "..target..sp
  end

  ataxiaTemp.rwBrAt = ataxiaTemp.rwBrAt or {}
  for _, ab in ipairs(brPickOrder(RW_BR)) do
    local ready = (nowT - (tonumber(ataxiaTemp.rwBrAt[ab.key]) or 0)) >= ab.cd
    local gated = false
    if ab.needsAff then
      local got = false
      for _, aff in ipairs(ab.needsAff) do
        if ataxiaBasher_dsHasAff and ataxiaBasher_dsHasAff(target, aff) then got = true end
      end
      if not got then gated = true end
    end
    if ready and not gated and ataxiaBasher_rageAfford(rage, ab.rage) then
      local cmd = ab.cmd..(ab.noTarget and "" or (" "..target))..sp
      ataxiaTemp.rwBrAt[ab.key] = nowT
      ataxiaTemp.rwBrPending = { verb = ab.key, cmd = cmd, at = nowT }
      ataxiaBasher_brSent()
      return cmd
    end
  end
  return ""
end

-- THUNDERCLAP (Mnemosyne boon, v4.7.181): "Your bisect ability now strikes a third time,
-- dealing bonus electric damage to ALL denizens in your location." That turns a
-- single-target finisher into a room hit, so the boon makes BISECT a crowd swing.
--
-- Economics. The two swings are not comparable per-hit, because BISECT HITS MULTIPLE AND
-- COMBINATION HITS ONE. Over a 4s window:
--     combination -> 2 swings, both on ONE mob
--     bisect      -> 1 empowered strike on the target, PLUS electric on EVERY denizen
-- So the trade is "twice the balance for room-wide coverage". At 1 denizen there is nothing
-- to splash to and the extra 2s buys nothing, which is the ONLY case the gate exists to
-- exclude. From 2 upward bisect is already covering ground combination cannot reach, and
-- the advantage widens with every additional mob -- and in the tower the objective is
-- CLEARING THE ROOM, not killing one thing fastest, which is exactly the situation spread
-- damage wins. Same shape as the Infernal Arc gate (4.75s vs ~2s dsl, also 2+).
--
-- `ataxiaBasher.bisectAt` tunes it UPWARD only -- the floor of 2 is enforced below.
-- (An earlier comment framed this as "gated on the balance cost, not on it being AoE".
-- That was backwards: it is gated on the AoE, and the balance cost only sets WHERE the
-- crossover falls. Corrected 2026-07-31 -- user's point that bisect hits multiple.)
--
-- It REPLACES the swing rather than riding alongside it: both spend balance.
--
-- STORMCLEAVER (v4.7.246) turns on the OTHER half of this ability. AB Bisect 3107:
--
--   ** If your target is an ADVENTURER and at 20% of their health or lower when the cutting
--      damage would be applied, they will be slain outright instead.
--
-- That clause was always present and always worthless while bashing -- this function used to
-- carry a note saying exactly that. The boon ("Your bisect attack now executes denizens with
-- less than 20% of their maximum health") drops the "adventurer" qualifier, so there is now a
-- single-target finisher worth 4s of balance: an EXECUTE is a guaranteed instant kill, which
-- beats two combinations that merely probably finish the job -- and in the tower, where
-- incoming damage is the real constraint, guaranteed-now beats probably-soon. It also denies
-- the self-healing denizens ("...ceases tending to his wounds") any chance to climb back out.
--
-- THE TWO BISECT BOONS PULL IN OPPOSITE DIRECTIONS and are independent of each other:
--   * Thunderclap  -> swing bisect at 2+ denizens (room-wide electric)
--   * Stormcleaver -> swing bisect at ONE denizen under the execute threshold
-- so the old `if not mnemThunderclap then return nil end` head-gate had to go: it would have
-- made Stormcleaver silently inert for anyone who held it without Thunderclap.
--
-- Notes from the AB entry that deliberately do NOT appear in this logic:
--   * It bypasses rebounding and reflections but leaves them intact, so it needs no raze
--     handling and gives none. The shielded branch is untouched: a shield must still be
--     broken first -- the execute does not change that, since a shield stops the strike
--     before any damage type is applied.
--   * `BISECT <target> [venom]` takes an optional venom; unused for bashing.
--
-- PREREQUISITE, deliberately unmanaged (user decision): bisect requires an edged runeblade
-- with the HUGALAZ rune sketched on the blade. Nothing in this package knows hugalaz -- the
-- sketch syntax for a BLADE rune was never captured, and inventing it would send garbage --
-- so keeping it on the weapon is the user's setup. If it ever lapses, bisect is refused
-- until re-sketched; capture that refusal line and this can back off on its own.
-- Denizen health for the Stormcleaver execute, as a percentage, or nil when we have no
-- reading. Fully guarded: `hpperc` is "-1" when the server has told us nothing, and the
-- denizen-state mirror can be nil or negative for the same reason.
--
-- NO READING MEANS NO EXECUTE -- the opposite default from the legend deck's
-- `targetNearlyDead`, which treats a missing reading as "never block". The asymmetry is
-- deliberate: there, a wrong guess withholds a card; here, it spends 4s of balance on a
-- finisher that will not finish anything.
local function bisectTargetHp()
	local ti = gmcp and gmcp.IRE and gmcp.IRE.Target and gmcp.IRE.Target.Info
	local hp = tonumber((tostring(ti and ti.hpperc or ""):gsub("%%", "")))
	if hp and hp > 0 then return hp end
	if ataxiaBasher_dsGet and type(target) == "number" then
		local ds = ataxiaBasher_dsGet(target)
		local dhp = ds and tonumber(ds.hpp)
		if dhp and dhp > 0 then return dhp end
	end
	return nil
end

function ataxiaBasher_rwBisect()
	if ataxiaBasher.shielded then return nil end -- break the shield first
	if type(target) ~= "number" then return nil end

	-- EXECUTE FIRST (Stormcleaver). A kill outranks any amount of spread damage, so this is
	-- checked before the crowd gate and is deliberately NOT crowd-gated itself: one denizen
	-- under the threshold is the entire case the boon exists for.
	--
	-- `<=` rather than `<`, though the boon says "less than 20%" while the AB says "at 20% of
	-- their health or lower". They are describing the same mechanic with different wording and
	-- we cannot tell which is exact -- but `hpperc` is LAST-PROMPT data on a mob we are
	-- actively hitting, so the real figure when the cutting damage lands is already lower than
	-- what we read. Firing at the boundary is therefore safe in the direction that matters,
	-- and the cost of being wrong is one bisect that deals damage instead of executing.
	if mnemStormcleaver then
		local hp = bisectTargetHp()
		if hp and hp <= (tonumber(ataxiaBasher.bisectExecuteAt) or 20) then
			return "bisect "..target
		end
	end

	if not mnemThunderclap then return nil end
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	-- FLOOR OF 2 IS A RULE, NOT A DEFAULT (user, 2026-07-31: "bisect should only be used if
	-- it is 2 denizens plus"). At a single denizen there is nothing for the third strike to
	-- splash to, so the extra 2s of balance buys literally nothing -- there is no
	-- configuration in which that is correct, so it is CLAMPED rather than merely defaulted.
	-- Same shape as `mnem swarm assess <n>`, which validates n >= 2 for the same reason.
	-- The execute above is exempt: it is a KILL, not splash damage, so the floor's reasoning
	-- ("nothing to splash to") simply does not apply to it.
	if n < math.max(2, tonumber(ataxiaBasher.bisectAt) or 2) then return nil end
	return "bisect "..target
end

function ataxiaBasher_runewardenBashing()
	local command, sp = "", ataxia.settings.separator
	local raze, bash, spec = "", "", ataxia.vitals.knight
	local brage = ataxiaBasher_rwBattlerage(sp)
	local braze = ataxiaBasher.battlerage.Runewarden.raze
	-- Lay the Hammer and Nail rune before swinging (free queue, so it costs no balance).
	local sowulu = ataxiaBasher_rwSowulu(sp)

	-- Falcon rake: free pet attack on a 30s cooldown (AB Rake 3264: "Works on/against:
	-- Denizens", "Every 30 seconds"). Mirrors the Infernal hyena maul; cooldown tracked in
	-- 005_Falcon_Cooldowns.lua and shortened by the Falconer's Tactics boon.
	local falcon = (ataxiaBasher.falconRakeReady and ("falcon rake "..target..sp)) or ""

	if spec == "Dual Cutting" then
		raze = "razeslash "..target
		bash = falcon.."dsl "..target
	elseif spec == "Two Handed" then
		raze = "battlefury focus speed"..sp.."carve "..target
		bash = "battlefury focus speed"..sp..falcon.."slaughter "..target
	elseif spec == "Dual Blunt" then
		raze = "fracture "..target
		bash = falcon.."doublewhirl "..target
	else
		raze = "combination "..target.." raze smash"
		bash = falcon.."combination "..target.." slice smash"
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = braze..sp..bash
		else
			command = raze..sp..brage
		end
	else
		-- Two crowd swaps can want this slot, and both spend BALANCE, so at most one lands.
		--
		-- BISECT (Thunderclap) WINS when it is available. It is an ordinary-cost swing that
		-- gains a third strike plus electric damage to every denizen in the room -- room-wide
		-- coverage for the price of the normal attack. ARC (Indiscriminate) buys the same
		-- coverage for 4.75s of balance, i.e. more than two normal swings. Given both boons,
		-- taking the cheap one is free money; arc is the answer only when Thunderclap is not
		-- held (or the target/spec puts bisect out of reach).
		--
		-- The falcon rake is folded into BOTH because it is a FREE pet order, not part of the
		-- balance swing -- dropping it with `bash` would quietly cost us a free hit.
		-- No separator argument: both are placed at the TAIL of the command, so unlike their
		-- sibling helpers they return a bare verb. Anything appended must add its own.
		local bisect = ataxiaBasher_rwBisect()
		local arc = ataxiaBasher_knightArc()
		local swing = bash
		if bisect then
			swing = falcon..bisect
		elseif arc ~= "" then
			swing = falcon..arc
		end
		command = sowulu..brage..sp..swing
	end

	return command
end

function ataxiaBasher_sentinelBashing()
   local command = ""
   if ataxiaBasher.shielded then
      command = command.."rivestrike "..target..ataxia.settings.separator
   end
   
   command = command..ataxiaBasher_assembleBattlerage()
      
   if not ataxiaBasher.shielded then 
      command = command.."thrust "..target
   end
 
   return command 
end

function ataxiaBasher_serpentBashing()
   local command = ""
	 local brage = ataxiaBasher_assembleBattlerage()

   if ataxiaBasher.shielded then
      command = command.."flay "..target.." shield"..ataxia.settings.separator
   end

   command = command..brage

   if not ataxiaBasher.shielded then
      command = command.."garrote "..target
   end

   return command
end

function ataxiaBasher_shamanBashing()	
local healhealth = tonumber(math.floor((ataxia.vitals.hp/ataxia.vitals.maxhp)*100))


	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Shaman.raze
  
  -- Default was "swiftcure" -- a typo. It never equalled the "swiftcurse" branch below, so the
  -- default bashType silently fell through to jinx/curse and swiftcurse was never actually the
  -- default. Set via `aconfig bashtype <type>` (shaman_system/005).
  if not shaman.spiritlore.bashType then shaman.spiritlore.bashType = "swiftcurse" end
	local bash_type = shaman.spiritlore.bashType

  local atk
  if healhealth < 60 then
    atk = "stand;wield shield;invoke regeneration"
  elseif bash_type == "arius" and shaman.spiritisbound("arius") then
    atk = "invoke roar "..target
  elseif bash_type == "swiftcurse" then
    -- No spirit-binding check: swiftcurse is used regardless of whether aelkesh is bound.
    --
    -- `curseCharge or 0`: it is a plain global with three writers -- shaman/011 (the real
    -- "You weave your fingers together..." line -> 14), shaman/012 (the authoritative "empowered
    -- with another N curses" -> N), and the ataxiaBasher_detectSwiftcurseCharge heuristic
    -- (genrunning/004). None run before the first charge of a session, so it is nil until then,
    -- and a bare `curseCharge <= 1` throws "attempt to compare nil with number", killing the
    -- whole attack. 004:61 already guards it the same way.
    if (curseCharge or 0) <= 1 then
      -- Recharge -- and only ONE at a time. `swiftcursing` is an in-flight guard: shaman/011
      -- ("You weave your fingers together...") and shaman/012 ("empowered with another N
      -- curses") both clear it, but NOTHING ever set it and nothing ever read it, so the guard
      -- was dead. The recharge therefore re-fired on the next prompt before the confirm-line
      -- landed -- weaving twice and paying a balance for each. Set it here (the missing half)
      -- and skip while a weave is outstanding.
      -- Paired with a TIMESTAMP so a swallowed/gagged confirm-line cannot strand the shaman
      -- unable to ever recharge again: after 3s we assume the weave was lost and retry.
      if swiftcursing and getEpoch() < (ataxiaTemp.swiftcurseSentAt or 0) + 3 then
        atk = "" -- weave already in flight; don't buy a second one
      else
        swiftcursing = true
        ataxiaTemp.swiftcurseSentAt = getEpoch()
        atk = "stand;wield shield;swiftcurse"
      end
    else
      atk = "stand;wield shield;swiftcurse "..target.." bleed"
    end
  else
    if ataxiaTemp.canJinx then
      atk = "jinx bleed bleed "..target
    else
      atk = "curse "..target.." bleed"
    end
  end
  
	
  -- atk is "" while a swiftcurse weave is in flight -- send the battlerage alone rather than
  -- `brage..sp..""`, which would trail a bare separator onto the queued command.
  if brage == "" or atk == "" then
  		command = (brage ~= "" and brage or atk)

  else
		command = brage..sp..atk
	end
	return command   
end



function ataxiaBasher_sylvanBashing()
   local command = ""
         
   command = command..ataxiaBasher_assembleBattlerage()
   command = command.."synchronise shear windwhip "..target

   return command 
end

function ataxiaBasher_wEleBashing()
   local command = ""   
   if ataxiaBasher.shielded then
      command = command.."manifest blade "..target..ataxia.settings.separator
   end
   
   command = command..ataxiaBasher_assembleBattlerage()
   
   if not ataxiaBasher.shielded then   
      command = command.."manifest blade "..target
   end
   
   return command   
end