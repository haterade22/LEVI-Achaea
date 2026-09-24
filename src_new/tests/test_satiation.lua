--- test_satiation.lua -- Healing Metabolism alone: hold "utterly satiated" off the horn (v4.7.303)
--
-- User: "When we have this boon we need to be full satiation. I have a horn which produces
-- food ... Get loaf from horn / eat loaf / If HUNGER is lower than utterly satiated."
--
-- Three ways to notice hunger (the SCORE row, the satiation defence leaving GMCP, a kill-driven
-- SCORE when the reading is stale), one feed path (`ataxia_hornSatiate`, corpse first when
-- Obligate Carnivore is held, else the proven horn probe), every feed VERIFIED by a follow-up
-- SCORE and re-fed if still short -- bounded per episode so an empty horn cannot spend charges
-- forever. Loads the real misc_scripts/022_Horn_Of_Plenty.lua.
--
-- Files share ONE Lua state: everything touched here is saved at the top and restored at the end.

local mock = require("mock_mudlet")

local _saved = {
  send = send, getEpoch = getEpoch, ataxiaEcho = ataxiaEcho,
  tempRegexTrigger = tempRegexTrigger, tempTimer = tempTimer,
  killTrigger = killTrigger, killTimer = killTimer, matches = matches, gmcp = gmcp,
  mnemObligateCarnivore = mnemObligateCarnivore, mnemHealingMetabolism = mnemHealingMetabolism,
  mnemFamine = mnemFamine,
  ataxiaTemp = ataxiaTemp, ataxiaSettings = ataxia and ataxia.settings,
}

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.separator = ";"
ataxia.settings.satiatePoll = nil
ataxiaTemp = {}

local sent, NOW, armed, timers, timerId = {}, 1000, nil, {}, 0
send = function(c) sent[#sent + 1] = c end
getEpoch = function() return NOW end
ataxiaEcho = function() end
tempRegexTrigger = function(_, fn) armed = fn; return 1 end
tempTimer = function(delay, fn) timerId = timerId + 1; timers[timerId] = { delay = delay, fn = fn }; return timerId end
killTrigger = function() end
killTimer = function(id) timers[id] = nil end

-- A clean handler table BEFORE the load, so exactly ONE Defences.Remove handler is registered
-- (test_carnivore.lua already loaded this file once into the mock's previous table).
mock.reset()
dofile("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/022_Horn_Of_Plenty.lua")

local function reset()
  sent, NOW, armed, timers, timerId = {}, 1000, nil, {}, 0
  ataxiaTemp = {}
  ataxia.settings.satiatePoll = nil
  mnemObligateCarnivore, mnemHealingMetabolism, mnemFamine = false, false, false
  gmcp = { Char = { Defences = { Remove = {} } } }
end

local function sentAny(needle)
  for _, c in ipairs(sent) do if c:find(needle, 1, true) then return true end end
  return false
end
local function sentCount(needle)
  local n = 0
  for _, c in ipairs(sent) do if c:find(needle, 1, true) then n = n + 1 end end
  return n
end

-- The horn listing row `probe horn` prints -- the same shape ataxia_hornFeed has parsed all along.
local function listHorn(id, what)
  matches = { '"' .. id .. '"      ' .. what, id, what }
  armed()
end

-- Fire every pending timer whose callback is a function (snapshot first, the mock's own rule).
local function fireTimers()
  local ids = {}
  for id in pairs(timers) do ids[#ids + 1] = id end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local t = timers[id]
    if t then timers[id] = nil; t.fn() end
  end
end

describe("Healing Metabolism upkeep -- the SCORE hunger row decides", function()
  it("'utterly satiated' closes the episode and sends nothing", function()
    reset(); mnemHealingMetabolism = true
    ataxiaTemp.satiateChain, ataxiaTemp.satiateChainAt = 2, NOW
    expect(ataxia_hungerSeen("utterly satiated")).toBe("satiated")
    expect(#sent).toBe(0)
    expect(ataxiaTemp.satiateChain).toBeNil()
    expect(ataxiaTemp.hungerState).toBe("utterly satiated")
  end)

  it("anything lower feeds off the horn -- probe, then get+eat the first item listed", function()
    reset(); mnemHealingMetabolism = true
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")
    expect(sentAny("probe horn")).toBeTrue()
    listHorn("loaf479025", "a small loaf of waybread")
    expect(sentAny("get loaf479025 from horn;eat loaf479025")).toBeTrue()
  end)

  it("does nothing below satiated WITHOUT the boon", function()
    reset()
    expect(ataxia_hungerSeen("hungry")).toBeFalse()
    expect(#sent).toBe(0)
    expect(ataxiaTemp.hungerState).toBe("hungry") -- still recorded: a reading is a reading
  end)

  it("emergency states take the starvation path whether or not any boon is held", function()
    reset()
    expect(ataxia_hungerSeen("famished")).toBe("emergency")
    expect(sentAny("probe horn")).toBeTrue()
    reset()
    expect(ataxia_hungerSeen("starving to death")).toBe("emergency")
    expect(sentAny("probe horn")).toBeTrue()
  end)

  it("tolerates the row's padding and case", function()
    reset(); mnemHealingMetabolism = true
    expect(ataxia_hungerSeen("  Utterly Satiated  ")).toBe("satiated")
    expect(#sent).toBe(0)
  end)
end)

describe("Healing Metabolism upkeep -- every feed is verified, and the chain is bounded", function()
  it("arms a confirming SCORE after the feed", function()
    reset(); mnemHealingMetabolism = true
    ataxia_hungerSeen("hungry")
    local verify
    for _, t in pairs(timers) do if t.delay == 6 then verify = t end end
    expect(verify ~= nil).toBeTrue()
    verify.fn()
    expect(sentAny("score")).toBeTrue()
  end)

  it("the confirming SCORE does not fire once the boon is gone", function()
    reset(); mnemHealingMetabolism = true
    ataxia_hungerSeen("hungry")
    sent = {}
    mnemHealingMetabolism = false
    fireTimers()
    expect(sentAny("score")).toBeFalse()
  end)

  -- One loaf may not climb the whole ladder. A row still below satiated after the verify feeds
  -- again, FORCED past the horn's 20s cooldown -- and stops at the chain bound.
  it("re-feeds on a still-short reading past the horn cooldown, three times, then waits", function()
    reset(); mnemHealingMetabolism = true
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")           -- 1
    NOW = NOW + 6
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")           -- 2, inside the 20s cooldown
    NOW = NOW + 6
    expect(ataxia_hungerSeen("peckish")).toBe("upkeep")          -- 3
    NOW = NOW + 6
    expect(ataxia_hungerSeen("peckish")).toBeFalse()             -- budget spent
    expect(sentCount("probe horn")).toBe(3)
    -- a fresh "utterly satiated" reopens the budget
    expect(ataxia_hungerSeen("utterly satiated")).toBe("satiated")
    NOW = NOW + 30
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")
    expect(sentCount("probe horn")).toBe(4)
  end)

  it("a spent chain expires with the episode, so silence cannot lock the upkeep out", function()
    reset(); mnemHealingMetabolism = true
    for _ = 1, 3 do ataxia_hungerSeen("hungry"); NOW = NOW + 6 end
    expect(ataxia_hungerSeen("hungry")).toBeFalse()
    NOW = NOW + 301
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")
  end)

  it("a corpse outranks the horn when Obligate Carnivore is held, and a closed corpse throttle falls through", function()
    reset(); mnemHealingMetabolism, mnemObligateCarnivore = true, true
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")
    expect(sentAny("ii corpse")).toBeTrue()
    expect(sentAny("probe horn")).toBeFalse()
    sent = {}; NOW = NOW + 6
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")  -- corpse throttle (45s) is closed...
    expect(sentAny("ii corpse")).toBeFalse()
    expect(sentAny("probe horn")).toBeTrue()            -- ...so the horn takes it
  end)
end)

describe("Healing Metabolism upkeep -- the satiation defence leaving GMCP", function()
  it("feeds when a defence named like 'satiation' is removed", function()
    reset(); mnemHealingMetabolism = true
    gmcp.Char.Defences.Remove = { "satiation" }
    raiseEvent("gmcp.Char.Defences.Remove")
    expect(sentCount("probe horn")).toBe(1) -- exactly once: one handler, one feed
  end)

  it("matches by substring, case-insensitively -- the exact GMCP name is unverified", function()
    reset(); mnemHealingMetabolism = true
    gmcp.Char.Defences.Remove = { "Satiated" }
    raiseEvent("gmcp.Char.Defences.Remove")
    expect(sentAny("probe horn")).toBeTrue()
  end)

  it("ignores every other defence, and does nothing without the boon", function()
    reset(); mnemHealingMetabolism = true
    gmcp.Char.Defences.Remove = { "speed" }
    raiseEvent("gmcp.Char.Defences.Remove")
    expect(#sent).toBe(0)
    reset()
    gmcp.Char.Defences.Remove = { "satiation" }
    raiseEvent("gmcp.Char.Defences.Remove")
    expect(#sent).toBe(0)
  end)
end)

describe("Healing Metabolism upkeep -- the kill-driven SCORE backstop", function()
  it("asks SCORE on a kill when the last reading is stale, once per poll window", function()
    reset(); mnemHealingMetabolism = true
    expect(ataxia_satiateKillCheck()).toBeTrue()
    expect(sentCount("score")).toBe(1)
    expect(ataxia_satiateKillCheck()).toBeFalse()       -- same window
    NOW = NOW + 299
    expect(ataxia_satiateKillCheck()).toBeFalse()
    NOW = NOW + 2
    expect(ataxia_satiateKillCheck()).toBeTrue()
    expect(sentCount("score")).toBe(2)
  end)

  it("does not ask while the reading is fresh", function()
    reset(); mnemHealingMetabolism = true
    ataxia_hungerSeen("utterly satiated")               -- a reading at NOW
    NOW = NOW + 100
    expect(ataxia_satiateKillCheck()).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("is off without the boon, with both boons (the corpse top-up is blind and free), and at poll 0", function()
    reset()
    expect(ataxia_satiateKillCheck()).toBeFalse()
    reset(); mnemHealingMetabolism, mnemObligateCarnivore = true, true
    expect(ataxia_satiateKillCheck()).toBeFalse()
    reset(); mnemHealingMetabolism = true; ataxia.settings.satiatePoll = 0
    expect(ataxia_satiateKillCheck()).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("honours a configured window", function()
    reset(); mnemHealingMetabolism = true; ataxia.settings.satiatePoll = 60
    expect(ataxia_satiateKillCheck()).toBeTrue()
    NOW = NOW + 61
    expect(ataxia_satiateKillCheck()).toBeTrue()
  end)
end)

describe("the starvation path's 5s re-fire throttle now lives in ataxia_hornOnHungry", function()
  it("swallows a repeat inside 5s and fires again after", function()
    reset()
    expect(ataxia_hornOnHungry("famished")).toBeTrue()
    NOW = NOW + 2
    expect(ataxia_hornOnHungry("famished")).toBeFalse()
    NOW = NOW + 4
    ataxiaTemp.hornFedAt = nil -- the horn's own 20s cooldown is a separate question
    expect(ataxia_hornOnHungry("famished")).toBeTrue()
  end)
end)

-- ---------------------------------------------------------------------------
-- FAMINE (v4.7.333). User, from a live status screen: "Famine: Taking damage has a chance to make
-- you more hungry, and your healing received from elixirs, moss, and potash is reduced by 20%." --
-- "When we have this we need to eat to full every room."
-- ---------------------------------------------------------------------------
describe("the Famine affix feeds on the room's clock, boon or no boon", function()
  it("opens the upkeep feed with no boon held at all", function()
    reset()
    expect(ataxia_hornSatiate("no affix")).toBeFalse() -- nothing holds it open...
    mnemFamine = true
    expect(ataxia_hornSatiate("famine")).toBeTrue()    -- ...the affix does
    expect(sentAny("probe horn")).toBeTrue()
  end)

  it("tops up per room, and does nothing when the affix is down", function()
    reset()
    expect(ataxia_famineTopUp()).toBeFalse()
    mnemFamine = true
    expect(ataxia_famineTopUp()).toBeTrue()
    expect(sentAny("probe horn")).toBeTrue()
  end)

  it("eats the corpse instead of a horn charge when corpses are edible", function()
    reset()
    mnemFamine, mnemObligateCarnivore = true, true
    expect(ataxia_famineTopUp()).toBeTrue()
    expect(sentAny("ii corpse")).toBeTrue()    -- free food first
    expect(sentAny("probe horn")).toBeFalse()
  end)

  it("still verifies with SCORE, so it can chain until full", function()
    reset()
    mnemFamine = true
    expect(ataxia_hornSatiate("famine")).toBeTrue()
    for _, t in pairs(timers) do t.fn() end
    expect(sentAny("score")).toBeTrue()
  end)

  it("a kill under Famine takes a corpse even without Healing Metabolism", function()
    reset()
    mnemObligateCarnivore = true
    expect(ataxia_carnivoreTopUp()).toBeFalse() -- the boon pair is what normally opens this
    mnemFamine = true
    expect(ataxia_carnivoreTopUp()).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us.
send, getEpoch, ataxiaEcho = _saved.send, _saved.getEpoch, _saved.ataxiaEcho
tempRegexTrigger, tempTimer = _saved.tempRegexTrigger, _saved.tempTimer
killTrigger, killTimer, matches, gmcp = _saved.killTrigger, _saved.killTimer, _saved.matches, _saved.gmcp
mnemObligateCarnivore, mnemHealingMetabolism = _saved.mnemObligateCarnivore, _saved.mnemHealingMetabolism
mnemFamine = _saved.mnemFamine
ataxiaTemp = _saved.ataxiaTemp or {}
if _saved.ataxiaSettings then ataxia.settings = _saved.ataxiaSettings end
mock.reset()
