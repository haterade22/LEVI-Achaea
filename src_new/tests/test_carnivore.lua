--- test_carnivore.lua -- Obligate Carnivore + Healing Metabolism (misc_scripts/022_Horn_Of_Plenty)
--
-- Two boons that only matter together. Obligate Carnivore makes corpses food; Healing Metabolism
-- makes the satiation defence worth 50% on every health elixir, which turns food from an
-- anti-starvation EMERGENCY into an UPKEEP. The horn already covered the emergency.
--
-- What these pin is the economics and the safety, in that order: a corpse is free and a horn
-- charge is one of six, so corpses go first; and eating shares the EATING balance with every
-- cure-herb, so the upkeep waits for a kill rather than firing mid-round.

require("mock_mudlet")

local _saved = {
  send = send, getEpoch = getEpoch, ataxiaEcho = ataxiaEcho,
  tempRegexTrigger = tempRegexTrigger, tempTimer = tempTimer,
  killTrigger = killTrigger, killTimer = killTimer, matches = matches,
}

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.separator = ";"
ataxiaTemp = {}

local sent, NOW, armed = {}, 1000, nil
send = function(c) sent[#sent + 1] = c end
getEpoch = function() return NOW end
ataxiaEcho = function() end
tempRegexTrigger = function(_, fn) armed = fn; return 1 end
tempTimer = function(_, _) return 2 end
killTrigger = function() end
killTimer = function() end

dofile("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/022_Horn_Of_Plenty.lua")

local function reset()
  sent, NOW, armed = {}, 1000, nil
  ataxiaTemp = {}
  mnemObligateCarnivore, mnemHealingMetabolism = false, false
end

local function sentAny(needle)
  for _, c in ipairs(sent) do if c:find(needle, 1, true) then return true end end
  return false
end

-- Feed the capture the row shape `ii corpse` actually prints -- the same one
-- `triggers/733_Corpse_Found.lua` has parsed for years.
local function listCorpse(id, what)
  matches = { "  " .. id .. "the corpse of " .. what, id, what }
  armed()
end

describe("Obligate Carnivore -- corpses as food", function()
  it("does nothing at all without the boon", function()
    reset()
    expect(ataxia_carnivoreEat("test")).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("probes for a corpse and eats the first one listed", function()
    reset(); mnemObligateCarnivore = true
    expect(ataxia_carnivoreEat("test")).toBeTrue()
    expect(sent[1]).toBe("ii corpse")
    listCorpse("corpse123456 ", "a haskrovska vine")
    expect(sentAny("eat corpse123456")).toBeTrue()
  end)

  -- Eating contends with cure-herbs for the EATING balance, and the basher's next
  -- `queue addclearfull` would wipe an ordinary queued command outright.
  it("sends the eat on the FREE queue", function()
    reset(); mnemObligateCarnivore = true
    ataxia_carnivoreEat("test")
    listCorpse("corpse1 ", "a rat")
    expect(sentAny("queue add free eat corpse1")).toBeTrue()
  end)

  -- An empty pack is the normal state between kills. Without stamping the ATTEMPT, every kill
  -- would re-probe forever and the channel would fill with `ii corpse`.
  it("throttles, and stamps the attempt even when nothing is listed", function()
    reset(); mnemObligateCarnivore = true
    expect(ataxia_carnivoreEat("first")).toBeTrue()   -- probe sent, no corpse ever arrives
    expect(ataxia_carnivoreEat("second")).toBeFalse() -- still inside the throttle
    NOW = NOW + 46
    expect(ataxia_carnivoreEat("third")).toBeTrue()
  end)

  -- The line that proves food went down re-stamps the throttle: a probe that found nothing has
  -- spent nothing, so the attempt stamp alone would be measuring the wrong event.
  it("re-stamps the throttle from the CONFIRMED line, and self-latches the flag", function()
    reset()
    NOW = 5000
    ataxia_carnivoreAte()
    expect(mnemObligateCarnivore).toBeTrue()   -- the line only prints with the boon up
    expect(ataxiaTemp.corpseAteAt).toBe(5000)
  end)
end)

describe("the horn defers to a corpse", function()
  -- A corpse is free; the horn holds six charges and refills on its own clock. Spending one on
  -- hunger we could have eaten off the floor is the single avoidable cost here.
  it("eats a corpse instead of a horn charge while the boon is held", function()
    reset(); mnemObligateCarnivore = true
    ataxia_hornOnHungry("famished")
    expect(sentAny("ii corpse")).toBeTrue()
    expect(sentAny("probe horn")).toBeFalse()
  end)

  it("still uses the horn without the boon", function()
    reset()
    ataxia_hornOnHungry("famished")
    expect(sentAny("probe horn")).toBeTrue()
    expect(sentAny("ii corpse")).toBeFalse()
  end)

  -- STARVATION ENDS IN UNCONSCIOUSNESS, and while unconscious nothing in this system can help.
  -- A throttle written for satiation upkeep must not stand in front of that.
  it("FORCES past the upkeep throttle when the game says we are starving", function()
    reset(); mnemObligateCarnivore = true
    ataxia_carnivoreEat("upkeep")          -- throttle now closed
    sent = {}
    ataxia_hornOnHungry("starving to death")
    expect(sentAny("ii corpse")).toBeTrue()
  end)

  it("falls through to the horn if the corpse path declines", function()
    reset()                                 -- no boon: carnivoreEat returns false
    ataxia_hornOnHungry("ravenous")
    expect(sentAny("probe horn")).toBeTrue()
  end)
end)

describe("satiation upkeep needs BOTH boons", function()
  -- Alone, Obligate Carnivore is just food and the horn's emergency path already covers hunger.
  -- It is Healing Metabolism -- 50% on every health elixir while satiated -- that makes holding
  -- the defence worth a command.
  it("does not top up with only Obligate Carnivore", function()
    reset(); mnemObligateCarnivore = true
    expect(ataxia_carnivoreTopUp()).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("does not top up with only Healing Metabolism -- there is no food source", function()
    reset(); mnemHealingMetabolism = true
    expect(ataxia_carnivoreTopUp()).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("tops up when both are held", function()
    reset(); mnemObligateCarnivore, mnemHealingMetabolism = true, true
    expect(ataxia_carnivoreTopUp()).toBeTrue()
    expect(sentAny("ii corpse")).toBeTrue()
  end)

  -- The top-up is upkeep, not an emergency: it must respect the throttle so a fast clearing pace
  -- does not probe on every kill.
  it("respects the throttle, unlike the starvation path", function()
    reset(); mnemObligateCarnivore, mnemHealingMetabolism = true, true
    expect(ataxia_carnivoreTopUp()).toBeTrue()
    expect(ataxia_carnivoreTopUp()).toBeFalse()
  end)
end)

send, getEpoch, ataxiaEcho = _saved.send, _saved.getEpoch, _saved.ataxiaEcho
tempRegexTrigger, tempTimer = _saved.tempRegexTrigger, _saved.tempTimer
killTrigger, killTimer, matches = _saved.killTrigger, _saved.killTimer, _saved.matches
mnemObligateCarnivore, mnemHealingMetabolism = nil, nil
ataxiaTemp = {}
