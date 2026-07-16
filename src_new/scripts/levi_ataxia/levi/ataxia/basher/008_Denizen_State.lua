--[[mudlet
type: script
name: Denizen State
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

-------------------------------------------------------------------------------
--                        Per-Denizen Combat State                           --
--                                                                           --
--  A live, per-denizen-id state table so the basher can SEE what our (and   --
--  others') attacks have done to each mob and act on it -- the headline     --
--  case being CHARM (a charmed mob fights the others for us) and the        --
--  battlerage AFFLICTIONS that some abilities cash in for bonus damage      --
--  (e.g. Headstrike hits harder on a reckless/feared mob).                  --
--                                                                           --
--  Lives under `ataxiaTemp` (NOT `ataxia`) because only `ataxia` is         --
--  serialized to disk -- transient combat state must never be saved.        --
--                                                                           --
--    ataxiaTemp.denizenState[id] = {                                        --
--      name = "a fire wyrm",                                                --
--      hpp  = 61,          -- only for the current server target (see 010)  --
--      affs = { charm = { endsAt = <epoch|nil> }, shielded = {...}, ... },  --
--    }                                                                      --
--                                                                           --
--  PvP-inert: everything keys off NUMERIC denizen ids (player targets are   --
--  strings) and reads `ataxia.denizensHere`, never `playersHere`.           --
--                                                                           --
--  Pure logic + a data-driven affliction spec; timers/triggers that feed it --
--  live in update_stuff/003, 010_Prompt_Running, and the denizen-line       --
--  triggers. Unit-tested in tests/test_denizen_state.lua (inject `now`).    --
-------------------------------------------------------------------------------

ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.denizenState = ataxiaTemp.denizenState or {}

-- Data-driven battlerage-affliction spec (durations from AB ATTAINMENT).
--   dur         = seconds the aff lasts (nil = count-based / until an "ends" line)
--   role        = coarse tactical class (documentation + future rotation use)
--   exploitedBy = the kind of attack that gains BONUS DAMAGE while this is up
--                 ("headstrike" | "burst" | "shatter" | "fire" | nil)
--   apply/ends  = game-line regex captures; nil = TODO (fill as we capture lines live)
--
-- Only CHARM's lines are confirmed so far. The other nine are declared with their
-- real durations so expiry works the moment we add an apply pattern -- adding an
-- affliction is then just filling `apply`/`ends` here + one trigger pattern.
ataxiaBasher_BR_AFFS = {
  charm        = { dur = 5,   role = "swap",     exploitedBy = nil,
                   apply = "eyes glaze over as they stay their hand",
                   ends  = "forces clarity back into their mind" },
  stun         = { dur = 4,   role = "safe",     exploitedBy = nil,
                   apply = "hurl a precise blast of Shin energy at",
                   ends  = "is no longer stunned" },
  weakness     = { dur = 7,   role = "safe",     exploitedBy = nil,
                   apply = "in several key locations with your blade, causing",
                   ends  = "stands up straight, having overcome the weakness" },
  aeon         = { dur = 6,   role = "safe",     exploitedBy = nil,   apply = nil, ends = nil },
  clumsy       = { dur = 7,   role = "safe",     exploitedBy = nil,
                   apply = "finding the link to fine motor control",
                   ends  = nil },
  feared       = { dur = 8,   role = "fleerisk", exploitedBy = "headstrike", apply = nil, ends = nil },
  sensitivity  = { dur = 8,   role = "burst",    exploitedBy = "burst",      apply = nil, ends = nil },
  recklessness = { dur = 15,  role = "noshield", exploitedBy = "headstrike",
                   apply = "puffs up their chest and rushes headlong into danger",
                   ends  = "Caution returns to" },
  inhibit      = { dur = 9,   role = "burst",    exploitedBy = "burst",
                   apply = "with the tips of your fingers, targeting specific nerves",
                   ends  = nil },
  amnesia      = { dur = nil, role = "safe",     exploitedBy = nil,   apply = nil, ends = nil },
}

-- Non-affliction states also tracked per denizen (same `affs` table, no duration --
-- cleared by an explicit line): shielded (exploit: Shatter), ablaze (exploit: fire /
-- keep Infuse Fire up), confused (info only).

local function dsNow(now)
  if now ~= nil then return now end
  return getEpoch()
end

-- Numeric-id guard: player targets are strings, so this makes the whole layer inert
-- in PvP without any explicit PvP checks.
local function numId(id)
  return tonumber(id)
end

function ataxiaBasher_dsReset()
  ataxiaTemp.denizenState = {}
end

function ataxiaBasher_dsGet(id)
  id = numId(id)
  return id and ataxiaTemp.denizenState[id] or nil
end

function ataxiaBasher_dsAdd(id, name)
  id = numId(id)
  if not id then return end
  local st = ataxiaTemp.denizenState
  if st[id] then st[id].name = name or st[id].name
  else st[id] = { name = name, hpp = nil, affs = {} } end
  return st[id]
end

function ataxiaBasher_dsRemove(id)
  id = numId(id)
  if id then ataxiaTemp.denizenState[id] = nil end
end

-- Reconcile the state table with a {id -> name} presence map (defaults to
-- ataxia.denizensHere): add newcomers, drop anyone no longer in the room. Preserves
-- existing affs/hp for denizens that persist.
function ataxiaBasher_dsSync(denizens)
  denizens = denizens or (ataxia and ataxia.denizensHere) or {}
  local st = ataxiaTemp.denizenState
  local present = {}
  for id, name in pairs(denizens) do
    local nid = numId(id)
    if nid then
      present[nid] = true
      if st[nid] then st[nid].name = name else st[nid] = { name = name, hpp = nil, affs = {} } end
    end
  end
  for id in pairs(st) do
    if not present[id] then st[id] = nil end
  end
end

-- HP% is only ever available for the CURRENT server target (the prompt's
-- `|(id|hp%)|` is composed by us from gmcp.IRE.Target.Info) -- fed from 010.
function ataxiaBasher_dsSetHp(id, hpp)
  local ds = ataxiaBasher_dsAdd(id)
  if ds then ds.hpp = tonumber(hpp) end
end

-- Set/refresh an affliction or state on a denizen. Duration comes from BR_AFFS
-- (nil -> endsAt nil -> lasts until an explicit clear, e.g. shielded/ablaze/charm-end).
function ataxiaBasher_dsSetAff(id, aff, now)
  -- Auto-create the entry (like dsSetHp) so an affliction is never silently dropped
  -- if the mob's dsSync hasn't landed yet. Returns nil for a non-numeric id (player),
  -- keeping this PvP-inert; any phantom id is pruned by the next dsSync.
  local ds = ataxiaBasher_dsAdd(id)
  if not ds then return end
  local spec = ataxiaBasher_BR_AFFS[aff]
  local dur = spec and spec.dur
  ds.affs[aff] = { endsAt = dur and (dsNow(now) + dur) or nil }
end

function ataxiaBasher_dsClearAff(id, aff)
  local ds = ataxiaBasher_dsGet(id)
  if ds then ds.affs[aff] = nil end
end

-- True if the denizen currently has `aff`. Lazy expiry on read: a timed aff whose
-- endsAt has passed is cleared and reported gone, so state self-heals even if the
-- game's "ends" line is missed.
function ataxiaBasher_dsHasAff(id, aff, now)
  local ds = ataxiaBasher_dsGet(id)
  if not (ds and ds.affs[aff]) then return false end
  local endsAt = ds.affs[aff].endsAt
  if endsAt and dsNow(now) >= endsAt then
    ds.affs[aff] = nil
    return false
  end
  return true
end

function ataxiaBasher_dsIsCharmed(id, now)
  return ataxiaBasher_dsHasAff(id, "charm", now)
end

-- The best bonus-damage move available given this denizen's current state, or nil.
-- The rotation (Stage 2) checks this FIRST, so we cash in afflictions -- from ANY
-- source (our BR, proc boons, groupmates) -- for extra damage.
function ataxiaBasher_dsExploit(id, now)
  if ataxiaBasher_dsHasAff(id, "shielded", now) then return "shatter" end
  if ataxiaBasher_dsHasAff(id, "recklessness", now) or ataxiaBasher_dsHasAff(id, "feared", now) then return "headstrike" end
  if ataxiaBasher_dsHasAff(id, "sensitivity", now) or ataxiaBasher_dsHasAff(id, "inhibit", now) then return "burst" end
  if ataxiaBasher_dsHasAff(id, "ablaze", now) then return "fire" end
  return nil
end

-- Resolve a mob NAME (from an "ends" line that names the mob, not its id) to a
-- numeric id present in `denizens`. 0 matches -> nil (players/stale no-op); 1 -> it;
-- many -> prefer one carrying `preferAff` (e.g. resolve a charm-end to a charmed id),
-- else the first. Documented MVP limitation for two identically-named charmed mobs.
function ataxiaBasher_dsResolveNameToId(name, denizens, preferAff, now)
  if type(name) ~= "string" then return nil end
  denizens = denizens or (ataxia and ataxia.denizensHere) or {}
  local lower = name:lower()
  local matches = {}
  for id, nm in pairs(denizens) do
    local nid = numId(id)
    if nid and type(nm) == "string" and nm:lower() == lower then matches[#matches + 1] = nid end
  end
  if #matches == 0 then return nil end
  if #matches == 1 then return matches[1] end
  if preferAff then
    for _, id in ipairs(matches) do
      if ataxiaBasher_dsHasAff(id, preferAff, now) then return id end
    end
  end
  return matches[1]
end

-- Pick a different valid denizen id to swap to (charm-swap): not `excludeId`, not an
-- own pet/summon, and (optionally) not itself charmed. nil when none -- caller then
-- keeps hitting the charmed mob so the room can still progress.
function ataxiaBasher_dsPickAlt(denizens, excludeId, excludeCharmed, now)
  denizens = denizens or (ataxia and ataxia.denizensHere) or {}
  excludeId = numId(excludeId)
  for id, nm in pairs(denizens) do
    local nid = numId(id)
    if nid and nid ~= excludeId then
      local own = false
      if ataxiaBasher_isOwnDenizen then
        local ok, res = pcall(ataxiaBasher_isOwnDenizen, nm)
        own = ok and res == true
      end
      if not own and not (excludeCharmed and ataxiaBasher_dsHasAff(nid, "charm", now)) then
        return nid
      end
    end
  end
  return nil
end

-- Visibility: colour the current triggering game line and echo a short tag to the bash
-- console, so what our attacks are doing to the mob (charm, recklessness, weakness, …)
-- stands out in the combat spam. Gated on ataxiaBasher.brAlerts (default on) so it can be
-- toggled off. All Mudlet UI calls are guarded so it's a no-op in the test harness.
ataxiaBasher = ataxiaBasher or {}
if ataxiaBasher.brAlerts == nil then ataxiaBasher.brAlerts = true end

function ataxiaBasher_dsAlert(msg, colour)
  if not ataxiaBasher.brAlerts then return end
  colour = colour or "yellow"
  if selectString and fg and resetFormat and type(line) == "string" and line ~= "" then
    pcall(function() selectString(line, 1); fg(colour); resetFormat() end)
  end
  -- pcall-guarded: cecho throws on an unknown colour tag, and a single typo'd colour
  -- name would otherwise error on EVERY alert (stun/Daze fires constantly in Mnemosyne).
  if cecho then
    pcall(cecho, "\n<a_darkcyan>(<a_darkmagenta>BR<a_darkcyan>): <" .. colour .. ">" .. tostring(msg))
  end
end

-- Debug/validation: dump the live per-denizen state so you can watch capture work.
function ataxiaBasher_dsStatus()
  local st = ataxiaTemp.denizenState or {}
  local n = 0
  for id, ds in pairs(st) do
    n = n + 1
    local affs = {}
    for a in pairs(ds.affs or {}) do affs[#affs + 1] = a end
    local line = "  [" .. tostring(id) .. "] " .. tostring(ds.name)
      .. (ds.hpp and (" (" .. ds.hpp .. "%)") or "")
      .. (#affs > 0 and (" <" .. table.concat(affs, ",") .. ">") or "")
    if cecho then cecho("\n" .. line) else print(line) end
  end
  local header = "denizenState: " .. n .. " denizen(s)"
  if cecho then cecho("\n<a_darkcyan>" .. header) else print(header) end
end

