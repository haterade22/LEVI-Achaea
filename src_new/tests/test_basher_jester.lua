--- test_basher_jester.lua -- Jester PvE bashing + the three Mnemosyne boons (v4.7.258)
--
-- Tough Crowd (BADJOKE becomes an AoE psychic nuke, but stuns and stupefies US),
-- Elusive Foolery (keep the SLIPPERY defence up), Apostatic (PRIESTESS tarot damages denizens).
-- Plus the base syntax fix: AB 681 gives "Syntax: BADJOKE" with no target.

require("mock_mudlet")

target = 7
ataxia = {
  settings = { separator = ";" },
  vitals = { rage = 0, hpp = 90, mp = 5000 },
  defences = {},
  afflictions = {},
}
ataxiaBasher = {
  shielded = false, rageraze = false, enabled = true, inMnemosyne = true,
  battlerage = { Jester = { small = "prank 7", large = "gambol 7", raze = "shatterbolt 7" } },
}
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "", num = 5 } },
  Char = { Status = { class = "Jester" } },
  IRE = { Target = { Info = { hpperc = "90%" } } },
}
function ataxiaEcho() end
function ataxiaBasher_assembleBattlerage() return "" end

local denizens = 0
local swarmState = "idle"
ataxia.mnemosyne = {
  _denizenCount = function() return denizens end,
  _cfg = function() return { swarm = { escapeAt = 35 } } end,
  roomLava = function() return ataxiaTemp.mnemLavaAt ~= nil end,
  swarm = setmetatable({}, { __index = function(_, k)
    if k == "state" then return swarmState end
  end }),
}

local clock = 100000
getEpoch = function() return clock end

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end

local function has(cmd, needle) return cmd:find(needle, 1, true) ~= nil end

local function reset()
  ataxiaBasher.shielded, ataxiaBasher.rageraze = false, false
  ataxia.vitals = { rage = 0, hpp = 90, mp = 5000 }
  ataxia.defences, ataxia.afflictions = {}, {}
  ataxiaTemp = {}
  mnemToughCrowd, mnemElusiveFoolery, mnemApostatic = false, false, false
  mnemMotleyBop, ataxiaBasher.jesterPriestess, ataxiaBasher.jesterMotleyAt = false, nil, nil
  gmcp.IRE.Target.Info.hpperc = "90%"
  ataxiaBasher.jesterJokeAt, ataxiaBasher.jesterJokeCd = nil, nil
  ataxiaBasher.jesterJokeMana, ataxiaBasher.jesterPriestessCd = nil, nil
  denizens, swarmState = 0, "idle"
  clock = clock + 500
end

-- ============================================================================
describe("BADJOKE takes no target (AB 681)", function()
  -- The shield-break sent "badjoke <target>" for as long as the Jester basher has existed.
  -- The ability is a ROOM effect -- "Works on: Adventurers, denizens, and room" -- so every
  -- one of those was malformed, and a rejected command is silent here.
  it("sends a bare badjoke on a shielded round", function()
    reset(); ataxiaBasher.shielded = true
    local cmd = ataxiaBasher_jesterBashing()
    expect(has(cmd, "badjoke")).toBeTrue()
    expect(has(cmd, "badjoke 7")).toBeFalse()
  end)

  it("strips shields without needing the boon", function()
    reset(); ataxiaBasher.shielded = true
    expect(ataxiaBasher_jesterBadjoke(";", true)).toBe("badjoke;")
  end)
end)

describe("Tough Crowd -- AoE psychic, at the price of stunning ourselves", function()
  it("does nothing without the boon", function()
    reset(); denizens = 4
    expect(ataxiaBasher_jesterBadjoke(";", false)).toBe("")
  end)

  it("fires at a crowd with the boon", function()
    reset(); mnemToughCrowd = true; denizens = 2
    expect(ataxiaBasher_jesterBadjoke(";", false)).toBe("badjoke;")
  end)

  it("holds off below the crowd threshold", function()
    reset(); mnemToughCrowd = true; denizens = 1
    expect(ataxiaBasher_jesterBadjoke(";", false)).toBe("")
  end)

  -- Equilibrium is not the limit -- how often we can afford to be unable to act is.
  it("is cooldown-limited well beyond its 3s equilibrium", function()
    reset(); mnemToughCrowd = true; denizens = 3
    expect(ataxiaBasher_jesterBadjoke(";", false)).toBe("badjoke;")
    clock = clock + 4
    expect(ataxiaBasher_jesterBadjoke(";", false)).toBe("")
    clock = clock + 20
    expect(ataxiaBasher_jesterBadjoke(";", false)).toBe("badjoke;")
  end)

  -- Stun blocks every action and stupidity eats queued commands. Doing that to ourselves
  -- mid-retreat is how every escape this session was lost, only on purpose.
  it("refuses while escaping", function()
    reset(); mnemToughCrowd = true; denizens = 3
    ataxiaTemp.escapeMode = true
    expect(ataxiaBasher_jesterJokeSafe()).toBeFalse()
    expect(ataxiaBasher_jesterBadjoke(";", false)).toBe("")
  end)

  it("refuses at or below the escape threshold", function()
    reset(); mnemToughCrowd = true; denizens = 3
    ataxia.vitals.hpp = 20
    expect(ataxiaBasher_jesterJokeSafe()).toBeFalse()
  end)

  it("refuses in lava and mid-recovery", function()
    reset(); mnemToughCrowd = true; denizens = 3
    ataxiaTemp.mnemLavaAt = clock
    expect(ataxiaBasher_jesterJokeSafe()).toBeFalse()
    ataxiaTemp.mnemLavaAt = nil
    swarmState = "recovering"
    expect(ataxiaBasher_jesterJokeSafe()).toBeFalse()
  end)

  it("refuses when already unable to act", function()
    reset(); mnemToughCrowd = true; denizens = 3
    ataxia.afflictions.stun = true
    expect(ataxiaBasher_jesterJokeSafe()).toBeFalse()
  end)

  -- 100 mana a throw, and under Corrupted Breath mana never comes back.
  it("keeps mana headroom", function()
    reset(); mnemToughCrowd = true; denizens = 3
    ataxia.vitals.mp = 150
    expect(ataxiaBasher_jesterBadjoke(";", false)).toBe("")
  end)

  -- Without the boon there is no self-affliction, so none of the danger gates apply.
  it("the safety gate is inert without the boon", function()
    reset()
    ataxiaTemp.escapeMode = true
    ataxia.vitals.hpp = 5
    expect(ataxiaBasher_jesterJokeSafe()).toBeTrue()
  end)

  -- A shielded round with the joke unsafe must still do something.
  it("falls back to the rage raze when the joke is unsafe", function()
    reset(); mnemToughCrowd = true
    ataxiaBasher.shielded = true
    ataxiaTemp.escapeMode = true
    local cmd = ataxiaBasher_jesterBashing()
    expect(has(cmd, "badjoke")).toBeFalse()
    expect(has(cmd, "shatterbolt")).toBeTrue()
  end)
end)

describe("Elusive Foolery -- keep SLIPPERY up", function()
  it("raises it when the defence is down", function()
    reset(); mnemElusiveFoolery = true
    expect(ataxiaBasher_jesterSlippery(";")).toBe("slippery;")
  end)

  it("does nothing while it is already up", function()
    reset(); mnemElusiveFoolery = true
    ataxia.defences.slippery = true
    expect(ataxiaBasher_jesterSlippery(";")).toBe("")
  end)

  it("does nothing without the boon", function()
    reset()
    expect(ataxiaBasher_jesterSlippery(";")).toBe("")
  end)

  -- An unconfirmed raise must not cost every round.
  it("holds between attempts", function()
    reset(); mnemElusiveFoolery = true
    expect(ataxiaBasher_jesterSlippery(";")).toBe("slippery;")
    expect(ataxiaBasher_jesterSlippery(";")).toBe("")
    clock = clock + 20
    expect(ataxiaBasher_jesterSlippery(";")).toBe("slippery;")
  end)

  it("rides the assembled round, including a shielded one", function()
    reset(); mnemElusiveFoolery = true
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_jesterBashing():find("slippery", 1, true)).toBe(1)
  end)
end)

describe("Apostatic -- priestess is BALANCE (AB 605) and off by default", function()
  -- User, 2026-10-07: "Just account for it, dont use it for now".
  it("sends nothing with the boon alone", function()
    reset(); mnemApostatic = true
    expect(ataxiaBasher_jesterPriestess()).toBe("")
    expect(has(ataxiaBasher_jesterBashing(), "priestess")).toBeFalse()
  end)

  it("needs the boon even when opted in", function()
    reset(); ataxiaBasher.jesterPriestess = true
    expect(ataxiaBasher_jesterPriestess()).toBe("")
  end)

  it("flings at the target when opted in", function()
    reset(); mnemApostatic = true; ataxiaBasher.jesterPriestess = true
    expect(ataxiaBasher_jesterPriestess()).toBe("fling priestess at 7")
  end)

  it("breaks the shield first", function()
    reset(); mnemApostatic = true; ataxiaBasher.jesterPriestess = true
    ataxiaBasher.shielded = true
    expect(ataxiaBasher_jesterPriestess()).toBe("")
  end)

  it("is on a generous cooldown", function()
    reset(); mnemApostatic = true; ataxiaBasher.jesterPriestess = true
    expect(ataxiaBasher_jesterPriestess()).toBe("fling priestess at 7")
    clock = clock + 5
    expect(ataxiaBasher_jesterPriestess()).toBe("")
    clock = clock + 30
    expect(ataxiaBasher_jesterPriestess()).toBe("fling priestess at 7")
  end)

  it("needs a numeric target", function()
    reset(); mnemApostatic = true; ataxiaBasher.jesterPriestess = true
    target = "Somebody"
    expect(ataxiaBasher_jesterPriestess()).toBe("")
    target = 7
  end)

  -- Both cost 3s of balance: the card takes the swing's slot, never both.
  it("replaces the bop on its round; the equilibrium joke still rides", function()
    reset(); mnemApostatic = true; ataxiaBasher.jesterPriestess = true
    mnemToughCrowd = true; denizens = 3
    local cmd = ataxiaBasher_jesterBashing()
    expect(has(cmd, "fling priestess at 7")).toBeTrue()
    expect(has(cmd, "badjoke")).toBeTrue()
    expect(has(cmd, "bop 7")).toBeFalse()
    -- next round, card on cooldown: the bop is back
    clock = clock + 3
    expect(has(ataxiaBasher_jesterBashing(), "bop 7")).toBeTrue()
  end)
end)

describe("Motley Bop -- keep bopping in a crowd", function()
  it("healthy target: bop either way", function()
    reset()
    expect(ataxiaBasher_jesterAttack(80)).toBe("bop ")
  end)

  it("no boon: gallowshumour below 50%", function()
    reset(); denizens = 3
    expect(ataxiaBasher_jesterAttack(40)).toBe("gallowshumour ")
  end)

  it("boon + crowd: bop below 50% for the splash", function()
    reset(); mnemMotleyBop = true; denizens = 2
    expect(ataxiaBasher_jesterAttack(40)).toBe("bop ")
  end)

  it("boon alone: the execute bonus still wins", function()
    reset(); mnemMotleyBop = true; denizens = 1
    expect(ataxiaBasher_jesterAttack(40)).toBe("gallowshumour ")
  end)

  it("drives the assembled round", function()
    reset(); mnemMotleyBop = true; denizens = 3
    gmcp.IRE.Target.Info.hpperc = "20%"
    expect(has(ataxiaBasher_jesterBashing(), "bop 7")).toBeTrue()
    denizens = 1
    expect(has(ataxiaBasher_jesterBashing(), "gallowshumour 7")).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
mnemToughCrowd, mnemElusiveFoolery, mnemApostatic = false, false, false
mnemMotleyBop = false
target = nil
