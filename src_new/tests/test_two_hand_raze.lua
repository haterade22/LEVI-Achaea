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

gmcp, target, ataxiaTemp, ataxiaBasher = _saved.gmcp, _saved.target, _saved.ataxiaTemp or {}, _saved.ataxiaBasher
ataxiaBasher_attack, getEpoch = _saved.ataxiaBasher_attack, _saved.getEpoch
mock.reset()
