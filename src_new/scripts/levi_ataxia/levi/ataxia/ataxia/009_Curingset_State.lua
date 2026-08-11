--[[mudlet
type: script
name: Curingset State
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
- Priority-related
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- KNOWING WHAT CURING SETS ACTUALLY EXIST (v4.7.247)
--
-- Until now nothing in this package could answer "does that curingset exist?", and two
-- systems needed the answer badly:
--
--   * ataxia_bashProfileInstall (008) fired `curingset new bash` / `curingset switch bash`
--     and then wrote ~55 `curing priority` commands on timers, ASSUMING both worked. They
--     can both fail -- there is a hard cap on curing sets, and a live capture shows the
--     account at "a total of 22 of your allowed 22". When `new` fails the `switch` fails
--     too, the active set is still the PvP one, and those 55 priority writes land in it.
--     That is the curingset write hazard this codebase has warned about since v4.7.172,
--     firing on the one code path that bypasses the guarded writer
--     (ataxia_sendCuringPriority) by calling send() directly. It then set `installed = true`
--     regardless, so every later basher-enable sent `curingset switch bash` into the void.
--
--   * classDetect.setup() sends `curingset new` for all 27 mapped sets, silently
--     (`send(..., false)`), against a 22 cap. It cannot ever fully succeed and never says so.
--
-- The list output is fully captured (user, 2026-08-10):
--
--   Your current curing sets
--   --------------------------------------------------------------------------------
--   normal (current)
--   slowcuring
--   ...
--   You are using a total of 22 of your allowed 22 curing sets.
--
-- so this parses exactly that, and nothing guesses.
--
-- CAPTURED WITH TEMP TRIGGERS, NOT PERMANENT ONES. A set-name row is a bare lowercase word
-- on its own line, which as a permanent trigger would match an enormous amount of unrelated
-- game text. Temp triggers armed only when WE asked for the list, torn down on completion or
-- timeout, cannot false-positive on anything.

ataxia = ataxia or {}
ataxia.curingsets = ataxia.curingsets or {
  list = {},        -- ordered set names as the game printed them (duplicates preserved)
  set = {},         -- name -> count, so duplicates are visible
  current = nil,    -- the name marked "(current)"
  used = nil,       -- from the total line
  allowed = nil,
  at = nil,         -- epoch of the last successful parse
}

local function now()
  return (getEpoch and getEpoch()) or os.time()
end

-- ---------------------------------------------------------------------------
-- Pure parser -- given the captured lines, produce the state. Unit-tested.
-- ---------------------------------------------------------------------------
-- Returns nil when the block never reached its total line: a half-read list is worse than
-- no list, because every caller treats "not in the list" as "does not exist" and would
-- happily create a duplicate or refuse a set that is really there.
function ataxia_parseCuringsetList(lines)
  if type(lines) ~= "table" then return nil end
  local out = { list = {}, set = {}, current = nil, used = nil, allowed = nil }
  local started, finished = false, false
  for _, raw in ipairs(lines) do
    local line = tostring(raw or ""):gsub("%s+$", "")
    if line:match("^Your current curing sets%s*$") then
      started = true
    elseif started then
      local used, allowed = line:match("^You are using a total of (%d+) of your allowed (%d+) curing sets%.$")
      if used then
        out.used, out.allowed = tonumber(used), tonumber(allowed)
        finished = true
        break
      end
      if not line:match("^[%-]+$") and line ~= "" then
        -- A row is a bare set name, optionally flagged "(current)".
        local name, cur = line:match("^([%a][%w_%-]*)%s*(%(current%))$")
        if not name then name = line:match("^([%a][%w_%-]*)$") end
        if name then
          name = name:lower()
          out.list[#out.list + 1] = name
          out.set[name] = (out.set[name] or 0) + 1
          if cur then out.current = name end
        end
      end
    end
  end
  if not finished then return nil end
  return out
end

-- ---------------------------------------------------------------------------
-- Live refresh
-- ---------------------------------------------------------------------------
local CAPTURE_TIMEOUT = 4

local function teardown()
  if ataxia._csCollectT then pcall(killTrigger, ataxia._csCollectT); ataxia._csCollectT = nil end
  if ataxia._csEndT then pcall(killTrigger, ataxia._csEndT); ataxia._csEndT = nil end
  if ataxia._csTimer then pcall(killTimer, ataxia._csTimer); ataxia._csTimer = nil end
end

local function finish(ok)
  teardown()
  local cbs = ataxia._csCallbacks or {}
  ataxia._csCallbacks = nil
  local parsed = ok and ataxia_parseCuringsetList(ataxia._csLines or {}) or nil
  if parsed then
    ataxia.curingsets.list = parsed.list
    ataxia.curingsets.set = parsed.set
    ataxia.curingsets.current = parsed.current
    ataxia.curingsets.used = parsed.used
    ataxia.curingsets.allowed = parsed.allowed
    ataxia.curingsets.at = now()
  end
  ataxia._csLines = nil
  for _, cb in ipairs(cbs) do pcall(cb, parsed) end
end

-- Ask the game and call back with the parsed state (or nil on timeout / malformed output).
-- Concurrent callers share one request rather than racing two captures for one reply.
function ataxia_curingsetRefresh(cb)
  if type(cb) == "function" then
    if ataxia._csCallbacks then
      table.insert(ataxia._csCallbacks, cb)
      return -- a capture is already in flight; it will call everyone
    end
    ataxia._csCallbacks = { cb }
  else
    ataxia._csCallbacks = ataxia._csCallbacks or {}
  end
  teardown()
  ataxia._csLines = {}
  ataxia._csCollectT = tempRegexTrigger("^(.*)$", function()
    if ataxia._csLines then table.insert(ataxia._csLines, matches[2] or line or "") end
  end)
  ataxia._csEndT = tempRegexTrigger("^You are using a total of \\d+ of your allowed \\d+ curing sets\\.$", function()
    -- The collector above already recorded this line; parse on the next tick so ordering
    -- between the two temp triggers cannot matter.
    tempTimer(0, function() finish(true) end)
  end)
  ataxia._csTimer = tempTimer(CAPTURE_TIMEOUT, function()
    ataxia._csTimer = nil
    finish(false)
  end)
  send("curingset list", false)
end

-- ---------------------------------------------------------------------------
-- Queries. All answer nil when we have never parsed a list -- "unknown" is a THIRD
-- answer and callers must not read it as "no". A caller that treats unknown as no will
-- create a set that already exists (burning one of a hard-capped 22) or refuse one that
-- does; both were live bugs.
-- ---------------------------------------------------------------------------
function ataxia_curingsetKnown()
  return ataxia.curingsets and ataxia.curingsets.at ~= nil
end

function ataxia_curingsetHas(name)
  if not ataxia_curingsetKnown() then return nil end
  if type(name) ~= "string" then return false end
  return (ataxia.curingsets.set[name:lower()] or 0) > 0
end

function ataxia_curingsetFull()
  if not ataxia_curingsetKnown() then return nil end
  local u, a = ataxia.curingsets.used, ataxia.curingsets.allowed
  if not (u and a) then return nil end
  return u >= a
end

function ataxia_curingsetFree()
  if not ataxia_curingsetKnown() then return nil end
  local u, a = ataxia.curingsets.used, ataxia.curingsets.allowed
  if not (u and a) then return nil end
  return math.max(0, a - u)
end

-- Names the game listed more than once. Duplicates are legal server-side but each one eats
-- a slot out of the cap, and `curingset switch <dupe>` is ambiguous.
function ataxia_curingsetDupes()
  local out = {}
  if not ataxia_curingsetKnown() then return out end
  for name, n in pairs(ataxia.curingsets.set) do
    if n > 1 then out[#out + 1] = { name = name, count = n } end
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

-- ---------------------------------------------------------------------------
-- Display
-- ---------------------------------------------------------------------------
function ataxia_curingsetReport()
  if not ataxiaEcho then return end
  if not ataxia_curingsetKnown() then
    ataxiaEcho("No curingset list captured yet -- fetching...")
    return ataxia_curingsetRefresh(function(ok)
      if ok then ataxia_curingsetReport()
      elseif ataxiaEcho then ataxiaEcho("<red>Could not read CURINGSET LIST<reset> (no reply in " .. CAPTURE_TIMEOUT .. "s).") end
    end)
  end
  local cs = ataxia.curingsets
  local free = ataxia_curingsetFree() or 0
  ataxiaEcho("Curing sets: <white>" .. tostring(cs.used) .. "<reset>/<white>" .. tostring(cs.allowed)
    .. "<reset> used (" .. (free > 0 and ("<green>" .. free .. " free") or "<red>FULL") .. "<reset>)")
  for _, name in ipairs(cs.list) do
    local dupe = (cs.set[name] or 0) > 1
    cecho("\n  " .. (name == cs.current and "<green>* " or "<DimGrey>  ") .. "<white>" .. name
      .. (dupe and " <red>(listed " .. cs.set[name] .. "x -- wastes a slot)" or "") .. "<reset>")
  end
  local s = ataxia.settings and ataxia.settings.bashcuring
  if s and s.setname then
    local has = ataxia_curingsetHas(s.setname)
    cecho("\n  <NavajoWhite>bash profile set: <white>" .. s.setname
      .. (has and " <green>(present)" or " <red>(MISSING -- the PvE profile cannot switch to it)") .. "<reset>")
  end
  cecho("\n")
end
