--- test_shikudo_telepathy.lua -- vv's Telepathy (shikudo/011, v4.7.420): the pure picker, the
--- snapshot it reads, and the rounds shikudo.dispatchMind sends. Loads the REAL monk/004 (kata),
--- 006 (the dispatch offense) and 011. Every global they create or change is restored at the end
--- (one shared Lua state for all test files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local SH = "src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/"
local KAIKATA = "src_new/scripts/levi_ataxia/levi/ataxia/monk/004_Kai_And_Kata.lua"
local TELE = SH .. "011_Shikudo_Telepathy.lua"
ataxia = { vitals = {}, settings = { separator = ";" }, balances = {} }
ataxiaTemp = {}
tAffs = {}
target = "Agathon"
cecho = function() end
-- A clock we move by hand (monk/004 reads getEpoch for the kata lapse, 011 for tree and blackout).
local now = 1000
getEpoch = function() return now end
-- The offenses read target afflictions through haveAff (V3); here it reads the tAffs a test sets.
-- An earlier test file may have left its own behind, so these are always installed.
haveAff = function(aff) return tAffs ~= nil and tAffs[aff] and true or false end
local targetClass = "Unknown"
ataxiaNDB_getClass = function() return targetClass end
combatQueue = function() return "" end
tBals = { tree = true, timers = {} }
reboundHold = nil
lb = {}
for _, f in ipairs({ KAIKATA, SH .. "006_CC_Shikudo_Dispatch.lua", TELE }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

local function set(...)
  local t = {}
  for _, a in ipairs({ ... }) do t[a] = true end
  return t
end

-- A hand-built snapshot: a standing target in Rain at kata 0, full mana, her tree up, no burst, the
-- chain safe. `fields` overrides any of it; `affs` is the target's afflictions.
local function snap(fields, affs)
  affs = affs or {}
  local s = { target = "Agathon", form = "Rain", kata = 0, eq = true, mpp = 100, prone = false,
    treeUp = true, burst = 0, atRisk = false }
  s.has = function(a) return affs[a] == true end
  for k, v in pairs(fields or {}) do s[k] = v end
  if affs.prone then s.prone = true end
  return s
end

-- shikudo.tele with one setting changed for the length of `fn`, put back even if `fn` throws.
local function withTele(key, value, fn)
  local saved = shikudo.tele[key]
  shikudo.tele[key] = value
  local ok, err = pcall(fn)
  shikudo.tele[key] = saved
  if not ok then error(err, 0) end
end

describe("vv's picker: the kill afflictions and its gates (011)", function()
  local pick = shikudo.telepathyPick

  it("with shikudo.tele.scythe on: MIND SCYTHE with a mangled head and two of the five", function()
    withTele("scythe", true, function()
      expect(pick(snap({}, set("mangledhead", "stupidity", "impatience")))).toBe("mind scythe Agathon")
      expect(pick(snap({ form = "Oak" }, set("mangledhead", "dizziness", "confusion"))))
        .toBe("mind scythe Agathon")
    end)
  end)

  it("with shikudo.tele.scythe on: MIND BATTER with a mangled head and fewer than two", function()
    withTele("scythe", true, function()
      expect(pick(snap({}, set("mangledhead")))).toBe("mind batter Agathon")
      expect(pick(snap({}, set("mangledhead", "stupidity")))).toBe("mind batter Agathon")
      -- Without a mangled head neither goes out, however many of the five are on.
      local c = pick(snap({ form = "Oak" }, set("stupidity", "impatience", "dizziness", "epilepsy")))
      expect(c).toBeNil()
    end)
  end)

  -- The scythe may need a mind lock, as blackout may (the wiki gives neither a (*)), and a refused
  -- one changes nothing vv reads, so it would be picked again on every press. Off until tested live.
  it("scythe and batter are off by default, and a mangled head falls through to the other rules", function()
    expect(shikudo.tele.scythe).toBeFalse()
    expect(pick(snap({ form = "Oak" }, set("mangledhead", "stupidity", "impatience")))).toBeNil()
    -- The lock-closing impatience is not pushed aside by a batter that sets up no scythe.
    expect(pick(snap({ form = "Oak" }, set("mangledhead", "asthma", "slickness", "anorexia"))))
      .toBe("mind impatience Agathon")
    local pool = { "mangledhead", "stupidity", "impatience", "dizziness", "epilepsy", "confusion" }
    for _, form in ipairs({ "Rain", "Oak", "Willow" }) do
      for mask = 0, 2 ^ #pool - 1 do
        local affs = {}
        for i, a in ipairs(pool) do
          if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then affs[a] = true end
        end
        local c = pick(snap({ form = form, kata = 10 }, affs))
        expect(c == nil or (c:find("scythe", 1, true) == nil and c:find("batter", 1, true) == nil))
          .toBeTrue()
      end
    end
  end)

  it("equilibrium at the press does not change the pick: the free queue waits for it", function()
    local soft = set("asthma", "slickness", "anorexia")
    expect(pick(snap({ eq = true }, soft))).toBe("mind impatience Agathon")
    expect(pick(snap({ eq = false }, soft))).toBe("mind impatience Agathon")
    expect(pick(snap({ eq = false, kata = 9 }, {}))).toBe("mind impatience Agathon")
  end)

  it("nothing under the mana floor", function()
    local soft = set("asthma", "slickness", "anorexia")
    expect(pick(snap({ mpp = 24 }, soft))).toBeNil()
    expect(pick(snap({ mpp = 25 }, soft))).toBe("mind impatience Agathon")
    expect(pick(snap({ mpp = false }, soft))).toBeNil() -- no reading yet: a combo
  end)

  it("nothing while the chain needs a strike before it lapses", function()
    local c, why = pick(snap({ atRisk = true, kataIdle = 13 }, set("mangledhead", "stupidity", "impatience")))
    expect(c).toBeNil()
    expect(why:find("lapse", 1, true) ~= nil).toBeTrue()
  end)

  it("nothing while she lies down in Gaital: the kill window", function()
    expect(pick(snap({ form = "Gaital" }, set("prone", "asthma", "slickness", "anorexia")))).toBeNil()
    -- Down in another form, or standing in Gaital, Telepathy still goes out.
    expect(pick(snap({ form = "Rain" }, set("prone", "asthma", "slickness", "anorexia"))))
      .toBe("mind impatience Agathon")
    expect(pick(snap({ form = "Gaital" }, set("asthma", "slickness", "anorexia"))))
      .toBe("mind impatience Agathon")
  end)

  it("nothing while she lies down at half health in Maelstrom: 006's CRESCENT kills her", function()
    local c, why = pick(snap({ form = "Maelstrom", halfHealth = true }, set("prone", "confusion")))
    expect(c).toBeNil()
    expect(why:find("CRESCENT", 1, true) ~= nil).toBeTrue()
    expect(pick(snap({ form = "Maelstrom", halfHealth = true }, set("prone", "asthma", "slickness", "anorexia"))))
      .toBeNil()
    -- No kill there: over half health (or no fresh ASSESS), or standing, or in another form.
    expect(pick(snap({ form = "Maelstrom", halfHealth = false }, set("prone", "confusion"))))
      .toBe("mind disrupt Agathon")
    expect(pick(snap({ form = "Maelstrom", halfHealth = true }, set("confusion")))).toBe("mind disrupt Agathon")
    expect(pick(snap({ form = "Rain", halfHealth = true }, set("prone", "confusion")))).toBe("mind disrupt Agathon")
  end)

  it("MIND IMPATIENCE closes the lock in any form", function()
    expect(pick(snap({ form = "Oak" }, set("asthma", "slickness", "anorexia")))).toBe("mind impatience Agathon")
    expect(pick(snap({ form = "Oak" }, set("asthma", "slickness")))).toBeNil()
    expect(pick(snap({ form = "Oak" }, set("asthma", "slickness", "anorexia", "impatience")))).toBeNil()
  end)

  it("MIND DISRUPT on a confused target that is not disrupted", function()
    expect(pick(snap({ form = "Willow" }, set("confusion")))).toBe("mind disrupt Agathon")
    expect(pick(snap({ form = "Willow" }, set("confusion", "disrupted")))).toBeNil()
  end)
end)

describe("vv's picker: the Rain burst (011)", function()
  local pick = shikudo.telepathyPick

  it("from kata 9 in Rain: impatience first, then paralyse once impatience is on", function()
    expect(pick(snap({ kata = 9 }, {}))).toBe("mind impatience Agathon")
    expect(pick(snap({ kata = 9 }, set("impatience")))).toBe("mind paralyse Agathon")
    expect(pick(snap({ kata = 12 }, set("impatience")))).toBe("mind paralyse Agathon")
    -- She is paralysed already: nothing left to burst with.
    expect(pick(snap({ kata = 9 }, set("impatience", "paralysis")))).toBeNil()
    -- Under kata 9, or outside Rain, no burst.
    expect(pick(snap({ kata = 8 }, {}))).toBeNil()
    expect(pick(snap({ form = "Oak", kata = 9 }, {}))).toBeNil()
  end)

  it("an Apostate never gets MIND PARALYSE", function()
    expect(pick(snap({ kata = 9, class = "apostate" }, set("impatience")))).toBeNil()
    expect(pick(snap({ kata = 9, class = "apostate" }, {}))).toBe("mind impatience Agathon")
    expect(pick(snap({ kata = 9, class = "runewarden" }, set("impatience")))).toBe("mind paralyse Agathon")
  end)

  it("stops once burstMax MIND rounds have run since the last combo", function()
    expect(pick(snap({ kata = 9, burst = 3 }, {}))).toBe("mind impatience Agathon")
    expect(pick(snap({ kata = 9, burst = 4 }, {}))).toBeNil()
    -- The cap is the burst's own: a lock-closing impatience still goes out.
    expect(pick(snap({ kata = 9, burst = 4 }, set("asthma", "slickness", "anorexia"))))
      .toBe("mind impatience Agathon")
  end)
end)

describe("vv's picker: MIND BLACKOUT (011)", function()
  local pick = shikudo.telepathyPick

  it("is never picked while shikudo.tele.blackout is off", function()
    expect(shikudo.tele.blackout).toBeFalse()
    local pool = { "asthma", "slickness", "anorexia", "paralysis", "impatience", "confusion" }
    for _, fields in ipairs({ { treeUp = true }, { treeUp = false, treeLeft = 10 }, { kata = 9 } }) do
      for mask = 0, 2 ^ #pool - 1 do
        local affs = {}
        for i, a in ipairs(pool) do
          if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then affs[a] = true end
        end
        local c = pick(snap(fields, affs))
        expect(c == nil or c:find("blackout", 1, true) == nil).toBeTrue()
      end
    end
  end)

  it("with it on: bait while her tree is up and two lock pieces are on", function()
    withTele("blackout", true, function()
      expect(pick(snap({}, set("asthma", "slickness")))).toBe("mind blackout")
      expect(pick(snap({}, set("asthma")))).toBeNil()
      -- Rain only: the hidden combo waits for our equilibrium.
      expect(pick(snap({ form = "Oak" }, set("asthma", "slickness")))).toBeNil()
    end)
  end)

  it("with it on: it sticks while her tree is down for 4 s or more, or she is paralysed", function()
    withTele("blackout", true, function()
      expect(pick(snap({ treeUp = false, treeLeft = 4 }, {}))).toBe("mind blackout")
      expect(pick(snap({ treeUp = false, treeLeft = 9 }, {}))).toBe("mind blackout")
      expect(pick(snap({ treeUp = true }, set("paralysis")))).toBe("mind blackout")
      -- 2 s left on her tree and not paralysed: she trees it off. No blackout.
      expect(pick(snap({ treeUp = false, treeLeft = 2 }, {}))).toBeNil()
    end)
  end)

  it("with it on: nothing inside our own blackout, so the hidden combo goes out", function()
    withTele("blackout", true, function()
      expect(pick(snap({ blackoutAge = 2, treeUp = false, treeLeft = 9 }, set("asthma", "slickness"))))
        .toBeNil()
      expect(pick(snap({ blackoutAge = 4, treeUp = false, treeLeft = 9 }, {}))).toBe("mind blackout")
    end)
  end)

  it("with it on: never under its own mana floor", function()
    withTele("blackout", true, function()
      expect(pick(snap({ mpp = 39, treeUp = false, treeLeft = 9 }, {}))).toBeNil()
      expect(pick(snap({ mpp = 40, treeUp = false, treeLeft = 9 }, {}))).toBe("mind blackout")
    end)
  end)
end)

describe("vv's picker: the commands themselves (011)", function()
  it("only MIND commands, never the bare words sent before v4.7.417, and never a lock", function()
    local pool = { "asthma", "slickness", "anorexia", "paralysis", "impatience", "confusion",
      "disrupted", "mangledhead", "stupidity" }
    -- Both switches on, so the sweep reaches every command the picker can send.
    withTele("blackout", true, function() withTele("scythe", true, function()
      for _, form in ipairs({ "Rain", "Oak", "Willow", "Gaital" }) do
        for mask = 0, 2 ^ #pool - 1 do
          local affs = {}
          for i, a in ipairs(pool) do
            if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then affs[a] = true end
          end
          local c = shikudo.telepathyPick(snap({ form = form, kata = 10, treeUp = false, treeLeft = 6 }, affs))
          if c then
            expect(c:find("^mind ") ~= nil).toBeTrue()
            expect(c:find("mindlock", 1, true)).toBeNil()
            expect(c:find("mind lock", 1, true)).toBeNil()
          end
        end
      end
    end) end)
  end)
end)

describe("the snapshot vv's picker reads (011)", function()
  local function fresh()
    ataxia.vitals = { form = "Rain", kata = 5, eq = true, mpp = 80 }
    ataxiaTemp = {}
    tAffs = {}
    tBals = { tree = true, timers = {} }
    targetClass = "Unknown"
  end

  it("reads how long her tree is down only while tBals.tree is false (a switch resets only that)", function()
    fresh()
    ataxiaTemp.targetTreeAt = now - 9
    expect(shikudo.teleState().treeLeft).toBeNil()   -- tree up: the stamp may be the last target's
    expect(shikudo.teleState().treeUp).toBeTrue()
    tBals.tree = false
    expect(shikudo.teleState().treeLeft).toBe(4)
    expect(shikudo.teleState().treeUp).toBeFalse()
    ataxiaTemp.targetTreeAt = now - 20
    expect(shikudo.teleState().treeLeft).toBe(0)
    ataxiaTemp.targetTreeAt = nil
    expect(shikudo.teleState().treeLeft).toBeNil()
  end)

  it("puts the chain at risk only when there is a chain: monk/004's ataxia_kataAtRisk", function()
    fresh()
    ataxiaTemp.kataAt = now - 13
    local s = shikudo.teleState()
    expect(s.atRisk).toBeTrue()
    expect(s.kataIdle).toBe(13)
    -- The kata reads 0 (the lapse line, a form change): nothing to save.
    ataxia.vitals.kata = 0
    expect(shikudo.teleState().atRisk).toBeFalse()
    ataxia.vitals.kata = 5
    ataxiaTemp.kataAt = now - 5
    expect(shikudo.teleState().atRisk).toBeFalse()
    ataxiaTemp.kataAt = nil
    expect(shikudo.teleState().atRisk).toBeFalse()
  end)

  it("reads the form, kata, mana, the class in lower case, and the burst", function()
    fresh()
    ataxia.vitals.form = "rain"
    targetClass = "Apostate"
    ataxiaTemp.shikTele = { burst = 3, blackoutAt = now - 1 }
    tAffs = set("prone")
    local s = shikudo.teleState()
    expect(s.form).toBe("Rain")
    expect(s.kata).toBe(5)
    expect(s.mpp).toBe(80)
    expect(s.class).toBe("apostate")
    expect(s.burst).toBe(3)
    expect(s.blackoutAge).toBe(1)
    expect(s.prone).toBeTrue()
    expect(s.has("prone")).toBeTrue()
    expect(s.target).toBe("Agathon")
  end)

  it("reads half health as 006's Crescent does: a fresh ASSESS of this target, raw numbers", function()
    fresh()
    expect(shikudo.teleState().halfHealth).toBeFalse()                 -- no ASSESS yet
    ataxiaTemp.lastAssessHp, ataxiaTemp.lastAssessMax = 3000, 7281
    ataxiaTemp.lastAssessAt, ataxiaTemp.lastAssessWho = now - 1, "Agathon"
    expect(shikudo.teleState().halfHealth).toBeTrue()
    ataxiaTemp.lastAssessAt = now - 6                                  -- older than 5 s
    expect(shikudo.teleState().halfHealth).toBeFalse()
    ataxiaTemp.lastAssessAt, ataxiaTemp.lastAssessHp = now - 1, 3540   -- 50.6%, floored to 50
    ataxiaTemp.lastAssessMax = 7000
    expect(shikudo.teleState().halfHealth).toBeFalse()
    ataxiaTemp.lastAssessHp, ataxiaTemp.lastAssessWho = 3000, "Belaziel" -- someone else's
    expect(shikudo.teleState().halfHealth).toBeFalse()
  end)
end)

-- One press of vv: the real dispatchMind with `send` captured. Every line it sent; `send` is put
-- back even when the press throws.
local function press()
  local sent, saved = {}, send
  send = function(c) sent[#sent + 1] = c end
  local ok, err = pcall(shikudo.dispatchMind)
  send = saved
  if not ok then error(err, 0) end
  return sent
end

-- A fight: our form, kata and mana, the target's afflictions, a chain whose last strike was a
-- second ago, both of her tree and our limb readings ordinary, and no run line read yet.
local function fight(form, kata, affs)
  ataxia.vitals = { form = form, kata = kata, eq = true, mpp = 90 }
  ataxia.settings = { separator = ";" }
  ataxiaTemp = { kataAt = now - 1 }
  tAffs = affs or {}
  tBals = { tree = true, timers = {} }
  targetClass = "Unknown"
  target = "Agathon"
  combatQueue = function() return "" end
  reboundHold = nil
  lb = { Agathon = { hits = { head = 0, torso = 0, ["left arm"] = 10, ["right arm"] = 30,
    ["left leg"] = 10, ["right leg"] = 30 } } }
end

local SOFT = { "asthma", "slickness", "anorexia" }

-- `fn` with shikudo.dispatch counted; the real one still runs. Returns the call count.
local function countingDispatch(fn)
  local real, calls = shikudo.dispatch, 0
  shikudo.dispatch = function(...) calls = calls + 1; return real(...) end
  local ok, err = pcall(fn)
  shikudo.dispatch = real
  if not ok then error(err, 0) end
  return calls
end

describe("vv's rounds: a MIND command goes out alone (011)", function()
  it("a MIND pick sends exactly one line: the command and ASSESS, no combo, no transition", function()
    fight("Rain", 9, set(unpack(SOFT)))
    local sent
    local calls = countingDispatch(function() sent = press() end)
    expect(calls).toBe(0)
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("queue addclear free mind impatience Agathon;assess Agathon")
    expect(sent[1]:find("combo", 1, true)).toBeNil()
    expect(sent[1]:find("transition", 1, true)).toBeNil()
  end)

  it("combatQueue's prefix leads it, and the shield option wields the shield first", function()
    fight("Rain", 9, set(unpack(SOFT)))
    combatQueue = function() return "g body;g gold;stand;" end
    expect(press()[1]).toBe("queue addclear free g body;g gold;stand;mind impatience Agathon;assess Agathon")
    withTele("shield", "shield", function()
      fight("Rain", 9, set(unpack(SOFT)))
      expect(press()[1]).toBe("queue addclear free wield shield;mind impatience Agathon;assess Agathon")
    end)
  end)

  it("drops ASSESS when 006's rounds do", function()
    fight("Rain", 9, set(unpack(SOFT)))
    local saved = shikudo.config.assessEachRound
    shikudo.config.assessEachRound = false
    local ok, err = pcall(function()
      expect(press()[1]).toBe("queue addclear free mind impatience Agathon")
    end)
    shikudo.config.assessEachRound = saved
    if not ok then error(err, 0) end
  end)

  it("the kill goes to shikudo.dispatch(), even over a scythe, and no MIND line goes out", function()
    -- Rain, so the picker's own Gaital gate is not what stops the MIND round; the scythe switched
    -- on, so a MIND round really is on offer.
    withTele("scythe", true, function()
      fight("Rain", 6, set("prone", "crushedthroat", "damagedhead", "mangledhead", "stupidity", "impatience"))
      expect(shikudo.telepathyPick(shikudo.teleState())).toBe("mind scythe Agathon")
      local sent
      local calls = countingDispatch(function() sent = press() end)
      expect(calls).toBe(1)
      expect(#sent).toBe(1)
      expect(sent[1]).toBe("queue addclear free wield staff;dispatch Agathon")
    end)
  end)

  it("down at half health in Maelstrom, vv sends 006's CRESCENT, not a MIND round", function()
    -- The review's case: a confused target would have drawn MIND DISRUPT, a softlocked one MIND
    -- IMPATIENCE, each a round in which she could stand up out of the kill.
    for _, affs in ipairs({ set("prone", "confusion"), set("prone", unpack(SOFT)) }) do
      fight("Maelstrom", 6, affs)
      ataxiaTemp.lastAssessHp, ataxiaTemp.lastAssessMax = 3000, 7281
      ataxiaTemp.lastAssessAt, ataxiaTemp.lastAssessWho = now - 1, "Agathon"
      local sent
      local calls = countingDispatch(function() sent = press() end)
      expect(calls).toBe(1)
      expect(#sent).toBe(1)
      expect(sent[1]:find("combo Agathon crescent", 1, true) ~= nil).toBeTrue()
      expect(sent[1]:find("mind ", 1, true)).toBeNil()
    end
  end)

  it("a shield goes to shikudo.dispatch(): SHATTER first", function()
    fight("Rain", 9, set("shield", unpack(SOFT)))
    local sent
    local calls = countingDispatch(function() sent = press() end)
    expect(calls).toBe(1)
    expect(#sent).toBe(1)
    expect(sent[1]:find("combo Agathon shatter", 1, true) ~= nil).toBeTrue()
    expect(sent[1]:find("mind ", 1, true)).toBeNil()
  end)

  it("no pick goes to shikudo.dispatch(), and ends the burst", function()
    fight("Oak", 3, {})
    ataxiaTemp.shikTele = { burst = 3 }
    local sent
    local calls = countingDispatch(function() sent = press() end)
    expect(calls).toBe(1)
    expect(sent[1]:find("combo Agathon", 1, true) ~= nil).toBeTrue()
    expect(ataxiaTemp.shikTele.burst).toBe(0)
  end)

  it("until a run line is read, each press counts toward the burst cap", function()
    fight("Rain", 9, {})
    for i = 1, 4 do
      expect(press()[1]).toBe("queue addclear free mind impatience Agathon;assess Agathon")
      expect(ataxiaTemp.shikTele.burst).toBe(i)
    end
    expect(press()[1]:find("combo Agathon", 1, true) ~= nil).toBeTrue()
    expect(ataxiaTemp.shikTele.burst).toBe(0)
    expect(press()[1]).toBe("queue addclear free mind impatience Agathon;assess Agathon")
  end)

  it("a live chain 13 s past its last strike gets the combo; a chain that reads 0 blocks nothing", function()
    fight("Rain", 9, set(unpack(SOFT)))
    ataxiaTemp.kataAt = now - 13
    expect(press()[1]:find("combo Agathon", 1, true) ~= nil).toBeTrue()
    -- The lapse line or a form change zeroed the kata: there is no chain to save (monk/004).
    fight("Rain", 0, set(unpack(SOFT)))
    ataxiaTemp.kataAt = now - 13
    expect(press()[1]).toBe("queue addclear free mind impatience Agathon;assess Agathon")
  end)

  it("stamps the MIND round it queued: when, what, the form", function()
    fight("Rain", 9, {})
    press()
    local st = ataxiaTemp.shikTele
    expect(st.at).toBe(now)
    expect(st.cmd).toBe("mind impatience Agathon")
    expect(st.form).toBe("Rain")
    expect(st.blackoutAt).toBeNil()
  end)

  it("a Deliverance target dropped by combatQueue gets 006's round, never the old target's MIND", function()
    fight("Rain", 9, set(unpack(SOFT)))
    local switched = false
    combatQueue = function()
      if not switched then switched = true; target = "Belaziel" end
      return ""
    end
    local sent = press()
    for _, line in ipairs(sent) do
      expect(line:find("mind ", 1, true)).toBeNil()
      expect(line:find("Agathon", 1, true)).toBeNil()
    end
    expect(sent[#sent]:find("combo Belaziel", 1, true) ~= nil).toBeTrue()
  end)

  it("reboundHold may hold the round, and lets go into vv again", function()
    fight("Rain", 9, set(unpack(SOFT)))
    local held
    reboundHold = { gate = function(fn) held = fn; return true end }
    expect(#press()).toBe(0)
    expect(held).toBe(shikudo.dispatchMind)
  end)

  it("no target: nothing goes out", function()
    fight("Rain", 9, set(unpack(SOFT)))
    target = ""
    local sent
    local calls = countingDispatch(function() sent = press() end)
    expect(#sent).toBe(0)
    expect(calls).toBe(0)
    target = "Agathon"
  end)

  it("never sends a bare impatience or paralyse, or a lock, in any state", function()
    local pool = { "asthma", "slickness", "anorexia", "paralysis", "impatience", "confusion", "prone" }
    for _, form in ipairs({ "Rain", "Oak", "Gaital" }) do
      for mask = 0, 2 ^ #pool - 1 do
        local affs = {}
        for i, a in ipairs(pool) do
          if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then affs[a] = true end
        end
        fight(form, 9, affs)
        for _, line in ipairs(press()) do
          local bare = line:gsub("mind impatience", ""):gsub("mind paralyse", "")
          expect(bare:find("impatience", 1, true)).toBeNil()
          expect(bare:find("paralyse", 1, true)).toBeNil()
          expect(line:find("mindlock", 1, true)).toBeNil()
          expect(line:find("mind lock", 1, true)).toBeNil()
        end
      end
    end
  end)
end)

local TL = dofile("src_new/tests/trigger_lib.lua")
local MOCK = package.loaded["mock_mudlet"] or require("mock_mudlet")

-- The temp triggers registered with the mock under 011's run-line pattern.
local function runTriggers()
  local found = {}
  for _, t in pairs(MOCK.active_triggers) do
    if t.pattern == shikudo.TELE_RAN_PATTERN then found[#found + 1] = t end
  end
  return found
end

-- The game runs `sent` (a whole "queue addclear free ..." or "queue add free ..." command). It
-- prints "[System]: Running queued free command: <round>" -- upper-cased here, since its case is
-- not known and queue_Scan lower-cases it -- wrapped at `width` (default 120), and the trigger sees
-- the FIRST row through 011's real pattern (trigger_lib) and its real callback. True when 011 took
-- it as the MIND round it had pending.
local function ran(sent, width)
  local round = sent:gsub("^queue addclear free ", ""):gsub("^queue add free ", "")
  local row = TL.wrap("[System]: Running queued free command: " .. round:upper(), width or 120)[1]
  expect(TL.matches(shikudo.TELE_RAN_PATTERN, 1, row)).toBeTrue()
  local trig = runTriggers()
  expect(#trig).toBe(1)
  local had, saved = ataxiaTemp.shikTele and ataxiaTemp.shikTele.pending, matches
  matches = { row, row:match("^%[System%]: Running queued %w+ command: (.+)$") }
  local ok, err = pcall(trig[1].callback)
  matches = saved
  if not ok then error(err, 0) end
  return had ~= nil and ataxiaTemp.shikTele.pending == nil
end

local function burst() return ataxiaTemp.shikTele.burst end

-- A fight in which a run line has already been read for one of our rounds: from here on the burst
-- moves only when a round runs. Returns the MIND line that ran (counted once: burst 1).
local function readingRunLines(form, kata, affs)
  fight(form, kata, affs)
  local line = press()[1]
  expect(line:find("mind ", 1, true) ~= nil).toBeTrue()
  expect(ran(line)).toBeTrue()
  expect(ataxiaTemp.shikTele.runLine).toBeTrue()
  expect(burst()).toBe(1)
  return line
end

describe("vv's burst moves when the game RUNS a round, not when vv is pressed (011)", function()
  it("pressing again before a MIND round runs queues the same round and counts nothing", function()
    local line = readingRunLines("Rain", 9, {})
    for _ = 1, 3 do expect(press()[1]).toBe(line) end
    expect(burst()).toBe(1)
    expect(ran(line)).toBeTrue()
    expect(burst()).toBe(2)
  end)

  it("at the cap the combo stays queued, however often vv is pressed, until it runs", function()
    local line = readingRunLines("Rain", 9, {})
    for i = 2, 4 do
      expect(press()[1]).toBe(line)
      expect(ran(line)).toBeTrue()
      expect(burst()).toBe(i)
    end
    local combo = press()[1]
    expect(combo:find("combo Agathon", 1, true) ~= nil).toBeTrue()
    for _ = 1, 3 do expect(press()[1]).toBe(combo) end
    expect(burst()).toBe(4)
    expect(ran(combo)).toBeFalse() -- not the MIND round: but a combo ran, so the burst is over
    expect(burst()).toBe(0)
    expect(press()[1]).toBe(line)
  end)

  it("a run line is matched from its first row, wherever the server wraps it", function()
    for _, width in ipairs({ 100, 119, 124, 200 }) do
      fight("Rain", 9, {})
      combatQueue = function() return "g body;g gold;stand;" end
      local line = press()[1]
      expect(line).toBe("queue addclear free g body;g gold;stand;mind impatience Agathon;assess Agathon")
      expect(ran(line, width)).toBeTrue()
      ataxiaTemp.shikTele.burst = 3
      local combo = "queue addclear free g body;g gold;stand;wield staff;combo Agathon frontkick left"
        .. " kuro left ruku left transition oak;assess Agathon"
      local rows = TL.wrap("[System]: Running queued free command: " .. combo:sub(#"queue addclear free " + 1), width)
      expect(#rows > 1 or width == 200).toBeTrue() -- the combo's run line really wraps
      ran(combo, width)
      expect(burst()).toBe(0)
    end
  end)

  -- The test above wraps only the combo: its MIND line is 97 columns and never wraps. A MIND round
  -- does wrap once combatQueue adds a parry (ataxia/003_Queueing_Related.lua:70-72) and the name is
  -- long, and only the first row reaches the trigger, so the round is matched by its prefix.
  it("a MIND round whose own run line wraps is counted from its first row", function()
    local ok, err = pcall(function()
      for _, width in ipairs({ 100, 119 }) do
        readingRunLines("Rain", 9, {})                      -- burst 1; only run lines count now
        target = "Xenophontes"
        combatQueue = function() return "g body;g gold;stand; ; parry right leg;" end
        local line = press()[1]
        expect(line).toBe("queue addclear free g body;g gold;stand; ; parry right leg;"
          .. "mind impatience Xenophontes;assess Xenophontes")
        local runLine = "[System]: Running queued free command: " .. line:sub(#"queue addclear free " + 1)
        expect(#runLine).toBe(124)
        expect(#TL.wrap(runLine, width) > 1).toBeTrue()     -- it really wraps
        expect(burst()).toBe(1)
        expect(ran(line, width)).toBeTrue()
        expect(burst()).toBe(2)
        expect(ataxiaTemp.shikTele.pending).toBeNil()
      end
    end)
    target, combatQueue = "Agathon", function() return "" end
    if not ok then error(err, 0) end
  end)

  it("another command's run line moves nothing, a target's name included", function()
    readingRunLines("Rain", 9, {})
    local line = press()[1]
    expect(ran("queue addclear free mind sense Agathon")).toBeFalse()
    expect(ran("queue addclear free kai choke Agathon;assess Agathon")).toBeFalse()
    target = "Combolith"
    expect(ran("queue addclear free mind impatience Combolith;assess Combolith")).toBeFalse()
    target = "Agathon"
    expect(burst()).toBe(1)
    expect(ran(line)).toBeTrue()
    expect(burst()).toBe(2)
    expect(ran(line)).toBeFalse() -- nothing pending any more
    expect(burst()).toBe(2)
  end)

  it("a combo press drops the MIND round it replaced: the same line run by sr later is not vv's", function()
    local line = readingRunLines("Rain", 9, {})
    expect(press()[1]).toBe(line)                       -- queued, then replaced by a combo:
    tAffs = set("impatience", "paralysis")
    expect(press()[1]:find("combo Agathon", 1, true) ~= nil).toBeTrue()
    expect(ran(line)).toBeFalse()                       -- 007 queued the identical MIND round
    expect(burst()).toBe(1)
  end)

  it("the blackout and the combo it hides go out together, and the window opens when it RUNS", function()
    withTele("blackout", true, function()
      readingRunLines("Rain", 3, set(unpack(SOFT)))   -- impatience closed the lock and ran
      tAffs.impatience = true
      tBals.tree = false
      ataxiaTemp.targetTreeAt = now - 4                  -- her tree is down for 9 s more
      local sent = press()
      expect(#sent).toBe(2)
      expect(sent[1]).toBe("queue addclear free mind blackout;assess Agathon")
      expect(sent[2]:find("^queue add free wield staff;combo Agathon ") ~= nil).toBeTrue()
      expect(sent[2]:find("mind ", 1, true)).toBeNil()
      expect(ataxiaTemp.shikTele.blackoutAt).toBeNil() -- not run yet: pressing again re-sends both
      local again = press()
      expect(again[1]).toBe(sent[1])
      expect(ran(sent[1])).toBeTrue()
      expect(ataxiaTemp.shikTele.blackoutAt).toBe(now)
      expect(burst()).toBe(2)
      -- Inside the window vv sends 006's combo in place of the hidden one, then the hidden combo
      -- that ran ends the burst.
      now = now + 2
      local inside = press()
      expect(#inside).toBe(1)
      expect(inside[1]:find("^queue addclear free wield staff;combo Agathon ") ~= nil).toBeTrue()
      ran(sent[2])
      expect(burst()).toBe(0)
      now = now + 2
      expect(press()[1]).toBe("queue addclear free mind blackout;assess Agathon")
    end)
  end)

  it("until a run line is read, a blackout opens its window at the press", function()
    withTele("blackout", true, function()
      fight("Rain", 3, set("paralysis"))
      local sent = press()
      expect(sent[1]).toBe("queue addclear free mind blackout;assess Agathon")
      expect(ataxiaTemp.shikTele.blackoutAt).toBe(now)
    end)
  end)

  it("with blackout off, the same fight sends no blackout and no second line", function()
    fight("Rain", 9, set("asthma", "slickness", "impatience"))
    tBals.tree = false
    ataxiaTemp.targetTreeAt = now - 4
    local sent = press()
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("queue addclear free mind paralyse Agathon;assess Agathon")
  end)

  it("the run-line trigger is registered once, and a reload replaces it", function()
    expect(#runTriggers()).toBe(1)
    local oldId
    for id, t in pairs(MOCK.active_triggers) do
      if t.pattern == shikudo.TELE_RAN_PATTERN then oldId = id end
    end
    local savedTemp = ataxiaTemp
    ataxiaTemp = { shikTeleRunTrigger = oldId }
    local ok, err = pcall(dofile, TELE)
    local newId = ataxiaTemp.shikTeleRunTrigger
    ataxiaTemp = savedTemp
    if not ok then error(err, 0) end
    expect(MOCK.active_triggers[oldId]).toBeNil()
    expect(#runTriggers()).toBe(1)
    expect(newId ~= nil and newId ~= oldId).toBeTrue()
  end)
end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
