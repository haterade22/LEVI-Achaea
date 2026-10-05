--- test_shikudo_sr_epitome.lua -- v4.7.382 fixes from one error dump.
-- (1) shikudo_checkForms threw `attempt to compare number with nil` on the first prompt: the vitals
--     update calls it while still reading the Form charstat, before Kata is parsed.
-- (2) The Epitome trigger used `epitomiser`, which nothing ever assigned; its duplicate is disabled.
-- (3) `sr` as a Monk named no owner: `shikudolock()` is a global defined by two scripts.
-- (4) The kuro affliction trigger matches the user's pasted lines and records weariness, then lethargy.

require("mock_mudlet")

local ROOT = "src_new/"
local EXTRAS = ROOT .. "scripts/levi_ataxia/levi/ataxia/monk/003_Shikudo_Extras.lua"
local EPITOME = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/703_Epitome.lua"
local EPITOME_DUP = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/314_Epitome.lua"
local SR = ROOT .. "aliases/levi_ataxia/for_levi/levi_062424/154_Group_(All_Classes).lua"
local KURO = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/573_2Kuro_(weariness_lethargy).lua"

local function read(p) local f = assert(io.open(p)); local s = f:read("*a"); f:close(); return s end

local savedSend, savedCecho, savedEcho = send, cecho, ataxiaEcho
local sent, echoed = {}, {}
send = function(c) sent[#sent + 1] = c end
cecho = function(s) echoed[#echoed + 1] = s end
ataxiaEcho = function(s) echoed[#echoed + 1] = s end
local function clear() sent, echoed = {}, {} end

describe("shikudo_checkForms -- nil kata/form (v4.7.382)", function()
  ataxia = ataxia or {}
  ataxia.vitals = {}
  dofile(EXTRAS)

  it("does not throw when Form is read before Kata", function()
    ataxia.vitals = { form = "Rain" }
    expect(pcall(shikudo_checkForms)).toBeTrue()
  end)

  it("does not throw with no form at all", function()
    ataxia.vitals = { kata = 7 }
    expect(pcall(shikudo_checkForms)).toBeTrue()
  end)

  it("still prints the next forms when kata is known", function()
    clear()
    ataxia.vitals = { form = "Rain", kata = 8 }
    shikudo_checkForms()
    expect(#echoed).toBe(1)
  end)
end)

describe("Epitome trigger (v4.7.382)", function()
  it("names the epitomiser and tells the party exactly once", function()
    clear()
    ataxiaTemp = {}
    function ataxia_boxEcho() end
    function selectString() end
    function fg() end
    function setBold() end
    function resetFormat() end
    line = "Bob moves with the grace of the wind, his stance the epitome of perfection beneath the flurry of blows."
    matches = { line, "Bob" }
    local ok, err = pcall(dofile, EPITOME)
    expect(ok).toBeTrue()
    if not ok then print(err) end
    expect(#sent).toBe(1)
    expect(sent[1]:find("pt Bob used EPITOMISE", 1, true) ~= nil).toBeTrue()
  end)

  it("the duplicate trigger on the same line is disabled", function()
    expect(read(EPITOME_DUP):find("isActive: 'no'", 1, true) ~= nil).toBeTrue()
  end)
end)

describe("sr as a Monk (v4.7.382)", function()
  local routed
  local function setup(form)
    routed = nil
    gmcp = { Char = { Status = { class = "Monk" } } }
    ataxia.vitals = { form = form }
    shikudoLock = { dispatch = function() routed = "007" end }
    shikudolock = function() routed = "global" end
  end

  it("routes a Shikudo monk to the 007 lock by name, not the shared global", function()
    setup("Rain")
    dofile(SR)
    expect(routed).toBe("007")
  end)

  it("a Tekura monk (no form) fires no staff lock", function()
    setup(nil)
    clear()
    dofile(SR)
    expect(routed).toBeNil()
    expect(#echoed).toBe(1)
  end)
end)

describe("kuro affliction trigger matches the live lines", function()
  -- The patterns themselves were checked against these exact lines with Python re (no rex in the mock).
  local strike = "Falling back into a low crouch, you lash out with a swift strike at the right thigh of Tabethys."
  local crunch = "As your blow lands with a crunch, you perceive that you have dealt 9.2% damage to Tabethys's right leg."

  it("records weariness, then lethargy on the second kuro", function()
    local applied = {}
    local have = {}
    function isTargeted(n) return n == "Tabethys" end
    function erAff() end
    function haveAff(a) return have[a] end
    function tarAffed(a) applied[#applied + 1] = a; have[a] = true end
    function moveCursor() end
    function moveCursorEnd() end
    function getLineNumber() return 1 end
    partyrelay = false
    target = "Tabethys"
    ataxiaTables = { limbData = {} }
    multimatches = { { strike, "Tabethys" }, { "1" }, { crunch, "9.2", "Tabethys", "right leg" } }
    dofile(KURO)
    dofile(KURO)
    expect(applied[1]).toBe("weariness")
    expect(applied[2]).toBe("lethargy")
  end)
end)

send, cecho, ataxiaEcho = savedSend, savedCecho, savedEcho
