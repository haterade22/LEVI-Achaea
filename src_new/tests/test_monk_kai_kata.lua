--- test_monk_kai_kata.lua -- the shared monk state (monk/004_Kai_And_Kata): kai read from
-- charstats (update_stuff/004), kai costs and the one-spender rule, the kata policy and `skata`,
-- the raw ASSESS reading Crescent needs (trigger 698), the kata lines (164, 165), and the
-- probable-stumble recorder (monk/003 shikudo_checkForms).
-- Loads the REAL scripts and the real trigger and alias bodies. Every global they create or
-- change is restored at the end (one shared Lua state for all test files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local tl = dofile("src_new/tests/trigger_lib.lua")

local ROOT = "src_new/"
local VITALS = ROOT .. "scripts/levi_ataxia/levi/ataxia/update_stuff/004_ataxia_Vitals_Update.lua"
local KAIKATA = ROOT .. "scripts/levi_ataxia/levi/ataxia/monk/004_Kai_And_Kata.lua"
local EXTRAS = ROOT .. "scripts/levi_ataxia/levi/ataxia/monk/003_Shikudo_Extras.lua"
local TRIG = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/"
local ASSESS, KATA, KATA_GONE = TRIG .. "698_Assess.lua", TRIG .. "164_Kata.lua", TRIG .. "165_Kata_Gone.lua"
local ALIASES = ROOT .. "aliases/levi_ataxia/for_levi/levi_062424/shikudo/"
local SKATA, SK = ALIASES .. "006_Kata.lua", ALIASES .. "004_Dispatch.lua"

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
-- A trigger or alias body without its YAML header, as Mudlet runs it.
local function body(p) return assert((loadstring or load)(read(p):match("%]%]%-%-\r?\n(.*)$"), p)) end
local function run(p, m) matches = m; body(p)() end

-- A clock we move by hand.
local now = 1000
getEpoch = function() return now end

local echoed, saved = {}, 0
ataxiaEcho = function(s) echoed[#echoed + 1] = s end
cecho = function(s) echoed[#echoed + 1] = s end
local function clear() echoed = {} end
local function allEchoed() return table.concat(echoed, "\n") end

-- cecho reads every <word> as a colour tag, so each one we print must be in OUR palette
-- (misc_scripts/007 replaces Mudlet's) -- never a placeholder like <form>.
local PALETTE = { reset = true }
do
  local src = read(ROOT .. "scripts/levi_ataxia/levi/ataxia/misc_scripts/007_Custom_Colour_Table.lua")
  -- Both spellings the table uses: `["NavajoWhite"] = {...}` and `white = {...}`.
  for n in src:gmatch('%["([%w_]+)"%]%s*=') do PALETTE[n] = true end
  for n in src:gmatch('\n%s*([%a_][%w_]*)%s*=%s*{') do PALETTE[n] = true end
end
local function badTag(s)
  for tag in s:gmatch("<([^>]*)>") do
    if not PALETTE[tag] then return tag end
  end
  return nil
end

ataxia = { vitals = {}, settings = {} }
ataxiaTemp = {}
target = "Agathon"

-- Load 004 with the event API stubbed, so the send watcher it registers is captured here.
local handlers, killed = {}, {}
registerAnonymousEventHandler = function(ev, fn) handlers[#handlers + 1] = { ev = ev, fn = fn }; return #handlers end
killAnonymousEventHandler = function(id) killed[#killed + 1] = id end
for _, f in ipairs({ VITALS, KAIKATA, EXTRAS }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- One gmcp.Char.Vitals tick through the REAL parse.
local function vitalsTick(class, charstats)
  gmcp = { Char = {
    Vitals = { hp = "5000", maxhp = "5000", mp = "4000", maxmp = "4000", ep = "1000", maxep = "1000",
      wp = "1000", maxwp = "1000", nl = "10", bal = "1", eq = "1", charstats = charstats },
    Status = { class = class },
  } }
  ataxiaTemp.class = class -- the same class as last tick: no class-change defup
  ataxiaBasher = {}
  ataxiagui_updateVitals = function() end
  ataxia_Vitals_Update()
end

describe("kai from charstats (update_stuff/004)", function()
  it("a Monk's 'Kai: 59%' is ataxia.vitals.kai, still class, and stamped", function()
    ataxia = { vitals = {}, settings = {} }
    ataxiaTemp = {}
    vitalsTick("Monk", { "Kai: 59%" })
    expect(ataxia.vitals.kai).toBe(59)
    expect(ataxia.vitals.class).toBe(59)
    expect(ataxiaTemp.kaiAt).toBe(now)
    expect(ataxia_kai()).toBe(59)
  end)

  it("a Blademaster's Shin is class, never kai, even right after a Monk tick", function()
    ataxia = { vitals = {}, settings = {} }
    ataxiaTemp = {}
    vitalsTick("Monk", { "Kai: 59%" })
    vitalsTick("Blademaster", { "Shin: 30" })
    expect(ataxia.vitals.kai).toBeNil()
    expect(ataxia.vitals.class).toBe(30)
    expect(ataxia_kai()).toBeNil()
  end)

  it("a kai restored from disk is unknown until a tick this session stamps it", function()
    ataxia = { vitals = { kai = 59 }, settings = {} }
    ataxiaTemp = {}
    expect(ataxia_kai()).toBeNil()
  end)
end)

describe("kai costs and the one-spender rule (monk/004)", function()
  local function kai(n) ataxia = { vitals = { kai = n }, settings = {} }; ataxiaTemp = { kaiAt = now } end

  it("surge costs 45 (the wiki), not 31: unaffordable at 44, affordable at 45", function()
    expect(ataxia_kaiCost("surge")).toBe(45)
    expect(ataxia_kaiCost("SURGE")).toBe(45)
    kai(44)
    local ok, have, need = ataxia_kaiAfford("surge")
    expect(ok).toBeFalse()
    expect(have).toBe(44)
    expect(need).toBe(45)
    kai(45)
    expect((ataxia_kaiAfford("surge"))).toBeTrue()
  end)

  it("kai already spent in the round counts: boost (11) then surge at 55 is refused", function()
    kai(55)
    local ok, have = ataxia_kaiAfford("surge", 11)
    expect(ok).toBeFalse()
    expect(have).toBe(44)
    expect((ataxia_kaiAfford("surge", 10))).toBeTrue()
  end)

  it("choke is free against a denizen (a numeric target), 10 against a player", function()
    expect(ataxia_kaiCost("choke", 12345)).toBe(0)
    expect(ataxia_kaiCost("choke", "Agathon")).toBe(10)
    expect(ataxia_kaiCost("choke")).toBe(10)
    ataxia = { vitals = {}, settings = {} }
    ataxiaTemp = {}
    expect((ataxia_kaiAfford("choke", 0, 12345))).toBeTrue()
  end)

  it("enfeeble is free against a denizen only with Spirit Rend", function()
    mnemSpiritRend = false
    expect(ataxia_kaiCost("enfeeble", 12345)).toBe(61)
    mnemSpiritRend = true
    expect(ataxia_kaiCost("enfeeble", 12345)).toBe(0)
    expect(ataxia_kaiCost("enfeeble", "Agathon")).toBe(61)
    mnemSpiritRend = false
  end)

  it("unknown kai is never affordable, and an unknown ability never is", function()
    ataxia = { vitals = { kai = 99 }, settings = {} }
    ataxiaTemp = {}
    local ok, have, need = ataxia_kaiAfford("boost")
    expect(ok).toBeFalse()
    expect(have).toBeNil()
    expect(need).toBe(11)
    kai(99)
    ok, have, need = ataxia_kaiAfford("burst")
    expect(ok).toBeFalse()
    expect(need).toBeNil()
  end)
end)

describe("the kata policy (monk/004)", function()
  it("Rain leaves after 15, and 18 with an override", function()
    ataxia = { vitals = {}, settings = {} }
    expect(ataxia_kataLeaveAfter("Rain")).toBe(15)
    expect(ataxia_kataLeaveAfter("Willow")).toBe(12)
    ataxia.settings.shikudoKata = { Rain = 18 }
    expect(ataxia_kataLeaveAfter("Rain")).toBe(18)
    expect(ataxia_kataLeaveAfter("rain")).toBe(18)
  end)

  it("an inline transition is judged on the chain after the combo's strikes", function()
    ataxia = { vitals = {}, settings = {} }
    expect(ataxia_kataShouldLeave("Willow", 9, 3)).toBeTrue()   -- post 12
    expect(ataxia_kataShouldLeave("Willow", 6, 3)).toBeFalse()  -- post 9
    expect(ataxia_kataShouldLeave("Willow", 3, 0)).toBeFalse()  -- not legal yet
    expect(ataxia_kataShouldLeave("Oak", 12, 0)).toBeTrue()
    expect(ataxia_kataShouldLeave("Rain", 12, 3)).toBeTrue()    -- post 15
    expect(ataxia_kataShouldLeave("Rain", 9, 3)).toBeFalse()
  end)

  it("Tykonos never stumbles, so it leaves as soon as legal, whatever the override", function()
    ataxia = { vitals = {}, settings = { shikudoKata = { Tykonos = 20 } } }
    expect(ataxia_kataShouldLeave("Tykonos", 2, 3)).toBeTrue()  -- post 5
    expect(ataxia_kataShouldLeave("Tykonos", 1, 3)).toBeFalse() -- post 4
    expect(ataxia_kataLeaveAfter("Tykonos")).toBe(5)
  end)

  it("an unknown form or no form never transitions", function()
    ataxia = { vitals = {}, settings = {} }
    expect(ataxia_kataShouldLeave(nil, 20, 3)).toBeFalse()
    expect(ataxia_kataShouldLeave("Krull", 20, 3)).toBeFalse()
    expect(ataxia_kataLeaveAfter(nil)).toBeNil()
  end)

  it("the chain is at risk once the last strike is older than maxIdle", function()
    ataxia = { vitals = { kata = 12 }, settings = {} } -- a live chain of 12
    ataxiaTemp = {}
    expect(ataxia_kataAtRisk(12)).toBeFalse()  -- no chain line this session: nothing to lose
    ataxiaTemp.kataAt = now - 13
    expect(ataxia_kataAtRisk(12)).toBeTrue()
    ataxiaTemp.kataAt = now - 5
    expect(ataxia_kataAtRisk(12)).toBeFalse()
    ataxiaTemp.kataAt = now - 18
    expect(ataxia_kataAtRisk()).toBeTrue()     -- default: lapseAfter, 17
  end)
end)

describe("ASSESS (698) and Crescent's half health", function()
  local function assess(name, hp, max, class)
    ataxia = { vitals = {}, settings = {} }
    ataxiaTemp = {}
    isTargeted = function(n) return type(target) == "string" and n:lower() == target:lower() end
    deleteLine = function() end
    ataxia_isClass = function(c) return class ~= nil and c:lower() == class:lower() end
    ataxia_boxEcho = function() end
    run(ASSESS, { "x", name, tostring(hp), tostring(max) })
  end

  -- v4.7.429: 698 called magi_setDestroy for a Magi, and nothing in src_new defines it, so every
  -- Magi round (each ends in `assess <target>`) threw here. This test used to stub it.
  it("as a Magi, an assess of our target runs to the end with no magi_setDestroy defined", function()
    target = "Agathon"
    local savedFn = magi_setDestroy
    magi_setDestroy = nil
    local okRun, errRun = pcall(assess, "Agathon", 3000, 7000, "magi")
    magi_setDestroy = savedFn
    if not okRun then error(errRun) end
    expect(ataxiaTemp.lastAssess).toBe(42)
  end)

  it("3540/7000 is 50.57%: lastAssess floors to 50, but it is NOT half or less", function()
    target = "Agathon"
    assess("Agathon", 3540, 7000)
    expect(ataxiaTemp.lastAssess).toBe(50)
    expect(ataxiaTemp.lastAssessHp).toBe(3540)
    expect(ataxiaTemp.lastAssessMax).toBe(7000)
    expect(ataxiaTemp.lastAssessWho).toBe("Agathon")
    expect(ataxia_assessAtMostHalf(5)).toBeFalse()
  end)

  it("3000/7000 fresh is true; 20 s old it is false", function()
    target = "Agathon"
    assess("Agathon", 3000, 7000)
    expect(ataxiaTemp.lastAssessAt).toBe(now)
    expect(ataxia_assessAtMostHalf(5)).toBeTrue()
    expect(ataxia_assessAtMostHalf()).toBeTrue()
    now = now + 20
    expect(ataxia_assessAtMostHalf(5)).toBeFalse()
  end)

  it("exactly half is enough (3500/7000)", function()
    target = "Agathon"
    assess("Agathon", 3500, 7000)
    expect(ataxia_assessAtMostHalf(5)).toBeTrue()
  end)

  it("a reading of someone else is false; the name compares in any case", function()
    target = "Agathon"
    assess("Agathon", 3000, 7000)
    target = "Bob"
    expect(ataxia_assessAtMostHalf(5)).toBeFalse()
    target = "agathon"
    expect(ataxia_assessAtMostHalf(5)).toBeTrue()
    target = 12345
    expect(ataxia_assessAtMostHalf(5)).toBeFalse()
    target = "Agathon"
  end)

  it("an assess of someone we are not targeting stores nothing", function()
    target = "Agathon"
    assess("Bob", 3000, 7000)
    expect(ataxiaTemp.lastAssessHp).toBeNil()
    expect(ataxia_assessAtMostHalf(5)).toBeFalse()
  end)
end)

describe("the kata lines (164, 165) through their real patterns", function()
  local CHAIN = "You are now maintaining a kata chain of 18 actions." -- attacker log :778
  local LAPSE = "You can no longer maintain your deadly kata."         -- vNTjvghY:5967

  local function stubs()
    selectCurrentLine = function() end
    fg = function() end
    bg = function() end
  end

  it("the chain line sets kata 18, kataLast and kataAt", function()
    local pats = tl.patterns(KATA)
    for _, w in ipairs({ 100, 119, 124 }) do
      local rows = tl.wrap(CHAIN, w)
      expect(#rows).toBe(1)
      expect(tl.anyMatches(pats, rows[1])).toBeTrue()
    end
    stubs()
    ataxia = { vitals = { kata = 9 }, settings = {} }
    ataxiaTemp = {}
    run(KATA, { CHAIN, CHAIN:match("(%d+)") })
    expect(ataxia.vitals.kata).toBe(18)
    expect(ataxiaTemp.kataLast).toBe(18)
    expect(ataxiaTemp.kataAt).toBe(now)
    expect(katachain).toBe(18)
  end)

  it("the lapse line sets kata 0", function()
    local pats = tl.patterns(KATA_GONE)
    for _, w in ipairs({ 100, 119, 124 }) do
      expect(tl.anyMatches(pats, tl.wrap(LAPSE, w)[1])).toBeTrue()
    end
    stubs()
    ataxia = { vitals = { kata = 12 }, settings = {} }
    ataxiaTemp = { kataLast = 12 }
    run(KATA_GONE, { LAPSE })
    expect(ataxia.vitals.kata).toBe(0)
    expect(katachain).toBe(0)
  end)
end)

describe("a form change resets the kata and flags a probable stumble (monk/003)", function()
  local function change(from, to, temp, kata)
    ataxia = { vitals = { oldform = from, form = to, kata = kata or 15 }, settings = {} }
    ataxiaTemp = temp
    clear()
    shikudo_checkForms(true)
  end

  it("Rain -> Tykonos with nothing sent: kata is zeroed and one stumble is recorded", function()
    change("Rain", "Tykonos", { kataAt = now - 3, kataLast = 15 })
    expect(ataxia.vitals.kata).toBe(0)
    local s = ataxiaTemp.shikudoStumbles
    expect(s and #s).toBe(1)
    expect(s[1].from).toBe("Rain")
    expect(s[1].kata).toBe(15)
    expect(s[1].at).toBe(now)
    expect(allEchoed()).toContain("[Shikudo] probable STUMBLE from Rain at kata 15 -- keep the line above")
    expect(badTag(allEchoed())).toBeNil()
  end)

  it("a 'transition to tykonos' sent 2 s earlier records nothing", function()
    change("Rain", "Tykonos", { kataAt = now - 3, kataLast = 15, shikFormSendAt = now - 2 })
    expect(ataxia.vitals.kata).toBe(0)
    expect(ataxiaTemp.shikudoStumbles).toBeNil()
    expect(allEchoed():find("probable STUMBLE", 1, true)).toBeNil()
  end)

  it("a send 7 s earlier no longer covers it", function()
    change("Willow", "Tykonos", { kataAt = now - 3, kataLast = 12, shikFormSendAt = now - 7 })
    expect(#ataxiaTemp.shikudoStumbles).toBe(1)
  end)

  it("no chain line this session (a form restored from disk) or a dead chain: nothing recorded", function()
    change("Rain", "Tykonos", {})
    expect(ataxia.vitals.kata).toBe(0)
    expect(ataxiaTemp.shikudoStumbles).toBeNil()
    change("Rain", "Tykonos", { kataAt = now - 60, kataLast = 15 })
    expect(ataxiaTemp.shikudoStumbles).toBeNil()
  end)

  it("a change to another form only resets the kata", function()
    change("Rain", "Oak", { kataAt = now - 3, kataLast = 15 })
    expect(ataxia.vitals.kata).toBe(0)
    expect(ataxiaTemp.shikudoStumbles).toBeNil()
  end)

  it("without a change it only prints: no reset, no record", function()
    ataxia = { vitals = { oldform = "Rain", form = "Tykonos", kata = 12 }, settings = {} }
    ataxiaTemp = { kataAt = now - 3, kataLast = 12 }
    clear()
    shikudo_checkForms()
    expect(ataxia.vitals.kata).toBe(12)
    expect(ataxiaTemp.shikudoStumbles).toBeNil()
    ataxia.vitals.oldform = "Tykonos"
    shikudo_checkForms(true) -- the first sighting: oldform == form
    expect(ataxia.vitals.kata).toBe(12)
  end)

  it("the vitals update's form change reaches it (update_stuff/004)", function()
    -- hp is set so the parse keeps this vitals table instead of building a fresh one.
    ataxia = { vitals = { hp = 5000, maxhp = 5000, mp = 4000, maxmp = 4000,
      form = "Willow", oldform = "Willow", kata = 12 }, settings = {} }
    ataxiaTemp = { kataAt = now - 2, kataLast = 12 }
    clear()
    vitalsTick("Monk", { "Kai: 80%", "Form: Tykonos" })
    expect(ataxia.vitals.form).toBe("Tykonos")
    expect(ataxia.vitals.oldform).toBe("Willow")
    expect(ataxia.vitals.kata).toBe(0)
    expect(#ataxiaTemp.shikudoStumbles).toBe(1)
    expect(ataxiaTemp.shikudoStumbles[1].from).toBe("Willow")
  end)
end)

-- The game ends a chain two ways besides a stumble: the lapse line, about 20 s after the last
-- strike (vNTjvghY:5377 -> :5967), and a transition, which resets it (Shikudo.wiki:116) -- Mystor
-- sends MIND rounds that carry one (vNTjvghY:715). Neither prints a chain line, so kataAt still
-- holds the dead chain's last strike.
describe("a chain the game has ended has nothing at risk (monk/004, 165, monk/003)", function()
  local LAPSE = "You can no longer maintain your deadly kata." -- vNTjvghY:5967

  local function liveChain(kata, age, form)
    form = form or "Rain"
    ataxia = { vitals = { form = form, oldform = form, kata = kata }, settings = {} }
    ataxiaTemp = { kataAt = now - age, kataLast = kata }
    selectCurrentLine = function() end
    fg = function() end
    bg = function() end
    clear()
  end
  -- A form change as update_stuff/004 makes one.
  local function toForm(f)
    ataxia.vitals.oldform = ataxia.vitals.form
    ataxia.vitals.form = f
    shikudo_checkForms(true)
  end
  local function stumbles() return ataxiaTemp.shikudoStumbles and #ataxiaTemp.shikudoStumbles or 0 end

  it("after the lapse line, a chain 20 s idle is not at risk", function()
    liveChain(12, 20)
    expect(ataxia_kataAtRisk(12)).toBeTrue()   -- still alive: it is
    run(KATA_GONE, { LAPSE })
    expect(ataxia_kataAtRisk(12)).toBeFalse()
    expect(ataxia_kataAtRisk()).toBeFalse()
  end)

  it("after a transition with no combo since, the old chain is not at risk", function()
    liveChain(12, 13)
    expect(ataxia_kataAtRisk(12)).toBeTrue()
    toForm("Oak")                              -- "transition to oak form/mind ..." (no chain line)
    expect(ataxia_kataAtRisk(12)).toBeFalse()
  end)

  it("a new chain after it is at risk again once it idles", function()
    liveChain(0, 30)
    run(KATA, { "You are now maintaining a kata chain of 3 actions.", "3" }) -- attacker log :960
    expect(ataxia_kataAtRisk(12)).toBeFalse()  -- fresh
    now = now + 13
    expect(ataxia_kataAtRisk(12)).toBeTrue()
  end)

  it("the stumble recorder: a drop to Tykonos after the lapse line records nothing", function()
    liveChain(12, 20)
    run(KATA_GONE, { LAPSE })
    now = now + 3                              -- the last strike is 23 s old, under CHAIN_LIVE
    toForm("Tykonos")
    expect(ataxia.vitals.kata).toBe(0)
    expect(stumbles()).toBe(0)
    expect(allEchoed():find("probable STUMBLE", 1, true)).toBeNil()
  end)

  it("a lapse line in the same round as the drop still records: it may be the stumble's own", function()
    liveChain(12, 3)
    run(KATA_GONE, { LAPSE })
    toForm("Tykonos")
    expect(stumbles()).toBe(1)
    expect(ataxiaTemp.shikudoStumbles[1].kata).toBe(12)
  end)

  it("the stumble recorder: a drop to Tykonos after a transition, with no combo since, records nothing", function()
    liveChain(12, 5)
    toForm("Oak")
    now = now + 3
    toForm("Tykonos")
    expect(stumbles()).toBe(0)
  end)

  it("a chain line after the transition makes the chain live again", function()
    liveChain(12, 5)
    toForm("Oak")
    now = now + 2
    run(KATA, { "You are now maintaining a kata chain of 3 actions.", "3" }) -- attacker log :960
    now = now + 2
    toForm("Tykonos")
    expect(stumbles()).toBe(1)
    expect(ataxiaTemp.shikudoStumbles[1].from).toBe("Oak")
    expect(ataxiaTemp.shikudoStumbles[1].kata).toBe(3)
  end)

  it("a stumble is recorded even when the kata reads 0 (the basher zeroes it as it queues a transition)", function()
    liveChain(0, 2, "Willow")                  -- basher/002:2623 zeroed it; the chain line said 12
    ataxiaTemp.kataLast = 12
    toForm("Tykonos")
    expect(stumbles()).toBe(1)
    expect(ataxiaTemp.shikudoStumbles[1].kata).toBe(12)
    expect(allEchoed()).toContain("probable STUMBLE from Willow at kata 12")
  end)
end)

describe("the send watcher: only a send that asks for Tykonos stamps (monk/004)", function()
  local function sees(cmd)
    ataxiaTemp = {}
    local hit = ataxia_shikFormSendSeen(cmd)
    return hit, ataxiaTemp.shikFormSendAt
  end

  it("transition, adopt, dispatch to Tykonos, and crescent stamp", function()
    for _, cmd in ipairs({
      "queue addclear free transition to tykonos form;combo Agathon thrust left",
      "ADOPT TYKONOS FORM",
      "dispatch Agathon tykonos",
      "queue addclear free stand;wield staff;combo Agathon livestrike jinzuku crescent;assess Agathon",
    }) do
      local hit, at = sees(cmd)
      expect(hit).toBeTrue()
      expect(at).toBe(now)
    end
  end)

  it("an inline transition to another form does not, so it cannot hide a stumble", function()
    local hit, at = sees("queue addclear free stand;combo Agathon hiru hiraku flashheel left transition rain;assess Agathon")
    expect(hit).toBeFalse()
    expect(at).toBeNil()
    expect((sees("adopt rain form"))).toBeFalse()
    expect((sees("combo Crescentia hiru hiraku"))).toBeFalse()
    expect((sees(nil))).toBeFalse()
  end)

  it("the stumble the inline transition might have hidden is still recorded", function()
    ataxiaTemp = { kataAt = now - 2, kataLast = 12 }
    ataxia_shikFormSendSeen("combo Agathon hiru hiraku flashheel left transition rain")
    ataxia = { vitals = { oldform = "Willow", form = "Tykonos", kata = 12 }, settings = {} }
    clear()
    shikudo_checkForms(true)
    expect(#ataxiaTemp.shikudoStumbles).toBe(1)
  end)

  it("is registered on sysDataSendRequest, and a reload kills the old handler first", function()
    expect(#handlers).toBe(1)
    expect(handlers[1].ev).toBe("sysDataSendRequest")
    ataxiaTemp = {}
    handlers[1].fn("sysDataSendRequest", "adopt tykonos form")
    expect(ataxiaTemp.shikFormSendAt).toBe(now)
    ataxiaTemp = { shikFormSendHandler = 1 }
    killed = {}
    dofile(KAIKATA)
    expect(killed[1]).toBe(1)
    expect(ataxiaTemp.shikFormSendHandler).toBe(2)
  end)
end)

describe("skata (alias shikudo/006)", function()
  local function skata(form, val)
    local m = { "skata" .. (form and (" " .. form) or "") .. (val and (" " .. val) or "") }
    if form then m[2] = form end
    if val then m[3] = val end
    clear()
    run(SKATA, m)
  end
  local function fresh()
    ataxia = { vitals = {}, settings = {} }
    saved = 0
    ataxia_saveSettings = function() saved = saved + 1 end
  end
  local function ascii(s) return not s:find("[\128-\255]") end

  it("sits in the active Shikudo group, beside sk", function()
    local function hier(p) return read(p):match("hierarchy:\r?\n(.-)attributes:") end
    expect(hier(SKATA)).toBe(hier(SK))
    expect(read(SKATA):find("isActive: 'yes'", 1, true) ~= nil).toBeTrue()
  end)

  it("'skata' shows every form's cap and saves nothing", function()
    fresh()
    skata()
    local out = allEchoed()
    for _, f in ipairs({ "Tykonos", "Willow", "Rain", "Oak", "Gaital", "Maelstrom" }) do
      expect(out).toContain(f)
    end
    expect(out).toContain("15")
    expect(saved).toBe(0)
    expect(ascii(out)).toBeTrue()
    expect(badTag(out)).toBeNil()
  end)

  it("'skata rain 18' saves an override, within what has been seen: no warning", function()
    fresh()
    skata("rain", "18")
    expect(ataxia.settings.shikudoKata.Rain).toBe(18)
    expect(ataxia_kataLeaveAfter("Rain")).toBe(18)
    expect(saved).toBe(1)
    expect(allEchoed():find("past the longest chain", 1, true)).toBeNil()
  end)

  it("'skata oak 14' warns, in ASCII, past the longest chain seen without a stumble", function()
    fresh()
    skata("oak", "14")
    expect(ataxia.settings.shikudoKata.Oak).toBe(14)
    expect(allEchoed()).toContain("past the longest chain seen without a stumble (13)")
    expect(ascii(allEchoed())).toBeTrue()
    expect(badTag(allEchoed())).toBeNil()
  end)

  it("'skata rain default' drops the override, and so does the default's own value", function()
    fresh()
    ataxia.settings.shikudoKata = { Rain = 18, Oak = 14 }
    skata("rain", "default")
    expect(ataxia.settings.shikudoKata.Rain).toBeNil()
    expect(ataxia_kataLeaveAfter("Rain")).toBe(15)
    skata("oak", "12")
    expect(ataxia.settings.shikudoKata.Oak).toBeNil()
    expect(saved).toBe(2)
  end)

  it("refuses Tykonos, a cap under 5, and an unknown form, saving nothing", function()
    fresh()
    for _, a in ipairs({ { "tykonos", "9" }, { "rain", "3" }, { "krull", "12" }, { "rain", "lots" } }) do
      skata(a[1], a[2])
      expect(#echoed).toBe(1)
      expect(badTag(allEchoed())).toBeNil() -- the usage text survives cecho
    end
    expect(ataxia.settings.shikudoKata == nil or next(ataxia.settings.shikudoKata) == nil).toBeTrue()
    expect(saved).toBe(0)
  end)
end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
