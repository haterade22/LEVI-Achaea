--- test_tekura_punch.lua -- the learned punch damage, with spiked knuckles in mind (v4.7.494)
-- * TK6 (tekura/002) learns our kick and punch damage from our own hits. It split them at a fixed
--   16%, so a punch through spiked knuckles (hand_to_hand, +35% Tekura punch damage: 14 x 1.35 =
--   18.9) was learned as a kick. A hit now goes to the learned value it is nearer.
-- * TKD (tekura/001) took one punch as a fixed 14% for its prep line (86) and its break guard. It
--   now reads the punch TK6 learned, and 14% only until TK6 has one.
-- Loads the REAL monk/004, tekura/001 and tekura/002. Every global this file creates or changes is
-- restored at the end (one shared Lua state for all test files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local ROOT = "src_new/scripts/levi_ataxia/levi/"
local FILES = {
  ROOT .. "ataxia/monk/004_Kai_And_Kata.lua",
  ROOT .. "levi_scripts/tekura/001_Tekura_Offense.lua",
  ROOT .. "levi_scripts/tekura/002_Tekura_6Limb_Offense.lua",
}

getEpoch = function() return 1000 end
cecho = function() end
ataxiaEcho = function() end
send = function() end
registerAnonymousEventHandler = function() return 1 end
killAnonymousEventHandler = function() end
ataxia = { vitals = {}, settings = {} }
ataxiaTemp = {}
tAffs = {}
target = "Agathon"
tekura, tekura6 = nil, nil
for _, f in ipairs(FILES) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end
affConfigV3 = nil

local function learned(k, p)
  tekura6.state.kickDamage, tekura6.state.punchDamage = k, p
end
local function hit(amount, who) tekura6.onLimbHitUpdated("limb hits updated", who or "Agathon", "torso", amount) end

describe("TK6: a hit goes to the learned value it is nearer (tekura/002)", function()
  it("a punch through spiked knuckles (18.9%) is a punch, not a kick", function()
    learned(25, 14)
    hit(18.9)
    expect(tekura6.state.punchDamage).toBe(18.9)
    expect(tekura6.state.kickDamage).toBe(25)
  end)

  it("a kick is still a kick", function()
    learned(25, 18.9)
    hit(24.6)
    expect(tekura6.state.kickDamage).toBe(24.6)
    expect(tekura6.state.punchDamage).toBe(18.9)
  end)

  it("the split moves with what we learn: 22 with 25 / 18.9 learned is a kick", function()
    learned(25, 18.9)
    expect(tekura6.classifyHit(22)).toBe("kick")
    expect(tekura6.classifyHit(21.9)).toBe("punch")
  end)

  it("a hit on someone else, a zero or no amount changes nothing", function()
    learned(25, 14)
    hit(18, "Sadey")
    hit(0)
    tekura6.onLimbHitUpdated("limb hits updated", "Agathon", "all")
    expect(tekura6.state.punchDamage).toBe(14)
    expect(tekura6.state.kickDamage).toBe(25)
  end)
end)

describe("TKD: one punch is the learned punch (tekura/001)", function()
  it("reads TK6's learned punch, and the prep line follows it", function()
    learned(25, 18.9)
    expect(tekura.punchDamage()).toBe(18.9)
    expect(math.abs(tekura.prepThreshold() - 81.1) < 1e-9).toBeTrue()
  end)

  it("14% until TK6 has learned one", function()
    tekura6.state.punchDamage = nil
    expect(tekura.punchDamage()).toBe(14)
    expect(tekura.prepThreshold()).toBe(86)
  end)

  it("a torso at 82% is prepped with an 18.9% punch, not with 14%", function()
    lb = { Agathon = { hits = { torso = 82, ["left leg"] = 0, ["right leg"] = 0, head = 0 } } }
    learned(25, 14)
    expect(tekura.dispatch.checkTorsoPrepped()).toBeFalse()
    learned(25, 18.9)
    expect(tekura.dispatch.checkTorsoPrepped()).toBeTrue()
  end)

  it("the torso prep round jabs instead of a punch that would break the torso", function()
    lb = { Agathon = { hits = { torso = 50, ["left leg"] = 0, ["right leg"] = 0, head = 0 } } }
    ataxiaTemp.parriedLimb = nil
    learned(25, 14)
    -- 50 + 25 kick = 75; 75 + 14 = 89; 89 + 14 = 103: the second punch would break, so it jabs.
    expect(tekura.dispatch.buildTorsoPrepAttack()).toBe("combo Agathon sdk hkp jbp")
    learned(25, 12)
    -- 75 + 12 = 87; 87 + 12 = 99: both punches stay under the break.
    expect(tekura.dispatch.buildTorsoPrepAttack()).toBe("combo Agathon sdk hkp hkp")
  end)
end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
