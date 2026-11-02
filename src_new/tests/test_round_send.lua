--- test_round_send.lua -- round delivery by server alias (ataxia/003, plan step 3, 2026-11-01).
--
-- Mudlet splits `;` on our side, so `queue addclear free a;b;c` queues only `a`. The shim sends
-- `setalias lvfree a/b/c`, then `queue addclear free lvfree`. It is off by default, Monk only, and not
-- yet proven in a fight. kb/mechanics/balance-and-queueing.md has the evidence.
--
-- Loads the REAL send wrapper (misc_scripts/031), the shim, combatQueue, the Shikudo offences, queue_Scan,
-- the fight log and the gag trigger. `send` here is the mock's own, which splits `;` as Mudlet does.
-- Every global these create or change is restored at the end (one shared Lua state for all test files).

local mock = require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end

local TL = dofile("src_new/tests/trigger_lib.lua")

local ROOT = "src_new/"
local LEVI = ROOT .. "scripts/levi_ataxia/levi/"
local SH = LEVI .. "levi_scripts/shikudo/"
local QUEUEING = LEVI .. "ataxia/ataxia/003_Queueing_Related.lua"
local TRAITS = LEVI .. "ataxia/misc_scripts/031_Traits.lua"
local KAIKATA = LEVI .. "ataxia/monk/004_Kai_And_Kata.lua"
local SCAN = LEVI .. "ataxia/misc_scripts/001_Queue_Scanning.lua"
local FIGHTLOG = LEVI .. "ataxia/misc_scripts/026_Fight_Log.lua"
local TRIG = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/800_Gag_Round_Alias.lua"
local ALIAS = ROOT .. "aliases/levi_ataxia/for_levi/levi_062424/configs/033_Rounds.lua"
local SHIELD_KEY = ROOT .. "aliases/levi_ataxia/for_levi/levi_062424/combat_aliases/004_shielding_cward.lua"
local TAROT_LUST = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/lust/001_Tarot_Lust.lua"
local LOGIN = LEVI .. "ataxia/login/001_Login_Function.lua"

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
local function body(p) return assert((loadstring or load)(read(p):match("%]%]%-%-\r?\n(.*)$"), p)) end

local now = 1000
getEpoch = function() return now end
cecho = function() end
local echoed = {}
ataxiaEcho = function(s) echoed[#echoed + 1] = s end
tempTimer = function() end
sendGMCP = function() end
local saves = 0
ataxia_saveSettings = function() saves = saves + 1 end
isTargeted = function(n) return type(n) == "string" and type(target) == "string" and n:lower() == target:lower() end
ataxia_isClass = function(c) return c:lower() == "monk" end
selectCurrentLine, fg, resetFormat = function() end, function() end, function() end
deleteFull, enableTrigger = function() end, function() end
ataxiaBasher = { enabled = false }
ataxia = { vitals = {}, settings = {}, afflictions = {} }
ataxiaTemp = {}
tAffs = {}
target = "Sadey"
lb = {}
tBals = { tree = true, timers = {} }
gmcp = { Char = { Status = { class = "Monk" }, Items = {} }, Room = {} }
local targetClass = "Unknown"
ataxiaNDB_getClass = function() return targetClass end

-- Capture the handlers monk/004 and the fight log register for what we send.
local handlers = {}
registerAnonymousEventHandler = function(ev, fn)
  handlers[ev] = handlers[ev] or {}
  table.insert(handlers[ev], fn)
  return #handlers[ev]
end
killAnonymousEventHandler = function() end

-- The wrapper wraps what `send` is when 031 loads. An earlier file may have left a wrapper flag set.
ataxia_sendWrapped, ataxia_rawSend = nil, nil
send = mock.send

for _, f in ipairs({ QUEUEING, TRAITS, KAIKATA, SCAN, SH .. "006_CC_Shikudo_Dispatch.lua",
                     SH .. "007_CC_Shikudo_Lock.lua", SH .. "010_Shikudo_Strike_Ledger.lua",
                     SH .. "011_Shikudo_Telepathy.lua", SH .. "013_Shikudo_Group_Damage.lua", FIGHTLOG }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

local realCombatQueue = combatQueue

-- A Monk with the flag as given (nil = never set), no target state, an empty send record.
local function fresh(flag)
  ataxia.settings = { separator = ";", roundDelivery = flag and { monk = flag } or nil }
  ataxia.vitals = { form = "Oak", kata = 0, eq = true, mpp = 90 }
  ataxia.playersHere = { "Sadey", "Akri" }
  ataxiaBasher = { enabled = false }
  ataxiaTemp = {}
  gmcp.Char.Status.class = "Monk"
  target = "Sadey"
  tAffs = {}
  tBals = { tree = true, timers = {} }
  haveAff = function(a) return tAffs[a] and true or false end
  combatQueue, reboundHold, tCity = realCombatQueue, nil, nil
  tChaseTimer, jestercheese, myaeon, preventriftlock, stoplatency = nil, nil, nil, nil, nil
  havebomb, tdeliverance = nil, nil
  lb = { Sadey = { hits = { head = 0, torso = 0, ["left arm"] = 0, ["right arm"] = 0,
    ["left leg"] = 0, ["right leg"] = 0 } } }
  gmcp.Char.Items.List = { location = "inv", items = {
    { id = "489282", name = "a twisted oaken staff" },
  } }
  shikudo.invEvent("gmcp.Char.Items.List")
  echoed = {}
  saves = 0
  mock.reset()
end

local function sent() return mock.sent_commands end

-- The exact lines that reached Mudlet's own send, and the argument after each, without the mock's split.
local function rawCalls(fn)
  local calls, saved = {}, ataxia_rawSend
  ataxia_rawSend = function(cmd, echo) calls[#calls + 1] = { cmd = cmd, echo = echo } end
  local ok, err = pcall(fn)
  ataxia_rawSend = saved
  if not ok then error(err, 0) end
  return calls
end

local function same(list, want)
  local a, b = table.concat(list, " | "), table.concat(want, " | ")
  if a ~= b then error("sent: [" .. a .. "]\nwant: [" .. b .. "]", 2) end
end

-- Lines that must leave unchanged with the flag off, and with it on when they are not a plain chain.
local ROUNDS = {
  "queue addclear free a;b;c",
  "queue addclearfull freestand stand;a;b",
  "queue addclear eqbal a;b",
  "queue addclear free combo Sadey a b c",
  "cq all;touch shield",
  "touch tree",
}

describe("flag off: every send is byte-identical", function()
  local function untouched(flag, setupFn)
    for _, line in ipairs(ROUNDS) do
      fresh(flag)
      if setupFn then setupFn() end
      local calls = rawCalls(function() send(line, false) end)
      expect(#calls).toBe(1)
      expect(calls[1].cmd).toBe(line)
      expect(calls[1].echo).toBe(false)
    end
  end

  it("the flag was never set", function() untouched(nil) end)
  it("the flag says raw", function() untouched("raw") end)

  it("the second argument still reaches Mudlet's send, and a missing one stays missing", function()
    fresh(nil)
    local calls = rawCalls(function() send("queue addclear free a;b") end)
    expect(calls[1].echo).toBeNil()
  end)

  it("it leaves no state behind", function()
    fresh(nil)
    send("queue addclear free a;b;c")
    expect(ataxiaTemp.roundSend).toBeNil()
  end)

  it("the measured problem: Mudlet's split queues only the first command", function()
    fresh(nil)
    send("queue addclear free a;b;c")
    same(sent(), { "queue addclear free a", "b", "c" })
  end)
end)

describe("flag on: one alias, one queue line", function()
  it("sends exactly setalias, then the queue line, with no ; left", function()
    fresh("alias")
    send("queue addclear free a;b;c")
    same(sent(), { "setalias lvfree a/b/c", "queue addclear free lvfree" })
  end)

  it("setalias is silent, and the queue line keeps the caller's argument", function()
    fresh("alias")
    local calls = rawCalls(function() send("queue addclear free a;b", false) end)
    expect(calls[1].cmd).toBe("setalias lvfree a/b")
    expect(calls[1].echo).toBe(false)
    expect(calls[2].cmd).toBe("queue addclear free lvfree")
    expect(calls[2].echo).toBe(false)
    fresh("alias")
    calls = rawCalls(function() send("queue addclear free a;b") end)
    expect(calls[2].echo).toBeNil()
  end)

  it("sends no setalias when the text has not changed, and a new one when it has", function()
    fresh("alias")
    send("queue addclear free a;b")
    mock.reset()
    send("queue addclear free a;b")
    same(sent(), { "queue addclear free lvfree" })
    mock.reset()
    send("queue addclear free a;c")
    same(sent(), { "setalias lvfree a/c", "queue addclear free lvfree" })
  end)

  it("keeps ADDCLEARFULL", function()
    fresh("alias")
    send("queue addclearfull eqbal a;b")
    same(sent(), { "setalias lveqbal a/b", "queue addclearfull eqbal lveqbal" })
  end)

  it("reads the verb and the type in any case", function()
    fresh("alias")
    send("QUEUE AddClear FREE a;b")
    same(sent(), { "setalias lvfree a/b", "queue addclear free lvfree" })
  end)

  it("joins on the package's own separator as well", function()
    fresh("alias")
    ataxia.settings.separator = "::"
    send("queue addclear free a::b;c")
    same(sent(), { "setalias lvfree a/b/c", "queue addclear free lvfree" })
  end)

  it("trims each command and drops empty ones", function()
    fresh("alias")
    send("queue addclear free  a ; ;combo Sadey b ;")
    same(sent(), { "setalias lvfree a/combo Sadey b", "queue addclear free lvfree" })
  end)

  it("takes ASSESS out first, when we lack the trait", function()
    fresh("alias")
    ataxia.settings.traits = { list = {} }
    send("queue addclear free wield x;combo Sadey a b c;assess Sadey")
    same(sent(), { "setalias lvfree wield x/combo Sadey a b c", "queue addclear free lvfree" })
  end)
end)

describe("flag on: what passes through unchanged", function()
  local LINES = {
    { "a / in the payload", "queue addclear free a/b;c" },
    { "a % in the payload", "queue addclear free a%b;c" },
    { "a { in the payload", "queue addclear free a{b;c" },
    { "stand;<dir>", "queue addclear free stand;n" },
    { "stand;<long dir>", "queue addclear free stand;northeast" },
    { "stand;tumble <dir>", "queue addclear free stand;tumble sw" },
    { "stand;mountjump <dir>", "queue addclear free stand;mountjump s" },
    { "a chase in the prefix", "queue addclear free g body;g gold;stand;w;combo Sadey a" },
    { "queue add", "queue add free a;b" },
    { "queue insert", "queue insert free 1 a;b" },
    { "queue prepend", "queue prepend free a;b" },
    { "a custom type", "queue addclear eb!p!w!t a;b" },
    { "an unknown type", "queue addclear swimming a;b" },
    { "no space after the type", "queue addclear free;stand;stand;wield staff;combo Sadey a" },
    { "one command", "queue addclear free combo Sadey a" },
    { "one command and a trailing ;", "queue addclear free combo Sadey a;" },
    { "stand alone", "queue addclear free stand;" },
    { "not a queue line", "cq all;touch shield" },
    { "a stand in full", "queue addclear full stand;a" },
  }
  for _, row in ipairs(LINES) do
    it(row[1], function()
      fresh("alias")
      local calls = rawCalls(function() send(row[2]) end)
      expect(#calls).toBe(1)
      expect(calls[1].cmd).toBe(row[2])
    end)
  end

  it("the length cap: 138 characters go by alias, 139 stay raw", function()
    local function chain(n)
      local a = string.rep("x", 60)
      return a .. ";" .. a .. ";" .. string.rep("y", n - 122)
    end
    fresh("alias")
    send("queue addclear free " .. chain(138))
    same(sent(), { "setalias lvfree " .. chain(138):gsub(";", "/"), "queue addclear free lvfree" })
    expect(#(sent()[1]:sub(#"setalias lvfree " + 1))).toBe(138)
    fresh("alias")
    local calls = rawCalls(function() send("queue addclear free " .. chain(139)) end)
    expect(#calls).toBe(1)
    expect(calls[1].cmd).toBe("queue addclear free " .. chain(139))
  end)
end)

describe("a pass-through leaves no stale alias queued", function()
  it("in the same queue the raw ADDCLEAR replaces it, so nothing more is sent", function()
    fresh("alias")
    send("queue addclear free a;b")
    mock.reset()
    send("queue addclear free stand;n")
    same(sent(), { "queue addclear free stand", "n" })
    expect(ataxiaTemp.roundSend.queued.free).toBeNil()
  end)

  it("in another queue it is cleared first", function()
    fresh("alias")
    send("queue addclear free a;b")
    mock.reset()
    send("queue addclear freestand stand;n")
    same(sent(), { "clearqueue free", "queue addclear freestand stand", "n" })
    expect(ataxiaTemp.roundSend.queued.free).toBeNil()
  end)

  it("so does a one-command line and a custom type", function()
    fresh("alias")
    send("queue addclear free a;b")
    mock.reset()
    send("queue addclear eqbal combo Sadey a")
    same(sent(), { "clearqueue free", "queue addclear eqbal combo Sadey a" })
    fresh("alias")
    send("queue addclear free a;b")
    mock.reset()
    send("queue addclear eb!p!w!t combo Sadey a")
    same(sent(), { "clearqueue free", "queue addclear eb!p!w!t combo Sadey a" })
  end)

  it("ADDCLEARFULL wipes every queue itself", function()
    fresh("alias")
    send("queue addclear free a;b")
    mock.reset()
    send("queue addclearfull eqbal stand;n")
    same(sent(), { "queue addclearfull eqbal stand", "n" })
    expect(ataxiaTemp.roundSend.queued.free).toBeNil()
  end)

  it("a line that only adds does not supersede the round, so the alias stays", function()
    fresh("alias")
    send("queue addclear free a;b")
    mock.reset()
    send("queue add free c")
    same(sent(), { "queue add free c" })
    expect(ataxiaTemp.roundSend.queued.free).toBeTrue()
  end)

  it("an alias round in another queue clears the old alias too", function()
    fresh("alias")
    send("queue addclear eqbal a;b")
    mock.reset()
    send("queue addclear free c;f")
    same(sent(), { "clearqueue eqbal", "setalias lvfree c/f", "queue addclear free lvfree" })
  end)

  -- A run line cannot say which press it answers. Round B can replace round A while A's run line is
  -- in flight, so that line must not mark the queue empty: B would then fire beside the next line.
  it("a run line does not mark the queue empty, because a newer round may wait there", function()
    fresh("alias")
    send("queue addclear free a;b")
    send("queue addclear free c;f")
    ataxia_roundRan("LVFREE")
    mock.reset()
    send("queue addclear freestand combo Sadey a b c")
    same(sent(), { "clearqueue free", "queue addclear freestand combo Sadey a b c" })
    expect(ataxiaTemp.roundSend.queued.free).toBeNil()
  end)
end)

-- The next attack press rewrites `lvfree`, and the game reads the alias when it fires. So a line in
-- that slot only runs if recovery lands before the next press. These lines must not wait there.
describe("a line that must not wait in the attack's slot stays raw", function()
  local shieldKey = body(SHIELD_KEY)
  local function press(word)
    matches = { word, word }
    shieldKey()
  end
  local function sentBy(flag, fn)
    fresh(flag)
    fn()
    return table.concat(sent(), " | ")
  end

  it("ts sends the same lines with the flag on as with it off", function()
    local off = sentBy(nil, function() press("ts") end)
    expect(off).toBe("queue addclear freestand g body | g gold | stand | touch shield")
    expect(sentBy("alias", function() press("ts") end)).toBe(off)
  end)

  it("cwd sends the same lines with the flag on as with it off", function()
    local off = sentBy(nil, function() press("cwd") end)
    expect(off).toBe("queue addclear freestand g body | g gold | stand | curseward")
    expect(sentBy("alias", function() press("cwd") end)).toBe(off)
  end)

  it("ts, then an attack press: the shield still goes out as its own line, and no alias holds it", function()
    fresh("alias")
    press("ts")
    shikudo.dispatch()
    local own = 0
    for _, line in ipairs(sent()) do
      if line == "touch shield" then own = own + 1 end
      if line:find("^setalias") and line:find("touch shield", 1, true) then error("an alias holds the shield: " .. line) end
    end
    expect(own).toBe(1)
  end)

  it("an attack waiting in free is cleared first, and the next press queues it again", function()
    fresh("alias")
    shikudo.dispatch()
    mock.reset()
    press("ts")
    same(sent(), { "clearqueue free", "queue addclear freestand g body", "g gold", "stand", "touch shield" })
    mock.reset()
    shikudo.dispatch()
    same(sent(), { "queue addclear free lvfree" })
  end)

  it("a tarot lust's reject stays raw, so its enemy cannot be rewritten away", function()
    fresh("alias")
    ataxia.lustedto = {}
    ataxia_needReject = function() return true end
    ataxia_boxEcho = function() end
    matches = { "the lust line", "Bob" }
    -- Mudlet's own helper, absent from the mock. It is not a global, so the end of this file cannot restore it.
    local savedContains = table.contains
    table.contains = function(t, v)
      for _, x in ipairs(t) do if x == v then return true end end
      return false
    end
    local ok, calls = pcall(rawCalls, body(TAROT_LUST))
    table.contains = savedContains
    if not ok then error(calls, 0) end
    expect(#calls).toBe(1)
    expect(calls[1].cmd).toBe("queue addclear free reject Bob;enemy Bob")
    expect(ataxiaTemp.roundSend == nil or ataxiaTemp.roundSend.aliases.lvfree == nil).toBeTrue()
  end)

  it("the words are read in any case, and a target's name is not one of them", function()
    fresh("alias")
    local calls = rawCalls(function() send("queue addclear free stand;TOUCH SHIELD") end)
    expect(#calls).toBe(1)
    fresh("alias")
    send("queue addclear free wield x;combo Reject a")
    same(sent(), { "setalias lvfree wield x/combo Reject a", "queue addclear free lvfree" })
  end)

  -- MIND BLACKOUT hides the combo behind it, and that combo goes by `queue add`, raw. With the
  -- blackout in an alias the two wait in different queues, so the combo could run first, unhidden.
  it("MIND BLACKOUT's press sends the same lines with the flag on as with it off", function()
    local function vv(flag)
      return sentBy(flag, function()
        ataxia.vitals = { form = "Rain", kata = 0, eq = true, mpp = 90 }
        tAffs = { paralysis = true }
        shikudo.tele.blackout = true
        local ok, err = pcall(shikudo.dispatchMind)
        shikudo.tele.blackout = false
        if not ok then error(err, 0) end
      end)
    end
    local off = vv(nil)
    expect(off:find("mind blackout", 1, true) ~= nil).toBeTrue()
    expect(off:find("queue add free wield staff489282", 1, true) ~= nil).toBeTrue()
    expect(vv("alias")).toBe(off)
  end)
end)

describe("the gates", function()
  it("another class stays raw, even with the flag in its slot", function()
    fresh("alias")
    gmcp.Char.Status.class = "Serpent"
    ataxia.settings.roundDelivery.serpent = "alias"
    expect(ataxia_roundMode()).toBe("raw")
    local calls = rawCalls(function() send("queue addclear free a;b") end)
    expect(calls[1].cmd).toBe("queue addclear free a;b")
    expect(#calls).toBe(1)
  end)

  it("no class known yet stays raw", function()
    fresh("alias")
    gmcp.Char.Status.class = nil
    expect(ataxia_roundMode()).toBe("raw")
    gmcp.Char.Status.class = "Monk"
  end)

  it("the basher stays raw", function()
    fresh("alias")
    ataxiaBasher.enabled = true
    expect(ataxia_roundMode()).toBe("raw")
    local calls = rawCalls(function() send("queue addclearfull freestand stand;a;b") end)
    expect(calls[1].cmd).toBe("queue addclearfull freestand stand;a;b")
    expect(#calls).toBe(1)
    ataxiaBasher.enabled = false
    expect(ataxia_roundMode()).toBe("alias")
  end)

  it("the default is raw: no setting exists until the user chooses", function()
    fresh(nil)
    expect(ataxia_roundMode()).toBe("raw")
    expect(ataxia.settings.roundDelivery).toBeNil()
    local src = read(LEVI .. "ataxia/002_Check_For_Any_Missing_Variables.lua")
      .. read(LEVI .. "ataxia/001_Save_Load_Settings.lua")
    expect(src:find("roundDelivery", 1, true)).toBeNil()
  end)
end)

describe("aconfig rounds", function()
  local run = body(ALIAS)
  local function press(arg)
    matches = { "aconfig rounds" .. (arg and (" " .. arg) or ""), arg }
    run()
  end

  it("alias saves it under the class, and raw puts it back", function()
    fresh(nil)
    press("alias")
    expect(ataxia.settings.roundDelivery.monk).toBe("alias")
    expect(ataxia_roundMode()).toBe("alias")
    expect(saves).toBe(1)
    press("raw")
    expect(ataxia.settings.roundDelivery.monk).toBe("raw")
    expect(ataxia_roundMode()).toBe("raw")
    expect(saves).toBe(2)
  end)

  it("with no argument it only shows the setting, and says it is not proven", function()
    fresh(nil)
    press(nil)
    expect(saves).toBe(0)
    expect(ataxia.settings.roundDelivery).toBeNil()
    expect(table.concat(echoed):find("not yet proven", 1, true) ~= nil).toBeTrue()
  end)

  it("refuses alias on another class and stores nothing", function()
    fresh(nil)
    gmcp.Char.Status.class = "Serpent"
    press("alias")
    expect(ataxia.settings.roundDelivery).toBeNil()
    expect(saves).toBe(0)
    expect(table.concat(echoed):find("Monk only", 1, true) ~= nil).toBeTrue()
  end)

  it("raw clears what the alias path queued", function()
    fresh("alias")
    send("queue addclear free a;b")
    mock.reset()
    press("raw")
    same(sent(), { "clearqueue free" })
  end)

  -- The run line's wording on this path is not yet seen. If an earlier raw round set runLine, 007 and
  -- 011 would no longer count at the press, and a wording we cannot read would stop the MIND cap.
  it("alias starts the press-time count again, until a run line matches on this path", function()
    fresh(nil)
    shikudoLock.state.runLine = true
    ataxiaTemp.shikTele = { burst = 0, runLine = true }
    press("alias")
    expect(shikudoLock.state.runLine).toBeNil()
    expect(ataxiaTemp.shikTele.runLine).toBeNil()
    shikudoLock.state.pending = nil
    shikudoLock.dispatch()
    expect(shikudoLock.state.pending.committed).toBeTrue()
    shikudoLock.state.pending = nil
  end)

  it("raw leaves those flags alone: the raw path's run line is known", function()
    fresh("alias")
    shikudoLock.state.runLine = true
    press("raw")
    expect(shikudoLock.state.runLine).toBeTrue()
    shikudoLock.state.runLine = nil
  end)

  it("tells the user when the basher holds it raw", function()
    fresh("alias")
    ataxiaBasher.enabled = true
    press(nil)
    expect(table.concat(echoed):find("raw while the basher is on", 1, true) ~= nil).toBeTrue()
  end)

  it("the regex takes alias, raw and nothing else", function()
    local src = read(ALIAS)
    expect(src:find("regex: ^aconfig rounds(?: (alias|raw))?$", 1, true) ~= nil).toBeTrue()
  end)
end)

describe("alias names", function()
  it("every name is letters only and at most 12 characters", function()
    local n = 0
    for qtype in pairs(ataxia_ROUND_TYPES) do
      local name = "lv" .. qtype
      expect(name:match("^%a+$")).toBe(name)
      expect(#name <= 12).toBeTrue()
      n = n + 1
    end
    expect(n).toBe(7)
  end)

  it("the longest name fits", function()
    fresh("alias")
    send("queue addclear freestand a;b")
    same(sent(), { "setalias lvfreestand a/b", "queue addclear freestand lvfreestand" })
    expect(#"lvfreestand").toBe(11)
  end)
end)

describe("round order: stand first, and a chain that stands leaves freestand", function()
  it("a freestand chain that stands us up goes to free", function()
    fresh("alias")
    send("queue addclear freestand stand;x;y")
    same(sent(), { "setalias lvfree stand/x/y", "queue addclear free lvfree" })
  end)

  it("ADDCLEARFULL too", function()
    fresh("alias")
    send("queue addclearfull freestand stand;x")
    same(sent(), { "setalias lvfree stand/x", "queue addclearfull free lvfree" })
  end)

  it("a freestand chain with no stand stays in freestand", function()
    fresh("alias")
    send("queue addclear freestand x;y")
    same(sent(), { "setalias lvfreestand x/y", "queue addclear freestand lvfreestand" })
  end)

  it("moving to free clears an alias waiting in freestand", function()
    fresh("alias")
    send("queue addclear freestand x;y")
    mock.reset()
    send("queue addclear freestand stand;z")
    same(sent(), { "clearqueue freestand", "setalias lvfree stand/z", "queue addclear free lvfree" })
  end)

  it("full needs class balance, so its chain with no stand stays in full", function()
    fresh("alias")
    send("queue addclear full x;y")
    same(sent(), { "setalias lvfull x/y", "queue addclear full lvfull" })
  end)

  it("stand moves to the front, once, and the rest keep their order", function()
    fresh("alias")
    send("queue addclear free g body;g gold;stand;wield x;combo Sadey a")
    same(sent(), { "setalias lvfree stand/g body/g gold/wield x/combo Sadey a", "queue addclear free lvfree" })
    fresh("alias")
    send("queue addclear free stand;stand;wield x;combo Sadey a")
    same(sent(), { "setalias lvfree stand/wield x/combo Sadey a", "queue addclear free lvfree" })
  end)

  it("no stand is added to a chain that has none", function()
    fresh("alias")
    send("queue addclear free wield x;combo Sadey a")
    same(sent(), { "setalias lvfree wield x/combo Sadey a", "queue addclear free lvfree" })
  end)

  it("a spender is never moved: the offence owns that order", function()
    fresh("alias")
    send("queue addclear free combo Sadey a;kai choke Sadey;wield x")
    same(sent(), { "setalias lvfree combo Sadey a/kai choke Sadey/wield x", "queue addclear free lvfree" })
  end)
end)

describe("reload", function()
  it("an empty ataxiaTemp sets the alias again, with the same text", function()
    fresh("alias")
    send("queue addclear free a;b")
    ataxiaTemp = {}
    mock.reset()
    send("queue addclear free a;b")
    same(sent(), { "setalias lvfree a/b", "queue addclear free lvfree" })
  end)

  -- The real reset lines of levilogin(). The whole function needs the full client.
  local function loginResets()
    local block = assert(read(LOGIN):match('\n(ataxia_resetTargetBals%(%).-)\nexpandAlias%("t Penwize"%)'))
    local saved = ataxia_resetTargetBals
    ataxia_resetTargetBals = function() end
    local ok, err = pcall(assert((loadstring or load)(block)))
    ataxia_resetTargetBals = saved
    if not ok then error(err, 0) end
  end

  it("a login sets the alias again: a press during a dropped link recorded text the server never got", function()
    fresh("alias")
    send("queue addclear free a;b")
    rawCalls(function() send("queue addclear free c;f") end)  -- the link is down: the setalias goes nowhere
    loginResets()
    mock.reset()
    send("queue addclear free c;f")
    same(sent(), { "setalias lvfree c/f", "queue addclear free lvfree" })
  end)

  it("re-running 031 keeps Mudlet's send and wraps it once, with the shim", function()
    local rawBefore = ataxia_rawSend
    dofile(TRAITS)
    dofile(TRAITS)
    expect(ataxia_rawSend).toBe(rawBefore)
    fresh("alias")
    send("queue addclear free a;b")
    same(sent(), { "setalias lvfree a/b", "queue addclear free lvfree" })
  end)

  it("a wrapper left by an older version is replaced, so the shim reaches the game without a restart", function()
    local rawBefore = ataxia_rawSend
    send = function(cmd, ...) return ataxia_rawSend(ataxia_traitFilter(cmd), ...) end -- the old wrapper
    dofile(TRAITS)
    expect(ataxia_rawSend).toBe(rawBefore)
    fresh("alias")
    send("queue addclear free a;b")
    same(sent(), { "setalias lvfree a/b", "queue addclear free lvfree" })
  end)

  it("re-running the shim's file keeps the text, so a reload sends no needless rewrite", function()
    fresh("alias")
    send("queue addclear free a;b")
    dofile(QUEUEING)
    mock.reset()
    send("queue addclear free a;b")
    same(sent(), { "queue addclear free lvfree" })
  end)
end)

describe("the readers", function()
  it("a run line naming the alias reads as the chain the offence built", function()
    fresh("alias")
    send("queue addclear free g body;g gold;stand;combo Sadey a")
    expect(ataxia_roundRan("LVFREE")).toBe("g body;g gold;stand;combo Sadey a")
    expect(ataxia_roundRan("lvfree")).toBe("g body;g gold;stand;combo Sadey a")
    expect(ataxia_roundRan("G BODY")).toBe("G BODY")
    expect(ataxia_roundRan("LVPROBE")).toBe("LVPROBE")
  end)

  it("with nothing sent, a run line stays as it is", function()
    fresh(nil)
    expect(ataxia_roundRan("LVFREE")).toBe("LVFREE")
    expect(ataxia_roundRan("G BODY")).toBe("G BODY")
  end)

  it("a sent queue line reads as the alias text, and any other line as itself", function()
    fresh("alias")
    send("queue addclear free a;combo Sadey b")
    expect(ataxia_roundSentText("queue addclear free lvfree")).toBe("a/combo Sadey b")
    expect(ataxia_roundSentText("queue addclear free combo Sadey b")).toBe("queue addclear free combo Sadey b")
    expect(ataxia_roundSentText("touch tree")).toBe("touch tree")
  end)

  it("queue_Scan reads the chain", function()
    fresh("alias")
    local ran = 0
    ataxia_extispicyRan = function() ran = ran + 1 end
    ataxiaTemp.dissectHold = true
    send("queue addclear free dissect rat;combo Sadey a")
    queue_Scan("lvfree")
    expect(ran).toBe(1)
    ataxia_extispicyRan = nil
  end)

  it("the fight log starts on a queue line that names the alias, as it does on the old line", function()
    fresh("alias")
    send("queue addclear free wield x;combo Sadey a")
    expect(ataxiaFight.isAttack("queue addclear free lvfree")).toBeTrue()
    target = "Akri"
    expect(ataxiaFight.isAttack("queue addclear free lvfree")).toBeFalse()
    target = "Sadey"
  end)

  it("the fight log's header says alias, and its first rows give the text", function()
    fresh("alias")
    send("queue addclear free wield x;combo Sadey a")
    local saved = ataxiaFight.dir
    ataxiaFight.dir = function() return "." end
    local started = ataxiaFight.start("Sadey", "test", false)
    local rows = table.concat(ataxiaTemp.fightlog.buf, "\n")
    ataxiaTemp.fightlog = nil
    ataxiaFight.dir = saved
    expect(started ~= nil).toBeTrue()
    expect(rows:find("| test | rounds alias\n", 1, true) ~= nil).toBeTrue()
    expect(rows:find("# alias lvfree holds: wield x/combo Sadey a", 1, true) ~= nil).toBeTrue()
  end)

  it("the fight log's idle clock sees the target through the alias", function()
    fresh("alias")
    send("queue addclear free wield x;combo Sadey a")
    local saved = ataxiaFight.write
    ataxiaFight.write = function() end
    ataxiaTemp.fightlog = { opp = "Sadey", lastAt = 1, buf = {}, rows = 0, path = "x" }
    ataxiaFight.onSent(nil, "queue addclear free lvfree")
    expect(ataxiaTemp.fightlog.lastAt).toBe(now)
    ataxiaFight.write = saved
    ataxiaTemp.fightlog = nil
  end)

  it("the form stamp sees a CRESCENT through the alias, on a press with unchanged text", function()
    fresh("alias")
    ataxia.settings.fightlog = { auto = false } -- this event also reaches the fight log
    send("queue addclear free wield x;combo Sadey crescent")
    expect(ataxiaTemp.shikFormSendAt).toBeNil()
    for _, fn in ipairs(handlers["sysDataSendRequest"]) do fn(nil, "queue addclear free lvfree") end
    expect(ataxiaTemp.shikFormSendAt).toBe(now)
  end)
end)

describe("the gag", function()
  local pats = TL.patterns(TRIG)

  it("gags the echo of every alias name the shim can write", function()
    for qtype in pairs(ataxia_ROUND_TYPES) do
      local echo = 'Alias "lv' .. qtype .. '" will now execute: "stand/wield staff/combo Sadey a"'
      expect(TL.anyMatches(pats, echo)).toBeTrue()
    end
  end)

  it("leaves other aliases alone: a test alias still shows", function()
    expect(TL.anyMatches(pats, 'Alias "lvprobe" will now execute: "say one"')).toBeFalse()
    expect(TL.anyMatches(pats, 'Alias "pk" will now execute: "stand"')).toBeFalse()
    expect(TL.anyMatches(pats, 'You have cleared alias "lvfree".')).toBeFalse()
  end)

  it("deletes the line and never the prompt after it", function()
    local deleted, full = 0, 0
    local savedFull = deleteFull
    deleteLine = function() deleted = deleted + 1 end
    deleteFull = function() full = full + 1 end
    body(TRIG)()
    deleteFull = savedFull
    expect(deleted).toBe(1)
    expect(full).toBe(0)
  end)
end)

-- Real rounds, built by the real offences and the real combatQueue, through the real wrapper.
describe("a real Shikudo round goes through it", function()
  local function chainOf(line)
    local text = line:match("^setalias lvfree (.+)$")
    local pieces = {}
    for piece in (text or ""):gmatch("[^/]+") do pieces[#pieces + 1] = piece end
    return pieces
  end

  local function lockState()
    local st = shikudoLock.state
    st.pending, st.runLine, st.lastRound, st.lastSay = nil, nil, nil, nil
    st.mindRun, st.prelude, st.choking = 0, 0, false
  end

  -- Reads the lines BEFORE the mock's split, which would hide a `;`.
  local function noSemicolon(fn)
    local calls = rawCalls(fn)
    expect(#calls > 0).toBeTrue()
    for _, c in ipairs(calls) do
      if c.cmd:find(";", 1, true) then error("left a ; on its way to the game: " .. c.cmd, 2) end
    end
  end

  it("flag off, the real round splits as it did: the setup goes out first and raw", function()
    fresh(nil)
    shikudo.dispatch()
    expect(sent()[1]).toBe("queue addclear free g body")
    expect(sent()[2]).toBe("g gold")
    expect(sent()[3]).toBe("stand")
  end)

  it("006 (zz): stand, the setup, wield, and the combo last", function()
    fresh("alias")
    shikudo.dispatch()
    expect(#sent()).toBe(2)
    expect(sent()[2]).toBe("queue addclear free lvfree")
    local c = chainOf(sent()[1])
    expect(c[1]).toBe("stand")
    expect(c[2]).toBe("g body")
    expect(c[3]).toBe("g gold")
    expect(c[4]).toBe("wield staff489282")
    expect(c[#c]:find("^combo Sadey ") ~= nil).toBeTrue()
    expect(#sent()[1] - #"setalias lvfree " <= 138).toBeTrue()
    fresh("alias")
    noSemicolon(shikudo.dispatch)
  end)

  it("006: a second press with nothing changed sends only the queue line", function()
    fresh("alias")
    shikudo.dispatch()
    mock.reset()
    shikudo.dispatch()
    same(sent(), { "queue addclear free lvfree" })
  end)

  it("007 (sr): the round goes through, and the run line commits it", function()
    fresh("alias")
    lockState()
    shikudoLock.dispatch()
    expect(sent()[2]).toBe("queue addclear free lvfree")
    local c = chainOf(sent()[1])
    expect(c[1]).toBe("stand")
    expect(c[#c]:find("^combo Sadey ") ~= nil or c[#c]:find("^mind ") ~= nil).toBeTrue()
    expect(shikudoLock.state.pending ~= nil).toBeTrue()
    -- We expect the run line to name LVFREE, until the first alias fight confirms it. Without the
    -- translation, that key would never match, and the round would stay pending.
    expect(shikudoLock.onQueueRan("LVFREE")).toBeTrue()
    expect(shikudoLock.state.pending).toBeNil()
    expect(shikudoLock.state.runLine).toBeTrue()
  end)

  it("007: a run line that is not ours does not commit the pending round", function()
    fresh("alias")
    lockState()
    shikudoLock.dispatch()
    expect(shikudoLock.onQueueRan("LVEQBAL")).toBeFalse()
    expect(shikudoLock.state.pending ~= nil).toBeTrue()
  end)

  it("013 (srd) in Rain: MIND CRUSH is the spender and it comes last, with no combo", function()
    fresh("alias")
    ataxia.vitals = { form = "Rain", kata = 0, eq = true, mpp = 90 }
    shikudoDmg.state = { breathHeld = {} }
    shikudoDmg.dispatch()
    expect(sent()[2]).toBe("queue addclear free lvfree")
    local c = chainOf(sent()[1])
    expect(c[#c]:find("^mind crush Sadey") ~= nil).toBeTrue()
    for _, piece in ipairs(c) do expect(piece:find("^combo ")).toBeNil() end
  end)

  it("011 (vv): a MIND round goes through, and the run line commits it", function()
    fresh("alias")
    ataxia.vitals = { form = "Rain", kata = 0, eq = true, mpp = 90 }
    tAffs = { asthma = true, slickness = true, anorexia = true }
    local tele = ataxiaTemp.shikTele
    expect(tele).toBeNil()
    shikudo.dispatchMind()
    expect(sent()[2]).toBe("queue addclear free lvfree")
    local c = chainOf(sent()[1])
    expect(c[1]).toBe("stand")
    expect(c[#c]:find("^mind ") ~= nil).toBeTrue()
    expect(shikudo.onTeleQueueRan("LVFREE")).toBeTrue()
    expect(ataxiaTemp.shikTele.pending).toBeNil()
  end)

  it("011: a combo round that ran by alias ends the burst", function()
    fresh("alias")
    shikudo.dispatch()
    ataxiaTemp.shikTele = { burst = 2 }
    expect(shikudo.onTeleQueueRan("LVFREE")).toBeFalse()
    expect(ataxiaTemp.shikTele.burst).toBe(0)
  end)

  it("no round of 006, 007, 011 or 013 leaves a ; on its way to the game", function()
    fresh("alias")
    noSemicolon(shikudo.dispatch)
    fresh("alias")
    lockState()
    noSemicolon(shikudoLock.dispatch)
    fresh("alias")
    ataxia.vitals = { form = "Rain", kata = 0, eq = true, mpp = 90 }
    tAffs = { asthma = true, slickness = true, anorexia = true }
    noSemicolon(shikudo.dispatchMind)
    fresh("alias")
    ataxia.vitals = { form = "Rain", kata = 0, eq = true, mpp = 90 }
    shikudoDmg.state = { breathHeld = {} }
    noSemicolon(shikudoDmg.dispatch)
  end)

  it("with the flag off, the same read sees the `;`, so that check can fail", function()
    fresh(nil)
    local calls = rawCalls(shikudo.dispatch)
    expect(calls[1].cmd:find(";", 1, true) ~= nil).toBeTrue()
  end)
end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
mock.reset()
