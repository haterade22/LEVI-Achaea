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

    THE QUEUE IS SAVED TO DISK, AND A RELOAD MUST RESUME IT (v4.7.336)
    -------------------------------------------------------------------
    `M._queue` and `M._busy` hang off `ataxia.mnemosyne`, and `ataxia_saveSettings` writes
    `ataxia` WHOLESALE -- `sanitizeForSave` strips only functions, metatabled objects and GUI
    snapshots, so plain request tables and a boolean go straight to disk, and `deepMerge` lets
    the stored values WIN on load. One save landed while a POST was in flight, so `_busy = true`
    came back from disk with no request behind it and no watchdog timer to clear it: `_pump()`
    returned early forever, every later report appended silently, and each save wrote the wedge
    out again. The live save held 711 unsent requests -- about nine runs -- with no echo at all,
    because nothing ever failed; nothing was ever SENT.

    The fix treats the queue the way the user asked for it to be treated (replay, not drop):
      * `M._resumeQueue(why)` runs at the end of this file (reinstall / SYSUPDATE / XML reimport)
        and from `ataxia_loadSettings` right after the merge (restart). It clears `_busy` -- after
        a reload nothing is waiting on a response -- and pumps the queue IN ORDER. The request
        that was in flight is sent again, so delivery is AT-LEAST-ONCE.
      * The watchdog timer id, the in-flight stamp and the event-handler ids live on
        `ataxiaTemp.mnemHttp`, which is never serialized -- so any id found there is live and
        ours, and killing it can never hit a stranger's timer (the v4.7.192 rule).
      * `_pump` refuses to trust a `_busy` flag it cannot account for: busy with NO send stamp is
        a restored wedge (resume it), busy with a stamp older than `STALE_BUSY` means the watchdog
        was lost (time the head out, exactly as the watchdog would have).
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

M.DEFAULT_URL = "http://104.128.56.238:8000"
M.REQUEST_TIMEOUT = 20 -- seconds before the watchdog force-advances a stuck request
-- The BACKSTOP threshold. Strictly beyond the watchdog's, so it can only act once the watchdog has
-- had every chance and failed -- a backstop that fires first overrules the thing it backs up
-- (v4.7.280).
M.STALE_BUSY = 2 * M.REQUEST_TIMEOUT

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
-- Transient client state (NEVER on the saved namespace -- see the header)
-- ---------------------------------------------------------------------------

-- `ataxiaTemp` is never serialized, so everything here is from THIS session: a timer id is a live
-- timer of ours, a stamp is a send we actually made.
--   watchdog   -- tempTimer id guarding the in-flight request
--   sentAt     -- epoch of the in-flight request's send
--   hPostDone/hPostErr/hGetDone/hGetErr -- anonymous event-handler ids
--   replay     -- { ok, refused, failed, first } outcome counts for a resumed backlog
--   replayLeft -- resumed entries still in the queue
function M._http()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mnemHttp = ataxiaTemp.mnemHttp or {}
  return ataxiaTemp.mnemHttp
end

local function now()
  return (getEpoch and getEpoch()) or os.time()
end

-- ---------------------------------------------------------------------------
-- Serial POST queue
-- ---------------------------------------------------------------------------

M._queue = M._queue or {}

-- Enqueue a POST. `payload` gets `token` stamped on automatically.
-- `onOk(parsed, rawBody)` is called with the decoded JSON response on success.
function M._enqueue(endpoint, payload, onOk, onError)
  payload = payload or {}
  payload.token = M._cfg().token
  table.insert(M._queue, { endpoint = endpoint, payload = payload, onOk = onOk, onError = onError, tries = 0 })
  M._pump()
end

function M._clearWatchdog()
  local h = M._http()
  if h.watchdog then
    pcall(killTimer, h.watchdog)
    h.watchdog = nil
  end
end

-- A RESUMED BACKLOG REPORTS ONCE, NOT PER REQUEST. Replaying hundreds of requests from an earlier
-- session will draw refusals (a ripple lower than the server's current one, a death with no open
-- run), and a red line for each would bury the console mid-fight. Returns true when the outcome
-- was absorbed into the replay tally, so the caller skips its own echo; a request made in THIS
-- session is never absorbed.
function M._noteOutcome(req, kind, detail)
  if not (type(req) == "table" and req.replay) then return false end
  local h = M._http()
  h.replay = h.replay or { ok = 0, refused = 0, failed = 0 }
  h.replay[kind] = (h.replay[kind] or 0) + 1
  if kind ~= "ok" and h.replay.first == nil and detail then h.replay.first = detail end
  return true
end

-- One resumed entry has left the queue; the last one prints the tally.
function M._replayStep()
  local h = M._http()
  h.replayLeft = (tonumber(h.replayLeft) or 1) - 1
  if h.replayLeft > 0 then return end
  local r = h.replay or { ok = 0, refused = 0, failed = 0 }
  local bad = (r.refused or 0) + (r.failed or 0)
  M.echo((bad == 0 and "<green>" or "<gold>") .. "Backlog replay done<reset>: "
    .. tostring(r.ok or 0) .. " sent OK, " .. tostring(r.refused or 0) .. " refused, "
    .. tostring(r.failed or 0) .. " failed."
    .. (r.first and ("\n  <grey>first problem: " .. tostring(r.first)) or ""))
  h.replay, h.replayLeft = nil, nil
end

function M._pump()
  if M._busy then
    -- THE BUSY FLAG MUST BE ACCOUNTED FOR (v4.7.336). Busy is only true while a request of OURS
    -- is on the wire, and `_pump` stamps `sentAt` every time it puts one there.
    local sentAt = tonumber(M._http().sentAt)
    if sentAt == nil then
      -- Busy, but nothing was sent this session: the flag came back from disk (or from a code
      -- path that bypassed the resume). This is the wedge that silently held 711 requests.
      return M._resumeQueue("queue was stuck")
    end
    if (now() - sentAt) < (tonumber(M.STALE_BUSY) or 40) then return end -- genuinely in flight
    -- Sent, and still busy long after the watchdog should have fired: the watchdog timer was lost
    -- (killed by id, or never armed). Do exactly what it would have done.
    return M._onTimeout("watchdog lost")
  end
  local req = M._queue[1]
  if not req then return end

  -- The CURRENT token, not the one captured at enqueue time: a resumed entry can predate a
  -- `mnem token` change, and the token is who we are, not a property of the request.
  if type(req.payload) == "table" and M._hasToken() then req.payload.token = M._cfg().token end

  local ok, data = pcall(yajl.to_string, req.payload)
  if not ok then
    local detail = tostring(req.endpoint) .. " (encode failed)"
    if not M._noteOutcome(req, "failed", detail) then
      M.echo("<indian_red>Encode failed<reset> for " .. tostring(req.endpoint) .. " -- dropping.")
    end
    table.remove(M._queue, 1)
    if req.replay then M._replayStep() end
    return M._pump()
  end

  local h = M._http()
  M._busy = true
  h.sentAt = now()
  M._clearWatchdog()
  h.watchdog = tempTimer(M.REQUEST_TIMEOUT, function() M._onTimeout() end)
  postHTTP(data, M._baseUrl() .. req.endpoint, { ["Content-Type"] = "application/json" })
end

-- Invoke a request's onError callback (guarded). Used by BOTH the error event and
-- the watchdog, so a stuck/dropped request also triggers recovery (e.g. resetting
-- run.active after a /run_start whose response never arrives).
function M._fireError(req, err)
  if req and req.onError then
    local cok, cerr = pcall(req.onError, err)
    if not cok then M.decho("onError callback error (" .. tostring(req.endpoint) .. "): " .. tostring(cerr)) end
  end
end

-- Watchdog fired: the in-flight request never completed (dropped response, or a
-- POST silently redirected to GET). Treat it as a failure so onError runs, then
-- force the queue forward. `why` is set only by the `_pump` backstop.
function M._onTimeout(why)
  if not M._busy then return end
  local req = M._queue[1]
  local ep = (req and req.endpoint) or "?"
  if not M._noteOutcome(req, "failed", ep .. " (" .. tostring(why or "timeout") .. ")") then
    M.echo("<indian_red>Request timed out<reset>: " .. ep .. (why and (" (" .. tostring(why) .. ")") or ""))
  end
  M._fireError(req, why or "timeout")
  M._finish()
end

-- Drop the finished head request and advance the queue.
function M._finish()
  M._clearWatchdog()
  local req = table.remove(M._queue, 1)
  M._busy = false
  M._http().sentAt = nil
  if type(req) == "table" and req.replay then M._replayStep() end
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
    -- WHAT THE SERVER SAID, NOT JUST THAT IT ANSWERED (v4.7.298). Every endpoint returns
    -- `OkResponse { ok, message? }` and we were reading neither: an HTTP 200 carrying
    -- `ok: false` -- the server telling us the operation did NOT happen -- was logged as a
    -- success and never shown. `message` is the server's own explanation and is the only place
    -- a refusal reason can come from.
    --
    -- IT SURFACES, IT DOES NOT RE-ROUTE. `ok: false` deliberately still runs `onOk` rather than
    -- firing the error path, for the same reason the claim-confirmation line warns instead of
    -- un-latching (v4.7.278): we have never seen this server answer `ok: false`, so we do not
    -- know which conditions produce it -- and `startRun`'s onError undoes the optimistic
    -- `run.active`, which would silently stop all reporting for the dive on a guess. Promote it
    -- to the error path once a real `ok: false` has been observed and its meaning is known.
    local msg = (type(parsed) == "table") and parsed.message or nil
    local why = (type(msg) == "string" and msg ~= "") and msg or nil
    if type(parsed) == "table" and parsed.ok == false then
      if not M._noteOutcome(req, "refused", req.endpoint .. (why and (": " .. why) or "")) then
        M.echo("<indian_red>" .. req.endpoint .. " refused<reset>" .. (why and (": " .. why) or ""))
      end
    else
      M._noteOutcome(req, "ok")
      M.decho(req.endpoint .. " -> OK" .. (why and (" (" .. why .. ")") or ""))
    end
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
    M._http().sentAt = nil
    M.decho("Retrying " .. req.endpoint .. " (" .. tostring(err) .. ")")
    return M._pump()
  end

  local ep = (req and req.endpoint) or "?"
  if not M._noteOutcome(req, "failed", ep .. " (" .. tostring(err) .. ")") then
    M.echo("<indian_red>Request failed<reset>: " .. ep .. " (" .. tostring(err) .. ")")
  end
  M._fireError(req, err)
  M._finish()
end

-- ---------------------------------------------------------------------------
-- Resume / inspect / clear
-- ---------------------------------------------------------------------------

-- RESUME WHATEVER THE QUEUE HOLDS (v4.7.336). See the header for why this exists.
--
-- Called at the end of this file (package reinstall, SYSUPDATE, XML reimport) and from
-- `ataxia_loadSettings` right after the settings merge (a restart, where the queue comes back
-- from disk). Both are needed: on a fresh start this file runs FIRST, sees an empty queue, and the
-- loader then merges the saved wedge on top of it.
--
-- After a reload nothing is waiting on a response -- any answer to the old in-flight request went
-- to a previous session -- so `_busy` is cleared and the queue is sent again from its head, in
-- order. That head may already have reached the server, so delivery is at-least-once; replay
-- rather than drop was the user's call (2026-09-24), and every replayed row carries the time it
-- was replayed, not the time it happened.
--
-- A live watchdog is killed (it is on ataxiaTemp, so it is ours). The LEGACY `M._watchdog` is only
-- forgotten, never killed: it came back from disk and names whatever timer inherited that id.
function M._resumeQueue(why)
  M._clearWatchdog()
  M._watchdog = nil
  M._busy = false
  local h = M._http()
  h.sentAt = nil

  -- Keep only well-formed requests, in order. A restored table is plain data, so anything that is
  -- not a request with an endpoint cannot be sent and would only wedge `_pump` on the next pass.
  local q = {}
  if type(M._queue) == "table" then
    for _, req in ipairs(M._queue) do
      if type(req) == "table" and type(req.endpoint) == "string" then
        req.replay = true
        req.tries = tonumber(req.tries) or 0
        if type(req.payload) ~= "table" then req.payload = {} end
        q[#q + 1] = req
      end
    end
  end
  M._queue = q

  local n = #q
  if n == 0 then
    h.replay, h.replayLeft = nil, nil
    return 0
  end
  h.replay = h.replay or { ok = 0, refused = 0, failed = 0 }
  h.replayLeft = n
  M.echo("Resuming <white>" .. n .. "<reset> unsent tracker request" .. (n == 1 and "" or "s")
    .. " (" .. tostring(why or "reload") .. ") -- sending them in order.")
  M._pump()
  return n
end

-- A snapshot for `mnem status` / `mnem queue`: what is waiting, what is on the wire, and for how
-- long. `stale` is the one fact worth colouring: a request older than the watchdog, or a busy flag
-- with no send behind it.
function M.queueInfo()
  local h = M._http()
  local q = (type(M._queue) == "table") and M._queue or {}
  local head = q[1]
  local sentAt = tonumber(h.sentAt)
  local age = (M._busy and sentAt) and (now() - sentAt) or nil
  return {
    pending = #q,
    busy = M._busy == true,
    head = (type(head) == "table") and head.endpoint or nil,
    age = age,
    replayLeft = tonumber(h.replayLeft),
    stale = (M._busy == true) and (age == nil or age > (tonumber(M.REQUEST_TIMEOUT) or 20)),
  }
end

-- Pending requests grouped by endpoint, sorted by count (then name).
function M.queueCounts()
  local counts, order = {}, {}
  for _, req in ipairs((type(M._queue) == "table") and M._queue or {}) do
    local ep = (type(req) == "table" and req.endpoint) or "?"
    if not counts[ep] then counts[ep] = 0; order[#order + 1] = ep end
    counts[ep] = counts[ep] + 1
  end
  table.sort(order, function(a, b)
    if counts[a] ~= counts[b] then return counts[a] > counts[b] end
    return a < b
  end)
  return order, counts
end

-- The manual escape hatch (`mnem queue clear`): drop everything, including a resumed backlog.
-- A response still owed to the dropped head arrives while `_busy` is false and is ignored.
function M.queueClear()
  local n = (type(M._queue) == "table") and #M._queue or 0
  M._clearWatchdog()
  M._queue = {}
  M._busy = false
  local h = M._http()
  h.sentAt, h.replay, h.replayLeft = nil, nil, nil
  return n
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

-- The ids live on ataxiaTemp (v4.7.336). They used to be `M._hPostDone` etc. -- on the saved
-- namespace -- so a restart restored the PREVIOUS session's ids over the live ones, and the next
-- reinstall killed those instead of ours: the live handler survived next to the new one and every
-- response was handled twice (a same-endpoint request behind it could be finished before its own
-- answer arrived). The legacy key is still killed once here -- that is the migration for the
-- install that brings this version in, and exactly what every earlier reinstall already did.
do
  local h = M._http()
  local legacy = { hPostDone = "_hPostDone", hPostErr = "_hPostErr", hGetDone = "_hGetDone", hGetErr = "_hGetErr" }
  for key, old in pairs(legacy) do
    if h[key] then pcall(killAnonymousEventHandler, h[key]); h[key] = nil end
    if M[old] then pcall(killAnonymousEventHandler, M[old]); M[old] = nil end
  end
  h.hPostDone = registerAnonymousEventHandler("sysPostHttpDone", function(...) M._onDone(...) end)
  h.hPostErr = registerAnonymousEventHandler("sysPostHttpError", function(...) M._onError(...) end)
  h.hGetDone = registerAnonymousEventHandler("sysGetHttpDone", function(...) M._onGetDone(...) end)
  h.hGetErr = registerAnonymousEventHandler("sysGetHttpError", function(...) M._onGetError(...) end)
end

-- Reinstall / SYSUPDATE / XML reimport: resume anything already queued in memory. On a fresh start
-- the queue is empty here and this is a no-op; the loader's call after the merge does the work.
M._resumeQueue("package reloaded")
