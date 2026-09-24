--[[mudlet
type: script
name: Dead Breath
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    NECROMANCY BOON RIDERS -- BELCH (Dead Breath) and SOULSTORM (Deathtempest)
    ============================================================================

    The boon (Mnemosyne, rare):

        Dead Breath    1    rare
          Your belch will now cause significant damage to all denizens in the location, but
          drains 10% of your mana in the process.

    The ability it upgrades (ABADMIN ID 136, pasted by the user):

        Belch (Necromancy)
        Syntax:            BELCH
        Works on/against:  Room
        Cooldown:          4.00 seconds of equilibrium
        Resource:          200 mana

    So this is a ROOM attack that costs EQUILIBRIUM -- the same idle channel Death Stare and Kai
    Choke ride while the class combo spends balance -- which is why it goes in the chain beside
    them rather than replacing the round.

    WHAT MAKES IT WORTH A ROUND: it hits everything. In a thin room the 200 mana plus a tenth of
    the pool buys one extra hit on one denizen; in a crowd it buys one on each. Hence the same
    crowd gate Kai Unleashed uses (2+ denizens), and a mana floor -- mana is the curing pool as
    well as the ammunition, and a belch that leaves us dry in a swarm trades damage for a death.

    THE REFUSAL IS A ROOM STATE, NOT A COOLDOWN (live line, user 2026-09-24):

        You take in a deep breath in preparation for your belch, but cough and sputter as you
        inhale the noxious air that surrounds you.

    That is the gas we already laid: the room is still foul, so another belch is refused. It is
    remembered PER ROOM and cleared when we move, because the next room's air is clean -- treating
    it as a flat cooldown would either waste the eq in a fresh room or keep re-trying in a fouled
    one.

    The boon is self-proving: `Your rotten breath befouls the air...` only prints with Dead Breath
    up (the Reaper-tithe rule), so the success trigger latches the flag as well as stamping it.
]]--

ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}

-- The ability's own 4s eq cooldown, plus a beat. A send we never saw land is retried after this.
local DEAD_BREATH_CD = 5
-- How long a refused (already-foul) room stays refused before we try it again. The gas outlasts
-- the ability's cooldown, so this is deliberately longer than DEAD_BREATH_CD.
local FOUL_HOLD = 15
-- Flat cost from ABADMIN; the boon adds a tenth of the pool on top.
local BELCH_MANA = 200

local function roomKey()
  local r = gmcp and gmcp.Room and gmcp.Room.Info
  return (r and (r.num or r.id)) or 0
end

-- Can we pay for it and still have a curing pool? `deadBreathManaFloor` is the percentage we
-- refuse to drop below (default 50): the belch costs 200 flat AND a tenth of maximum, so in a
-- swarm an unguarded spend is how a full mana bar becomes an empty one in four rounds.
local function affordable()
  local v = ataxia and ataxia.vitals
  local mp = tonumber(v and v.mp)
  if not mp then return false end
  local maxmp = tonumber((gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.maxmp))
  local drain = BELCH_MANA + ((maxmp and maxmp * 0.10) or 0)
  if mp < drain then return false end
  local floor = tonumber(ataxiaBasher.deadBreathManaFloor) or 50
  if floor > 0 and maxmp and maxmp > 0 then
    if ((mp - drain) / maxmp) * 100 < floor then return false end
  end
  return true
end

-- The eq rider, called from `ataxiaBasher_assembleAttack` beside Death Stare. Returns "" or the
-- command plus the separator, so the caller can concatenate it blind.
function ataxiaBasher_deadBreathBelch(sp)
  if not mnemDeadBreath then return "" end
  if not (ataxiaBasher and ataxiaBasher.enabled) then return "" end
  if ataxiaBasher.shielded then return "" end -- break the shield first, every rider's rule
  ataxiaTemp = ataxiaTemp or {}
  local nowT = (getEpoch and getEpoch()) or os.time()

  -- The room we last fouled is still foul: no second cloud until it clears or we leave.
  if ataxiaTemp.belchFouledRoom == roomKey()
     and (nowT - (tonumber(ataxiaTemp.belchFouledAt) or 0)) < FOUL_HOLD then
    return ""
  end
  if (nowT - (tonumber(ataxiaTemp.belchAt) or 0)) < DEAD_BREATH_CD then return "" end

  -- A ROOM attack earns its eq in a crowd, not on one denizen.
  local M = ataxia and ataxia.mnemosyne
  local n = (M and M._denizenCount and M._denizenCount()) or 0
  if n < 2 then return "" end
  if not affordable() then return "" end

  ataxiaTemp.belchAt = nowT
  sp = sp or ((ataxia.settings and ataxia.settings.separator) or ";")
  return "belch" .. sp
end

-- "You belch a cloud of stinking gas out of your lungs and into your surroundings." and the boon's
-- own "Your rotten breath befouls the air...". Stamps the send as landed and -- since the second
-- line cannot print without the boon -- latches the flag.
function ataxiaBasher_belchLanded(fromBoonLine)
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.belchAt = (getEpoch and getEpoch()) or os.time()
  ataxiaTemp.belchFouledRoom, ataxiaTemp.belchFouledAt = nil, nil
  if fromBoonLine then mnemDeadBreath = true end
  return true
end

-- The refusal: the air here is already ours. Remember WHICH room, so moving clears it.
function ataxiaBasher_belchFouled()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.belchFouledRoom = roomKey()
  ataxiaTemp.belchFouledAt = (getEpoch and getEpoch()) or os.time()
  return true
end

-- ---------------------------------------------------------------------------
-- DEATHTEMPEST -- SOULSTORM, ONCE PER DENIZEN  (v4.7.338, user-directed)
-- ---------------------------------------------------------------------------
--
-- The boon (rare, Offence): "Your necromancy soulstorm ability deals additional cold damage when
-- it profanes a denizen."  The ability (ABADMIN 142):
--
--     Syntax:            SOULSTORM <target>
--     Cooldown:          4.00 seconds of equilibrium   (greatly reduced against a denizen)
--     Resource:          1% life essence               (likewise)
--     "Against denizens, you will instead profane their soul with malign energy, causing them to
--      take ten percent more damage from necromantic abilities, the curses of evileye, and the
--      weaponmastery attacks of your fellow Infernals."
--
-- USER'S RULE: "We should use this once" -- "If we have the boon deathtempest".
--
-- ONCE PER DENIZEN IS THE WHOLE POINT. Profane is a DEBUFF that sits on the mob, not damage we
-- repeat: a second storm on the same soul buys nothing and costs the equilibrium the round's real
-- attacks want. So it is tracked by TARGET ID -- ids are unique per creature and never return
-- once it dies -- and confirmed by the game's own line rather than by the send.
--
-- IT DOES NOT STAND DOWN FOR THE BELCH (corrected v4.7.343, user: "For soulstorm, belch doesnt
-- matter, shouldnt be a criteria. They are two seperate attacks"). v4.7.338 held the storm back on
-- any round the belch fired, reasoning that one equilibrium cannot buy two abilities. That was my
-- inference, not the game's rule -- and the ability text supports the user: against a denizen
-- soulstorm's "equilibrium and essence costs shall be greatly reduced". Both go out.
local SOULSTORM_RETRY = 6 -- a send we never saw confirmed is tried again after this

function ataxiaBasher_deathtempestStorm(sp)
  if not mnemDeathtempest then return "" end
  if not (ataxiaBasher and ataxiaBasher.enabled) then return "" end
  if ataxiaBasher.shielded then return "" end
  if type(target) ~= "number" then return "" end
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.profaned = ataxiaTemp.profaned or {}
  if ataxiaTemp.profaned[target] then return "" end -- this soul is already profaned

  local nowT = (getEpoch and getEpoch()) or os.time()
  if ataxiaTemp.soulstormTarget == target
     and (nowT - (tonumber(ataxiaTemp.soulstormAt) or 0)) < SOULSTORM_RETRY then
    return "" -- waiting on the confirmation line for this target
  end
  ataxiaTemp.soulstormAt, ataxiaTemp.soulstormTarget = nowT, target
  sp = sp or ((ataxia.settings and ataxia.settings.separator) or ";")
  return "soulstorm " .. target .. sp
end

-- "You call forth an unholy tide of necromantic essence and release it, engulfing <mob> in a
-- profane soulstorm." (live 2026-09-24). The soul is profaned: never storm this one again.
--
-- Stamped against the target we SENT for, not whatever is in front of us now -- the round may
-- have moved on, and marking the wrong mob would cost a storm on the right one. The base ability
-- prints this line with or without the boon, so it proves nothing about Deathtempest and does not
-- latch it: that comes from the claim.
function ataxiaBasher_soulstormLanded()
  ataxiaTemp = ataxiaTemp or {}
  local id = ataxiaTemp.soulstormTarget or (type(target) == "number" and target or nil)
  if not id then return false end
  ataxiaTemp.profaned = ataxiaTemp.profaned or {}
  ataxiaTemp.profaned[id] = true
  ataxiaTemp.soulstormAt, ataxiaTemp.soulstormTarget = nil, nil
  return true
end

-- "Necromantic essence still profanes a bloated cabin boy's soul." (live 2026-09-24, user: "This
-- is soulstorm already active on the target btw").
--
-- The game refusing a second storm is the same fact as the first one landing: THIS SOUL IS
-- PROFANED. It matters because it is the only way to learn it when the confirmation never
-- arrived -- a reload between the send and the reply, a line eaten by a burst -- and without it
-- the retry would spend equilibrium on that mob every six seconds for as long as it lived.
function ataxiaBasher_soulstormAlready()
  return ataxiaBasher_soulstormLanded()
end

-- A room's worth of profaned ids is dead weight once we leave; ids never repeat, so this is
-- housekeeping rather than correctness. Called from the room read.
function ataxiaBasher_profanedForget()
  if type(ataxiaTemp) == "table" then ataxiaTemp.profaned = {} end
end
