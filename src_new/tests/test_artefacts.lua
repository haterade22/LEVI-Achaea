--- test_artefacts.lua -- our artefact powers from ARTEFACT POWER LIST OWNED (v4.7.494)
--
-- A player's report: our docs and logic did not count the artefacts we own (the Aldar Diadem: 15%
-- faster equilibrium). misc_scripts/033 reads the game's list, saves it, and answers what an
-- artefact changes. These tests read the list the user pasted (kb/raw/live/), so the parser meets
-- the game's real rows, cut names and all. Globals are restored at the end.

require("mock_mudlet")

local saved = {}
local NAMES = { "ataxia_saveSettings", "ataxiaEcho", "tempTimer", "getEpoch", "send", "itemCatalog",
  "ataxia_hasTrait", "ataxiaBasher", "curseCharge", "swiftcursing" }
for _, k in ipairs(NAMES) do
  saved[k] = _G[k]
end
local savedSettings = ataxia and ataxia.settings and ataxia.settings.artefacts
local savedVitals = ataxia and ataxia.vitals

local clock, saves, sent, echoes = 1000, 0, {}, {}
getEpoch = function() return clock end
ataxia_saveSettings = function() saves = saves + 1 end
ataxiaEcho = function(m) echoes[#echoes + 1] = m end
tempTimer = function() return 1 end
send = function(c) sent[#sent + 1] = c end
itemCatalog = nil
ataxia_hasTrait = nil

dofile("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/033_Artefacts.lua")

local function rawRows()
  local f = assert(io.open("kb/raw/live/artefact_power_list_owned_2026-11-13.txt", "r"))
  local rows, inTable = {}, false
  for l in f:lines() do
    if l:find("^Item ID") then inTable = true
    elseif inTable and l:find("^%d") then rows[#rows + 1] = l end
  end
  f:close()
  return rows
end

local function reset()
  ataxia.settings.artefacts = nil
  ataxia.vitals = nil
  itemCatalog = nil
  ataxia_hasTrait = nil
  ataxiaTemp.artefactRead = nil
  saves, sent, echoes = 0, {}, {}
end

local ok, err = pcall(function()
describe("artefacts: reading ARTEFACT POWER LIST OWNED", function()
  it("reads every row of the pasted list", function()
    local rows = rawRows()
    expect(#rows).toBe(74)
    local powers, n = ataxia_artefactsFromLines(rows)
    expect(n).toBe(74)
    expect(powers.faster_eq.id).toBe(385702)
    expect(powers.faster_eq.level).toBe(2)
    expect(powers.swiftcurse.level).toBe(3)
    expect(powers.enhanced_shin.level).toBeNil()
  end)

  it("reads a row whose name runs into the power with one space", function()
    local id, name, power, level =
      ataxia_parseArtefactPowerRow("442098        a gem of haematite with elemental f rapid_resonation       -")
    expect(id).toBe(442098)
    expect(name).toBe("a gem of haematite with elemental f")
    expect(power).toBe("rapid_resonation")
    expect(level).toBeNil()
  end)

  it("skips the header, the dashed rules and other lines", function()
    expect(ataxia_parseArtefactPowerRow("Item ID       Item Name                           Power                Level ")).toBeNil()
    expect(ataxia_parseArtefactPowerRow(string.rep("-", 79))).toBeNil()
    expect(ataxia_parseArtefactPowerRow("12:34:32:940 [15352] [97] |(340034)|[]  ")).toBeNil()
    expect(ataxia_parseArtefactPowerRow("")).toBeNil()
  end)

  it("gives a cut power its full name when one we know starts with it", function()
    reset()
    itemCatalog = { kb = { x = { power = "class_switch_reduction" } }, items = {} }
    local _, _, power = ataxia_parseArtefactPowerRow(
      "212547        a stone of the lesser lorewarden    class_switch_reducti   3")
    expect(power).toBe("class_switch_reduction")
    itemCatalog = nil
    expect(ataxia_artefactPowerKey("class_switch_reducti")).toBe("class_switch_reducti")
  end)
end)

describe("artefacts: the header opens a window, rows inside it are saved", function()
  it("saves the rows that follow the header", function()
    reset()
    ataxia_artefactHeader()
    ataxia_artefactRow("385702        an Aldar Diadem                     faster_eq              2")
    clock = clock + 0.1
    ataxia_artefactRow("630835        a sapphire skull pendant            swiftcurse             3")
    expect(ataxia_artefactsKnown()).toBeTrue()
    expect(ataxia.settings.artefacts.powers.faster_eq.level).toBe(2)
    expect(ataxia.settings.artefacts.count).toBe(2)
    expect(saves > 0).toBeTrue()
  end)

  it("ignores a row with no header before it, or after the window", function()
    reset()
    ataxia_artefactRow("385702        an Aldar Diadem                     faster_eq              2")
    expect(ataxia_artefactsKnown()).toBeFalse()
    ataxia_artefactHeader()
    clock = clock + 11
    ataxia_artefactRow("385702        an Aldar Diadem                     faster_eq              2")
    expect(ataxia_artefactsKnown()).toBeFalse()
  end)

  it("a new list replaces the old one", function()
    reset()
    ataxia_artefactsStore({ faster_eq = { id = 1, name = "a", level = 2 } }, 1)
    ataxia_artefactHeader()
    ataxia_artefactRow("630835        a sapphire skull pendant            swiftcurse             3")
    expect(ataxia_artefact("faster_eq")).toBeNil()
    expect(ataxia_artefact("swiftcurse").level).toBe(3)
  end)
end)

describe("artefacts: what a power changes", function()
  it("the Aldar Diadem makes equilibrium x0.85, and Rain x0.85 more", function()
    reset()
    ataxia_artefactsStore(ataxia_artefactsFromLines(rawRows()))
    local f, why = ataxia_eqFactor("Oak")
    expect(math.abs(f - 0.85) < 1e-9).toBeTrue()
    expect(why).toContain("Aldar Diadem")
    local r = ataxia_eqFactor("Willows in Rain Storm")
    expect(math.abs(r - 0.7225) < 1e-9).toBeTrue()
    expect(math.abs(ataxia_eqSeconds(4.00, "Oak") - 3.40) < 1e-9).toBeTrue()
  end)

  it("reads our form from GMCP when none is given", function()
    reset()
    ataxia_artefactsStore({ faster_eq = { id = 1, name = "d", level = 2 } }, 1)
    ataxia.vitals = { form = "Rain" }
    expect(math.abs(ataxia_eqFactor() - 0.7225) < 1e-9).toBeTrue()
  end)

  it("a level-1 circlet is 7%", function()
    reset()
    ataxia_artefactsStore({ faster_eq = { id = 1, name = "a Circlet of the Wise", level = 1 } }, 1)
    expect(math.abs(ataxia_eqFactor("Oak") - 0.93) < 1e-9).toBeTrue()
  end)

  it("no artefact: factor 1", function()
    reset()
    ataxia_artefactsStore({}, 0)
    local f, why = ataxia_eqFactor("Oak")
    expect(f).toBe(1)
    expect(why).toBe("no equilibrium artefact")
  end)

  it("quick-witted is named but not counted (its size is unknown)", function()
    reset()
    ataxia_artefactsStore({}, 0)
    ataxia_hasTrait = function(t) return t == "quick-witted" end
    local f, why = ataxia_eqFactor("Oak")
    expect(f).toBe(1)
    expect(why).toContain("quick-witted")
  end)

  it("sizes per level: the sapphire skull pendant adds 6 curses", function()
    reset()
    ataxia_artefactsStore(ataxia_artefactsFromLines(rawRows()))
    expect(ataxia_artefactSize("swiftcurse", "add", 0)).toBe(6)
    expect(ataxia_artefactSize("hand_to_hand", "pct", 0)).toBe(35)
    ataxia_artefactsStore({}, 0)
    expect(ataxia_artefactSize("swiftcurse", "add", 0)).toBe(0)
  end)
end)

describe("artefacts: the user's switch", function()
  it("off hides an owned power, auto brings it back", function()
    reset()
    ataxia_artefactsStore({ faster_eq = { id = 1, name = "d", level = 2 } }, 1)
    ataxia_artefactCommand("faster_eq off")
    expect(ataxia_artefact("faster_eq")).toBeNil()
    expect(ataxia_eqFactor("Oak")).toBe(1)
    ataxia_artefactCommand("faster_eq auto")
    expect(ataxia_artefact("faster_eq").level).toBe(2)
  end)

  it("on gives a power we do not own, with a level", function()
    reset()
    ataxia_artefactsStore({}, 0)
    ataxia_artefactCommand("faster_eq on 1")
    expect(ataxia_artefact("faster_eq").level).toBe(1)
    expect(math.abs(ataxia_eqFactor("Oak") - 0.93) < 1e-9).toBeTrue()
  end)

  it("scan sends the list command", function()
    reset()
    ataxia_artefactCommand("scan")
    expect(sent[1]).toBe("artefact power list owned")
  end)

  it("login asks once, only while nothing is saved", function()
    reset()
    local asked = 0
    tempTimer = function() asked = asked + 1 end
    ataxia_artefactLogin()
    ataxia_artefactsStore({}, 0)
    ataxia_artefactLogin()
    tempTimer = function() return 1 end
    expect(asked).toBe(1)
  end)
end)

describe("artefacts: the Shaman swiftcurse stand-in (trigger shaman/011)", function()
  local function body(p)
    local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close()
    return assert(loadstring(s:match("%]%]%-%-\r?\n(.*)$"), p))
  end
  local UP = body("src_new/triggers/levi_ataxia/for_levi/leviticus/shaman/011_Swiftcurse_Up.lua")

  it("ten curses plus a sapphire skull pendant's six", function()
    reset()
    ataxiaBasher = { enabled = false }
    ataxia_artefactsStore(ataxia_artefactsFromLines(rawRows()))
    UP()
    expect(curseCharge).toBe(16)
  end)

  it("ten with no pendant", function()
    reset()
    ataxiaBasher = { enabled = false }
    ataxia_artefactsStore({}, 0)
    UP()
    expect(curseCharge).toBe(10)
  end)
end)

describe("artefacts: never scanned, the item catalog stands in", function()
  it("reads the diadem from a catalog entry keyed to the KB", function()
    reset()
    itemCatalog = {
      items = { [385702] = { name = "an Aldar Diadem", kbKey = "aldar diadem" } },
      kb = { ["aldar diadem"] = { power = "faster_eq", tier = 2 } },
    }
    local a = ataxia_artefact("faster_eq")
    expect(a.level).toBe(2)
    expect(a.from).toBe("catalog")
    expect(math.abs(ataxia_eqFactor("Oak") - 0.85) < 1e-9).toBeTrue()
  end)

  it("nothing at all: no artefact", function()
    reset()
    expect(ataxia_artefact("faster_eq")).toBeNil()
    expect(ataxia_artefactLevel("faster_eq")).toBe(0)
  end)
end)
end)

-- restore
ataxia.settings.artefacts = savedSettings
ataxia.vitals = savedVitals
ataxiaTemp.artefactRead = nil
for _, k in ipairs(NAMES) do _G[k] = saved[k] end -- a name that was nil goes back to nil
if not ok then error(err) end
