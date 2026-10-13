--- test_shikudo_dispatch.lua -- the dispatch offense (006: zz/xx/sk), v4.7.420: reading the breaks,
-- the parry and hyperfocus from the trackers, the flashheel leg, one needle, the prone follow-ups,
-- the kata policy, Crescent's ASSESS, the round builder, and the staff it wields (006, triggers 166,
-- 168, calls/008, gags/001 and the skstaff alias).
-- Loads the REAL scripts, monk/004 (kai, kata, ASSESS) first, and the real trigger and alias bodies.
-- Every global they create or change is restored at the end (one shared Lua state for all test
-- files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local TL = dofile("src_new/tests/trigger_lib.lua")

local ROOT = "src_new/"
local KAIKATA = ROOT .. "scripts/levi_ataxia/levi/ataxia/monk/004_Kai_And_Kata.lua"
local DISPATCH = ROOT .. "scripts/levi_ataxia/levi/levi_scripts/shikudo/006_CC_Shikudo_Dispatch.lua"
local TRIG = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/"
local ALIAS = ROOT .. "aliases/levi_ataxia/for_levi/levi_062424/shikudo/"

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
-- A trigger or alias body without its YAML header, as Mudlet runs it.
local function body(p) return assert((loadstring or load)(read(p):match("%]%]%-%-\r?\n(.*)$"), p)) end

-- A clock we move by hand (monk/004 reads getEpoch for the age of an ASSESS).
local now = 1000
getEpoch = function() return now end
cecho = function() end
local echoed = {}
ataxiaEcho = function(s) echoed[#echoed + 1] = s end

ataxia = { vitals = {}, settings = {} }
ataxiaTemp = {}
tAffs = {}
target = "Agathon"
lb = {}
for _, f in ipairs({ KAIKATA, DISPATCH }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- One fight state. `l` holds the limb damage: head, ll, rl. haveAff reads tAffs (an earlier test
-- file may have left a real one behind). Everything a round reads besides is cleared: no mount, no
-- rebound hold, no combatQueue prefix, no city, no learned damage table, no parry flags.
local function setup(form, affs, l)
  l = l or {}
  ataxia.vitals = { form = form, kata = 0 }
  ataxia.settings = {}
  ataxia.defences = nil
  ataxiaTemp = {}
  tAffs = affs or {}
  haveAff = function(a) return tAffs[a] and true or false end
  shikudo_limbDamage, tmounted, reboundHold, combatQueue, tCity = nil, nil, nil, nil, nil
  tph, tpto, tpll, tprl, tpla, tpra = nil, nil, nil, nil, nil, nil
  lb = { Agathon = { hits = { head = l.head or 0, torso = 0, ["left arm"] = 0,
    ["right arm"] = 0, ["left leg"] = l.ll or 0, ["right leg"] = l.rl or 0 } } }
end

-- Every command sent until the next capture().
local sent
local function capture()
  sent = {}
  send = function(c) sent[#sent + 1] = c end
  return sent
end

describe("the dispatch offense reads the trackers (006 state reads)", function()
  it("reads a flashheel break from the tracker at 8.4% damage (#3)", function()
    setup("Gaital", { brokenleftleg = true }, { ll = 8.4 })
    expect(shikudo.legBroken("left")).toBeTrue()
    expect(shikudo.legBroken("right")).toBeFalse()
    setup("Gaital", {}, { rl = 100 })
    expect(shikudo.legBroken("right")).toBeTrue()
    setup("Gaital", { damagedleftleg = true }, {})
    expect(shikudo.legBroken("left")).toBeTrue()
  end)

  it("takes the kick and staff damage from the logs", function()
    setup("Rain", {}, {})
    expect(shikudo.getAttackDamage("flashheel")).toBe(8.4)
    expect(shikudo.getAttackDamage("frontkick")).toBe(8.4)
    expect(shikudo.getAttackDamage("kuro")).toBe(8.4)
    expect(shikudo.getAttackDamage("needle")).toBe(13.4)
    expect(shikudo.getAttackDamage("spinkick")).toBe(27.0)
  end)
end)

describe("Dispatch needs prone, a damaged head and the windpipe, and no leg (#4)", function()
  it("is ready with both legs whole", function()
    setup("Gaital", { prone = true, crushedthroat = true }, { head = 100 })
    expect(shikudo.checkDispatchReady()).toBeTrue()
    setup("Gaital", { prone = true, damagedwindpipe = true }, { head = 100 })
    expect(shikudo.checkDispatchReady()).toBeTrue()
  end)

  it("needs all three: prone, the head, the throat", function()
    setup("Gaital", { crushedthroat = true }, { head = 100 })
    expect(shikudo.checkDispatchReady()).toBeFalse()
    setup("Gaital", { prone = true }, { head = 100 })
    expect(shikudo.checkDispatchReady()).toBeFalse()
    setup("Gaital", { prone = true, crushedthroat = true }, { head = 90 })
    expect(shikudo.checkDispatchReady()).toBeFalse()
    setup("Gaital", { prone = true, crushedthroat = true, damagedhead = true }, {})
    expect(shikudo.checkDispatchReady()).toBeTrue()
  end)
end)

describe("hyperfocus halves the damage on its limb, read from ataxiaTemp.hyperLimb (#6)", function()
  it("halves the head, not the torso, and moves the Gaital head threshold with it", function()
    setup("Gaital", {}, {})
    local full = shikudo.getAttackDamage("needle", "head")
    expect(shikudo.getHeadPrepThreshold()).toBe(100 - full)
    ataxiaTemp.hyperLimb = "head"
    expect(shikudo.getAttackDamage("needle", "head")).toBe(full / 2)
    expect(shikudo.getAttackDamage("needle", "torso")).toBe(full)
    expect(shikudo.getHeadPrepThreshold()).toBe(100 - full / 2)
    expect(shikudo.isHyperfocusSet()).toBeTrue()
    expect(shikudo.getHyperfocusCommand()).toBeNil()
  end)

  it("stops halving once GMCP's defence list is known and holds no hyperfocus", function()
    setup("Gaital", {}, {})
    local full = shikudo.getAttackDamage("needle", "head")
    ataxiaTemp.hyperLimb = "head"
    ataxia.defences = { rebounding = true }
    expect(shikudo.getAttackDamage("needle", "head")).toBe(full)
    ataxia.defences = { rebounding = true, hyperfocus = true }
    expect(shikudo.getAttackDamage("needle", "head")).toBe(full / 2)
  end)

  it("the leg threshold and the Oak head threshold read the same damage numbers", function()
    setup("Oak", {}, {})
    expect(shikudo.getLegPrepThreshold("left leg")).toBe(100 - 8.4)
    expect(shikudo.getHeadPrepThreshold()).toBe(100 - 13.4)
    ataxiaTemp.hyperLimb = "left leg"
    expect(shikudo.getLegPrepThreshold("left leg")).toBe(100 - 4.2)
    expect(shikudo.getLegPrepThreshold("right leg")).toBe(100 - 8.4)
  end)

  it("setHyperfocus and resetHyperfocus write and clear ataxiaTemp.hyperLimb", function()
    setup("Rain", {}, {})
    shikudo.setHyperfocus("ll")
    expect(ataxiaTemp.hyperLimb).toBe("left leg")
    expect(shikudo.hyperLimb()).toBe("left leg")
    shikudo.resetHyperfocus()
    expect(shikudo.hyperLimb()).toBeNil()
  end)
end)

describe("the flashheel leg (#3)", function()
  it("Willow keeps a leg short of 100% while the other can take the kick, and re-breaks a mended leg", function()
    setup("Willow", {}, { ll = 95, rl = 50 })
    expect(shikudo.selectKick()).toBe("flashheel right")
    expect(ataxiaTemp.kickTarget).toBe("right leg")
    setup("Willow", { brokenleftleg = true }, { ll = 50, rl = 95 })
    expect(shikudo.selectKick()).toBe("flashheel left")
    -- Both on the brink: one has to take it, the one with more damage.
    setup("Willow", {}, { ll = 93, rl = 95 })
    expect(shikudo.selectKick()).toBe("flashheel right")
  end)

  it("Willow breaks the leg that is not broken, then the one with more damage", function()
    setup("Willow", { brokenleftleg = true }, { ll = 30, rl = 10 })
    expect(shikudo.selectKick()).toBe("flashheel right")
    setup("Willow", {}, { ll = 10, rl = 30 })
    expect(shikudo.selectKick()).toBe("flashheel right")
    setup("Willow", {}, {})
    expect(shikudo.selectKick()).toBe("flashheel left")
  end)

  it("keeps a prone target down by breaking the leg that is whole", function()
    setup("Gaital", { prone = true, brokenleftleg = true }, { head = 98, ll = 8.4, rl = 8.4 })
    expect(shikudo.selectKick()).toBe("flashheel right")
  end)

  it("never pushes into a leg already at 100% while the other is below it", function()
    -- After the sweep round: left 100.8, right 92.4, and the next flashheel went right (attacker
    -- log :2474, :2560-2561). Both legs reading broken (her mend not seen yet) must not send it
    -- into the leg already there.
    setup("Gaital", { prone = true, brokenleftleg = true, brokenrightleg = true },
      { head = 97, ll = 100.8, rl = 92.4 })
    expect(shikudo.selectKick()).toBe("flashheel right")
    -- Not even when this kick leaves the other leg short of 100%.
    setup("Gaital", { prone = true, brokenleftleg = true, brokenrightleg = true },
      { head = 97, ll = 100.8, rl = 50 })
    expect(shikudo.selectKick()).toBe("flashheel right")
  end)

  it("pushes a leg to 100% in the sweep round", function()
    -- Both legs and the head prepped, standing: selectGaitalStaff sweeps, and the kick takes a leg
    -- to 100% beside it (attacker log :2404; c.iJVmpL:3867-3869). The left leg is already past
    -- 100%, so only the push sends the kick into the right leg, on the brink: without it the kick
    -- spares that leg. (At legs 92/95 both answers were the right leg, so the push went unseen.)
    setup("Gaital", {}, { head = 90, ll = 100.8, rl = 95 })
    expect(shikudo.selectStaff(1)).toBe("sweep")
    expect(shikudo.selectKick()).toBe("flashheel right")
    expect(shikudo.flashheelKick(false)).toBe("flashheel left")
  end)
end)

describe("spinkick on a prone head (Mystor's finish)", function()
  it("spinkicks only while she stays down and one needle is short", function()
    setup("Gaital", { prone = true }, { head = 80, ll = 100 })
    expect(shikudo.selectKick()).toBe("spinkick")
    expect(ataxiaTemp.kickTarget).toBe("head")
    setup("Gaital", { prone = true }, { head = 95, ll = 100 })
    expect(shikudo.selectKick()).toBe("flashheel right")
    setup("Gaital", { prone = true }, { head = 80 })
    expect(shikudo.selectKick()).toBe("flashheel left")
    setup("Gaital", {}, { head = 80, ll = 100 })
    expect(shikudo.selectKick()).toBe("flashheel right")
  end)

  it("never spinkicks into a parried head", function()
    setup("Gaital", { prone = true }, { head = 80, ll = 100 })
    tph = true
    expect(shikudo.selectKick()).toBe("flashheel right")
  end)
end)

describe("the parried limb is read every round, and hyperfocus opens it (#7, #6)", function()
  it("avoids a parried leg on every press", function()
    setup("Willow", {}, { ll = 50, rl = 10 })
    tpll = true
    expect(shikudo.selectKick()).toBe("flashheel right")
    expect(shikudo.selectKick()).toBe("flashheel right")
    ataxiaTemp.hyperLimb = "left leg"
    expect(shikudo.selectKick()).toBe("flashheel left")
  end)

  it("a perceived parry (trigger 148) outranks the last parried strike", function()
    setup("Willow", {}, { ll = 50, rl = 10 })
    tprl = true
    ataxiaTemp.parriedLimb = "left leg"
    expect(shikudo.parriedLimb()).toBe("left leg")
    expect(shikudo.selectKick()).toBe("flashheel right")
  end)

  it("frontkicks the arm she is not parrying, on every press", function()
    setup("Rain", {}, {})
    tpla = true
    expect(shikudo.selectKick()).toBe("frontkick right")
    expect(shikudo.selectKick()).toBe("frontkick right")
    expect(ataxiaTemp.kickTarget).toBe("right arm")
  end)

  it("keeps the last frontkick arm when the parry is elsewhere", function()
    setup("Rain", {}, {})
    ataxiaTemp.lastFrontkickArm = "right"
    tpll = true
    expect(shikudo.selectKick()).toBe("frontkick right")
  end)
end)

describe("one needle crushes the windpipe (Gaital staff)", function()
  it("sends one needle once the head will be damaged, then slickness, then addiction", function()
    setup("Gaital", { prone = true, brokenleftleg = true, brokenrightleg = true }, { head = 95 })
    expect(shikudo.selectStaff(1)).toBe("needle")
    expect(shikudo.selectStaff(2)).toBe("ruku torso")
    tAffs.slickness = true
    expect(shikudo.selectStaff(2)).toBe("jinzuku")
    tAffs.addiction = true
    expect(shikudo.selectStaff(2)).toBe("kuro right")
  end)

  it("needles twice while one needle leaves the head short", function()
    setup("Gaital", { prone = true }, { head = 40 })
    expect(shikudo.selectStaff(2)).toBe("needle")
  end)

  it("counts this combo's spinkick before a second needle", function()
    setup("Gaital", { prone = true }, { head = 60 })
    expect(shikudo.needleSecond()).toBe("needle")
    ataxiaTemp.kickTarget = "head"  -- the spinkick (27) plus the needle (13.4) take 60 past 100
    expect(shikudo.needleSecond()).toBe("ruku torso")
  end)

  it("spends the prone window on the head even when the legs read whole", function()
    setup("Gaital", { prone = true }, { head = 50 })
    expect(shikudo.selectStaff(1)).toBe("needle")
    expect(shikudo.selectStaff(2)).toBe("needle")
  end)
end)

describe("prone follow-ups: stun her while she is down", function()
  it("risingkicks the head of a prone target in Tykonos, even a prepped head", function()
    setup("Tykonos", { prone = true }, {})
    expect(shikudo.selectKick()).toBe("risingkick head")
    setup("Tykonos", { prone = true }, { head = 95 })
    expect(shikudo.selectKick()).toBe("risingkick head")
    setup("Tykonos", {}, { head = 95 })
    expect(shikudo.selectKick()).toBe("risingkick torso")
    setup("Tykonos", { prone = true }, { head = 95 })
    tph = true
    expect(shikudo.selectKick()).toBe("risingkick torso")
  end)

  it("Willow's slot 2 falls back to hiraku light on a prone target", function()
    setup("Willow", { prone = true }, { head = 97 })
    expect(shikudo.selectStaff(2)).toBe("hiraku light")
    setup("Willow", {}, { head = 97 })
    expect(shikudo.selectStaff(2)).toBe("dart torso")
    setup("Willow", { prone = true }, { head = 97 })
    tph = true
    expect(shikudo.selectStaff(2)).toBe("dart torso")
  end)
end)

describe("transitions follow the shared kata policy (monk/004)", function()
  local function at(form, kata, affs, l)
    setup(form, affs, l)
    ataxia.vitals.kata = kata
    return shikudo.shouldTransition()
  end

  it("never leaves Gaital while she is down", function()
    expect(at("Gaital", 10, { prone = true }, {})).toBeNil()
    expect(at("Gaital", 10, {}, {})).toBe("Maelstrom")
  end)

  it("stays in Gaital on the round that sweeps her down, even at the cap", function()
    -- The sweep opens the kill, and the needle is Gaital's. The review found this round carrying
    -- "transition maelstrom" at a chain of 9 or more.
    for _, kata in ipairs({ 9, 10, 14 }) do
      setup("Gaital", {}, { head = 90, ll = 92, rl = 95 })
      ataxia.vitals.kata = kata
      local cmd, kind, transition = shikudo.buildRound()
      expect(kind).toBe("combo")
      expect(cmd).toBe("wield staff;combo Agathon sweep flashheel right;assess Agathon")
      expect(transition).toBeNil()
    end
  end)

  it("judges a sweep round on its two strikes, not three", function()
    -- A sweep and its kick are two kata actions (c.iJVmpL:3868-3872). From a chain of 2 the
    -- transition would be refused (a chain of 4), so it waits a round; from 3 it goes.
    setup("Tykonos", {}, { head = 95, ll = 95, rl = 95 })
    ataxia.vitals.kata = 2
    local cmd, _, transition = shikudo.buildRound()
    expect(cmd).toBe("wield staff;combo Agathon sweep risingkick torso;assess Agathon")
    expect(transition).toBeNil()
    ataxia.vitals.kata = 3
    cmd, _, transition = shikudo.buildRound()
    expect(transition).toBe("Willow")
    expect(cmd).toBe("wield staff;combo Agathon sweep risingkick torso transition willow;assess Agathon")
    setup("Maelstrom", {}, { head = 97, ll = 95, rl = 95 })
    ataxia.vitals.kata = 2
    cmd, _, transition = shikudo.buildRound()
    expect(cmd:find("combo Agathon sweep ", 1, true) ~= nil).toBeTrue()
    expect(transition).toBeNil()
  end)

  it("Willow leaves at a chain of 12 after the combo", function()
    expect(at("Willow", 9, {}, {})).toBe("Rain")
    expect(at("Willow", 8, {}, {})).toBeNil()
  end)

  it("Rain leaves at 15 after the combo, not 24", function()
    expect(at("Rain", 12, {}, {})).toBe("Oak")
    expect(at("Rain", 9, {}, {})).toBeNil()
    -- The purpose exit stays: legs prepped at 9 goes on to Oak.
    expect(at("Rain", 9, {}, { ll = 95, rl = 95 })).toBe("Oak")
  end)

  it("Tykonos leaves as soon as the transition is legal: a chain of 5 after the strikes", function()
    expect(at("Tykonos", 2, {}, {})).toBe("Willow")
    expect(at("Tykonos", 1, {}, {})).toBeNil()
  end)

  it("judges legality after the combo's strikes, so a purpose exit can go at kata 2", function()
    expect(at("Rain", 2, {}, { head = 99, ll = 95, rl = 95 })).toBe("Oak")
    expect(at("Rain", 1, {}, { head = 99, ll = 95, rl = 95 })).toBeNil()
  end)

  it("an skata override moves the cap", function()
    setup("Rain", {}, {})
    ataxia.vitals.kata = 12
    ataxia.settings.shikudoKata = { Rain = 18 }
    expect(shikudo.shouldTransition()).toBeNil()
    ataxia.vitals.kata = 15
    expect(shikudo.shouldTransition()).toBe("Oak")
  end)
end)

describe("Crescent wants a fresh ASSESS at half health or less, from the raw numbers", function()
  local function assessed(hp, age, who)
    ataxiaTemp.lastAssess = math.floor(hp / 7000 * 100)
    ataxiaTemp.lastAssessHp, ataxiaTemp.lastAssessMax = hp, 7000
    ataxiaTemp.lastAssessAt, ataxiaTemp.lastAssessWho = now - (age or 0), who or "Agathon"
  end

  it("fires on a prone target at 3000/7000, fresh", function()
    setup("Maelstrom", { prone = true }, {})
    assessed(3000)
    expect(shikudo.selectKick()).toBe("crescent")
  end)

  it("not at 3540/7000, which the floored 50% let through", function()
    setup("Maelstrom", { prone = true }, {})
    assessed(3540)
    expect(ataxiaTemp.lastAssess).toBe(50)
    expect(shikudo.selectKick()).toBe("risingkick head")
  end)

  it("not on a 20 s old reading, another target's, or a standing target", function()
    setup("Maelstrom", { prone = true }, {})
    assessed(3000, 20)
    expect(shikudo.selectKick()).toBe("risingkick head")
    assessed(3000, 0, "Claes")
    expect(shikudo.selectKick()).toBe("risingkick head")
    setup("Maelstrom", {}, {})
    assessed(3000)
    expect(shikudo.selectKick()).toBe("risingkick head")
  end)
end)

describe("the round: buildRound builds it, dispatch sends it (#4, #10)", function()
  it("dispatch() kills with both legs whole, wields the bare 'staff', and does not ASSESS", function()
    setup("Gaital", { prone = true, crushedthroat = true }, { head = 100 })
    local out = capture()
    shikudo.dispatch()
    expect(#out).toBe(1)
    expect(out[1]).toBe("queue addclear free wield staff;dispatch Agathon")
  end)

  it("incapacitates a Mhaldorian instead, without an ASSESS", function()
    setup("Gaital", { prone = true, crushedthroat = true }, { head = 100 })
    tCity = "Mhaldor"
    local cmd, kind = shikudo.buildRound()
    expect(kind).toBe("incapacitate")
    expect(cmd).toBe("wield staff;incapacitate Agathon")
  end)

  it("buildRound() sends nothing and returns a combo ending in ';assess Agathon'", function()
    setup("Rain", {}, {})
    local out = capture()
    local cmd, kind, transition = shikudo.buildRound()
    expect(#out).toBe(0)
    expect(kind).toBe("combo")
    expect(transition).toBeNil()
    expect(cmd:find("^wield staff;combo Agathon frontkick left ") ~= nil).toBeTrue()
    expect(cmd:sub(-#";assess Agathon")).toBe(";assess Agathon")
  end)

  it("carries the inline transition before the ASSESS, and returns its form", function()
    setup("Willow", {}, {})
    ataxia.vitals.kata = 9
    local cmd, kind, transition = shikudo.buildRound()
    expect(kind).toBe("combo")
    expect(transition).toBe("Rain")
    expect(cmd:find(" transition rain;assess Agathon$") ~= nil).toBeTrue()
  end)

  it("a shielded target gets the shatter round, with its ASSESS", function()
    setup("Rain", { shield = true }, {})
    local cmd, kind = shikudo.buildRound()
    expect(kind).toBe("shatter")
    expect(cmd).toBe("wield staff;combo Agathon shatter frontkick left;assess Agathon")
  end)

  it("assessEachRound off drops the ASSESS", function()
    setup("Rain", {}, {})
    shikudo.config.assessEachRound = false
    local ok, err = pcall(function()
      local cmd = shikudo.buildRound()
      expect(cmd:find("assess", 1, true)).toBeNil()
    end)
    shikudo.config.assessEachRound = true
    assert(ok, err)
  end)

  it("no target, no round", function()
    setup("Rain", {}, {})
    target = ""
    local ok, err = pcall(function()
      expect(shikudo.buildRound()).toBeNil()
      local out = capture()
      shikudo.dispatch()
      expect(#out).toBe(0)
    end)
    target = "Agathon"
    assert(ok, err)
  end)

  it("wields the configured staff and never staff489282", function()
    setup("Rain", {}, {})
    ataxia.settings.shikudoStaff = "staff123456"
    local out = capture()
    shikudo.dispatch()
    expect(out[1]:find("wield staff123456;", 1, true) ~= nil).toBeTrue()
    expect(out[1]:find("staff489282", 1, true)).toBeNil()
    setup("Gaital", { prone = true, crushedthroat = true }, { head = 100 })
    ataxia.settings.shikudoStaff = "staff123456"
    expect((shikudo.buildRound())).toBe("wield staff123456;dispatch Agathon")
  end)

  it("puts combatQueue()'s prefix in front of the round", function()
    setup("Gaital", { prone = true, crushedthroat = true }, { head = 100 })
    combatQueue = function() return "stand;" end
    local out = capture()
    shikudo.dispatch()
    expect(out[1]).toBe("queue addclear free stand;wield staff;dispatch Agathon")
  end)
end)

-- The game lines, as the server sends them (log 1's trailing ".." is its logger's marker,
-- kb/raw/logs/README.md). Lines the logs lack are the first-strike wordings the KB table gives
-- (kb/combat/shikudo.md, from our strike triggers).
local OAK = "a twisted oaken staff"
local function staffLine(s, staff) return (s:gsub("<S>", staff or OAK)) end
local SHATTER = "Bracing your feet, you drive <S> towards Claes."                       -- attacker :1109
local NERVESTRIKE = "You whip <S> at the side of Claes's neck."                         -- attacker :829
local GAGGED = {
  "Taking a firm hold of <S> you whip it in a wide sweep at the legs of Claes.",        -- :2455
  "You whip <S> at Claes in a controlled arc, bringing its length to crack against her torso.", -- :1807
  "Lunging forward, you drive the end of <S> viciously into the solar plexus of Claes.", -- :1732
  "You spin a full rotation, bringing <S> around in a blur of motion to smash into the right arm of Claes.", -- :774
  "You spin a full rotation, bringing <S> around in a blur of motion to smash into the torso of Claes.", -- :893
  "Bracing your back foot, you lunge forward with <S> at the face of Claes.",           -- :955
  "Snapping back into a ready stance, you whirl <S> in a long sweep at the head of Claes.", -- :951
  "With pinpoint precision, you drive <S> at the throat of Claes.",                     -- KB: needle
  "Stepping to the side of Claes, you drive <S> at her kidneys.",                       -- KB: jinzuku
  "Stepping forward, you drive <S> at the face of Claes.",                              -- KB: hiraku
  "Whirling <S> in a tight arc, you bring the weapon around to crash into the side of the head of Claes.", -- KB: hiru
}

describe("the staff-line triggers match any staff, on the first row at any width (166, calls/008, gags/001)", function()
  local function firstRowMatches(file, s, staff)
    local pats = TL.patterns(TRIG .. file)
    for _, w in ipairs({ 100, 119, 124 }) do
      local row = TL.wrap(staffLine(s, staff), w)[1]
      if not TL.anyMatches(pats, row) then return false, w end
    end
    return true
  end

  it("166 catches the SHATTER strike line, with any staff", function()
    expect(firstRowMatches("166_Shield_Down.lua", SHATTER)).toBeTrue()
    expect(firstRowMatches("166_Shield_Down.lua", SHATTER, "a dark ash wood staff")).toBeTrue()
  end)

  it("calls/008 catches the nervestrike strike line, with any staff", function()
    expect(firstRowMatches("calls/008_Nervestrike_Paralyze.lua", NERVESTRIKE)).toBeTrue()
    expect(firstRowMatches("calls/008_Nervestrike_Paralyze.lua", NERVESTRIKE, "a dark ash wood staff")).toBeTrue()
  end)

  it("gags/001 catches every staff strike line it gags, wrapped or not, with any staff", function()
    for _, s in ipairs(GAGGED) do
      local ok, w = firstRowMatches("gags/001_Delete.lua", s)
      if not ok then error("not gagged at " .. tostring(w) .. ": " .. staffLine(s)) end
      ok, w = firstRowMatches("gags/001_Delete.lua", s, "a warped black iron staff coated with rust")
      if not ok then error("not gagged with another staff at " .. tostring(w) .. ": " .. s) end
    end
  end)

  it("gags/001 leaves the lines it never gagged alone", function()
    local pats = TL.patterns(TRIG .. "gags/001_Delete.lua")
    for _, ln in ipairs({
      staffLine(NERVESTRIKE),
      "As your blow lands with a crunch, you perceive that you have dealt 8.4% damage to Claes's torso.",
      "Whirling around, you bring the ball of your foot crashing into the temple of Claes.",
      "Falling back into a low crouch, you lash out with a swift strike at the left thigh of Claes.",
      "Dominius whips a dark ash wood staff in a tight arc, sweeping it at your head.",
    }) do
      expect(TL.anyMatches(pats, ln)).toBeFalse()
    end
  end)

  it("no staff-line pattern names one staff any more", function()
    for _, f in ipairs({ "166_Shield_Down.lua", "calls/008_Nervestrike_Paralyze.lua", "gags/001_Delete.lua" }) do
      for _, p in ipairs(TL.patterns(TRIG .. f)) do
        expect(p.pat:find("twisted oaken", 1, true)).toBeNil()
      end
    end
  end)
end)

describe("gags/001 gags a wrapped strike line's tail row too, in PvP only", function()
  local gagBody = body(TRIG .. "gags/001_Delete.lua")
  -- `tgt` is the target (default our player); `bashing` turns the basher on. Both are set here,
  -- since an earlier test file may leave the basher on.
  local function gag(row, tgt, bashing)
    local deleted, armed = 0, nil
    deleteFull = function() deleted = deleted + 1 end
    deleteLine = function() deleted = deleted + 1 end
    tempLineTrigger = function(from, n, fn) armed = { from = from, n = n, fn = fn } end
    line = row
    target, ataxiaBasher = tgt or "Agathon", { enabled = bashing or false }
    local ok, err = pcall(gagBody)
    target = "Agathon"
    assert(ok, err)
    return armed, function() return deleted end
  end

  it("a whole line is gagged alone", function()
    local armed, deleted = gag(staffLine(GAGGED[1]))
    expect(armed).toBeNil()
    expect(deleted()).toBe(1)
  end)

  it("the first row of a wrapped line arms one more delete for the next row", function()
    local rows = TL.wrap(staffLine(GAGGED[4]), 119)
    expect(#rows).toBe(2)
    local armed, deleted = gag(rows[1])
    expect(armed ~= nil).toBeTrue()
    expect(armed.from).toBe(1)
    expect(armed.n).toBe(1)
    armed.fn()
    expect(deleted()).toBe(2)
  end)

  it("gags nothing while bashing: a numeric target, or the basher on", function()
    -- The old whole-line patterns ended in a one-word name and never matched a denizen; the
    -- fragments do (v4.7.420 review).
    local bear = staffLine("Taking a firm hold of <S> you whip it in a wide sweep at the legs of a black bear.")
    expect(TL.anyMatches(TL.patterns(TRIG .. "gags/001_Delete.lua"), bear)).toBeTrue()
    local armed, deleted = gag(bear, 45812)
    expect(deleted()).toBe(0)
    expect(armed).toBeNil()
    armed, deleted = gag(bear, "bear", true)
    expect(deleted()).toBe(0)
    armed, deleted = gag(bear)
    expect(deleted()).toBe(1)
  end)
end)

describe("166 records a shattered shield in PvP only", function()
  local shieldBody = body(TRIG .. "166_Shield_Down.lua")
  -- The afflictions the body erases. Target and basher are set here, as in the gag tests.
  local function shatter(tgt, bashing)
    local cured = {}
    erAff = function(a) cured[#cured + 1] = a end
    targshield = true
    target, ataxiaBasher = tgt or "Agathon", { enabled = bashing or false }
    local ok, err = pcall(shieldBody)
    target = "Agathon"
    assert(ok, err)
    return cured
  end

  it("erases our target's shield", function()
    local cured = shatter()
    expect(#cured).toBe(1)
    expect(cured[1]).toBe("shield")
    expect(targshield).toBeFalse()
  end)

  it("does nothing while bashing, though the fragment matches a denizen's line", function()
    local bear = staffLine("Bracing your feet, you drive <S> towards a black bear.")
    expect(TL.anyMatches(TL.patterns(TRIG .. "166_Shield_Down.lua"), bear)).toBeTrue()
    expect(#shatter(45812)).toBe(0)
    expect(targshield).toBeTrue()
    expect(#shatter("bear", true)).toBe(0)
  end)
end)

describe("the staff to wield: 168 and the skstaff alias (#10)", function()
  it("168 wields the bare keyword with no setting, else the setting", function()
    setup("Rain", {}, {})
    local out = capture()
    body(TRIG .. "168_Staff.lua")()
    expect(out[1]).toBe("wield staff")
    ataxia.settings.shikudoStaff = "staff123456"
    body(TRIG .. "168_Staff.lua")()
    expect(out[2]).toBe("wield staff123456")
  end)

  it("168 still wields 'staff' if the dispatch offense is not loaded", function()
    setup("Rain", {}, {})
    local out = capture()
    local saved = shikudo
    shikudo = nil
    local ok, err = pcall(function() body(TRIG .. "168_Staff.lua")() end)
    shikudo = saved
    assert(ok, err)
    expect(out[1]).toBe("wield staff")
  end)

  -- cecho reads every <word> as a colour tag, so each one we print must be in OUR palette
  -- (misc_scripts/007 replaces Mudlet's).
  local PALETTE = { reset = true }
  do
    local src = read(ROOT .. "scripts/levi_ataxia/levi/ataxia/misc_scripts/007_Custom_Colour_Table.lua")
    for n in src:gmatch('%["([%w_]+)"%]%s*=') do PALETTE[n] = true end
    for n in src:gmatch('\n%s*([%a_][%w_]*)%s*=%s*{') do PALETTE[n] = true end
  end
  local function badTag(s)
    for tag in s:gmatch("<([^>]*)>") do
      if not PALETTE[tag] then return tag end
    end
    return nil
  end

  it("skstaff sets, shows and clears the staff, and saves", function()
    setup("Rain", {}, {})
    local saves = 0
    ataxia_saveSettings = function() saves = saves + 1 end
    echoed = {}
    local alias = body(ALIAS .. "007_Staff.lua")
    matches = { "skstaff staff123456", "staff123456" }
    alias()
    expect(ataxia.settings.shikudoStaff).toBe("staff123456")
    expect(shikudo.staffRef()).toBe("staff123456")
    matches = { "skstaff", "" }
    alias()
    expect(echoed[#echoed]:find("staff123456", 1, true) ~= nil).toBeTrue()
    matches = { "skstaff clear", "clear" }
    alias()
    expect(ataxia.settings.shikudoStaff).toBeNil()
    expect(shikudo.staffRef()).toBe("staff")
    expect(saves).toBe(2)
    for _, e in ipairs(echoed) do expect(badTag(e)).toBeNil() end
  end)
end)

describe("skstatus shows the leg as what holds her down, not as a kill condition", function()
  local function render()
    local lines = {}
    cecho = function(s) lines[#lines + 1] = s end
    local ok, err = pcall(shikudo.status)
    cecho = function() end
    assert(ok, err)
    return table.concat(lines)
  end

  it("renders in Rain, Gaital and with no form, showing the policy cap", function()
    setup("Rain", {}, {})
    ataxia.vitals.kata = 6
    expect(render():find("(6/15 kata)", 1, true) ~= nil).toBeTrue()
    setup(nil, {}, {})
    expect(render():find("/? kata)", 1, true) ~= nil).toBeTrue()
    setup("Gaital", { prone = true, crushedthroat = true, brokenleftleg = true }, { head = 100 })
    local out = render()
    local kill = out:match("KILL CONDITIONS:(.-)PREP STATUS:")
    expect(kill:find("Leg", 1, true)).toBeNil()
    expect(out:find("Leg broken (holds her down): <green>YES", 1, true) ~= nil).toBeTrue()
    expect(out:find("DISPATCH READY: <green>", 1, true) ~= nil).toBeTrue()
  end)
end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
