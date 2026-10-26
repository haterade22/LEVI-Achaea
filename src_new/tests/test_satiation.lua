--- test_satiation.lua -- satiation and hunger upkeep (misc_scripts/022_Horn_Of_Plenty.lua)
--
-- HEALING METABOLISM (v4.7.452): "Your health elixirs are 50% more effective while you possess the
-- satiation defence." The defence is the Survival skill SATIATION (4s eq, 100 mana) followed by a
-- meal in its short window. `ataxia_satiationTick` runs on gmcp.Char.Vitals and sends ONE chain,
-- `satiation;eat <corpse>` or `satiation;get <id> from horn;eat <id>`, when the defence is absent,
-- eq is free and the mana floor holds. GMCP Defences.Add confirms; 3 unconfirmed attempts back off.
--
-- FAMINE keeps the v4.7.303 hunger-row upkeep: below "utterly satiated" it feeds, verifies with
-- SCORE, and is bounded per episode. Loads the real misc_scripts/022_Horn_Of_Plenty.lua.
--
-- Files share ONE Lua state: everything touched here is saved at the top and restored at the end.

local mock = require("mock_mudlet")

local _saved = {
  send = send, getEpoch = getEpoch, ataxiaEcho = ataxiaEcho,
  tempRegexTrigger = tempRegexTrigger, tempTimer = tempTimer,
  killTrigger = killTrigger, killTimer = killTimer, matches = matches, gmcp = gmcp,
  mnemObligateCarnivore = mnemObligateCarnivore, mnemHealingMetabolism = mnemHealingMetabolism,
  mnemFamine = mnemFamine, affed = affed,
  ataxiaTemp = ataxiaTemp, ataxiaSettings = ataxia and ataxia.settings,
  ataxiaDefences = ataxia and ataxia.defences,
}

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.separator = ";"
ataxiaTemp = {}

local sent, NOW, armed, timers, timerId = {}, 1000, nil, {}, 0
local affs = {}
send = function(c) sent[#sent + 1] = c end
getEpoch = function() return NOW end
ataxiaEcho = function() end
tempRegexTrigger = function(_, fn) armed = fn; return 1 end
tempTimer = function(delay, fn) timerId = timerId + 1; timers[timerId] = { delay = delay, fn = fn }; return timerId end
killTrigger = function() end
killTimer = function(id) timers[id] = nil end
affed = function(a) return affs[a] == true end

-- A clean handler table BEFORE the load, so exactly ONE handler per event is registered
-- (test_carnivore.lua already loaded this file once into the mock's previous table).
mock.reset()
dofile("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/022_Horn_Of_Plenty.lua")

local function vitals(eq, mp, maxmp)
  gmcp.Char.Vitals = { eq = eq or "1", mp = tostring(mp or 5000), maxmp = tostring(maxmp or 5000) }
end

local function reset()
  sent, NOW, armed, timers, timerId = {}, 1000, nil, {}, 0
  affs = {}
  ataxiaTemp = {}
  ataxia.settings.satiationManaFloor = nil
  ataxia.defences = {}
  mnemObligateCarnivore, mnemHealingMetabolism, mnemFamine = false, false, false
  gmcp = { Char = { Defences = { Remove = {}, Add = {} } } }
  vitals()
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

-- The `ii corpse` row shape (733_Corpse_Found).
local function listCorpse(id, what)
  matches = { "  " .. id .. "the corpse of " .. what, id, what }
  armed()
end

-- Fire pending timers (optionally only those of one delay); snapshot first, the mock's own rule.
local function fireTimers(onlyDelay)
  local ids = {}
  for id in pairs(timers) do ids[#ids + 1] = id end
  table.sort(ids)
  for _, id in ipairs(ids) do
    local t = timers[id]
    if t and (not onlyDelay or t.delay == onlyDelay) then timers[id] = nil; t.fn() end
  end
end

describe("Healing Metabolism -- SATIATION, then food, in one chain", function()
  it("probes the horn, then sends satiation;get;eat on the listed item", function()
    reset(); mnemHealingMetabolism = true
    expect(ataxia_satiationTick()).toBeTrue()
    expect(sentAny("probe horn")).toBeTrue()
    listHorn("loaf479025", "a small loaf of waybread")
    expect(sentAny("satiation;get loaf479025 from horn;eat loaf479025")).toBeTrue()
  end)

  it("eats a corpse with Obligate Carnivore: satiation;eat <id>", function()
    reset(); mnemHealingMetabolism, mnemObligateCarnivore = true, true
    expect(ataxia_satiationTick()).toBeTrue()
    expect(sentAny("ii corpse")).toBeTrue()
    expect(sentAny("probe horn")).toBeFalse()
    listCorpse("corpse12345", "a rat")
    expect(sentAny("satiation;eat corpse12345")).toBeTrue()
  end)

  it("falls back to the horn when the corpse probe lists nothing", function()
    reset(); mnemHealingMetabolism, mnemObligateCarnivore = true, true
    ataxia_satiationTick()
    fireTimers(3)                                -- the corpse probe timeout, nothing listed
    expect(sentAny("probe horn")).toBeTrue()
    listHorn("pork528142", "a slab of roast pork")
    expect(sentAny("satiation;get pork528142 from horn;eat pork528142")).toBeTrue()
  end)

  it("runs from gmcp.Char.Vitals", function()
    reset(); mnemHealingMetabolism = true
    raiseEvent("gmcp.Char.Vitals")
    expect(sentCount("probe horn")).toBe(1)
  end)
end)

describe("Healing Metabolism -- the gates", function()
  it("does nothing without the boon", function()
    reset()
    expect(ataxia_satiationTick()).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("does nothing while the defence is up", function()
    reset(); mnemHealingMetabolism = true; ataxia.defences.satiation = true
    expect(ataxia_satiationTick()).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("waits for equilibrium", function()
    reset(); mnemHealingMetabolism = true; vitals("0")
    expect(ataxia_satiationTick()).toBeFalse()
  end)

  it("keeps the mana floor after the 100-mana cost (default 30%)", function()
    reset(); mnemHealingMetabolism = true; vitals("1", 1599, 5000)  -- 1499 left < 1500
    expect(ataxia_satiationTick()).toBeFalse()
    vitals("1", 1600, 5000)                                          -- 1500 left
    expect(ataxia_satiationTick()).toBeTrue()
  end)

  it("honours a configured floor", function()
    reset(); mnemHealingMetabolism = true; ataxia.settings.satiationManaFloor = 0
    vitals("1", 100, 5000)
    expect(ataxia_satiationTick()).toBeTrue()
  end)

  it("does not try while anorexic or paralysed", function()
    reset(); mnemHealingMetabolism = true; affs.anorexia = true
    expect(ataxia_satiationTick()).toBeFalse()
    reset(); mnemHealingMetabolism = true; affs.paralysis = true
    expect(ataxia_satiationTick()).toBeFalse()
  end)

  it("sends one attempt at a time", function()
    reset(); mnemHealingMetabolism = true
    expect(ataxia_satiationTick()).toBeTrue()
    NOW = NOW + 5
    expect(ataxia_satiationTick()).toBeFalse()
    expect(sentCount("probe horn")).toBe(1)
  end)
end)

describe("Healing Metabolism -- GMCP confirms, failures back off", function()
  it("Defences.Add satiation clears the attempt and the fail count", function()
    reset(); mnemHealingMetabolism = true
    ataxia_satiationTick()
    ataxiaTemp.satiationFails = 2
    gmcp.Char.Defences.Add = { name = "satiation", desc = "x" }
    raiseEvent("gmcp.Char.Defences.Add")
    expect(ataxiaTemp.satiationPendingAt).toBeNil()
    expect(ataxiaTemp.satiationFails).toBe(0)
  end)

  it("ignores every other defence on Add", function()
    reset(); mnemHealingMetabolism = true
    ataxia_satiationTick()
    gmcp.Char.Defences.Add = { name = "speed" }
    raiseEvent("gmcp.Char.Defences.Add")
    expect(ataxiaTemp.satiationPendingAt).toBe(1000)
  end)

  it("an unconfirmed attempt releases the next one; three in a row back off", function()
    reset(); mnemHealingMetabolism = true
    for _ = 1, 3 do
      expect(ataxia_satiationTick()).toBeTrue()
      fireTimers(12)                             -- the confirm window closes, no Add
      NOW = NOW + 1
    end
    expect(sentCount("probe horn")).toBe(3)
    expect(ataxia_satiationTick()).toBeFalse()  -- backing off
    NOW = NOW + 301
    expect(ataxia_satiationTick()).toBeTrue()
  end)

  it("the back-off echo says which half failed, from the activation line", function()
    local echoes = {}
    local oldEcho = ataxiaEcho
    ataxiaEcho = function(m) echoes[#echoes + 1] = m end
    reset(); mnemHealingMetabolism = true
    for _ = 1, 3 do ataxia_satiationTick(); fireTimers(12); NOW = NOW + 1 end
    expect(echoes[#echoes]:find("never activated", 1, true) ~= nil).toBeTrue()
    reset(); mnemHealingMetabolism = true; echoes = {}
    for _ = 1, 3 do
      ataxia_satiationTick(); ataxia_satiationActivated(); fireTimers(12); NOW = NOW + 1
    end
    expect(echoes[#echoes]:find("the meal failed", 1, true) ~= nil).toBeTrue()
    ataxiaEcho = oldEcho
  end)

  it("trigger 791 matches the activation line", function()
    local src = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/791_Satiation_Activated.lua"):read("*a")
    expect(src:find("pattern: ^You begin concentrating on efficient digestion\\.$", 1, true) ~= nil).toBeTrue()
  end)

  it("Defences.Remove satiation starts a new attempt at once", function()
    reset(); mnemHealingMetabolism = true; ataxia.defences.satiation = true
    gmcp.Char.Defences.Remove = { "satiation" }
    raiseEvent("gmcp.Char.Defences.Remove")
    expect(sentCount("probe horn")).toBe(1)
    expect(ataxia.defences.satiation).toBeNil()
  end)

  it("ignores every other defence on Remove", function()
    reset(); mnemHealingMetabolism = true; ataxia.defences.satiation = true
    gmcp.Char.Defences.Remove = { "speed" }
    raiseEvent("gmcp.Char.Defences.Remove")
    expect(#sent).toBe(0)
  end)

  it("the hunger row no longer feeds for Healing Metabolism", function()
    reset(); mnemHealingMetabolism = true; vitals("0")
    expect(ataxia_hungerSeen("hungry")).toBeFalse()
    expect(#sent).toBe(0)
  end)
end)

describe("Famine upkeep -- the SCORE hunger row decides", function()
  it("'utterly satiated' closes the episode and sends nothing", function()
    reset(); mnemFamine = true
    ataxiaTemp.satiateChain, ataxiaTemp.satiateChainAt = 2, NOW
    expect(ataxia_hungerSeen("utterly satiated")).toBe("satiated")
    expect(#sent).toBe(0)
    expect(ataxiaTemp.satiateChain).toBeNil()
    expect(ataxiaTemp.hungerState).toBe("utterly satiated")
  end)

  it("anything lower feeds off the horn -- probe, then get+eat the first item listed", function()
    reset(); mnemFamine = true
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")
    expect(sentAny("probe horn")).toBeTrue()
    listHorn("loaf479025", "a small loaf of waybread")
    expect(sentAny("get loaf479025 from horn;eat loaf479025")).toBeTrue()
    expect(sentAny("satiation;")).toBeFalse()
  end)

  it("does nothing below satiated without Famine", function()
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
    reset(); mnemFamine = true
    expect(ataxia_hungerSeen("  Utterly Satiated  ")).toBe("satiated")
    expect(#sent).toBe(0)
  end)

  it("re-feeds on a still-short reading past the horn cooldown, three times, then waits", function()
    reset(); mnemFamine = true
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")           -- 1
    NOW = NOW + 6
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")           -- 2, inside the 20s cooldown
    NOW = NOW + 6
    expect(ataxia_hungerSeen("peckish")).toBe("upkeep")          -- 3
    NOW = NOW + 6
    expect(ataxia_hungerSeen("peckish")).toBeFalse()             -- budget spent
    expect(sentCount("probe horn")).toBe(3)
    expect(ataxia_hungerSeen("utterly satiated")).toBe("satiated")
    NOW = NOW + 30
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")
    expect(sentCount("probe horn")).toBe(4)
  end)

  it("a spent chain expires with the episode, so silence cannot lock the upkeep out", function()
    reset(); mnemFamine = true
    for _ = 1, 3 do ataxia_hungerSeen("hungry"); NOW = NOW + 6 end
    expect(ataxia_hungerSeen("hungry")).toBeFalse()
    NOW = NOW + 301
    expect(ataxia_hungerSeen("hungry")).toBe("upkeep")
  end)

  it("the confirming SCORE does not fire once Famine is gone", function()
    reset(); mnemFamine = true
    ataxia_hungerSeen("hungry")
    sent = {}
    mnemFamine = false
    fireTimers(6)
    expect(sentAny("score")).toBeFalse()
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
    expect(ataxia_carnivoreTopUp()).toBeFalse() -- Carnivore alone opens nothing
    mnemFamine = true
    expect(ataxia_carnivoreTopUp()).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us.
send, getEpoch, ataxiaEcho = _saved.send, _saved.getEpoch, _saved.ataxiaEcho
tempRegexTrigger, tempTimer = _saved.tempRegexTrigger, _saved.tempTimer
killTrigger, killTimer, matches, gmcp = _saved.killTrigger, _saved.killTimer, _saved.matches, _saved.gmcp
mnemObligateCarnivore, mnemHealingMetabolism = _saved.mnemObligateCarnivore, _saved.mnemHealingMetabolism
mnemFamine, affed = _saved.mnemFamine, _saved.affed
ataxiaTemp = _saved.ataxiaTemp or {}
if _saved.ataxiaSettings then ataxia.settings = _saved.ataxiaSettings end
ataxia.defences = _saved.ataxiaDefences
mock.reset()
