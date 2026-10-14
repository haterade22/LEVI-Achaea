--- test_alchemist.lua -- Alchemist robes + Extispicy (class_things/004 and 005)
--
-- User: "We would want to robes summon. Then imbue with lead, iron, gold and mercury (this depends
-- on what is hitting the hardest in mnem since we track damage taken)."
-- User: "Kill eat and then dissect rat for bashing."

require("mock_mudlet")

local _saved = {
  send = send, getEpoch = getEpoch, ataxiaEcho = ataxiaEcho, isClass = ataxia_isClass,
  tempRegexTrigger = tempRegexTrigger, tempTimer = tempTimer,
  killTrigger = killTrigger, killTimer = killTimer, matches = matches,
  bashStats = bashStats, gmcp = gmcp, basher = ataxiaBasher,
}

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.defences = ataxia.defences or {}
ataxiaTemp = {}

local sent, NOW, armed, CLASS = {}, 5000, nil, "Alchemist"
send = function(c) sent[#sent + 1] = c end
getEpoch = function() return NOW end
ataxiaEcho = function() end
tempRegexTrigger = function(_, fn) armed = fn; return 1 end
tempTimer = function(_, _) return 2 end
killTrigger = function() end
killTimer = function() end

dofile("src_new/scripts/levi_ataxia/levi/ataxia/basher/003_Bash_Stats_Functions.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/class_things/004_Alchemist_Robes.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/class_things/005_Alchemist_Extispicy.lua")
ataxia_isClass = function(c) return c:lower() == CLASS:lower() end
ataxiaBasher_recordIncoming = nil

local function reset()
  sent, NOW, armed, CLASS = {}, NOW + 1000, nil, "Alchemist"
  ataxiaTemp = {}
  ataxia.settings.robesImbue, ataxia.settings.extispicy = nil, nil
  ataxia.defences = {}
  ataxiaBasher = { inMnemosyne = false }
  gmcp = { Char = { Vitals = { mp = "5000" } } }
  bashStats = { incomingByType = {}, incomingTotal = 0, incomingHits = 0 }
end

local function count(needle)
  local n = 0
  for _, c in ipairs(sent) do if c:find(needle, 1, true) then n = n + 1 end end
  return n
end

local function hit(n, dtype)
  for _ = 1, n do bashStats_recordIncoming(100, dtype) end
end

describe("alchemist robes: symbol choice", function()
  it("maps the game's damage strings to symbols", function()
    expect(ataxia_robesSymbolFor("physical blunt")).toBe("lead")
    expect(ataxia_robesSymbolFor("physical cutting")).toBe("iron")
    expect(ataxia_robesSymbolFor("electricity")).toBe("copper")
    expect(ataxia_robesSymbolFor("asphyxiation")).toBe("sulphur")
    expect(ataxia_robesSymbolFor("raw")).toBeNil()
    expect(ataxia_robesSymbolFor("unblockable")).toBeNil()
  end)

  it("defaults to lead iron gold mercury with no damage data", function()
    reset()
    local plan, src = ataxia_robesPlan()
    expect(table.concat(plan, " ")).toBe("lead iron gold mercury")
    expect(src).toBe("default")
  end)

  it("ranks the types that hit hardest, filled from the default set", function()
    reset()
    bashStats.incomingByType = { cold = 900, magic = 500, raw = 2000, ["physical blunt"] = 100 }
    bashStats.incomingHits = 10
    local plan, src = ataxia_robesPlan()
    expect(table.concat(plan, " ")).toBe("silver salt lead iron")
    expect(src).toBe("damage")
  end)

  it("keeps the default set until there are enough hits", function()
    reset()
    bashStats.incomingByType = { cold = 900 }
    bashStats.incomingHits = ataxia_ROBES_MIN_HITS - 1
    expect(table.concat(ataxia_robesPlan(), " ")).toBe("lead iron gold mercury")
  end)

  it("a fixed setting is used as given, unknown words dropped", function()
    reset()
    ataxia.settings.robesImbue = "tin copper bogus tin"
    local plan, src = ataxia_robesPlan()
    expect(table.concat(plan, " ")).toBe("tin copper")
    expect(src).toBe("fixed")
  end)
end)

describe("alchemist robes: summon and imbue", function()
  it("defup summons once per session and imbues on equilibrium", function()
    reset()
    ataxia_robesSummon("defup")
    expect(sent[1]).toBe("queue add eq robes summon")
    expect(sent[2]).toBe("queue add eq robes imbue with lead iron gold mercury")
    NOW = NOW + 60
    ataxia_robesSummon("defup")
    expect(count("robes summon")).toBe(1)
    expect(count("robes imbue")).toBe(1) -- same set already on
  end)

  it("does nothing for another class or when off", function()
    reset(); CLASS = "Magi"
    expect(ataxia_robesSummon("defup")).toBeFalse()
    reset(); ataxia.settings.robesImbue = false
    expect(ataxia_robesSummon("defup")).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("re-imbues in the tower when the worst four change, no more than once per gap", function()
    reset()
    ataxiaBasher.inMnemosyne = true
    ataxia_robesSummon("defup")
    NOW = NOW + ataxia_ROBES_REIMBUE_GAP
    hit(10, "cold")
    expect(count("robes imbue with silver lead iron gold")).toBe(1)
    hit(20, "psychic")
    expect(count("robes imbue")).toBe(2) -- inside the gap: no new imbue yet
    NOW = NOW + ataxia_ROBES_REIMBUE_GAP
    hit(1, "psychic")
    expect(count("robes imbue with tin silver lead iron")).toBe(1)
  end)

  it("never re-imbues outside the tower", function()
    reset()
    ataxia_robesSummon("defup")
    NOW = NOW + ataxia_ROBES_REIMBUE_GAP
    hit(10, "cold")
    expect(count("robes imbue")).toBe(1)
  end)
end)

describe("alchemist extispicy", function()
  it("knows a rat", function()
    expect(ataxia_extispicyIsRat("a young rat")).toBeTrue()
    expect(ataxia_extispicyIsRat("an old black rat")).toBeTrue()
    expect(ataxia_extispicyIsRat("a ratman")).toBeFalse()
    expect(ataxia_extispicyIsRat("a pirate")).toBeFalse()
  end)

  it("a rat kill probes corpses and queues dissect on the rat corpse id", function()
    reset()
    expect(ataxia_extispicyOnKill("a young rat")).toBeTrue()
    expect(sent[1]).toBe("ii corpse")
    expect(ataxiaTemp.dissectHold).toBeTrue()
    matches = { "", "corpse412345       ", "a goblin" }
    armed()
    expect(count("dissect")).toBe(0)
    matches = { "", "corpse98765       ", "a young rat" }
    armed()
    expect(sent[#sent]).toBe("queue addclear bal dissect corpse98765")
    expect(ataxiaTemp.dissectHold).toBeTrue()
    expect(ataxia_extispicyRan()).toBeTrue()
    expect(ataxiaTemp.dissectHold).toBeNil()
  end)

  it("skips non-rats, other classes, the defence already up, low mana, and off", function()
    reset(); expect(ataxia_extispicyOnKill("a goblin")).toBeFalse()
    reset(); CLASS = "Magi"; expect(ataxia_extispicyOnKill("a rat")).toBeFalse()
    reset(); ataxia.defences.extispicy = true; expect(ataxia_extispicyOnKill("a rat")).toBeFalse()
    reset(); gmcp.Char.Vitals.mp = "50"; expect(ataxia_extispicyOnKill("a rat")).toBeFalse()
    reset(); ataxia.settings.extispicy = false; expect(ataxia_extispicyOnKill("a rat")).toBeFalse()
    expect(#sent).toBe(0)
  end)
end)

send, getEpoch, ataxiaEcho, ataxia_isClass = _saved.send, _saved.getEpoch, _saved.ataxiaEcho, _saved.isClass
tempRegexTrigger, tempTimer = _saved.tempRegexTrigger, _saved.tempTimer
killTrigger, killTimer, matches = _saved.killTrigger, _saved.killTimer, _saved.matches
bashStats, gmcp, ataxiaBasher = _saved.bashStats, _saved.gmcp, _saved.basher
ataxia.settings.robesImbue, ataxia.settings.extispicy = nil, nil
ataxiaTemp = {}
