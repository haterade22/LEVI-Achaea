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
	--
	-- Held as the VERB rather than the finished command since v4.7.273, because the infuse element
	-- is now woven INTO it (announcement #174) and that is not decided until the shin budget below.
	local slashVerb = bmShatteredStar and "multislash" or "drawslash"

	-- SHIN PHOENIX -- the emergency reset, and it outranks every other shin spender (v4.7.269).
	--
	-- AB 321: `SHIN PHOENIX`, self, requires 80 shin and CONSUMES ALL OF IT, "cleansed almost all
	-- ailments and afflictions" -- and, user-confirmed 2026-08-12, it also RETURNS US TO FULL
	-- HEALTH. The AB states only the cleanse, so the heal is knowledge its text does not carry and
	-- is the reason this is worth automating at all: a full reset for 80 shin is the strongest
	-- button in the kit, and it is what the infuse budget below exists to protect.
	--
	-- FIRST IN THE ROUND, deliberately. There is no round planner here -- shin priority is
	-- hardcoded position, and the augment used to win simply by being written first. Phoenix must
	-- outrank it: at 10% HP a 20% damage reduction is not the answer, and since Phoenix takes the
	-- whole pool it cannot share a round with anything.
	--
	-- `hpp > 0` IS NOT REDUNDANT. A zero reading means BLACKOUT -- vitals unknown, not nearly dead
	-- -- which ataxiaBasher_dangerLevel already encodes as `if hpp == 0 then return "wait" end`. A
	-- bare `hpp <= 10` would empty the shin pool every time we lose sight of our own health.
	--
	-- No cooldown stamp and no confirm line: consuming ALL shin means the `>= 80` gate is its own
	-- re-fire guard, and our own cast line is uncaptured (the only phoenix trigger in the tree,
	-- passive_active/010, is the OPPONENT-side line for an enemy Blademaster).
	if not shinSpent then
		local hpp = tonumber(ataxia.vitals and ataxia.vitals.hpp) or 0
		if hpp > 0 and hpp <= (tonumber(ataxiaBasher.phoenixAt) or 10)
			 and ataxiaBasher_shinNow() >= 80 then
			command = command.."shin phoenix"..sp
			shinSpent = true
			if ataxiaBasher_dsAlert then
				ataxiaBasher_dsAlert("<indian_red>" .. hpp .. "% HP<reset> -- <cyan>SHIN PHOENIX<reset>"
					.. " (full heal + cleanse, spends all shin).")
			end
		end
	end

	-- Bladed Reflexes boon (Mnemosyne): "You take 20% reduced damage while your reflexes are
	-- augmented with Shin energy via your Shindo augment ability." SHIN AUGMENT <ALL|amount>
	-- (AB 316) channels shin into the reflex augment, tracked as the `bodyaugment` defence.
	--
	-- THE MECHANIC, user-confirmed 2026-08-12 (none of it is in AB 316):
	--   * duration SCALES with the shin spent -- roughly 10 seconds at the bottom to ~1.5 minutes
	--     at the top -- but the CURVE IS UNKNOWN. It is explicitly NOT 1 shin = 1 second.
	--   * 4 SECONDS TO ACTIVATE, in all cases: a fixed overhead, not proportional to the spend.
	--   * when it ENDS it goes on COOLDOWN EQUAL TO THE DURATION IT WAS UP FOR.
	--
	-- The old default of 3 is wrong regardless of the curve -- it sits at or under the 10s floor,
	-- which is what the v4.7.126 log showed when `shin augment 1` visibly dissipated 12ms later.
	-- 20 is a provisional middle, NOT a computed optimum: choosing properly needs the curve, which
	-- is what `bash shinprobe` (basher/012) is for -- it records every (spend -> measured duration)
	-- pair from live play, the same way the rage probe measures a damage threshold.
	--
	-- What the mechanic already tells us without the curve: because the cooldown equals the
	-- duration, uptime can never exceed 50% however much is spent, and the 4s activation is a
	-- fixed tax that a SHORT augment pays proportionally more of. So the useful range is bounded at
	-- both ends, and the question the probe answers is where in it the shin is best spent.
	--
	-- THE COOLDOWN NEEDS NO CURVE. "Equal to the duration it was up for" is directly OBSERVABLE:
	-- watch the `bodyaugment` defence, time up -> down, and hold for exactly that long. That is
	-- what the block below does, and it is why this is correct today despite the unknown.
	--
	-- DELIBERATELY EXEMPT FROM THE SHIN FLOOR (user rule): this may spend below the 90 the infuse
	-- budget protects, and therefore below Phoenix's 80. That is the right trade -- 20% damage
	-- reduction held continuously beats banking a panic button we may never need -- and the
	-- ORDERING resolves the conflict on its own: Phoenix is evaluated above this block, so at 10%
	-- HP it claims the pool and the augment never runs. Only while healthy can the augment take us
	-- under Phoenix's floor, and while healthy is exactly when that does not matter.
	--
	-- Gated on the GMCP-tracked defence (expiry arrives via Char.Defences.Remove, no duration
	-- guessing) plus an attempt-hold so the channel wind-up isn't respammed every swing. The hold
	-- is 7s, not 5: a live capture recorded a ~6s re-augment lockout ("Regardless of your skill,
	-- augmenting yourself with shin energy so soon would be fatal") whose refusal line has no
	-- trigger, so a 5s hold walked into a rejection nothing could see. Flag mirrors
	-- bmShatteredStar (claim alias + BOONS row trigger 019, reset each run).
	-- `not shinSpent` and the APPEND are both new in v4.7.269, and both were latent traps rather
	-- than style: this block used to be the first thing in the round, so it needed neither. It had
	-- no shinSpent check because nothing could precede it, and it wrote `command = "shin augment "..`
	-- -- an ASSIGNMENT -- which silently DESTROYS anything already in the buffer. Putting Phoenix
	-- above it exposed both at once: the phoenix was built and then thrown away, and the round went
	-- out with the augment alone. A "one spender per round" rule enforced by position alone breaks
	-- the moment the positions change.
	-- Honour the COOLDOWN without knowing the duration curve. As of v4.7.271 the game tells us both
	-- edges -- `The shin energy enhancing your body dissipates.` starts it and `You may augment
	-- yourself with shin energy once again.` ends it (triggers highlighting/053-054) -- so this
	-- usually returns 0 and the derived wait is only the backstop for a missed line. It still feeds
	-- the probe, so every cycle we live through becomes a data point.
	local augCdUntil = ataxiaBasher_bmAugmentWatch and ataxiaBasher_bmAugmentWatch() or 0
	local nowAug = (getEpoch and getEpoch()) or os.time()

	if not shinSpent and bmBladedReflexes
		 and not (ataxia.defences and ataxia.defences.bodyaugment)
		 and nowAug >= augCdUntil -- the post-drop cooldown, MEASURED (see the watcher)
		 and not ataxiaTemp.bmAugmentAttempted then
		local shin = ataxiaBasher_shinNow()
		local amt = tonumber(ataxiaBasher.bmAugmentAmount) or 20
		if shin >= amt then
			ataxiaTemp.bmAugmentAttempted = true
			-- 7s covers the 4s activation with margin. It is only the ATTEMPT hold; the real
			-- post-drop wait is the measured cooldown above, which can be up to ~90s -- retrying
			-- every 7s through that would have been a rejected command a dozen times over.
			tempTimer(7, [[ataxiaTemp.bmAugmentAttempted = nil]])
			ataxiaTemp.bmAugmentSpent = amt -- what this cycle cost, for the probe
			command = command.."shin augment "..amt..sp
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

	-- THE SHIN BUDGET (v4.7.269, user rule: "only infuse if above 90 shin").
	--
	-- `infuse` was the ONLY shin spender in this function with no arithmetic behind it -- no cost
	-- check, no hold, no cooldown, no place in the one-spender rule -- and the only one that fired
	-- on EVERY round, which makes it plausibly the largest sustained draw in the whole economy.
	--
	-- 90 IS DERIVED, NOT ARBITRARY: Phoenix needs 80, so infusing only above 90 means that after
	-- paying for one infuse we still hold more than 80. An infuse can therefore never be the action
	-- that takes Phoenix off the table. Keep that relationship in mind before tuning either number.
	--
	-- The cost of an infuse is NOT verified. `.claude/classes/blademaster.md` states 5 shin with no
	-- AB capture behind it, and the only code that enforces the arithmetic is the PvP airfist gate
	-- (25 = 20 + 5) as an opaque total. 90 clears 80 with headroom whether the real figure is 5 or
	-- 10, which is why this is a tunable with its derivation written down rather than 80 + a
	-- constant we would be inventing.
	--
	-- TOWER-SCOPED, matching the "while wading" framing: outside Mnemosyne nothing is being saved
	-- for, so general bashing keeps infusing every round and the blast radius stays in the tower.
	--
	-- The gate lives HERE rather than inside ataxiaBasher_bmInfuse on purpose: that function is a
	-- pure element-chooser with its own suite, and giving it a shin/area dependency would force
	-- every one of those tests to mock both.
	local infuse, infuseEl = "", nil
	if not ataxiaBasher.inMnemosyne or ataxiaBasher_shinNow() > (tonumber(ataxiaBasher.bmInfuseAt) or 90) then
		infuseEl = ataxiaBasher_bmInfuse()
	elseif ataxia.mnemosyne and ataxia.mnemosyne.damageNulled
		 and ataxia.mnemosyne.damageNulled("cutting") and not ataxiaTemp.bmCuttingWarned then
		-- SAY IT OUT LOUD, once per ripple. Our base bashing damage IS physical cutting, so under a
		-- ripple that suppresses it the infuse stops being a bonus and becomes the only real damage
		-- we have -- and the user's rule is that the floor holds anyway, so we are knowingly
		-- swinging into a resistance to keep Phoenix available. A deliberate trade the log never
		-- mentions is indistinguishable from a bug, and this is the one place to mention it.
		ataxiaTemp.bmCuttingWarned = true
		if ataxiaBasher_dsAlert then
			ataxiaBasher_dsAlert("<indian_red>cutting damage is suppressed this ripple<reset> and shin is"
				.. " below " .. (tonumber(ataxiaBasher.bmInfuseAt) or 90) .. " -- holding it for PHOENIX."
				.. " <a_darkmagenta>infuse manually if you would rather have the damage.")
		end
	end

	-- INLINE INFUSE (announcement #174, 2026-08-17):
	--
	--   "You can now include INFUSEELEMENT in inline blademaster attacks. For example,
	--    COMPASSSLASH MAKARIOS NORTH INFUSEFIRE STERNUM. You must specify infuse<element> rather
	--    than just element name -- this is to avoid various permutations of the syntax that might
	--    clash with serverside targeting against elemental based denizens otherwise."
	--
	-- WHY THIS IS WORTH TAKING, and it is not tidiness. `infuse` is a SEPARATE command in a chain
	-- that `queue addclearfull` rebuilds every prompt, and this package has already learned twice
	-- what that costs: a command in the round that does not wait on balance executes on EVERY
	-- re-queue rather than once per swing (v4.7.270 -- `shin augment` observed refused five times
	-- in 0.45s for exactly that reason). Woven into the attack, the infuse can only happen when the
	-- attack does -- once per balance, by construction.
	--
	-- TOKEN ORDER IS INFERRED FROM THE ONE EXAMPLE: attack, target, [direction], infuse<element>,
	-- body part. Our verbs take no direction, so `drawslash <t> infuselightning sternum`. That is a
	-- single data point and the announcement states no grammar -- see v4.7.272, one example is not
	-- a sample.
	--
	-- AND THE FAILURE MODE IS WORSE THAN THE OLD FORM'S, which is why the toggle exists: a
	-- malformed `infuse X` costs the infuse and the swing still lands, while a malformed inline
	-- attack is rejected WHOLE and the swing is lost. `bash inlineinfuse off` restores the
	-- two-command form.
	local slash
	if infuseEl and ataxiaBasher.bmInlineInfuse ~= false then
		slash = slashVerb.." "..target.." infuse"..infuseEl.." sternum"
	else
		slash = slashVerb.." "..target.." sternum"
		if infuseEl then infuse = "infuse "..infuseEl.." "..sp.." " end
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = command..raze..sp..infuse..slash
		else
			command = command.."raze "..target..sp..brage
		end
	else
		command = command..storm..brage..sp..infuse..slash
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

-- CURRENT SHIN, one accessor (v4.7.269). This two-line expression was copy-pasted verbatim at
-- three call sites (the augment block, thunderstorm, blizzard) and the shin budget below would have
-- made it four.
--
-- The `ataxia.vitals.class` fallback those copies carried is DEAD and is deliberately not
-- reproduced: `blademaster.getShin()` is declared unconditionally regardless of class and returns
-- `0` rather than nil when the charstat is missing -- and `0` is truthy in Lua, so the `or` branch
-- could never run. That matters because it hides the failure mode: if Achaea ever rewords the
-- `Shin:` charstat, shin reads 0, the augment and both storms gate themselves off, and (before this
-- version) `infuse` carried on firing unpriced. One accessor makes that one place to fix.
--
-- Never nil, so callers may compare directly.
function ataxiaBasher_shinNow()
  if blademaster and blademaster.getShin then
    return tonumber(blademaster.getShin()) or 0
  end
  return 0
end

-- Preference order, tunable via ataxiaBasher.bmInfusePrefs.
--
-- LIGHTNING FIRST (v4.7.269, user-directed). The old order led with `fire`, and that was never a
-- damage judgement: v4.7.186 introduced this function to replace a hardcoded `infuse fire` and put
-- fire first purely so an unaffected ripple behaved exactly as before. That caution has outlived
-- its purpose -- and the class's own PvP offense has always disagreed with it, since
-- levi_scripts/blademaster/003_BrokenStar.lua infuses LIGHTNING in every branch. The PvE basher
-- was the odd one out.
local BM_INFUSE_ORDER = { "lightning", "fire", "ice", "void" }

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
  -- `first` covers any usable list, so the literal is only reached when bmInfusePrefs is garbage
  -- (no recognised element at all). Match the head of BM_INFUSE_ORDER so the last resort agrees
  -- with the module's own first choice.
  return first or "lightning"
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

-- TIMEQUAKE (Mnemosyne boon, v4.7.264): "Your aeonics distortion ability now deals magic damage
-- to all denizens when distorting a location." User-directed: at 2+ denizens, ON ENTRANCE, once.
--
-- AB Distortion (2426): `CHRONO DISTORTION [BOOST]`, works on "Adventurers and room", costs
-- **300 AGE**. Read the Syntax line, not just the boon text -- three facts follow from it:
--
--   * NOT BOOSTED, deliberately. Boost removes the EQUILIBRIUM cost, and equilibrium is the one
--     resource we do not need to save: an eq ability RIDES beside the balance swing, so the cost
--     is already free. What boost trades it for is the AB's warning that the spell becomes
--     "progressively less potent the older you grow" -- an unquantified penalty for a cost we are
--     not paying. Plain distortion, every time.
--   * AGE-CAPPED on the SAME key as chrono blur (`ataxiaBasher.dwAgeCap`, 400). Age is the class's
--     PvP currency and 300 is a large spend; bashing must not price out the chrono kit. Whether
--     the 300 is added to the age counter or drawn from it is NOT confirmed, so the cap is applied
--     to the current reading exactly as `dwFlashforward` does -- consistent, and conservative in
--     the direction that costs us damage rather than the kit.
--   * ONCE PER ROOM (the sowulu/uruz guard). Distortion is a persistent room effect, so re-casting
--     it in a room that already has ours spends 300 age for nothing.
--
-- Worth knowing and NOT relied upon: distortion stops *enemies* leaving, not us, so it cannot
-- strand the escape ladder -- and it should incidentally hold a fleeing boss (Lyaeus) in the room.
-- Neither is asserted anywhere, because neither has been observed.
function ataxiaBasher_dwTimequake(sp)
	if not dwTimequake then return "" end
	if ataxiaBasher.shielded then return "" end -- break the shield first; the nuke keeps
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	if n < (tonumber(ataxiaBasher.distortionAt) or 2) then return "" end
	local dw = ataxiaTables and ataxiaTables.depthswalker
	local age = tonumber(dw and dw.age) or 0
	if age > (tonumber(ataxiaBasher.dwAgeCap) or 400) then return "" end
	ataxiaTemp = ataxiaTemp or {}
	local nowT = (getEpoch and getEpoch()) or os.time()
	-- THE GAME'S REFUSAL IS THE GROUND TRUTH, NOT OUR ROOM KEY (captured live 2026-08-12).
	-- `You have already distorted time in this location.` arrived TWICE in the user's log, which
	-- is what a room-keyed guard looks like when the key is a lie -- and in the tower it often is,
	-- because dementia mints a new room id on every look. Same lesson as the legend deck, where
	-- the game's "lacks the power to invoke" rejection outranks ldm's own charge count. A global
	-- hold after a refusal covers the case the per-room guard cannot see.
	if (nowT - (tonumber(ataxiaTemp.dwDistortRefusedAt) or 0)) < 20 then return "" end
	local room = (gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.num) or "unknown"
	if ataxiaTemp.dwDistortRoom == room then return "" end
	-- Stamped OPTIMISTICALLY at send: an unconfirmed cast must not re-fire every prompt at 300
	-- age a go. The confirmation line re-stamps it and the refusal line hard-stops it, so both
	-- outcomes converge on "do not cast here again".
	ataxiaTemp.dwDistortRoom = room
	return "chrono distortion"..sp
end

-- Both outcomes of a distortion mean the same thing operationally: THIS LOCATION IS DISTORTED,
-- do not spend 300 age on it again. Called from the confirmation line and the refusal line
-- (triggers mnemosyne/073 and 074). The refusal additionally arms a global hold, because it is
-- the only evidence available when our room key is wrong.
function ataxiaBasher_dwDistortMark(refused)
	ataxiaTemp = ataxiaTemp or {}
	ataxiaTemp.dwDistortRoom = (gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.num) or "unknown"
	if refused then
		ataxiaTemp.dwDistortRefusedAt = (getEpoch and getEpoch()) or os.time()
	end
end

-- ---------------------------------------------------------------------------
-- Dragon SCORCH -- react to a denizen healing itself (v4.7.266)
-- ---------------------------------------------------------------------------
--
-- `Swallowing the morsel, a monstrous hellhound crouches low, seeming invigorated.` -- the mob
-- ate someone and healed. SCORCH (AB 2299: 18 rage, 25.00s cooldown, denizens only) applies
-- INHIBIT, which slows exactly that healing, so the heal line is the cue.
--
-- REACTIVE, so it is SENT DIRECTLY rather than queued. The standing rule -- anything queued that
-- is not an attack must hold the dispatcher, because every attack sends `queue addclearfull` --
-- exists because a QUEUED command can be wiped before it fires. A direct send executes now, which
-- is what a counter to a heal that already happened wants, and battlerage carries no balance cost
-- to wait for.
--
-- It still has to respect the rotation's economy, or the next assembled round queues a second
-- battlerage and one of the two is rejected: it honours `brGlobalReadyAt` and calls
-- `ataxiaBasher_brSent()` on the way out, exactly as every rotation pick does.
--
-- WHY THE TARGET IS RESOLVED RATHER THAN ASSUMED: the hellhound in the capture lunged at a PARTY
-- MEMBER, not at us, so the healer is very often NOT our current target -- which is the whole
-- reason this cannot simply ride the attack round. Prefer the numeric id from the denizen model
-- (unambiguous, and what the package targets with everywhere else) and fall back to the last word
-- of the captured name, which is the keyword form a player would type.
--
-- Colour: gated on class Dragon rather than RED specifically. The AB records no colour
-- restriction, and gating on an unconfirmed one would silently disable the feature for whoever
-- the restriction does not apply to -- the failure direction that hides itself.
function ataxiaBasher_dragonScorch(name)
	if not (ataxiaBasher and ataxiaBasher.enabled) or ataxiaBasher.paused then return false end
	if ataxiaBasher.scorchAuto == false then return false end
	local class = string.lower((gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class) or "")
	if not class:find("dragon", 1, true) then return false end

	local nowT = (getEpoch and getEpoch()) or os.time()
	ataxiaTemp = ataxiaTemp or {}
	if nowT < (tonumber(ataxiaTemp.brGlobalReadyAt) or 0) then return false end
	if (nowT - (tonumber(ataxiaTemp.scorchAt) or 0)) < 25 then return false end -- AB cooldown
	if not ataxiaBasher_rageAfford(tonumber(ataxia.vitals.rage) or 0, 18) then return false end

	-- Resolve the healer. It is usually not `target` -- see above.
	local id
	if ataxiaBasher_dsResolveNameToId then
		id = ataxiaBasher_dsResolveNameToId(name, ataxia.denizensHere, nil, nowT)
	end
	-- Already inhibited: the heal is already slowed, and a second scorch is 18 rage for nothing.
	if id and ataxiaBasher_dsHasAff and ataxiaBasher_dsHasAff(id, "inhibit", nowT) then return false end

	local ref = id or (type(name) == "string" and name:match("(%a+)%s*$"))
	if not ref then return false end

	ataxiaTemp.scorchAt = nowT
	send("scorch " .. ref, false)
	ataxiaBasher_brSent() -- arm the shared ~1s global BR cooldown, as every rotation pick does
	if ataxiaBasher_dsAlert then
		ataxiaBasher_dsAlert("<gold>" .. tostring(name) .. "<reset> healed itself -- <cyan>SCORCH<reset>.")
	end
	return true
end

-- ---------------------------------------------------------------------------
-- Aeonic cash-in: DEGENERATE / DETERIORATE (v4.7.265)
-- ---------------------------------------------------------------------------
--
-- These are NOT boon-gated (user-directed). The base abilities already deal "significant magical
-- damage" to a denizen carrying the right affliction; Herald of Infirmity only adds 25% on top.
--
-- AB 2423 CHRONO DEGENERATE <target>, 700 age -- fires on a PHYSICALLY-PLAGUED denizen:
--     inhibit, weakness, sensitivity, clumsiness
-- AB 2425 CHRONO DETERIORATE <target>, 300 age -- fires on a MIND-ADDLED denizen:
--     recklessness, charm, fear, aeon, amnesia
--
-- All nine are already modelled by basher/008 (`ataxiaBasher_BR_AFFS`), which is the whole
-- reason this is cheap to build: the denizen-state layer was written for exactly this shape of
-- question and `dwHasAff` already asks it. Note the two naming mismatches between the AB prose
-- and the tracked keys -- "clumsiness" is `clumsy`, "fear" is `feared`.
--
-- THE LOOP IS SELF-FEEDING, which is the point. Depthswalker's own battlerage applies two of the
-- five mental triggers: `chrono curse` -> AEON (DW_BR, `skipIfAff = "aeon"`) and `intone boinad`
-- -> CHARM. So the rotation plants the affliction and this cashes it in a round or two later --
-- the same shape as the Blademaster cashing reckless/feared denizens into Headstrike.
--
-- NEVER BOOSTED. Both ABs say so explicitly for the denizen case ("cannot be boosted"), so the
-- BOOST suffix is not merely unhelpful here, it is invalid.
--
-- IT REPLACES THE SWING rather than riding beside it. The balance type is NOT stated in either AB
-- -- unlike distortion, whose AB names an eq cost by saying boost removes it -- so this is a
-- judgement made in the safe direction. If these are balance abilities and we appended them, the
-- swing would be REJECTED after the chain had already spent the age; if they are equilibrium and
-- we replace, we lose one `shadow reap` per cash-in, which "significant magical damage" should
-- comfortably beat. Losing a swing is recoverable, spending 300-700 age on a rejected command is
-- not. Correct this the moment the resource is confirmed.
--
-- DETERIORATE IS PREFERRED WHEN BOTH ARE AVAILABLE: 300 age against 700 for the same stated
-- effect. Age is the class's PvP currency, and the cap below is shared with chrono blur so
-- bashing cannot price out the chrono kit.
--
-- AMNESIA IS SORTED LAST, deliberately. `chrono erasure` (DW_BR) CONSUMES weakness or amnesia,
-- so the two cash-ins compete for the same affliction; preferring any other trigger first means
-- the rotation and this rarely fight over one. Same reason weakness is last in the physical set.
local DW_DETERIORATE_AFFS = { "aeon", "charm", "feared", "recklessness", "amnesia" }
local DW_DEGENERATE_AFFS  = { "inhibit", "sensitivity", "clumsy", "weakness" }

-- Which cash-in is live, or nil. Returns command, the affliction that enabled it, and the age
-- cost -- named rather than inlined so `bash dwaeonic` and the tests can report WHY.
function ataxiaBasher_dwAeonicPick()
  if type(target) ~= "number" then return nil end -- PvE only; these read the denizen model
  for _, aff in ipairs(DW_DETERIORATE_AFFS) do
    if dwHasAff(aff) then return "chrono deteriorate "..target, aff, 300 end
  end
  for _, aff in ipairs(DW_DEGENERATE_AFFS) do
    if dwHasAff(aff) then return "chrono degenerate "..target, aff, 700 end
  end
  return nil
end

function ataxiaBasher_dwAeonicCashIn()
  if ataxiaBasher.dwAeonic == false then return "" end
  if ataxiaBasher.shielded then return "" end -- break the shield first; the affliction keeps
  local dw = ataxiaTables and ataxiaTables.depthswalker
  local age = tonumber(dw and dw.age) or 0
  if age > (tonumber(ataxiaBasher.dwAgeCap) or 400) then return "" end
  local cmd, aff = ataxiaBasher_dwAeonicPick()
  if not cmd then return "" end
  -- IN-FLIGHT REPLAY, NOT A HOLD (corrected v4.7.267 from a live log).
  --
  -- v4.7.265 shipped a 4s hold here, reasoning that re-sending every 0.3s would waste the
  -- affliction. That is the exact opposite of what this round needs, and the log shows it: the
  -- echo fired twice while almost nothing landed. The basher rebuilds the round every prompt and
  -- every rebuild sends `queue addclearfull`, which WIPES the line queued 0.3s earlier -- so a
  -- hold means the very next rebuild replaces our queued `chrono deteriorate` with a plain swing
  -- before balance ever comes up. The command is only sent once and then deleted.
  --
  -- The owned battlerage rotations solved this years ago (`dwBrPending`, v4.7.129): hold the PICK
  -- and re-emit the SAME command verbatim on every rebuild until it fires, so each addclearfull
  -- re-queues it rather than dropping it. Byte-stable on purpose -- a command that changes between
  -- rebuilds is a command that never survives one.
  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp = ataxiaTemp or {}
  local pend = ataxiaTemp.dwAeonicPending
  if pend and pend.cmd and (nowT - (tonumber(pend.at) or 0)) < 3 then return pend.cmd end
  ataxiaTemp.dwAeonicPending = nil
  ataxiaTemp.dwAeonicPending = { cmd = cmd, aff = aff, at = nowT }
  -- Announced once per PICK, not per rebuild: the replay above returns before reaching this.
  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert("aeonic cash-in on <cyan>" .. aff .. "<reset>"
      .. (dwHeraldInfirmity and " <pale_green>(+25% Herald)<reset>" or "") .. ".")
  end
  return cmd
end

-- Fire-line confirmation, the dwConfirm shape: the cast landed, so release the replay instead of
-- re-queueing it for the rest of the 3s window. Captured live 2026-08-12:
--   `Time wreaks ruin upon <target>, deteriorating before your eyes.`
-- It repeats as the effect ticks; the first one is the confirmation and the rest are no-ops.
function ataxiaBasher_dwAeonicConfirm()
  ataxiaTemp = ataxiaTemp or {}
  local pend = ataxiaTemp.dwAeonicPending
  ataxiaTemp.dwAeonicPending = nil
  -- SPEND THE AFFLICTION IN OUR MODEL. Without this the replay releases, the next rebuild sees
  -- the same affliction still recorded, and cashes in AGAIN -- 300-700 age every round for as
  -- long as it lasts. Amnesia runs 30s, so that is up to five casts on one application.
  --
  -- Clearing it is also the honest reading of the AB: the ability "drastically accelerates the
  -- effects of said afflictions", which is a consumption. If it turns out not to consume, the
  -- cost of being wrong is that we may re-apply an affliction the denizen still has -- cheap,
  -- and self-correcting the moment the rotation's own tracking updates. The cost of the other
  -- error is hundreds of age a round.
  if pend and pend.aff and type(target) == "number" and ataxiaBasher_dsClearAff then
    ataxiaBasher_dsClearAff(target, pend.aff)
  end
end

function ataxiaBasher_depthswalkerBashing()
	local command, sp = "", ataxia.settings.separator
	-- Equilibrium rider: rides every round, shielded or not (see above).
	local ff = ataxiaBasher_dwFlashforward(sp)
	-- ONE EQUILIBRIUM SPENDER PER ASSEMBLED ROUND (the v4.7.193 rule). `queue addclearfull a;b;c`
	-- is ONE entry -- every command runs back to back in the same instant -- so chrono blur and
	-- chrono distortion would both pass their own "do I have eq?" gate, only the first could pay,
	-- and the second would be REJECTED after already stamping its once-per-room guard. The blur
	-- keeper wins the tie because it only fires when a defence has actually dropped and holds 8s
	-- between attempts; distortion is once per room and can wait a round.
	local tq = (ff == "") and ataxiaBasher_dwTimequake(sp) or ""
	ff = ff .. tq
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
	local br = ataxiaBasher_dwBattlerage(sp, keeper ~= "")
	-- THE CASH-IN REPLACES THE SWING (see the block above for why that direction). The battlerage
	-- still rides -- it is paid in rage, not balance -- and it is what plants the affliction in
	-- the first place, so cutting it here would starve the very loop this feeds.
	-- It occupies the PRIMARY slot, so it carries no trailing separator (as  does not).
	-- v4.7.265 appended one and stripped it with gsub("%s*$") -- which strips WHITESPACE and the
	-- separator is ";", so the round went out with a trailing empty command.
	local aeonic = ataxiaBasher_dwAeonicCashIn()
	if aeonic ~= "" then
		return ff..keeper..br..aeonic
	end
	command = ff..keeper..br..primary
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
-- backs that up.
--
-- NOT INFERNAL-ONLY (v4.7.285). Fury is a RUNEWARDEN ability too -- the SnB combos in
-- `aliases/.../snb/003` and `snb/004` have sent `fury on` beside `falcon slay` for as long as
-- they have existed, and a falcon is a Runewarden's bird. This helper was reachable only from
-- `ataxiaBasher_infernalBashing`, so a Runewarden holding the boon got nothing: the same
-- one-class-at-a-time gap as Arc (v4.7.244) and the falcon/hyena redeploy (v4.7.284). It is
-- now called from the Runewarden round as well.
--
-- The `inf` PREFIX ON EVERY NAME IS KEPT DELIBERATELY (`infFuryOfAges`, `infFuryOn`,
-- `infFuryAt`, `infFuryOnAt`, `infFuryOffAt`) -- exactly the call made for `infIndiscriminate`
-- in v4.7.244. The boon flag is reset in three separate places, and a rename that missed one
-- would leave fury armed outside the tower, quadrupling endurance costs on a normal grind.
--
-- STATE IS NOW CONFIRMED, NOT OPTIMISTIC (v4.7.285). The note here used to say "no fury on/off
-- game line has been captured yet -- if one shows up, confirm from it instead." Two showed up:
--
--     Your eyes rage with fury.        -> it went up          (highlighting/055)
--     You're already raged with fury!  -> it was ALREADY up   (highlighting/056)
--
-- Both mean the same thing for our purposes, which is why one handler takes both: the refusal
-- is not a failure, it is the game telling us the state we wanted is the state we have. Only
-- the ON edge is confirmed -- no fury-OFF line has been seen, so `fury off` stays optimistic.
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

-- FURY IS UP, from the game rather than from our own send (v4.7.285, triggers
-- highlighting/055-056). `Your eyes rage with fury.` and `You're already raged with fury!` both
-- resolve to the same fact, so both land here -- the second is a refusal only in wording.
--
-- It also stamps `infFuryAt`, which is the 30s anti-flap floor: a confirmation arriving from
-- the wade-entry check must not be followed a second later by the EP keeper deciding to toggle.
function ataxiaBasher_furyConfirmed()
	ataxiaTemp = ataxiaTemp or {}
	local wasOn = ataxiaTemp.infFuryOn
	ataxiaTemp.infFuryOn = true
	ataxiaTemp.infFuryAt = (getEpoch and getEpoch()) or os.time()
	return wasOn and "already" or "raised"
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

-- ELUSIVE FOOLERY (Mnemosyne boon, v4.7.258): "While slippery, your dexterity is increased by
-- 2, the defence allows you to shrug off webs, ropes, and other entanglements, but your
-- constitution is reduced by 1."
--
-- Everything it gives is conditional on the SLIPPERY defence being up, so the whole handling is
-- "keep slippery raised" -- the same defence-keeper shape as infDeathaura / senselessFlurryNumb
-- / dwFlashforward: defence-gated on the GMCP read, attempt-held so an unconfirmed raise cannot
-- cost every round, and prefixed to the round rather than replacing anything.
--
-- `slippery` is a KNOWN Jester defence in this package (the defences map and classDefences both
-- carry it), so neither the name nor the raising command is invented.
--
-- The -1 constitution is accepted rather than managed: it is the price of the boon and there is
-- nothing to decide about it. Shrugging off entanglements is worth having in the tower on its
-- own -- webs and ropes are exactly what strands an escape.
function ataxiaBasher_jesterSlippery(sp)
	if not mnemElusiveFoolery then return "" end
	if ataxia.defences and ataxia.defences.slippery then return "" end
	local nowT = (getEpoch and getEpoch()) or os.time()
	ataxiaTemp = ataxiaTemp or {}
	if (nowT - (tonumber(ataxiaTemp.jesterSlipperyAt) or 0)) < 10 then return "" end
	ataxiaTemp.jesterSlipperyAt = nowT
	return "slippery"..sp
end

-- Is it safe to BADJOKE right now? Only interesting while TOUGH CROWD is held, because that is
-- the boon that turns our own joke into a self-affliction.
--
-- "Telling a bad joke will cause psychic damage to all denizens present, but your comedic flair
-- is so horrific that doing so will cause you to become STUPID AND STUNNED."
--
-- Stun blocks every action outright, and stupidity is the affliction this codebase already
-- documents as EATING QUEUED COMMANDS (the Pinnacle death, v4.7.116). So each use buys AoE
-- damage at the price of a window in which we cannot act or reliably queue -- which is fine in
-- a fight we are winning and lethal in one we are leaving. Every escape this session has been
-- lost to something that stopped us moving; deliberately stunning ourselves mid-retreat would
-- be doing it on purpose.
function ataxiaBasher_jesterJokeSafe()
	if not mnemToughCrowd then return true end -- no self-affliction: nothing to weigh
	if ataxiaTemp and ataxiaTemp.escapeMode then return false end
	local M = ataxia.mnemosyne
	if M and M.roomLava and M.roomLava() then return false end
	if M and M.swarm and M.swarm.state == "recovering" then return false end
	if ataxia.afflictions and (ataxia.afflictions.stun or ataxia.afflictions.paralysis) then
		return false -- already unable to act; a second stun only extends it
	end
	-- Defaulted, not conditional (the v4.7.255 rule): a guard that evaporates because a config
	-- key is missing would stun us at crash HP on a fresh profile.
	local s = M and M._cfg and M._cfg()
	local esc = (s and s.swarm and tonumber(s.swarm.escapeAt)) or 35
	local hp = tonumber(ataxia.vitals and ataxia.vitals.hpp)
	if hp and hp <= esc then return false end
	return true
end

-- BADJOKE. Base ability (AB 681): syntax `BADJOKE`, works on "Adventurers, denizens, and room",
-- 3.00s of EQUILIBRIUM, 100 mana, and it strips the rebounding aura and shield defences from
-- everyone who hears it.
--
-- SYNTAX CORRECTION (v4.7.258): this was sent as `badjoke <target>`. The ability takes NO
-- target -- it is a room effect -- so every shield-break the Jester basher has ever thrown was
-- a malformed command. Nothing surfaced it because a rejected command is silent here.
--
-- TOUGH CROWD adds psychic damage to all denizens, which makes it worth throwing on an
-- UNSHIELDED round too. It costs equilibrium, so it rides free beside the balance swing (the
-- standing resource rule) -- but the boon's self-stun means the limit is not equilibrium, it is
-- how often we can afford to be unable to act. Hence a cooldown far longer than the 3s eq, a
-- crowd gate (it is AoE), a mana floor (100 a throw, and mana is one-way under Corrupted
-- Breath), and jesterJokeSafe above.
function ataxiaBasher_jesterBadjoke(sp, shielded)
	if not ataxiaBasher_jesterJokeSafe() then return "" end
	-- 100 mana a throw. Keep headroom rather than bottoming out the pool: running out of mana
	-- is a kill condition, and with a manaleech boon it does not come back.
	local mp = tonumber(ataxia.vitals and ataxia.vitals.mp) or 0
	if mp < (tonumber(ataxiaBasher.jesterJokeMana) or 300) then return "" end
	if shielded then return "badjoke"..sp end -- the shield strip: no boon or crowd needed
	if not mnemToughCrowd then return "" end
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	if n < (tonumber(ataxiaBasher.jesterJokeAt) or 2) then return "" end
	local nowT = (getEpoch and getEpoch()) or os.time()
	ataxiaTemp = ataxiaTemp or {}
	if (nowT - (tonumber(ataxiaTemp.jesterJokeAt) or 0)) < (tonumber(ataxiaBasher.jesterJokeCd) or 12) then
		return ""
	end
	ataxiaTemp.jesterJokeAt = nowT
	return "badjoke"..sp
end

-- APOSTATIC (Mnemosyne boon): "Your priestess tarot now deals magic damage to denizens instead
-- of healing them." So a card that was actively counterproductive while bashing becomes damage.
--
-- The FLING syntax is not invented: `fling fool at me` is already sent by this package's
-- lock-breakers (can(x)/003_Lock_breakers), so `fling <card> at <target>` is the confirmed form.
--
-- TWO THINGS ARE GENUINELY UNKNOWN and the defaults are conservative because of it:
--   * which balance a fling spends (equilibrium is likely, but unconfirmed), so this is
--     appended rather than allowed to replace the swing -- if it turns out to take BALANCE it
--     costs a round rather than silently eating the attack;
--   * whether it consumes an INSCRIBED CARD. Tarot cards are stock a Jester has to inscribe,
--     so a fling every round could quietly empty the deck. The cooldown is therefore generous
--     (`ataxiaBasher.jesterPriestessCd`, default 20s) rather than tuned.
-- Capture the AB entry and both can be tightened; until then the failure mode is "we throw it
-- less often than we could", which costs damage rather than resources we cannot replace.
function ataxiaBasher_jesterPriestess(sp)
	if not mnemApostatic then return "" end
	if type(target) ~= "number" then return "" end
	if ataxiaBasher.shielded then return "" end -- break the shield first
	local nowT = (getEpoch and getEpoch()) or os.time()
	ataxiaTemp = ataxiaTemp or {}
	if (nowT - (tonumber(ataxiaTemp.jesterPriestessAt) or 0)) < (tonumber(ataxiaBasher.jesterPriestessCd) or 20) then
		return ""
	end
	ataxiaTemp.jesterPriestessAt = nowT
	return "fling priestess at "..target..sp
end

function ataxiaBasher_jesterBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Jester.raze
	local wield = "wield blackjack;wield shield"..sp
	local rawhp = (gmcp.IRE.Target.Info.hpperc or "100"):gsub("%%", "")
	local mobhp = tonumber(rawhp) or 100
	-- GALLOWSHUMOUR vs BOP (AB 2680, confirmed 2026-08-11). Against a denizen gallowshumour
	-- needs no puppet, deals PSYCHIC damage off the better of intellect or strength, and
	-- "the closer they are to death, the sharper your wit cuts": increased damage under 50%
	-- health, and increased FURTHER under 25%. So the existing 50% switch is exactly the
	-- documented breakpoint, and the second tier needs no code -- it is the same command,
	-- simply worth more as the target drops. 2.10s of balance, and it takes a TARGET (unlike
	-- badjoke, which does not).
	local attack = (mobhp < 50) and "gallowshumour " or "bop "
	-- Keep SLIPPERY up (Elusive Foolery) ahead of everything: it is a defence, not a swing.
	local slip = ataxiaBasher_jesterSlippery(sp)

	if ataxiaBasher.shielded then
		local joke = ataxiaBasher_jesterBadjoke(sp, true)
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = slip..wield..raze..sp..attack..target
		elseif joke ~= "" then
			command = slip..wield..joke..brage
		else
			-- Tough Crowd made the joke unsafe (or mana is short): fall back to the rage raze
			-- rather than standing there shielded. Better a spent battlerage than a stun at
			-- crash HP or a round that does nothing.
			command = slip..wield..raze..sp..brage
		end
	else
		-- Both riders spend something other than the balance swing, so they ride beside it.
		local joke = ataxiaBasher_jesterBadjoke(sp, false)
		local card = ataxiaBasher_jesterPriestess(sp)
		command = slip..wield..joke..card..brage..sp..attack..target
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
	local shin = ataxiaBasher_shinNow()
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

	local shin = ataxiaBasher_shinNow()
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

-- The focused target's health as a percentage, or nil when we genuinely cannot read it.
--
-- Hoisted to a named global (v4.7.292) because a SECOND class helper now needs it: it lived as a
-- file-local `bisectTargetHp` defined ~650 lines below, which Lua would not let anything above it
-- call. `bisectTargetHp` is kept as a thin wrapper so the Runewarden call sites and their tests are
-- untouched.
--
-- `gmcp.IRE.Target.Info.hpperc` first (live, server-fed, needs the IRE.Target module negotiated and
-- a server target set -- see `ataxiaBasher_setServerTarget`), then our own denizen-state model.
-- Returns NIL rather than a guess: every caller has to decide for itself what an unreadable target
-- means, and the two current callers answer differently on purpose.
function ataxiaBasher_targetHpPct()
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

-- ---------------------------------------------------------------------------
-- SPIRIT REND (Mnemosyne boon, v4.7.292, user-directed)
-- ---------------------------------------------------------------------------
--
--   "Your kaido enfeeble ability costs no kai and can target denizens, halving the target's
--    current health. You can only use this ability against denizens every 60 seconds."
--
-- AB Enfeeble (Kaido, ID 901): `KAI ENFEEBLE <target>`, **3.00 seconds of EQUILIBRIUM**, 61 kai.
--
-- The boon rewrites three of those facts and each one shapes the code:
--   * "costs no kai"      -> NO kai gate. The AB's 61 is what the boon removes.
--   * "can target denizens" -> the AB says "Works on/against: Adventurers"; the boon is the only
--     reason this is legal in PvE at all. So it is `type(target) == "number"` gated -- against a
--     player it would be an ordinary 61-kai ability and the basher has no business spending it.
--   * "every 60 seconds"  -> a denizen-only cooldown the AB does not mention.
--
-- HALVING CURRENT HEALTH IS WORTH MOST AT FULL HEALTH, which is why the user's rule is a floor
-- rather than a ceiling: fire above `ataxiaBasher.spiritRendAt` (50). At 100% it removes half the
-- mob; at 20% it removes a tenth of one. There is no wasted-overkill case to guard against, only a
-- diminishing one.
--
-- NO PRONE GATE, deliberately. The AB carries "if your opponent does not lie prone before you,
-- this will be reduced to a 25% reduction" -- but that sentence is in the ADVENTURER ability, and
-- the boon restates the denizen effect flatly as "halving the target's current health" with no
-- such clause. Adding a prone requirement would be inventing a mechanic from the wrong paragraph;
-- if a live capture ever shows a reduced effect on a standing denizen, this is the note to revisit.
--
-- NO MANA FLOOR, unlike the Kai Choke beside it. Choke has one because its AB lists 50 mana; this
-- AB lists kai and nothing else, and the boon removes the kai.
--
-- IT RIDES, IT DOES NOT REPLACE. 3s of equilibrium is idle during a balance combo (the same reason
-- Kai Choke and NUMB ride), so the enfeeble and the combo land in one queued round.
local SPIRIT_REND_CD = 60     -- the boon's own denizen cooldown, timed from the CONFIRMED line
local SPIRIT_REND_RETRY = 6   -- an eaten/refused send retries this often rather than locking out

-- TEKURA OR SHIKUDO-RAIN (user-directed, 2026-09-03) -- shared by all three Kaido eq riders
-- below (Spirit Rend, Kai Choke, the Senseless Flurry numb refresh). Kaido is the class skill
-- COMMON to both specs (CLAUDE.md: "Monk: Tekura/Shikudo, Kaido, Telepathy"), so none of these
-- abilities is Shikudo-exclusive -- "Rain form" was always user doctrine for WHICH Shikudo form
-- to use them in, never a restriction to Shikudo itself. It shipped as a bare `form ~= "Rain"`
-- gate anyway, which silently blocked all three for a Tekura Monk (`form` is nil in Tekura, so
-- the check always failed) for as long as they have existed.
--
-- NO STANCE-NAME FILTER FOR TEKURA, deliberately. `ataxiaBasher_monkBashing2` already uses
-- `ataxia.vitals.stance and true or false` as its Tekura/Shikudo discriminator, and that is all
-- this needs too: during ordinary bashing a Tekura Monk sits in exactly ONE stance the whole
-- time (Horse/Bear only appear in the TK6 backbreaker's FINISHING sequence against a target
-- already being killed, per `.claude/classes/tekura.md`), so there is nothing to filter beyond
-- "are we in Tekura at all". Filtering by stance NAME would be inventing a restriction the boon
-- text never states, in the direction that costs damage rather than the direction that is safe.
local function ataxiaBasher_monkKaidoReady()
  return (ataxia.vitals.stance and true or false) or ataxia.vitals.form == "Rain"
end

function ataxiaBasher_spiritRend(useShieldbreak)
  if not mnemSpiritRend then return nil end
  if useShieldbreak then return nil end -- shielded round: break it first, as the choke does
  if not ataxiaBasher_monkKaidoReady() then return nil end
  if type(target) ~= "number" then return nil end     -- PvE only; the boon is the denizen permit

  local nowT = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp = ataxiaTemp or {}
  if (nowT - (tonumber(ataxiaTemp.spiritRendAt) or 0)) < SPIRIT_REND_CD then return nil end
  if (nowT - (tonumber(ataxiaTemp.spiritRendPendingAt) or 0)) < SPIRIT_REND_RETRY then return nil end

  -- AN UNREADABLE TARGET DOES NOT FIRE, and says so once per run. The rule matches
  -- `ataxiaBasher_rwBisect`'s: a threshold we cannot evaluate is not a threshold we may assume.
  -- But refusing silently is this package's most common failure -- a feature that quietly never
  -- fires -- and here the refusal would be invisible, because the ability costs no balance and
  -- nothing else would look wrong. So it warns, once, naming the reason (the Arc proof-of-life
  -- shape, v4.7.245).
  local hp = ataxiaBasher_targetHpPct()
  if not hp then
    if not ataxiaTemp.spiritRendNoHpWarned then
      ataxiaTemp.spiritRendNoHpWarned = true
      ataxiaEcho("<gold>SPIRIT REND<reset> held, but the target's health cannot be read -- "
        .. "holding off. Check the server target (IRE.Target) if this persists.")
    end
    return nil
  end
  if hp <= (tonumber(ataxiaBasher.spiritRendAt) or 50) then return nil end

  ataxiaTemp.spiritRendPendingAt = nowT
  return "kai enfeeble "..target.."; "
end

-- Enfeeble CONFIRMED (trigger 080, live-captured 2026-09-02): "You violently propel your kai
-- energy at <mob>, enfeebling him." The REAL 60s cooldown starts HERE rather than at send, for
-- the reason the choke's does: a command the server ate or refused has not spent the cooldown, and
-- stamping on send would lock the ability out for a minute over a round that never happened.
-- Self-proving, so it re-latches the flag too -- a missed BOONS row cannot desync it.
function ataxiaBasher_spiritRendConfirm()
  mnemSpiritRend = true
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.spiritRendAt = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp.spiritRendPendingAt = nil
end

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
  if not ataxiaBasher_monkKaidoReady() then return nil end
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
  if not ataxiaBasher_monkKaidoReady() then return nil end
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
    -- Same eq-rider chain as Shikudo below (Kaido is shared by both specs -- see
    -- ataxiaBasher_monkKaidoReady). Tekura's balance combo is unarmed (`combo ... rhk/sdk ucp
    -- ucp`), not the staff flow, but it is still a BALANCE action with idle equilibrium beside
    -- it, so the riders prepend exactly as they do for Shikudo.
    local tRend = ataxiaBasher_spiritRend(useShieldbreak)
    local tChoke = (not tRend) and ataxiaBasher_kaiUnleashedChoke(useShieldbreak) or nil
    command = command..(tRend or tChoke or ataxiaBasher_senselessFlurryNumb() or "")
    command = command.."unwield all"..sp.."combo "..target..(useShieldbreak and " rhk ucp ucp; " or " sdk ucp ucp; ")
  elseif shikudo then
    monkWarnedNoSpec = false
    -- EQ riders alongside the balance combo (both land the same round). ONE eq spender per
    -- round, and the order below is the whole decision -- the `or` chain short-circuits, so a
    -- helper further down is not even CALLED when an earlier one fires, and none of them stamps
    -- anything before it is chosen.
    --
    -- SPIRIT REND FIRST, because its window CLOSES. It is legal only while the target is above
    -- `spiritRendAt` (50%), and every round we spend elsewhere is a round the mob drops closer to
    -- the floor that makes it illegal -- and halving current health is worth twice as much at 80%
    -- as at 40%. Kai Choke has no such window: at 2+ denizens it is just as good next round, and
    -- its own 30s clock keeps running whether we cast it now or in six seconds. The numb refresh
    -- is a self-buff and waits happily. **The ability whose opportunity expires outranks the ones
    -- that merely recur** -- the same reasoning that puts Stormcleaver's execute ahead of the
    -- Thunderclap crowd gate in `ataxiaBasher_rwBisect`.
    local rend = ataxiaBasher_spiritRend(useShieldbreak)
    local choke = (not rend) and ataxiaBasher_kaiUnleashedChoke(useShieldbreak) or nil
    command = command..(rend or choke or ataxiaBasher_senselessFlurryNumb() or "")
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
-- URUZ ON THE GROUND -- health regeneration, laid FIRST in a crowded room (v4.7.248).
--
-- User, 2026-08-11: "in rooms of 3 or more denizens, the first thing we should do is sketch
-- uruz on ground for healing of health", "when in runewarden".
--
-- Runewarden-only because RUNELORE is: the helper is called from ataxiaBasher_runewardenBashing
-- and nowhere else. Corroborated inside this package -- the rune identification tables
-- (triggers 738/740, totem/001) already map uruz to "hp regen" from its totem description
-- ("like a lightning bolt"), which is independent confirmation of what the rune does.
--
-- THREE DIFFERENCES FROM ITS SIBLING ataxiaBasher_rwSowulu, all deliberate:
--
--   1. NOT boon-gated. Sowulu's splash only exists while Hammer and Nail is held; uruz
--      regeneration is base Runelore and always available.
--
--   2. NOT shield-gated. Sowulu skips a shielded round because splash damage is pointless
--      while we are still breaking a shield -- that reasoning does not transfer. Uruz heals
--      US, so its value has nothing to do with the target's shield, and "the first thing we
--      should do" means the first round, not the first round after the shield falls. A
--      crowded room where the opener is a raze is precisely the one we most need to be
--      healing through.
--
--   3. Threshold 3, not 2 (`ataxiaBasher.uruzAt`) -- the user's number. Tunable rather than
--      clamped: unlike bisect's floor-of-2 (where at one denizen there is literally nothing
--      to splash to) there is no count at which regeneration becomes *wrong*, only counts at
--      which it is not worth the round. So this is a default, not a rule.
--
-- ONCE PER ROOM, on the room number, exactly like sowulu: the rune sits on this room's
-- ground, a new room needs its own, and re-entering re-sketches. No expiry line for a ground
-- rune has ever been captured, so a duration-based re-sketch would be invented timing --
-- the once-per-room latch is what we can actually justify. If uruz turns out to lapse
-- mid-fight, capture that line and this can refresh on it.
function ataxiaBasher_rwUruz(sp)
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	if n < (tonumber(ataxiaBasher.uruzAt) or 3) then return "" end
	ataxiaTemp = ataxiaTemp or {}
	local room = (gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.num) or "unknown"
	if ataxiaTemp.rwUruzRoom == room then return "" end
	ataxiaTemp.rwUruzRoom = room
	return "sketch uruz on ground"..sp
end

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
-- Kept as a name so the Runewarden sites and their tests read unchanged; the body moved up to
-- `ataxiaBasher_targetHpPct` when Spirit Rend needed the same read from above this point in the
-- file (v4.7.292). One implementation, two callers that disagree about what nil means.
local function bisectTargetHp()
	return ataxiaBasher_targetHpPct()
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
	-- URUZ FIRST (user: "the first thing we should do"). Health regeneration for a crowded
	-- room, laid ahead of everything else including the shield-break -- see rwUruz for why it
	-- does not share sowulu's shielded skip.
	local uruz = ataxiaBasher_rwUruz(sp)
	-- Fury of Ages keeper (v4.7.285). Prefixed to EVERY branch including the shielded one, the
	-- way the Infernal prefixes its `aura`: fury costs willpower, not balance or equilibrium, so
	-- it never competes with the round it rides on.
	--
	-- This is the OFF switch as much as the on: the boon quadruples endurance costs, and turning
	-- fury on for a class with nothing to turn it off would strand a Runewarden mid-grind. That
	-- is the hazard `ataxiaBasher_infFury`'s EP hysteresis was written for, and it applies to
	-- both classes identically.
	local fury = ataxiaBasher_infFury(sp)
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
		-- uruz rides the shielded round too: it heals US, so the target's shield is irrelevant
		-- to it, and a crowded room whose opener is a raze is exactly when we want it down.
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = fury..uruz..braze..sp..bash
		else
			command = fury..uruz..raze..sp..brage
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
		command = fury..uruz..sowulu..brage..sp..swing
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