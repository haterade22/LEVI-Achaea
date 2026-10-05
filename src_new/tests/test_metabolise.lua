--- test_metabolise.lua -- METABOLISE PARALYSIS on every defup (v4.7.380)
--
-- User: "We need to add this into our defence list for all. We should do it against paralysis."
-- METABOLISE is not a defence (DEF does not list it), so SSC cannot keep it: defup sends it.

local mock = require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

local realEpoch, realSend, realEcho = getEpoch, send, ataxiaEcho
local NOW = 200000
getEpoch = function() return NOW end
local sent = {}
send = function(c) sent[#sent + 1] = c end
ataxiaEcho = function() end
local realIsDef, realCheck = isDefenceForCurrentClass, checkSSCErrors
ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxiaTemp = ataxiaTemp or {}

dofile("src_new/scripts/levi_ataxia/levi/ataxia/deffing/001_Defence_API.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/deffing/002_Deffing_Up.lua")
isDefenceForCurrentClass = function() return true end
checkSSCErrors = function() end

local TRIG = "src_new/triggers/levi_ataxia/for_levi/leviticus/786_Metabolise_Focus.lua"
local LINE = "You begin to focus upon advanced metabolisation of the paralysis affliction."

local function reset()
  sent = {}
  NOW = NOW + 1000
  ataxiaTemp.metaboliseSentAt, ataxiaTemp.metabolised = nil, nil
  ataxia.settings.metaboliseAff = nil
end

local function count(pat)
  local n = 0
  for _, c in ipairs(sent) do if c:find(pat, 1, true) then n = n + 1 end end
  return n
end

describe("metabolise: paralysis on every defup", function()
  it("defaults to paralysis, queued on equilibrium", function()
    reset()
    ataxia_metabolise("test")
    expect(sent[1]).toBe("queue add eq metabolise paralysis")
  end)

  it("every defup profile sends it, whatever class", function()
    reset()
    ataxia.settings.defences = { current = "", defup = { anyprofile = { shield = true } }, keepup = { anyprofile = {} } }
    systemDefup("anyprofile")
    expect(count("metabolise paralysis")).toBe(1)
  end)

  it("login plus defup inside 10s sends it once", function()
    reset()
    ataxia_metabolise("defup")
    NOW = NOW + 5
    ataxia_metabolise("login")
    expect(count("metabolise")).toBe(1)
    NOW = NOW + 10
    ataxia_metabolise("defup")
    expect(count("metabolise")).toBe(2)
  end)

  it("off stops it", function()
    reset()
    ataxia_setMetabolise("off")
    ataxia_metabolise("defup")
    expect(count("metabolise")).toBe(0)
    expect(ataxia_metaboliseAff()).toBeNil()
  end)

  it("a new affliction is stored lower-case and sent at once", function()
    reset()
    ataxia_metabolise("defup")
    ataxia_setMetabolise("Impatience")
    expect(ataxia.settings.metaboliseAff).toBe("impatience")
    expect(sent[#sent]).toBe("queue add eq metabolise impatience")
  end)

  it("the game's focus line matches and records the confirmation", function()
    reset()
    local pats = TL.patterns(TRIG)
    expect(TL.anyMatches(pats, LINE)).toBe(true)
    matches = { LINE, "paralysis" }
    dofile(TRIG)
    expect(ataxiaTemp.metabolised).toBe("paralysis")
  end)
end)

getEpoch, send, ataxiaEcho = realEpoch, realSend, realEcho
isDefenceForCurrentClass, checkSSCErrors = realIsDef, realCheck
ataxia.settings.metaboliseAff, ataxia.settings.defences = nil, nil
