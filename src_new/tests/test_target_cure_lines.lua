--- test_target_cure_lines.lua -- target cure and affliction lines, 2026-11-08 deep review (group D)
--
-- F14  A goldenseal eat is charged as V3's random cure on its own line (herbs/002). When the next
--      line names the cure ("Lucidity returns to the eyes of X." -> shadowmadness, third-person
--      _removes/003; "X ceases his violent trembling." -> mycalium, herbs/004), the named erase
--      came ON TOP of the random cure: one eat took two afflictions. ataxia_knownCureV3
--      (ataxia/001_Miscellaneous_Aff_Tracking_Methods) now puts the eat's branches back first.
-- F43  399 (focus, known) repeated 398's work behind tBals.focus, which 398 had already set false,
--      so it never ran: no serpent.trackCure("focus"), and a focus that took lovers was charged as
--      a random cure plus 002_Seduce's lovers erase.
-- F44  herbs/016: "X gives a sigh of relief." follows a cuprum eat that cured retribution; it also
--      erased earworm.
-- F45  herbs/006: an ash eat with our crescendo up zeroed crescendo AND ran the V3 ash cure.
-- F18  394: a sip erased voyria through a second, unguarded block even under Latency.
-- F47  419: the voices line could never match, and nine stupidity lines had no pattern.
-- H2   paAff (party calls, 426/428/436) wrote tAffs without V3; the raw word went to V3 instead.
-- 410  a stand line threw on a missing limb row, so prone and paralysis stayed.
-- 420  lines that GIVE paralysis collapsed the branches as if they showed it. The Magi tracker's
--      copy of the Horror line (magi_offense_tracking/007) added it a second time.
-- F14 siblings: the same known-cure rule for kelp, ginseng and the smoke, and 008 no longer charges
--      a ginseng eat twice more on the flushings line.
-- Proofs: a tree, a focus, a salve and a sileris or quicksilver apply drop the branches they rule
--      out, before anything erases the affliction (proveAffAbsentV3, 007); a known-cure line keeps
--      a smoke's or a focus's proof; herbs/013 no longer reads the salve clock.
--
-- The tests run the REAL trigger bodies through the REAL public API (017), the REAL V3 tracker
-- (007, 008) and the REAL helpers (ataxia/001). Every global the loaded files create or change is
-- restored at the end (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains
local savedStarts = string.starts

-- The V3 files initialise these as `X = X or {...}`. Clear them, so the loads build fresh tables.
for _, k in ipairs({ "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3",
  "affLastConfirmedV3", "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3",
  "negativeConfirmTimersV3", "tAffsV2", "tAffStacksV2" }) do
  _G[k] = nil
end
ataxiaTemp, tAffs, affTimers = {}, {}, {}

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end
local realIsTargeted = isTargeted

-- Mudlet extensions the loaded code uses; restored at the end.
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end
string.starts = string.starts or function(s, p) return s:sub(1, #p) == p end

local TL = dofile("src_new/tests/trigger_lib.lua")
local LEVI = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local PATH = {
  GOLDENSEAL = LEVI .. "herbs/002_Goldenseal_(Madness).lua",
  MYCALIUM = LEVI .. "herbs/004_Goldenseal_(Mycalium).lua",
  KELP = LEVI .. "herbs/003_Kelp_(Unknown).lua",
  GINSENG = LEVI .. "herbs/007_Ginseng.lua",
  FLUSHINGS = LEVI .. "herbs/008_Ginseng_with_Flushings.lua",
  SMOKED = LEVI .. "390_Smoked.lua",
  ASH = LEVI .. "herbs/006_Ash.lua",
  SIGH = LEVI .. "herbs/016_Cured_Earworm.lua",
  LUCIDITY = LEVI .. "third-person_removes/003_Remove_Madness.lua",
  NERVOUS = LEVI .. "third-person_removes/001_Remove_Mycalium.lua",
  SLIME = LEVI .. "third-person_removes/002_Remove_Rebbies.lua",
  VITAL = LEVI .. "third-person_removes/004_Remove_Unweavingbody.lua",
  UNBURDENED = LEVI .. "third-person_removes/005_Remove_Unweavingspirit.lua",
  REIGNITES = LEVI .. "third-person_removes/006_Remove_Unweavingmind.lua",
  FULMINATED = LEVI .. "magi_offense_tracking/007_Fulminated_Paralysis.lua",
  FOCUS = LEVI .. "398_Focus_(UNK).lua",
  FOCUS_NEXT = LEVI .. "399_Focus_(known).lua",
  SEDUCE = LEVI .. "other_things_fading/002_Seduce_(siren).lua",
  SIP = LEVI .. "394_Sipped_Something.lua",
  STUPID = LEVI .. "419_Stupidity.lua",
  STAND = LEVI .. "410_Stood_Up.lua",
  PARALYSIS = LEVI .. "420_Paralysis.lua",
  PARTY = LEVI .. "426_Party_Afflictions.lua",
  PARTY2 = LEVI .. "428_Double_Party_Affs.lua",
  PARTY_ON = LEVI .. "436_PARTY_AFFS_DIFFERENT.lua",
  TREE = LEVI .. "389_Tree(U).lua",
  SALVE_BODY = LEVI .. "391_Applied_Body_Skin.lua",
  SALVE_HEAD = LEVI .. "392_Applied_Head.lua",
  SALVE_TORSO = LEVI .. "393_Applied_Torso.lua",
  SALVE_LIMBS = LEVI .. "395_Applied_Limbs.lua",
  SALVES = LEVI .. "396_Salves.lua",
  QUICKSILVER = LEVI .. "herbs/013_Quicksilver.lua",
}
local BODY = {}
for k, path in pairs(PATH) do
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a"); fh:close()
  BODY[k] = assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
end

-- The world the triggers run in. Only what the loaded files do not provide is stubbed.
local now, events, echoes, tracked = 1000, {}, {}, {}
local function world(name)
  now, events, echoes, tracked = 1000, {}, {}, {}
  mock.reset()                          -- no timer from an earlier test may fire into this one
  getEpoch = function() return now end
  target = name or "Archaeon"
  isTargeted = function(n) return type(n) == "string" and n:lower() == target:lower() end
  raiseEvent = function(e, a) events[#events + 1] = { e, a } end
  checkTargetLocks = function() end     -- curing/003, not loaded
  ataxiaEcho, zgui = function() end, nil
  cecho = function(s) echoes[#echoes + 1] = s end
  fg = function() end
  predictBal = function() end
  gmcp = { Char = { Status = { class = "Serpent" } } }
  ataxiaTemp = { tarAffTimers = {} }
  tAffs, affTimers = {}, {}
  tBals = { tree = true, focus = true, plant = true, timers = {} }
  targetIshere = false
  serpent = { trackCure = function(kind) tracked[#tracked + 1] = kind end }
  tdeliverance, anorexiaFailsafe, passiveFailsafe, lastFocus = nil, nil, nil, nil
  pariah = { state = {} }
  rw2h = nil
  lb = {}
  affConfigV3.enabled = true
  resetStatesV3()
end

local P = function(a) return getAffProbabilityV3(a) end
local function near(got, want, what)
  if math.abs(got - want) > 1e-9 then
    error(string.format("%s: expected %.4f but got %.4f", what, want, got), 2)
  end
end
-- The afflictions erAff reported cured ("target cured aff", 017), in order.
local function cured()
  local out = {}
  for _, ev in ipairs(events) do
    if ev[1] == "target cured aff" then out[#out + 1] = ev[2] end
  end
  return out
end
local function count(list, v)
  local n = 0
  for _, x in ipairs(list) do if x == v then n = n + 1 end end
  return n
end
local function afflictedEvents()
  local n = 0
  for _, ev in ipairs(events) do if ev[1] == "tar afflicted" then n = n + 1 end end
  return n
end
local function v3Has(aff)
  for _, s in ipairs(afflictionStatesV3) do if s.affs[aff] then return true end end
  return false
end

-- One run of a single-line trigger body.
local function fire(key, text, ...)
  line = text
  matches = { text, ... }
  multimatches = nil
  BODY[key]()
end

-- Verbatim rows. X8pRorzR = kb/raw/logs/2026-11-01_nikita_depthswalker-vs-serpent_win_X8pRorzR.txt
local EAT = "Archaeon eats a plumbum flake."                          -- X8pRorzR.txt:536
local LUCID = "Lucidity returns to the eyes of Archaeon."              -- X8pRorzR.txt:537
local function eatGoldenseal() fire("GOLDENSEAL", EAT, "Archaeon", "plumbum flake") end
local function lucidity() fire("LUCIDITY", LUCID, "Archaeon") end

local ok, err = pcall(function()

describe("F14: a known goldenseal cure replaces the eat's random cure", function()
  it("the eat and the Lucidity line match their triggers", function()
    expect(TL.anyMatches(TL.patterns(PATH.GOLDENSEAL), EAT)).toBeTrue()
    expect(TL.anyMatches(TL.patterns(PATH.LUCIDITY), LUCID)).toBeTrue()
  end)

  it("stupidity + shadowmadness, eat then Lucidity: stupidity stays certain", function()
    world()
    tarAffed("stupidity", "shadowmadness")
    eatGoldenseal()
    near(P("stupidity"), 1 / 3, "stupidity after the eat")      -- the eat alone still branches
    lucidity()
    expect(P("stupidity")).toBe(1)
    expect(P("shadowmadness")).toBe(0)
    expect(tAffs.stupidity).toBeTrue()
    expect(tAffs.shadowmadness).toBeFalse()
    -- The eat's own negative confirmation is settled, and nothing unfolds later.
    expect(negativeConfirmTimersV3.herb_negconf).toBeNil()
    mock.fire_timers()
    expect(P("stupidity")).toBe(1)
    expect(P("shadowmadness")).toBe(0)
    expect(count(cured(), "stupidity")).toBe(0)
    expect(count(cured(), "shadowmadness")).toBe(1)
  end)

  it("the eat still proves anorexia gone and starts the herb balance", function()
    world()
    tarAffed("anorexia", "impatience", "shadowmadness")
    eatGoldenseal()
    lucidity()
    expect(P("anorexia")).toBe(0)
    expect(P("impatience")).toBe(1)
    expect(canTargetCureV3("herb")).toBeFalse()
  end)

  it("with no known line the eat branches as before", function()
    world()
    tarAffed("stupidity", "shadowmadness")
    eatGoldenseal()
    near(P("stupidity"), 1 / 3, "stupidity")
    near(P("shadowmadness"), 2 / 3, "shadowmadness")
  end)

  it("a Lucidity line with no eat before it only erases shadowmadness", function()
    world()
    tarAffed("stupidity", "shadowmadness")
    lucidity()
    expect(P("stupidity")).toBe(1)
    expect(P("shadowmadness")).toBe(0)
  end)

  it("a hit between the two lines is not undone", function()
    world()
    tarAffed("stupidity", "shadowmadness")
    eatGoldenseal()
    tarAffed("asthma")
    lucidity()
    expect(P("asthma")).toBe(1)
    expect(P("shadowmadness")).toBe(0)
    near(P("stupidity"), 1 / 3, "stupidity (the old erase only)")
  end)

  it("a Lucidity line after the window only erases", function()
    world()
    tarAffed("stupidity", "shadowmadness")
    eatGoldenseal()
    now = now + 1
    lucidity()
    near(P("stupidity"), 1 / 3, "stupidity")
    expect(P("shadowmadness")).toBe(0)
  end)

  it("another person's Lucidity line changes nothing for the target", function()
    world()
    tarAffed("stupidity", "shadowmadness")
    eatGoldenseal()
    fire("LUCIDITY", "Lucidity returns to the eyes of Bystander.", "Bystander")
    near(P("stupidity"), 1 / 3, "stupidity")
    near(P("shadowmadness"), 2 / 3, "shadowmadness")
  end)

  it("mercury on the target: the eat erases it and the known cure still replaces the random one", function()
    world()
    tarAffed("stupidity", "shadowmadness", "mercury")           -- 444 gives mercury through tarAffed
    expect(tAffs.mercury).toBeTrue()
    eatGoldenseal()
    lucidity()
    expect(P("stupidity")).toBe(1)
    expect(P("shadowmadness")).toBe(0)
    expect(P("mercury")).toBe(0)
    expect(tAffs.mercury).toBeFalse()
    -- The plant balance still waits the mercury time (1.9 s), not the plain 1.3 s.
    expect(mock.active_timers[tBals.timers.plant].delay).toBe(1.9)
  end)

  it("no mercury: the plant balance waits the plain 1.3 s", function()
    world()
    tarAffed("stupidity")
    eatGoldenseal()
    expect(mock.active_timers[tBals.timers.plant].delay).toBe(1.3)
  end)

  it("herbs/004: eat then 'ceases his violent trembling' charges mycalium alone", function()
    world()
    tarAffed("stupidity", "mycalium")
    eatGoldenseal()
    local TREMBLE = "Archaeon ceases his violent trembling."
    expect(TL.anyMatches(TL.patterns(PATH.MYCALIUM), TREMBLE)).toBeTrue()
    line = TREMBLE
    matches = {}
    multimatches = { { EAT, "Archaeon", "plumbum flake" }, { TREMBLE, "Archaeon" } }
    BODY.MYCALIUM()
    expect(P("stupidity")).toBe(1)
    expect(P("mycalium")).toBe(0)
  end)

  it("herbs/004: another person's trembling after the target's eat moves nothing", function()
    world()
    tarAffed("stupidity", "mycalium")
    eatGoldenseal()
    local TREMBLE = "Bystander ceases his violent trembling."
    multimatches = { { EAT, "Archaeon", "plumbum flake" }, { TREMBLE, "Bystander" } }
    BODY.MYCALIUM()
    near(P("stupidity"), 1 / 3, "stupidity")
    near(P("mycalium"), 2 / 3, "mycalium")
  end)
end)

-- The eat and smoke rows are verbatim. The named cure lines are CONSTRUCTED from each trigger's own
-- pattern: no log holds them in the third person (the first-person forms are in AFFLICTION SHOW,
-- kb/raw/live/affliction_show/).
local KELP_EAT = "Claes eats a piece of kelp."              -- 2026-10-11_shikudo-vs-runewarden-snb_attacker.txt:39
local GINSENG_EAT = "Claes eats a ginseng root."            -- 2026-10-11_shikudo-vs-runewarden-snb_attacker.txt:352
local SMOKE = "Dominius takes a long drag off his pipe."    -- 2026-10-11_runewarden-snb-vs-shikudo_defender.txt:53
local function eatGinseng() fire("GINSENG", GINSENG_EAT, "Claes", "ginseng root") end
-- The patterns trigger_lib can read: 390 has an unanchored regex (the hookah line), 008 a line spacer.
local function anchoredPatterns(path)
  local out = {}
  for _, p in ipairs(TL.patterns(path)) do
    if p.type == 1 and p.pat:sub(1, 1) == "^" then out[#out + 1] = p end
  end
  return out
end

describe("F14 siblings: a known cure replaces the random cure of its action", function()
  local CASES = {
    { what = "unweavingmind after a goldenseal eat", who = "Archaeon", act = "GOLDENSEAL", line = EAT,
      args = { "Archaeon", "plumbum flake" }, known = "REIGNITES",
      text = "The light behind the eyes of Archaeon reignites.", aff = "unweavingmind", other = "stupidity" },
    { what = "mycalium after a goldenseal eat", who = "Archaeon", act = "GOLDENSEAL", line = EAT,
      args = { "Archaeon", "plumbum flake" }, known = "NERVOUS",
      text = "Archaeon ceases his nervous trembling.", aff = "mycalium", other = "stupidity" },
    { what = "rebbies after a kelp eat", who = "Claes", act = "KELP", line = KELP_EAT,
      args = { "Claes", "a piece of kelp" }, known = "SLIME",
      text = "The skin of Claes ceases secreting slime.", aff = "rebbies", other = "weariness" },
    { what = "unweavingbody after a ginseng eat", who = "Claes", act = "GINSENG", line = GINSENG_EAT,
      args = { "Claes", "ginseng root" }, known = "VITAL",
      text = "Claes suddenly seems much more vital.", aff = "unweavingbody", other = "nausea" },
    { what = "unweavingspirit after a smoke", who = "Dominius", act = "SMOKED", line = SMOKE,
      args = { "Dominius" }, known = "UNBURDENED",
      text = "Dominius seems suddenly unburdened, clarity reasserting itself upon his features.",
      aff = "unweavingspirit", other = "disloyalty" },
  }
  local function act(c) fire(c.act, c.line, unpack(c.args)) end
  local function named(c) fire(c.known, c.text, c.who) end

  for _, c in ipairs(CASES) do
    describe(c.what, function()
      it("the lines match their triggers", function()
        expect(TL.anyMatches(anchoredPatterns(PATH[c.act]), c.line)).toBeTrue()
        expect(TL.anyMatches(anchoredPatterns(PATH[c.known]), c.text)).toBeTrue()
      end)

      it("the action then the named line take the named affliction alone", function()
        world(c.who)
        tarAffed(c.other, c.aff)
        act(c)
        local p = P(c.other)
        expect(p > 0 and p < 1).toBeTrue()                        -- the action alone branches
        named(c)
        expect(P(c.other)).toBe(1)
        expect(P(c.aff)).toBe(0)
        expect(tAffs[c.other]).toBeTrue()
        -- The action's own negative confirmation is settled, and nothing unfolds later.
        expect(negativeConfirmTimersV3.herb_negconf).toBeNil()
        expect(negativeConfirmTimersV3.smoke_negconf).toBeNil()
        mock.fire_timers()
        expect(P(c.other)).toBe(1)
        expect(P(c.aff)).toBe(0)
        expect(count(cured(), c.other)).toBe(0)
        expect(count(cured(), c.aff)).toBe(1)
      end)

      it("a plain action still cures: it branches over the two and takes one", function()
        world(c.who)
        tarAffed(c.other, c.aff)
        act(c)
        near(P(c.other) + P(c.aff), 1, "one of the two is gone")
        expect(P(c.other) > 0 and P(c.aff) > 0).toBeTrue()
      end)

      it("a plain action on the one affliction it can take cures it", function()
        world(c.who)
        tarAffed(c.aff)
        act(c)
        expect(P(c.aff)).toBe(0)
      end)

      it("the named line with no action before it only erases", function()
        world(c.who)
        tarAffed(c.other, c.aff)
        named(c)
        expect(P(c.other)).toBe(1)
        expect(P(c.aff)).toBe(0)
      end)

      it("a hit between the two lines is not undone", function()
        world(c.who)
        tarAffed(c.other, c.aff)
        act(c)
        tarAffed("paralysis")
        named(c)
        expect(P("paralysis")).toBe(1)
        expect(P(c.aff)).toBe(0)
      end)
    end)
  end

  it("the smoke still proves asthma gone when the named line replaces its cure", function()
    world("Dominius")
    tarAffed("asthma", "disloyalty", "unweavingspirit")
    fire("SMOKED", SMOKE, "Dominius")
    fire("UNBURDENED", "Dominius seems suddenly unburdened, clarity reasserting itself upon his features.", "Dominius")
    expect(P("asthma")).toBe(0)
    expect(P("disloyalty")).toBe(1)
    expect(P("unweavingspirit")).toBe(0)
  end)

  it("the named line of another kind of action does not undo this one", function()
    world("Claes")
    tarAffed("weariness", "unweavingbody")
    fire("KELP", KELP_EAT, "Claes", "a piece of kelp")      -- kelp cannot take unweavingbody
    expect(P("weariness")).toBe(0)
    fire("VITAL", "Claes suddenly seems much more vital.", "Claes")
    expect(P("weariness")).toBe(0)
    expect(P("unweavingbody")).toBe(0)
  end)

  for _, c in ipairs({ CASES[3], CASES[4] }) do
    it(c.act .. ": mercury goes first, so the named line still replaces the random cure", function()
      world(c.who)
      tarAffed(c.other, c.aff, "mercury")
      act(c)
      named(c)
      expect(P(c.other)).toBe(1)
      expect(P(c.aff)).toBe(0)
      expect(P("mercury")).toBe(0)
      expect(tAffs.mercury).toBeFalse()
      expect(mock.active_timers[tBals.timers.plant].delay).toBe(1.9)
    end)

    it(c.act .. ": no mercury, the plain 1.3 s plant balance", function()
      world(c.who)
      tarAffed(c.other)
      act(c)
      expect(mock.active_timers[tBals.timers.plant].delay).toBe(1.3)
    end)
  end
end)

describe("008: the flushings line after a ginseng eat", function()
  -- CONSTRUCTED from 008's own pattern. The first-person form is verbatim at
  -- 2026-11-01_claes_runewarden-vs-pariah_loss_Vr.NkCGD.txt:856, after the eat and its cure line.
  local function blood(who)
    who = who or "Claes"
    local l = "Blood begins to run from the pores of " .. who .. "."
    expect(TL.anyMatches(anchoredPatterns(PATH.FLUSHINGS), l)).toBeTrue()
    line = l
    matches = {}
    multimatches = { { GINSENG_EAT, who, "ginseng root" }, {}, { l, who } }
    BODY.FLUSHINGS()
  end
  local function total()
    return P("flushings") + P("nausea") + P("addiction")
  end

  it("eat and flushings line: one eat takes one affliction", function()
    world("Claes")
    tarAffed("flushings", "nausea", "addiction")
    eatGinseng()
    near(total(), 2, "after the eat")
    local n = P("nausea")
    blood()
    near(total(), 2, "after the flushings line")
    near(P("nausea"), n, "the line moves nothing")
  end)

  it("the line starts no second eat: the ledger and the anorexia proof are 007's", function()
    world("Claes")
    tarAffed("nausea", "addiction", "anorexia")
    eatGinseng()
    expect(P("anorexia")).toBe(0)
    expect(count(tracked, "ginseng")).toBe(1)
    blood()
    expect(count(tracked, "ginseng")).toBe(1)
  end)

  it("a known line between the eat and the flushings line: the named one alone", function()
    world("Claes")
    tarAffed("nausea", "unweavingbody")
    eatGinseng()
    fire("VITAL", "Claes suddenly seems much more vital.", "Claes")
    blood()
    expect(P("nausea")).toBe(1)
    expect(P("unweavingbody")).toBe(0)
  end)

  it("a part-name target ('t cla'): 007 did not run, so this line charges the eat once", function()
    world("Claes")
    isTargeted = realIsTargeted
    updateTarget = function(n) target = n:sub(1, 1):upper() .. n:sub(2) end
    target = "Cla"
    tarAffed("nausea", "addiction")
    eatGinseng()
    expect(P("nausea") + P("addiction")).toBe(2)            -- 007 compares the exact name
    blood()
    expect(target).toBe("Claes")
    near(P("nausea") + P("addiction"), 1, "one eat, one cure")
  end)

  it("a bystander's flushings line changes nothing", function()
    world("Claes")
    tarAffed("nausea", "addiction")
    blood("Bystander")
    expect(P("nausea")).toBe(1)
    expect(P("addiction")).toBe(1)
  end)
end)

describe("F43: 398 owns the focus, 399 reads the next line", function()
  -- kb/raw/logs/ours/2026-11-07_164635_Saibel.log:372
  local FOCUS = "A look of extreme focus crosses the face of Saibel."
  local CLARITY = "Saibel shakes her head and a look of clarity returns to her eyes."
  local function focusLine() fire("FOCUS", FOCUS, "Saibel") end
  local function nextLine(text)
    line = text
    matches = {}
    multimatches = { { FOCUS, "Saibel" }, {}, { text } }
    BODY.FOCUS_NEXT()
  end
  local function seduce(text) fire("SEDUCE", text, "Saibel") end

  it("one focus counts once for the Serpent ledger", function()
    world("Saibel")
    tarAffed("stupidity")
    focusLine()
    nextLine("H: Full, M: High, E: High, W: Full cekdb-")
    expect(count(tracked, "focus")).toBe(1)
    expect(P("stupidity")).toBe(0)
  end)

  it("a bystander's focus counts nothing", function()
    world("Saibel")
    fire("FOCUS", "A look of extreme focus crosses the face of Bystander.", "Bystander")
    expect(#tracked).toBe(0)
  end)

  it("a focus that took lovers: lovers alone goes (399 first, then 002_Seduce)", function()
    world("Saibel")
    tarAffed("lovers", "stupidity")
    focusLine()
    near(P("stupidity"), 1 / 2, "stupidity after the focus")
    nextLine(CLARITY)
    seduce(CLARITY)
    expect(P("stupidity")).toBe(1)
    expect(P("lovers")).toBe(0)
    expect(tAffs.lovers).toBeFalse()
    expect(count(cured(), "lovers")).toBe(1)
  end)

  it("the same in the other order (002_Seduce first, then 399)", function()
    world("Saibel")
    tarAffed("lovers", "stupidity")
    focusLine()
    seduce(CLARITY)
    nextLine(CLARITY)
    expect(P("stupidity")).toBe(1)
    expect(P("lovers")).toBe(0)
    expect(count(cured(), "lovers")).toBe(1)
  end)

  it("a plain next line leaves the random focus cure as it was", function()
    world("Saibel")
    tarAffed("lovers", "stupidity")
    focusLine()
    nextLine("You have recovered balance on all limbs.")
    near(P("stupidity"), 1 / 2, "stupidity")
    near(P("lovers"), 1 / 2, "lovers")
  end)
end)

describe("F44: the sigh of relief is retribution, not earworm (herbs/016)", function()
  it("retribution goes, earworm stays", function()
    world()
    tarAffed("earworm", "retribution")
    -- X8pRorzR.txt:426, straight after "Archaeon eats a cuprum flake." (425)
    local SIGH = "Archaeon gives a sigh of relief."
    expect(TL.anyMatches(TL.patterns(PATH.SIGH), SIGH)).toBeTrue()
    fire("SIGH", SIGH, "Archaeon")
    expect(P("retribution")).toBe(0)
    expect(P("earworm")).toBe(1)
    expect(tAffs.earworm).toBeTrue()
    expect(count(cured(), "earworm")).toBe(0)
  end)
end)

describe("F45: an ash eat with our crescendo up is one cure (herbs/006)", function()
  local ASH = "Saibel eats some prickly ash bark."
  local function eatAsh() fire("ASH", ASH, "Saibel", "some prickly ash bark") end

  it("crescendo 3 and confusion: crescendo drops to 1, confusion stays", function()
    world("Saibel")
    tAffs.crescendo = 3
    tarAffed("confusion")
    eatAsh()
    expect(tAffs.crescendo).toBe(1)
    expect(P("confusion")).toBe(1)
    expect(canTargetCureV3("herb")).toBeFalse()
  end)

  it("crescendo 1 and confusion: crescendo ends, confusion stays", function()
    world("Saibel")
    tAffs.crescendo = 1
    tarAffed("confusion", "anorexia")
    eatAsh()
    expect(tAffs.crescendo).toBe(0)
    expect(P("confusion")).toBe(1)
    expect(P("anorexia")).toBe(0)
  end)

  it("no crescendo: the V3 ash cure takes confusion, as before", function()
    world("Saibel")
    tAffs.crescendo = false
    tarAffed("confusion")
    eatAsh()
    expect(P("confusion")).toBe(0)
  end)
end)

describe("F18: a sip under Latency keeps voyria (394)", function()
  local SIP = "Saibel takes a drink from a pale cyan vial."
  local function sip() fire("SIP", SIP, "Saibel", "a pale cyan vial") end

  it("with latency running, voyria stays", function()
    world("Saibel")
    tarAffed("voyria")
    pariah.state.latencyTimer = 1
    sip()
    expect(haveAff("voyria")).toBeTrue()
    expect(count(cured(), "voyria")).toBe(0)
  end)

  it("without latency, the sip cures it", function()
    world("Saibel")
    tarAffed("voyria")
    sip()
    expect(haveAff("voyria")).toBeFalse()
  end)

  it("with no pariah table at all, the sip still cures it", function()
    world("Saibel")
    tarAffed("voyria")
    pariah = nil
    sip()
    expect(haveAff("voyria")).toBeFalse()
  end)
end)

describe("F47: the stupidity lines (419)", function()
  -- Verbatim, with the row each comes from (419's comment lists the files).
  local LINES = {
    { '"The voices! The voices! Get them out of my head!!" Saibel moans, holding her head.', "Saibel" }, -- Saibel.log:1752
    { "Saibel fondles herself absently.", "Saibel" },                                             -- Saibel.log:1763
    { "Saibel stumbles and pokes herself in the eye.", "Saibel" },                                -- Saibel.log:1812
    { "Archaeon pulls down his pants and moons the world.", "Archaeon" },                         -- X8pRorzR.txt:1498
    { "Archaeon looks around vainly for a partner to tango with.", "Archaeon" },                  -- X8pRorzR.txt:1502
    { "Archaeon flaps his arms madly.", "Archaeon" },                                             -- X8pRorzR.txt:4626
    { "Archaeon giggles happily.", "Archaeon" },                                                  -- X8pRorzR.txt:5754
    { "Tears fill Archaeon's eyes and begin to slowly run down his face.", "Archaeon" },          -- X8pRorzR.txt:5794
    { "Archaeon sweeps across the floor, leaping and twirling like a true master.", "Archaeon" }, -- X8pRorzR.txt:5931
    { "Dominius attempts to do a standing backflip, but merely stumbles over his own feet.", "Dominius" }, -- defender.txt:1798
    { '"The voices! The voices! Get them out of my head!!" Dominius moans, holding his head.', "Dominius" }, -- defender.txt:1845
  }
  -- The pattern that matches the line, with its first (\w+) replaced by the name, still matches:
  -- so the name is what the trigger hands its body as matches[2].
  local function capturesName(l, name)
    for _, p in ipairs(TL.patterns(PATH.STUPID)) do
      if TL.matches(p.pat, p.type, l) then
        local s, e = p.pat:find("(\\w+)", 1, true)
        if not s then return false end
        local pinned = p.pat:sub(1, s - 1) .. name .. p.pat:sub(e + 1)
        return TL.matches(pinned, p.type, l)
      end
    end
    return false
  end

  it("each line matches a pattern that captures the name", function()
    for _, l in ipairs(LINES) do
      if not capturesName(l[1], l[2]) then error("no pattern captures " .. l[2] .. " in: " .. l[1]) end
    end
  end)

  it("our own first-person lines match nothing (LcJC-rJ5.txt:751, 946-948, 3666)", function()
    local pats = TL.patterns(PATH.STUPID)
    for _, l in ipairs({
      "You attempt to do a standing backflip, but merely stumble over your own feet.",
      "Tears fill your eyes and begin to slowly run down your face.",
      "You giggle happily.",
      '"The voices! The voices! Get them out of my head!!" you moan, holding your head in pain.',
      "You flap your arms madly.",
    }) do
      expect(TL.anyMatches(pats, l)).toBeFalse()
    end
  end)

  it("each line on the target proves stupidity after a branching eat", function()
    for _, l in ipairs(LINES) do
      world(l[2])
      tarAffed("stupidity", "impatience")
      onHerbCureV3("goldenseal")
      fire("STUPID", l[1], l[2])
      expect(P("stupidity")).toBe(1)
    end
  end)

  it("a bystander's line moves nothing", function()
    world("Saibel")
    tarAffed("stupidity", "impatience")
    onHerbCureV3("goldenseal")
    local p = P("stupidity")
    fire("STUPID", "Archaeon giggles happily.", "Archaeon")
    expect(P("stupidity")).toBe(p)
  end)
end)

describe("H2: party calls reach V3 (paAff, 426, 428, 436)", function()
  it("paAff turns a venom into its affliction and gives it to V3", function()
    world("Saibel")
    paAff("curare")
    expect(P("paralysis")).toBe(1)
    expect(tAffs.paralysis).toBeTrue()
    expect(v3Has("curare")).toBeFalse()
    expect(tAffs.curare).toBeNil()
  end)

  it("a called affliction can be cured by the target's eat", function()
    world("Saibel")
    paAff("Paralysis")
    expect(P("paralysis")).toBe(1)
    onHerbCureV3("bloodroot")
    expect(P("paralysis")).toBe(0)
    expect(tAffs.paralysis).toBeFalse()
  end)

  it("a call confirms an affliction the tracker had split", function()
    world("Saibel")
    tarAffed("stupidity", "impatience")
    onHerbCureV3("goldenseal")
    paAff("aconite")
    expect(P("stupidity")).toBe(1)
  end)

  it("426: 'hit with curare' adds paralysis, never 'curare'", function()
    world("Saibel")
    local L = '(Party): Gavai says, "Saibel hit with curare."'
    expect(TL.anyMatches(TL.patterns(PATH.PARTY), L)).toBeTrue()
    fire("PARTY", L, "Gavai", "Saibel", "curare")
    expect(P("paralysis")).toBe(1)
    expect(v3Has("curare")).toBeFalse()
    expect(afflictedEvents()).toBe(1)
  end)

  it("426: a two-word list adds both, once each", function()
    world("Saibel")
    local L = '(Party): Maldrantus says, "Saibel: impatience kalmia."'
    expect(TL.anyMatches(TL.patterns(PATH.PARTY), L)).toBeTrue()
    fire("PARTY", L, "Maldrantus", "Saibel", "impatience", "kalmia")
    expect(P("impatience")).toBe(1)
    expect(P("asthma")).toBe(1)
    expect(v3Has("kalmia")).toBeFalse()
    expect(afflictedEvents()).toBe(2)
  end)

  it("426: a Serin 'has' line is read by the 'has' pattern and does not throw", function()
    world("Saibel")
    local L = '(Party): Serin says, "Saibel has paralysis."'
    expect(TL.anyMatches(TL.patterns(PATH.PARTY), L)).toBeTrue()
    fire("PARTY", L, "Serin", "Saibel", "paralysis")
    expect(P("paralysis")).toBe(1)
  end)

  it("426: another target's call moves nothing", function()
    world("Saibel")
    fire("PARTY", '(Party): Gavai says, "Kutcher hit with curare."', "Gavai", "Kutcher", "curare")
    expect(P("paralysis")).toBe(0)
  end)

  it("428: 'wracked: curare kalmia' adds paralysis and asthma", function()
    world("Saibel")
    local L = '(Party): Gavai says, "Saibel wracked: curare kalmia."'
    expect(TL.anyMatches(TL.patterns(PATH.PARTY2), L)).toBeTrue()
    fire("PARTY2", L, "Gavai", "Saibel", "curare", "kalmia")
    expect(P("paralysis")).toBe(1)
    expect(P("asthma")).toBe(1)
    expect(v3Has("curare")).toBeFalse()
    expect(v3Has("kalmia")).toBeFalse()
  end)

  it("436: ' curare on Saibel' adds paralysis", function()
    world("Saibel")
    local L = '(Party): Gavai says, " curare on Saibel."'
    expect(TL.anyMatches(TL.patterns(PATH.PARTY_ON), L)).toBeTrue()
    fire("PARTY_ON", L, "Gavai", "curare", "Saibel")
    expect(P("paralysis")).toBe(1)
    expect(v3Has("curare")).toBeFalse()
  end)
end)

describe("410: a stand line with no limb row for the full name", function()
  local STAND = "Saibel stands up."

  it("a part-name target: the stand still clears prone and paralysis", function()
    world("Saibel")
    isTargeted = realIsTargeted
    updateTarget = function(n) target = n:sub(1, 1):upper() .. n:sub(2) end
    target = "Sai"
    lb = { Sai = { hits = { ["left leg"] = 0, ["right leg"] = 0 } } }
    tarAffed("prone", "paralysis")
    expect(TL.anyMatches(TL.patterns(PATH.STAND), STAND)).toBeTrue()
    fire("STAND", STAND, "Saibel")
    expect(target).toBe("Saibel")
    expect(haveAff("prone")).toBeFalse()
    expect(haveAff("paralysis")).toBeFalse()
    expect(tAffs.prone).toBeFalse()
  end)

  it("with a row, a broken leg's counter is reset as before", function()
    world("Saibel")
    lb = { Saibel = { hits = { ["left leg"] = 120, ["right leg"] = 40 } } }
    tarAffed("prone", "brokenleftleg")
    fire("STAND", STAND, "Saibel")
    expect(lb.Saibel.hits["left leg"]).toBe(0)
    expect(lb.Saibel.hits["right leg"]).toBe(40)
    expect(haveAff("brokenleftleg")).toBeFalse()
  end)
end)

describe("420: a line that gives paralysis adds it to every branch", function()
  -- kb/raw/logs/ours/2026-11-03_081532_Tabethys.log:28 (an ally's curare on Xylarys)
  local HORROR = "Horror overcomes Xylarys's face as his body stiffens into paralysis."

  it("after a bloodroot eat split paralysis and slickness, slickness keeps its weight", function()
    world("Xylarys")
    tarAffed("paralysis", "slickness", "anorexia")
    onHerbCureV3("bloodroot")
    local slick = P("slickness")
    expect(slick > 0 and slick < 1).toBeTrue()
    expect(TL.anyMatches(TL.patterns(PATH.PARALYSIS), HORROR)).toBeTrue()
    fire("PARALYSIS", HORROR, "Xylarys")
    expect(P("paralysis")).toBe(1)
    near(P("slickness"), slick, "slickness")
    expect(tAffs.slickness).toBeTrue()
  end)

  it("420 and the Magi tracker (007) read the same line: one add, whichever runs first", function()
    expect(TL.anyMatches(TL.patterns(PATH.FULMINATED), HORROR)).toBeTrue()
    for _, order in ipairs({ { "PARALYSIS", "FULMINATED" }, { "FULMINATED", "PARALYSIS" } }) do
      world("Xylarys")
      tarAffed("asthma")
      events = {}
      fire(order[1], HORROR, "Xylarys")
      fire(order[2], HORROR, "Xylarys")
      expect(P("paralysis")).toBe(1)
      expect(P("asthma")).toBe(1)
      expect(afflictedEvents()).toBe(1)
    end
  end)

  it("the Magi tracker alone gives it, and another person's line does nothing", function()
    world("Xylarys")
    fire("FULMINATED", HORROR, "Xylarys")
    expect(P("paralysis")).toBe(1)
    world("Xylarys")
    fire("FULMINATED", "Horror overcomes Bystander's face as his body stiffens into paralysis.", "Bystander")
    expect(P("paralysis")).toBe(0)
  end)

  it("with no paralysis at all, the line gives it and says so once", function()
    world("Xylarys")
    tarAffed("asthma")
    events = {}
    fire("PARALYSIS", HORROR, "Xylarys")
    expect(P("paralysis")).toBe(1)
    expect(P("asthma")).toBe(1)
    expect(afflictedEvents()).toBe(1)
  end)

  it("when paralysis is certain already, nothing is raised again", function()
    world("Xylarys")
    tarAffed("paralysis")
    events = {}
    fire("PARALYSIS", HORROR, "Xylarys")
    expect(P("paralysis")).toBe(1)
    expect(afflictedEvents()).toBe(0)
  end)

  it("certain in every branch, but the weights sum a few ulps under 1: nothing is raised", function()
    world("Xylarys")
    afflictionStatesV3 = {
      { affs = { paralysis = true, asthma = true }, prob = 0.7 },
      { affs = { paralysis = true, slickness = true }, prob = 0.2 },
      { affs = { paralysis = true }, prob = 0.1 },
    }
    rebuildCacheV3()
    expect(P("paralysis") < 1).toBeTrue()            -- 0.99999999999999989: the old >= 1 test failed here
    expect(isAffCertainV3("paralysis")).toBeTrue()
    events = {}
    fire("PARALYSIS", HORROR, "Xylarys")
    expect(afflictedEvents()).toBe(0)
    near(P("slickness"), 0.2, "slickness")
  end)
end)

-- The application rows are verbatim in kb/raw/logs/ours (cited at each); rub() builds the same row
-- for the other spots.
local BERRY = "Grulk applies a sileris berry to himself."              -- 2026-11-03_081532_Tabethys.log:1455
local DROPLET = "Sinit applies a quicksilver droplet to herself."      -- 2026-10-27_112717_Tabethys.log:1328
local TREE_LINE = "Saibel touches a tree of life tattoo."              -- FceAmb0o.txt:359, with Saibel's name
local FOCUS_LINE = "A look of extreme focus crosses the face of Saibel." -- 2026-11-07_164635_Saibel.log:372
local CLARITY = "Saibel shakes her head and a look of clarity returns to her eyes."

-- 391-396 in Mudlet's order for each spot: the Groups folder runs them top to bottom, and each one
-- fires only on the lines its own pattern matches.
local RUB_ORDER = {
  skin = { "SALVE_BODY", "SALVES" }, body = { "SALVE_BODY", "SALVE_TORSO", "SALVES" },
  head = { "SALVE_HEAD", "SALVES" }, torso = { "SALVE_TORSO", "SALVES" },
  arms = { "SALVE_LIMBS", "SALVES" }, legs = { "SALVE_LIMBS", "SALVES" },
}
local function rub(who, spot)
  local text = who .. " takes some salve from a vial and rubs it on his " .. spot .. "."
  for _, key in ipairs(RUB_ORDER[spot]) do
    expect(TL.anyMatches(TL.patterns(PATH[key]), text)).toBeTrue()
    fire(key, text, who, spot)
  end
end

-- world() plus what the application triggers need, with the tracker's echoes recorded.
local function proofWorld(name)
  world(name)
  ataxiaEcho = function(s) echoes[#echoes + 1] = s end
  ataxiaTemp.crushedCheck = {}
  selectCurrentLine, target_appliedTo, target_salveBal = function() end, function() end, function() end
  treeTimer0, treeTimer4, treeTimer9, treeTimer = nil, nil, nil, nil
  salveChargedAtV3 = nil
end
local function says(what)
  local n = 0
  for _, s in ipairs(echoes) do if s:find(what, 1, true) then n = n + 1 end end
  return n
end

describe("a proof drops the branches it rules out (proveAffAbsentV3, 007)", function()
  local function tree() fire("TREE", TREE_LINE, "Saibel") end

  it("magnesium then a tree: the 'slickness cured' branch goes, asthma and slickness are 1/2", function()
    proofWorld("Saibel")
    tarAffed("asthma", "paralysis", "slickness")
    onHerbCureV3("bloodroot")
    near(P("paralysis"), 1 / 3, "paralysis after the eat")
    near(P("slickness"), 2 / 3, "slickness after the eat")
    tree()
    expect(P("paralysis")).toBe(0)
    near(P("slickness"), 1 / 2, "slickness")           -- 1/3 when the erase came first
    near(P("asthma"), 1 / 2, "asthma")
    expect(count(cured(), "paralysis")).toBe(1)
  end)

  it("the same with clumsiness: three candidates at 2/3 each", function()
    proofWorld("Saibel")
    tarAffed("asthma", "clumsiness", "paralysis", "slickness")
    onHerbCureV3("bloodroot")
    tree()
    near(P("slickness"), 2 / 3, "slickness")           -- 0.44 when the erase came first
    near(P("asthma"), 2 / 3, "asthma")
    near(P("clumsiness"), 2 / 3, "clumsiness")
  end)

  it("a tree on a certain paralysis takes it off with no WARNING, and reports it once", function()
    proofWorld("Saibel")
    tarAffed("paralysis", "asthma")
    tree()
    expect(P("paralysis")).toBe(0)
    expect(P("asthma")).toBe(0)                        -- the tree's only candidate
    expect(says("WARNING")).toBe(0)
    expect(count(cured(), "paralysis")).toBe(1)
  end)

  it("a paralysis that only tAffs held is still erased by the tree", function()
    proofWorld("Saibel")
    tAffs.paralysis = true
    tree()
    expect(tAffs.paralysis).toBeFalse()
    expect(count(cured(), "paralysis")).toBe(1)
  end)

  for _, spot in ipairs({ "skin", "body", "head", "torso", "arms", "legs" }) do
    it("magnesium then a salve on the " .. spot .. ": slickness was gone, so paralysis is certain", function()
      proofWorld("Saibel")
      tarAffed("paralysis", "slickness")
      onHerbCureV3("bloodroot")
      rub("Saibel", spot)
      near(P("paralysis"), 1, "paralysis")             -- 1/3 when the erase came first
      expect(P("slickness")).toBe(0)
      expect(tAffs.paralysis).toBeTrue()
    end)
  end

  it("a salve on a certain slickness takes it off with no WARNING", function()
    proofWorld("Saibel")
    tarAffed("slickness", "asthma")
    rub("Saibel", "torso")
    expect(P("slickness")).toBe(0)
    expect(P("asthma")).toBe(1)
    expect(says("WARNING")).toBe(0)
  end)

  it("a salve the clock calls an illusion proves nothing: slickness is only erased, as before", function()
    proofWorld("Saibel")
    tarAffed("paralysis", "slickness")
    onHerbCureV3("bloodroot")
    startCureBalanceV3("salve")
    rub("Saibel", "torso")
    near(P("paralysis"), 1 / 3, "paralysis")
    expect(P("slickness")).toBe(0)
    expect(says("ILLUSION")).toBe(1)
  end)

  it("goldenseal then a focus: the branches holding impatience go, the other two are 1/2", function()
    proofWorld("Saibel")
    tarAffed("impatience", "stupidity", "shyness")
    onHerbCureV3("goldenseal")
    fire("FOCUS", FOCUS_LINE, "Saibel")
    expect(P("impatience")).toBe(0)
    near(P("stupidity"), 1 / 2, "stupidity")           -- 0.07 when the focus only stripped it
    near(P("shyness"), 1 / 2, "shyness")
  end)

  it("kelp, a smoke, then the line naming the smoke's cure: the smoke's proof stands", function()
    proofWorld("Dominius")
    tarAffed("asthma", "clumsiness", "unweavingspirit")
    fire("KELP", "Dominius eats a piece of kelp.", "Dominius", "a piece of kelp")
    near(P("clumsiness"), 2 / 3, "clumsiness after the kelp")
    fire("SMOKED", SMOKE, "Dominius")
    near(P("clumsiness"), 1, "clumsiness after the smoke")
    fire("UNBURDENED", "Dominius seems suddenly unburdened, clarity reasserting itself upon his features.", "Dominius")
    near(P("clumsiness"), 1, "clumsiness after the named line")      -- 0.67 when the branch came back
    expect(P("asthma")).toBe(0)
    expect(P("unweavingspirit")).toBe(0)
  end)

  it("the same with a second smoke candidate: the named one alone goes", function()
    proofWorld("Dominius")
    tarAffed("asthma", "clumsiness", "disloyalty", "unweavingspirit")
    fire("KELP", "Dominius eats a piece of kelp.", "Dominius", "a piece of kelp")
    fire("SMOKED", SMOKE, "Dominius")
    fire("UNBURDENED", "Dominius seems suddenly unburdened, clarity reasserting itself upon his features.", "Dominius")
    near(P("clumsiness"), 1, "clumsiness")
    near(P("disloyalty"), 1, "disloyalty")
    expect(P("unweavingspirit")).toBe(0)
  end)

  it("goldenseal, a focus, then the line naming lovers: the focus's proof stands", function()
    proofWorld("Saibel")
    tarAffed("impatience", "stupidity", "lovers")
    onHerbCureV3("goldenseal")
    fire("FOCUS", FOCUS_LINE, "Saibel")
    line = CLARITY
    matches = {}
    multimatches = { { FOCUS_LINE, "Saibel" }, {}, { CLARITY } }
    BODY.FOCUS_NEXT()
    fire("SEDUCE", CLARITY, "Saibel")
    near(P("stupidity"), 1, "stupidity")
    expect(P("impatience")).toBe(0)
    expect(P("lovers")).toBe(0)
    expect(says("WARNING")).toBe(0)
  end)
end)

describe("013: a sileris berry or a quicksilver droplet is not on salve balance", function()
  it("the lines match the trigger", function()
    expect(TL.anyMatches(TL.patterns(PATH.QUICKSILVER), BERRY)).toBeTrue()
    expect(TL.anyMatches(TL.patterns(PATH.QUICKSILVER), DROPLET)).toBeTrue()
  end)

  it("a berry 0.143 s after a legs salve: no ILLUSION line, the salve clock left alone", function()
    proofWorld("Grulk")
    rub("Grulk", "legs")                               -- 2026-11-03_081532_Tabethys.log:1435
    local clock = cureBalancesV3.salve
    now = now + 0.143
    fire("QUICKSILVER", BERRY, "Grulk", "sileris berry")
    expect(says("ILLUSION")).toBe(0)
    expect(cureBalancesV3.salve).toBe(clock)
  end)

  it("a berry starts no salve clock: a torso line 0.2 s later is accepted", function()
    proofWorld("Grulk")
    fire("QUICKSILVER", BERRY, "Grulk", "sileris berry")
    expect(canTargetCureV3("salve")).toBeTrue()
    now = now + 0.2
    rub("Grulk", "torso")
    expect(says("ILLUSION")).toBe(0)
    expect(canTargetCureV3("salve")).toBeFalse()       -- the torso line started it
  end)

  it("a second salve inside the window is still called an illusion", function()
    proofWorld("Grulk")
    rub("Grulk", "torso")
    now = now + 0.2
    rub("Grulk", "torso")
    expect(says("ILLUSION")).toBe(1)
  end)

  it("the apply proves no slickness: the smoke's branch that kept it is dropped", function()
    proofWorld("Sinit")
    tarAffed("slickness", "disloyalty")
    onSmokeCureV3()
    local d = P("disloyalty")
    expect(d > 0 and d < 1).toBeTrue()
    fire("QUICKSILVER", DROPLET, "Sinit", "quicksilver droplet")
    near(P("disloyalty"), 1, "disloyalty")             -- the V2 erase stripped slickness first
    expect(P("slickness")).toBe(0)
  end)

  it("an apply on a certain slickness takes it off with no WARNING", function()
    proofWorld("Sinit")
    tarAffed("slickness", "asthma")
    fire("QUICKSILVER", DROPLET, "Sinit", "quicksilver droplet")
    expect(P("slickness")).toBe(0)
    expect(P("asthma")).toBe(1)
    expect(says("WARNING")).toBe(0)
  end)
end)

end)

mock.reset()
table.contains = savedContains
string.starts = savedStarts
-- Restore the shared Lua state: drop every global the loaded files created and put back every
-- one they replaced.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
