--- test_rw2h_offense.lua -- the Two Handed Runewarden offence (rw2h, v4.7.465)
--
-- The user's model (2026-10-28): PERCEIVE before every decision; stack fractures (head whenever
-- unparried, one cracked rib, one wrist fracture, legs last); PRECISION stacks 2 fractures, SPEED
-- hits the limb harder; 6 tendons -> devastate + upset -> impale -> disembowel; the overwhelm
-- path brains at 5 skull fractures. Loads the REAL script.

require("mock_mudlet")

local realSend, realTempTimer, realRegex, realEpoch = send, tempTimer, tempRegexTrigger, getEpoch
local now = 1000
getEpoch = function() return now end
local sent, prompts = {}, {}
send = function(cmd) sent[#sent + 1] = cmd end
tempTimer = function() return 1 end
tempRegexTrigger = function() return 1 end
tempPromptTrigger = function(fn) prompts[#prompts + 1] = fn; return 1 end

ataxia = { settings = { separator = ";" }, playersHere = { "Bob" }, vitals = { knight = "Two Handed" } }
ataxia.getWeapon = function(slot) return ({ bastard = "bastard405364", warhammer = "warhammer109410" })[slot] end
function combatQueue() return "" end
function ataxiaEcho() end
table.contains = table.contains or function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/levi_scripts/rw_2h/001_RW_2H_Logic.lua")
if not ok then error("failed to load rw2h: " .. tostring(err)) end
rw2h.echo = function() end

local function reset(mode)
  sent, prompts = {}, {}
  target = "Bob"
  engaged = true
  gmcp = { Char = { Vitals = { bal = "1", eq = "1" }, Status = { class = "Runewarden" } } }
  tAffs, lb, ataxiaTemp = {}, {}, {}
  affConfigV3 = nil
  rw2h.state = { mode = mode or "impale", dmg = {} }
  rw2h.config.overwhelmProne = "tendons"
end

-- One full round: dispatch -> perceive -> header (clears) -> setup (what perceive showed) -> done.
local function round(setup)
  rw2h.dispatch()
  expect(sent[#sent]).toBe("battlefury perceive Bob")
  rw2h.onPerceiveHeader("Bob")
  if setup then setup() end
  rw2h.onPerceiveDone()
  return sent[#sent]
end

local function has(s, part) return s:find(part, 1, true) ~= nil end
local function F(sf, cr, wf, tt)
  ataxiaTemp.fractures = { skullfractures = sf, crackedribs = cr, wristfractures = wf, torntendons = tt }
end

describe("rw2h: perceive first", function()
  it("sends only PERCEIVE, then attacks after the answer", function()
    reset()
    rw2h.dispatch()
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("battlefury perceive Bob")
    rw2h.dispatch()                              -- mashing while waiting sends nothing
    expect(#sent).toBe(1)
    rw2h.onPerceiveHeader("Bob")
    rw2h.onPerceiveDone()
    expect(#sent).toBe(2)
    expect(has(sent[2], "queue addclearfull free ")).toBeTrue()
  end)

  it("the header clears stale fractures and the parry", function()
    reset()
    F(3, 2, 1, 4); ataxiaTemp.parriedLimb = "head"
    rw2h.dispatch()
    rw2h.onPerceiveHeader("Bob")
    expect(rw2h.frac("skullfractures")).toBe(0)
    expect(ataxiaTemp.parriedLimb).toBe("none")
  end)

  it("ignores another person's perceive header", function()
    reset()
    F(3, 0, 0, 0)
    rw2h.dispatch()
    rw2h.onPerceiveHeader("Alice")
    expect(rw2h.frac("skullfractures")).toBe(3)
  end)

  it("the prompt after the header completes the perceive", function()
    reset()
    rw2h.dispatch()
    rw2h.onPerceiveHeader("Bob")
    expect(#prompts).toBe(1)
    prompts[1]()
    expect(#sent).toBe(2)
  end)
end)

describe("rw2h: fracture stacking order", function()
  it("head first, with SPEED before they apply, the bastard and the empower priority", function()
    reset()
    local atk = round()
    expect(has(atk, "wield bastard405364")).toBeTrue()
    expect(has(atk, "empower priority set sowulu isaz sleizak")).toBeTrue()
    expect(has(atk, "battlefury focus speed")).toBeTrue()
    expect(has(atk, "envenom bastard405364 with euphorbia")).toBeTrue()
    expect(has(atk, "overhand Bob")).toBeTrue()
    expect(has(atk, "assess Bob")).toBeTrue()
  end)

  it("then one cracked rib, then one wrist fracture, then the legs", function()
    reset()
    expect(has(round(function() F(2, 0, 0, 0) end), "underhand Bob")).toBeTrue()
    expect(has(round(function() F(2, 1, 0, 0) end), "hew Bob left arm")).toBeTrue()
    expect(has(round(function() F(2, 1, 1, 0) end), "hew Bob left leg")).toBeTrue()
  end)

  it("goes back to the head when the skull fractures are cured", function()
    reset()
    expect(has(round(function() F(1, 1, 1, 4) end), "overhand Bob")).toBeTrue()
  end)

  it("skips a parried limb", function()
    reset()
    expect(has(round(function() ataxiaTemp.parriedLimb = "head" end), "underhand Bob")).toBeTrue()
    expect(has(round(function() F(2, 1, 1, 2); ataxiaTemp.parriedLimb = "left leg" end), "hew Bob right leg")).toBeTrue()
    expect(has(round(function() F(2, 1, 0, 0); ataxiaTemp.parriedLimb = "left arm" end), "hew Bob right arm")).toBeTrue()
  end)

  it("sets the empower priority only when the weapon changes", function()
    reset()
    round()
    expect(has(round(), "empower priority")).toBeFalse()
  end)
end)

describe("rw2h: SPEED until they sip, PRECISION after, SPEED when they apply", function()
  it("a sip switches stacking to PRECISION; an apply switches it back to SPEED", function()
    reset()
    expect(has(round(), "battlefury focus speed")).toBeTrue()
    rw2h.onTargetSipped()
    expect(has(round(), "battlefury focus precision")).toBeTrue()
    expect(has(round(), "battlefury focus precision")).toBeTrue()   -- stays until they apply
    rw2h.onTargetApplied()
    expect(has(round(), "battlefury focus speed")).toBeTrue()
    rw2h.onTargetSipped()
    expect(has(round(), "battlefury focus precision")).toBeTrue()
  end)

  it("a new target starts on SPEED", function()
    reset()
    rw2h.onTargetSipped()
    rw2h.state.lastTarget = "Alice"
    expect(has(round(), "battlefury focus speed")).toBeTrue()
  end)

  local function trig(name)
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/" .. name); local t = f:read("*a"); f:close(); return t
  end
  it("trigger 394 reports the sip and 153 the apply", function()
    expect(has(trig("394_Sipped_Something.lua"), "rw2h.onTargetSipped()")).toBeTrue()
    expect(has(trig("153_Applied.lua"), "rw2h.onTargetApplied()")).toBeTrue()
  end)
end)

describe("rw2h: impale kill path", function()
  it("6 tendons -> DEVASTATE LEGS + UPSET", function()
    reset()
    local atk = round(function() F(2, 1, 1, 6) end)
    expect(has(atk, "devastate Bob legs;battlefury upset Bob")).toBeTrue()
  end)

  it("prone -> IMPALE, impaled -> DISEMBOWEL", function()
    reset()
    expect(has(round(function() tAffs.prone = true end), "impale Bob")).toBeTrue()
    expect(has(round(function() tAffs.prone = true; tAffs.impaled = true end), "disembowel Bob")).toBeTrue()
  end)

  it("a broken leg and not prone -> UPSET, and that round's hit has no focus", function()
    reset()
    local atk = round(function() tAffs.damagedleftleg = true end)
    expect(has(atk, "battlefury upset Bob")).toBeTrue()
    expect(has(atk, "battlefury focus")).toBeFalse()
  end)

  it("razes with CARVE (focus speed), and BISECTs at 20% with no shield", function()
    reset()
    local atk = round(function() tAffs.shield = true end)
    expect(has(atk, "battlefury focus speed;carve Bob")).toBeTrue()
    tAffs.shield = nil
    ataxiaTemp.lastAssess = 18
    expect(has(round(), "bisect Bob")).toBeTrue()
  end)
end)

describe("rw2h: overwhelm kill path", function()
  it("uses the warhammer: pulverise for limbs, no venom", function()
    reset("overwhelm")
    local atk = round(function() F(2, 1, 1, 0) end)
    expect(has(atk, "wield warhammer109410")).toBeTrue()
    expect(has(atk, "pulverise Bob left leg")).toBeTrue()
    expect(has(atk, "envenom")).toBeFalse()
  end)

  it("prone with 5 skull fractures -> OVERWHELM, then BRAIN", function()
    reset("overwhelm")
    expect(has(round(function() tAffs.prone = true; F(5, 0, 0, 0) end), "battlefury overwhelm Bob")).toBeTrue()
    expect(has(round(function() tAffs.prone = true; F(5, 0, 0, 0) end), "brain Bob")).toBeTrue()
  end)

  it("prone with an unbroken head -> break the head", function()
    reset("overwhelm")
    local atk = round(function() tAffs.prone = true; F(1, 0, 0, 0) end)
    expect(has(atk, "overhand Bob")).toBeTrue()
  end)

  it("the 'break' route hits a leg to break it", function()
    reset("overwhelm")
    rw2h.config.overwhelmProne = "break"
    local atk = round(function() F(2, 1, 1, 0); ataxiaTemp.parriedLimb = "left leg" end)
    expect(has(atk, "pulverise Bob right leg")).toBeTrue()
    rw2h.config.overwhelmProne = "tendons"
  end)
end)

describe("rw2h: focus and limb damage", function()
  it("records hit damage per weapon and per focus", function()
    reset()
    rw2h.state.lastWeapon = "warhammer"
    ataxiaTemp.thfocus = "speed";     rw2h.recordHit("41.5")
    ataxiaTemp.thfocus = "precision"; rw2h.recordHit("22")
    expect(rw2h.hitDamage("warhammer", "speed")).toBe(41.5)
    expect(rw2h.hitDamage("warhammer", "precision")).toBe(22)
    expect(rw2h.hitDamage("bastard", "speed")).toBeNil()
  end)

  it("breaks with PRECISION when a precision hit is enough, else SPEED", function()
    reset()
    lb.Bob = { hits = { head = 80 } }
    expect(rw2h.breakFocus("head", "warhammer")).toBe("speed")      -- unknown precision damage
    rw2h.state.dmg["warhammer:precision"] = 22
    expect(rw2h.breakFocus("head", "warhammer")).toBe("precision")  -- 80 + 22 >= 100
    lb.Bob.hits.head = 60
    expect(rw2h.breakFocus("head", "warhammer")).toBe("speed")      -- 60 + 22 < 100
  end)
end)

describe("rw2h: manual aliases and wiring", function()
  it("manual a<limb> hits that limb with the warhammer, by the same focus rule", function()
    reset()
    rw2h.onTargetSipped()
    rw2h.manual("rl", "warhammer")
    expect(has(sent[#sent], "battlefury focus precision;pulverise Bob right leg")).toBeTrue()
  end)

  local function src(p) local f = io.open(p); local s = f:read("*a"); f:close(); return s end
  local A = "src_new/aliases/levi_ataxia/for_levi/levi_062424/"
  it("the q/a aliases call rw2h, not the undefined runietwohandlogic", function()
    expect(has(src(A .. "2h/001_Bastard_Hew.lua"), "rw2h.manual(matches[2], \"bastard\")")).toBeTrue()
    expect(has(src(A .. "2h/006_Warhammer_Pulvervise.lua"), "\nrunietwohandlogic()")).toBeFalse()
    expect(has(src(A .. "2h/006_Warhammer_Pulvervise.lua"), "rw2h.manual(matches[2], \"warhammer\")")).toBeTrue()
  end)
  it("the attack alias dispatches Two Handed Runewardens", function()
    expect(has(src(A .. "152_First_Attack_(All_Classes).lua"), "rw2h.dispatch()")).toBeTrue()
  end)
  it("limb/004 records the hit damage", function()
    expect(has(src("src_new/triggers/levi_ataxia/for_levi/leviticus/limb/004_dealt_limb_damage.lua"), "rw2h.recordHit(matches.amount)")).toBeTrue()
  end)
end)

send, tempTimer, tempRegexTrigger, tempPromptTrigger, getEpoch = realSend, realTempTimer, realRegex, nil, realEpoch
ataxia, rw2h, target, engaged, gmcp, tAffs, lb, ataxiaTemp = nil, nil, nil, nil, nil, nil, nil, nil
combatQueue, ataxiaEcho = nil, nil
