--- test_permanent_boon_affs.lua -- a boon's permanent affliction is not a reason to cure (v4.7.495)
--
-- The user, 2026-11-13, with Sprightly ("Your dexterity is increased by 5, but you suffer permanent
-- clumsiness."): "When we take boons that give permanent afflictions we are not immune from the
-- system needs to account for that" and "We dont need to tree or use actives if we have this
-- affliction on us". The live prompt was `[ [ IMP clu PAR ]]`, and the system printed
-- "[CURE] 3 afflictions: shrugging" with the permanent clumsiness counted as one of the 3.
--
-- These tests load the real mnemosyne parser and history (mnemosyne/004, 007), the real affed and
-- gotAff (004_Aff_gains_losses), the real class cure (can(x)/003), the real tree pool (cut from
-- affliction_tracking_core/008) and the real FIRE_SCALD trigger. Every global this file sets is put
-- back at the end, because all test files share one Lua state.

local mock = require("mock_mudlet")

local SAVED = {}
local function setGlobal(name, value)
  if SAVED[name] == nil then SAVED[name] = { v = _G[name] } end
  _G[name] = value
end

local clock = 1000
setGlobal("getEpoch", function() return clock end)
table.contains = table.contains or function(t, val)
  for _, v in pairs(t) do if v == val then return true end end
  return false
end

-- The mnemosyne client needs these; nothing here sends a report.
setGlobal("yajl", { to_string = function() return "JSON" end, to_value = function() return nil end })
setGlobal("postHTTP", function() end)
setGlobal("getHTTP", function() end)

-- 004_Aff_gains_losses's dependencies, as test_afflictions.lua stubs them.
setGlobal("Algedonic", {
  ApplySwaps = function() end, RestoreSwaps = function() end, Prioritize = function() end,
  Stack_My_Affs = function() end, Count_My_Affs = function() return 0 end, AffCount = 0,
})
for name, fn in pairs({
  ataxiaNDB_getClass = function() return "" end,
  ataxia_lockBreak = function() end,
  ataxia_boxEcho = function() end,
  ataxia_isClass = function() return false end,
  ataxia_tryVultureTalon = function() end,
  ataxia_facingClass = function() return "" end,
  ataxia_sendCuringPriority = function() end,
  retardationOn = function() end,
  retardationOff = function() end,
  getdirectionn = function() end,
  expandAlias = function() end,
  ataxiaEcho = function() end,
}) do setGlobal(name, fn) end
for _, name in ipairs({ "zgui", "mnemRimewrought", "attemptedLockBreak", "attemptedPreLock" }) do
  setGlobal(name, nil)
end
setGlobal("random_direction", "north")
setGlobal("myaeon", false)

setGlobal("ataxia", { settings = { separator = ";" }, vitals = {}, afflictions = {}, defences = {} })
setGlobal("ataxiaBasher", { enabled = true, treeblackout = true })
setGlobal("ataxiaTemp", {})
setGlobal("ataxiaTables", {})
setGlobal("gmcp", {
  Room = { Info = { area = "" } },
  Char = {
    Status = { class = "Serpent" },
    Afflictions = { Add = { name = "" }, Remove = { "" }, List = {} },
  },
})

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/001_HTTP_Client.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/002_Reporter_API.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/003_Commands.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/004_Parsers.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/005_Ripple_Map.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/007_History.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/004_Aff_gains_losses.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/can(x)/003_Lock_breakers.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- The real pool, cut out of 008: the rest of that file needs the whole tracker.
do
  local fh = assert(io.open("src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua", "r"))
  local src = fh:read("*a")
  fh:close()
  setGlobal("treeCurableAffsV3", nil)
  assert(loadstring(assert(src:match("(treeCurableAffsV3 = %b{})"))))()
end

local M = ataxia.mnemosyne

-- The live descriptions, from 010_Boon_Seed.
local DESC = {
  Sprightly = "Your dexterity is increased by 5, but you suffer permanent clumsiness.",
  Poindexter = "Your intelligence is increased by 5, but you suffer permanent dizziness.",
  ["Sure-Footed"] = "You are immune to the dizziness affliction.",
  ["Corrupted Cold"] = "Your cold resistance is increased by 66%, but you suffer permanent dehydration and tenderskin.",
}

local function claim(name, run, withDesc)
  return { run = run or 7, ripple = 1, name = name, rarity = "", echoes = 1,
           description = (withDesc ~= false) and DESC[name] or nil }
end

local function reset(claims, class, affs, run)
  mock.reset()
  clock = clock + 100
  ataxia.settings = { separator = ";", reporting = { enabled = false, quiet = false } }
  ataxia.vitals = { bal = true, eq = true, mp = 5000, hpp = 100 }
  ataxia.afflictions = affs or {}
  ataxiaTemp = { class = class or "Serpent" }
  ataxiaTables = {}
  ataxiaBasher.enabled = true
  ataxiaBasher.treeblackout = true
  ataxiaBasher.inMnemosyne = true
  attemptedLockBreak = nil
  gmcp.Char.Status.class = class or "Serpent"
  M.history = M.history or {}
  M.history.run = run or 7
  M.history.claims = claims or {}
  M.history.boonLibrary = M.history.boonLibrary or {}
  M._boonLibGen = (M._boonLibGen or 0) + 1 -- a new cache key for every scenario
end

local function sentText()
  return table.concat(mock.sent_commands, ";")
end

local function echoes(find)
  local n = 0
  for _, line in ipairs(mock.echoed_lines) do
    if line:find(find, 1, true) then n = n + 1 end
  end
  return n
end

-- ─── the parser ─────────────────────────────────────────────────────────────

describe("M._permanentAffsFrom -- what a boon makes permanent", function()
  local function parse(desc) return table.concat(M._permanentAffsFrom(desc), ",") end

  it("reads one affliction after 'permanent'", function()
    expect(parse(DESC.Sprightly)).toBe("clumsiness")
    expect(parse(DESC.Poindexter)).toBe("dizziness")
  end)

  it("reads a list joined by 'and'", function()
    expect(parse(DESC["Corrupted Cold"])).toBe("dehydration,tenderskin")
  end)

  it("stops at the comma: Rose of Pain is hallucinations only", function()
    expect(parse("Your intelligence is increased by 3, and your equilibrium recovers 15% faster, but you suffer "
      .. "from permanent hallucinations, and your fire resistance is reduced by 20%.")).toBe("hallucinations")
  end)

  it("reads 'from permanent' (Trainwreck)", function()
    expect(parse("You gain 2% bonus damage for each point of strength, intelligence and dexterity you have, "
      .. "but you suffer from permanent stuttering.")).toBe("stuttering")
  end)

  it("reads nothing where 'permanent' names no affliction", function()
    for _, desc in ipairs({
      "Your rajamalan heritage grants you a permanent balancing defense.",                 -- Feline Grace
      "Extispicy is now permanent and grants an additional 2% critical strike chance.",   -- Rat Catcher
      "Your Dawnhand defence is now permanent and will always function as if it is dawn.", -- Sword of Creation
      "Your epitaph is permanently at the maximum speed.",                                 -- Deathmage
      "Your woeful recitation of Seleucar now lasts permanently and you deal 10% additional damage while affected.",
      "While wading, all of your skills are permanently transcendent.",                    -- Prodigy
    }) do
      expect(parse(desc)).toBe("")
    end
  end)

  it("reads nothing from a cost that is not permanent (Sohtanate's Suffering: stupidity still cures)", function()
    expect(parse("Focusing your mind cures an additional mental affliction, but all stupidity you labour under "
      .. "shall be muddled further.")).toBe("")
  end)

  it("returns an empty list for nil or empty text", function()
    expect(#M._permanentAffsFrom(nil)).toBe(0)
    expect(#M._permanentAffsFrom("")).toBe(0)
  end)
end)

-- ─── this run's permanent afflictions ────────────────────────────────────────

describe("M.runPermanentAffs and ataxia_permanentAff -- this run only, less our immunities", function()
  it("names the boon for each permanent affliction of this run", function()
    reset({ claim("Sprightly"), claim("Corrupted Cold") })
    local map = M.runPermanentAffs()
    expect(map.clumsiness).toBe("Sprightly")
    expect(map.dehydration).toBe("Corrupted Cold")
    expect(map.tenderskin).toBe("Corrupted Cold")
    expect(ataxia_permanentAff("clumsiness")).toBe("Sprightly")
    expect(ataxia_permanentAff("Clumsiness")).toBe("Sprightly")
    expect(ataxia_permanentAff("paralysis")).toBeNil()
  end)

  it("drops a cost that a held boon makes us immune to: Poindexter with Sure-Footed costs nothing", function()
    reset({ claim("Sprightly"), claim("Poindexter"), claim("Sure-Footed") })
    local map = M.runPermanentAffs()
    expect(map.clumsiness).toBe("Sprightly")
    expect(map.dizziness).toBeNil()
  end)

  it("ignores a claim from an earlier run", function()
    reset({ claim("Sprightly", 6) })
    expect(ataxia_permanentAff("clumsiness")).toBeNil()
  end)

  it("reads the description from the library when the claim has none, by the base name", function()
    reset({ claim("(ECHO) Sprightly", 7, false) })
    M.history.boonLibrary.Sprightly = { description = DESC.Sprightly }
    expect(ataxia_permanentAff("clumsiness")).toBe("Sprightly")
    M.history.boonLibrary.Sprightly = nil
  end)

  it("is nil outside the tower: boons end with the run", function()
    reset({ claim("Sprightly") })
    ataxiaBasher.inMnemosyne = false
    expect(ataxia_permanentAff("clumsiness")).toBeNil()
  end)

  it("says each new one once per run, and not under mnem quiet", function()
    -- Runs of their own: the echo remembers what it said in a run.
    reset({ claim("Sprightly", 51) }, nil, nil, 51)
    M.runPermanentAffs()
    M.runPermanentAffs()
    expect(echoes("permanent <yellow>clumsiness")).toBe(1)
    table.insert(M.history.claims, claim("Corrupted Cold", 51))
    M.runPermanentAffs()
    expect(echoes("permanent <yellow>clumsiness")).toBe(1)
    expect(echoes("permanent <yellow>dehydration")).toBe(1)

    reset({ claim("Sprightly", 52) }, nil, nil, 52)
    ataxia.settings.reporting.quiet = true
    M.runPermanentAffs()
    expect(echoes("permanent")).toBe(0)
  end)
end)

-- ─── the class cure ─────────────────────────────────────────────────────────

describe("the class cure does not count a permanent affliction", function()
  local BOARD = { impatience = true, clumsiness = true, paralysis = true } -- the user's prompt

  it("the user's board under Sprightly counts 2, and no shrugging is sent", function()
    reset({ claim("Sprightly") }, "Serpent", BOARD)
    expect(ataxia_randomCurableCount()).toBe(2)
    expect(ataxia_loadCureCommand()).toBeNil()
    expect(ataxia_loadCureReady()).toBeNil()
  end)

  it("without the boon the same board counts 3 and shrugs, as before", function()
    reset({}, "Serpent", BOARD)
    expect(ataxia_randomCurableCount()).toBe(3)
    expect(ataxia_loadCureCommand()).toBe("shrugging")
  end)

  it("outside the tower the same board counts 3: the claim list is the last run's", function()
    reset({ claim("Sprightly") }, "Serpent", BOARD)
    ataxiaBasher.inMnemosyne = false
    expect(ataxia_randomCurableCount()).toBe(3)
  end)

  it("a third curable affliction still shrugs under Sprightly", function()
    reset({ claim("Sprightly") }, "Serpent",
      { impatience = true, clumsiness = true, paralysis = true, nausea = true })
    expect(ataxia_randomCurableCount()).toBe(3)
    expect(ataxia_loadCureCommand()).toBe("shrugging")
  end)

  it("FITNESS does not go for a permanent asthma", function()
    reset({ { run = 7, name = "Wheezy", description = "You are faster, but you suffer permanent asthma." } },
      "Monk", { asthma = true, nausea = true, paralysis = true, impatience = true })
    expect(ataxia_curableAffed("asthma")).toBeFalse()
    expect(ataxia_loadCureCommand()).toBeNil()
    mock.sent_commands = {}
    ataxia_tryActiveCure()
    expect(sentText()).toBe("")
  end)
end)

-- ─── the blackout tree ──────────────────────────────────────────────────────

describe("the blackout tree skips when only permanent afflictions could be taken", function()
  local function blackout(affs)
    ataxia.afflictions = affs
    gmcp.Char.Afflictions.Add = { name = "blackout" }
    mock.sent_commands = {}
    gotAff()
    return sentText()
  end

  it("ataxia_treeOnlyPermanent is true for blackout + Sprightly's clumsiness only", function()
    reset({ claim("Sprightly") })
    ataxia.afflictions = { blackout = true, clumsiness = true }
    expect(ataxia_treeOnlyPermanent()).toBeTrue()
    ataxia.afflictions = { blackout = true, clumsiness = true, sensitivity = true }
    expect(ataxia_treeOnlyPermanent()).toBeFalse()
    ataxia.afflictions = { blackout = true }
    expect(ataxia_treeOnlyPermanent()).toBeFalse()
  end)

  it("no touch tree with blackout + Sprightly's clumsiness (the live 'unchanged' case)", function()
    reset({ claim("Sprightly") })
    expect(blackout({ clumsiness = true }):find("touch tree", 1, true)).toBeNil()
  end)

  it("touches the tree with another curable affliction up", function()
    reset({ claim("Sprightly") })
    expect(blackout({ clumsiness = true, sensitivity = true }):find("touch tree", 1, true) ~= nil).toBeTrue()
  end)

  it("touches the tree without the boon, as before", function()
    reset({})
    expect(blackout({ clumsiness = true }):find("touch tree", 1, true) ~= nil).toBeTrue()
  end)

  it("FIRE SCALD skips the tree the same way", function()
    local trig = "src_new/triggers/levi_ataxia/for_levi/leviticus/unknown_checks/005_FIRE_SCALD.lua"
    reset({ claim("Sprightly") })
    ataxia.afflictions = { blackout = true, clumsiness = true }
    mock.sent_commands = {}
    dofile(trig)
    expect(sentText():find("touch tree", 1, true)).toBeNil()

    reset({ claim("Sprightly") })
    ataxia.afflictions = { blackout = true, clumsiness = true, sensitivity = true }
    mock.sent_commands = {}
    dofile(trig)
    expect(sentText():find("touch tree", 1, true) ~= nil).toBeTrue()
  end)
end)

-- ─── put the shared state back ──────────────────────────────────────────────

for name, rec in pairs(SAVED) do _G[name] = rec.v end
