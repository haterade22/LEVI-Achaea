--[[mudlet
type: script
name: Fight Log
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- FIGHT LOG -- record our fights in full, for analysis (v4.7.418).
--
-- User: "we should add a way to log the fights and save them somewhere that you can analyse".
-- Mystor's logs (2026-10-11) showed what makes a log worth analysing: every line, in order, with the
-- time it arrived. They also showed what a client log loses: his client gagged his own attack lines,
-- and nothing in a client log says what we SENT (a `send(cmd, false)` prints nothing) or what our
-- tracker BELIEVED. This records all of it to <profile>/fightlogs/<date>_<time>_<Opponent>.log; in
-- the repo, `python tools/fightlog_import.py` files the logs into kb/raw/logs/ours/.
--
-- One row per event: "<HH:MM:SS.mmm> <kind> <text>". Kinds:
--   |     a game line (the text as the game sent it, gagged or not)
--   P     a prompt
--   >     a command we sent (every send, echoed or not, from the sysDataSendRequest event)
--   +aff  -aff   an affliction we gained / lost (GMCP Char.Afflictions)
--   +def  -def   a defence we gained / lost (GMCP Char.Defences)
--   +tar  -tar   our tracker gives the target an affliction / takes one away
--   #     a note (header, start, stop)
--
-- When it records:
--   * Automatically (`fightlog auto on`, the default) when a player attacks us (the class detector's
--     "attacker class detected"), or when we send a queued command ("queue add...") naming our target
--     while that target is a PLAYER in the room. PvE targets are numbers and denizens are not players,
--     so bashing is never recorded.
--   * By hand: `fightlog on [name]`.
-- When it stops: TAIL seconds after a kill, a death or an arena verdict; after `fightlog idle`
-- seconds (default 60) with nothing naming the opponent (automatic recordings only: one started by
-- hand runs until `fightlog off`); at MAX_ROWS; or on disconnect. After an automatic stop the same
-- opponent cannot start a new recording for REARM seconds, so the last queued commands of a fight do
-- not open a second log.
--
-- Cost: the catch-all line trigger exists only while recording (the KB capture's pattern), and rows
-- are buffered and written every TICK seconds rather than one write per line.

ataxiaFight = ataxiaFight or {}
local F = ataxiaFight

F.IDLE = 60          -- default seconds with nothing naming the opponent before an automatic stop
F.TAIL = 3           -- seconds still recorded after a kill, death or arena verdict
F.TICK = 2           -- flush and idle-check period
F.REARM = 15         -- seconds after an automatic stop before the same opponent can start another
F.MAX_ROWS = 50000   -- safety cap per fight

local function cfg()
  ataxia = ataxia or {}
  ataxia.settings = ataxia.settings or {}
  ataxia.settings.fightlog = ataxia.settings.fightlog or {}
  local c = ataxia.settings.fightlog
  if c.auto == nil then c.auto = true end
  return c
end

-- Transient state lives on ataxiaTemp, never under the saved ataxia namespace (a recording, a trigger
-- id or a timer id restored from disk would name things that no longer exist).
local function st()
  ataxiaTemp = ataxiaTemp or {}
  return ataxiaTemp.fightlog
end

local function echo(msg)
  if ataxiaEcho then ataxiaEcho(msg) end
end

function F.now() return getEpoch() end
function F.dir() return getMudletHomeDir() .. "/fightlogs" end

-- Achaea prints a player's name capitalised ("Agathon"); a target may have been typed in any case.
function F.norm(name)
  if type(name) ~= "string" or name == "" then return nil end
  return name:sub(1, 1):upper() .. name:sub(2):lower()
end

local function stampOf(t)
  local s = math.floor(t)
  local ms = math.floor((t - s) * 1000 + 0.5)
  if ms > 999 then ms = 999 end
  return os.date("%H:%M:%S", s) .. string.format(".%03d", ms)
end

local function safeName(s)
  local n = tostring(s or ""):gsub("[^%w_%-]", "")
  return n ~= "" and n or "fight"
end

function F.isRecording() return st() ~= nil end

function F.write(kind, text)
  local s = st()
  if not s then return end
  if s.rows >= F.MAX_ROWS then
    if not s.endAt then s.endAt, s.endWhy = F.now(), "row cap (" .. F.MAX_ROWS .. ") reached" end
    return
  end
  s.rows = s.rows + 1
  s.buf[#s.buf + 1] = stampOf(F.now()) .. " " .. kind .. " " .. tostring(text)
end

function F.flush()
  local s = st()
  if not s or #s.buf == 0 then return end
  local f = io.open(s.path, "a")
  if not f then
    if not s.writeFailed then
      s.writeFailed = true
      echo("<red>Fight log<reset>: cannot write " .. s.path)
    end
    return
  end
  f:write(table.concat(s.buf, "\n") .. "\n")
  f:close()
  s.buf = {}
end

-- The lines that end a fight (all four seen in Mystor's arena logs, 2026-10-11).
local function isEnd(s, text)
  if text:find("You have been slain by ", 1, true) == 1 then return "we died" end
  if text:find("You have been defeated and are thrown out of the Arena", 1, true) == 1 then return "we lost (arena)" end
  if text:find("You have been victorious and leave the Arena", 1, true) == 1 then return "we won (arena)" end
  if s.opp and text:find("You have slain " .. s.opp, 1, true) == 1 then return "we killed " .. s.opp end
  return nil
end

function F.onLine(text, prompt)
  local s = st()
  if not s or type(text) ~= "string" then return end
  F.write(prompt and "P" or "|", text)
  if s.opp and text:find(s.opp, 1, true) then s.lastAt = F.now() end
  if not s.endAt then
    local why = isEnd(s, text)
    if why then s.endAt, s.endWhy = F.now() + F.TAIL, why end
  end
end

-- Is this name a player in our room? (ataxia.playersHere, from GMCP Room.Players; never us)
function F.playerHere(name)
  local n = F.norm(name)
  if not n or not (ataxia and type(ataxia.playersHere) == "table") then return false end
  for _, p in ipairs(ataxia.playersHere) do
    if F.norm(p) == n then return true end
  end
  return false
end

-- Should a command we send start a recording? A queued command naming our target, a player here.
function F.isAttack(cmd)
  if type(cmd) ~= "string" or type(target) ~= "string" or target == "" or tonumber(target) then return false end
  if not cmd:lower():find("^%s*queue add") then return false end
  if not cmd:lower():find(target:lower(), 1, true) then return false end
  return F.playerHere(target)
end

-- Not the same opponent again within REARM seconds of an automatic stop.
local function rearmed(opp)
  local last = ataxiaTemp and ataxiaTemp.fightlogStopped
  return not (last and last.opp == F.norm(opp) and F.now() - last.at < F.REARM)
end

function F.onSent(_, cmd)
  if type(cmd) ~= "string" then return end
  local s = st()
  if not s then
    if not (cfg().auto and F.isAttack(cmd) and rearmed(target)) then return end
    F.start(target, "our attack", true)
    s = st()
    if not s then return end
  end
  F.write(">", cmd)
  if s.opp and cmd:lower():find(s.opp:lower(), 1, true) then s.lastAt = F.now() end
end

function F.onAttacker(_, who, class)
  if F.isRecording() or not cfg().auto or not F.norm(who) or not rearmed(who) then return end
  F.start(who, "attacked by " .. tostring(class or "?"), true)
end

-- GMCP Add carries { name = ... }; Remove carries a list of names.
local function gmcpAdd(kind, t)
  if not F.isRecording() or type(t) ~= "table" then return end
  if t.name then F.write(kind, t.name) end
end

local function gmcpRemove(kind, t)
  if not F.isRecording() or type(t) ~= "table" then return end
  for _, n in ipairs(t) do F.write(kind, type(n) == "table" and n.name or n) end
end

function F.onAffAdd() gmcpAdd("+aff", gmcp and gmcp.Char and gmcp.Char.Afflictions and gmcp.Char.Afflictions.Add) end
function F.onAffRemove() gmcpRemove("-aff", gmcp and gmcp.Char and gmcp.Char.Afflictions and gmcp.Char.Afflictions.Remove) end
function F.onDefAdd() gmcpAdd("+def", gmcp and gmcp.Char and gmcp.Char.Defences and gmcp.Char.Defences.Add) end
function F.onDefRemove() gmcpRemove("-def", gmcp and gmcp.Char and gmcp.Char.Defences and gmcp.Char.Defences.Remove) end

-- The tracker's own events: "tar afflicted" carries a list, "target cured aff" one name.
function F.onTarAfflicted(_, affs)
  if not F.isRecording() then return end
  if type(affs) == "table" then
    if #affs > 0 then F.write("+tar", table.concat(affs, " ")) end
  elseif affs then
    F.write("+tar", affs)
  end
end

function F.onTarCured(_, aff)
  if F.isRecording() and aff then F.write("-tar", aff) end
end

-- One timer at a time, re-armed by each tick (the codebase's idiom). The next tick is armed BEFORE the
-- work, so an error in the work cannot stop the clock that ends the recording.
local function schedule()
  local s = st()
  if s and tempTimer then s.timer = tempTimer(F.TICK, function() F.tick() end) end
end

function F.tick()
  local s = st()
  if not s then return end
  schedule()
  F.flush()
  local now = F.now()
  if s.endAt and now >= s.endAt then return F.stop(s.endWhy or "fight over") end
  if s.auto then
    local idle = tonumber(cfg().idle) or F.IDLE
    if now - (s.lastAt or s.startedAt) > idle then
      return F.stop("nothing naming " .. tostring(s.opp) .. " for " .. idle .. " s")
    end
  end
end

function F.start(opp, reason, auto)
  if st() then return st().path end
  opp = F.norm(opp)
  local dir = F.dir()
  if lfs and lfs.mkdir then pcall(lfs.mkdir, dir) end
  local t = F.now()
  local name = os.date("%Y-%m-%d_%H%M%S", math.floor(t)) .. "_" .. safeName(opp) .. ".log"
  ataxiaTemp.fightlog = { path = dir .. "/" .. name, name = name, opp = opp, auto = auto and true or false,
    startedAt = t, lastAt = t, buf = {}, rows = 0 }
  local s = st()
  local ours = gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class
  s.buf[1] = "# LEVI fight log | version " .. tostring(ataxiaVersion) .. " | started "
    .. os.date("%Y-%m-%d %H:%M:%S", math.floor(t)) .. " | opponent " .. tostring(opp)
    .. " | our class " .. tostring(ours) .. " | " .. tostring(reason)
  s.buf[2] = "# rows: <time> <kind> <text>. kinds: | line, P prompt, > we sent, +aff/-aff ours (GMCP),"
    .. " +def/-def ours (GMCP), +tar/-tar our tracker on the target, # note"
  if tempRegexTrigger then
    s.trig = tempRegexTrigger("^", function() F.onLine(line, isPrompt and isPrompt() or false) end)
  end
  schedule()
  echo("<cyan>Fight log<reset> recording: " .. name)
  return s.path
end

function F.stop(reason)
  local s = st()
  if not s then return nil end
  if s.trig and killTrigger then killTrigger(s.trig) end
  if s.timer and killTimer then killTimer(s.timer) end
  s.buf[#s.buf + 1] = "# stopped: " .. tostring(reason) .. " | " .. s.rows .. " rows | "
    .. string.format("%.1f", F.now() - s.startedAt) .. " s"
  F.flush()
  ataxiaTemp.fightlog = nil
  ataxiaTemp.fightlogLast = s.path
  if s.auto then ataxiaTemp.fightlogStopped = { opp = s.opp, at = F.now() } end
  echo("<cyan>Fight log<reset> saved (" .. tostring(reason) .. "): " .. s.path)
  return s.path
end

function F.status()
  local c, s = cfg(), st()
  echo("<cyan>Fight log<reset>: " .. (s and ("<green>recording<reset> " .. s.name .. " (" .. s.rows .. " rows, "
    .. (s.auto and "automatic" or "by hand") .. ")") or "not recording")
    .. " | auto " .. (c.auto and "on" or "off") .. " | idle stop " .. tostring(tonumber(c.idle) or F.IDLE) .. " s")
  echo("  folder: " .. F.dir() .. (ataxiaTemp and ataxiaTemp.fightlogLast and ("  last: " .. ataxiaTemp.fightlogLast) or ""))
end

function F.command(arg)
  arg = arg or ""
  local c = cfg()
  local w1, rest = arg:match("^(%S*)%s*(.-)$")
  if w1 == "" or w1 == "status" then return F.status() end
  if w1 == "on" then
    local who = rest ~= "" and rest or (type(target) == "string" and not tonumber(target) and target) or nil
    return F.start(who, "started by hand", false)
  end
  if w1 == "off" then return F.stop("stopped by hand") end
  if w1 == "auto" and (rest == "on" or rest == "off") then
    c.auto = (rest == "on")
    return echo("<cyan>Fight log<reset> auto: " .. rest)
  end
  if w1 == "idle" and tonumber(rest) and tonumber(rest) > 0 then
    c.idle = tonumber(rest)
    return echo("<cyan>Fight log<reset> idle stop: " .. c.idle .. " s")
  end
  echo("Usage: fightlog [status | on [name] | off | auto on|off | idle <seconds>]")
end

-- Handlers live for the session. On a reload the old ones are killed first; their ids are kept on
-- ataxiaTemp, never saved.
ataxiaTemp = ataxiaTemp or {}
if ataxiaTemp.fightlogHandlers and killAnonymousEventHandler then
  for _, id in ipairs(ataxiaTemp.fightlogHandlers) do pcall(killAnonymousEventHandler, id) end
end
ataxiaTemp.fightlogHandlers = {}
if registerAnonymousEventHandler then
  local h = ataxiaTemp.fightlogHandlers
  local function on(event, fn) h[#h + 1] = registerAnonymousEventHandler(event, fn) end
  on("sysDataSendRequest", function(e, cmd) F.onSent(e, cmd) end)
  on("attacker class detected", function(e, who, class) F.onAttacker(e, who, class) end)
  on("gmcp.Char.Afflictions.Add", function() F.onAffAdd() end)
  on("gmcp.Char.Afflictions.Remove", function() F.onAffRemove() end)
  on("gmcp.Char.Defences.Add", function() F.onDefAdd() end)
  on("gmcp.Char.Defences.Remove", function() F.onDefRemove() end)
  on("tar afflicted", function(e, affs) F.onTarAfflicted(e, affs) end)
  on("target cured aff", function(e, aff) F.onTarCured(e, aff) end)
  on("sysDisconnectionEvent", function() F.stop("disconnected") end)
end
