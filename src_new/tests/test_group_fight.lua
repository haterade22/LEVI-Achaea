--- test_group_fight.lua -- the party and defence faults from the 2026-11-03 group fight (v4.7.474)
--
-- The fight: fightlogs 080944_Lauryyn, 081009_Froedine, 081532_Tabethys, and log_shi_group.txt.
--   * A leader's repeat call ran the whole target switch: 18 of 49 calls named the target we held.
--   * The curing set followed the called target: 77 `curingset switch` sends in 19 minutes.
--   * `curing priority defence avoid 25` was refused 47 times.
--   * `queue add inr all` printed "Unknown queue specified."
-- These run the REAL trigger, engine and deffing code. Every global they change is restored at the end.
-- The round delivery faults from the same fight are in test_round_send.lua.

local mock = require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

local before = {}
for k, v in pairs(_G) do before[k] = v end
local tableSave, tableLoad, ioExists = table.save, table.load, io.exists

local LEVI ="src_new/scripts/levi_ataxia/levi/"
local PARTY = "src_new/triggers/levi_ataxia/for_levi/leviticus/party_targetting/002_Party_Targeting.lua"
local ENGINE = LEVI .. "levi_scripts/class_detect/001_Class_Detect_Engine.lua"
local DEFFING = LEVI .. "ataxia/deffing/002_Deffing_Up.lua"
local LOGIN = LEVI .. "ataxia/login/001_Login_Function.lua"

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
local function body(p) return assert((loadstring or load)(read(p):match("%]%]%-%-\r?\n(.*)$"), p)) end

local function has(list, want)
  for _, c in ipairs(list) do
    if c == want then return true end
  end
  return false
end

describe("a leader's call", function()
  local aliases
  local function call(speaker, name)
    local line = '(Party): ' .. speaker .. ' says, "Target: ' .. name .. '."'
    assert(TL.anyMatches(TL.patterns(PARTY), line), "the trigger no longer takes its line")
    matches = { line, speaker, name }
    body(PARTY)()
  end
  local function fresh()
    aliases = {}
    expandAlias = function(a) aliases[#aliases + 1] = a end
    partyleader, partyrelay, target = "Tabethys", true, "Lauryyn"
  end

  it("for a new name runs the switch, with no relay", function()
    fresh()
    call("Tabethys", "Froedine")
    expect(aliases[1]).toBe("t Froedine")
    expect(partyrelay).toBe(false)
  end)

  it("for the name we hold does nothing at all", function()
    fresh()
    call("Tabethys", "Lauryyn")
    expect(#aliases).toBe(0)
    expect(partyrelay).toBe(true)
  end)

  it("compares without case: a call in lower case is the same person", function()
    fresh()
    call("Tabethys", "lauryyn")
    expect(#aliases).toBe(0)
  end)

  it("from anyone but the leader does nothing, as before", function()
    fresh()
    call("Kaden", "Froedine")
    expect(#aliases).toBe(0)
  end)

  it("with no target yet runs the switch", function()
    fresh()
    target = nil
    call("Tabethys", "Froedine")
    expect(aliases[1]).toBe("t Froedine")
  end)
end)

-- The engine is loaded in a table of its own stubs: its handlers and its saved config stay out of
-- the other test files.
describe("the curing set in a party", function()
  local sent, ndbClass
  local function loadEngine()
    sent = {}
    send = function(c) sent[#sent + 1] = c end
    ataxia_sendCuringPriority = function(c) sent[#sent + 1] = c end
    ataxia_bashProfileActive = function() return false end
    isDefenceForCurrentClass = function() return true end
    getEpoch = function() return 1000 end
    registerAnonymousEventHandler = function() return 1 end
    killAnonymousEventHandler = function() end
    cecho = function() end
    table.save, table.load = function() end, function() end
    io.exists = function() return false end
    ataxiaNDB_getClass = function() return ndbClass end
    ataxia = { settings = { defences = { current = "shi",
      defup = { shi = { vitality = true, avoid = true, shikudoform = true, starburst = true } },
      keepup = { shi = { vitality = true } } } }, channels = {} }
    ataxiaTemp = {}
    target = "Lauryyn"
    classDetect = nil
    dofile(ENGINE)
    dofile(DEFFING)
    classDetect.config.apiLookupEnabled = false
  end
  local function fresh(channels)
    loadEngine()
    ataxia.channels = channels
    classDetect.state.currentCuringset = "normal"
    classDetect.state.lastSwitchTime = 0
    ndbClass = "Serpent"
    sent = {}
  end
  local IN_PARTY = { party = "Party", ct = "Mhaldor" }

  it("out of a party, a called target still picks its class set", function()
    fresh({ ct = "Mhaldor" })
    classDetect.onTargetChanged()
    expect(sent[1]).toBe("curingset switch serpent")
    expect(classDetect.state.currentCuringset).toBe("serpent")
  end)

  it("in a party, a called target sends nothing", function()
    fresh(IN_PARTY)
    classDetect.onTargetChanged()
    expect(#sent).toBe(0)
    expect(classDetect.state.currentCuringset).toBe("normal")
  end)

  it("in a party, one attacker's class sends nothing either", function()
    fresh(IN_PARTY)
    classDetect.setAttackerClass("Lauryyn", "Serpent")
    expect(#sent).toBe(0)
    expect(classDetect.state.currentCuringset).toBe("normal")
  end)

  it("joining a party on a class set goes back to normal at the next detection", function()
    fresh(IN_PARTY)
    classDetect.state.currentCuringset = "serpent"
    classDetect.onTargetChanged()
    expect(sent[1]).toBe("curingset switch normal")
    expect(classDetect.state.currentCuringset).toBe("normal")
  end)

  it("an API answer in a party sends nothing", function()
    fresh(IN_PARTY)
    classDetect.switchCuringset("Serpent")
    expect(#sent).toBe(0)
  end)

  it("no channel list yet counts as no party", function()
    fresh(nil)
    expect(classDetect.inParty()).toBe(false)
    classDetect.onTargetChanged()
    expect(sent[1]).toBe("curingset switch serpent")
  end)

  describe("the defence list", function()
    local function line()
      for _, c in ipairs(sent) do
        if c:find("^curing priority defence %a") and not c:find("list reset", 1, true) then return c end
      end
    end

    it("a set switch leaves out what the game refuses", function()
      fresh({ ct = "Mhaldor" })
      classDetect.onTargetChanged()
      expect(has(sent, "curing priority defence list reset")).toBeTrue()
      expect(line():find("vitality 25", 1, true) ~= nil).toBeTrue()
      for _, def in ipairs({ "avoid", "shikudoform", "starburst" }) do
        expect(line():find(def, 1, true)).toBeNil()
      end
    end)

    it("a defup leaves them out too", function()
      fresh({ ct = "Mhaldor" })
      killTimer, tempTimer = function() end, function() return 1 end
      checkSSCErrors = function() end
      ataxiaEcho = function() end
      systemDefup("shi")
      expect(line():find("vitality 25", 1, true) ~= nil).toBeTrue()
      expect(line():find("avoid", 1, true)).toBeNil()
    end)

    it("the failsafe does not reset them", function()
      fresh({ ct = "Mhaldor" })
      killTimer = function() end
      ataxia.settings.defences.keepup.shi = {}
      defupFailsafe()
      expect(line():find("vitality reset", 1, true) ~= nil).toBeTrue()
      expect(line():find("avoid", 1, true)).toBeNil()
    end)

    it("a defence coming up does not reset what the game refuses", function()
      fresh({ ct = "Mhaldor" })
      dofile(LEVI .. "ataxia/deffing/001_Defence_API.lua")
      ataxiaBasher = { enabled = false }
      trueDef = function(d) return d end
      ataxia.defences = {}
      ataxia.settings.defences.keepup.shi = {}
      gmcp = { Char = { Defences = { Add = { name = "epitomise" } } } }
      gotDef()
      expect(has(sent, "curing priority defence epitomise reset")).toBe(false)
      gmcp.Char.Defences.Add = { name = "shikudoform" }
      gotDef()
      expect(has(sent, "curing priority defence shikudoform reset")).toBe(false)
      gmcp.Char.Defences.Add = { name = "vitality" }
      gotDef()
      expect(has(sent, "curing priority defence vitality reset")).toBeTrue()
    end)

    it("other defences still take a priority", function()
      fresh({})
      expect(ataxia_defenceTakesPriority("vitality")).toBeTrue()
      expect(ataxia_defenceTakesPriority("avoid")).toBe(false)
    end)
  end)
end)

describe("the login's queue lines", function()
  it("name a queue: `queue add inr all` printed `Unknown queue specified.`", function()
    local src = read(LOGIN)
    expect(src:find("queue add inr all", 1, true)).toBeNil()
    expect(src:find("queue add free inr all", 1, true) ~= nil).toBeTrue()
  end)
end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
table.save, table.load, io.exists = tableSave, tableLoad, ioExists
mock.reset()
