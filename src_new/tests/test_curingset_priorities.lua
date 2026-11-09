--- test_curingset_priorities.lua -- one priority list per curing set (kb/CONFLICTS.md #76)
--
-- The user, 2026-11-08: "The purpose of curing sets is to set priorities based on the class you
-- are facing. Classes through skills can only give specific afflictions. So we do curing sets for
-- them. If Infernal can never give impatience. no need for Impatience to be curing priority
-- impatience 2".
--
-- A small fake server holds one priority table per set and answers `curing priority` writes,
-- `curingset switch` and `curing priority list` with the game's own lines. The real triggers
-- 716, 717, 718 and 719 run on those lines, through their real patterns. The real classDetect
-- engine sends the switches. Replies wait in a queue until a test calls pump(), so a test can act
-- while a reply is still on its way. Every global this file changes is restored at the end.

local mock = require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

local before = {}
for k, v in pairs(_G) do before[k] = v end
local tableSave, tableLoad, ioExists = table.save, table.load, io.exists

local LEVI = "src_new/scripts/levi_ataxia/levi/"
local DEFAULTS_FILE = LEVI .. "ataxia/ataxia/001_Default_Curing_Prios.lua"
local PRIO_FILE = LEVI .. "ataxia/ataxia/002_Prio_Management.lua"
local ENGINE = LEVI .. "levi_scripts/class_detect/001_Class_Detect_Engine.lua"
local ANTI = LEVI .. "levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua"
local DEF_API = LEVI .. "ataxia/deffing/001_Defence_API.lua"
local LOGIN = LEVI .. "ataxia/login/001_Login_Function.lua"
local DAMNATION = LEVI .. "levi_scripts/algedonic_defense_1.0/002_Damnation_Defence.lua"
local CURINGSET_FILE = LEVI .. "ataxia/ataxia/009_Curingset_State.lua"
local BASH_FILE = LEVI .. "ataxia/ataxia/008_Bash_Curing_Profile.lua"
local RESET_ALIAS = "src_new/aliases/levi_ataxia/for_levi/levi_062424/combat_aliases/008_Reset_Aff_Prios.lua"
local ENGAGED = LEVI .. "ataxia/genrunning/003_Engaged_Disengage.lua"
local TRIG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local T716, T717, T718, T719 = TRIG .. "716_Curing_Priority_List.lua", TRIG .. "717_Get_Line_of_Affs.lua",
  TRIG .. "718_Save_Priorities.lua", TRIG .. "719_Affliction_Set.lua"
local TUMBLE = TRIG .. "misc_alerts/004_We're_tumbling.lua"
local CAPTURE_FILE = "kb/raw/live/curing-priority-list_normal_2026-10-10.txt"

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
local BODY = {}
local function body(p)
  BODY[p] = BODY[p] or assert((loadstring or load)(read(p):match("%]%]%-%-\r?\n(.*)$"), p))
  return BODY[p]
end

-- Each real trigger's capture groups, for `matches`. TL checks the real pattern first.
local CAPTURES = {
  [T716] = "^(Your affliction curing priorities for the priority set (%S+):)",
  [T717] = "^((%d+):%s+(.+))$",
  [T718] = "^(.+)$",
  [T719] = "^(You have set the '(.+)' affliction to the (%d+) priority.)$",
}

-- ---------------------------------------------------------------------------
-- The test bench
-- ---------------------------------------------------------------------------
local game, printed, deleted, clock, timers, temps, chain, saves, nextId, bashOn, disk, echoes

local function advance(dt)
  clock = clock + dt
  local due = {}
  for id, t in pairs(timers) do
    if t.at <= clock then due[#due + 1] = { id = id, t = t } end
  end
  table.sort(due, function(a, b)
    if a.t.at ~= b.t.at then return a.t.at < b.t.at end
    return a.id < b.id
  end)
  for _, d in ipairs(due) do
    if timers[d.id] then
      timers[d.id] = nil
      if type(d.t.fn) == "string" then assert((loadstring or load)(d.t.fn))() else d.t.fn() end
    end
  end
end

local function fire(path, text)
  if not TL.anyMatches(TL.patterns(path), text) then return false end
  matches = { text:match(CAPTURES[path]) }
  body(path)()
  return true
end

-- One line reaches Mudlet: permanent triggers in tree order, the chain children only on lines
-- after the head fired, then temp triggers. A trigger armed in this pass also sees this line.
local function deliver(text)
  deleted = false
  line = text
  local chainWasOpen = chain > 0
  if chainWasOpen then chain = chain - 1 end
  local function permanent()
    if fire(T716, text) then chain = 99 end
    if chainWasOpen then
      fire(T717, text)
      fire(T718, text)
    end
    fire(T719, text)
  end
  local function temporary()
    local i = 1
    while temps[i] do
      local t = temps[i]
      if not t.dead and (not t.only or text:match(t.only)) then
        matches = { text, text }
        t.fn()
      end
      i = i + 1
    end
  end
  -- Mudlet runs temp triggers last, as far as its source shows. The read must not depend on it.
  if game.tempsFirst then temporary(); permanent() else permanent(); temporary() end
  if not deleted then printed[#printed + 1] = text end
end

local function pump()
  while #game.queue > 0 do deliver(table.remove(game.queue, 1)) end
end

-- `burning5` prints as `burning(5)`.
local function displayName(aff)
  return (aff:gsub("^(%a+)(%d+)$", "%1(%2)"))
end

local function listLines(setName)
  local rows = {}
  for aff, v in pairs(game.sets[setName] or {}) do
    rows[v] = rows[v] or {}
    table.insert(rows[v], displayName(aff))
  end
  local out = { "Your affliction curing priorities for the priority set " .. setName .. ":" }
  for n = 1, 26 do
    if rows[n] then
      table.sort(rows[n])
      local text = n .. ":" .. (n < 10 and "  " or " ") .. table.concat(rows[n], ", ")
      if game.wrapAt then
        for _, row in ipairs(TL.wrap(text, game.wrapAt)) do out[#out + 1] = row end
      else
        out[#out + 1] = text
      end
    else
      out[#out + 1] = n .. ":"
    end
  end
  out[#out + 1] = "Affs with priority 26 are ignored."
  return out
end

local function queueLine(text) game.queue[#game.queue + 1] = text end

local function serverRun(cmd)
  game.commands[#game.commands + 1] = cmd
  local to = cmd:match("^curingset switch (%S+)$")
  local cloned = cmd:match("^curingset clone (%S+)$")
  if to then
    game.current = to
    queueLine("You will now cure using the " .. to .. " set.")
  elseif cloned then
    game.sets[game.current] = {}
    for aff, v in pairs(game.sets[cloned] or {}) do game.sets[game.current][aff] = v end
  elseif cmd == "curingset list" then
    game.csAsked = (game.csAsked or 0) + 1
    if game.loseCs and game.loseCs[game.csAsked] then return end
    local names = {}
    for name in pairs(game.sets) do names[#names + 1] = name end
    table.sort(names)
    queueLine("Your current curing sets")
    queueLine(string.rep("-", 80))
    for _, name in ipairs(names) do
      queueLine(name .. (name == game.current and " (current)" or ""))
    end
    queueLine("You are using a total of " .. #names .. " of your allowed 22 curing sets.")
  elseif cmd == "curing priority list" then
    game.listsAsked = game.listsAsked + 1
    if game.loseList and game.loseList[game.listsAsked] then return end
    for _, l in ipairs(listLines(game.current)) do queueLine(l) end
  elseif cmd:match("^curing priority defence ") or cmd:match("^curing priority health")
      or cmd:match("^curing priority mana") then
    return
  else
    local rest = cmd:match("^curing priority (.+)$")
    if rest and game.refuse and game.refuse(cmd) then
      queueLine("You have exceeded the spam threshold for curing priority.")
    elseif rest then
      game.sets[game.current] = game.sets[game.current] or {}
      for aff, n in rest:gmatch("(%a+%d*) (%d+)") do
        game.sets[game.current][aff] = tonumber(n)
        queueLine("You have set the '" .. aff .. "' affliction to the " .. n .. " priority.")
      end
    end
  end
end

-- `bench.sets` is the server's tables. The current set is `normal`, as at login.
local function fresh(sets)
  mock.reset()
  game = { sets = sets or {}, current = "normal", queue = {}, sends = {}, commands = {}, listsAsked = 0 }
  game.sets.normal = game.sets.normal or {}
  printed, temps, timers = {}, {}, {}
  disk, echoes = { files = {}, writes = 0 }, {}
  clock, chain, saves, nextId, bashOn, deleted = 1000, 0, 0, 0, false, false

  send = function(cmd)
    game.sends[#game.sends + 1] = cmd
    if game.linkDown then return end
    for piece in cmd:gmatch("[^;]+") do serverRun(piece) end
  end
  getEpoch = function() return clock end
  deleteLine = function() deleted = true end
  setTriggerStayOpen = function(name, n) if name == "Curing Priority List" then chain = n end end
  tempTimer = function(delay, fn)
    nextId = nextId + 1
    timers[nextId] = { at = clock + delay, fn = fn }
    return nextId
  end
  killTimer = function(id) timers[id] = nil end
  -- The read's line trigger and the two of 009's CURINGSET LIST capture.
  local ANY, LIST_END = "^(.*)$", "^You are using a total of \\d+ of your allowed \\d+ curing sets\\.$"
  tempRegexTrigger = function(pat, fn)
    assert(pat == ANY or pat == LIST_END, "an unexpected temp pattern")
    nextId = nextId + 1
    temps[#temps + 1] = { id = nextId, fn = fn,
      only = pat == LIST_END and "^You are using a total of %d+ of your allowed %d+ curing sets%.$" or nil }
    return nextId
  end
  killTrigger = function(id)
    for _, t in ipairs(temps) do if t.id == id then t.dead = true end end
  end
  registerAnonymousEventHandler = function(event, fn)
    if event == "sysConnectionEvent" then game.onConnect = fn end
    if event == "sysDisconnectionEvent" then game.onDisconnect = fn end
    return 1
  end
  killAnonymousEventHandler = function() end
  cecho, echo = function() end, function() end
  -- A real copy each way, as table.save and table.load make. A save or a load can only see the disk.
  local function copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = copy(x) end
    return out
  end
  table.save = function(path, data)
    disk.files[path] = copy(data)
    disk.writes = disk.writes + 1
  end
  table.load = function(path, into)
    for k, v in pairs(copy(disk.files[path])) do into[k] = v end
  end
  io.exists = function(path) return disk.files[path] ~= nil end

  ataxia = { settings = { bashcuring = { active = false }, defences = { current = "" } },
    afflictions = {}, curingprio = {}, channels = {}, vitals = { bleed = 0 } }
  ataxiaTemp = {}
  ataxiaEcho = function(m) echoes[#echoes + 1] = tostring(m) end
  ataxia_saveSettings = function() saves = saves + 1 end
  ataxia_bashProfileActive = function() return bashOn end
  ataxia_bashProfileOff = function() end
  ataxiaNDB_getClass = function() return game.tc end
  ataxiaNDB_Exists = function() return game.tc ~= nil end
  ataxia_resetSwaps = function() ataxia.prioritySwaps = {} end
  affed = function(a) return ataxia.afflictions[a] end
  target = "Someone"
  prioWaitfor, prioWaitrestore = nil, nil
  classDetect, Algedonic, ataxiaPrioSets, ataxiaPrioSetsHandler, ataxiaPrioLinkHandler = nil, {}, nil, nil, nil
  ataxia_curingsetRefresh = nil

  dofile(DEFAULTS_FILE)
  dofile(PRIO_FILE)
  dofile(ENGINE)
  dofile(ANTI)
  classDetect.config.echoSwitches = false
  classDetect.config.apiLookupEnabled = false
end

local DEBOUNCE = 0.6 -- past classDetect's 500 ms

local function switchTo(className)
  advance(DEBOUNCE)
  classDetect.switchCuringset(className)
end

local function sentEver(cmd)
  for _, c in ipairs(game.commands) do
    if c == cmd then return true end
  end
  return false
end

local function positionOf(cmd)
  for i, c in ipairs(game.commands) do
    if c == cmd then return i end
  end
  return nil
end

local function printedAnyList()
  for _, l in ipairs(printed) do
    if l:match("^Your affliction curing priorities") or l:match("^%d+:") or l:match("^Affs with priority 26") then
      return true
    end
  end
  return false
end

local function liveTemps()
  local n = 0
  for _, t in ipairs(temps) do
    if not t.dead then n = n + 1 end
  end
  return n
end

-- Every read goes unanswered.
local LOSE_ALL = setmetatable({}, { __index = function() return true end })

local function SIMPLE(values)
  local t = { normal = {}, serpent = {}, infernal = {} }
  for k, v in pairs(values or {}) do t[k] = v end
  return t
end

-- ---------------------------------------------------------------------------
-- The user's example
-- ---------------------------------------------------------------------------
describe("a class set keeps its own values", function()
  it("Infernal: a swap and a restore put back the set's low impatience, never the global 4", function()
    fresh(SIMPLE({ infernal = { impatience = 20, paralysis = 3 } }))
    switchTo("Infernal")
    pump()
    expect(game.current).toBe("infernal")
    ataxia_setAffPrio("impatience", 1)
    pump()
    expect(game.sets.infernal.impatience).toBe(1)
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    expect(game.sets.infernal.impatience).toBe(20)
    expect(sentEver("curing priority impatience 4")).toBeFalse()
    expect(ataxia_defaultCuringPrios().impatience).toBe(4)
  end)

  it("the restore guards read the set's value: RestoreSwaps puts the 20 back too", function()
    fresh(SIMPLE({ infernal = { impatience = 20, paralysis = 3 } }))
    switchTo("Infernal")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    ataxia.prioritySwaps = { astImp = { active = true } }
    Algedonic.RestoreSwaps("paralysis")
    pump()
    expect(game.sets.infernal.impatience).toBe(20)
  end)

  it("a stacked name with no row of its own restores to the set's base", function()
    fresh(SIMPLE({ infernal = { burning = 7 } }))
    switchTo("Infernal")
    pump()
    expect(ataxia_defaultPrioAff("burning3")).toBe(7)
    expect(ataxia_defaultPrioAff("BURNING3")).toBe(7)
  end)

  it("a per-stack row answers for its own name, read from the game's `burning(5)`", function()
    fresh(SIMPLE({ infernal = { burning = 7, burning5 = 2 } }))
    switchTo("Infernal")
    pump()
    expect(ataxia_defaultPrioAff("burning5")).toBe(2)
    expect(ataxia_defaultPrioAff("burning")).toBe(7)
    expect(ataxia_getPrio("burning5")).toBe(2)
  end)

  it("ataxia.curingprio is the mirror of the active set, not of the baseline", function()
    fresh(SIMPLE({ infernal = { impatience = 20 } }))
    switchTo("Infernal")
    pump()
    expect(ataxia_getPrio("impatience")).toBe(20)
    ataxia.curingprio.impatience = 1
    expect(ataxia_defaultPrioAff("impatience")).toBe(20)
  end)
end)

-- ---------------------------------------------------------------------------
-- The send
-- ---------------------------------------------------------------------------
describe("a switch puts the old set's swaps back first", function()
  local function swapped()
    fresh(SIMPLE({ serpent = { impatience = 4, paralysis = 3 }, infernal = { impatience = 20, paralysis = 6 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    ataxia_setAffPrio("paralysis", 1)
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
    game.sends, game.commands = {}, {}
  end

  it("switchCuringset: one send, the multi-set restore, the switch, then the read", function()
    swapped()
    switchTo("Infernal")
    expect(#game.sends).toBe(1)
    expect(game.sends[1]).toBe("curing priority impatience 4 paralysis 3;curingset switch infernal;curing priority list")
    pump()
    expect(game.sets.serpent.impatience).toBe(4)
    expect(game.sets.serpent.paralysis).toBe(3)
    expect(game.sets.infernal.impatience).toBe(20)
    expect(game.sets.infernal.paralysis).toBe(6)
  end)

  it("resetToNormal: the same send", function()
    swapped()
    classDetect.resetToNormal()
    expect(game.sends[1]).toBe("curing priority impatience 4 paralysis 3;curingset switch normal;curing priority list")
    pump()
    expect(game.sets.serpent.impatience).toBe(4)
  end)

  it("the multiple-attacker branch: the same send", function()
    swapped()
    classDetect.state.attackers = { saibel = true }
    classDetect.state.attackerName = "Saibel"
    classDetect.state.attackerClass = "Serpent"
    classDetect.setAttackerClass("Froedine", "Monk")
    expect(game.sends[1]).toBe("curing priority impatience 4 paralysis 3;curingset switch normal;curing priority list")
    pump()
    expect(game.sets.serpent.paralysis).toBe(3)
  end)

  it("the restore comes before the switch, and the read right after it, on the wire", function()
    swapped()
    switchTo("Infernal")
    local r, s, l = positionOf("curing priority impatience 4 paralysis 3"), positionOf("curingset switch infernal"),
      positionOf("curing priority list")
    expect(r < s).toBeTrue()
    expect(l).toBe(s + 1)
  end)

  it("a swap put back during the fight is not restored again at the switch", function()
    swapped()
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    game.sends, game.commands = {}, {}
    switchTo("Infernal")
    expect(game.sends[1]).toBe("curing priority paralysis 3;curingset switch infernal;curing priority list")
  end)

  it("a restore that had to queue is still restored by the switch", function()
    swapped()
    advance(1.1)
    ataxia.prioThrottle.sentThisSecond = 4
    ataxia.prioThrottle.windowStart = clock
    ataxia_restorePrio("impatience")
    expect(#ataxia.prioThrottle.commands).toBe(1)
    game.sends, game.commands = {}, {}
    -- No debounce wait: the queue must not have drained before the switch.
    classDetect.state.lastSwitchTime = 0
    classDetect.switchCuringset("Infernal")
    expect(#ataxia.prioThrottle.commands).toBe(0)
    pump()
    expect(game.sets.serpent.impatience).toBe(4)
  end)

  it("a swap that had to queue, then landed, still goes back at the switch", function()
    fresh(SIMPLE({ serpent = { impatience = 9 } }))
    switchTo("Serpent")
    pump()
    ataxia.prioThrottle.sentThisSecond = 4
    ataxia.prioThrottle.windowStart = clock
    ataxia_setAffPrio("impatience", 1)
    expect(#ataxia.prioThrottle.commands).toBe(1)
    advance(1.1)
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
    game.sends = {}
    switchTo("Infernal")
    expect(game.sends[1]).toBe("curing priority impatience 9;curingset switch infernal;curing priority list")
  end)

  it("with nothing to put back the send is the switch and the read", function()
    fresh(SIMPLE())
    switchTo("Serpent")
    expect(game.sends[1]).toBe("curingset switch serpent;curing priority list")
  end)

  it("the send counts against the throttle's window: restore and read, not the switch", function()
    swapped()
    advance(1.1)
    switchTo("Infernal")
    expect(ataxia.prioThrottle.sentThisSecond).toBe(2)
    fresh(SIMPLE())
    switchTo("Serpent")
    expect(ataxia.prioThrottle.sentThisSecond).toBe(1)
  end)

  it("a full window gives up the read and never the restore, and never draws a refusal", function()
    swapped()
    advance(1.1)
    ataxia.prioThrottle.sentThisSecond = 4
    ataxia.prioThrottle.windowStart = clock + 0.7 -- still inside the window after the debounce
    switchTo("Infernal")
    expect(game.sends[1]).toBe("curing priority impatience 4 paralysis 3;curingset switch infernal")
    pump()
    expect(game.sets.serpent.impatience).toBe(4)
    expect(ataxia_defaultPrioAff("impatience")).toBeNil()
  end)

  it("leaving normal restores the global default, in the same send", function()
    fresh(SIMPLE())
    ataxia_setAffPrio("impatience", 1)
    pump()
    game.sends, game.commands = {}, {}
    switchTo("Serpent")
    expect(game.sends[1]).toBe("curing priority impatience 4;curingset switch serpent;curing priority list")
    pump()
    expect(game.sets.normal.impatience).toBe(4)
  end)
end)

describe("the cache during a switch", function()
  local function armed()
    fresh(SIMPLE({ serpent = { paralysis = 3 }, infernal = { paralysis = 5 } }))
    ataxia.prioritySwaps = { paraAst = { active = true } }
    ataxia.afflictions = { asthma = true, paralysis = true, slickness = true }
    switchTo("Serpent")
    pump()
    Algedonic.ApplySwaps("asthma")
    pump()
    expect(game.sets.serpent.paralysis).toBe(1)
    expect(ataxia_getPrio("paralysis")).toBe(1)
  end

  it("a guarded swap in a new set is not skipped because of the old set's value", function()
    armed()
    advance(1.1) -- a fresh throttle window: the swap must go out, not queue
    switchTo("Infernal")
    pump()
    expect(ataxia_getPrio("paralysis")).toBe(5)
    Algedonic.ApplySwaps("asthma")
    pump()
    expect(game.sets.infernal.paralysis).toBe(1)
  end)

  it("a first visit: the swap waits for the read and sets no hold, then the next gain sends it", function()
    armed()
    advance(1.1)
    switchTo("Infernal")
    expect(ataxia_getPrio("paralysis")).toBe(0)
    game.commands = {}
    Algedonic.ApplySwaps("asthma")
    expect(sentEver("curing priority paralysis 1")).toBeFalse()
    expect(prioWaitfor.paralysis).toBeNil()
    pump()
    expect(game.sets.infernal.paralysis).toBe(5)
    Algedonic.ApplySwaps("asthma")
    pump()
    expect(game.sets.infernal.paralysis).toBe(1)
    expect(ataxia_defaultPrioAff("paralysis")).toBe(5)
  end)

  it("a later visit: the swap goes out while the read is on its way, and lands after it", function()
    armed()
    advance(1.1)
    switchTo("Infernal")
    pump()
    advance(1.1)
    switchTo("Serpent")
    pump()
    advance(1.1)
    switchTo("Infernal")
    expect(ataxia_getPrio("paralysis")).toBe(0)
    game.commands = {}
    Algedonic.ApplySwaps("asthma")
    expect(sentEver("curing priority paralysis 1")).toBeTrue()
    pump()
    expect(game.sets.infernal.paralysis).toBe(1)
    -- The read came before the swap, so the baseline holds the set's own value.
    expect(ataxia_defaultPrioAff("paralysis")).toBe(5)
    expect(ataxia_getPrio("paralysis")).toBe(1)
  end)

  it("the one-second hold of the old set's swap does not block the new set", function()
    armed()
    expect(prioWaitfor.paralysis ~= nil).toBeTrue()
    switchTo("Infernal")
    expect(prioWaitfor.paralysis).toBeNil()
  end)

  it("an old-set confirmation that arrives before the read is replaced by the read", function()
    armed()
    switchTo("Infernal")
    table.insert(game.queue, 1, "You have set the 'paralysis' affliction to the 3 priority.")
    pump()
    expect(ataxia_getPrio("paralysis")).toBe(5)
  end)

  it("[+] and [-] links left over from before a switch do nothing", function()
    armed()
    switchTo("Infernal")
    expect(pcall(ataxia_raisePrio, "paralysis", true)).toBeTrue()
    expect(pcall(ataxia_lowerPrio, "paralysis", true)).toBeTrue()
  end)
end)

-- ---------------------------------------------------------------------------
-- normal, unknown, bash, reload
-- ---------------------------------------------------------------------------
describe("the sets with no list of their own", function()
  it("normal still restores the global default", function()
    fresh(SIMPLE({ normal = { impatience = 9 } }))
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    expect(game.sets.normal.impatience).toBe(4)
    expect(ataxia_defaultPrioAff("impatience")).toBe(4)
  end)

  it("no class set active at all answers as before", function()
    fresh(SIMPLE())
    classDetect = nil
    expect(ataxia_defaultPrioAff("impatience")).toBe(4)
    expect(ataxia_defaultPrioAff("burning3")).toBe(ataxia_defaultCuringPrios().burning)
    expect(ataxia_defaultPrioAff("nosuchaff")).toBeNil()
    expect(pcall(ataxia_setAffPrio, "impatience", 1)).toBeTrue()
    expect(ataxiaPrioSets.live.normal.impatience).toBeTrue()
  end)

  it("a class set with no baseline: nil, no swap goes out, and a restore writes nothing", function()
    fresh(SIMPLE({ infernal = { impatience = 20 } }))
    game.loseList = LOSE_ALL
    switchTo("Infernal")
    pump()
    advance(3.1)
    expect(ataxia_defaultPrioAff("impatience")).toBeNil()
    local before2 = #game.commands
    ataxia_setAffPrio("impatience", 1)
    expect(prioWaitfor.impatience).toBeNil()
    ataxia_restorePrio("impatience")
    expect(#game.commands).toBe(before2)
    expect(sentEver("curing priority impatience 4")).toBeFalse()
    expect(game.sets.infernal.impatience).toBe(20)
  end)

  it("a swap with no value to put back is left out of the switch's restore", function()
    fresh(SIMPLE({ infernal = { impatience = 20 } }))
    switchTo("Infernal")
    pump()
    ataxia_setAffPrio("nosuchaff", 1)
    pump()
    expect(game.sets.infernal.nosuchaff).toBe(1)
    game.sends = {}
    classDetect.resetToNormal()
    expect(game.sends[1]).toBe("curingset switch normal;curing priority list")
  end)

  it("every caller of ataxia_defaultPrioAff stands a nil on a class set with no baseline", function()
    fresh(SIMPLE())
    game.loseList = LOSE_ALL
    ataxia.prioritySwaps = { scyPara = { active = true }, conDis = { active = true }, astImp = { active = true },
      brSlick = { active = true }, hypoImp = { active = true }, paraAst = { active = true },
      astWear = { active = true }, fratLock = { active = true }, psionBleed = { active = true },
      magi = { active = true } }
    switchTo("Infernal")
    pump()
    advance(3.1)
    for _, aff in ipairs({ "scytherus", "confusion", "hypochondria", "paralysis", "asthma", "weariness",
      "fratricide", "slickness", "haemophilia", "frozen", "hypothermia", "dehydrated", "timeflux" }) do
      expect(pcall(Algedonic.RestoreSwaps, aff)).toBeTrue()
    end
    dofile(LEVI .. "levi_scripts/algedonic_defense_1.0/002_Damnation_Defence.lua")
    expect(pcall(Algedonic.RestorePaladin)).toBeTrue()
  end)

  it("the bash set: the global answer, writes dropped, and the plain switch alone", function()
    fresh(SIMPLE({ serpent = { impatience = 9 } }))
    switchTo("Serpent")
    pump()
    expect(ataxia_defaultPrioAff("impatience")).toBe(9)
    bashOn = true
    expect(ataxia_defaultPrioAff("impatience")).toBe(4)
    local n = #game.commands
    ataxia_setAffPrio("impatience", 1)
    ataxia_restorePrio("impatience")
    expect(#game.commands).toBe(n)
    expect(ataxiaPrioSets.live.serpent).toBeNil()

    -- classDetect's only path that can still send in the bash set: the multiple-attacker branch.
    ataxia.curingprio = { kept = 3 }
    game.sends = {}
    classDetect.state.attackers = { saibel = true }
    classDetect.state.currentCuringset = "serpent"
    classDetect.setAttackerClass("Froedine", "Monk")
    expect(#game.sends).toBe(1)
    expect(game.sends[1]).toBe("curingset switch normal")
    expect(ataxia.curingprio.kept).toBe(3)
  end)

  it("a package reload keeps the baselines and the live names", function()
    fresh(SIMPLE({ infernal = { impatience = 20 } }))
    switchTo("Infernal")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    dofile(PRIO_FILE)
    expect(ataxia_defaultPrioAff("impatience")).toBe(20)
    expect(ataxiaPrioSets.live.infernal.impatience).toBeTrue()
  end)

  it("a connection keeps them too, through a named handler, and drops the reads in flight", function()
    fresh(SIMPLE({ infernal = { impatience = 20 }, serpent = { impatience = 9 } }))
    switchTo("Infernal")
    pump()
    switchTo("Serpent")
    expect(#ataxiaPrioSets.pending).toBe(1)
    expect(game.onConnect).toBe("ataxia_prioSetsReset")
    ataxia_prioSetsReset()
    expect(#ataxiaPrioSets.pending).toBe(0)
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(20)
  end)

  -- A login that moves the server to normal, then the next visit to the set the swap was left in.
  local function reconnectThenReturn()
    fresh(SIMPLE({ serpent = { impatience = 20 } }))
    dofile(LOGIN)
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
    ataxia_prioSetsReset()
    ataxia_loginCuringsetNormal()
    pump()
    expect(game.current).toBe("normal")
    switchTo("Serpent")
    pump()
  end

  it("a swap left up across a connection is not taken for the set's value by the next read", function()
    reconnectThenReturn()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
  end)

  it("the mirror still shows the swap, so the next restore puts it back", function()
    reconnectThenReturn()
    expect(ataxia_getPrio("impatience")).toBe(1)
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
  end)

  it("or the next switch puts it back", function()
    reconnectThenReturn()
    classDetect.resetToNormal()
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
  end)

  it("nothing about the sets is under `ataxia`, so a save cannot carry it", function()
    fresh(SIMPLE({ infernal = { impatience = 20 } }))
    switchTo("Infernal")
    pump()
    for k, v in pairs(ataxia) do
      if type(v) == "table" then expect(v.baseline).toBeNil() end
    end
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(20)
  end)
end)

-- ---------------------------------------------------------------------------
-- The hidden read
-- ---------------------------------------------------------------------------
describe("our own read prints nothing", function()
  it("the header, every row and the last line are hidden; the switch's own line is not", function()
    fresh(SIMPLE({ infernal = { impatience = 20, burning = 9, burning5 = 2 } }))
    switchTo("Infernal")
    pump()
    expect(printedAnyList()).toBeFalse()
    expect(#printed).toBe(1)
    expect(printed[1]).toBe("You will now cure using the infernal set.")
    expect(saves).toBe(0)
  end)

  it("no window is left open behind it", function()
    fresh(SIMPLE({ infernal = { impatience = 20 } }))
    switchTo("Infernal")
    pump()
    expect(chain).toBe(0)
    expect(ataxiaPrioSets.read).toBeNil()
    expect(#ataxiaPrioSets.pending).toBe(0)
    deliver("1: a line that only looks like a row")
    expect(printed[#printed]).toBe("1: a line that only looks like a row")
  end)

  it("does not depend on whether Mudlet runs the temp trigger before the permanent ones", function()
    fresh(SIMPLE({ infernal = { impatience = 20, burning = 9, burning5 = 2 } }))
    game.tempsFirst = true
    switchTo("Infernal")
    pump()
    expect(printedAnyList()).toBeFalse()
    expect(ataxia_defaultPrioAff("impatience")).toBe(20)
    expect(chain).toBe(0)
    expect(saves).toBe(0)
  end)

  it("wrapped rows are hidden and read in full", function()
    fresh(SIMPLE({ infernal = { aeon = 2, entangled = 2, peace = 2, scytherus = 2, bound = 2, impaled = 2, sleeping = 2,
      transfixation = 2, voyria = 2, webbed = 2, heartseed = 2, prone = 2, disrupted = 2, hypothermia = 2,
      calcifiedskull = 2, calcifiedtorso = 2, unweavingbody5 = 2, unweavingmind5 = 2 } }))
    game.wrapAt = 80
    switchTo("Infernal")
    pump()
    expect(printedAnyList()).toBeFalse()
    expect(#printed).toBe(1)
    expect(ataxia_defaultPrioAff("unweavingmind5")).toBe(2)
    expect(ataxia_defaultPrioAff("voyria")).toBe(2)
  end)

  it("the real capture: every line is hidden and every row is read", function()
    local lines = {}
    for l in (read(CAPTURE_FILE) .. "\n"):gmatch("([^\n]*)\n") do
      lines[#lines + 1] = (l:gsub("\r$", ""))
    end
    fresh(SIMPLE({ normal = {} }))
    switchTo("Serpent")
    game.queue = {}
    -- From the header on, as the capture has it, under the name we asked for.
    local started = false
    for _, l in ipairs(lines) do
      if l:match("^Your affliction curing priorities") then
        started = true
        l = l:gsub("priority set normal:", "priority set serpent:")
      end
      if started and l ~= "" then game.queue[#game.queue + 1] = l end
    end
    pump()
    expect(printedAnyList()).toBeFalse()
    expect(#printed).toBe(0)
    local b = ataxiaPrioSets.baseline.serpent
    expect(b ~= nil).toBeTrue()
    expect(b.brokenrightarm).toBe(1)
    expect(b.transfixation).toBe(2)    -- on a wrapped row
    expect(b.unweavingmind4).toBe(2)   -- `unweavingmind(4)` at the end of a wrapped row
    expect(b.burning5).toBe(4)
    expect(b.burning4).toBe(6)
    expect(b.burning).toBe(9)
    expect(b.crackedribs).toBe(9)      -- at the start of a wrapped row
    expect(b.fratricide).toBe(25)
    expect(b.insomnia).toBe(26)
    expect(b["5"]).toBeNil()
  end)
end)

describe("a list the user types", function()
  local function onInfernal()
    fresh(SIMPLE({ infernal = { impatience = 20, burning = 9, burning5 = 2 } }))
    switchTo("Infernal")
    pump()
    printed = {}
    saves = 0
  end

  it("prints exactly what the game sent", function()
    onInfernal()
    send("curing priority list")
    local want = listLines("infernal")
    pump()
    expect(#printed).toBe(#want)
    for i, l in ipairs(want) do expect(printed[i]).toBe(l) end
  end)

  it("refreshes the cache, with stacked names whole", function()
    onInfernal()
    ataxia.curingprio = { ghost = 1 }
    send("curing priority list")
    pump()
    expect(ataxia.curingprio.ghost).toBeNil()
    expect(ataxia.curingprio.impatience).toBe(20)
    expect(ataxia.curingprio.burning5).toBe(2)
    expect(ataxia.curingprio["5"]).toBeNil()
  end)

  it("never changes a baseline, even when the set's values have moved", function()
    onInfernal()
    game.sets.infernal.impatience = 15
    send("curing priority list")
    pump()
    expect(ataxia.curingprio.impatience).toBe(15)
    expect(ataxia_defaultPrioAff("impatience")).toBe(20)
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(20)
  end)

  it("still saves, as 718 always meant to, and closes the chain", function()
    onInfernal()
    send("curing priority list")
    pump()
    expect(saves).toBe(1)
    expect(chain).toBe(0)
  end)

  it("names a set we did not ask for: it prints even while a read is pending", function()
    fresh(SIMPLE({ infernal = { impatience = 20 }, serpent = { impatience = 9 } }))
    switchTo("Infernal")
    -- A header for `serpent` can only be a list the user typed before this switch.
    local block = listLines("serpent")
    for i = #block, 1, -1 do table.insert(game.queue, 1, block[i]) end
    pump()
    local seen
    for _, l in ipairs(printed) do
      if l == "Your affliction curing priorities for the priority set serpent:" then seen = true end
    end
    expect(seen).toBeTrue()
    expect(ataxia_defaultPrioAff("impatience")).toBe(20)
    expect(ataxiaPrioSets.baseline.serpent).toBeNil()
  end)
end)

describe("a read that goes wrong cannot hide later lines", function()
  it("the first line that is not a list row ends the window and prints", function()
    fresh(SIMPLE({ infernal = { impatience = 2, paralysis = 3 } }))
    switchTo("Infernal")
    deliver("You will now cure using the infernal set.")
    game.queue = {}
    local lines = listLines("infernal")
    deliver(lines[1]) -- header
    deliver(lines[2]) -- 1:
    deliver(lines[3]) -- 2: impatience
    expect(ataxiaPrioSets.read ~= nil).toBeTrue()
    printed = {}
    deliver("Saibel slashes into you with a dirk.")
    expect(printed[1]).toBe("Saibel slashes into you with a dirk.")
    expect(ataxiaPrioSets.read).toBeNil()
    expect(chain).toBe(0)
    deliver("3: this is no longer hidden")
    expect(printed[2]).toBe("3: this is no longer hidden")
  end)

  it("a cut read fills no baseline: a half-read list is worse than none", function()
    fresh(SIMPLE({ infernal = { impatience = 2, paralysis = 3 } }))
    switchTo("Infernal")
    game.queue = {}
    local lines = listLines("infernal")
    deliver(lines[1])
    deliver(lines[3])
    deliver("A prompt line, or anything else.")
    expect(ataxiaPrioSets.baseline.infernal).toBeNil()
    expect(ataxia_defaultPrioAff("impatience")).toBeNil()
  end)

  it("a names-only line after a row with no trailing comma is not a continuation", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    switchTo("Infernal")
    game.queue = {}
    local lines = listLines("infernal")
    deliver(lines[1])
    deliver(lines[3])
    printed = {}
    deliver("impatience, paralysis")
    expect(printed[1]).toBe("impatience, paralysis")
    expect(ataxiaPrioSets.read).toBeNil()
  end)

  it("a new header ends an unfinished read, and only the new read fills", function()
    fresh(SIMPLE({ serpent = { impatience = 9 }, infernal = { impatience = 20 } }))
    switchTo("Serpent")
    switchTo("Infernal")
    game.queue = {}
    deliver(listLines("serpent")[1])
    for _, l in ipairs(listLines("infernal")) do deliver(l) end
    expect(ataxiaPrioSets.baseline.serpent).toBeNil()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(20)
    expect(printedAnyList()).toBeFalse()
    expect(liveTemps()).toBe(0)
  end)

  it("a reply cut after the header: the timeout ends the window", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    switchTo("Infernal")
    game.queue = {}
    local lines = listLines("infernal")
    deliver(lines[1])
    expect(ataxiaPrioSets.read ~= nil).toBeTrue()
    advance(3.1)
    expect(ataxiaPrioSets.read).toBeNil()
    expect(chain).toBe(0)
    printed = {}
    deliver("2: impatience")
    expect(printed[1]).toBe("2: impatience")
  end)

  it("a lost reply: the timeout asks again, the reply is hidden, and it fills the baseline", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    game.loseList = { [1] = true }
    switchTo("Infernal")
    pump()
    expect(#ataxiaPrioSets.pending).toBe(1)
    advance(3.1)
    expect(game.listsAsked).toBe(2)
    expect(#ataxiaPrioSets.pending).toBe(1)
    pump()
    expect(printedAnyList()).toBeFalse()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(2)
    expect(ataxia_getPrio("impatience")).toBe(2)
  end)

  it("the retries stop, and a later typed list prints", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    game.loseList = LOSE_ALL
    switchTo("Infernal")
    pump()
    for _ = 1, 8 do advance(3.1); pump() end
    expect(game.listsAsked).toBe(4)
    expect(#ataxiaPrioSets.pending).toBe(0)
    game.loseList = nil
    printed = {}
    send("curing priority list")
    pump()
    expect(printedAnyList()).toBeTrue()
    expect(ataxiaPrioSets.baseline.infernal).toBeNil()
  end)

  it("a new visit asks again from the start", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    game.loseList = LOSE_ALL
    switchTo("Infernal")
    for _ = 1, 8 do advance(3.1); pump() end
    classDetect.resetToNormal()
    pump()
    game.loseList = { [5] = true, [6] = true, [7] = true }
    advance(1)
    switchTo("Infernal")
    for _ = 1, 3 do pump(); advance(3.1) end
    pump()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(2)
  end)

  it("a read that gave way to a full window goes out once the window has room", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    local t = ataxia.prioThrottle
    advance(DEBOUNCE)
    t.sentThisSecond, t.windowStart = 5, clock
    classDetect.switchCuringset("Infernal")
    expect(game.sends[1]).toBe("curingset switch infernal")
    expect(game.listsAsked).toBe(0)
    pump()
    advance(1.2)
    expect(game.listsAsked).toBe(1)
    pump()
    expect(printedAnyList()).toBeFalse()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(2)
  end)

  it("a set that already has a baseline is not asked again", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    switchTo("Infernal")
    pump()
    local asked = game.listsAsked
    advance(3.1)
    expect(game.listsAsked).toBe(asked)
  end)

  it("a retry stops when the set is no longer the active one", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    game.loseList = { [1] = true }
    switchTo("Infernal")
    pump()
    classDetect.resetToNormal()
    pump()
    local asked = game.listsAsked
    advance(3.1)
    expect(game.listsAsked).toBe(asked)
    expect(ataxiaPrioSets.baseline.infernal).toBeNil()
  end)

  it("a read that gave way is not asked again once the set has changed", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    local t = ataxia.prioThrottle
    advance(DEBOUNCE)
    t.sentThisSecond, t.windowStart = 5, clock
    classDetect.switchCuringset("Infernal")
    expect(game.listsAsked).toBe(0)
    pump()
    advance(1.05) -- the window has rolled, and the retry waits for 1.1 s
    classDetect.resetToNormal()
    pump()
    expect(game.listsAsked).toBe(1)
    advance(0.2)
    expect(game.listsAsked).toBe(1)
    expect(ataxiaPrioSets.baseline.infernal).toBeNil()
  end)

  it("a read older than the timeout is never hidden, even if its timer died", function()
    fresh(SIMPLE({ infernal = { impatience = 2 } }))
    game.loseList = { [1] = true }
    switchTo("Infernal")
    pump()
    timers = {}
    ataxiaPrioSets.timer = nil
    advance(3.1)
    expect(#ataxiaPrioSets.pending).toBe(1)
    printed = {}
    send("curing priority list")
    pump()
    expect(printedAnyList()).toBeTrue()
  end)
end)

-- ---------------------------------------------------------------------------
-- The queue
-- ---------------------------------------------------------------------------
describe("the throttle queue at a switch", function()
  local function withQueue()
    fresh(SIMPLE({ serpent = {} }))
    switchTo("Serpent")
    pump()
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 4, clock + 0.7
    ataxia_sendCuringPriority("curing priority impatience 1", false)
    ataxia_sendCuringPriority("curing priority defence insulation 25", false)
    ataxia_sendCuringPriority("curing priority frozen 2;curing priority shivering 2;curing priority defence fangbarrier 2", false)
    ataxia_sendCuringPriority("curing priority health", false)
    expect(#t.commands).toBe(4)
    return t
  end

  it("stored writes are dropped, and the defence writes it holds are kept", function()
    local t = withQueue()
    switchTo("Infernal")
    expect(#t.commands).toBe(3)
    expect(t.commands[1].cmd).toBe("curing priority defence insulation 25")
    expect(t.commands[2].cmd).toBe("curing priority defence fangbarrier 2")
    expect(t.commands[3].cmd).toBe("curing priority health")
  end)

  it("a dropped write never reaches the new set", function()
    local t = withQueue()
    switchTo("Infernal")
    pump()
    advance(1.1)
    ataxia_drainPrioQueue()
    pump()
    expect(game.sets.infernal.impatience).toBeNil()
    expect(sentEver("curing priority frozen 2")).toBeFalse()
    expect(#t.commands).toBe(0)
    expect(sentEver("curing priority defence insulation 25")).toBeTrue()
  end)
end)

-- ---------------------------------------------------------------------------
-- Two switches, one flight
-- ---------------------------------------------------------------------------
describe("two quick switches", function()
  it("each reply goes to its own set, in order, and none prints", function()
    fresh(SIMPLE({ serpent = { impatience = 9 }, infernal = { impatience = 20 } }))
    switchTo("Serpent")
    switchTo("Infernal")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(9)
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(20)
    expect(printedAnyList()).toBeFalse()
    expect(#ataxiaPrioSets.pending).toBe(0)
    expect(ataxia_getPrio("impatience")).toBe(20)
    expect(ataxia_defaultPrioAff("impatience")).toBe(20)
  end)

  it("the first set's swap goes back before the second switch", function()
    fresh(SIMPLE({ serpent = { impatience = 9 }, infernal = { impatience = 20 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    game.sends = {}
    switchTo("Infernal")
    expect(game.sends[1]).toBe("curing priority impatience 9;curingset switch infernal;curing priority list")
  end)

  it("the mirror holds the active set: a superseded reply fills only its baseline", function()
    fresh(SIMPLE({ serpent = { impatience = 9 }, infernal = { impatience = 20 } }))
    game.loseList = { [2] = true }
    switchTo("Serpent")
    switchTo("Infernal")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(9)
    expect(ataxia_getPrio("impatience")).toBe(0)
  end)

  it("a lost first reply: the second header still finds its read", function()
    fresh(SIMPLE({ serpent = { impatience = 9 }, infernal = { impatience = 20 } }))
    game.loseList = { [1] = true }
    switchTo("Serpent")
    switchTo("Infernal")
    pump()
    expect(ataxiaPrioSets.baseline.serpent).toBeNil()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(20)
    expect(printedAnyList()).toBeFalse()
    expect(#ataxiaPrioSets.pending).toBe(0)
  end)

  it("a return to a set re-reads it", function()
    fresh(SIMPLE({ serpent = { impatience = 9 } }))
    switchTo("Serpent")
    pump()
    game.sets.serpent.impatience = 6 -- the user tuned it between fights
    classDetect.resetToNormal()
    pump()
    advance(1)
    switchTo("Serpent")
    pump()
    expect(ataxia_defaultPrioAff("impatience")).toBe(6)
  end)
end)

-- ---------------------------------------------------------------------------
-- Swaps that do not go through ataxia_setAffPrio
-- ---------------------------------------------------------------------------
describe("a direct swap goes back at the switch", function()
  -- The real shield path: GMCP says the defence came up, gotDef runs.
  local function realShield()
    ataxia.prioritySwaps = { parshield = { active = true } }
    ataxia.settings.defences = { current = "x", keepup = { x = { shield = true } }, defup = { x = {} } }
    ataxia.defences = {}
    ataxiaBasher = { enabled = true }
    trueDef = function(d) return d end
    isDefenceForCurrentClass = function() return true end
    ataxia_defenceTakesPriority = function() return true end
    gmcp = { Char = { Defences = { Add = { name = "shield", desc = "x" } } } }
    dofile(DEF_API)
    gotDef()
  end

  local function realTumble()
    ataxia.prioritySwaps = { parshield = { active = true } }
    ataxia_boxEcho = function() end
    gmcp = { Char = { Status = { class = "Monk" } } }
    matches = { "You begin to tumble agilely to the north.", "north" }
    body(TUMBLE)()
  end

  local function onSerpent(values)
    fresh(SIMPLE({ serpent = values, infernal = { paralysis = 5, slickness = 6, scalded = 7, frozen = 8, shivering = 9 } }))
    switchTo("Serpent")
    pump()
  end

  -- The debounce is cleared, because the point is a switch inside the swap's short hold.
  local function leaveInsideHold(to)
    advance(0.6)
    classDetect.state.lastSwitchTime = 0
    game.sends = {}
    classDetect.switchCuringset(to)
    pump()
  end

  it("the shield's 25s go back, and the delayed restore leaves the new set alone", function()
    onSerpent({ paralysis = 3, slickness = 4 })
    realShield()
    pump()
    expect(game.sets.serpent.paralysis).toBe(25)
    expect(game.sets.serpent.slickness).toBe(25)
    leaveInsideHold("Infernal")
    advance(1.0)
    pump()
    expect(game.sets.serpent.paralysis).toBe(3)
    expect(game.sets.serpent.slickness).toBe(4)
    expect(game.sets.infernal.paralysis).toBe(5)
    expect(game.sets.infernal.slickness).toBe(6)
  end)

  it("the next visit reads the set's own values, not the 25s", function()
    onSerpent({ paralysis = 3, slickness = 4 })
    realShield()
    pump()
    leaveInsideHold("Infernal")
    advance(1.0)
    pump()
    classDetect.resetToNormal()
    pump()
    advance(1)
    switchTo("Serpent")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.paralysis).toBe(3)
    expect(ataxiaPrioSets.baseline.serpent.slickness).toBe(4)
  end)

  it("the tumble's 25s go back", function()
    onSerpent({ paralysis = 3, slickness = 4 })
    realTumble()
    pump()
    expect(game.sets.serpent.paralysis).toBe(25)
    leaveInsideHold("Infernal")
    advance(3.5)
    pump()
    expect(game.sets.serpent.paralysis).toBe(3)
    expect(game.sets.serpent.slickness).toBe(4)
  end)

  it("timeflux's scalded 26 goes back", function()
    onSerpent({ scalded = 16 })
    ataxia.prioritySwaps = {}
    ataxia.afflictions.timeflux = true
    Algedonic.ApplySwaps("timeflux")
    pump()
    expect(game.sets.serpent.scalded).toBe(26)
    leaveInsideHold("Infernal")
    expect(game.sets.serpent.scalded).toBe(16)
    expect(game.sets.infernal.scalded).toBe(7)
  end)

  it("Magi: 20 then 2 in one pass ends at 2, the hold would have dropped it, and both go back", function()
    onSerpent({ frozen = 11, shivering = 12 })
    ataxia.prioritySwaps = { magi = { active = true } }
    ataxia.afflictions.frozen = true
    Algedonic.ApplySwaps("hypothermia")
    pump()
    advance(1.1) -- 2 + 3 commands pass the throttle's 4, so the second send drains from the queue.
    pump()
    expect(game.sets.serpent.frozen).toBe(2)
    expect(game.sets.serpent.shivering).toBe(2)
    leaveInsideHold("Infernal")
    expect(game.sets.serpent.frozen).toBe(11)
    expect(game.sets.serpent.shivering).toBe(12)
  end)

  it("Paladin: the disembowel legs go back", function()
    onSerpent({ brokenleftleg = 7, brokenrightleg = 8 })
    dofile(DAMNATION)
    game.tc = "Paladin"
    ataxia.afflictions = { brokenleftleg = true, brokenrightleg = true, brokenleftarm = true }
    Algedonic.AntiPaladin()
    pump()
    expect(game.sets.serpent.brokenleftleg).toBe(1)
    leaveInsideHold("Infernal")
    expect(game.sets.serpent.brokenleftleg).toBe(7)
    expect(game.sets.serpent.brokenrightleg).toBe(8)
  end)

  it("a shield with no switch restores once and leaves nothing live", function()
    onSerpent({ paralysis = 3, slickness = 4 })
    realShield()
    pump()
    advance(1.5)
    pump()
    expect(game.sets.serpent.paralysis).toBe(3)
    expect(ataxiaPrioSets.live.serpent.paralysis).toBeNil()
    expect(ataxiaPrioSets.live.serpent.slickness).toBeNil()
    advance(2)
    classDetect.state.lastSwitchTime = 0
    game.sends = {}
    classDetect.switchCuringset("Infernal")
    expect(game.sends[1]).toBe("curingset switch infernal;curing priority list")
  end)

  it("the bash guard drops it, and nothing is live", function()
    onSerpent({ paralysis = 3, slickness = 4 })
    bashOn = true
    realShield()
    pump()
    expect(game.sets.serpent.paralysis).toBe(3)
    expect(ataxiaPrioSets.live.serpent).toBeNil()
  end)

  it("a class set with no baseline: the shield does not park", function()
    fresh(SIMPLE({ serpent = { paralysis = 3, slickness = 4 } }))
    switchTo("Serpent")
    realShield()
    pump()
    expect(game.sets.serpent.paralysis).toBe(3)
    expect(ataxiaPrioSets.live.serpent).toBeNil()
  end)

  it("a defence write in the same send stays unmarked", function()
    onSerpent({ frozen = 11, shivering = 12 })
    ataxia_sendPrioSwap("curing priority frozen 2;curing priority defence insulation 2", false)
    expect(ataxiaPrioSets.live.serpent.frozen).toBeTrue()
    expect(ataxiaPrioSets.live.serpent.defence).toBeNil()
    expect(ataxiaPrioSets.live.serpent.insulation).toBeNil()
  end)

  it("the [+] link is the user's tuning and survives a switch", function()
    onSerpent({ paralysis = 3, slickness = 4 })
    ataxia_raisePrio("paralysis", true)
    pump()
    expect(game.sets.serpent.paralysis).toBe(2)
    leaveInsideHold("Infernal")
    expect(game.sets.serpent.paralysis).toBe(2)
  end)

  it("a multi-set table write stays unmarked", function()
    onSerpent({ paralysis = 3 })
    ataxia_sendPrioSwap("curing priority paralysis 1 slickness 2", false)
    expect(ataxiaPrioSets.live.serpent).toBeNil()
  end)

  -- The burn park needs the whole basher to run, so its call site is read here.
  it("no stored swap goes straight to the throttle at these call sites", function()
    for _, p in ipairs({ DEF_API, TUMBLE, ANTI, DAMNATION, ENGAGED }) do
      local source = read(p):gsub('ataxia_sendCuringPriority%(%s*"curing priority defence', ""):gsub(
        'ataxia_sendCuringPriority%(%s*"curing priority health', ""):gsub('ataxia_sendCuringPriority%(%s*"curing priority mana', "")
      expect(source:find('ataxia_sendCuringPriority%(%s*"curing priority %a+%d* %d') == nil).toBeTrue()
    end
  end)
end)

describe("the default table stops at a switch", function()
  local function changed(set, want)
    local n = 0
    for aff, v in pairs(want) do
      if game.sets[set][aff] ~= v then n = n + 1 end
    end
    return n
  end
  local WANT = { impatience = 20, paralysis = 3, slickness = 6, burning = 9, asthma = 7 }
  local function values()
    local t = {}
    for aff, v in pairs(WANT) do t[aff] = v end
    return t
  end

  it("a class switch mid-send: nothing more lands, and the table is not recorded as sent", function()
    fresh(SIMPLE({ serpent = values() }))
    ataxia_sendDefaultPrios()
    advance(2.5)
    classDetect.switchCuringset("Serpent")
    advance(12)
    pump()
    expect(changed("serpent", WANT)).toBe(0)
    expect(ataxia.settings.prioSentSig).toBeNil()
  end)

  it("with no switch every batch goes, and the table is recorded", function()
    fresh(SIMPLE())
    ataxia_sendDefaultPrios()
    advance(12)
    pump()
    expect(game.sets.normal.impatience).toBe(ataxia_defaultCuringPrios().impatience)
    expect(ataxia.settings.prioSentSig ~= nil).toBeTrue()
  end)

  -- The bash guard already drops the writes. The stop is what keeps the table recorded as unsent.
  it("the bash set starting mid-send stops it too, and the table is not recorded as sent", function()
    fresh(SIMPLE({ bash = values() }))
    ataxia.settings.bashcuring = { enabled = true, installed = true, active = false, setname = "bash" }
    dofile(LEVI .. "ataxia/ataxia/008_Bash_Curing_Profile.lua")
    ataxia_sendDefaultPrios()
    advance(2.5)
    ataxia_bashProfileOn()
    expect(game.current).toBe("bash")
    advance(12)
    pump()
    expect(changed("bash", WANT)).toBe(0)
    expect(ataxia.settings.prioSentSig).toBeNil()
  end)
end)

describe("a value set during a visit is the set's own", function()
  local function onSerpent(values)
    fresh(SIMPLE({ serpent = values, infernal = { impatience = 10 } }))
    switchTo("Serpent")
    pump()
  end

  it("typed: a later swap and restore put back what the user set", function()
    onSerpent({ impatience = 20 })
    send("curing priority impatience 12")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(12)
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    expect(game.sets.serpent.impatience).toBe(12)
  end)

  it("the [+] link counts too", function()
    onSerpent({ impatience = 20 })
    ataxia_raisePrio("impatience", true)
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(19)
  end)

  it("a swap's own line is not taken", function()
    onSerpent({ impatience = 20 })
    ataxia_setAffPrio("impatience", 1)
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
  end)

  it("a direct swap's own line is not taken", function()
    onSerpent({ paralysis = 3 })
    ataxia_sendPrioSwap("curing priority paralysis 25", false)
    pump()
    expect(ataxiaPrioSets.baseline.serpent.paralysis).toBe(3)
  end)

  -- The read is lost here. A read that lands replaces the baseline anyway.
  it("a line from the set we left, with the read still due, is not taken", function()
    onSerpent({ impatience = 20 })
    classDetect.resetToNormal()
    pump()
    advance(1)
    switchTo("Infernal")
    pump()
    game.loseList = { [game.listsAsked + 1] = true }
    advance(1)
    switchTo("Serpent")
    table.insert(game.queue, 1, "You have set the 'impatience' affliction to the 3 priority.")
    pump()
    expect(#ataxiaPrioSets.pending).toBe(1)
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
  end)

  it("a line from the set we left, when the read gave way, is not taken", function()
    fresh(SIMPLE({ serpent = { impatience = 20 }, infernal = { impatience = 10 } }))
    switchTo("Infernal")
    pump()
    advance(1)
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 5, clock
    classDetect.state.lastSwitchTime = 0
    classDetect.switchCuringset("Infernal")
    expect(#ataxiaPrioSets.pending).toBe(0)
    pump()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(10)
  end)

  it("on normal the table answers, so nothing is stored", function()
    fresh(SIMPLE())
    send("curing priority impatience 12")
    pump()
    expect(ataxiaPrioSets.baseline.normal).toBeNil()
    expect(ataxia_defaultPrioAff("impatience")).toBe(4)
  end)
end)

describe("the queue keeps its order", function()
  it("a restore cannot pass the swap queued before it", function()
    fresh(SIMPLE({ serpent = { hypochondria = 10 } }))
    switchTo("Serpent")
    pump()
    advance(1.2)
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 4, clock - 0.9
    ataxia_setAffPrio("hypochondria", 1)
    expect(#t.commands).toBe(1)
    advance(0.11) -- the window has rolled and the drain has not run
    ataxia.curingprio.hypochondria = 1
    ataxia_restorePrio("hypochondria")
    expect(#t.commands).toBe(2)
    advance(1.5)
    pump()
    expect(game.sets.serpent.hypochondria).toBe(10)
  end)

  it("a queued write still goes out in order after the drain", function()
    fresh(SIMPLE())
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 4, clock
    ataxia_sendCuringPriority("curing priority defence a 1", false)
    ataxia_sendCuringPriority("curing priority defence b 1", false)
    advance(1.2)
    expect(game.sends[1]).toBe("curing priority defence a 1")
    expect(game.sends[2]).toBe("curing priority defence b 1")
  end)

  -- ataxia.prioThrottle is saved with `ataxia`. The table a load leaves behind has queued commands
  -- and the id of a timer from another session.
  it("a queue that came back from a save blocks nothing, and its commands never go out", function()
    fresh(SIMPLE())
    local t = ataxia.prioThrottle
    t.commands = { { cmd = "curing priority paralysis 1", silent = false } }
    t.drainTimer = 99999
    expect(ataxia_sendCuringPriority("curing priority defence a 1", false)).toBe("sent")
    expect(#t.commands).toBe(0)
    advance(2)
    expect(sentEver("curing priority paralysis 1")).toBeFalse()
  end)

  it("a save taken with the queue full still lets a later queued write drain", function()
    fresh(SIMPLE())
    local t = ataxia.prioThrottle
    t.drainTimer = 99999
    t.sentThisSecond, t.windowStart = 4, clock
    expect(ataxia_sendCuringPriority("curing priority defence a 1", false)).toBe("queued")
    advance(1.2)
    expect(sentEver("curing priority defence a 1")).toBeTrue()
  end)

  it("a second queue, after the first has drained, drains too", function()
    fresh(SIMPLE())
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 4, clock
    expect(ataxia_sendCuringPriority("curing priority defence a 1", false)).toBe("queued")
    advance(1.2)
    expect(sentEver("curing priority defence a 1")).toBeTrue()
    t.sentThisSecond, t.windowStart = 4, clock
    expect(ataxia_sendCuringPriority("curing priority defence b 2", false)).toBe("queued")
    advance(1.2)
    expect(sentEver("curing priority defence b 2")).toBeTrue()
  end)

  it("the drain drops a stored write once the bash set is active, and keeps a defence write", function()
    fresh(SIMPLE({ serpent = { hypochondria = 10 }, bash = { hypochondria = 6 } }))
    switchTo("Serpent")
    pump()
    advance(1.2)
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 4, clock
    ataxia_setAffPrio("hypochondria", 1)
    ataxia_sendCuringPriority("curing priority defence insulation 25", false)
    bashOn = true
    send("curingset switch bash")
    advance(1.2)
    pump()
    expect(game.sets.bash.hypochondria).toBe(6)
    expect(sentEver("curing priority defence insulation 25")).toBeTrue()
  end)
end)

describe("the login's own switch to normal", function()
  it("moves the state with the server, so a restore on normal reads the table", function()
    fresh(SIMPLE({ serpent = { paralysis = 6 } }))
    dofile(LOGIN)
    switchTo("Serpent")
    pump()
    ataxia_prioSetsReset()
    ataxia_loginCuringsetNormal()
    pump()
    expect(game.current).toBe("normal")
    expect(classDetect.state.currentCuringset).toBe("normal")
    ataxia_setAffPrio("paralysis", 1)
    pump()
    advance(1.1)
    ataxia_restorePrio("paralysis")
    pump()
    expect(game.sets.normal.paralysis).toBe(ataxia_defaultCuringPrios().paralysis)
    expect(game.sets.serpent.paralysis).toBe(6)
  end)

  it("levilogin has no raw switch left, and six branches use the helper", function()
    local source = read(LOGIN)
    local _, helper = source:gsub("ataxia_loginCuringsetNormal%(%)", "")
    local _, raw = source:gsub('send%("curingset switch normal"%)', "")
    expect(helper).toBe(7) -- the six calls and the definition
    expect(raw).toBe(1)    -- the helper's own send
  end)

  it("a connection alone does not touch the state: the server keeps its set on the other classes", function()
    fresh(SIMPLE({ serpent = { slickness = 6 } }))
    switchTo("Serpent")
    pump()
    ataxia_prioSetsReset()
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(game.current).toBe("serpent")
  end)
end)

describe("astImp's put-back when the raise and the weariness arrive in one packet", function()
  local function raised(class)
    fresh(SIMPLE({ serpent = { impatience = 2 }, alchemist = { impatience = 2 } }))
    game.tc = class
    ataxia.prioritySwaps = { astImp = { active = true } }
    ataxia.afflictions = { paralysis = true }
    switchTo(class)
    pump()
    ataxia.afflictions.asthma = true
    Algedonic.ApplySwaps("asthma")
    ataxia.afflictions.weariness = true
    Algedonic.ApplySwaps("weariness")
    expect(ataxia_getPrio("impatience")).toBe(2)
  end

  it("the confirmation puts impatience back against a Serpent", function()
    raised("Serpent")
    expect(game.sets.serpent.impatience).toBe(1)
    pump()
    expect(game.sets.serpent.impatience).toBe(2)
  end)

  it("an Alchemist keeps the raise", function()
    raised("Alchemist")
    pump()
    expect(game.sets.alchemist.impatience).toBe(1)
  end)

  it("toggled off, the confirmation changes nothing", function()
    raised("Serpent")
    ataxia.prioritySwaps.astImp.active = false
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
  end)

  it("a raise with no weariness stays up", function()
    fresh(SIMPLE({ serpent = { impatience = 2 } }))
    game.tc = "Serpent"
    ataxia.prioritySwaps = { astImp = { active = true } }
    ataxia.afflictions = { paralysis = true, asthma = true }
    switchTo("Serpent")
    pump()
    Algedonic.ApplySwaps("asthma")
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
  end)
end)

-- ---------------------------------------------------------------------------
-- The second bench: CURINGSET LIST, the login, a restart
-- ---------------------------------------------------------------------------
-- The CURINGSET LIST reply reaches the capture in 009, which parses it on the next tick.
local function answer()
  pump()
  advance(0)
  pump()
end

-- The real levilogin. It needs the whole client, so anything the bench does not hold is a stub that
-- does nothing. Its string timers need that client too, and do nothing for these tests.
local function login(class)
  dofile(LOGIN)
  if not ataxia_curingsetRefresh then dofile(CURINGSET_FILE) end
  ataxia.settings.use = ataxia.settings.use or {}
  gmcp = { Char = { Status = { class = class, name = "Levi" }, Vitals = { charstats = { "a", "b", "c", "d" } } } }
  local stub
  stub = setmetatable({}, { __index = function(t) return t end, __call = function() return nil end })
  setfenv(levilogin, setmetatable({ mmp = stub, zgui = stub }, {
    __index = function(_, k)
      local v = _G[k]
      if v == nil then return stub end
      return v
    end,
    __newindex = function(_, k, v) _G[k] = v end,
  }))
  levilogin()
  for id, t in pairs(timers) do
    if type(t.fn) == "string" then timers[id] = nil end
  end
end

-- What a new Lua state keeps: the server, the disk, and the saved `ataxia` table.
local function restart()
  timers, temps, chain = {}, {}, 0
  prioWaitfor, prioWaitrestore = nil, nil
  classDetect, ataxiaPrioSets, ataxiaPrioSetsHandler, ataxiaPrioLinkHandler = nil, nil, nil, nil
  ataxia.prioThrottle = nil
  ataxia_curingsetRefresh = nil
  dofile(DEFAULTS_FILE)
  dofile(PRIO_FILE)
  dofile(ENGINE)
  dofile(ANTI)
  classDetect.config.echoSwitches = false
  classDetect.config.apiLookupEnabled = false
end

-- The state names normal and the server is on the set the last session left.
local function serverLeftOn(set, values)
  local t = SIMPLE({ infernal = { impatience = 10 } })
  t[set] = values
  fresh(t)
  game.current = set
end

local function linesOf(pattern)
  local n = 0
  for _, m in ipairs(echoes) do
    if m:find(pattern, 1, true) then n = n + 1 end
  end
  return n
end

local function switchesSent()
  local n = 0
  for _, c in ipairs(game.commands) do
    if c:match("^curingset switch ") then n = n + 1 end
  end
  return n
end

local LINE = "You have set the '%s' affliction to the %d priority."

-- ---------------------------------------------------------------------------
-- D1: reset prios
-- ---------------------------------------------------------------------------
describe("reset prios asks the game which set is active", function()
  local function onSerpent()
    fresh(SIMPLE({ serpent = { impatience = 9, paralysis = 12 } }))
    dofile(CURINGSET_FILE)
    switchTo("Serpent")
    pump()
  end

  it("on a class set nothing is written, the table is not marked sent, and one line says why", function()
    onSerpent()
    body(RESET_ALIAS)()
    answer()
    advance(12)
    pump()
    expect(game.sets.serpent.impatience).toBe(9)
    expect(game.sets.serpent.paralysis).toBe(12)
    expect(ataxia.settings.prioSentSig).toBeNil()
    expect(#echoes).toBe(1)
    expect(echoes[1]).toContain("serpent")
    expect(echoes[1]).toContain("reset prios")
  end)

  it("on normal the table goes to normal", function()
    fresh(SIMPLE({ serpent = { impatience = 9 } }))
    dofile(CURINGSET_FILE)
    body(RESET_ALIAS)()
    answer()
    advance(12)
    pump()
    expect(game.sets.normal.impatience).toBe(4)
    expect(game.sets.serpent.impatience).toBe(9)
    expect(ataxia.settings.prioSentSig ~= nil).toBeTrue()
    expect(#echoes).toBe(0)
  end)

  it("a lost reply sends nothing and says so, once", function()
    fresh(SIMPLE())
    dofile(CURINGSET_FILE)
    game.loseCs = LOSE_ALL
    body(RESET_ALIAS)()
    pump()
    advance(4.1)
    advance(12)
    pump()
    expect(game.sets.normal.impatience).toBeNil()
    expect(#echoes).toBe(1)
    expect(echoes[1]).toContain("unknown")
    expect(echoes[1]).toContain("normal")
  end)

  it("a switch while the answer is on its way stops the table, though the answer says normal", function()
    fresh(SIMPLE({ serpent = { impatience = 9 } }))
    dofile(CURINGSET_FILE)
    body(RESET_ALIAS)()
    switchTo("Serpent")
    answer()
    advance(12)
    pump()
    expect(game.sets.serpent.impatience).toBe(9)
    expect(ataxia.settings.prioSentSig).toBeNil()
    expect(echoes[1]).toContain("serpent")
  end)

  it("the sync check has the same stop", function()
    fresh(SIMPLE({ serpent = { impatience = 9 } }))
    dofile(CURINGSET_FILE)
    ataxia_prioSyncCheck()
    switchTo("Serpent")
    answer()
    advance(12)
    pump()
    expect(game.sets.serpent.impatience).toBe(9)
    expect(ataxia.settings.prioSentSig).toBeNil()
    expect(echoes[1]).toContain("serpent")
  end)

  it("the sync check still sends when nothing moved", function()
    fresh(SIMPLE())
    dofile(CURINGSET_FILE)
    ataxia_prioSyncCheck()
    answer()
    advance(12)
    pump()
    expect(game.sets.normal.impatience).toBe(4)
  end)

  -- The documented limit: the bail-out in ataxia_sendDefaultPrios leaves the bash set by itself.
  it("while bashing it does not ask, and sendDefaultPrios does what it always did", function()
    fresh(SIMPLE())
    dofile(CURINGSET_FILE)
    bashOn = true
    ataxia_bashProfileOff = function() bashOn = false end
    body(RESET_ALIAS)()
    advance(12)
    pump()
    expect(game.csAsked).toBeNil()
    expect(game.sets.normal.impatience).toBe(4)
  end)
end)

-- ---------------------------------------------------------------------------
-- D2: which set the server is on, at login
-- ---------------------------------------------------------------------------
describe("a login does not know which set the server is on", function()
  it("until the game answers no swap and no restore goes out, and no default answers", function()
    serverLeftOn("serpent", { impatience = 20, paralysis = 11 })
    login("Runewarden")
    expect(ataxiaPrioSets.unknown).toBeTrue()
    expect(ataxia_defaultPrioAff("impatience")).toBeNil()
    local n = #game.commands
    ataxia_setAffPrio("paralysis", 1)
    ataxia_sendPrioSwap("curing priority slickness 25", false)
    ataxia_restorePrio("paralysis")
    expect(#game.commands).toBe(n)
    expect(game.sets.serpent.paralysis).toBe(11)
  end)

  it("the game's answer is adopted, the class set is read and hidden, and swaps open", function()
    serverLeftOn("serpent", { impatience = 20, paralysis = 11 })
    login("Runewarden")
    answer()
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(ataxiaPrioSets.unknown).toBeNil()
    expect(printedAnyList()).toBeFalse()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
    expect(ataxia_getPrio("impatience")).toBe(20)
    expect(switchesSent()).toBe(0)
    ataxia_setAffPrio("paralysis", 1)
    pump()
    expect(game.sets.serpent.paralysis).toBe(1)
    advance(1.1)
    ataxia_restorePrio("paralysis")
    pump()
    expect(game.sets.serpent.paralysis).toBe(11)
    expect(sentEver("curing priority paralysis 3")).toBeFalse()
  end)

  it("a login branch that switches makes the set known, and the reply follows that switch", function()
    serverLeftOn("serpent", { impatience = 20 })
    login("Serpent")
    expect(game.current).toBe("normal")
    expect(ataxiaPrioSets.unknown).toBeNil()
    expect(ataxia_defaultPrioAff("impatience")).toBe(4)
    answer()
    expect(classDetect.state.currentCuringset).toBe("normal")
    expect(game.csAsked).toBe(1)
    expect(switchesSent()).toBe(1)
  end)

  it("the ask is the last thing levilogin does, after the six branches", function()
    local src = read(LOGIN)
    local ask = src:find("if ataxia_prioLoginRead then ataxia_prioLoginRead() end", 1, true)
    local branch = src:find('if gmcp.Char.Status.class == "Serpent" then', 1, true)
    local event = src:find('raiseEvent("logged in")', 1, true)
    expect(ask ~= nil and branch ~= nil and event ~= nil).toBeTrue()
    expect(ask > event).toBeTrue()
    expect(ask > branch).toBeTrue()
    expect(src:find("if ataxia_prioLoginStart then ataxia_prioLoginStart() end", 1, true)
      < src:find("enableV3()", 1, true)).toBeTrue()
  end)

  it("normal: the answer changes nothing and no read is asked for", function()
    fresh(SIMPLE())
    login("Runewarden")
    answer()
    expect(classDetect.state.currentCuringset).toBe("normal")
    expect(ataxiaPrioSets.unknown).toBeNil()
    expect(game.listsAsked).toBe(0)
    expect(ataxia_defaultPrioAff("impatience")).toBe(4)
  end)

  it("the saved cache of another set goes when the answer moves the state", function()
    serverLeftOn("serpent", { impatience = 20 })
    ataxia.curingprio = { impatience = 1, ghost = 3 }
    game.loseList = LOSE_ALL
    login("Runewarden")
    answer()
    expect(ataxia.curingprio.ghost).toBeNil()
  end)

  it("a repeat login on a class set reads it again, though it has a baseline", function()
    fresh(SIMPLE({ serpent = { impatience = 20 } }))
    switchTo("Serpent")
    pump()
    local asked = game.listsAsked
    ataxia.curingprio = {}
    login("Runewarden")
    answer()
    expect(game.listsAsked).toBe(asked + 1)
    expect(ataxia_getPrio("impatience")).toBe(20)
    expect(printedAnyList()).toBeFalse()
  end)

  it("a class switch before the answer stands: the set is known and the answer is ignored", function()
    serverLeftOn("serpent", { impatience = 20 })
    login("Runewarden")
    switchTo("Infernal")
    expect(ataxiaPrioSets.unknown).toBeNil()
    answer()
    expect(classDetect.state.currentCuringset).toBe("infernal")
    expect(game.current).toBe("infernal")
  end)

  it("a switch away and back before the answer: the state matches, the generation does not", function()
    serverLeftOn("serpent", { impatience = 20 })
    login("Runewarden")
    switchTo("Infernal")
    classDetect.resetToNormal()
    answer()
    expect(classDetect.state.currentCuringset).toBe("normal")
    expect(game.current).toBe("normal")
  end)

  it("a state moved with no generation change: the answer is ignored", function()
    fresh(SIMPLE({ infernal = { impatience = 10 } }))
    game.current = "infernal"
    classDetect.state.currentCuringset = "infernal"
    login("Runewarden")
    ataxia_loginCuringsetNormal()
    answer()
    expect(classDetect.state.currentCuringset).toBe("normal")
  end)

  it("the bash profile active: not adopted, and the set stays unknown", function()
    fresh(SIMPLE({ bash = {} }))
    game.current = "bash"
    bashOn = true
    login("Runewarden")
    answer()
    expect(classDetect.state.currentCuringset).toBe("normal")
    expect(ataxiaPrioSets.unknown).toBeTrue()
    expect(game.listsAsked).toBe(0)
  end)

  it("the server on the bash set with the profile off: not taken for a class set", function()
    fresh(SIMPLE({ bash = {} }))
    game.current = "bash"
    ataxia.settings.bashcuring.setname = "bash"
    login("Runewarden")
    answer()
    expect(classDetect.state.currentCuringset).toBe("normal")
    expect(ataxiaPrioSets.unknown).toBeTrue()
    expect(game.listsAsked).toBe(0)
  end)

  it("a lost reply asks once more, and that answer is adopted", function()
    serverLeftOn("serpent", { impatience = 20 })
    game.loseCs = { [1] = true }
    login("Runewarden")
    pump()
    advance(4.1)
    expect(game.csAsked).toBe(2)
    answer()
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(ataxiaPrioSets.unknown).toBeNil()
  end)

  it("lost twice: unknown, one line, no third ask, and a class switch ends it", function()
    serverLeftOn("serpent", { impatience = 20 })
    game.loseCs = LOSE_ALL
    login("Runewarden")
    pump()
    advance(4.1)
    pump()
    advance(4.1)
    pump()
    advance(4.1)
    expect(game.csAsked).toBe(2)
    expect(ataxiaPrioSets.unknown).toBeTrue()
    expect(linesOf("Could not read the active curing set")).toBe(1)
    switchTo("Infernal")
    expect(ataxiaPrioSets.unknown).toBeNil()
    expect(game.current).toBe("infernal")
  end)

  it("a set already known does not ask again and does not complain", function()
    fresh(SIMPLE())
    game.loseCs = LOSE_ALL
    login("Serpent")
    pump()
    advance(4.1)
    advance(4.1)
    expect(game.csAsked).toBe(1)
    expect(linesOf("Could not read")).toBe(0)
  end)

  it("the switch that ends unknown puts nothing back: the set we would leave is a guess", function()
    serverLeftOn("serpent", { paralysis = 11 })
    login("Runewarden")
    ataxiaPrioSets.live.normal = { paralysis = true }
    game.sends = {}
    switchTo("Infernal")
    expect(game.sends[1]).toBe("curingset switch infernal;curing priority list")
    expect(ataxiaPrioSets.live.normal.paralysis).toBeTrue()
    expect(game.sets.serpent.paralysis).toBe(11)
  end)

  it("nothing is taken into a baseline while unknown", function()
    fresh(SIMPLE({ serpent = { impatience = 20 } }))
    switchTo("Serpent")
    pump()
    login("Runewarden")
    deliver(LINE:format("impatience", 7))
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
  end)

  it("a reload during the wait keeps the set unknown", function()
    serverLeftOn("serpent", { paralysis = 11 })
    login("Runewarden")
    dofile(PRIO_FILE)
    expect(ataxiaPrioSets.unknown).toBeTrue()
    expect(ataxia_defaultPrioAff("paralysis")).toBeNil()
  end)

  it("no login sends an extra set switch", function()
    fresh(SIMPLE())
    login("Runewarden")
    answer()
    expect(switchesSent()).toBe(0)
    fresh(SIMPLE())
    login("Psion")
    answer()
    expect(switchesSent()).toBe(1)
  end)
end)

-- ---------------------------------------------------------------------------
-- D3: a link drop
-- ---------------------------------------------------------------------------
describe("a link drop", function()
  local function dropped()
    fresh(SIMPLE({ serpent = { impatience = 20 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
    game.linkDown = true
    ataxia_prioLinkDown()
    game.sends = {}
  end

  it("is heard from the real event, by a named handler", function()
    fresh(SIMPLE())
    expect(game.onDisconnect).toBe("ataxia_prioLinkDown")
    ataxia_prioLinkDown()
    expect(ataxiaPrioSets.offline).toBeTrue()
  end)

  it("the combat timer firing offline moves nothing and sends nothing", function()
    dropped()
    classDetect.resetToNormal()
    expect(#game.sends).toBe(0)
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
  end)

  it("a class line offline, and the two-attacker branch offline, move nothing", function()
    dropped()
    switchTo("Infernal")
    expect(classDetect.state.currentCuringset).toBe("serpent")
    classDetect.state.attackers = { saibel = true }
    classDetect.setAttackerClass("Froedine", "Monk")
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
  end)

  it("ataxia_switchCuringsetSend itself does not reach the restore", function()
    dropped()
    ataxia_switchCuringsetSend("normal", "serpent")
    expect(#game.sends).toBe(0)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    expect(next(ataxiaPrioSets.echoes)).toBeNil()
  end)

  it("a restore offline is not sent and leaves the name alone", function()
    dropped()
    advance(1.1)
    ataxia_restorePrio("impatience")
    expect(#game.sends).toBe(0)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    expect(ataxiaPrioSets.restoring.serpent).toBeNil()
  end)

  it("a confirmation that arrives after the event does not clear the name", function()
    fresh(SIMPLE({ serpent = { impatience = 20 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    ataxia_restorePrio("impatience")
    ataxia_prioLinkDown()
    pump()
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
  end)

  it("the flag survives a connection and a reload, and levilogin ends it", function()
    dropped()
    ataxia_prioSetsReset()
    expect(ataxiaPrioSets.offline).toBeTrue()
    dofile(PRIO_FILE)
    expect(ataxiaPrioSets.offline).toBeTrue()
    game.linkDown = false
    login("Runewarden")
    expect(ataxiaPrioSets.offline).toBeNil()
  end)

  it("end to end: the name survives, a six-class login, and the next visit puts it back", function()
    dropped()
    classDetect.resetToNormal()
    ataxia_prioSetsReset()
    game.linkDown = false
    login("Serpent")
    answer()
    expect(game.current).toBe("normal")
    switchTo("Serpent")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
    expect(ataxia_getPrio("impatience")).toBe(1)
    classDetect.resetToNormal()
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
  end)

  it("end to end, a class with no login switch: the state still names the server's set", function()
    dropped()
    classDetect.resetToNormal()
    ataxia_prioSetsReset()
    game.linkDown = false
    login("Runewarden")
    answer()
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(ataxia_defaultPrioAff("impatience")).toBe(20)
    expect(sentEver("curing priority impatience 4")).toBeFalse()
  end)
end)

-- ---------------------------------------------------------------------------
-- D4: a restore counts when the game confirms it
-- ---------------------------------------------------------------------------
describe("a restore counts when the game confirms it", function()
  local function up()
    fresh(SIMPLE({ serpent = { impatience = 20 }, infernal = { impatience = 10 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
  end

  local function refuseRestores()
    game.refuse = function(cmd) return cmd:match("^curing priority impatience 20") ~= nil end
  end

  it("a sent restore keeps the name live until its line, and the line ends it", function()
    up()
    ataxia_restorePrio("impatience")
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    expect(ataxiaPrioSets.restoring.serpent.impatience).toBe(20)
    pump()
    expect(ataxiaPrioSets.live.serpent.impatience).toBeNil()
    expect(ataxiaPrioSets.restoring.serpent.impatience).toBeNil()
  end)

  it("a queued restore has the same token, and its line ends it after the drain", function()
    up()
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 4, clock
    ataxia_restorePrio("impatience")
    expect(#t.commands).toBe(1)
    expect(ataxiaPrioSets.restoring.serpent.impatience).toBe(20)
    advance(1.2)
    pump()
    expect(ataxiaPrioSets.live.serpent.impatience).toBeNil()
  end)

  it("after that the user's own value is kept, and a switch does not overwrite it", function()
    up()
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 4, clock
    ataxia_restorePrio("impatience")
    advance(1.2)
    pump()
    send("curing priority impatience 12")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(12)
    game.sends = {}
    switchTo("Infernal")
    expect(game.sends[1]).toBe("curingset switch infernal;curing priority list")
    expect(game.sets.serpent.impatience).toBe(12)
  end)

  it("a restore on its way survives a reload: its line still ends the name", function()
    up()
    ataxia_restorePrio("impatience")
    dofile(PRIO_FILE)
    pump()
    expect(ataxiaPrioSets.live.serpent.impatience).toBeNil()
  end)

  it("a line with another number does not end it", function()
    up()
    ataxia_restorePrio("impatience")
    deliver(LINE:format("impatience", 7))
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    expect(ataxiaPrioSets.restoring.serpent.impatience).toBe(20)
  end)

  it("a line with no token does not end a live name", function()
    up()
    deliver(LINE:format("impatience", 20))
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
  end)

  it("the game's stacked name reaches the same token", function()
    fresh(SIMPLE({ serpent = { burning5 = 2, burning = 9 } }))
    switchTo("Serpent")
    pump()
    ataxia_sendPrioSwap("curing priority burning5 1", false)
    game.queue = {}
    advance(1.1)
    ataxia.curingprio.burning5 = 1
    ataxia_restorePrio("burning5")
    game.queue = {}
    deliver(LINE:format("burning(5)", 2))
    expect(ataxiaPrioSets.live.serpent.burning5).toBeNil()
  end)

  it("a refused restore stays live, and the next switch puts it back", function()
    up()
    refuseRestores()
    ataxia_restorePrio("impatience")
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    game.refuse = nil
    switchTo("Infernal")
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
  end)

  -- The race the SM7 verifier found: the older restore's line must not end the newer swap.
  it("a new swap while the older restore's confirmation is in flight stays live", function()
    up()
    ataxia_restorePrio("impatience")
    advance(1.1)
    ataxia_setAffPrio("impatience", 1)
    expect(ataxiaPrioSets.restoring.serpent.impatience).toBeNil()
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
    game.sends = {}
    switchTo("Infernal")
    expect(game.sends[1]).toBe("curing priority impatience 20;curingset switch infernal;curing priority list")
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
  end)

  it("a swap queued behind a queued restore: the same", function()
    up()
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 4, clock
    ataxia_restorePrio("impatience")
    ataxia_sendPrioSwap("curing priority impatience 1", false)
    expect(#t.commands).toBe(2)
    advance(1.2)
    advance(1.2)
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
  end)

  it("a confirmed batch leaves nothing behind", function()
    up()
    switchTo("Infernal")
    expect(ataxiaPrioSets.live.serpent).toBeNil()
    pump()
    expect(ataxiaPrioSets.live.serpent).toBeNil()
    expect(next(ataxiaPrioSets.echoes)).toBeNil()
  end)

  it("a refused batch goes back to live at the new read's header", function()
    up()
    refuseRestores()
    switchTo("Infernal")
    expect(ataxiaPrioSets.live.serpent).toBeNil()
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
  end)

  it("the next visit keeps the set's own value, and the next switch puts it back", function()
    up()
    refuseRestores()
    switchTo("Infernal")
    pump()
    game.refuse = nil
    advance(1)
    switchTo("Serpent")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
    expect(ataxia_getPrio("impatience")).toBe(1)
    classDetect.resetToNormal()
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
  end)

  it("a read that gave way has no header: the timeout does it", function()
    fresh(SIMPLE({ serpent = { impatience = 20 }, infernal = { impatience = 10 } }))
    switchTo("Infernal")
    pump()
    advance(1)
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    refuseRestores()
    local t = ataxia.prioThrottle
    t.sentThisSecond, t.windowStart = 5, clock
    classDetect.state.lastSwitchTime = 0
    classDetect.switchCuringset("Infernal")
    expect(#ataxiaPrioSets.pending).toBe(0)
    pump()
    expect(ataxiaPrioSets.live.serpent).toBeNil()
    advance(3.1)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
  end)

  it("a lost read has no header either", function()
    up()
    refuseRestores()
    game.loseList = { [game.listsAsked + 1] = true }
    switchTo("Infernal")
    pump()
    expect(ataxiaPrioSets.live.serpent).toBeNil()
    advance(3.1)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
  end)

  it("a batch not yet over is not settled by an earlier read's header", function()
    fresh(SIMPLE({ serpent = { impatience = 20 }, infernal = { impatience = 10 } }))
    ataxiaPrioSets.live.infernal = { impatience = true }
    ataxiaPrioSets.baseline.infernal = { impatience = 10 }
    switchTo("Infernal")
    local firstReply = 1 + #listLines("infernal")
    switchTo("Serpent")
    for _ = 1, firstReply do deliver(table.remove(game.queue, 1)) end
    -- The first read's header has been seen. The batch of the second send is still outstanding.
    expect(ataxiaPrioSets.live.infernal).toBeNil()
    expect(ataxiaPrioSets.echoes.impatience[1].from).toBe("infernal")
    pump()
    expect(next(ataxiaPrioSets.echoes)).toBeNil()
    expect(game.sets.infernal.impatience).toBe(10)
  end)

  it("a quick return with the restore refused does not read the swap as the set's own", function()
    up()
    refuseRestores()
    switchTo("Infernal")
    switchTo("Serpent")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
    expect(ataxia_getPrio("impatience")).toBe(1)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
  end)

  it("a fresh read after a confirmed batch takes what the user set between visits", function()
    up()
    switchTo("Infernal")
    pump()
    game.sets.serpent.impatience = 6
    advance(1)
    switchTo("Serpent")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(6)
  end)
end)

-- ---------------------------------------------------------------------------
-- D5: a confirmation from the set we left
-- ---------------------------------------------------------------------------
describe("a confirmation from the set we left is never adopted", function()
  local function leaveWithSwap()
    fresh(SIMPLE({ serpent = { impatience = 20 }, infernal = { impatience = 10 } }))
    switchTo("Serpent")
    pump()
    advance(1)
    switchTo("Infernal")
    pump()
    advance(1)
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    switchTo("Infernal")
  end

  it("at 3.2 s, after the read has given up", function()
    leaveWithSwap()
    advance(3.2)
    pump()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(10)
    expect(next(ataxiaPrioSets.echoes)).toBeNil()
  end)

  it("at 6.5 s", function()
    leaveWithSwap()
    advance(6.5)
    pump()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(10)
  end)

  it("the late line goes nowhere: the set keeps its value through the next restore", function()
    leaveWithSwap()
    advance(3.2)
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    expect(game.sets.infernal.impatience).toBe(10)
  end)

  it("across a package reload", function()
    leaveWithSwap()
    expect(ataxiaPrioSets.batchSeq).toBe(1)
    dofile(PRIO_FILE)
    expect(ataxiaPrioSets.batchSeq).toBe(1)
    pump()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(10)
  end)

  it("across a connection", function()
    leaveWithSwap()
    ataxia_prioSetsReset()
    pump()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(10)
  end)

  it("leaving normal: the global value does not reach the class set", function()
    fresh(SIMPLE({ infernal = { impatience = 10 } }))
    switchTo("Infernal")
    pump()
    classDetect.resetToNormal()
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    switchTo("Infernal")
    advance(3.2)
    pump()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(10)
  end)

  it("a list end does not empty the table: two quick switches", function()
    fresh(SIMPLE({ serpent = { impatience = 20 }, infernal = { impatience = 10 } }))
    ataxiaPrioSets.baseline.serpent = { impatience = 20 }
    ataxiaPrioSets.baseline.infernal = { impatience = 10 }
    ataxiaPrioSets.live.infernal = { impatience = true }
    switchTo("Infernal")
    local firstReply = 1 + #listLines("infernal")
    switchTo("Serpent")
    for _ = 1, firstReply do deliver(table.remove(game.queue, 1)) end
    advance(3.2)
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
  end)

  it("a single restore on its way at the switch is an echo too", function()
    fresh(SIMPLE({ serpent = { impatience = 20 }, infernal = { impatience = 10 } }))
    switchTo("Infernal")
    pump()
    advance(1)
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    ataxia_restorePrio("impatience")
    switchTo("Infernal")
    expect(ataxiaPrioSets.restoring.serpent).toBeNil()
    advance(3.2)
    pump()
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(10)
    expect(next(ataxiaPrioSets.echoes)).toBeNil()
  end)

  it("a name leaving is matched before a stale entry of the same value", function()
    fresh(SIMPLE({ serpent = { impatience = 20 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    ataxiaPrioSets.echoes.impatience = { { value = 20 } }
    advance(1.1)
    switchTo("Infernal")
    pump()
    expect(ataxiaPrioSets.live.serpent).toBeNil()
    expect(#ataxiaPrioSets.echoes.impatience).toBe(1)
    expect(ataxiaPrioSets.echoes.impatience[1].from).toBeNil()
  end)

  it("a different number for the name is still the user's own", function()
    leaveWithSwap()
    pump()
    deliver(LINE:format("impatience", 13))
    expect(ataxiaPrioSets.baseline.infernal.impatience).toBe(13)
  end)
end)

-- ---------------------------------------------------------------------------
-- D6, D7: the bash profile
-- ---------------------------------------------------------------------------
describe("the bash profile", function()
  it("two attackers: bash off goes where the state says, and the class set is not written", function()
    fresh(SIMPLE({ serpent = { impatience = 20 }, bash = {} }))
    ataxia.settings.bashcuring = { enabled = true, installed = true, active = false, setname = "bash" }
    dofile(BASH_FILE)
    switchTo("Serpent")
    pump()
    ataxia_bashProfileOn()
    expect(game.current).toBe("bash")
    expect(ataxia.settings.bashcuring.restoreTo).toBe("serpent")
    classDetect.state.attackers = { saibel = true }
    classDetect.setAttackerClass("Froedine", "Monk")
    expect(game.current).toBe("normal")
    expect(ataxia.settings.bashcuring.restoreTo).toBe("normal")
    ataxia_bashProfileOff()
    expect(game.current).toBe("normal")
    expect(classDetect.state.currentCuringset).toBe("normal")
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
    expect(game.sets.normal.impatience).toBe(4)
  end)

  it("no second attacker: bash off still returns to the class set", function()
    fresh(SIMPLE({ serpent = { impatience = 20 }, bash = {} }))
    ataxia.settings.bashcuring = { enabled = true, installed = true, active = false, setname = "bash" }
    dofile(BASH_FILE)
    switchTo("Serpent")
    pump()
    ataxia_bashProfileOn()
    ataxia_bashProfileOff()
    expect(game.current).toBe("serpent")
    expect(classDetect.state.currentCuringset).toBe("serpent")
  end)

  local function install()
    fresh(SIMPLE({ serpent = { clumsiness = 20, paralysis = 6 }, bash = {} }))
    ataxia.settings.bashcuring = { enabled = true, installed = false, active = false, setname = "bash" }
    dofile(BASH_FILE)
    dofile(CURINGSET_FILE)
    switchTo("Serpent")
    pump()
    ataxia_bashProfileInstall()
    answer()
    for _ = 1, 14 do
      advance(1)
      pump()
    end
  end

  it("an install from a class set: its confirmation lines are not that set's values", function()
    install()
    expect(game.current).toBe("serpent")
    expect(game.sets.bash.clumsiness).toBe(6)
    expect(ataxiaPrioSets.baseline.serpent.clumsiness).toBe(20)
    expect(ataxiaPrioSets.baseline.serpent.paralysis).toBe(6)
  end)

  it("the window ends, and a value the user sets later is adopted", function()
    install()
    advance(5)
    send("curing priority paralysis 9")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.paralysis).toBe(9)
  end)
end)

-- ---------------------------------------------------------------------------
-- D9: a restart with a swap up
-- ---------------------------------------------------------------------------
describe("a Mudlet restart with a swap up", function()
  local FILE = "/tmp/mudlet-test/ataxia_curingset_swaps.lua"

  local function swapped()
    fresh(SIMPLE({ serpent = { impatience = 20, paralysis = 11 }, infernal = { impatience = 10 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
    advance(1)
  end

  it("the file holds the name and its own value, a second later and not before", function()
    fresh(SIMPLE({ serpent = { impatience = 20 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    expect(disk.writes).toBe(0)
    advance(1)
    expect(disk.writes).toBe(1)
    expect(disk.files[FILE].live.serpent.impatience).toBe(20)
    expect(ataxia.prioThrottle.file).toBeNil()
  end)

  it("many changes inside a second are one write", function()
    fresh(SIMPLE({ serpent = { impatience = 20, paralysis = 11, slickness = 5 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    advance(0.2)
    ataxia_setAffPrio("paralysis", 1)
    advance(0.2)
    ataxia_sendPrioSwap("curing priority slickness 25", false)
    pump()
    advance(0.7)
    expect(disk.writes).toBe(1)
    expect(disk.files[FILE].live.serpent.slickness).toBe(5)
  end)

  it("a change just after a write waits its own second", function()
    fresh(SIMPLE({ serpent = { impatience = 20, paralysis = 11, slickness = 5 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    advance(0.5)
    ataxia_setAffPrio("paralysis", 1)
    advance(0.6)
    expect(disk.writes).toBe(1)
    ataxia_sendPrioSwap("curing priority slickness 25", false)
    advance(0.5)
    expect(disk.writes).toBe(1)
    advance(0.6)
    expect(disk.writes).toBe(2)
    expect(disk.files[FILE].live.serpent.slickness).toBe(5)
  end)

  it("an unchanged content is not written again", function()
    swapped()
    local n = disk.writes
    advance(1.1)
    ataxia_sendPrioSwap("curing priority impatience 1", false)
    pump()
    advance(1.1)
    expect(disk.writes).toBe(n)
  end)

  it("a name on its way back at a switch stays in the file until its line comes", function()
    fresh(SIMPLE({ serpent = { impatience = 20, paralysis = 11 }, infernal = { impatience = 10 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    ataxia_setAffPrio("paralysis", 1)
    pump()
    advance(1.1)
    switchTo("Infernal")
    -- One of the two confirmations has come, the other is still on its way.
    ataxia_prioTuned("impatience", 20)
    advance(1.1)
    local held = disk.files[FILE].live.serpent
    expect(held.paralysis).toBe(11)
    expect(held.impatience).toBeNil()
  end)

  it("with no live names the file holds nothing", function()
    swapped()
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    advance(1.1)
    expect(next(disk.files[FILE].live)).toBeNil()
  end)

  it("a name on its way back counts until the game confirms it", function()
    swapped()
    local n = disk.writes
    switchTo("Infernal")
    advance(1)
    expect(disk.writes).toBe(n)
    expect(disk.files[FILE].live.serpent.impatience).toBe(20)
    pump()
    advance(1)
    expect(next(disk.files[FILE].live)).toBeNil()
  end)

  it("a save that throws is harmless", function()
    swapped()
    table.save = function() error("disk full") end
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    advance(1.1)
    expect(ataxiaPrioSets.live.serpent.impatience).toBeNil()
    expect(#echoes).toBe(0)
  end)

  local function afterRestart()
    swapped()
    restart()
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    expect(ataxiaPrioSets.baseline.serpent).toBeNil()
  end

  it("a six-class login: the next read keeps the own value and a restore puts the swap back", function()
    afterRestart()
    login("Serpent")
    answer()
    expect(game.current).toBe("normal")
    switchTo("Serpent")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
    expect(ataxia_getPrio("impatience")).toBe(1)
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
  end)

  it("or the next switch puts it back", function()
    afterRestart()
    login("Serpent")
    answer()
    switchTo("Serpent")
    pump()
    classDetect.resetToNormal()
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
  end)

  it("a class with no login switch: adopted, read, and the swap goes back", function()
    afterRestart()
    login("Runewarden")
    answer()
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
    expect(ataxia_getPrio("impatience")).toBe(1)
    classDetect.resetToNormal()
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
  end)

  it("before any read of that set a switch still puts the swap back from the file's value", function()
    afterRestart()
    login("Runewarden")
    game.loseList = LOSE_ALL
    answer()
    expect(ataxiaPrioSets.baseline.serpent).toBeNil()
    game.sends = {}
    classDetect.resetToNormal()
    expect(game.sends[1]).toBe("curing priority impatience 20;curingset switch normal;curing priority list")
    pump()
    expect(game.sets.serpent.impatience).toBe(20)
  end)

  it("the file's values are no baseline: other names stay shut and the first read still goes out", function()
    afterRestart()
    login("Runewarden")
    game.loseList = { [game.listsAsked + 1] = true }
    answer()
    expect(ataxiaPrioSets.baseline.serpent).toBeNil()
    expect(ataxia_defaultPrioAff("impatience")).toBe(20)
    expect(ataxia_defaultPrioAff("paralysis")).toBeNil()
    local n = #game.commands
    ataxia_setAffPrio("paralysis", 1)
    expect(#game.commands).toBe(n)
    advance(3.1)
    pump()
    expect(ataxiaPrioSets.baseline.serpent.paralysis).toBe(11)
  end)

  it("the file's values are dropped at the first read", function()
    afterRestart()
    login("Runewarden")
    answer()
    expect(ataxiaPrioSets.seeded.serpent).toBeNil()
  end)

  it("only a state with no ataxiaPrioSets reads it", function()
    swapped()
    disk.files[FILE] = { live = { priest = { asthma = 5 } } }
    dofile(PRIO_FILE)
    expect(ataxiaPrioSets.live.priest).toBeNil()
    ataxia_prioSetsReset()
    expect(ataxiaPrioSets.live.priest).toBeNil()
  end)

  it("a missing file is nothing, and writes nothing", function()
    fresh(SIMPLE())
    expect(disk.writes).toBe(0)
    expect(next(ataxiaPrioSets.live)).toBeNil()
    expect(next(ataxiaPrioSets.seeded)).toBeNil()
    advance(2)
    expect(disk.writes).toBe(0)
  end)

  it("a damaged file is harmless and quiet, whatever it holds", function()
    for _, bad in ipairs({ "not a table", { live = "nope" }, { other = 1 },
      { live = { serpent = "x", [3] = { a = 1 } } }, { live = { serpent = { impatience = "high", [1] = 2 } } } }) do
      fresh(SIMPLE())
      disk.files[FILE] = bad
      restart()
      expect(next(ataxiaPrioSets.live)).toBeNil()
      expect(#echoes).toBe(0)
    end
    fresh(SIMPLE())
    disk.files[FILE] = {}
    table.load = function() error("bad pickle") end
    expect(pcall(restart)).toBeTrue()
    expect(next(ataxiaPrioSets.live)).toBeNil()
    expect(#echoes).toBe(0)
  end)

  it("a damaged row among good ones does not cost the good ones", function()
    fresh(SIMPLE({ serpent = { impatience = 20 } }))
    disk.files[FILE] = { live = { serpent = { impatience = 20, bad = "x" }, [7] = { a = 1 } } }
    restart()
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    expect(ataxiaPrioSets.live.serpent.bad).toBeNil()
  end)

  it("a restart with the file unchanged does not write it", function()
    swapped()
    local n = disk.writes
    restart()
    login("Runewarden")
    answer()
    ataxia_sendPrioSwap("curing priority impatience 1", false)
    pump()
    advance(2)
    expect(disk.writes).toBe(n)
  end)

  it("a reload does not forget what the file holds", function()
    swapped()
    local n = disk.writes
    dofile(PRIO_FILE)
    advance(1.1)
    ataxia_sendPrioSwap("curing priority impatience 1", false)
    pump()
    advance(1.1)
    expect(disk.writes).toBe(n)
  end)

  it("a connection before the first read keeps the file's values", function()
    afterRestart()
    ataxia_prioSetsReset()
    login("Serpent")
    answer()
    switchTo("Serpent")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(20)
  end)
end)

-- ---------------------------------------------------------------------------
-- Round 3: lines still in flight when something newer happens
-- ---------------------------------------------------------------------------
local function printedLine(pattern)
  for _, l in ipairs(printed) do
    if l:match(pattern) then return true end
  end
  return false
end

describe("a swap's own line from the set we left", function()
  local function repeatVisit(sets)
    fresh(sets)
    switchTo("Infernal")
    pump()
    switchTo("Serpent")
    pump()
    switchTo("Infernal")
    pump()
    advance(1.1)
  end

  -- Two steps: a timer runs at the END of an advance, so one long step would start the quiet window
  -- late and cover the line, and the echo would not be what is tested.
  local function waitPast(lag)
    advance(3.1)
    advance(lag - 3.1)
  end

  local function swapInFlight(lag)
    repeatVisit(SIMPLE({ serpent = { frozen = 15 }, infernal = { frozen = 20 } }))
    ataxia_setAffPrio("frozen", 4)
    switchTo("Serpent")
    waitPast(lag)
    pump()
  end

  for _, lag in ipairs({ 6.5, 30 }) do
    it("arriving " .. lag .. " s late is not adopted, and a restore writes nothing wrong", function()
      swapInFlight(lag)
      expect(ataxiaPrioSets.baseline.serpent.frozen).toBe(15)
      prioWaitrestore = {}
      ataxia_restorePrio("frozen")
      pump()
      expect(game.sets.serpent.frozen).toBe(15)
    end)
  end

  it("leaving normal: the swap value does not reach the class set", function()
    fresh(SIMPLE({ normal = { paralysis = 3 }, serpent = { paralysis = 9 } }))
    switchTo("Serpent")
    pump()
    classDetect.resetToNormal()
    pump()
    advance(1.1)
    ataxia_setAffPrio("paralysis", 25)
    switchTo("Serpent")
    waitPast(6.5)
    pump()
    expect(ataxiaPrioSets.baseline.serpent.paralysis).toBe(9)
    expect(game.sets.serpent.paralysis).toBe(9)
  end)

  it("the read gave way: not adopted either", function()
    repeatVisit(SIMPLE({ serpent = { frozen = 15 }, infernal = { frozen = 20 } }))
    ataxia_setAffPrio("frozen", 4)
    advance(DEBOUNCE)
    ataxia.prioThrottle.windowStart, ataxia.prioThrottle.sentThisSecond = clock, 4
    classDetect.switchCuringset("Serpent")
    expect(game.sends[#game.sends]:find("curing priority list", 1, true)).toBeNil()
    waitPast(6.5)
    pump()
    expect(ataxiaPrioSets.baseline.serpent.frozen).toBe(15)
  end)

  it("across a reload inside the reply lag", function()
    repeatVisit(SIMPLE({ serpent = { frozen = 15 }, infernal = { frozen = 20 } }))
    ataxia_setAffPrio("frozen", 4)
    switchTo("Serpent")
    dofile(PRIO_FILE)
    waitPast(6.5)
    pump()
    expect(ataxiaPrioSets.baseline.serpent.frozen).toBe(15)
  end)

  it("two names in one send are both covered", function()
    repeatVisit(SIMPLE({ serpent = { frozen = 15, shivering = 16 }, infernal = { frozen = 20, shivering = 21 } }))
    ataxia_sendPrioSwap("curing priority frozen 4;curing priority shivering 5", false)
    switchTo("Serpent")
    waitPast(6.5)
    pump()
    expect(ataxiaPrioSets.baseline.serpent.frozen).toBe(15)
    expect(ataxiaPrioSets.baseline.serpent.shivering).toBe(16)
  end)

  it("in its own visit the line is taken, and leaves nothing behind", function()
    fresh(SIMPLE({ serpent = { frozen = 15 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("frozen", 4)
    expect(#ataxiaPrioSets.echoes.frozen).toBe(1)
    pump()
    expect(ataxiaPrioSets.echoes.frozen).toBeNil()
    expect(ataxiaPrioSets.live.serpent.frozen).toBeTrue()
    expect(ataxiaPrioSets.baseline.serpent.frozen).toBe(15)
  end)

  it("a restore after it still ends the live mark", function()
    fresh(SIMPLE({ serpent = { frozen = 15 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("frozen", 4)
    pump()
    advance(1.1)
    ataxia_restorePrio("frozen")
    pump()
    expect(ataxiaPrioSets.live.serpent.frozen).toBeNil()
    expect(game.sets.serpent.frozen).toBe(15)
  end)
end)

describe("a line with no echo, past the read's clock", function()
  local function overdue()
    fresh(SIMPLE({ serpent = { frozen = 15 }, infernal = { frozen = 20 } }))
    switchTo("Infernal")
    pump()
    switchTo("Serpent")
    pump()
    switchTo("Infernal")
  end

  it("is not adopted while the replies are overdue, and is adopted after", function()
    overdue()
    game.queue = {}
    advance(3.1)
    deliver(LINE:format("frozen", 7))
    expect(ataxiaPrioSets.baseline.infernal.frozen).toBe(20)
    advance(3.1)
    deliver(LINE:format("frozen", 7))
    expect(ataxiaPrioSets.baseline.infernal.frozen).toBe(7)
  end)

  it("a read that came back opens no window", function()
    overdue()
    pump()
    advance(3.1)
    expect(ataxiaPrioSets.quietUntil).toBeNil()
    deliver(LINE:format("frozen", 7))
    expect(ataxiaPrioSets.baseline.infernal.frozen).toBe(7)
  end)

  it("a reload with a read due holds the window", function()
    overdue()
    game.queue = {}
    dofile(PRIO_FILE)
    deliver(LINE:format("frozen", 7))
    expect(ataxiaPrioSets.baseline.infernal.frozen).toBe(20)
  end)

  it("a reload carries a window already open, and a longer one is not shortened", function()
    overdue()
    pump()
    ataxiaPrioSets.quietUntil = clock + 20
    dofile(PRIO_FILE)
    expect(ataxiaPrioSets.quietUntil).toBe(clock + 20)
    switchTo("Serpent")
    game.queue = {}
    advance(3.1)
    expect(ataxiaPrioSets.quietUntil > clock + 10).toBeTrue()
  end)
end)

describe("an older restore's line does not eat newer state", function()
  local function swapped()
    fresh(SIMPLE({ serpent = { impatience = 17 }, infernal = { impatience = 10 } }))
    switchTo("Serpent")
    pump()
    ataxia_setAffPrio("impatience", 1)
    pump()
    advance(1.1)
  end

  it("a refused batch: the old line leaves the name leaving, so it goes back to live", function()
    swapped()
    ataxia_restorePrio("impatience")
    ataxia_setAffPrio("impatience", 2)
    expect(ataxiaPrioSets.restoring.serpent.impatience).toBeNil()
    expect(game.sets.serpent.impatience).toBe(2)
    game.refuse = function(cmd) return cmd:find("impatience 17", 1, true) ~= nil end
    switchTo("Infernal")
    pump()
    game.refuse = nil
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    switchTo("Serpent")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(17)
    classDetect.resetToNormal()
    pump()
    expect(game.sets.serpent.impatience).toBe(17)
  end)

  it("a queued newer restore: the old line does not take its token, and the switch restores", function()
    swapped()
    ataxia_restorePrio("impatience")
    ataxia_setAffPrio("impatience", 2)
    advance(1.1)
    ataxia.prioThrottle.windowStart, ataxia.prioThrottle.sentThisSecond = clock, 4
    ataxia_restorePrio("impatience")
    expect(#ataxia.prioThrottle.commands).toBe(1)
    expect(ataxiaPrioSets.restoring.serpent.impatience).toBe(17)
    pump()
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    expect(ataxiaPrioSets.restoring.serpent.impatience).toBe(17)
    switchTo("Infernal")
    pump()
    expect(game.sets.serpent.impatience).toBe(17)
  end)

  it("a line is matched to a cancelled entry, then a leaving one, then the oldest plain one", function()
    fresh(SIMPLE({ serpent = { impatience = 17 } }))
    local e = { { value = 17, mark = "old" }, { value = 17, mark = "new" },
      { value = 17, from = "serpent", seq = 1 }, { value = 17, cancelled = true } }
    ataxiaPrioSets.echoes.impatience = e
    ataxia_prioTuned("impatience", 17)
    expect(#e).toBe(3)
    for _, x in ipairs(e) do expect(x.cancelled).toBeNil() end
    ataxia_prioTuned("impatience", 17)
    expect(#e).toBe(2)
    for _, x in ipairs(e) do expect(x.from).toBeNil() end
    ataxia_prioTuned("impatience", 17)
    expect(#e).toBe(1)
    expect(e[1].mark).toBe("new")
  end)

  it("no line of a cancelled restore: only one extra restore follows", function()
    swapped()
    ataxia_restorePrio("impatience")
    game.queue = {}
    ataxia_setAffPrio("impatience", 2)
    pump()
    advance(1.1)
    ataxia_restorePrio("impatience")
    pump()
    expect(ataxiaPrioSets.live.serpent.impatience).toBeTrue()
    advance(1.1)
    ataxia_restorePrio("impatience")
    expect(ataxia_getPrio("impatience")).toBe(17)
    switchTo("Infernal")
    pump()
    expect(game.sets.serpent.impatience).toBe(17)
  end)
end)

describe("a read answered after a swap", function()
  it("a lost read, a swap, then a typed list: the swap value is not taken for the set's own", function()
    fresh(SIMPLE({ serpent = { impatience = 17 }, infernal = { impatience = 10 } }))
    switchTo("Serpent")
    pump()
    switchTo("Infernal")
    pump()
    game.loseList = { [game.listsAsked + 1] = true }
    switchTo("Serpent")
    pump()
    expect(#ataxiaPrioSets.pending).toBe(1)
    ataxia_setAffPrio("impatience", 1)
    send("curing priority list")
    pump()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(17)
    expect(ataxia_getPrio("impatience")).toBe(1)
  end)
end)

describe("the echoes of one name are bounded", function()
  it("eight at most, the oldest plain ones go first", function()
    fresh(SIMPLE({ serpent = { impatience = 17 } }))
    switchTo("Serpent")
    pump()
    for i = 1, 40 do
      advance(1.1)
      ataxia_setAffPrio("impatience", i)
      game.queue = {}
    end
    local list = ataxiaPrioSets.echoes.impatience
    expect(#list).toBe(8)
    expect(list[1].value).toBe(33)
    expect(list[8].value).toBe(40)
  end)

  it("a name leaving is never the one that goes", function()
    fresh(SIMPLE({ serpent = { impatience = 17 } }))
    switchTo("Serpent")
    pump()
    local list = {}
    for i = 1, 8 do list[i] = { value = 100 + i, from = "serpent", seq = 1 } end
    ataxiaPrioSets.echoes.impatience = list
    ataxia_setAffPrio("impatience", 1)
    expect(#list).toBe(8)
    for _, x in ipairs(list) do expect(x.from).toBe("serpent") end
  end)

  it("a cancelled restore goes through the same cap", function()
    fresh(SIMPLE({ serpent = { impatience = 17 } }))
    switchTo("Serpent")
    pump()
    for _ = 1, 20 do
      ataxia_setAffPrio("impatience", 1)
      pump()
      game.queue = {}
      advance(1.1)
      ataxia.curingprio.impatience = 1
      ataxia_restorePrio("impatience")
      game.queue = {}
      advance(1.1)
    end
    expect(#ataxiaPrioSets.echoes.impatience <= 8).toBeTrue()
  end)
end)

describe("a login while the bash profile holds the set", function()
  local function hunting(restoreTo, current)
    fresh(SIMPLE({ serpent = { impatience = 17 }, bash = {} }))
    game.current = current
    ataxia.settings.bashcuring = { enabled = true, installed = true, active = true,
      setname = "bash", restoreTo = restoreTo }
    dofile(BASH_FILE)
  end

  it("a six-class login moves the way back to normal", function()
    fresh(SIMPLE({ serpent = { impatience = 17 }, bash = {} }))
    ataxia.settings.bashcuring = { enabled = true, installed = true, active = false, setname = "bash" }
    dofile(BASH_FILE)
    switchTo("Serpent")
    pump()
    ataxia_bashProfileOn()
    expect(ataxia.settings.bashcuring.restoreTo).toBe("serpent")
    login("Serpent")
    answer()
    expect(game.current).toBe("normal")
    expect(ataxia.settings.bashcuring.restoreTo).toBe("normal")
    ataxia_bashProfileOff()
    expect(game.current).toBe("normal")
    expect(classDetect.state.currentCuringset).toBe("normal")
    ataxia_setAffPrio("impatience", 1)
    pump()
    expect(game.sets.normal.impatience).toBe(1)
    expect(game.sets.serpent.impatience).toBe(17)
    switchTo("Serpent")
    pump()
    expect(game.sets.serpent.impatience).toBe(17)
    expect(game.sets.normal.impatience).toBe(4)
  end)

  it("the way back is left alone when the profile is off", function()
    fresh(SIMPLE({ bash = {} }))
    ataxia.settings.bashcuring = { active = false, setname = "bash", restoreTo = "serpent" }
    ataxia_loginCuringsetNormal()
    expect(ataxia.settings.bashcuring.restoreTo).toBe("serpent")
  end)

  it("bash off to normal: swaps and restores come back, with no extra switch", function()
    hunting("normal", "bash")
    login("Runewarden")
    answer()
    expect(ataxiaPrioSets.unknown).toBeTrue()
    expect(switchesSent()).toBe(0)
    ataxia_bashProfileOff()
    expect(game.current).toBe("normal")
    expect(ataxiaPrioSets.unknown).toBeNil()
    expect(switchesSent()).toBe(1)
    expect(game.listsAsked).toBe(0)
    expect(ataxia_defaultPrioAff("impatience")).toBe(4)
    ataxia_setAffPrio("impatience", 1)
    pump()
    expect(game.sets.normal.impatience).toBe(1)
  end)

  it("bash off to a class set: the state follows, the read is hidden, the swap lands there", function()
    hunting("serpent", "bash")
    login("Runewarden")
    answer()
    ataxia.curingprio = { ghost = 3 }
    ataxia_bashProfileOff()
    expect(game.current).toBe("serpent")
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(ataxiaPrioSets.unknown).toBeNil()
    expect(ataxia.curingprio.ghost).toBeNil()
    pump()
    expect(game.listsAsked).toBe(1)
    expect(printedAnyList()).toBeFalse()
    expect(ataxiaPrioSets.baseline.serpent.impatience).toBe(17)
    expect(switchesSent()).toBe(1)
    ataxia_setAffPrio("impatience", 1)
    pump()
    expect(game.sets.serpent.impatience).toBe(1)
  end)

  it("with no link the send was lost: the set stays unknown", function()
    hunting("normal", "bash")
    login("Runewarden")
    answer()
    ataxia_prioLinkDown()
    game.linkDown = true
    ataxia_bashProfileOff()
    expect(ataxiaPrioSets.unknown).toBeTrue()
  end)

  it("a set already known is left alone", function()
    fresh(SIMPLE({ serpent = { impatience = 17 }, bash = {} }))
    ataxia.settings.bashcuring = { enabled = true, installed = true, active = false, setname = "bash" }
    dofile(BASH_FILE)
    switchTo("Serpent")
    pump()
    local asked = game.listsAsked
    ataxia_bashProfileOn()
    ataxia_bashProfileOff()
    expect(game.listsAsked).toBe(asked)
    expect(classDetect.state.currentCuringset).toBe("serpent")
  end)

  it("the server on the bash set with the profile off: swaps stay off and one line says so", function()
    fresh(SIMPLE({ bash = {} }))
    game.current = "bash"
    ataxia.settings.bashcuring.setname = "bash"
    login("Runewarden")
    answer()
    expect(ataxiaPrioSets.unknown).toBeTrue()
    expect(linesOf("The server is on the bash curing set")).toBe(1)
    local n = #game.commands
    ataxia_setAffPrio("impatience", 1)
    expect(#game.commands).toBe(n)
  end)

  it("the set already known by then: the bash-set answer prints no such line", function()
    fresh(SIMPLE({ bash = {} }))
    game.current = "bash"
    ataxia.settings.bashcuring.setname = "bash"
    login("Runewarden")
    ataxia_prioSetKnown()
    answer()
    expect(linesOf("The server is on the bash curing set")).toBe(0)
  end)
end)

describe("the login's own CURINGSET LIST", function()
  local function listShown()
    return printedLine("^Your current curing sets") or printedLine("^You are using a total")
      or printedLine("^%-+$") or printedLine("^normal") or printedLine("^serpent")
  end

  it("prints nothing at an ordinary login, and is still read", function()
    serverLeftOn("serpent", { impatience = 20 })
    login("Runewarden")
    answer()
    expect(listShown()).toBeFalse()
    expect(classDetect.state.currentCuringset).toBe("serpent")
    expect(ataxiaPrioSets.unknown).toBeNil()
  end)

  it("a six-class login too", function()
    fresh(SIMPLE())
    login("Serpent")
    answer()
    expect(listShown()).toBeFalse()
  end)

  it("the retry after a lost reply is quiet too", function()
    serverLeftOn("serpent", { impatience = 20 })
    game.loseCs = { [1] = true }
    login("Runewarden")
    pump()
    advance(4.1)
    answer()
    expect(game.csAsked).toBe(2)
    expect(listShown()).toBeFalse()
    expect(classDetect.state.currentCuringset).toBe("serpent")
  end)

  it("a game line inside the window still prints, and one before the header too", function()
    fresh(SIMPLE())
    login("Runewarden")
    table.insert(game.queue, 1, "A rat scurries in.")
    table.insert(game.queue, 3, "H:100 M:100 <eb>")
    answer()
    expect(printedLine("^A rat scurries in%.$")).toBeTrue()
    expect(printedLine("^H:100")).toBeTrue()
    expect(listShown()).toBeFalse()
  end)

  it("a list the code asks for without quiet prints", function()
    fresh(SIMPLE())
    dofile(CURINGSET_FILE)
    ataxia_curingsetRefresh(function() end)
    answer()
    expect(printedLine("^Your current curing sets")).toBeTrue()
    expect(printedLine("^You are using a total")).toBeTrue()
  end)

  it("anyone who joins the login's capture without quiet gets it printed", function()
    fresh(SIMPLE())
    login("Runewarden")
    ataxia_curingsetRefresh(function() end)
    answer()
    expect(printedLine("^Your current curing sets")).toBeTrue()
  end)

  it("the quiet ends at the total line: a later list prints", function()
    fresh(SIMPLE())
    login("Runewarden")
    game.queue[#game.queue + 1] = "Hmmm"
    answer()
    expect(printedLine("^Hmmm$")).toBeTrue()
    ataxia_curingsetRefresh(function() end)
    answer()
    expect(printedLine("^Your current curing sets")).toBeTrue()
  end)

  it("the flag is in no saved table", function()
    fresh(SIMPLE())
    login("Runewarden")
    local n = 0
    for k in pairs(ataxia) do
      if type(k) == "string" and k:match("^_cs") and k:lower():find("quiet", 1, true) then n = n + 1 end
    end
    expect(n).toBe(0)
  end)
end)

-- ---------------------------------------------------------------------------
-- The patterns
-- ---------------------------------------------------------------------------
describe("the triggers read the game's real lines", function()
  it("716 takes the captured header", function()
    local header = "Your affliction curing priorities for the priority set normal:"
    expect(read(CAPTURE_FILE):find(header, 1, true) ~= nil).toBeTrue()
    expect(TL.anyMatches(TL.patterns(T716), header)).toBeTrue()
  end)

  it("717 takes a captured row, and 718 the last line", function()
    expect(TL.anyMatches(TL.patterns(T717), "1:  brokenrightarm, brokenleftarm, latched, icebound")).toBeTrue()
    expect(TL.anyMatches(TL.patterns(T718), "Affs with priority 26 are ignored.")).toBeTrue()
  end)

  it("ataxia_prioRowNames joins the game's stacked form", function()
    fresh(SIMPLE())
    local names = ataxia_prioRowNames("burning(5), aeon, Pyre(3)")
    expect(table.concat(names, " ")).toBe("burning5 aeon pyre3")
  end)
end)

-- Leave shared state clean: test files run in one interpreter.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
table.save, table.load, io.exists = tableSave, tableLoad, ioExists
mock.reset()
