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
  OFFENSIVE SYSTEM - Pariah

  REQUIRED READING before modifying:
  - .claude/classes/lock_types.md (lock definitions)
  - .claude/classes/pariah.md (class mechanics)

  Kill routes:
    "latency" mode: Voyria kill — stack plagues, trigger latency, accelerate finish
    "scourge" mode: Scourge kill — pyramides + scytherus + haemophilia + bleed >= 200

  Logograph tree determines trace ability per round.
  Swarm sting/burrow/infest apply plagues.
  Epitaph heartbeats control trace delay.

  See pariah.state in 007_Pariah_things.lua for all mutable state.
]]--

--------------------------------------------------------------------------------
-- Helpers (local to this file)
--------------------------------------------------------------------------------

local function selectLogograph(mode)
  local trace = {}
  local logo  = pariah.state.lastLogograph

  if haveAff("shield") then
    table.insert(trace, "fissure")
  elseif not logo then
    -- Starting logograph differs by kill route
    table.insert(trace, (mode == "scourge") and "bear" or "serpent")

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
    elseif haveAff("clumsiness") and (mode == "scourge" or not haveAff("haemophilia")) then
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
    if mode == "scourge" then
      if haveAff("flushings") and not haveAff("addiction") then
        table.insert(trace, "scarab")
      elseif not haveAff("asthma") then
        table.insert(trace, "jackal")
      else
        table.insert(trace, "scarab")
      end
    else
      -- latency mode
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

local function selectSwarmSting(mode)
  local sting = {}
  if mode == "scourge" then
    if not haveAff("pyramides") and not haveAff("burrow") then
      table.insert(sting, "pyramides")
    elseif not haveAff("flushings") then
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
    -- latency mode
    if not haveAff("pyramides") and not haveAff("burrow") then
      table.insert(sting, "pyramides")
    elseif not haveAff("sandfever") and not haveAff("impatience") then
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

--------------------------------------------------------------------------------
-- Main dispatch
--------------------------------------------------------------------------------

function pariah.dispatch(mode)
  -- mode = "latency" or "scourge"
  if reboundHold and reboundHold.gate(pariah.dispatch) then return end
  local atk = combatQueue()
  local e   = ataxia.vitals.epitaph
  taccelerates = taccelerates or 0  -- system-global, managed by 013_Accelerate.lua

  getLockingAffliction()
  checkTargetLocks()

  -- Kelp stack (haemophilia added for scourge mode)
  local kelpList = (mode == "scourge")
    and {"paralysis", "asthma", "epilepsy", "clumsiness", "impatience", "addiction", "relapsing", "haemophilia"}
    or  {"paralysis", "asthma", "epilepsy", "clumsiness", "impatience", "addiction", "relapsing"}
  tAffs.logostack = checkAffList(kelpList, 3)

  -- Plague stack (local — not global): 3+ plagues active triggers latency route
  local tlatency = checkAffList({"mycalium", "rebbies", "sandfever", "flushings", "pyramides"}, 3)

  local logographtrace = selectLogograph(mode)
  local myheartbeats   = selectHeartbeats(e)
  local myswarmsting   = selectSwarmSting(mode)

  -- Attack dispatch
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

  elseif mode == "scourge"
      and tAffs.bleed >= 200
      and haveAff("scytherus") and haveAff("haemophilia")
      and haveAff("pyramides") and haveAff("burrow") then
    atk = atk .. "swarm scourge pyramides " .. target .. ";trace " .. logographtrace[1] .. " " .. target

  elseif e >= 3 and pariah.state.expose then
    if mode == "latency" and haveAff("burrow") and tlatency and e >= 4 then
      -- Latency kill setup: swarm has burrow, 3+ plagues active, epitaph deep enough
      atk = atk .. "swarm latency pyramides;trace scorpion " .. target
    elseif not haveAff("burrow") then
      atk = atk .. "swarm burrow pyramides " .. target .. ";trace " .. logographtrace[1] .. " " .. target
    elseif mode == "scourge" and haveAff("burrow") and tAffs.bleed >= 200 then
      atk = atk .. "swarm sting " .. myswarmsting[1] .. " " .. target .. ";trace scorpion " .. target
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

-- Backward-compat wrappers
function levipariahlatencytest() pariah.dispatch("latency") end
function levipariahscourgetest() pariah.dispatch("scourge") end
