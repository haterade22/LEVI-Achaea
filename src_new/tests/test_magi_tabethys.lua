--- test_magi_tabethys.lua -- what Tabethys's log of a Magi kill changed in our Magi (v4.7.429)
--
-- Source: kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt, one group fight and one
-- stormhammer kill. What was wrong, and is checked here:
--   * stormhammer (005): the finders take only ENEMIED players (of a known city, in city mode), so
--     a target we had not enemied was left out. Alone in the room it got "No ... enemies" and NO
--     send, so P4 and group mode sent an empty kill round; with others listed, the stormhammer went
--     at them. It also sent the bare cast, with no stand or staff and shield. And a target that is
--     not listed in the room (hidden) must not be cast at: "You cannot see that being here."
--   * general/001_Assess set targetHealth from anyone's glance.
--   * 014_Temperance recorded a strip on anyone as our target's.
--   * the compact echoes (`You: <Spell> -> X`, `<Plane>: <Stage> -> X`) and the prompt's stage word.
-- The dehydrate double burn is in test_magi_tracking.lua, the assess error in test_monk_kai_kata.lua.
-- One shared Lua state: every global, and table.contains, is restored at the end.

local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains

local MAGE = "src_new/scripts/levi_ataxia/levi/levi_scripts/mage/"
local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local NAME = "Kalys"

magi = nil
ataxia = { afflictions = {}, settings = { separator = "::" }, playersHere = {} }
ataxiaTemp, tAffs = { enemies = {} }, {}
target = NAME
targetHealth, php, partyrelay = 100, nil, false
gmcp = { Char = { Name = { name = "Tabethys" }, Status = { class = "Magi" },
  Vitals = { bal = "1", eq = "1", charstats = {} } } }

table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

-- The target's afflictions: one set behind the public API.
local has = {}
haveAff = function(a) return has[a] == true end
tarAffed = function(...) for _, a in ipairs({ ... }) do has[a] = true end end
erAff = function(a) has[a] = nil end
getAffProbabilityV3 = function(a) return has[a] and 1 or 0 end
isTargeted = function(n) return type(target) == "string" and n:lower() == target:lower() end

local cities = {}
ataxiaNDB_getCitizenship = function(n) return cities[n] end

local sent, echoes = {}, {}
send = function(cmd) sent[#sent + 1] = cmd end
cecho = function(s) echoes[#echoes + 1] = s end
echo = function() end
ataxiaEcho = function(s) echoes[#echoes + 1] = s end
ataxia_boxEcho = function(s) echoes[#echoes + 1] = s end
local now = 1000
getEpoch = function() return now end
tempTimer = function() return 1 end
killTimer = function() end

local loadErr
for _, f in ipairs({ MAGE .. "001_Resonance.lua", MAGE .. "004_Magi_Offense.lua",
  MAGE .. "005_Stormhammer_Targeting.lua" }) do
  local okLoad, errLoad = pcall(dofile, f)
  if not okLoad then loadErr = "Failed to load " .. f .. ": " .. tostring(errLoad); break end
end

local function body(file)
  local fh = assert(io.open(TRG .. file, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(assert(src:match("%]%]%-%-\r?\n(.*)$"), "no header: " .. file), file))
end

local function world(opts)
  opts = opts or {}
  has = {}
  for _, a in ipairs(opts.affs or {}) do has[a] = true end
  sent, echoes = {}, {}
  now = now + 100   -- past any cast-echo window
  target = NAME
  targetHealth, php = opts.hp or 100, nil
  ataxia.playersHere = opts.here or { NAME }
  ataxiaTemp.enemies = opts.enemies or {}
  cities = opts.cities or {}
  magi.storm.mode = opts.mode or "city"
  magi.resonance = { fire = 0, water = 0, earth = 0, air = 0 }
  for k, v in pairs(opts.reso or {}) do magi.resonance[k] = v end
  local st = magi.offense.state
  st.mode, st.burns, st.scalded, st.conflagrated = opts.offMode or "fire", opts.burns or 0, opts.scalded or false, false
  st.shalestorm, st.calcifiedTorso = false, false
  magi.offense.config.compactEcho = true
  tburns = st.burns
end

local function allEchoes() return table.concat(echoes, "\n") end

local ok, err = pcall(function()
if loadErr then error(loadErr, 0) end
local ASSESS, TEMPER, RESO, FAN = body("general/001_Assess.lua"), body("general/014_Temperance.lua"),
  body("general/022_Resonance_Afflictions.lua"), body("general/022_Increase_Burning.lua")

describe("stormhammer: our target in the room is always slot 1", function()
  it("not enemied and alone: a single-target stormhammer, not an empty round", function()
    world({ hp = 20 })
    magi.offense.selectSpell()
    expect(#sent).toBe(1)
    expect(sent[1]).toContain("cast stormhammer at Kalys::assess Kalys")
  end)

  it("the round stands and wields the staff and shield, as every round does", function()
    world({ hp = 20 })
    magi.offense.selectSpell()
    expect(sent[1]).toContain("queue addclearfull freestand stand::wield ")
    expect(sent[1]).toContain(" shield::cast stormhammer at Kalys")
  end)

  it("not enemied, with two enemied citymates here: the target first, then them", function()
    world({ hp = 20, here = { "Ana", NAME, "Bo" }, enemies = { "Ana", "Bo" },
      cities = { Ana = "Hashan", Bo = "Hashan", Kalys = "Hashan" } })
    magi.offense.selectSpell()
    expect(sent[1]).toContain("cast stormhammer at Kalys and Ana and Bo::")
  end)

  it("enemied with citymates: unchanged, the target first, three at most", function()
    world({ hp = 20, here = { "Ana", "Bo", NAME, "Cy" }, enemies = { "Ana", "Bo", NAME, "Cy" },
      cities = { Ana = "Hashan", Bo = "Hashan", Kalys = "Hashan", Cy = "Hashan" } })
    magi.offense.selectSpell()
    expect(sent[1]).toContain("cast stormhammer at Kalys and Ana and Bo::")
  end)

  it("a target gmcp does not list (hidden, or gone): nothing is sent", function()
    world({ hp = 20, here = { "Ana" } })
    magi.offense.selectSpell()
    expect(#sent).toBe(0)
    expect(allEchoes()).toContain("No ")
  end)

  it("group mode at 50% takes the same path", function()
    world({ hp = 50, offMode = "group", scalded = true })
    magi.offense.selectSpell()
    expect(sent[1]).toContain("cast stormhammer at Kalys::")
  end)

  it("reproduces the bug: without the slot-1 rule the finders return nobody", function()
    world({ hp = 20 })
    expect(#magi.storm.findTargets()).toBe(0)
  end)
end)

describe("general/001_Assess: only our target's glance sets targetHealth", function()
  it("our target sets it, a bystander does not", function()
    world({ hp = 77 })
    matches = { "x", "Bystander", "his", "100", "1000" }
    ASSESS()
    expect(targetHealth).toBe(77)
    matches = { "x", "kalys", "his", "4415", "10034" }
    ASSESS()
    expect(targetHealth).toBe(44)
  end)
end)

describe("014_Temperance: only our target's strip, and its echo", function()
  it("a strip on someone else records nothing", function()
    world()
    matches = { "x", "Someoneelse" }
    TEMPER()
    expect(has.notemperance).toBeNil()
    expect(#echoes).toBe(0)
  end)

  it("our target: notemperance and `Fire: Temperance stripped -> Kalys`", function()
    world()
    matches = { "x", NAME }
    TEMPER()
    expect(has.notemperance).toBeTrue()
    expect(allEchoes()).toContain("Fire: <white>Temperance stripped <dim_grey>-> <NavajoWhite>Kalys")
  end)
end)

describe("the compact echoes", function()
  it("spell labels", function()
    local L = magi.offense.spellLabel
    expect(L("cast dehydrate at Kalys")).toBe("Dehydrate")
    expect(L("cast emanation at Kalys water")).toBe("Emanation water")
    expect(L("staffcast horripilation Kalys")).toBe("Horripilation")
    expect(L("staffcast scintilla at Kalys")).toBe("Scintilla")
    expect(L("cast meteorite at Kalys flaming 4")).toBe("Meteorite flaming 4")
  end)

  it("one cast line per round sent: a second press of the same round within 2 s prints nothing", function()
    world()
    magi.offense.sendAttack("cast dehydrate at Kalys")
    magi.offense.sendAttack("cast dehydrate at Kalys")
    expect(#sent).toBe(2)
    expect(#echoes).toBe(1)
    expect(echoes[1]).toContain("You: <white>Dehydrate <dim_grey>-> <NavajoWhite>Kalys")
    magi.offense.sendAttack("cast magma at Kalys")
    expect(#echoes).toBe(2)
    now = now + 3
    magi.offense.sendAttack("cast magma at Kalys")
    expect(#echoes).toBe(3)
  end)

  it("a resonance line prints `<Plane>: <Stage> -> <Target>` after the game line", function()
    world({ scalded = true })
    line = "You will that Kalys should burn, and so he does."
    matches = { line, NAME }
    RESO()
    expect(allEchoes()).toContain("Fire: <white>Scalded > Burning 1/5 <dim_grey>-> <NavajoWhite>Kalys")
    world()
    line = "A loud crack emanates from the right arm of Kalys."
    matches = { line, "right arm", NAME }
    RESO()
    expect(allEchoes()).toContain("Earth: <white>Broken right arm")
  end)

  it("the fan line prints the burn count", function()
    world({ burns = 1 })
    matches = { "x", NAME }
    FAN()
    expect(allEchoes()).toContain("Fire: <white>Burning 2/5")
  end)

  it("mm echo off silences all three", function()
    world()
    magi.offense.config.compactEcho = false
    magi.offense.sendAttack("cast dehydrate at Kalys")
    magi.offense.resoEcho("Fire", "Scalded", NAME)
    magi.offense.promptEcho()
    expect(allEchoes()).toBe("Target: Burns 0")
  end)
end)

describe("the stage word follows selectSpell's order", function()
  local W = function() return magi.offense.stageWord() end
  it("each stage", function()
    world(); expect(W()).toBe("scald")
    world({ scalded = true }); expect(W()).toBe("build")
    world({ scalded = true, burns = 2, affs = { "burning" } }); expect(W()).toBe("burn 2/5")
    world({ scalded = true, burns = 2 }); expect(W()).toBe("build")       -- V3 holds no burning: stale
    world({ affs = { "shield" } }); expect(W()).toBe("shield")
    world({ hp = 25 }); expect(W()).toBe("storm")
    world({ hp = 50, offMode = "group" }); expect(W()).toBe("storm")
    world({ hp = 50 }); expect(W()).toBe("scald")
    world({ affs = { "frozen", "hypothermia" }, reso = { water = 2, air = 2 } }); expect(W()).toBe("glaciate")
    world({ affs = { "frozen" }, reso = { water = 2, air = 2 } }); expect(W()).toBe("hypothermia")
    world({ offMode = "lock" }); expect(W()).toBe("lock")
  end)

  it("destroy outranks the shield, as P1 outranks P2", function()
    world({ hp = 30, affs = { "burning", "shield" } })
    magi.offense.state.conflagrated = true
    expect(W()).toBe("destroy")
    world({ hp = 40, affs = { "burning" } })
    magi.offense.state.conflagrated = true
    expect(W()).toBe("conflagrated")
  end)

  it("the water route names its own step, and the stage word sends nothing", function()
    world({ offMode = "waterroute" })
    expect(W()).toBe("opener")
    world({ offMode = "waterroute", hp = 10 })
    expect(W()).toBe("opener")
    expect(#sent).toBe(0)
  end)

  it("the prompt line: `Target: Burns 2 [burn 2/5]`", function()
    world({ scalded = true, burns = 2, affs = { "burning" } })
    magi.offense.promptEcho()
    expect(echoes[1]).toBe("Target: Burns 2 [burn 2/5]")
  end)
end)

end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
table.contains = savedContains
if not ok then error(err) end
