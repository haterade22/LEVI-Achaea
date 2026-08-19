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
  drainTimer = nil,
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
-- ataxia.curingprio from server tokens via gmatch("%w+"), so `burning5` becomes its own row
-- and ataxia_showPrios' [+]/[-] links write it straight back.
local function writesStoredAffPrio(cmd)
  if type(cmd) ~= "string" then return false end
  for part in cmd:gmatch("[^;]+") do
    local aff = part:match("^%s*curing%s+priority%s+(%a+)%d*%s+%d+%s*$")
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

function ataxia_sendCuringPriority(cmd, silent)
  if ataxia_bashProfileActive and ataxia_bashProfileActive() then
    local blocked, aff = writesStoredAffPrio(cmd)
    if blocked then
      if ataxiaBasher_debug and ataxiaEcho then
        ataxiaEcho("[DBG] dropped stored priority write on the bash set: " .. tostring(aff))
      end
      return
    end
  end

  local now = getEpoch()
  local throttle = ataxia.prioThrottle

  if (now - throttle.windowStart) >= 1.0 then
    throttle.sentThisSecond = 0
    throttle.windowStart = now
  end

  -- `sentThisSecond == 0` lets an oversized batch through rather than queueing it forever:
  -- it cannot be split here, and holding it would be worse than one second slightly over.
  local n = commandCount(cmd)
  if throttle.sentThisSecond == 0 or (throttle.sentThisSecond + n) <= throttle.MAX_PER_SECOND then
    throttle.sentThisSecond = throttle.sentThisSecond + n
    send(cmd, silent or false)
  else
    table.insert(throttle.commands, {cmd = cmd, silent = silent or false})
    if not throttle.drainTimer then
      throttle.drainTimer = tempTimer(0.25, function() ataxia_drainPrioQueue() end)
    end
  end
end

function ataxia_drainPrioQueue()
  local throttle = ataxia.prioThrottle
  throttle.drainTimer = nil

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

  if #throttle.commands > 0 then
    throttle.drainTimer = tempTimer(0.25, function() ataxia_drainPrioQueue() end)
  end
end

-- What should this name be RESTORED to? For a stacked name with no override of its own that
-- is the family's BASE entry -- the same answer SSC itself uses at that count. Without the
-- fallback, ataxia_restorePrio("burning3") reached a nil concat and threw.
--
-- Deliberately NOT applied to ataxia_getPrio: that answers "what value does the server hold
-- for this exact name", and ApplySwaps/RestoreSwaps compare the two -- a fallback there
-- would make the equality test lie.
function ataxia_defaultPrioAff(aff)
	if type(aff) ~= "string" then return nil end
	-- Lowercased because ataxia_stackAff is case-insensitive and trigger 717 writes
	-- ataxia.curingprio keys straight from server tokens without normalising: two writers of
	-- one table with different casing is a split-key bug waiting to happen.
	aff = aff:lower()
	local defaultPrios = ataxia_defaultCuringPrios()
	if defaultPrios[aff] then return defaultPrios[aff] end
	local base = aff:match("^(%a+)%d+$")
	return base and defaultPrios[base] or nil
end

function ataxia_setAffPrio(aff, num)
	prioWaitfor = prioWaitfor or {}
	if not prioWaitfor[aff] then
		prioWaitfor[aff] = tempTimer(1, [[ prioWaitfor["]]..aff..[["] = nil ]])
		ataxia_sendCuringPriority("curing priority "..aff.. " "..num, false)
	end
end

function ataxia_restorePrio(aff)
	ataxia.curingprio = ataxia.curingprio or {}
	prioWaitrestore = prioWaitrestore or {}

	-- The comparison and the SEND must read the same source. This used to compare via
	-- ataxia_defaultPrioAff but index defaultPrios directly on the send, so the base fallback
	-- above would have been bypassed on the one line that concatenates. A name the table does
	-- not know at all (`brokenhead` is one we have been sending) now returns instead of
	-- building "curing priority brokenhead nil".
	local def = ataxia_defaultPrioAff(aff)
	if not def then return end
	if ataxia_getPrio(aff) == def then return end
	if not prioWaitrestore[aff] then
		prioWaitrestore[aff] = tempTimer(1, [[ prioWaitrestore["]]..aff..[["] = nil ]])
		ataxia_sendCuringPriority("curing priority "..aff.." "..def)
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
	local newprio = (ataxia.curingprio[aff] - 1)
	ataxia.curingprio[aff] = newprio
	ataxia_sendCuringPriority("curing priority "..aff.." "..newprio)

	if not hide then
		ataxiaEcho("Raised "..aff.." to a priority of "..newprio)
		ataxia_showPrios(newprio)
	end
end

function ataxia_lowerPrio(aff, hide)
	local newprio = (ataxia.curingprio[aff] + 1)
	ataxia.curingprio[aff] = newprio
	ataxia_sendCuringPriority("curing priority "..aff.." "..newprio)

	if not hide then
		ataxiaEcho("Lowered "..aff.." to a priority of "..newprio)
		ataxia_showPrios(newprio)
	end
end