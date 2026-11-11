--- test_earring_auto.lua -- `ataxia setup earrings auto` saves every partner (2026-11-11)
--
-- The scan kept a partner only if its name was in a fixed list of 9, so 5 of the user's 11
-- earrings were dropped, and the old `axios = earring87118` stayed after 87118 was re-paired
-- with Arador. The travel alias had the same fixed list. These tests load the real script.

require("mock_mudlet")

local SRC = "src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/020_Setup_Wizard.lua"

-- The user's EARRINGS output, 2026-11-11
local LINES = {
  { "87118", "Arador" }, { "244327", "Aegoth" }, { "258959", "Proficy" },
  { "309763", "Mystor" }, { "336805", "Pharaus" }, { "413383", "Cresil" },
  { "428872", "Zylvith" }, { "495017", "Antoninus" }, { "495481", "Agathon" },
  { "497379", "Harkon" }, { "531179", "Tabethys" },
}

local realTempAlias, realKillAlias, realSend = tempAlias, killAlias, send
local aliases, nextAlias, sent = {}, 0, {}
tempAlias = function(pattern, fn)
  nextAlias = nextAlias + 1
  aliases[nextAlias] = { pattern = pattern, fn = fn }
  return nextAlias
end
killAlias = function(id) aliases[id] = nil end
send = function(cmd) sent[#sent + 1] = cmd end
local realEcho = ataxiaEcho
ataxiaEcho = function() end
-- Mudlet supplies utf8 (the wizard's header bar); the mock does not
local realUtf8 = utf8
utf8 = utf8 or { char = function() return "-" end }
local realSave = ataxia_saveSettings
ataxia_saveSettings = function() end

ataxia = ataxia or {}
ataxia.settings = { user = { artefacts = { earrings = {
  -- the old pairing: axios held 87118, entaro was never listed
  axios = "earring87118", aegoth = "earring244327", entaro = "earring1",
} } } }
ataxia.getEarring = function(p) return ataxia.settings.user.artefacts.earrings[p] end

local ok, err = pcall(dofile, SRC)
if not ok then error("failed to load " .. SRC .. ": " .. tostring(err)) end
local S = leviSetup

local function scan()
  S.earringAuto = { triggers = {}, results = {} }
  for _, l in ipairs(LINES) do S.earringRecord(l[1], l[2]) end
  S.earringAutoFinish()
end

local function aliasFor(word)
  for _, a in pairs(aliases) do
    if ("^h" .. word:sub(2) .. "$") == a.pattern then return a end
  end
end

describe("earring auto-config", function()
  it("saves all 11 partners, Cresil (no (M)) too", function()
    scan()
    local e = ataxia.settings.user.artefacts.earrings
    expect(#S.earringPartners(e)).toBe(11)
    expect(e.arador).toBe("earring87118")
    expect(e.cresil).toBe("earring413383")
    expect(e.harkon).toBe("earring497379")
  end)

  it("drops the re-paired and the unlisted entries", function()
    local e = ataxia.settings.user.artefacts.earrings
    expect(e.axios).toBeNil()
    expect(e.entaro).toBeNil()
  end)

  it("reports what it removed and why", function()
    local saved = { axios = "earring87118", entaro = "earring1", aegoth = "earring244327" }
    local removed = S.earringMerge(saved, { arador = "earring87118", aegoth = "earring244327" })
    expect(#removed).toBe(2)
    expect(removed[1].partner).toBe("axios")
    expect(removed[1].now).toBe("arador")
    expect(removed[2].partner).toBe("entaro")
    expect(removed[2].now).toBeNil()
  end)

  it("an empty scan changes nothing", function()
    S.earringAuto = { triggers = {}, results = {} }
    S.earringAutoFinish()
    expect(#S.earringPartners(ataxia.settings.user.artefacts.earrings)).toBe(11)
  end)

  it("makes one travel alias per partner: hara -> arador", function()
    sent = {}
    local a = aliasFor("hara")
    expect(a ~= nil).toBeTrue()
    a.fn()
    expect(sent[1]).toBe("clearqueue all;queue add free travel to arador with earring87118")
    expect(aliasFor("hmys") ~= nil).toBeTrue()
    expect(aliasFor("hcre") ~= nil).toBeTrue()
  end)

  it("makes no alias for other words (help) and none for a shared prefix", function()
    expect(aliasFor("help")).toBeNil()
    ataxia.settings.user.artefacts.earrings.arala = "earring9"
    local made = S.earringAliases()
    expect(made.ara).toBeNil()
    expect(aliasFor("hara")).toBeNil()
    ataxia.settings.user.artefacts.earrings.arala = nil
    S.earringAliases()
  end)

  it("never takes horn, the horn alias", function()
    ataxia.settings.user.artefacts.earrings.ornella = "earring8"
    expect(S.earringAliases().orn).toBeNil()
    ataxia.settings.user.artefacts.earrings.ornella = nil
    S.earringAliases()
  end)

  it("the alias count follows the table (no leftover aliases)", function()
    local n = 0
    for _ in pairs(aliases) do n = n + 1 end
    expect(n).toBe(11)
  end)
end)

tempAlias, killAlias, send = realTempAlias, realKillAlias, realSend
ataxiaEcho, ataxia_saveSettings, utf8 = realEcho, realSave, realUtf8
