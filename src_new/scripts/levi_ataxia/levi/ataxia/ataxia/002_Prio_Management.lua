--[[mudlet
type: script
name: Prio Management
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

-- Global curing priority throttle (5 commands/second limit per Announce #5450)
ataxia.prioThrottle = ataxia.prioThrottle or {
  commands = {},
  sentThisSecond = 0,
  windowStart = 0,
  MAX_PER_SECOND = 4,
}

-- `curing priority <aff> <n>` writes a STORED priority into whichever curingset is
-- active. While the PvE `bash` set is selected (ataxia/008_Bash_Curing_Profile.lua) any
-- such write would permanently mutate that set -- and worse, ataxia_restorePrio would
-- then put the PVP default back into the BASH set, so the profile silently rots one
-- affliction at a time across a hunting session. Every PvP swap that reaches here
-- (Damnation, the anti-class handlers, parshield, engage/disengage burning) is
-- meaningless against denizens anyway, so dropping them while bashing costs nothing.
--
-- Only stored AFFLICTION priorities are dropped. `curing priority defence ...` and the
-- health-vs-mana sip toggle (`curing priority health|mana`) still pass, and `curing
-- prioaff <aff>` -- the TEMPORARY prioritisation used by SLC's defensive reactions --
-- never routes through here at all.
-- STACK SUFFIXES: the pattern captures the base and swallows the count SEPARATELY rather
-- than widening the class to `([%a]+%d*)`, so the defence/health/mana exclusion below still
-- tests the BASE and nothing can slip through by carrying a digit. Letters-only was a real
-- hole: `curing priority burning5 9` did not match, so it passed this guard and landed in
-- whichever curingset was active. Reachable from the UI -- trigger 717 fills
-- ataxia.curingprio from the server's rows (ataxia_prioRowNames), so `burning5` becomes its own
-- key and ataxia_showPrios' [+]/[-] links write it straight back.
local function writesStoredAffPrio(cmd)
  if type(cmd) ~= "string" then return false end
  for part in cmd:gmatch("[^;]+") do
    -- No `$`: a multi-set command (`curing priority a 1 b 2 ...`, v4.7.403) is a stored write
    -- too, and its first pair is enough to classify it.
    local aff = part:match("^%s*curing%s+priority%s+(%a+)%d*%s+%d+")
    if aff then
      aff = aff:lower()
      if aff ~= "defence" and aff ~= "defense" and aff ~= "health" and aff ~= "mana" then
        return true, aff
      end
    end
  end
  return false
end

-- The server limit is 5 COMMANDS a second, not 5 sends. Several call sites batch with
-- semicolons -- the Firelord burn park is three, the Magi frozen/shivering swap is three --
-- and each used to cost a single slot, so a batch overlapping a `reset prios` could put 7+
-- commands into one second against a cap of 5. Overflow is dropped server-side with no
-- client-visible signal, and nothing in the package parses a rate-limit refusal, so the
-- symptom would have been priorities that silently did not apply.
local function commandCount(cmd)
  if type(cmd) ~= "string" then return 1 end
  local n = 0
  for _ in cmd:gmatch("[^;]+") do n = n + 1 end
  return math.max(1, n)
end

-- Whether a drain is running in this Lua state. It is not kept in ataxia.prioThrottle, because that
-- table is saved with `ataxia`. A loaded save can bring back queued commands that no timer drains,
-- and no send may pass the queue, so they would block every later write.
local drainArmed = false

local function armDrain()
  if drainArmed then return end
  drainArmed = true
  tempTimer(0.25, function() ataxia_drainPrioQueue() end)
end

-- Returns "sent", "queued", or nil when the bash guard dropped the write.
function ataxia_sendCuringPriority(cmd, silent)
  if ataxia_bashProfileActive and ataxia_bashProfileActive() then
    local blocked, aff = writesStoredAffPrio(cmd)
    if blocked then
      if ataxiaBasher_debug and ataxiaEcho then
        ataxiaEcho("[DBG] dropped stored priority write on the bash set: " .. tostring(aff))
      end
      return nil
    end
  end

  local now = getEpoch()
  local throttle = ataxia.prioThrottle
  if not drainArmed and #throttle.commands > 0 then throttle.commands = {} end

  if (now - throttle.windowStart) >= 1.0 then
    throttle.sentThisSecond = 0
    throttle.windowStart = now
  end

  -- `sentThisSecond == 0` lets an oversized batch through rather than queueing it forever:
  -- it cannot be split here, and holding it would be worse than one second slightly over.
  -- A send never passes the queue: a restore that passed its queued swap would land first, and the
  -- swap would stay up with nothing tracking it.
  local n = commandCount(cmd)
  if #throttle.commands == 0
     and (throttle.sentThisSecond == 0 or (throttle.sentThisSecond + n) <= throttle.MAX_PER_SECOND) then
    throttle.sentThisSecond = throttle.sentThisSecond + n
    send(cmd, silent or false)
    return "sent"
  else
    table.insert(throttle.commands, {cmd = cmd, silent = silent or false})
    armDrain()
    return "queued"
  end
end

-- Removes the stored writes still in the queue. At a switch they belong to the set we leave, and
-- with the bash set active they would land in it. Defence and health/mana writes stay.
local function dropQueuedStoredWrites()
  local throttle = ataxia.prioThrottle
  local kept = {}
  for _, entry in ipairs(throttle.commands) do
    local parts = {}
    for part in entry.cmd:gmatch("[^;]+") do
      if not writesStoredAffPrio(part) then parts[#parts + 1] = part end
    end
    if #parts > 0 then
      kept[#kept + 1] = { cmd = table.concat(parts, ";"), silent = entry.silent }
    end
  end
  throttle.commands = kept
end

function ataxia_drainPrioQueue()
  local throttle = ataxia.prioThrottle
  drainArmed = false
  if ataxia_bashProfileActive and ataxia_bashProfileActive() then dropQueuedStoredWrites() end

  local now = getEpoch()
  if (now - throttle.windowStart) >= 1.0 then
    throttle.sentThisSecond = 0
    throttle.windowStart = now
  end

  while #throttle.commands > 0 do
    local n = commandCount(throttle.commands[1].cmd)
    if not (throttle.sentThisSecond == 0
            or (throttle.sentThisSecond + n) <= throttle.MAX_PER_SECOND) then break end
    local entry = table.remove(throttle.commands, 1)
    throttle.sentThisSecond = throttle.sentThisSecond + n
    send(entry.cmd, entry.silent)
  end

  if #throttle.commands > 0 then armDrain() end
end

-- ONE PRIORITY LIST PER CURINGSET
--
-- The game keeps one priority list per curing set, and the user tunes each class set for what
-- that class can give. If Infernal can never give impatience, the infernal set holds impatience
-- low. ataxia.curingprio mirrors the ACTIVE set only. A restore on a class set puts back that
-- set's own value, read from the game, and never the table in 001.
--
-- ataxiaPrioSets is not saved with `ataxia`. A package reload and a connection keep everything but
-- the reads in flight. A swap that is up when the link drops is still up on the server, so its name
-- stays live and goes back at the next restore or switch.
--
-- On a class set with no baseline a swap does not go out, and a restore has only the file's value
-- (below) or does nothing. A swap with no value to come back to would stay up, and the next read would take it for the set's own value.
--
-- A Mudlet restart loses this table, so the live names and their own values also go to a small
-- file (below). Only a Lua state with no ataxiaPrioSets reads it.
local LIVE_FILE = "/ataxia_curingset_swaps.lua"

local function liveFilePath()
  return getMudletHomeDir() .. LIVE_FILE
end

-- Sorted, so equal content gives an equal string and an unchanged file is not written again.
local function liveFileSig(bySet)
  local setNames, parts = {}, {}
  for set in pairs(bySet) do setNames[#setNames + 1] = set end
  table.sort(setNames)
  for _, set in ipairs(setNames) do
    local affs = {}
    for aff in pairs(bySet[set]) do affs[#affs + 1] = aff end
    table.sort(affs)
    for _, aff in ipairs(affs) do parts[#parts + 1] = set .. ":" .. aff .. "=" .. bySet[set][aff] end
  end
  return table.concat(parts, ",")
end

-- A missing or damaged file costs only what it would have restored, so nothing is printed.
local function loadLiveFile(sets)
  local ok, data = pcall(function()
    local path = liveFilePath()
    if not io.exists(path) then return { live = {} } end
    local loaded = {}
    table.load(path, loaded)
    return loaded
  end)
  if not ok or type(data) ~= "table" or type(data.live) ~= "table" then return end
  local seeded = {}
  for set, names in pairs(data.live) do
    if type(set) == "string" and type(names) == "table" then
      for aff, value in pairs(names) do
        if type(aff) == "string" and type(value) == "number" then
          seeded[set] = seeded[set] or {}
          seeded[set][aff] = value
          sets.live[set] = sets.live[set] or {}
          sets.live[set][aff] = true
        end
      end
    end
  end
  sets.seeded = seeded
  sets.fileSig = liveFileSig(seeded)
end

local LIST_TIMEOUT = 3      -- seconds before we stop expecting a read's reply

-- Replies are overdue, so a line of the set we left can still come. Never shortens a longer window
-- (bashInstallWrite's).
local function holdLateLines(sets)
  sets.quietUntil = math.max(sets.quietUntil or 0, getEpoch() + LIST_TIMEOUT)
end

function ataxia_prioSetsReset()
  local old = ataxiaPrioSets
  if old then
    if old.lineTrigger then pcall(killTrigger, old.lineTrigger) end
    if old.timer then pcall(killTimer, old.timer) end
  end
  ataxiaPrioSets = {
    baseline = old and old.baseline or {},  -- set name -> { aff = value }, filled by our own reads and the user's writes
    live = old and old.live or {},          -- set name -> { aff = true }, swaps we wrote and the game has not confirmed back
    restoring = old and old.restoring or {},-- set name -> { aff = value }, a single restore on its way
    echoes = old and old.echoes or {},      -- aff -> list of { value =, from =, seq =, cancelled = }, lines still to come (addEcho)
    seeded = old and old.seeded or {},      -- set name -> { aff = value }, own values from the file, until that set's first read
    batchSeq = old and old.batchSeq or 0,   -- number of the last restore batch sent at a switch
    fileSig = old and old.fileSig or nil,   -- what the file holds
    offline = old and old.offline or nil,   -- the link is down, from sysDisconnectionEvent until levilogin
    unknown = old and old.unknown or nil,   -- from levilogin until we know which set the server is on
    quietUntil = old and old.quietUntil or nil, -- until then a line of unknown origin is not adopted
    pending = {},   -- reads we asked for and have not seen, oldest first: { set =, at =, stale =, upTo = }
    retries = {},   -- set name -> how many times this visit asked again for a read that never came
  }
  -- This empties the reads we were waiting for, so their window would end with them.
  if old and #old.pending > 0 then holdLateLines(ataxiaPrioSets) end
  if not old then loadLiveFile(ataxiaPrioSets) end
end
ataxia_prioSetsReset()

if ataxiaPrioSetsHandler then pcall(killAnonymousEventHandler, ataxiaPrioSetsHandler) end
ataxiaPrioSetsHandler = registerAnonymousEventHandler("sysConnectionEvent", "ataxia_prioSetsReset")

-- A send with no link is lost, and classDetect's combat timer keeps running. A socket connect is
-- not enough to clear this, because we are at the login prompt then. levilogin clears it.
function ataxia_prioLinkDown()
  ataxiaPrioSets.offline = true
end
if ataxiaPrioLinkHandler then pcall(killAnonymousEventHandler, ataxiaPrioLinkHandler) end
ataxiaPrioLinkHandler = registerAnonymousEventHandler("sysDisconnectionEvent", "ataxia_prioLinkDown")

local SERVER_PER_SECOND = 5 -- Announce #5450. prioThrottle.MAX_PER_SECOND stays one below it.
local READ_RETRIES = 3      -- how many times one visit asks again for a read that never came
local READ_RETRY_DELAY = 1.1 -- past the throttle's one-second window

local function activeSet()
  local cur = classDetect and classDetect.state and classDetect.state.currentCuringset
  if type(cur) == "string" and cur ~= "" then return cur:lower() end
  return "normal"
end

-- The set whose own values answer a restore. nil means the table in 001 answers: on normal, and
-- on the bash set, where ataxia_sendCuringPriority drops the write anyway.
local function classSetActive()
  if ataxia_bashProfileActive and ataxia_bashProfileActive() then return nil end
  local set = activeSet()
  if set == "normal" then return nil end
  return set
end

-- A stacked name with no entry of its own takes the family's BASE entry, the same answer SSC
-- itself uses at that count. Without the fallback, ataxia_restorePrio("burning3") built a nil
-- concat and threw.
local function lookup(values, aff)
  if values[aff] then return values[aff] end
  local base = aff:match("^(%a+)%d+$")
  return base and values[base] or nil
end

-- `seeded` holds only names left up at a restart. It answers until the first read of that set, and
-- it is never a baseline, so it opens no swap and does not stop that read.
local function restoreValue(set, aff)
  if set == "normal" then return lookup(ataxia_defaultCuringPrios(), aff) end
  local values = ataxiaPrioSets.baseline[set]
  if values then return lookup(values, aff) end
  local seeded = ataxiaPrioSets.seeded[set]
  return seeded and seeded[aff] or nil
end

-- What should this name be RESTORED to in the active set? nil means we do not know, and the caller
-- must not write. Deliberately NOT applied to ataxia_getPrio: that answers "what value does the
-- server hold for this exact name", and ApplySwaps/RestoreSwaps compare the two, so a fallback
-- there would make the equality test lie.
function ataxia_defaultPrioAff(aff)
	if type(aff) ~= "string" then return nil end
	-- Until levilogin has heard from the game the server may be on any set.
	if ataxiaPrioSets.unknown then return nil end
	-- Lowercased because ataxia_stackAff is case-insensitive and ataxia.curingprio is lowercase-keyed.
	return restoreValue(classSetActive() or "normal", aff:lower())
end

-- THE FILE
--
-- Live names and each one's own value, outside the saved `ataxia` table, the way classDetect keeps
-- its config. The next read after a restart must not take a swap that is still up for the set's
-- own value. A name on its way back counts until the game confirms it. The profile folder is synced
-- by OneDrive and fights change this often, so a change arms one timer and the write happens only
-- if the content differs.
local LIVE_WRITE_DELAY = 1
local liveWriteArmed = false

local function liveSnapshot()
  local sets, out = ataxiaPrioSets, {}
  local function put(set, aff, value)
    if type(value) ~= "number" then return end
    out[set] = out[set] or {}
    out[set][aff] = value
  end
  for set, names in pairs(sets.live) do
    for aff in pairs(names) do put(set, aff, restoreValue(set, aff)) end
  end
  for aff, list in pairs(sets.echoes) do
    for _, echo in ipairs(list) do
      if echo.from then put(echo.from, aff, echo.value) end
    end
  end
  return out
end

local function writeLiveFile()
  liveWriteArmed = false
  pcall(function()
    local bySet = liveSnapshot()
    local sig = liveFileSig(bySet)
    if sig == ataxiaPrioSets.fileSig then return end
    table.save(liveFilePath(), { live = bySet })
    ataxiaPrioSets.fileSig = sig
  end)
end

local function persistLive()
  if liveWriteArmed then return end
  liveWriteArmed = true
  tempTimer(LIVE_WRITE_DELAY, writeLiveFile)
end

-- WHAT A LINE MEANS
--
-- One line, "You have set the 'x' affliction to the N priority.", can arrive from the set we just
-- left, at any lag. `echoes` holds the lines we expect, per name, so none is adopted by the set we
-- are in. There are three kinds of entry:
--   from, seq  a name leaving that set at a switch. It is not live and not yet confirmed. Its line
--              takes it off for good. Left when the batch's replies are over, it goes back to
--              live[from], because the restore did not land, and stays as a plain entry.
--   cancelled  a single restore overtaken by a newer swap. Its line is old news and must take
--              neither a leaving name nor a newer restore's token.
--   plain      a swap's own line, or a line we no longer wait for.
-- A line is matched to a cancelled entry first, then a leaving one, then the oldest plain one. An
-- entry that never gets its line (a refused write, or one dropped from the queue) costs at most one
-- extra restore or one non-adoption of an equal value, so the oldest such entries can go.
local ECHOES_PER_NAME = 8

local function addEcho(aff, entry)
  local echoes = ataxiaPrioSets.echoes
  echoes[aff] = echoes[aff] or {}
  local list = echoes[aff]
  table.insert(list, entry)
  local i = 1
  while #list > ECHOES_PER_NAME and i <= #list do
    if list[i].from then i = i + 1 else table.remove(list, i) end
  end
end

local function takeEcho(aff, num)
  local sets = ataxiaPrioSets
  local list = sets.echoes[aff]
  if not list then return false end
  local hit, rank = nil, 0
  for i, echo in ipairs(list) do
    if echo.value == num then
      local r = echo.cancelled and 3 or echo.from and 2 or 1
      if r > rank then hit, rank = i, r end
    end
  end
  if not hit then return false end
  if list[hit].from then persistLive() end
  table.remove(list, hit)
  if #list == 0 then sets.echoes[aff] = nil end
  return true
end

-- `value` is what this swap writes. Its own line can still be on its way when we switch.
local function markLive(aff, value)
  local sets, set = ataxiaPrioSets, activeSet()
  aff = aff:lower()
  sets.live[set] = sets.live[set] or {}
  sets.live[set][aff] = true
  -- A new swap cancels any restore of that name still on its way, so that line must not clear the
  -- mark of this swap.
  local token = sets.restoring[set] and sets.restoring[set][aff]
  if token then
    addEcho(aff, { value = token, cancelled = true })
    sets.restoring[set][aff] = nil
  end
  addEcho(aff, { value = tonumber(value) })
  persistLive()
end

local function clearLive(aff)
  local sets = ataxiaPrioSets
  if sets.offline then return end
  local names = sets.live[activeSet()]
  if names then names[aff:lower()] = nil end
  persistLive()
end

-- ApplySwaps sends again on the next gain, so a swap held here only waits for the read.
local function swapAllowed()
  if ataxiaPrioSets.unknown then return false end
  local set = classSetActive()
  return not set or ataxiaPrioSets.baseline[set] ~= nil
end

function ataxia_setAffPrio(aff, num)
	if not swapAllowed() then return end
	prioWaitfor = prioWaitfor or {}
	if not prioWaitfor[aff] then
		prioWaitfor[aff] = tempTimer(1, [[ prioWaitfor["]]..aff..[["] = nil ]])
		-- nil means the bash guard dropped the write, so the server holds no swap.
		if ataxia_sendCuringPriority("curing priority "..aff.. " "..num, false) then
			markLive(aff, num)
		end
	end
end

-- A swap that cannot use ataxia_setAffPrio: two names in one send, or a second write to a name in
-- the same pass. It skips the one-second hold and still counts as live, so a switch puts it back.
-- The [+]/[-] links do not come here. Those are the user's own tuning, and a switch keeps them.
function ataxia_sendPrioSwap(cmd, silent)
  if not swapAllowed() then return nil end
  local result = ataxia_sendCuringPriority(cmd, silent)
  if not result then return nil end
  for part in cmd:gmatch("[^;]+") do
    local aff, value = part:match("^%s*curing%s+priority%s+(%a+%d*)%s+(%d+)%s*$")
    if aff and writesStoredAffPrio(part) then markLive(aff, value) end
  end
  return result
end

function ataxia_restorePrio(aff)
	ataxia.curingprio = ataxia.curingprio or {}
	prioWaitrestore = prioWaitrestore or {}
	-- No link, so the send would be lost and the swap would stay up with nothing tracking it.
	if ataxiaPrioSets.offline then return end

	-- The comparison and the SEND read the same source. A name we have no value for returns here
	-- instead of building "curing priority brokenhead nil".
	local def = ataxia_defaultPrioAff(aff)
	if not def then return end
	if ataxia_getPrio(aff) == def then return end
	if not prioWaitrestore[aff] then
		prioWaitrestore[aff] = tempTimer(1, [[ prioWaitrestore["]]..aff..[["] = nil ]])
		-- The name stays live until trigger 719 confirms this value (ataxia_prioTuned). A write can be
		-- refused or dropped at a switch, and then the swap is still up.
		if ataxia_sendCuringPriority("curing priority "..aff.." "..def) then
			local sets, set = ataxiaPrioSets, activeSet()
			sets.restoring[set] = sets.restoring[set] or {}
			sets.restoring[set][aff:lower()] = def
		end
	end
end

-- THE SWITCH, IN ONE SEND
--
-- The server runs a send's commands in order, so this order is the guarantee:
--   1. `curing priority a 1 b 2` puts back the swaps of the set we leave, while it is still active.
--   2. `curingset switch <name>`.
--   3. `curing priority list` reads the new set before any later swap write can land in it.
-- Our swaps go out after this send, so the list cannot hold them.

-- The replies to batches up to `upTo` are over. A send's replies come in order, so the header of
-- the read sent after a batch proves it. With no header, LIST_TIMEOUT does. Line 787 does not: it
-- names no write, and several can be outstanding.
local function settleLeaving(upTo)
  local sets = ataxiaPrioSets
  for aff, list in pairs(sets.echoes) do
    for _, echo in ipairs(list) do
      if echo.from and echo.seq <= upTo then
        sets.live[echo.from] = sets.live[echo.from] or {}
        sets.live[echo.from][aff] = true
        echo.from, echo.seq = nil, nil
      end
    end
  end
end

-- The multi-set command for the swaps of `set`. A swap we have no value for stays where it is.
local function restoreCommand(set)
  local sets = ataxiaPrioSets
  local names = sets.live[set]
  sets.live[set] = nil
  -- A single restore on its way prints in the set we move to. One dropped from the queue prints
  -- nothing, and the switch below puts its name back.
  for aff, value in pairs(sets.restoring[set] or {}) do addEcho(aff, { value = value }) end
  sets.restoring[set] = nil
  if not names then return nil end
  local prios = {}
  for aff in pairs(names) do prios[aff] = restoreValue(set, aff) end
  if next(prios) == nil then return nil end
  sets.batchSeq = sets.batchSeq + 1
  local seq = sets.batchSeq
  for aff, value in pairs(prios) do addEcho(aff, { value = value, from = set, seq = seq }) end
  tempTimer(LIST_TIMEOUT, function() settleLeaving(seq) end)
  return table.concat(ataxia_prioMassCommands(prios), ";")
end

local giveUpReads

-- The names of `set` a read must not take from the game. A name still live is a swap left up from
-- before a reload, a connection or a refused restore. A name still leaving is the same if its
-- restore is refused.
local function swappedNames(set)
  local sets, names = ataxiaPrioSets, {}
  for aff in pairs(sets.live[set] or {}) do names[aff] = true end
  for aff, list in pairs(sets.echoes) do
    for _, echo in ipairs(list) do
      if echo.from == set then names[aff] = true end
    end
  end
  return names
end

-- A read leaves now. Its clock starts here, or its reply could print.
local function expectRead(set, now)
  local sets = ataxiaPrioSets
  table.insert(sets.pending, { set = set, at = now, stale = swappedNames(set), upTo = sets.batchSeq })
  if sets.timer then pcall(killTimer, sets.timer) end
  sets.timer = tempTimer(LIST_TIMEOUT, giveUpReads)
end

-- A class set with no baseline blocks its swaps, so a read that gave way or was lost asks again.
-- A direct send: through the throttle queue the reply could outlive the read's clock.
local function readAgain(set, force)
  local sets = ataxiaPrioSets
  if classSetActive() ~= set or (sets.baseline[set] and not force) then return end
  local tries = (sets.retries[set] or 0) + 1
  if tries > READ_RETRIES then return end
  sets.retries[set] = tries

  local throttle = ataxia.prioThrottle
  local now = getEpoch()
  if (now - throttle.windowStart) >= 1.0 then
    throttle.sentThisSecond = 0
    throttle.windowStart = now
  end
  if throttle.sentThisSecond + 1 > SERVER_PER_SECOND then
    tempTimer(READ_RETRY_DELAY, function() readAgain(set, force) end)
    return
  end
  throttle.sentThisSecond = throttle.sentThisSecond + 1
  expectRead(set, now)
  send("curing priority list", false)
end

giveUpReads = function()
  local sets = ataxiaPrioSets
  sets.timer = nil
  if #sets.pending > 0 then holdLateLines(sets) end
  sets.pending = {}
  if sets.read then ataxia_prioListStop() end
  readAgain(activeSet())
end

-- classDetect's three switch sites call this, with the set we are leaving. A bash-set switch
-- has nothing of ours to put back and must not touch its stored writes, so it goes out alone.
function ataxia_switchCuringsetSend(name, from)
  local sets = ataxiaPrioSets
  if sets.offline then return end
  -- Stops a default-table send still on its timers (ataxia_sendDefaultPrios).
  ataxiaPrioGen = (ataxiaPrioGen or 0) + 1
  -- The server's set is known after this send. The set we leave is not, so nothing goes back to it.
  local wasUnknown = sets.unknown
  sets.unknown = nil
  if ataxia_bashProfileActive and ataxia_bashProfileActive() then
    send("curingset switch " .. name, false)
    -- This is where the server now is, so the way back must lead here: bash off would otherwise
    -- return the server to a set the state no longer names.
    ataxia.settings.bashcuring.restoreTo = name
    return
  end

  local throttle = ataxia.prioThrottle
  local set = name:lower()
  sets.retries[set] = nil
  dropQueuedStoredWrites()

  local now = getEpoch()
  if (now - throttle.windowStart) >= 1.0 then
    throttle.sentThisSecond = 0
    throttle.windowStart = now
  end

  local parts = {}
  local cost = 0
  local restore = not wasUnknown and restoreCommand(from or "normal") or nil
  if restore then
    parts[#parts + 1] = restore
    cost = commandCount(restore)
  end
  parts[#parts + 1] = "curingset switch " .. name
  -- The read gives way before a refusal. A refused write would fire trigger 787 and its re-send.
  if throttle.sentThisSecond + cost + 1 <= SERVER_PER_SECOND then
    parts[#parts + 1] = "curing priority list"
    cost = cost + 1
    expectRead(set, now)
  else
    -- Confirmations from the set we left can still arrive, and no pending read marks them.
    holdLateLines(sets)
    tempTimer(READ_RETRY_DELAY, function() readAgain(set) end)
  end
  throttle.sentThisSecond = throttle.sentThisSecond + cost

  -- Stale values must not guard a swap in the new set. ataxia_getPrio answers 0 until the list
  -- arrives. The one-second per-name holds belong to the old set too.
  ataxia.curingprio = {}
  prioWaitfor, prioWaitrestore = {}, {}

  send(table.concat(parts, ";"), false)
end

-- THE HIDDEN READ
--
-- The reply, from the capture kb/raw/live/curing-priority-list_normal_2026-10-10.txt:
--   Your affliction curing priorities for the priority set normal:
--   1:  brokenrightarm, brokenleftarm, latched, icebound
--   ...
--   18:
--   ...
--   Affs with priority 26 are ignored.
-- A row can wrap at the server's width. Its next line then holds only names, and the row before
-- it ends in a comma. A stacked name prints as `burning(5)`.
--
-- Each line has one owner: 716 the header, 717 a row with names, 718 the last line, and the
-- temporary trigger below everything else. The trigger is armed only inside a read, the same care
-- as 009_Curingset_State. It sees every line, so the window ends on the first line that is not
-- part of the list. A complete read fills the baseline. A cut read fills nothing: a half-read
-- list is worse than none.

local HEADER = "^Your affliction curing priorities for the priority set %S+:"
local TRAILER = "Affs with priority 26 are ignored."

-- The game prints `burning(5)`. Our key, and the form a write takes, is `burning5`.
function ataxia_prioRowNames(text)
  local names = {}
  for token in (text:gsub("%((%d+)%)", "%1")):gmatch("%w+") do
    names[#names + 1] = token:lower()
  end
  return names
end

local function fillRow(read, num, text)
  for _, aff in ipairs(ataxia_prioRowNames(text)) do read.rows[aff] = num end
  read.num = num
  read.comma = text:match(",%s*$") ~= nil
end

local function isNameList(text)
  local found = false
  for token in text:gmatch("[^,]+") do
    token = token:gsub("^%s+", ""):gsub("%s+$", "")
    if token ~= "" then
      if not (token:match("^%a%w*$") or token:match("^%a%w*%(%d+%)$")) then return false end
      found = true
    end
  end
  return found
end

local function dropReadTrigger()
  local sets = ataxiaPrioSets
  if sets.lineTrigger then pcall(killTrigger, sets.lineTrigger) end
  sets.lineTrigger = nil
  sets.read = nil
end

-- Ends the window. The chain would otherwise stay open for 99 lines and 717 would keep reading.
function ataxia_prioListStop()
  dropReadTrigger()
  setTriggerStayOpen("Curing Priority List", 0)
end

local function readLine()
  local read = ataxiaPrioSets.read
  if not read then return end
  local text = ((matches and matches[2]) or line or ""):gsub("%s+$", "")
  if text == TRAILER or text:match(HEADER) or text:match("^%d+:%s+%S") then return end
  if text:match("^%d+:$") then
    read.comma = false
    deleteLine()
  elseif read.comma and isNameList(text) then
    fillRow(read, read.num, text)
    deleteLine()
  else
    ataxia_prioListStop()
  end
end

-- Trigger 716. True when this is the reply to our own read, so the line is hidden and owned here.
-- A set we did not ask about is a list the user typed: it prints and changes no baseline.
function ataxia_prioListHeader(setName)
  local sets = ataxiaPrioSets
  if sets.read then dropReadTrigger() end
  if type(setName) ~= "string" then return false end
  setName = setName:lower()
  local now = getEpoch()
  for i, want in ipairs(sets.pending) do
    if want.set == setName and (now - want.at) < LIST_TIMEOUT then
      -- Older reads came back out of turn or not at all.
      for _ = 1, i do table.remove(sets.pending, 1) end
      settleLeaving(want.upTo)
      sets.read = { set = setName, rows = {}, num = 0, comma = false, stale = want.stale }
      sets.lineTrigger = tempRegexTrigger("^(.*)$", readLine)
      deleteLine()
      return true
    end
  end
  return false
end

-- Trigger 717.
function ataxia_prioListRow(num, text)
  local read = ataxiaPrioSets.read
  if not read then return false end
  fillRow(read, tonumber(num), text)
  deleteLine()
  return true
end

-- Trigger 718.
function ataxia_prioListEnd()
  local sets = ataxiaPrioSets
  local read = sets.read
  if not read then return false end
  deleteLine()
  -- The mirror takes what the server holds, so a stale swap still reads as up and a restore fires.
  local mirror = {}
  for aff, value in pairs(read.rows) do mirror[aff] = value end
  -- The baseline keeps the set's own value for a swap left up from before a reload, a connection,
  -- a restart or a refused restore.
  -- Names swapped since the ask count too: when a read was lost, a list the user typed answers it.
  local own = sets.baseline[read.set] or sets.seeded[read.set]
  if own then
    for aff in pairs(read.stale) do read.rows[aff] = own[aff] end
    for aff in pairs(swappedNames(read.set)) do read.rows[aff] = own[aff] end
  end
  sets.baseline[read.set] = read.rows
  sets.seeded[read.set] = nil
  -- A later switch may have gone out already: the mirror holds the active set only.
  if read.set == activeSet() then ataxia.curingprio = mirror end
  ataxia_prioListStop()
  return true
end

-- Trigger 719. A line can be an echo: a swap's or a restore's, from this set or the one we left, at
-- any lag, so it is taken by its name and number before anything else. Or it confirms a restore of
-- this visit, which is the only thing that ends a name's live mark. Otherwise a value set during a
-- visit is the set's own from now on, so a later swap and restore put back that value. Any other
-- line from the set we just left waits for the read.
function ataxia_prioTuned(aff, num)
  local sets = ataxiaPrioSets
  -- No capture shows how the game names a stack here. The list prints it as `burning(5)`.
  aff = aff:gsub("%((%d+)%)", "%1")
  if takeEcho(aff, num) then return end
  local tokens = sets.restoring[activeSet()]
  if tokens and tokens[aff] == num then
    tokens[aff] = nil
    clearLive(aff)
    return
  end
  if sets.unknown then return end
  local set = classSetActive()
  if not set or not sets.baseline[set] then return end
  if #sets.pending > 0 or sets.read then return end
  if sets.quietUntil and getEpoch() < sets.quietUntil then return end
  if sets.live[set] and sets.live[set][aff] then return end
  sets.baseline[set][aff] = num
end

-- LOGIN
--
-- A new Lua state starts with currentCuringset "normal", whatever the server is on. Six classes
-- switch to normal in levilogin and the rest do not, so until the game answers nothing may write.
function ataxia_prioLoginStart()
  ataxiaPrioSets.offline = nil
  ataxiaPrioSets.unknown = true
end

function ataxia_prioSetKnown()
  ataxiaPrioSets.unknown = nil
end

-- Called last in levilogin, so a reply cannot predate the login's own switch. It sends no switch.
function ataxia_prioLoginRead(tries)
  tries = tries or 1
  if not (classDetect and classDetect.state and ataxia_curingsetRefresh) then return end
  local gen, state = ataxiaPrioGen or 0, classDetect.state.currentCuringset
  ataxia_curingsetRefresh(function(cs)
    local sets = ataxiaPrioSets
    -- A switch since the ask has moved the server, so this answer is out of date.
    if (ataxiaPrioGen or 0) ~= gen or classDetect.state.currentCuringset ~= state then return end
    if ataxia_bashProfileActive and ataxia_bashProfileActive() then return end
    local cur = cs and cs.current
    if not cur then
      if not sets.unknown then return end
      if tries < 2 then return ataxia_prioLoginRead(tries + 1) end
      if ataxiaEcho then
        ataxiaEcho("Could not read the active curing set. Priority swaps stay off until the next class switch.")
      end
      return
    end
    -- The bash set is the profile's. Taken as a class set, our swaps would write into it.
    local bash = ataxia.settings and ataxia.settings.bashcuring
    if bash and bash.setname == cur then
      if sets.unknown and ataxiaEcho then
        ataxiaEcho("The server is on the bash curing set. Priority swaps stay off until the next class switch.")
      end
      return
    end
    sets.unknown = nil
    classDetect.state.currentCuringset = cur
    -- The saved cache is the list of the set that was active at the last save.
    if cur ~= state then ataxia.curingprio = {} end
    if cur ~= "normal" then
      sets.retries[cur] = nil
      readAgain(cur, true)
    end
  end, true)
end

-- The profile has let go of the server and named the set it went to, so that set is known now. 008
-- calls this after its send, once the profile reads as off. It sends no switch, and a read only
-- when that set is a class set, or its swaps would stay off for the visit.
function ataxia_prioBashReleased(name)
  local sets = ataxiaPrioSets
  -- With no link the send was lost and the server did not move.
  if not sets.unknown or sets.offline then return end
  if not (classDetect and classDetect.state) then return end
  local set = name:lower()
  local state = classDetect.state.currentCuringset
  sets.unknown = nil
  classDetect.state.currentCuringset = set
  if set ~= state then ataxia.curingprio = {} end
  if set ~= "normal" then
    sets.retries[set] = nil
    readAgain(set, true)
  end
end

function ataxia_showPrios(num)
	ataxiaEcho("Displaying our current curing priorities:")
	for prio = 1, num do
		for aff, num in pairs(ataxia.curingprio) do
			if num == prio then
				echo("\n")
				fg("green")
				echoLink(" [+]", [[ataxia_raisePrio("]]..aff..[[")]], "Raise "..aff.." to priority of "..(ataxia.curingprio[aff] + 1)..".",true)
				fg("red")
				echoLink(" [-]", [[ataxia_lowerPrio("]]..aff..[[")]], "Lower "..aff.." to priority of "..(ataxia.curingprio[aff] - 1)..".",true)
				cecho("<white>: <DimGrey>(<LightSlateGrey>"..prio.."<DimGrey>) <NavajoWhite>"..aff)
			end
		end	
	end
	send(" ")
end

function ataxia_getPrio(aff)
	if not ataxia.curingprio[aff] then
		return 0
	else
		return ataxia.curingprio[aff]
	end
end

function ataxia_raisePrio(aff, hide)
	-- A switch empties the cache, and this link can be older than that.
	if not ataxia.curingprio[aff] then return end
	local newprio = (ataxia.curingprio[aff] - 1)
	ataxia.curingprio[aff] = newprio
	ataxia_sendCuringPriority("curing priority "..aff.." "..newprio)

	if not hide then
		ataxiaEcho("Raised "..aff.." to a priority of "..newprio)
		ataxia_showPrios(newprio)
	end
end

function ataxia_lowerPrio(aff, hide)
	if not ataxia.curingprio[aff] then return end
	local newprio = (ataxia.curingprio[aff] + 1)
	ataxia.curingprio[aff] = newprio
	ataxia_sendCuringPriority("curing priority "..aff.." "..newprio)

	if not hide then
		ataxiaEcho("Lowered "..aff.." to a priority of "..newprio)
		ataxia_showPrios(newprio)
	end
end