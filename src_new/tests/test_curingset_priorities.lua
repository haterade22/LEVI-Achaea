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
local game, printed, deleted, clock, timers, temps, chain, saves, nextId, bashOn

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
      if not t.dead then
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
  if to then
    game.current = to
    queueLine("You will now cure using the " .. to .. " set.")
  elseif cmd == "curing priority list" then
    game.listsAsked = game.listsAsked + 1
    if game.loseList and game.loseList[game.listsAsked] then return end
    for _, l in ipairs(listLines(game.current)) do queueLine(l) end
  elseif cmd:match("^curing priority defence ") or cmd:match("^curing priority health")
      or cmd:match("^curing priority mana") then
    return
  else
    local rest = cmd:match("^curing priority (.+)$")
    if rest then
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
  clock, chain, saves, nextId, bashOn, deleted = 1000, 0, 0, 0, false, false

  send = function(cmd)
    game.sends[#game.sends + 1] = cmd
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
  tempRegexTrigger = function(pat, fn)
    assert(pat == "^(.*)$", "the only temp pattern here is the read's line trigger")
    nextId = nextId + 1
    temps[#temps + 1] = { id = nextId, fn = fn }
    return nextId
  end
  killTrigger = function(id)
    for _, t in ipairs(temps) do if t.id == id then t.dead = true end end
  end
  registerAnonymousEventHandler = function(event, fn)
    if event == "sysConnectionEvent" then game.onConnect = fn end
    return 1
  end
  killAnonymousEventHandler = function() end
  cecho, echo = function() end, function() end
  table.save, table.load = function() end, function() end
  io.exists = function() return false end

  ataxia = { settings = { bashcuring = { active = false }, defences = { current = "" } },
    afflictions = {}, curingprio = {}, channels = {}, vitals = { bleed = 0 } }
  ataxiaTemp = {}
  ataxiaEcho = function() end
  ataxia_saveSettings = function() saves = saves + 1 end
  ataxia_bashProfileActive = function() return bashOn end
  ataxia_bashProfileOff = function() end
  ataxiaNDB_getClass = function() return game.tc end
  ataxiaNDB_Exists = function() return game.tc ~= nil end
  ataxia_resetSwaps = function() ataxia.prioritySwaps = {} end
  affed = function(a) return ataxia.afflictions[a] end
  target = "Someone"
  prioWaitfor, prioWaitrestore = nil, nil
  classDetect, Algedonic, ataxiaPrioSets, ataxiaPrioSetsHandler = nil, {}, nil, nil

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
