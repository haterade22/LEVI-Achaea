--[[mudlet
type: script
name: Queueing Related
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function combatQueue()
	local sp = ataxia.settings.separator

  local t = "g body"..sp.."g gold"..sp.."stand"..sp
  
  --Deliverance
  if tdeliverance == true then
    if partyrelay and not ataxia.afflictions.aeon then
      send("pt "..target.. ": Has Deliverance - DO NOT HIT - Need NEW Target")
      send("pt "..target.. ": Has Deliverance - DO NOT HIT - Need NEW Target")
    end
  send("cq all")
  ataxiaEcho("TARGET HAS DELIVERANCE - PICKING NEW TARGET")
  expandAlias("nt")
  end
  --Jester Bomb
  if havebomb == true then
    send("cq all;put bomb in pack;put bomb in pack;put bomb in pack;put bomb in pack")
  end
  
  --Jester AEON Cheese \ OCCIE Wheel Cheese \ Sentinel Riftlock \ Pariah Voyria Kill
  --
  -- THROTTLED (v4.7.275). This branch fires once per DISPATCH, and each pass sends `cq all`,
  -- which clears our own attack queue. In the 2026-08-19 Grulk log `preventriftlock` stayed set
  -- (it only clears on a successful shield, and a lemming stripped every shield in ~2s), so we
  -- re-shielded and re-cleared repeatedly: six balances spent to block our own offense.
  --
  -- The throttle matters more since v4.7.275 added blademaster.retryTick, which dispatches on
  -- the PROMPT rather than only on a keypress -- without it, an un-clearable cheese flag would
  -- send `cq all` several times a second and offense could never resume.
  if jestercheese == true or myaeon == true or preventriftlock == true or stoplatency == true then
    ataxiaTemp = ataxiaTemp or {}
    local now = (getEpoch and getEpoch()) or os.time()
    -- A due lock-breaker goes first (the user, 2026-11-09), and `cq all` would clear a held one.
    -- The throttle is tested first and is not stamped, so the shield goes on a later dispatch.
    if (not ataxiaTemp.cheeseAt or (now - ataxiaTemp.cheeseAt) >= 4) and not ataxia_shieldWaitsForLockBreak() then
      ataxiaTemp.cheeseAt = now
      ataxiaEcho("CLASS CHEESE INCOMMING")
      if gmcp.Char.Status.class == "Magi" then
        send("cq all;cast reflection at me")
      elseif mnemRimewrought then
        send("cq all") -- v4.7.333: the shield tattoo is inert under Rimewrought
      else
        send("cq all;touch shield")
      end
    end
  end
 if gmcp.Char.Status.class == "Psion" then 
 if affed("asthma") and (affed("slickness") or affed("bloodfire")) and affed("anorexia") and affed("paralysis") and affed("impatience") or affed("sandfever") then
  send(mnemRimewrought and "cq all" or "cq all;psi manipulate touch tree") -- tattoo inert: v4.7.333
 end
 end
   
   
   
	if ataxia.settings and ataxia.settings.use and ataxia.settings.use.parry and ataxia.parry ~= "manual" then
		if ataxia.parrying.shouldparry ~= ataxia.parrying.limb then
			t = t.." " ..sp.." parry " ..ataxia.parrying.shouldparry..sp
		end
	end

	-- A nil dir_left passes every test below and throws at the concatenation, and the round is lost.
	-- With no direction there is no chase piece: the round goes out without one.
	if tChaseTimer and not targetIshere and dir_left then
      if dir_left ~= "fly" and dir_left ~= "ether" and dir_left ~= "forcefly" then
			t = t..dir_left..sp
		elseif dir_left == "forcefly" and not affed("tension") then
			t = t.."land"..sp
		elseif dir_left == "fly" then
			if ataxia_isClass("Alchemist") then
				t = t.."educe lead "..target
			elseif ataxia_isClass("Psion") then
				t = t.."weave prepare disruption"..sp.."weave launch "..target
       
			else
				t = t.."touch tentacle "..target..sp
			end
		end
	end

	return t
end

function depthswalkerQueue()
	local sp = ataxia.settings.separator
	local t = "stand"..sp

	if ataxia.settings and ataxia.settings.use and ataxia.settings.use.parry and ataxia.parry ~= "manual" then
		if ataxia.parrying.shouldparry ~= ataxia.parrying.limb then
			t = t.."parry "..ataxia.parrying.shouldparry..sp
		end
	end

	-- As in combatQueue: a nil dir_left has no chase piece, and the round still goes out.
	if tChaseTimer and not targetIshere and dir_left then
		if dir_left ~= "fly" and dir_left ~= "ether" and dir_left ~= "forcefly" then
			t = t..dir_left..sp
		elseif dir_left == "forcefly" and not affed("tension") then
			t = t.."land"..sp
		elseif dir_left == "fly" and ataxiaTables.depthswalker.wordBal and haveWord("heila") then
			t = t.."intone heila"..sp
		else
			t = t.."touch tentacle "..target..sp
		end
	end
	
	if haveAff("shield") or attuningPerson then
		t = t.."wield shield dagger"..sp
		attuningPerson = nil
	else
		t = t.."wield shield scythe"..sp.."wipe scythe"..sp
	end
	return t
end

function resetNeededAffs()
	tarNeeds = {}
	table.insert(tarNeeds, "paralysis")
	table.insert(tarNeeds, "impatience")
	table.insert(tarNeeds, getLockingAffliction())
	table.insert(tarNeeds, "asthma")
	table.insert(tarNeeds, "vertigo")
	table.insert(tarNeeds, "dizziness")
	table.insert(tarNeeds, "anorexia")
	table.insert(tarNeeds, "slickness")
end

function predictBal(bal, time)
  balTime = balTime or {}
  balTime[bal] = getEpoch() + time
end

function getPredictBal(bal)
  return balTime[bal] or getEpoch() + 0.01
end

-- ---------------------------------------------------------------------------------------------
-- ROUND DELIVERY BY SERVER ALIAS. Off by default and Monk only. One group fight so far (2026-11-03).
-- `aconfig rounds alias|raw` sets it. Plan: step 3 of the 2026-11-01 timing plan.
--
-- THE PROBLEM. Mudlet's command separator is `;`, so send("queue addclear free a;b;c") is split on
-- our side. Only `a` is queued. `b` and `c` go out raw, and the game's auto-queue re-adds them if it
-- refuses them. Measured in our logs: setup ran before the attack in 8 of 71 flushes, and a superseded
-- attack fired in 15% (Monk) and 33% (Infernal) of queue-run attacks (kb/mechanics/balance-and-queueing.md).
--
-- THE FIX. One server alias: `setalias lvfree a/b/c`, then `queue addclear free lvfree`. The queue
-- stores the NAME and the game reads the body when the entry fires, so a rewrite after queueing
-- changes what runs. The first of three commands ran first, and all their replies came before one
-- prompt (kb/raw/live/probes_2026-11-01.txt). The other two gave the same refusal, so their order
-- cannot be seen.
--
-- The send wrapper (misc_scripts/031) calls ataxia_roundDeliver for every line, after the trait
-- filter, so ASSESS never reaches an alias without its trait. Every offence goes through one place,
-- and with the flag off the line leaves unchanged.
-- ---------------------------------------------------------------------------------------------

-- The classes the flag can reach. The plan's order: Shikudo first, then the others one at a time.
local ROUND_CLASSES = { monk = true }

-- The named queue types (HELP 4.6.1). A custom type such as eb!p!w!t passes through: `!` cannot be
-- in an alias name. "lvfreestand" is the longest name, 11 of the game's 12 characters. The gag
-- trigger 800 lists the same names.
ataxia_ROUND_TYPES = { eq = true, bal = true, eqbal = true, class = true, free = true, freestand = true, full = true }

-- A cautious cap, below the longest alias text in our logs: 142 characters
-- (2026-10-11_shikudo-vs-runewarden-snb_attacker.txt rows 1319, 1364, 1400). The 250-character probe
-- is still open, so a longer round stays on the raw path.
local ROUND_MAX_TEXT = 138

-- A command that ends in one of these moves us. Movement chains stay raw: `stand;<dir>` must reach
-- the game the way the explorer and the chase send it. A target named "N" also passes through,
-- which only costs that round the old delivery.
local ROUND_MOVES = {}
for _, d in ipairs({ "n", "e", "s", "w", "ne", "nw", "se", "sw", "u", "d", "in", "out", "north", "east", "south",
  "west", "northeast", "northwest", "southeast", "southwest", "up", "down" }) do
  ROUND_MOVES[d] = true
end

-- A chain with one of these stays raw, so the press sends what it sends with the flag off.
--   touch shield, curseward, reject: the next attack press rewrites the alias, and the game reads the
--     alias when it fires, so a key in that slot would run only if recovery came before that press.
--     Raw, it goes at once or the auto-queue holds it, and an attack press cannot remove it.
--     `reject` is the first word only: `reject <name>`.
--   mind blackout: it must run before the combo it hides, and that combo goes by `queue add`, raw
--     (shikudo/011). With the blackout in an alias the two wait in different queues, so the combo
--     could run first, unhidden.
local ROUND_RAW = { ["touch shield"] = true, curseward = true, reject = true, ["mind blackout"] = true }

-- RETARDATION. "You move sluggishly into action." prints once per command, and only the LAST command
-- of the LAST run happens, about 1.05 s later. A new run replaces the waiting one and starts the delay
-- again (group fight 2026-11-03, 081009_Froedine: runs at rows 2059, 2087, 2099 gave one combo at 2113,
-- 1.03 s after the last). That is 7 of 8 runs, an inference from rows and no HELP file. So a slowed
-- round is ONE command, and a press inside this gap sends nothing. It is 1.05 s plus a send's 0.13 s.
local ROUND_SLOW_GAP = 1.2

-- The commands of a chain that a slowed round skips: they prepare nothing the attack needs.
local ROUND_SLOW_SKIP = { g = true, get = true, parry = true, assess = true, contemplate = true }

-- A held attack that names the target has run by now, because recovery is generally 2-5 s (HELP 4.6).
local ROUND_HELD_SECS = 6

-- Is a slowed round in force? ataxia is saved, so a restart can bring ataxia.retardation back with no
-- timer left to clear it. retardationOn (misc_scripts/004) always starts that timer.
local function roundSlowed()
  return ataxia.retardation and retardDropDetectionTimer ~= nil
end

-- The one command a slowed round sends, in the order the round needs them: stand if prone, the staff
-- if GMCP says it is not in hand, the transition, and then the attack. A combo that goes before its
-- transition is refused: the runs at rows 2152, 2736 and 2765 of that log. The second value is true when the
-- command is the round's attack, so the run line may count the round as run.
local function roundSlowPick(pieces)
  local prone = ataxia.afflictions and ataxia.afflictions.prone
  local inHand = ataxiaTemp.wieldedItems
  local form, attack
  for _, piece in ipairs(pieces) do
    local low = piece:lower()
    local word = low:match("^%S+")
    if low == "stand" then
      if prone then return piece, false end
    elseif word == "wield" then
      local id = low:match("(%d+)$")
      if id and inHand and not inHand[id] then return piece, false end
    elseif word == "transition" then
      form = form or piece
    elseif not ROUND_SLOW_SKIP[word] then
      attack = attack or piece
    end
  end
  if form then return form, false end
  return attack or pieces[#pieces], true
end

-- Transient, on ataxiaTemp. A restart or a login empties it, so the next round sets the alias again.
--   aliases[name] = { text = the alias body we last sent, raw = the chain as the offence built it, or
--                     nil when the alias holds less than that chain, queue = the queue type it went to }
--   queued[type]  = true while an alias of ours may still wait in that queue
--   slowAt        = when the last slowed round went out
--   heldAt        = when the game last held a command that names the target (ataxia_roundHeld)
local function roundState()
  ataxiaTemp = ataxiaTemp or {}
  local rs = ataxiaTemp.roundSend
  if not rs then
    rs = { aliases = {}, queued = {} }
    ataxiaTemp.roundSend = rs
  end
  return rs
end

-- "alias" when this round goes through the shim, else "raw". It never applies while the basher is
-- on: bashing is a later step of the plan, and `swarm.decorate` needs tests first.
function ataxia_roundMode()
  local flags = ataxia and ataxia.settings and ataxia.settings.roundDelivery
  if type(flags) ~= "table" then return "raw" end
  if ataxiaBasher and ataxiaBasher.enabled then return "raw" end
  local class = gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class
  class = type(class) == "string" and class:lower() or ""
  if ROUND_CLASSES[class] and flags[class] == "alias" then return "alias" end
  return "raw"
end

-- The alias body and the queue it goes to, or nil to pass the line through unchanged.
--
-- ROUND ORDER. `stand` goes first and only once: a `free` entry has no upright condition, so it can
-- fire while we are prone, and the rest of the round needs us up. The rest keeps the offence's order,
-- so the offence still decides where its spender goes.
--
-- FREESTAND. A `freestand` entry cannot fire while we are prone, so a chain that stands us up would
-- wait for ever (HELP 4.6.1). That chain moves to `free`, the same conditions without the upright one.
-- `full` also needs class balance, and `free` would lose that, so its chain stays raw.
--
-- TOUCH TENTACLE ends the round. It spends equilibrium (2.14 s; 1.53 s even when the target is gone),
-- so the game refuses and HOLDS each command after it in the alias, and `queue addclear` cannot remove
-- those. They ran at the next recovery, after a target switch (081009_Froedine rows 428-433, 546-550).
-- The next press sends the attack. The chase lasts about 2.3 s (trigger 640), so a round cannot stay
-- on the tentacle for long.
--
-- The third value is true when the alias holds the whole round, or its attack alone. The run line then
-- counts the round as run. A tentacle or a transition is not the attack the offence planned.
local function roundPlan(qtype, payload)
  if not ataxia_ROUND_TYPES[qtype] or payload:find("[/%%{]") then return nil end
  local sep = ataxia.settings.separator
  if type(sep) == "string" and sep ~= "" and sep ~= ";" then
    payload = payload:gsub((sep:gsub("%p", "%%%0")), ";")
  end
  local pieces, stands, tentacleAt = {}, false, nil
  for piece in payload:gmatch("[^;]+") do
    piece = piece:match("^%s*(.-)%s*$")
    local low = piece:lower()
    if low == "stand" then
      stands = true
    elseif low ~= "" then
      if ROUND_MOVES[low:match("(%S+)$")] or ROUND_RAW[low] or ROUND_RAW[low:match("^%S+")] then return nil end
      pieces[#pieces + 1] = piece
      if not tentacleAt and low:find("^touch tentacle") then tentacleAt = #pieces end
    end
  end
  for i = #pieces, (tentacleAt or #pieces) + 1, -1 do pieces[i] = nil end
  if stands then table.insert(pieces, 1, "stand") end
  local slowed = roundSlowed()
  if #pieces < 2 and not tentacleAt and not slowed then return nil end
  if stands and qtype == "full" then return nil end
  local into = (stands and qtype == "freestand") and "free" or qtype
  local whole = not tentacleAt
  if slowed then
    local one, attack = roundSlowPick(pieces)
    pieces = { one }
    whole = whole and attack
  end
  local text = table.concat(pieces, "/")
  if #text > ROUND_MAX_TEXT then return nil end
  return text, into, whole
end

-- The send wrapper's hook. Returns the line to send. Anything it adds goes out first, so the alias
-- text is on the server before the queue line names it.
function ataxia_roundDeliver(cmd)
  if type(cmd) ~= "string" or ataxia_roundMode() ~= "alias" then return cmd end
  -- `free;stand;x` has no space after the type, so it does not match: Mudlet sends it as today.
  local verb, qtype, payload = cmd:match("^%s*[Qq][Uu][Ee][Uu][Ee]%s+(%a+)%s+([%w!]+)%s+(.+)$")
  verb = verb and verb:lower()
  if verb ~= "addclear" and verb ~= "addclearfull" then return cmd end
  qtype = qtype:lower()
  local rs = roundState()
  local text, into, whole = roundPlan(qtype, payload)

  -- A slowed round went out inside the gap: one more run would replace it and restart its delay.
  if text and roundSlowed() then
    local now = getEpoch()
    if rs.slowAt and now - rs.slowAt < ROUND_SLOW_GAP then return "" end
    rs.slowAt = now
  end

  -- This line replaces the round. ADDCLEAR clears only its own queue, so an alias waiting in another
  -- queue would still fire: clear it. ADDCLEARFULL wipes every queue itself.
  if verb == "addclearfull" then
    rs.queued = {}
  else
    for q in pairs(rs.queued) do
      if q ~= (into or qtype) then
        ataxia_rawSend("clearqueue " .. q, false)
        rs.queued[q] = nil
      end
    end
  end

  if not text then
    rs.queued[qtype] = nil -- the raw ADDCLEAR replaces any alias in its own queue
    return cmd
  end

  local name = "lv" .. into
  local a = rs.aliases[name]
  if not a then
    a = {}
    rs.aliases[name] = a
  end
  if a.text ~= text then
    ataxia_rawSend("setalias " .. name .. " " .. text, false)
    a.text = text
  end
  a.raw, a.queue = whole and payload or nil, into
  rs.queued[into] = true
  return "queue " .. verb .. " " .. into .. " " .. name
end

-- Triggers 001 and 007: the game held `text` for a recovery ("... was added to your balance queue.").
-- Only a command that names the target counts, so a held `touch shield` does not cost a clear below.
function ataxia_roundHeld(text)
  if ataxia_roundMode() ~= "alias" or type(text) ~= "string" then return end
  if type(target) == "string" and target ~= "" and text:lower():find(target:lower(), 1, true) then
    roundState().heldAt = getEpoch()
  end
end

-- switchTarget, for a new name. Our alias keeps the old name until the next press, and it fired at the
-- old target 52 ms and 1.35 s after a switch (081009_Froedine rows 550, 3838). `queue addclear` leaves
-- a held command alone, so only CLEARQUEUE ALL reaches one: 0 of 82 held commands in our logs ran after
-- `All queued commands cleared.` unless sent again. It also takes any other queued command, so it goes
-- only when a held command names the target. The clear can lose a race with a recovery already in flight.
function ataxia_roundTargetChanged()
  local rs = ataxiaTemp and ataxiaTemp.roundSend
  if not rs or ataxia_roundMode() ~= "alias" then return end
  if rs.heldAt and getEpoch() - rs.heldAt < ROUND_HELD_SECS then
    ataxia_rawSend("clearqueue all", false)
  else
    for q in pairs(rs.queued) do ataxia_rawSend("clearqueue " .. q, false) end
  end
  rs.queued, rs.heldAt, rs.slowAt = {}, nil, nil
end

-- We expect the game's run line to name the alias ("Running queued free command: LVFREE"), until the
-- first alias fight confirms it. This returns the chain as the offence built it, because the run-line
-- readers (queue_Scan, shikudo 007 and 011) match it against what they queued. Any other text comes
-- back unchanged.
--
-- It leaves rs.queued alone. A run line cannot say which press it answers: round B can replace round
-- A while A's run line is in flight, and B would then fire beside the next line to another queue. The
-- cost is one extra `clearqueue` when the queue type changes.
function ataxia_roundRan(ran)
  local rs = ataxiaTemp and ataxiaTemp.roundSend
  if not rs or type(ran) ~= "string" then return ran end
  local a = rs.aliases[ran:lower():match("^%s*(lv%a+)%s*$") or ""]
  return a and a.raw or ran
end

-- A queue line we sent names the alias. This returns the alias text, for the readers of sent lines
-- that look for a target or a word in them. Any other line comes back unchanged.
function ataxia_roundSentText(cmd)
  local rs = ataxiaTemp and ataxiaTemp.roundSend
  if not rs or type(cmd) ~= "string" then return cmd end
  local a = rs.aliases[cmd:lower():match("^%s*queue%s+%a+%s+[%w!]+%s+(lv%a+)%s*$") or ""]
  return a and a.text or cmd
end

-- `aconfig rounds [alias|raw]`. The setting is per class and saved. Leaving the alias path clears
-- what it queued, because a later raw ADDCLEAR replaces only its own queue.
function ataxia_roundCommand(arg)
  local class = gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class
  class = type(class) == "string" and class:lower() or ""
  if arg == "alias" and not ROUND_CLASSES[class] then
    ataxiaEcho("Round aliases are for Monk only in this step, so <white>" .. class
      .. "<NavajoWhite> stays raw.")
    return
  end
  if arg == "alias" or arg == "raw" then
    ataxia.settings.roundDelivery = ataxia.settings.roundDelivery or {}
    ataxia.settings.roundDelivery[class] = arg
    if arg == "raw" then
      local rs = roundState()
      for q in pairs(rs.queued) do ataxia_rawSend("clearqueue " .. q, false) end
      rs.queued = {}
    else
      -- 007 and 011 count a round at the press only until a run line has matched. The wording on this
      -- path is not yet seen, so a match from a raw round must not end that count here: a wording we
      -- cannot read would stop the MIND cap with no alert.
      if shikudoLock and shikudoLock.state then shikudoLock.state.runLine = nil end
      if ataxiaTemp and ataxiaTemp.shikTele then ataxiaTemp.shikTele.runLine = nil end
    end
    ataxia_saveSettings(false)
  end
  local flags = ataxia.settings.roundDelivery
  local chosen = type(flags) == "table" and flags[class] or "raw"
  ataxiaEcho("Round delivery: " .. (chosen == "alias" and "<green>alias" or "<white>raw") .. "<NavajoWhite>"
    .. (chosen == "alias" and ataxia_roundMode() == "raw" and " (raw while the basher is on)" or "")
    .. ". Change it: <white>aconfig rounds alias|raw<NavajoWhite>. Alias has one group fight behind it so far.")
end
