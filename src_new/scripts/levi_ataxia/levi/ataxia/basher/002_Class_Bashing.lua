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
      return ataxiaBasher_goldenDragonBattlerage(sp)
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
local GDRAGON_BR = {
  { key = "deaden",    cmd = "deaden",    rage = 24, cd = 35, control = true },
  { key = "psidaze",   cmd = "psidaze",   rage = 28, cd = 41, control = true },
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
  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and (rage >= 36 or ataxiaBasher_brFree())
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    return "reap "..target..sp
  end
  ataxiaTemp.gdragonBrAt = ataxiaTemp.gdragonBrAt or {}
  for _, ab in ipairs(GDRAGON_BR) do
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
-- "Bard Performance" timer. Needs the instrument in hand, so it wields the lyre first
-- (the next blade attack re-wields the left shield; the rapier stays in the right hand).
-- Called once at bash start (basher_engaged) and again when the 15-min timer expires.
function ataxiaBasher_bardCompose()
   -- Debounce: rapid "not performing" lines (repeated battlerage 'play' commands fire before the
   -- compose lands) can call this several times; the extras are just redundant. Allow one per 2s.
   if bardComposePending then return end
   bardComposePending = true
   tempTimer(2, [[bardComposePending = false]])
   local c = (ataxia.bardStuff and ataxia.bardStuff.bashCompose) or "paean prelude scherzo sonata maqam"
   send("remove lyre;wield left lyre;compose "..c)
   enableTimer("Bard Performance")
   ataxiaEcho("<green>Bard bash:<reset> composed <cyan>"..c)
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
    local atk
    if ataxia.bardStuff and ataxia.bardStuff.bashPunctuate then
       atk = "blade punctuate "..target.." nomos"
    elseif bardWarmarch then
       atk = "blade flick "..target.." paean"  -- Warmarch boon: paean refrain now hits denizens (+100% psychic)
    else
       atk = "blade flick "..target.. " nomos"
    end
    command = command.."wield right rapier;wield left shield;"..atk

   return command
end

function ataxiaBasher_blademasterBashing()
	local command, sp = "", ataxia.settings.separator
	local brage = ataxiaBasher_assembleBattlerage()
	local raze = ataxiaBasher.battlerage.Blademaster.raze

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
		end
	end

	if ataxiaBasher.shielded then
		if ataxiaBasher.rageraze and ataxia.vitals.rage >= 17 then
			command = command..raze..sp.."infuse fire "..sp.." "..slash
		else
			command = command.."raze "..target..sp..brage
		end
	else
		command = command..brage..sp.."infuse fire "..sp.." "..slash
	end

	return command
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
  { key = "curse",   cmd = "chrono curse",   rage = 24, cd = 35, skipIfAff = "aeon" },
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

function ataxiaBasher_dwBattlerage(sp)
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
  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and (rage >= 36 or ataxiaBasher_brFree())
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    ataxiaBasher_brSent()
    return "reap "..target..sp
  end

  ataxiaTemp.dwBrAt = ataxiaTemp.dwBrAt or {}
  for _, ab in ipairs(DW_BR) do
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
	command = ff..ataxiaBasher_dwKeeper(sp)..ataxiaBasher_dwBattlerage(sp)..primary
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
-- ARC (Weaponmastery, general -- all four specs) normally reads "Works on: Adventurers
-- and room", so it is dead weight in PvE; the boon is what makes it hit denizens. The
-- UNTARGETED form damages EVERYONE in the room for 4.75s of balance; naming a target
-- hits only them for 3.00s. We always want the room form -- one wide swing instead of
-- several narrow ones.
--
-- It spends BALANCE, so like Tyranny it REPLACES the round's swing rather than riding
-- alongside it. That is also why the crowd gate matters: at 4.75s versus a ~2s dsl, one
-- arc costs more than two normal swings, so it only pays with enough denizens standing
-- in it. User-directed threshold: 2+ (tunable via ataxiaBasher.infArcAt).
function ataxiaBasher_infArc(sp)
	if not infIndiscriminate then return "" end
	if ataxiaBasher.shielded then return "" end -- break the shield first
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	if n < (tonumber(ataxiaBasher.infArcAt) or 2) then return "" end
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
		-- one 4.75s room-wide hit instead of several single-target ones.
		local arc = ataxiaBasher_infArc(sp)
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
		command = brage..sp..bash
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
  if pend and pend.verb and (nowT - (tonumber(pend.at) or 0)) < 3 then
    return pend.verb.." "..target..sp
  end
  ataxiaTemp.psionBrPending = nil
  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and (rage >= 36 or ataxiaBasher_brFree())
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    return "reap "..target..sp
  end
  ataxiaTemp.psionBrAt = ataxiaTemp.psionBrAt or {}
  for _, ab in ipairs(PSION_BR) do
    -- Rage floor (v4.7.141): see ataxiaBasher_rageAfford (001).
    if (not ab.optIn or ataxiaBasher.psionRegrowth) and ataxiaBasher_rageAfford(rage, ab.rage)
       and (nowT - (tonumber(ataxiaTemp.psionBrAt[ab.key]) or 0)) >= ab.cd then
      ataxiaTemp.psionBrAt[ab.key] = nowT
      ataxiaTemp.psionBrPending = { verb = ab.cmd, at = nowT }
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
  local brage = ataxiaBasher_psionBattlerage(sp)

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
		command = brage..sp..bash
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
  { key = "bulwark",   cmd = "bulwark",       rage = 28, cd = 45, noTarget = true },
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

  if ataxiaBasher.cullingBlade and not ataxiaTemp.bladeCooldown and (rage >= 36 or ataxiaBasher_brFree())
     and gmcp.Room.Info.area ~= "the Fathomless Expanse of the World Tree" then
    ataxiaBasher_brSent()
    return "reap "..target..sp
  end

  ataxiaTemp.rwBrAt = ataxiaTemp.rwBrAt or {}
  for _, ab in ipairs(RW_BR) do
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
-- Economics, and why it is crowd-gated rather than default: AB Bisect spends 4.00s of
-- BALANCE against the SnB combination's ~2s, so it is roughly a double-length swing. It
-- pays for itself only when the third strike lands on more than one mob. Same shape as the
-- Infernal Arc gate (4.75s vs ~2s dsl, gated at 2+) -- `ataxiaBasher.bisectAt`, default 2.
--
-- It REPLACES the swing rather than riding alongside it: both spend balance.
--
-- Notes from the AB entry that deliberately do NOT appear in this logic:
--   * The "slain outright at <=20% health" clause is ADVENTURERS ONLY. There is no execute
--     value against denizens, so no low-hp branch here -- the boon's AoE is the whole point.
--   * It bypasses rebounding and reflections but leaves them intact, so it needs no raze
--     handling and gives none. The shielded branch is untouched: a shield must still be
--     broken first.
--   * `BISECT <target> [venom]` takes an optional venom; unused for bashing.
--
-- PREREQUISITE, deliberately unmanaged (user decision): bisect requires an edged runeblade
-- with the HUGALAZ rune sketched on the blade. Nothing in this package knows hugalaz -- the
-- sketch syntax for a BLADE rune was never captured, and inventing it would send garbage --
-- so keeping it on the weapon is the user's setup. If it ever lapses, bisect is refused
-- until re-sketched; capture that refusal line and this can back off on its own.
function ataxiaBasher_rwBisect(sp)
	if not mnemThunderclap then return nil end
	if ataxiaBasher.shielded then return nil end -- break the shield first
	if type(target) ~= "number" then return nil end
	local M = ataxia.mnemosyne
	local n = (M and M._denizenCount and M._denizenCount()) or 0
	if n < (tonumber(ataxiaBasher.bisectAt) or 2) then return nil end
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
		-- Thunderclap: at a crowd the room-wide bisect replaces the single-target swing.
		-- The falcon rake is folded back in because it is a FREE pet order, not part of the
		-- balance swing -- dropping it with `bash` would quietly cost us a free hit.
		local bisect = ataxiaBasher_rwBisect(sp)
		command = sowulu..brage..sp..(bisect and (falcon..bisect) or bash)
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