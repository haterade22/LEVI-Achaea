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
-- ataxiaPrioSets is not saved. A package reload and a connection keep the baselines and the live
-- names and drop only the reads in flight. A swap that is up when the link drops is still up on the
-- server, so its name stays live and goes back at the next restore or switch.
--
-- On a class set with no baseline a swap does not go out and a restore does nothing. A swap with
-- no value to come back to would stay up, and the next read would take it for the set's own value.
function ataxia_prioSetsReset()
  local old = ataxiaPrioSets
  if old then
    if old.lineTrigger then pcall(killTrigger, old.lineTrigger) end
    if old.timer then pcall(killTimer, old.timer) end
  end
  ataxiaPrioSets = {
    baseline = old and old.baseline or {},  -- set name -> { aff = value }, filled by our own reads and the user's writes
    live = old and old.live or {},          -- set name -> { aff = true }, swaps we wrote and have not put back
    pending = {},   -- reads we asked for and have not seen, oldest first: { set =, at =, stale = }
    retries = {},   -- set name -> how many times this visit asked again for a read that never came
  }
end
ataxia_prioSetsReset()

if ataxiaPrioSetsHandler then pcall(killAnonymousEventHandler, ataxiaPrioSetsHandler) end
ataxiaPrioSetsHandler = registerAnonymousEventHandler("sysConnectionEvent", "ataxia_prioSetsReset")

local LIST_TIMEOUT = 3      -- seconds before we stop expecting a read's reply
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

local function restoreValue(set, aff)
  if set == "normal" then return lookup(ataxia_defaultCuringPrios(), aff) end
  return lookup(ataxiaPrioSets.baseline[set] or {}, aff)
end

-- What should this name be RESTORED to in the active set? nil means we do not know, and the caller
-- must not write. Deliberately NOT applied to ataxia_getPrio: that answers "what value does the
-- server hold for this exact name", and ApplySwaps/RestoreSwaps compare the two, so a fallback
-- there would make the equality test lie.
function ataxia_defaultPrioAff(aff)
	if type(aff) ~= "string" then return nil end
	-- Lowercased because ataxia_stackAff is case-insensitive and ataxia.curingprio is lowercase-keyed.
	return restoreValue(classSetActive() or "normal", aff:lower())
end

local function markLive(aff)
  local live, set = ataxiaPrioSets.live, activeSet()
  live[set] = live[set] or {}
  live[set][aff:lower()] = true
end

local function clearLive(aff)
  local names = ataxiaPrioSets.live[activeSet()]
  if names then names[aff:lower()] = nil end
end

-- ApplySwaps sends again on the next gain, so a swap held here only waits for the read.
local function swapAllowed()
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
			markLive(aff)
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
    local aff = part:match("^%s*curing%s+priority%s+(%a+%d*)%s+%d+%s*$")
    if aff and writesStoredAffPrio(part) then markLive(aff) end
  end
  return result
end

function ataxia_restorePrio(aff)
	ataxia.curingprio = ataxia.curingprio or {}
	prioWaitrestore = prioWaitrestore or {}

	-- The comparison and the SEND read the same source. A name we have no value for returns here
	-- instead of building "curing priority brokenhead nil".
	local def = ataxia_defaultPrioAff(aff)
	if not def then return end
	if ataxia_getPrio(aff) == def then return end
	if not prioWaitrestore[aff] then
		prioWaitrestore[aff] = tempTimer(1, [[ prioWaitrestore["]]..aff..[["] = nil ]])
		-- A queued restore stays live: a switch drops the queue, so the switch must put it back.
		if ataxia_sendCuringPriority("curing priority "..aff.." "..def) == "sent" then
			clearLive(aff)
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

-- The multi-set command for the swaps of `set`. A swap we have no value for stays where it is.
local function restoreCommand(set)
  local names = ataxiaPrioSets.live[set]
  ataxiaPrioSets.live[set] = nil
  if not names then return nil end
  local prios = {}
  for aff in pairs(names) do prios[aff] = restoreValue(set, aff) end
  if next(prios) == nil then return nil end
  return table.concat(ataxia_prioMassCommands(prios), ";")
end

local giveUpReads

-- A read leaves now. Its clock starts here, or its reply could print. A name still live in this set
-- is a swap left up from before a reload or a connection, so the read must not take its value.
local function expectRead(set, now)
  local sets = ataxiaPrioSets
  local stale
  if sets.live[set] then
    stale = {}
    for aff in pairs(sets.live[set]) do stale[aff] = true end
  end
  table.insert(sets.pending, { set = set, at = now, stale = stale })
  if sets.timer then pcall(killTimer, sets.timer) end
  sets.timer = tempTimer(LIST_TIMEOUT, giveUpReads)
end

-- A class set with no baseline blocks its swaps, so a read that gave way or was lost asks again.
-- A direct send: through the throttle queue the reply could outlive the read's clock.
local function readAgain(set)
  local sets = ataxiaPrioSets
  if classSetActive() ~= set or sets.baseline[set] then return end
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
    tempTimer(READ_RETRY_DELAY, function() readAgain(set) end)
    return
  end
  throttle.sentThisSecond = throttle.sentThisSecond + 1
  expectRead(set, now)
  send("curing priority list", false)
end

giveUpReads = function()
  local sets = ataxiaPrioSets
  sets.timer = nil
  sets.pending = {}
  if sets.read then ataxia_prioListStop() end
  readAgain(activeSet())
end

-- classDetect's three switch sites call this, with the set we are leaving. A bash-set switch
-- has nothing of ours to put back and must not touch its stored writes, so it goes out alone.
function ataxia_switchCuringsetSend(name, from)
  -- Stops a default-table send still on its timers (ataxia_sendDefaultPrios).
  ataxiaPrioGen = (ataxiaPrioGen or 0) + 1
  if ataxia_bashProfileActive and ataxia_bashProfileActive() then
    send("curingset switch " .. name, false)
    return
  end

  local sets = ataxiaPrioSets
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
  local restore = restoreCommand(from or "normal")
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
    sets.quietUntil = now + LIST_TIMEOUT
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
  -- The baseline keeps the set's own value for a swap left up from before a reload or a connection.
  local was = sets.baseline[read.set]
  if read.stale and was then
    for aff in pairs(read.stale) do read.rows[aff] = was[aff] end
  end
  sets.baseline[read.set] = read.rows
  -- A later switch may have gone out already: the mirror holds the active set only.
  if read.set == activeSet() then ataxia.curingprio = mirror end
  ataxia_prioListStop()
  return true
end

-- Trigger 719. A value set during a visit is the set's own from now on, so a later swap and restore
-- put back that value. A swap's own line is skipped, because its name is live. A line can also
-- belong to the set we just left, so nothing is taken while a read is due.
function ataxia_prioTuned(aff, num)
  local sets = ataxiaPrioSets
  local set = classSetActive()
  if not set or not sets.baseline[set] then return end
  if #sets.pending > 0 or sets.read then return end
  if sets.quietUntil and getEpoch() < sets.quietUntil then return end
  if sets.live[set] and sets.live[set][aff] then return end
  sets.baseline[set][aff] = num
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