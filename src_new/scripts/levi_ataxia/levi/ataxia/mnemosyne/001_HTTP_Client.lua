--[[mudlet
type: script
name: Mnemosyne HTTP Client
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
    MNEMOSYNE RUN TRACKER - HTTP CLIENT
    ============================================================================
    Serial POST queue for the Mnemosyne Run Tracker API.

    The API takes no auth header; every request is a POST whose JSON body
    carries a `token` field (added automatically here). Requests are sent one
    at a time -- the next only fires after sysPostHttpDone/sysPostHttpError for
    the previous -- so ordering is guaranteed (e.g. /ripple_level before the
    monsters/boss/effects for that ripple, /boons_offered before /boons_selected).

    A done/error event is only accepted if its URL matches the exact endpoint of
    the request at the queue head, and a per-request watchdog force-advances the
    queue if no response ever arrives (e.g. a POST silently redirected to GET, or
    a dropped response) so the queue can never stall permanently.

    Event handlers are registered as anonymous handlers so they survive
    uninstallPackage (same reasoning as ataxia.updater in misc_scripts/021).

    Loads BEFORE 002 (Reporter API) and 003 (Commands).
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

M.DEFAULT_URL = "http://104.128.56.238:8000"
M.REQUEST_TIMEOUT = 20 -- seconds before the watchdog force-advances a stuck request

-- Endpoints safe to auto-retry on error (no side effects if the original also
-- landed). Everything else is left alone to avoid double-posting a run/death/etc.
M._IDEMPOTENT = { ["/ripple_level"] = true, ["/run_exists"] = true }

-- ---------------------------------------------------------------------------
-- Config helpers
-- ---------------------------------------------------------------------------

-- Returns the persistent reporting config table, creating it if absent so
-- mutations (token/enabled toggles) survive ataxia_saveSettings().
function M._cfg()
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.reporting = ataxia.settings.reporting
    or { enabled = false, contemplate = true, url = M.DEFAULT_URL }
  return ataxia.settings.reporting
end

function M._baseUrl()
  local url = M._cfg().url
  if type(url) ~= "string" or url == "" then url = M.DEFAULT_URL end
  return (url:gsub("/+$", "")) -- trim trailing slashes
end

function M._hasToken()
  local t = M._cfg().token
  return type(t) == "string" and t ~= ""
end

-- True when automatic (trigger-driven) reporting should fire.
function M._auto()
  return M._cfg().enabled and M._hasToken()
end

-- True only when auto-reporting is on AND a run is actually in progress. Used to
-- gate the generic-sounding game-text handlers (monsters/effects/boons) so they
-- can't fire outside a tracked run.
function M._inRun()
  return M._auto() and M.run ~= nil and M.run.active == true
end

-- ---------------------------------------------------------------------------
-- Echo helpers
-- ---------------------------------------------------------------------------

function M.echo(msg)
  cecho("\n<a_darkcyan>(<a_darkmagenta>MNEM<a_darkcyan>): <NavajoWhite>" .. tostring(msg))
end

function M.decho(msg)
  if M._cfg().debug then
    cecho("\n<a_darkcyan>(<a_darkmagenta>MNEM<a_darkcyan>): <grey>" .. tostring(msg))
  end
end

-- ---------------------------------------------------------------------------
-- Serial POST queue
-- ---------------------------------------------------------------------------

M._queue = M._queue or {}
M._busy = false

-- Enqueue a POST. `payload` gets `token` stamped on automatically.
-- `onOk(parsed, rawBody)` is called with the decoded JSON response on success.
function M._enqueue(endpoint, payload, onOk)
  payload = payload or {}
  payload.token = M._cfg().token
  table.insert(M._queue, { endpoint = endpoint, payload = payload, onOk = onOk, tries = 0 })
  M._pump()
end

function M._clearWatchdog()
  if M._watchdog then
    pcall(killTimer, M._watchdog)
    M._watchdog = nil
  end
end

function M._pump()
  if M._busy then return end
  local req = M._queue[1]
  if not req then return end

  local ok, data = pcall(yajl.to_string, req.payload)
  if not ok then
    M.echo("<indian_red>Encode failed<reset> for " .. tostring(req.endpoint) .. " -- dropping.")
    table.remove(M._queue, 1)
    return M._pump()
  end

  M._busy = true
  M._clearWatchdog()
  M._watchdog = tempTimer(M.REQUEST_TIMEOUT, function()
    if M._busy then
      M.echo("<indian_red>Request timed out<reset>: " .. (M._queue[1] and M._queue[1].endpoint or "?"))
      M._finish()
    end
  end)
  postHTTP(data, M._baseUrl() .. req.endpoint, { ["Content-Type"] = "application/json" })
end

-- Drop the finished head request and advance the queue.
function M._finish()
  M._clearWatchdog()
  table.remove(M._queue, 1)
  M._busy = false
  M._pump()
end

-- Accept a done/error event only if its URL is the exact endpoint of the request
-- currently in flight (the queue head) -- guards against stray/duplicate events
-- or any ad-hoc postHTTP to the same host being misattributed to the head.
function M._matchesHead(url)
  if type(url) ~= "string" then return false end
  local req = M._queue[1]
  if not req then return false end
  return url == (M._baseUrl() .. req.endpoint)
end

function M._onDone(_, url, body)
  if not M._busy or not M._matchesHead(url) then return end
  M._clearWatchdog()
  local req = M._queue[1]

  local parsed
  if type(body) == "string" and body ~= "" then
    local pok, t = pcall(yajl.to_value, body)
    if pok then parsed = t end
  end

  if req then
    M.decho(req.endpoint .. " -> OK")
    if req.onOk then
      local cok, cerr = pcall(req.onOk, parsed, body)
      if not cok then M.echo("Callback error (" .. req.endpoint .. "): " .. tostring(cerr)) end
    end
  end

  M._finish()
end

function M._onError(_, err, url)
  if not M._busy or not M._matchesHead(url) then return end
  M._clearWatchdog()
  local req = M._queue[1]

  -- Retry once, but only for endpoints that are safe to repeat.
  if req and req.tries < 1 and M._IDEMPOTENT[req.endpoint] then
    req.tries = req.tries + 1
    M._busy = false
    M.decho("Retrying " .. req.endpoint .. " (" .. tostring(err) .. ")")
    return M._pump()
  end

  M.echo("<indian_red>Request failed<reset>: " .. (req and req.endpoint or "?") .. " (" .. tostring(err) .. ")")
  M._finish()
end

-- ---------------------------------------------------------------------------
-- Health check (GET /health) -- used by `mnem test`
-- ---------------------------------------------------------------------------

function M.testHealth()
  local url = M._baseUrl() .. "/health"
  M.echo("Pinging " .. url .. " ...")
  getHTTP(url, {})
end

function M._onGetDone(_, url, body)
  if url ~= (M._baseUrl() .. "/health") then return end
  M.echo("<green>Health OK<reset>: " .. tostring(body))
end

function M._onGetError(_, err, url)
  if url ~= (M._baseUrl() .. "/health") then return end
  M.echo("<indian_red>Health check failed<reset>: " .. tostring(err))
end

-- ---------------------------------------------------------------------------
-- Register handlers (anonymous so they survive uninstallPackage)
-- ---------------------------------------------------------------------------

for _, h in ipairs({ "_hPostDone", "_hPostErr", "_hGetDone", "_hGetErr" }) do
  if M[h] then killAnonymousEventHandler(M[h]) end
end

M._hPostDone = registerAnonymousEventHandler("sysPostHttpDone", function(...) M._onDone(...) end)
M._hPostErr = registerAnonymousEventHandler("sysPostHttpError", function(...) M._onError(...) end)
M._hGetDone = registerAnonymousEventHandler("sysGetHttpDone", function(...) M._onGetDone(...) end)
M._hGetErr = registerAnonymousEventHandler("sysGetHttpError", function(...) M._onGetError(...) end)
