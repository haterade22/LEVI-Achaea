--[[mudlet
type: script
name: Confusion Disrupted
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

-- CONFUSED AND DISRUPTED (v4.7.373, user-directed).
--
-- User: "When we have the affliction confusion and are disrupted. We need to priority cure
-- confusion and concentrate right after curing it. Or else we never get EQ back." -- "CURING
-- PRIOAFF <aff>".
--
-- DISRUPTED takes our equilibrium and only CONCENTRATE gives it back, and concentrating does not
-- work while CONFUSED. The live prompt that prompted this (a ravening bainligor, 2026-10-04):
--
--   [ bld(959) REB slashedthroat sen prone PYR con crackedribs (2) AST diz disrupted ]
--
-- SSC holds disrupted at priority 2 but confusion far lower (an ash cure: 8 in the defaults, 12
-- in the PvE `bash` curingset), so
-- with both up it keeps trying the concentrate that confusion blocks while the confusion waits
-- its turn -- and no equilibrium comes back. So, with both up: `curing prioaff confusion` (the
-- one-shot server-side bump the user named; it writes no stored priority, so it is safe against
-- the curingset write hazard), and the moment confusion is cured while we are still disrupted:
-- `concentrate`.
--
-- The `conDis` priority swap (swaps/002) aims at the same pair, but it is off by default, also
-- requires impatience, and rewrites the STORED confusion priority. This is separate on purpose.
--
-- Event-driven ("aff gained" / "aff cured", raised by 004_Aff_gains_losses after the affliction
-- table is updated), so neither of that file's long if/elseif chains is touched. Both actions are
-- throttled: the full affliction list re-raises "aff gained" for everything we carry.

ataxia = ataxia or {}
ataxiaTemp = ataxiaTemp or {}

local THROTTLE = 1.5 -- seconds between repeats of either action

local function has(aff)
  local v = ataxia.afflictions and ataxia.afflictions[aff]
  if v == nil or v == false then return false end
  if type(v) == "number" then return v > 0 end
  return true
end

local function now() return (getEpoch and getEpoch()) or os.time() end

function ataxia_conDisGained(aff)
  if aff ~= "confusion" and aff ~= "disrupted" then return false end
  if not (has("confusion") and has("disrupted")) then return false end
  if (now() - (tonumber(ataxiaTemp.conDisPrioAt) or -1e9)) < THROTTLE then return false end
  ataxiaTemp.conDisPrioAt = now()
  send("curing prioaff confusion", false)
  if ataxiaEcho then
    ataxiaEcho("Confused <red>and<reset> disrupted -- curing <yellow>confusion<reset> first, then concentrate.")
  end
  return true
end

function ataxia_conDisCured(aff)
  if aff ~= "confusion" then return false end
  if not has("disrupted") then return false end
  if (now() - (tonumber(ataxiaTemp.conDisConcAt) or -1e9)) < THROTTLE then return false end
  ataxiaTemp.conDisConcAt = now()
  send("concentrate", false)
  return true
end

if ataxia_conDisGainedH then killAnonymousEventHandler(ataxia_conDisGainedH) end
if ataxia_conDisCuredH then killAnonymousEventHandler(ataxia_conDisCuredH) end
ataxia_conDisGainedH = registerAnonymousEventHandler("aff gained", function(_, aff) ataxia_conDisGained(aff) end)
ataxia_conDisCuredH = registerAnonymousEventHandler("aff cured", function(_, aff) ataxia_conDisCured(aff) end)
