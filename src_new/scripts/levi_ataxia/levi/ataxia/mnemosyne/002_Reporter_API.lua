--[[mudlet
type: script
name: Mnemosyne Reporter API
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    MNEMOSYNE RUN TRACKER - REPORTER API
    ============================================================================
    One thin function per API endpoint, plus in-memory run state.

    These are the mechanism; they fire whenever a token is set (so manual `mnem`
    commands work even with auto-reporting off). Triggers gate on M._auto()/
    M._inRun() before calling these.

    Run state is intentionally in-memory only -- on load we re-sync via
    /run_exists rather than persisting it (the server is the source of truth).

    Depends on 001_HTTP_Client.lua (loads first).
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

M.run = M.run or { active = false, publicId = nil, ripple = 0 }
M.run.pendingMonsters = M.run.pendingMonsters or {} -- buffered mob spawn lines
M.run.lastOffered = M.run.lastOffered or {} -- canonical names from the last boons-offered block

-- Reset all per-run buffers/counters. Called synchronously at run start/end so a
-- fast first GO!/wade-status can never hit a stale ripple guard or flush a
-- previous run's leftover monsters.
function M._resetRun()
  M.run.ripple = 0
  M.run.publicId = nil
  M.run.pendingMonsters = {}
  M.run.lastOffered = {}
end

-- Send any buffered monster spawns as one combined string, then clear.
function M._flushMonsters()
  local pm = M.run.pendingMonsters
  if type(pm) == "table" and #pm > 0 then
    M.reportMonsters(table.concat(pm, "; "))
  end
  M.run.pendingMonsters = {}
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function M.startRun()
  if not M._hasToken() then return M.decho("startRun skipped (no token)") end
  -- Optimistic, synchronous local reset (don't wait for the async response).
  M.run.active = true
  M._resetRun()
  M._enqueue("/run_start", {}, function(parsed)
    if parsed and parsed.public_id then
      M.run.publicId = parsed.public_id
      M.echo("<green>Run started<reset> (id: " .. tostring(parsed.public_id) .. ")")
    else
      M.echo("Run started, but response had no public_id.")
    end
  end)
end

-- Resume detection: ask the server whether a run is already in progress and
-- sync our ripple to it. Safe to call on load or when enabling mid-run.
function M.runExists()
  if not M._hasToken() then return end
  M._enqueue("/run_exists", {}, function(parsed)
    if parsed and parsed.exists then
      M.run.active = true
      M.run.ripple = tonumber(parsed.ripple) or M.run.ripple or 0
      M.decho("Resumed in-progress run at ripple " .. tostring(M.run.ripple))
    else
      M.run.active = false
    end
  end)
end

function M.endRun()
  if not M._hasToken() then return M.decho("endRun skipped (no token)") end
  -- Flush any final-wave monsters before closing the run.
  M._flushMonsters()
  M._enqueue("/run_end", {}, function()
    M.echo("<green>Run ended.")
  end)
  -- Reset locally right away; the run is over regardless of the response.
  M.run.active = false
  M._resetRun()
end

-- ---------------------------------------------------------------------------
-- Per-ripple reporting
-- ---------------------------------------------------------------------------

-- The API errors if ripple < current and no-ops if ==, so guard locally too.
function M.setRipple(n)
  n = tonumber(n)
  if not n then return end
  if not M._hasToken() then return end
  if M.run.ripple and n <= M.run.ripple then
    return M.decho("Ripple " .. n .. " <= current " .. tostring(M.run.ripple) .. ", skipping")
  end
  M._enqueue("/ripple_level", { ripple = n }, function()
    M.run.ripple = n
    M.decho("Ripple -> " .. n)
  end)
end

function M.reportMonsters(str)
  if not M._hasToken() then return end
  if type(str) ~= "string" or str == "" then return end
  M._enqueue("/monsters", { monsters = str })
end

function M.reportBoss(name)
  if not M._hasToken() then return end
  if type(name) ~= "string" or name == "" then return end
  M._enqueue("/boss", { boss = name })
end

-- list: array of { name = <string>, description = <string> }
function M.reportEffects(list)
  if not M._hasToken() then return end
  if type(list) ~= "table" or #list == 0 then return end
  M._enqueue("/effects", { effects = list })
end

-- list: array of { name, description?, quote?, rarity?, num_echoes_possible? }
function M.reportBoonsOffered(list)
  if not M._hasToken() then return end
  if type(list) ~= "table" or #list == 0 then return end
  M._enqueue("/boons_offered", { offered = list })
end

-- names: string or array of strings
function M.reportBoonsSelected(names)
  if not M._hasToken() then return end
  if type(names) == "string" then names = { names } end
  if type(names) ~= "table" or #names == 0 then return end
  M._enqueue("/boons_selected", { selected = names })
end

function M.reportDeath(killer)
  if not M._hasToken() then return end
  M._enqueue("/death", { killer = (type(killer) == "string" and killer ~= "") and killer or "unknown" })
end

-- ---------------------------------------------------------------------------
-- Resume on load (~6s after boot, mirroring ataxia.updater's approach)
-- ---------------------------------------------------------------------------

if M._loadHandler then killAnonymousEventHandler(M._loadHandler) end
M._loadHandler = registerAnonymousEventHandler("sysLoadEvent", function()
  tempTimer(6, function()
    if ataxia.mnemosyne._auto() then ataxia.mnemosyne.runExists() end
  end)
end)
