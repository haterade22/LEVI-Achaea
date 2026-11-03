--- test_mindnet_report.lua -- who a mindnet line calls to the party (v4.7.472)
--
-- A group fight on 2026-11-03 printed "Xylarys has entered the area." and nobody heard about it: the
-- trigger only sent `pt` with raid on, in Annwyn, or for a city enemy in the area named exactly
-- Mhaldor, and the fight was out on a road. `raid mindnet` read as the switch for this, and nothing
-- read that setting. These tests run the REAL trigger, the REAL ataxia_mindnetTellParty and the REAL
-- NDB helpers in a private environment, with the players from that fight.

local TL = dofile("src_new/tests/trigger_lib.lua")
local TRIGGER = "src_new/triggers/levi_ataxia/for_levi/leviticus/telepathy/001_Mindnet.lua"
local RAID = "src_new/scripts/levi_ataxia/levi/ataxia/013_Raid_Mode_Things_(WIP).lua"
local NDB = "src_new/scripts/levi_ataxia/levi/ataxia/ataxia_ndb/003_ataxiaNDB_API.lua"
local WILDS = "the Northern Wilderness"

local function contains(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

-- A private world: the globals the code reads come from opts, and what it writes stays in env.
local function world(opts)
  opts = opts or {}
  local rec = { sent = {}, acquired = {}, alerts = 0, boxes = 0 }
  local channels = { ct = "Mhaldor", party = "Party" }
  if opts.channels ~= nil then channels = opts.channels end
  if opts.noChannels then channels = nil end
  local env = setmetatable({
    matches = {},
    table = setmetatable({ contains = contains, index_of = function() return nil end }, { __index = table }),
    gmcp = {
      Room = { Info = { area = opts.area or WILDS } },
      Char = { Status = { name = "Leviticus" } },
    },
    ataxia = {
      channels = channels,
      settings = { raid = opts.raid or { mindnet = true }, paused = opts.paused or false },
    },
    ataxiaNDB = {
      players = {
        Xylarys = { city = "Eleusis" }, Lauryyn = { city = "Eleusis" }, Valkyri = { city = "Mhaldor" },
        Leviticus = { city = "Mhaldor" }, Vasyly = { city = "None" }, Hidey = { city = "(hidden)" },
      },
      cityEnemies = { "Akri", "Nahaj", "Xylarys" },
    },
    ataxiaTemp = { allies = opts.allies, enemies = opts.enemies },
    ataxiaBasher = { enabled = false },
    ataxia_paused = function() return opts.paused or false end,
    ataxiaNDB_Acquire = function(n) rec.acquired[#rec.acquired + 1] = n end,
    ataxiaBasher_alert = function() rec.alerts = rec.alerts + 1 end,
    ataxia_boxEcho = function() rec.boxes = rec.boxes + 1 end,
    cecho = function() end,
    send = function(c) rec.sent[#rec.sent + 1] = c end,
  }, { __index = _G })
  for _, path in ipairs({ NDB, RAID }) do
    local fn = assert(loadfile(path))
    setfenv(fn, env)
    fn()
  end
  return env, rec
end

-- Run the trigger for one game line, in a new world.
local function line(name, verb, opts)
  local env, rec = world(opts)
  local fn = assert(loadfile(TRIGGER))
  setfenv(fn, env)
  env.matches = { name .. " has " .. verb .. " the area.", name, verb }
  fn()
  return rec.sent, rec
end

describe("the mindnet line reaches the trigger", function()
  it("matches both lines from the game", function()
    local pats = TL.patterns(TRIGGER)
    expect(TL.anyMatches(pats, "Xylarys has entered the area.")).toBeTrue()
    expect(TL.anyMatches(pats, "Lauryyn has left the area.")).toBeTrue()
  end)
end)

describe("in a party, outside Mhaldor and Annwyn, raid off", function()
  it("calls a player of another city in and out", function()
    expect(line("Xylarys", "entered")[1]).toBe("pt Xylarys IN!")
    expect(line("Xylarys", "left")[1]).toBe("pt Xylarys OUT!")
  end)

  it("calls a non-citizen who is not a city enemy (the list is too small for this)", function()
    expect(line("Lauryyn", "entered")[1]).toBe("pt Lauryyn IN!")
  end)

  it("does not call a fellow citizen", function()
    expect(#line("Valkyri", "entered")).toBe(0)
  end)

  it("calls a player the NDB has not seen, and still asks the NDB about them", function()
    local sent, rec = line("Stranger", "entered")
    expect(sent[1]).toBe("pt Stranger IN!")
    expect(rec.acquired[1]).toBe("Stranger")
  end)

  it("calls a rogue and a hidden-city player", function()
    expect(line("Vasyly", "entered")[1]).toBe("pt Vasyly IN!")
    expect(line("Hidey", "entered")[1]).toBe("pt Hidey IN!")
  end)

  it("does not call an ally, whatever the city", function()
    expect(#line("Vasyly", "entered", { allies = { "Vasyly" } })).toBe(0)
    expect(#line("Xylarys", "entered", { allies = { "Xylarys" } })).toBe(0)
  end)

  it("does not call ourselves", function()
    expect(#line("Leviticus", "entered", { channels = { party = "Party" } })).toBe(0)
  end)

  it("sends only the party call: no clan line, no alert, no box", function()
    local sent, rec = line("Xylarys", "entered")
    expect(#sent).toBe(1)
    expect(rec.alerts).toBe(0)
    expect(rec.boxes).toBe(0)
  end)

  it("calls nobody while paused", function()
    expect(#line("Xylarys", "entered", { paused = true })).toBe(0)
  end)
end)

describe("party status comes from the channel list", function()
  it("sends nothing out of a party", function()
    expect(#line("Xylarys", "entered", { channels = { ct = "Mhaldor" } })).toBe(0)
  end)

  it("calls when the list is not read yet: a refused pt costs less than silence", function()
    expect(line("Lauryyn", "entered", { noChannels = true })[1]).toBe("pt Lauryyn IN!")
  end)

  it("with no city channel, calls every other player but an ally", function()
    local chans = { party = "Party" }
    expect(line("Valkyri", "entered", { channels = chans })[1]).toBe("pt Valkyri IN!")
    expect(#line("Valkyri", "entered", { channels = chans, allies = { "Valkyri" } })).toBe(0)
  end)
end)

describe("raid mindnet is the off switch", function()
  local off = function(extra)
    local raid = { mindnet = false }
    for k, v in pairs(extra or {}) do raid[k] = v end
    return raid
  end

  it("stops the party call, also with raid on and in Annwyn", function()
    expect(#line("Xylarys", "entered", { raid = off() })).toBe(0)
    local sent, rec = line("Xylarys", "entered", { raid = off({ enabled = true }) })
    expect(#sent).toBe(0)
    expect(rec.alerts).toBe(1)
    expect(#line("Xylarys", "entered", { raid = off(), area = "Annwyn" })).toBe(0)
  end)

  it("in Mhaldor stops the pt and keeps the clan line for a city enemy", function()
    local sent = line("Xylarys", "entered", { raid = off(), area = "Mhaldor" })
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("clt6 Xylarys has entered Mhaldor")
  end)

  it("the setting flips both ways from the seeded true", function()
    local env = world({ raid = { mindnet = true } })
    env.ataxia_raidToggle("mindnet")
    expect(env.ataxia.settings.raid.mindnet).toBeFalse()
    expect(env.ataxia_mindnetTellParty("Xylarys", WILDS)).toBeFalse()
    env.ataxia_raidToggle("mindnet")
    expect(env.ataxia.settings.raid.mindnet).toBeTrue()
    expect(env.ataxia_mindnetTellParty("Xylarys", WILDS)).toBeTrue()
  end)

  it("a save with no mindnet key (every save before this) still calls", function()
    expect(line("Xylarys", "entered", { raid = {} })[1]).toBe("pt Xylarys IN!")
  end)
end)

describe("the old cases keep their behaviour", function()
  it("raid on calls everyone, a citizen too, with the alert", function()
    local sent, rec = line("Valkyri", "entered", { raid = { mindnet = true, enabled = true } })
    expect(sent[1]).toBe("pt Valkyri IN!")
    expect(rec.alerts).toBe(1)
  end)

  it("raid on calls out of a party too", function()
    local raid = { mindnet = true, enabled = true }
    expect(line("Valkyri", "entered", { raid = raid, channels = { ct = "Mhaldor" } })[1]).toBe("pt Valkyri IN!")
  end)

  it("Annwyn calls everyone, a citizen too, with the alert and the box", function()
    local sent, rec = line("Valkyri", "left", { area = "Annwyn" })
    expect(sent[1]).toBe("pt Valkyri OUT!")
    expect(rec.alerts).toBe(1)
    expect(rec.boxes).toBe(1)
  end)

  it("Mhaldor: a city enemy gets pt, the clan line, the alert and the box, out of a party too", function()
    local sent, rec = line("Xylarys", "entered", { area = "Mhaldor", channels = { ct = "Mhaldor" } })
    expect(sent[1]).toBe("pt Xylarys IN!")
    expect(sent[2]).toBe("clt6 Xylarys has entered Mhaldor")
    expect(rec.alerts).toBe(1)
    expect(rec.boxes).toBe(1)
  end)

  it("Mhaldor: the clan line says left when a city enemy leaves", function()
    expect(line("Nahaj", "left", { area = "Mhaldor" })[2]).toBe("clt6 Nahaj has left Mhaldor")
  end)

  it("Mhaldor: a non-citizen who is not a city enemy gets the party call and no clan line", function()
    local sent, rec = line("Lauryyn", "entered", { area = "Mhaldor" })
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("pt Lauryyn IN!")
    expect(rec.alerts).toBe(0)
  end)

  it("Mhaldor: a citizen gets nothing", function()
    expect(#line("Valkyri", "entered", { area = "Mhaldor" })).toBe(0)
  end)

  it("a personal enemy still rings the alert, and the box only while bashing", function()
    local _, rec = line("Valkyri", "entered", { enemies = { "Valkyri" } })
    expect(rec.alerts).toBe(1)
    expect(rec.boxes).toBe(0)
  end)
end)
