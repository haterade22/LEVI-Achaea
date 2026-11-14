--[[mudlet
type: script
name: Pariah Logic
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Pariah
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
  OFFENSIVE SYSTEM - Pariah (Adaptive)

  REQUIRED READING before modifying:
  - .claude/classes/lock_types.md (lock definitions)
  - .claude/classes/pariah.md (class mechanics)

  Single adaptive dispatch — no manual mode selection needed.
  Always starts with bear (haemophilia) to build toward scourge.
  Dynamically selects kill route based on what afflictions stick:

  Kill routes (checked in priority order):
    Scourge:   haemophilia + scytherus + pyramides + burrow + bleed >= 200
    Latency:   3+ plagues + burrow + epitaph >= 4 → voyria + accelerate
    Virulence: 3+ plagues + asthma stuck → sting + virulence (combo afflictions)

  Logograph tree determines trace ability per round.
  Swarm sting/burrow/infest apply plagues.
  Epitaph heartbeats control trace delay.

  See pariah.state in 007_Pariah_things.lua for all mutable state.
]]--

--------------------------------------------------------------------------------
-- Helpers (local to this file)
--------------------------------------------------------------------------------

local function selectLogograph()
  local trace = {}
  local logo  = pariah.state.lastLogograph

  if haveAff("shield") then
    table.insert(trace, "fissure")
  elseif not logo then
    -- Always start with bear for haemophilia
    table.insert(trace, "bear")

  elseif logo == "serpent" then
    if ataxia_wantClumsiness() and not haveAff("clumsiness") then
      table.insert(trace, "scales")
    elseif not haveAff("weariness") then
      table.insert(trace, "nest")
    elseif (haveAff("clumsiness") or haveAff("weariness")) and not haveAff("impatience") then
      table.insert(trace, "skein")
    else
      table.insert(trace, "nest")
    end

  elseif logo == "nest" then
    if haveAff("impatience") or haveAff("sandfever") then
      table.insert(trace, "bear")
    elseif haveAff("flushings") then
      table.insert(trace, "bear")
    elseif haveAff("clumsiness") and not haveAff("haemophilia") then
      table.insert(trace, "bear")
    else
      table.insert(trace, "skein")
    end

  elseif logo == "scales" then
    table.insert(trace, "bear")

  elseif logo == "skein" then
    if haveAff("impatience") and (haveAff("sandfever") or haveAff("mycalium")) and not haveAff("addiction") then
      table.insert(trace, "scarab")
    elseif haveAff("impatience") or (haveAff("sandfever") and not haveAff("epilepsy")) then
      table.insert(trace, "sun")
    elseif haveAff("flushings") and not haveAff("addiction") then
      table.insert(trace, "scarab")
    elseif haveAff("addiction") then
      table.insert(trace, "sun")
    elseif not haveAff("epilepsy") then
      table.insert(trace, "sun")
    else
      table.insert(trace, "scarab")
    end

  elseif logo == "bear" then
    -- If haemophilia is stuck, stack ginseng to protect it; otherwise kelp pressure
    if haveAff("haemophilia") then
      if haveAff("flushings") and not haveAff("addiction") then
        table.insert(trace, "scarab")
      elseif not haveAff("asthma") then
        table.insert(trace, "jackal")
      else
        table.insert(trace, "scarab")
      end
    else
      if not haveAff("asthma") then
        table.insert(trace, "jackal")
      elseif haveAff("flushings") and not haveAff("addiction") then
        table.insert(trace, "scarab")
      else
        table.insert(trace, "jackal")
      end
    end

  elseif logo == "scarab" then
    table.insert(trace, "jackal")

  elseif logo == "sun" or logo == "scorpion" or logo == "jackal" then
    table.insert(trace, "serpent")

  else
    table.insert(trace, "serpent")
  end

  return trace
end

local function selectHeartbeats(e)
  local hb = {}
  if     e == 0 then table.insert(hb, "5")
  elseif e == 1 then table.insert(hb, "3")
  elseif e == 2 then table.insert(hb, "1")
  else               table.insert(hb, "0")
  end
  return hb
end

local function selectSwarmSting()
  local sting = {}
  local hasHaemo = haveAff("haemophilia")

  if not haveAff("pyramides") and not haveAff("burrow") then
    table.insert(sting, "pyramides")
  elseif hasHaemo then
    -- Haemophilia sticking: ginseng pressure to protect it
    if not haveAff("flushings") then
      table.insert(sting, "flushings")
    elseif not haveAff("mycalium") then
      table.insert(sting, "mycalium")
    elseif not haveAff("rebbies") then
      table.insert(sting, "rebbies")
    elseif not haveAff("sandfever") and not haveAff("impatience") then
      table.insert(sting, "sandfever")
    else
      table.insert(sting, "pyramides")
    end
  else
    -- Haemophilia not sticking: goldenseal pressure, build plagues for latency
    if not haveAff("sandfever") and not haveAff("impatience") then
      table.insert(sting, "sandfever")
    elseif not haveAff("rebbies") then
      table.insert(sting, "rebbies")
    elseif not haveAff("flushings") then
      table.insert(sting, "flushings")
    elseif not haveAff("mycalium") then
      table.insert(sting, "mycalium")
    else
      table.insert(sting, "mycalium")
    end
  end
  return sting
end

--- With both arms out and no VIRULENCE to send, say why the key did nothing: at most once in 3 s,
--- because a held key sends a round on every press. A window on getEpoch(), never `==` (CLAUDE.md, v4.7.469).
local ARMS_ECHO_GAP = 3
function pariah.armsOutEcho()
  local now = getEpoch()
  local last = ataxiaTemp and ataxiaTemp.pariahArmsEchoAt
  if last and now - last < ARMS_ECHO_GAP then return end
  if ataxiaTemp then ataxiaTemp.pariahArmsEchoAt = now end
  local why = pariah.state.virulenceTimer and "virulence is on its 10 s delay"
    or "virulence needs 3 of rebbies, sandfever, flushings, pyramides"
  pariah.echo("Both arms out: no attack sent (" .. why .. ").")
end

--------------------------------------------------------------------------------
-- Main dispatch (adaptive — no mode argument)
--------------------------------------------------------------------------------

function pariah.dispatch()
  if reboundHold and reboundHold.gate(pariah.dispatch) then return end
  local atk = combatQueue()
  local e   = ataxia.vitals.epitaph
  taccelerates = taccelerates or 0  -- system-global, managed by 013_Accelerate.lua

  -- Both of OUR arms out (2026-11-13): every Memorium record (TRACE, CRUX, BLOOD) and the swarm commands
  -- STING, BURROW, INFEST, SCOURGE and LATENCY say `Requires arms: 1`, and the attacker needs at least one
  -- unbroken arm (the user). VIRULENCE states `Requires arms: 0` with Pre checks, so the 0 is a statement,
  -- and it bypasses a shield: it is the one attack left. Without its plagues we send nothing and say why,
  -- because every other command of the round would be refused.
  if ataxia_selfArmsOut and ataxia_selfArmsOut() then
    if pariah.canVirulence() and not pariah.state.virulenceTimer then
      send("queue addclearfull freestand " .. atk .. "virulence " .. target)
    else
      pariah.armsOutEcho()
    end
    return
  end

  getLockingAffliction()
  checkTargetLocks()

  -- Kelp stack -- always include haemophilia to track if it's stuck
  tAffs.logostack = checkAffList(
    {"paralysis", "asthma", "epilepsy", "clumsiness", "impatience", "addiction", "relapsing", "haemophilia"}, 3)

  -- Plague stack: 3+ plagues active enables latency/virulence
  local tlatency = checkAffList({"mycalium", "rebbies", "sandfever", "flushings", "pyramides"}, 3)

  local logographtrace = selectLogograph()
  local myheartbeats   = selectHeartbeats(e)
  local myswarmsting   = selectSwarmSting()

  -- Attack dispatch (priority order)
  if haveAff("shield") then
    if haveAff("voyria") and taccelerates < 2 then
      atk = atk .. ";trace fissure " .. target .. ";blood accelerate " .. target
    elseif e >= 2 and pariah.state.expose then
      atk = atk .. "swarm sting " .. myswarmsting[1] .. " " .. target .. ";trace fissure " .. target
    elseif e <= 1 then
      atk = atk .. ";trace fissure " .. target
    end

  elseif not pariah.state.bladePrepared then
    atk = atk .. "crux ensorcell " .. target

  elseif taccelerates >= 2 then
    atk = atk .. ";trace " .. logographtrace[1] .. " " .. target

  elseif haveAff("voyria") then
    atk = atk .. ";trace " .. logographtrace[1] .. " " .. target .. ";blood accelerate " .. target

  elseif pariah.state.latencyTimer and not haveAff("voyria") and pariah.state.lastLogograph == "scorpion" then
    atk = atk .. "trace serpent " .. target .. ";crux transpose voyria;blood accelerate " .. target

  -- Scourge kill: all conditions met
  elseif tAffs.bleed >= 200
      and haveAff("scytherus") and haveAff("haemophilia")
      and haveAff("pyramides") and haveAff("burrow") then
    atk = atk .. "swarm scourge pyramides " .. target .. ";trace " .. logographtrace[1] .. " " .. target

  elseif e >= 3 and pariah.state.expose then
    -- Latency kill: 3+ plagues, burrowed, epitaph deep enough
    if haveAff("burrow") and tlatency and e >= 4 then
      atk = atk .. "swarm latency pyramides;trace scorpion " .. target

    -- Virulence: 3+ plagues + asthma stuck + exposed → sting + virulence (free) + trace
    elseif pariah.canVirulence() and haveAff("asthma") then
      atk = atk .. "swarm sting " .. myswarmsting[1] .. " " .. target .. ";virulence " .. target .. ";trace " .. logographtrace[1] .. " " .. target

    -- Scourge prep: haemophilia + burrow + high bleed → get scytherus via scorpion
    elseif haveAff("haemophilia") and haveAff("burrow") and tAffs.bleed >= 200 then
      atk = atk .. "swarm sting " .. myswarmsting[1] .. " " .. target .. ";trace scorpion " .. target

    elseif not haveAff("burrow") then
      atk = atk .. "swarm burrow pyramides " .. target .. ";trace " .. logographtrace[1] .. " " .. target

    elseif haveAff("burrow") and not pariah.state.infestTimer then
      atk = atk .. "swarm infest pyramides " .. target .. ";trace " .. logographtrace[1] .. " " .. target

    else
      atk = atk .. "swarm sting " .. myswarmsting[1] .. " " .. target .. ";trace " .. logographtrace[1] .. " " .. target
    end

  elseif e <= 2 then
    if myheartbeats[1] ~= "0" then
      atk = atk .. ";trace " .. logographtrace[1] .. " " .. target .. " " .. myheartbeats[1] .. " heartbeats"
    else
      atk = atk .. "swarm sting " .. myswarmsting[1] .. " " .. target .. ";trace " .. logographtrace[1] .. " " .. target
    end
  end

  send("queue addclearfull freestand wield left knife;unwield right;" .. atk)
end

-- Backward-compat wrappers (both call the same adaptive dispatch)
function levipariahlatencytest() pariah.dispatch() end
function levipariahscourgetest() pariah.dispatch() end
