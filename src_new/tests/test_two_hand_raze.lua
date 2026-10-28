--- test_two_hand_raze.lua -- Two Handed shield break follows the wielded weapon (v4.7.452)
--
-- User: "When in 2 handed, if I am wielding a bastard sword it should carve, warhammer splinter."
-- Loads the real basher/015_Two_Hand_Raze.lua. Files share ONE Lua state: what is touched here is
-- saved at the top and restored at the end.

local mock = require("mock_mudlet")

local _saved = {
  gmcp = gmcp, target = target, ataxiaTemp = ataxiaTemp, ataxiaBasher = ataxiaBasher,
  ataxiaBasher_attack = ataxiaBasher_attack, getEpoch = getEpoch,
}

mock.reset()
ataxiaTemp = {}
dofile("src_new/scripts/levi_ataxia/levi/ataxia/basher/015_Two_Hand_Raze.lua")

local attacks, NOW = 0, 1000
local function reset()
  ataxiaTemp = {}
  mock.sent_commands = {}
  gmcp = { Char = { Items = {} } }
  ataxiaBasher = { enabled = true }
  target = 12345
  attacks, NOW = 0, 1000
  ataxiaBasher_attack = function() attacks = attacks + 1 end
  getEpoch = function() return NOW end
end

local function invList(items)
  gmcp.Char.Items.List = { location = "inv", items = items }
  raiseEvent("gmcp.Char.Items.List")
end

describe("Two Handed raze follows the wielded weapon", function()
  it("a wielded warhammer splinters", function()
    reset()
    invList({ { id = "1", name = "a steel warhammer", attrib = "lL" } })
    expect(ataxiaBasher_twoHandRaze(123, "carve")).toBe("splinter 123")
  end)

  it("a wielded bastard sword carves", function()
    reset()
    invList({ { id = "2", name = "a steel bastard sword", attrib = "lL" } })
    expect(ataxiaBasher_twoHandRaze(123, "splinter")).toBe("carve 123")
  end)

  it("a carried but unwielded warhammer does not count", function()
    reset()
    invList({ { id = "1", name = "a steel warhammer", attrib = "" },
              { id = "2", name = "a steel bastard sword", attrib = "L" } })
    expect(ataxiaBasher_twoHandRaze(123, "splinter")).toBe("carve 123")
  end)

  it("follows a wield change from Char.Items.Update", function()
    reset()
    invList({ { id = "2", name = "a steel bastard sword", attrib = "lL" },
              { id = "1", name = "a steel warhammer", attrib = "" } })
    gmcp.Char.Items.Update = { location = "inv", item = { id = "2", name = "a steel bastard sword", attrib = "" } }
    raiseEvent("gmcp.Char.Items.Update")
    gmcp.Char.Items.Update = { location = "inv", item = { id = "1", name = "a steel warhammer", attrib = "lL" } }
    raiseEvent("gmcp.Char.Items.Update")
    expect(ataxiaBasher_twoHandRaze(123, "carve")).toBe("splinter 123")
  end)

  it("ignores the room's item list", function()
    reset()
    invList({ { id = "2", name = "a steel bastard sword", attrib = "lL" } })
    gmcp.Char.Items.List = { location = "room", items = { { id = "9", name = "a warhammer", attrib = "l" } } }
    raiseEvent("gmcp.Char.Items.List")
    expect(ataxiaBasher_twoHandRaze(123, "splinter")).toBe("carve 123")
  end)

  it("an unknown weapon keeps the class default and asks GMCP for the inventory once", function()
    reset()
    expect(ataxiaBasher_twoHandRaze(123, "carve")).toBe("carve 123")
    expect(ataxiaBasher_twoHandRaze(123, "splinter")).toBe("splinter 123")
    local asks = 0
    for _, c in ipairs(mock.sent_commands) do if c == "GMCP:Char.Items.Inv" then asks = asks + 1 end end
    expect(asks).toBe(1)
  end)
end)

describe("the splinter refusal teaches 'bastard sword'", function()
  it("switches to carve and re-sends the round", function()
    reset()
    ataxiaBasher_splinterRefused()
    expect(ataxiaBasher_twoHandRaze(123, "splinter")).toBe("carve 123")
    expect(attacks).toBe(1)
  end)

  it("re-sends at most once a second, and never in PvP or while paused", function()
    reset()
    ataxiaBasher_splinterRefused(); ataxiaBasher_splinterRefused()
    expect(attacks).toBe(1)
    reset(); target = "Somebody"
    ataxiaBasher_splinterRefused()
    expect(attacks).toBe(0)
    reset(); ataxiaBasher.paused = true
    ataxiaBasher_splinterRefused()
    expect(attacks).toBe(0)
  end)

  it("a fresh inventory picture outranks the refusal's guess", function()
    reset()
    ataxiaBasher_splinterRefused()
    invList({ { id = "1", name = "a steel warhammer", attrib = "lL" } })
    expect(ataxiaBasher_twoHandRaze(123, "carve")).toBe("splinter 123")
  end)

  it("the trigger's pattern matches the game's line", function()
    local src = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/790_Splinter_Needs_Warhammer.lua"):read("*a")
    expect(src:find("pattern: ^You must be wielding a warhammer to splinter an opponent's defences\\.$", 1, true) ~= nil).toBeTrue()
  end)
end)

-- v4.7.461, the user's log: "a Hellforge Hammer" in hand, CARVE refused three times in a second.
describe("an artefact two-hander and the carve refusal", function()
  it("a wielded Hellforge Hammer splinters", function()
    reset()
    invList({ { id = "77", name = "a Hellforge Hammer", attrib = "lL" } })
    expect(ataxiaBasher_twoHandRaze(123, "carve")).toBe("splinter 123")
  end)

  it("the carve refusal teaches 'warhammer' and re-sends the round", function()
    reset()
    ataxiaBasher_carveRefused()
    expect(ataxiaBasher_twoHandRaze(123, "carve")).toBe("splinter 123")
    expect(attacks).toBe(1)
  end)

  it("wields by the inventory ID, and never a carried one-handed sword", function()
    reset()
    invList({ { id = "77", name = "a Hellforge Hammer", attrib = "lL" },
              { id = "88", name = "a rune-etched longsword", attrib = "" },
              { id = "99", name = "a steel bastard sword", attrib = "" } })
    expect(ataxiaBasher_twoHandWield("bastard", ";")).toBe("wield 99;")
    reset()
    invList({ { id = "88", name = "a rune-etched longsword", attrib = "" },
              { id = "66", name = "a bastard sword", attrib = "lL" } })
    expect(ataxiaBasher_twoHandWield("warhammer", ";")).toBe("wield warhammer;")
    invList({ { id = "77", name = "a Hellforge Hammer", attrib = "" },
              { id = "66", name = "a bastard sword", attrib = "lL" } })
    expect(ataxiaBasher_twoHandWield("warhammer", ";")).toBe("wield 77;")
  end)

  it("with no inventory list since a reload: learns the held ID and asks GMCP once for the rest", function()
    reset()
    local asks, prev = 0, sendGMCP
    sendGMCP = function(m) if m == "Char.Items.Inv" then asks = asks + 1 end end
    ataxiaTemp.wieldedItems = { ["405364"] = "Apocalypse, a blackrock sword of black-hued steel" }
    expect(ataxiaBasher_twoHandWield("warhammer", ";")).toBe("wield warhammer;")
    expect(ataxiaTemp.twoHandIds.bastard).toBe("405364")
    expect(ataxiaTemp.twoHandSeen.bastard).toBe("405364")
    ataxiaBasher_twoHandWield("warhammer", ";")
    expect(asks).toBe(1)                                 -- the 0.3 s rebuilds do not ask again
    NOW = NOW + 31
    ataxiaBasher_twoHandWield("warhammer", ";")
    expect(asks).toBe(2)
    sendGMCP = prev
  end)

  it("finds a named artefact sword by the ID seen wielded, or as the only sword carried", function()
    reset()
    local sword = { id = "55", name = "Apocalypse, a blackrock sword of black-hued steel", attrib = "lL" }
    invList({ sword, { id = "77", name = "a Hellforge Hammer", attrib = "" } })
    expect(ataxiaBasher_twoHandRaze(1, "splinter")).toBe("carve 1")
    sword.attrib = ""
    invList({ sword, { id = "88", name = "a rune-etched longsword", attrib = "" },
              { id = "77", name = "a Hellforge Hammer", attrib = "lL" } })
    expect(ataxiaBasher_twoHandWield("bastard", ";")).toBe("wield 55;")
    reset()
    invList({ sword, { id = "77", name = "a Hellforge Hammer", attrib = "lL" } })
    expect(ataxiaBasher_twoHandWield("bastard", ";")).toBe("wield 55;")
  end)

  it("the trigger's pattern matches the game's line", function()
    local src = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/799_Carve_Needs_Sword.lua"):read("*a")
    expect(src:find("pattern: ^You must be wielding a two handed sword to carve through an opponent's defences\\.$", 1, true) ~= nil).toBeTrue()
  end)
end)

-- v4.7.455: arc/bisect wield the bastard sword; normal rounds pick the weapon by measured DPS.
local function hold(kind)
  ataxiaTemp.wieldedItems = { ["1"] = (kind == "bastard") and "a steel bastard sword" or "a steel warhammer" }
end

describe("the wield prefix", function()
  it("wields the bastard when the warhammer is in hand, and nothing when it is already held", function()
    reset(); hold("warhammer")
    expect(ataxiaBasher_twoHandWield("bastard", ";")).toBe("wield bastard;")
    hold("bastard")
    expect(ataxiaBasher_twoHandWield("bastard", ";")).toBe("")
    -- the hammer was seen in hand above (hold() gives it ID "1"), so it goes back in by ID (v4.7.463)
    expect(ataxiaBasher_twoHandWield("warhammer", ";")).toBe("wield 1;")
  end)

  it("wields when the hand is unknown, and uses the configured keyword", function()
    reset()
    expect(ataxiaBasher_twoHandWield("bastard", ";")).toBe("wield bastard;")
    ataxiaBasher.twoHandSwordWord = "sword123"
    expect(ataxiaBasher_twoHandWield("bastard", ";")).toBe("wield sword123;")
  end)
end)

describe("the DPS ledger", function()
  local function hit(kind, amount, dt)
    hold(kind); NOW = NOW + dt
    ataxiaBasher_twoHandRecord(amount)
  end

  it("records only normal rounds, in PvE, with a known weapon", function()
    reset(); hold("warhammer")
    ataxiaTemp.twoHandRound = "crowd"
    ataxiaBasher_twoHandRecord(500)
    expect(ataxiaBasher.twoHandDps).toBe(nil)
    ataxiaTemp.twoHandRound = "single"; target = "Somebody"
    ataxiaBasher_twoHandRecord(500)
    expect(ataxiaBasher.twoHandDps).toBe(nil)
    target = 12345; ataxiaTemp.wieldedItems = {}
    ataxiaBasher_twoHandRecord(500)
    expect(ataxiaBasher.twoHandDps).toBe(nil)
    hold("warhammer")
    ataxiaBasher_twoHandRecord(500)
    expect(ataxiaBasher.twoHandDps.warhammer.dmg).toBe(500)
  end)

  it("counts a short gap as fighting time, but not a gap across a weapon swap", function()
    reset(); ataxiaTemp.twoHandRound = "single"
    hit("warhammer", 100, 0); hit("warhammer", 100, 2)
    expect(ataxiaBasher.twoHandDps.warhammer.secs).toBe(2)
    hit("bastard", 100, 3)
    expect(ataxiaBasher.twoHandDps.bastard.secs).toBe(0)
    hit("bastard", 100, 20)                     -- longer than the combat gap
    expect(ataxiaBasher.twoHandDps.bastard.secs).toBe(0)
  end)

  it("takes a crit's damage out but keeps its time, and counts it as an average hit", function()
    reset(); ataxiaTemp.twoHandRound = "single"
    local prevStats = bashStats
    bashStats = { lastHitWasCrit = false }
    hit("warhammer", 100, 0); hit("warhammer", 300, 2)
    bashStats.lastHitWasCrit = true
    hit("warhammer", 6400, 2)                   -- a 32x crit
    bashStats.lastHitWasCrit = false
    local l = ataxiaBasher.twoHandDps.warhammer
    expect(l.dmg).toBe(400); expect(l.hits).toBe(2); expect(l.crits).toBe(1); expect(l.secs).toBe(4)
    -- (400 / 2) * 3 hits / 4 s = 150 dps; with the crit counted raw it would be 1700.
    expect(ataxiaBasher_twoHandReport()[1]:find("150 dps", 1, true) ~= nil).toBeTrue()
    bashStats = prevStats
  end)

  it("starts a ledger from v4.7.455 again (its damage included crits)", function()
    reset(); ataxiaTemp.twoHandRound = "single"
    ataxiaBasher.twoHandDps = { warhammer = { dmg = 99999, secs = 50, hits = 10 } }
    hit("warhammer", 100, 0)
    expect(ataxiaBasher.twoHandDps.warhammer.dmg).toBe(100)
  end)
end)

describe("the normal-round pick", function()
  local function set(h, b)
    h.v, b.v = 2, 2
    ataxiaBasher.twoHandDps = { warhammer = h, bastard = b }
  end

  it("samples the weapon with less fighting time first", function()
    reset(); hold("warhammer")
    expect(ataxiaBasher_twoHandPick()).toBe("warhammer")      -- nothing yet: keep the one in hand
    set({ dmg = 1000, secs = 30, hits = 5 }, { dmg = 0, secs = 0, hits = 0 })
    expect(ataxiaBasher_twoHandPick()).toBe("bastard")
  end)

  it("then picks the higher DPS, with a margin before it leaves the weapon in hand", function()
    reset(); hold("warhammer")
    set({ dmg = 120000, secs = 120, hits = 60 }, { dmg = 150000, secs = 120, hits = 40 })
    expect(ataxiaBasher_twoHandPick()).toBe("bastard")
    set({ dmg = 120000, secs = 120, hits = 60 }, { dmg = 122000, secs = 120, hits = 40 })
    expect(ataxiaBasher_twoHandPick()).toBe("warhammer")      -- 1.7% better is noise
    hold("bastard")
    expect(ataxiaBasher_twoHandPick()).toBe("bastard")
  end)

  it("a pinned mode wins", function()
    reset(); hold("warhammer")
    set({ dmg = 999999, secs = 200, hits = 1 }, { dmg = 1, secs = 200, hits = 1 })
    ataxiaBasher.twoHandMode = "bastard"
    expect(ataxiaBasher_twoHandPick()).toBe("bastard")
  end)
end)

-- v4.7.460, user: "bash twohand auto doesnt echo or anything for the player to understand it is working"
describe("the player sees what Two Handed does", function()
  local said
  local prevEcho = ataxiaEcho
  local function capture()
    said = {}
    ataxiaEcho = function(t) said[#said + 1] = t end
  end
  local function has(text)
    for _, t in ipairs(said) do if t:find(text, 1, true) then return true end end
    return false
  end

  it("says the normal-round weapon and why, once, until it changes", function()
    reset(); capture(); hold("warhammer")
    ataxiaBasher_twoHandSay("normal")
    expect(#said).toBe(1)
    expect(has("Normal rounds: <white>warhammer<reset> (sampling, 0/120s)")).toBeTrue()
    ataxiaBasher_twoHandSay("normal")                    -- the 0.3 s rebuild: no repeat
    expect(#said).toBe(1)
    ataxiaBasher_twoHandSay("bisect")
    expect(has("bisect rounds: <white>bastard<reset> (bisect needs the sword), wielding it now")).toBeTrue()
    ataxiaBasher.twoHandMode = "warhammer"
    ataxiaBasher_twoHandSay("normal")
    expect(has("pinned by bash twohand warhammer")).toBeTrue()
    ataxiaEcho = prevEcho
  end)

  it("reports sampling every 30 s and the end of a sample", function()
    reset(); capture(); hold("warhammer"); ataxiaTemp.twoHandRound = "single"
    ataxiaBasher_twoHandRecord(100)
    for _ = 1, 15 do NOW = NOW + 2; ataxiaBasher_twoHandRecord(100) end   -- 30 s
    expect(#said).toBe(1)
    expect(has("sampling <white>warhammer<reset>: 30/120s")).toBeTrue()
    for _ = 1, 45 do NOW = NOW + 2; ataxiaBasher_twoHandRecord(100) end   -- 120 s
    expect(has("<white>warhammer<reset> sampled: <white>51<reset> dps over 120s")).toBeTrue()
    expect(has("Both weapons sampled")).toBeFalse()
    ataxiaEcho = prevEcho
  end)

  it("says once a minute that GMCP shows no two-hander", function()
    reset(); capture(); ataxiaTemp.twoHandRound = "single"
    ataxiaBasher_twoHandRecord(100); ataxiaBasher_twoHandRecord(100)
    expect(#said).toBe(1)
    expect(has("DPS is not measured")).toBeTrue()
    NOW = NOW + 61
    ataxiaBasher_twoHandRecord(100)
    expect(#said).toBe(2)
    ataxiaEcho = prevEcho
  end)
end)

gmcp, target, ataxiaTemp, ataxiaBasher = _saved.gmcp, _saved.target, _saved.ataxiaTemp or {}, _saved.ataxiaBasher
ataxiaBasher_attack, getEpoch = _saved.ataxiaBasher_attack, _saved.getEpoch
mock.reset()
