--- test_fight_log.lua -- the fight recorder (v4.7.418)
--
-- Loads the REAL script. Pins when a recording starts and stops, the row format the importer reads,
-- and that the catch-all trigger and the timer go away with the recording. Every global this file
-- creates or replaces is restored at the end (one shared Lua state for all test files).

require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end

local clock = 1000000.25
local handlers, timers, trigs = {}, {}, {}
getEpoch = function() return clock end
registerAnonymousEventHandler = function(ev, fn)
  handlers[ev] = handlers[ev] or {}
  table.insert(handlers[ev], fn)
  return #handlers[ev]
end
killAnonymousEventHandler = function() end
tempTimer = function(d, fn) timers[#timers + 1] = { d = d, fn = fn, live = true }; return #timers end
killTimer = function(id) if timers[id] then timers[id].live = false end end
tempRegexTrigger = function(p, fn) trigs[#trigs + 1] = { p = p, fn = fn, live = true }; return #trigs end
killTrigger = function(id) if trigs[id] then trigs[id].live = false end end
ataxiaEcho = function() end
isPrompt = function() return false end
ataxia = { settings = {}, playersHere = { "Agathon" } }
ataxiaTemp = {}
ataxiaVersion = "test"
target = "Agathon"
gmcp = { Char = { Status = { class = "Monk" }, Afflictions = {}, Defences = {} } }

dofile("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/026_Fight_Log.lua")
local F = ataxiaFight

-- A writable folder on every runtime (see test_kb_capture.lua: lua5.1.exe's os.tmpname() names the
-- drive root, so it is moved into %TEMP%).
local DIR
do
  local name = os.tmpname()
  if name:sub(1, 1) == "\\" and name:sub(2, 2) ~= "\\" then
    local d = os.getenv("TEMP") or os.getenv("TMP")
    if d then name = d .. name end
  end
  os.remove(name)
  DIR = name:match("^(.*)[/\\]")
end
F.dir = function() return DIR end

local made = {}
local function fire(ev, ...)
  for _, fn in ipairs(handlers[ev] or {}) do fn(ev, ...) end
end
local function feed(text, prompt)
  line = text
  isPrompt = function() return prompt or false end
  for i = #trigs, 1, -1 do
    if trigs[i].live then return trigs[i].fn() end
  end
end
local function read(path)
  made[#made + 1] = path
  local f = assert(io.open(path, "r"))
  local s = f:read("*a")
  f:close()
  return s
end
local function fresh(opts)
  if F.isRecording() then made[#made + 1] = F.stop("test reset") end
  opts = opts or {}
  ataxiaTemp = {}
  ataxia.settings = { fightlog = opts.cfg }
  ataxia.playersHere = opts.players or { "Agathon" }
  target = opts.target or "Agathon"
  clock = clock + 1000
end
local function has(text, s) return text:find(s, 1, true) ~= nil end

describe("fight log: when it starts", function()
  it("starts on a queued command naming our target while the target is a player here, in any case", function()
    fresh({ target = "agathon" })
    fire("sysDataSendRequest", "queue addclearfull freestand combo agathon sweep")
    expect(F.isRecording()).toBeTrue()
    expect(ataxiaTemp.fightlog.opp).toBe("Agathon")
    expect(ataxiaTemp.fightlog.auto).toBeTrue()
    local text = read(F.stop("test"))
    expect(has(text, " > queue addclearfull freestand combo agathon sweep")).toBeTrue()
    expect(has(text, "| our attack")).toBeTrue()
  end)

  it("does not start for a number, a denizen, a command that is not queued, or with auto off", function()
    fresh({ target = "12345" })
    fire("sysDataSendRequest", "queue addclearfull freestand kill 12345")
    expect(F.isRecording()).toBeFalse()
    fresh({ target = "rat" })
    fire("sysDataSendRequest", "queue add bal kill rat")
    expect(F.isRecording()).toBeFalse()
    fresh()
    fire("sysDataSendRequest", "say hello Agathon")
    expect(F.isRecording()).toBeFalse()
    fresh({ cfg = { auto = false } })
    fire("sysDataSendRequest", "queue add bal combo Agathon sweep")
    expect(F.isRecording()).toBeFalse()
  end)

  it("starts when a player attacks us (the class detector's event)", function()
    fresh()
    fire("attacker class detected", "Belaziel", "Depthswalker")
    expect(F.isRecording()).toBeTrue()
    expect(ataxiaTemp.fightlog.opp).toBe("Belaziel")
    local text = read(F.stop("test"))
    expect(has(text, "| opponent Belaziel | our class Monk | attacked by Depthswalker")).toBeTrue()
  end)
end)

describe("fight log: what it records", function()
  it("writes the header, then lines, prompts, our commands, our afflictions and defences, and the tracker", function()
    fresh()
    local path = F.start("Agathon", "test", false)
    feed("Agathon swings at you.")
    feed("5000h, 4000m ex-", true)
    fire("sysDataSendRequest", "touch tree")
    gmcp.Char.Afflictions.Add = { name = "paralysis", cure = "bloodroot" }
    fire("gmcp.Char.Afflictions.Add")
    gmcp.Char.Afflictions.Remove = { "paralysis" }
    fire("gmcp.Char.Afflictions.Remove")
    gmcp.Char.Defences.Add = { name = "shield", desc = "shield" }
    fire("gmcp.Char.Defences.Add")
    gmcp.Char.Defences.Remove = { "shield" }
    fire("gmcp.Char.Defences.Remove")
    fire("tar afflicted", { "asthma", "slickness" })
    fire("target cured aff", "asthma")
    expect(F.stop("done")).toBe(path)
    local text = read(path)
    expect(text:find("# LEVI fight log | version test | started ", 1, true)).toBe(1)
    expect(text:find("\n%d%d:%d%d:%d%d%.250 | Agathon swings at you%.\n") ~= nil).toBeTrue()
    for _, row in ipairs({ " P 5000h, 4000m ex-", " > touch tree", " +aff paralysis", " -aff paralysis",
      " +def shield", " -def shield", " +tar asthma slickness", " -tar asthma" }) do
      expect(has(text, row)).toBeTrue()
    end
    expect(has(text, "# stopped: done | 9 rows | ")).toBeTrue()
  end)

  it("takes the trigger and the timer away with the recording", function()
    fresh()
    F.start("Agathon", "test", false)
    local s = ataxiaTemp.fightlog
    expect(trigs[s.trig].live).toBeTrue()
    expect(timers[s.timer].live).toBeTrue()
    read(F.stop("test"))
    expect(trigs[s.trig].live).toBeFalse()
    expect(timers[s.timer].live).toBeFalse()
  end)

  it("ignores the events when it is not recording", function()
    fresh()
    gmcp.Char.Afflictions.Add = { name = "paralysis" }
    fire("gmcp.Char.Afflictions.Add")
    fire("tar afflicted", { "asthma" })
    expect(F.isRecording()).toBeFalse()
  end)

  it("stops at the row cap", function()
    fresh()
    local cap = F.MAX_ROWS
    F.MAX_ROWS = 3
    F.start("Agathon", "test", false)
    for i = 1, 5 do feed("line " .. i) end
    F.tick()
    F.MAX_ROWS = cap
    expect(F.isRecording()).toBeFalse()
    local text = read(ataxiaTemp.fightlogLast)
    expect(has(text, "line 3")).toBeTrue()
    expect(has(text, "line 4")).toBeFalse()
    expect(has(text, "# stopped: row cap (3) reached")).toBeTrue()
  end)
end)

describe("fight log: when it stops", function()
  it("keeps recording for TAIL seconds after a kill, then stops", function()
    fresh()
    fire("sysDataSendRequest", "queue add bal combo Agathon sweep")
    feed("You have slain Agathon.")
    clock = clock + 1
    feed("Defeated, Agathon is cast out of the Arena.")
    F.tick()
    expect(F.isRecording()).toBeTrue()
    clock = clock + F.TAIL
    F.tick()
    expect(F.isRecording()).toBeFalse()
    local text = read(ataxiaTemp.fightlogLast)
    expect(has(text, "Defeated, Agathon is cast out of the Arena.")).toBeTrue()
    expect(has(text, "# stopped: we killed Agathon")).toBeTrue()
  end)

  it("stops on our death and on the arena's verdicts", function()
    for l, why in pairs({ ["You have been slain by Belaziel."] = "we died",
      ["You have been defeated and are thrown out of the Arena."] = "we lost (arena)",
      ["You have been victorious and leave the Arena in triumph!"] = "we won (arena)" }) do
      fresh()
      F.start("Agathon", "test", false)
      feed(l)
      clock = clock + F.TAIL
      F.tick()
      expect(F.isRecording()).toBeFalse()
      expect(has(read(ataxiaTemp.fightlogLast), "# stopped: " .. why)).toBeTrue()
    end
  end)

  it("an automatic recording stops after the idle time; activity naming the opponent resets it", function()
    fresh({ target = "agathon" })
    fire("sysDataSendRequest", "queue add bal combo agathon sweep")
    clock = clock + 50
    feed("Agathon jabs you.")
    clock = clock + 50
    F.tick()
    expect(F.isRecording()).toBeTrue()
    clock = clock + 61
    F.tick()
    expect(F.isRecording()).toBeFalse()
    expect(has(read(ataxiaTemp.fightlogLast), "# stopped: nothing naming Agathon for 60 s")).toBeTrue()
  end)

  it("a recording started by hand ignores the idle time", function()
    fresh()
    F.command("on Agathon")
    clock = clock + 600
    F.tick()
    expect(F.isRecording()).toBeTrue()
    F.command("off")
    expect(F.isRecording()).toBeFalse()
    read(ataxiaTemp.fightlogLast)
  end)

  it("after an automatic stop, the same opponent starts no new log for REARM seconds", function()
    fresh()
    fire("sysDataSendRequest", "queue add bal combo Agathon sweep")
    feed("You have slain Agathon.")
    clock = clock + F.TAIL
    F.tick()
    read(ataxiaTemp.fightlogLast)
    clock = clock + 5
    fire("sysDataSendRequest", "queue add bal combo Agathon sweep")
    expect(F.isRecording()).toBeFalse()
    clock = clock + F.REARM
    fire("sysDataSendRequest", "queue add bal combo Agathon sweep")
    expect(F.isRecording()).toBeTrue()
  end)
end)

describe("fight log: settings", function()
  it("auto on|off and idle <seconds> change the settings; bad input changes nothing", function()
    fresh()
    F.command("auto off")
    expect(ataxia.settings.fightlog.auto).toBeFalse()
    F.command("auto maybe")
    expect(ataxia.settings.fightlog.auto).toBeFalse()
    F.command("auto on")
    expect(ataxia.settings.fightlog.auto).toBeTrue()
    F.command("idle 30")
    expect(ataxia.settings.fightlog.idle).toBe(30)
    F.command("idle soon")
    F.command("idle -5")
    expect(ataxia.settings.fightlog.idle).toBe(30)
  end)
end)

-- Clean up the logs and restore the shared Lua state.
if F.isRecording() then made[#made + 1] = F.stop("end of tests") end
for _, p in ipairs(made) do os.remove(p) end
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
