--- test_sim_fight.lua -- the rules of the whole-fight engine (tools/sim/fight.lua, victim.lua, attackers.lua).
-- Each case pins one rule of kb/sim/rules.json. The fixture is literal, as in test_sim_forward.lua, so a change to
-- rules.json does not move these cases: tools/test_theorycraft.py checks the model built from the real table.

local forward = dofile("tools/sim/forward.lua")
local V = dofile("tools/sim/victim.lua")
local A = dofile("tools/sim/attackers.lua")
local F = dofile("tools/sim/fight.lua").wire(forward, V, A)

local function model(over)
  local m = {
    lists = {
      eat = { "asthma", "clumsiness", "hypochondria", "impatience", "paralysis", "slickness", "stupidity", "weariness" },
      smoke = { "slickness" },
      salve = { "anorexia" },
      focus = { "anorexia", "stupidity" },
      random = { "anorexia", "asthma", "clumsiness", "hypochondria", "impatience", "nausea", "paralysis", "slickness",
                 "stupidity", "voyria", "weariness" },
    },
    herb = { paralysis = "bloodroot", slickness = "bloodroot", impatience = "goldenseal", stupidity = "goldenseal",
             hypochondria = "lobelia", weariness = "kelp", asthma = "kelp", clumsiness = "kelp" },
    items = { eat = { paralysis = "bloodroot", asthma = "kelp" }, smoke = { slickness = "valerian" },
              salve = { anorexia = "epidermal to body" } },
    prio = { paralysis = 3, slickness = 3, anorexia = 4, impatience = 4, hypochondria = 5, weariness = 6, asthma = 7,
             clumsiness = 7, stupidity = 8 },
    clocks = { eat = { median = 1.5, sd = 0 }, smoke = { median = 1.48, sd = 0 }, salve = { median = 0.92, sd = 0 },
               focus = { median = 2.43, sd = 0 }, tree = { median = 13.96, sd = 0 }, rebounding = { median = 8.49, sd = 0 } },
    blocked = { eat = "anorexia", salve = "slickness", smoke = "asthma", focus = "impatience", tree = "paralysis" },
    classcure = nil,
    dagaz = nil,
    labelBlocker = "weariness",
    ssc = { min = 0.10, median = 0.14, max = 0.18 },
    phi = 1,
    shield = { cost = 3.4, whileParalysed = false, reraise = { median = 5.83, sd = 0, min = 2.59 } },
    chain = { { aff = "nausea", at = 3.12 }, { aff = "lethargy", at = 6.24 }, { aff = "impatience", at = 9.31 } },
    venoms = { curare = { affs = { "paralysis" } }, kalmia = { affs = { "asthma" } }, gecko = { affs = { "slickness" } },
               slike = { affs = { "anorexia" } }, vernalius = { affs = { "weariness" } },
               aconite = { affs = { "stupidity" } }, voyria = { affs = { "voyria" } },
               epseth = { affs = { "brokenleftleg|brokenrightleg" } } },
    dstabVenoms = 2,
  }
  for k, v in pairs(over or {}) do m[k] = v end
  return m
end

local FITNESS = { kind = "fitness", cures = { "asthma" }, blocked_by = { "weariness" },
                  lockout = { median = 9.81, sd = 0 }, needs_bal = true, needs_eq = true, spends_bal = 2.8 }
local SALT = { kind = "salt", cures = "one", count = 1, blocked_by = { "stupidity" }, lockout = { median = 9.31, sd = 0 },
               needs_eq = true, spends_eq = 2.55 }
local ACCELERATE = { kind = "accelerate", cures = "one", count = 2, blocked_by = { "recklessness" },
                     lockout = { median = 19.45, sd = 0 }, needs_eq = true, spends_eq = 2.12 }
-- Only the class cure, the Dagaz rune or the tree can cure here: no eat, smoke, salve or focus list.
local RANDOM_ONLY = { eat = {}, smoke = {}, salve = {}, focus = {}, random = { "asthma", "paralysis", "voyria" } }

local function env(over)
  local e = { median = true, gap = 1.83, defences = {}, tree = "now", tail = 2.5, horizon = 30 }
  for k, v in pairs(over or {}) do e[k] = v end
  return e
end

local function start(over)
  local s = { t0 = 0, affs = {}, firstAt = 0 }
  for k, v in pairs(over or {}) do s[k] = v end
  return s
end

local function script(lines, m)
  local acts = A.script(lines, m)
  return acts
end

local function run(lines, m, e, st, seed)
  m = m or model()
  return F.run(st or start(), script(lines, m), m, e or env(), seed or 1)
end

local function state(affs, ready)
  local s = { affs = {}, defs = {}, ready = { eat = 0, smoke = 0, salve = 0, focus = 0, tree = 0, class = 0, bal = 0, eq = 0 } }
  for _, a in ipairs(affs) do s.affs[a] = true end
  for k, v in pairs(ready or {}) do s.ready[k] = v end
  return s
end

-- The first event of a kind and name, or nil.
local function find(out, kind, name, after)
  for i = 1, #out.events do
    local ev = out.events[i]
    if ev.kind == kind and (name == nil or ev.name == name) and (after == nil or ev.t > after) then return ev end
  end
  return nil
end

local function close(a, b)
  return math.abs(a - b) < 1e-9
end

describe("the runtime", function()
  it("is Lua 5.1", function()
    expect(_VERSION).toBe("Lua 5.1")
  end)
end)

describe("the blockers (channel.*.blocked_by)", function()
  local m = model({ classcure = FITNESS })
  it("anorexia shuts the eat", function()
    expect(V.shut(state({ "anorexia" }), "eat", m, 1)).toBe("anorexia")
  end)
  it("slickness shuts the salve", function()
    expect(V.shut(state({ "slickness" }), "salve", m, 1)).toBe("slickness")
  end)
  it("asthma shuts the smoke", function()
    expect(V.shut(state({ "asthma" }), "smoke", m, 1)).toBe("asthma")
  end)
  it("impatience shuts the focus", function()
    expect(V.shut(state({ "impatience" }), "focus", m, 1)).toBe("impatience")
  end)
  it("paralysis shuts the tree", function()
    expect(V.shut(state({ "paralysis" }), "tree", m, 1)).toBe("paralysis")
  end)
  it("a clock shuts a channel until it is back", function()
    expect(V.shut(state({}, { eat = 2 }), "eat", m, 1)).toBe("clock")
    expect(V.shut(state({}, { eat = 2 }), "eat", m, 2)).toBeNil()
  end)
end)

describe("the class cures (class.*)", function()
  it("FITNESS: weariness refuses it", function()
    expect(V.shut(state({ "asthma", "weariness" }), "class", model({ classcure = FITNESS }), 1)).toBe("weariness")
  end)
  it("FITNESS needs balance and equilibrium", function()
    local m = model({ classcure = FITNESS })
    expect(V.shut(state({ "asthma" }, { bal = 2 }), "class", m, 1)).toBe("bal")
    expect(V.shut(state({ "asthma" }, { eq = 2 }), "class", m, 1)).toBe("eq")
  end)
  it("FITNESS cures asthma under paralysis, spends 2.8 s of balance, and locks out", function()
    local m = model({ classcure = FITNESS })
    local out = run({ "give asthma paralysis" }, m, env({ tail = 5 }))
    local fit = find(out, "classcure", "fitness")
    expect(fit ~= nil).toBeTrue()
    expect(close(fit.t, 0.14)).toBeTrue()
    local bal = find(out, "recover", "bal")
    expect(close(bal.t, 0.14 + 2.8)).toBeTrue()
    -- A second asthma inside the lockout is not taken by FITNESS. Only FITNESS cures asthma here: no eat list, and the
    -- tree is down.
    local only = model({ classcure = FITNESS, lists = { eat = {}, smoke = {}, salve = {}, focus = {}, random = { "asthma" } } })
    local out2 = run({ "give asthma", "wait 1", "give asthma" }, only, env({ gap = 1 }), start({ ready = { tree = 30 } }))
    local n = 0
    for _, ev in ipairs(out2.events) do if ev.name == "fitness" then n = n + 1 end end
    expect(n).toBe(1)
  end)
  it("Salt: stupidity shuts it, and it needs equilibrium", function()
    expect(V.shut(state({ "stupidity" }), "class", model({ classcure = SALT }), 1)).toBe("stupidity")
    expect(V.shut(state({ "asthma" }, { eq = 2 }), "class", model({ classcure = SALT }), 1)).toBe("eq")
  end)
  it("Salt cures one random affliction, spends 2.55 s of equilibrium, and locks out (class.salt, class.salt.eq)", function()
    local m = model({ classcure = SALT, lists = RANDOM_ONLY })
    local out = run({ "give paralysis asthma" }, m, env({ tail = 12 }), start({ ready = { tree = 30 } }))
    local salt = find(out, "classcure", "salt")
    expect(close(salt.t, 0.14)).toBeTrue()
    -- With --median the random pick is the top priority: paralysis (3) before asthma (7).
    expect(find(out, "lose", "paralysis").by).toBe("salt")
    expect(close(find(out, "recover", "eq").t, 0.14 + 2.55)).toBeTrue()
    -- Back at 0.14 + 9.31, then the SSC delay again.
    local again = find(out, "classcure", "salt", 0.14)
    expect(close(again.t, 0.14 + 9.31 + 0.14)).toBeTrue()
    expect(find(out, "lose", "asthma").by).toBe("salt")
  end)
  it("Accelerate: recklessness shuts it", function()
    expect(V.shut(state({ "recklessness" }), "class", model({ classcure = ACCELERATE }), 1)).toBe("recklessness")
  end)
  it("Accelerate takes count afflictions in one fire, spends 2.12 s of equilibrium (class.accelerate.*)", function()
    local m = model({ classcure = ACCELERATE, lists = RANDOM_ONLY })
    local out = run({ "give paralysis asthma" }, m, env({ tail = 5 }), start({ ready = { tree = 30 } }))
    local n = 0
    for _, ev in ipairs(out.events) do if ev.kind == "classcure" then n = n + 1 end end
    expect(n).toBe(1)
    expect(find(out, "lose", "paralysis").by).toBe("accelerate")
    expect(find(out, "lose", "asthma").by).toBe("accelerate")
    expect(close(find(out, "recover", "eq").t, 0.14 + 2.12)).toBeTrue()
  end)
  it("Accelerate's lockout holds the second fire 19.45 s, and its end is 'recover accelerate' (class.accelerate.lockout)", function()
    local m = model({ classcure = ACCELERATE, lists = RANDOM_ONLY })
    local out = run({ "give paralysis", "wait 2", "give asthma" }, m, env({ tail = 25, gap = 1 }),
                    start({ ready = { tree = 60 } }))
    local first = find(out, "classcure", "accelerate")
    expect(close(first.t, 0.14)).toBeTrue()
    expect(close(find(out, "recover", "accelerate").t, 0.14 + 19.45)).toBeTrue()
    local second = find(out, "classcure", "accelerate", 0.14)
    expect(close(second.t, 0.14 + 19.45 + 0.14)).toBeTrue()
    expect(find(out, "recover", "class")).toBeNil()
  end)
  it("no class cure: the channel never acts", function()
    expect(V.shut(state({ "asthma" }), "class", model(), 1)).toBe("none")
  end)
  it("Dagaz takes voyria first (class.dagaz first)", function()
    -- Nothing else cures, and the tree is down. Without "first" the tick takes the top priority, paralysis.
    local function tick(first)
      local m = model({ lists = RANDOM_ONLY, dagaz = { period = { median = 15.1, sd = 0 }, first = first } })
      local out = run({ "give paralysis voyria" }, m, env({ tail = 3 }), start({ dagazNext = 1, ready = { tree = 20 } }))
      local ev = find(out, "classcure", "dagaz")
      expect(close(ev.t, 1)).toBeTrue()
      expect(ev.side).toBe("V")
      return find(out, "lose", nil, 0.5).name
    end
    expect(tick("voyria")).toBe("voyria")
    expect(tick(nil)).toBe("paralysis")
  end)
  it("the first Dagaz tick: half a period with median, drawn over one period without (class.dagaz.phase)", function()
    local m = model({ lists = RANDOM_ONLY, dagaz = { period = { median = 15.1, sd = 0 }, first = "voyria" } })
    local out = run({ "give voyria" }, m, env({ tail = 20 }), start({ ready = { tree = 40 } }))
    expect(close(find(out, "classcure", "dagaz").t, 7.55)).toBeTrue()
    local seen = {}
    for seed = 1, 5 do
      local o = run({ "give voyria" }, m, env({ tail = 20, median = false }), start({ ready = { tree = 40 } }), seed)
      local t = find(o, "classcure", "dagaz").t
      expect(t > 0 and t < 15.1).toBeTrue()
      seen[string.format("%.3f", t)] = true
    end
    local n = 0
    for _ in pairs(seen) do n = n + 1 end
    expect(n > 1).toBeTrue()
  end)
end)

describe("the attacks and the defences (attack.*)", function()
  local m = model()
  it("a DSTAB gives both venoms", function()
    local s = state({})
    local result, landed = A.apply(s, A.parse("dstab curare kalmia", m), m)
    expect(result).toBe("hit")
    expect(#landed).toBe(2)
  end)
  it("a shield blocks a DSTAB", function()
    local s = state({})
    s.defs.shield = true
    local result, landed = A.apply(s, A.parse("dstab curare kalmia", m), m)
    expect(result).toBe("shield")
    expect(#landed).toBe(0)
    expect(s.defs.shield).toBeTrue()
  end)
  it("rebounding sends a DSTAB back", function()
    local s = state({})
    s.defs.rebounding = true
    local result, landed = A.apply(s, A.parse("dstab curare kalmia", m), m)
    expect(result).toBe("rebounded")
    expect(#landed).toBe(0)
  end)
  it("FLAY SHIELD strips the shield, and no venom lands while rebounding is up (attack.flay)", function()
    local s = state({})
    s.defs.shield, s.defs.rebounding = true, true
    local act = A.parse("flay shield curare", m)
    local result, landed = A.apply(s, act, m)
    expect(result).toBe("flay.shield")
    expect(#landed).toBe(0)
    expect(s.defs.rebounding).toBeTrue()
    expect(A.lines(act, result, s)).toBe("flay.shield")
  end)
  it("FLAY REBOUNDING strips rebounding, and then the venom lands with the whip line", function()
    local s = state({})
    s.defs.rebounding = true
    local act = A.parse("flay rebounding curare", m)
    local result, landed = A.apply(s, act, m)
    expect(result).toBe("flay.rebounding")
    expect(landed[1]).toBe("paralysis")
    local name, parts = A.lines(act, result, s)
    expect(name).toBe("flay.rebounding")
    expect(parts[1].name).toBe("flay.whip")
  end)
  it("a bare FLAY strips the sileris coating and its venom lands (g rows 945-948, X rows 3189-3194)", function()
    local s = state({})
    s.defs.sileris = true
    local act = A.parse("flay curare", m)
    local result, landed, coat = A.apply(s, act, m)
    expect(result).toBe("flay.sileris")
    expect(coat).toBeTrue()
    expect(s.defs.sileris).toBeFalse()
    expect(landed[1]).toBe("paralysis")
    local name, parts = A.lines(act, result, s, coat)
    expect(name).toBe("flay.whip")
    expect(parts[1].name).toBe("sileris.down")
  end)
  it("a named FLAY takes the coating with its defence; one whose defence is gone strips nothing (attack.flay.coating)", function()
    local s = state({})
    s.defs.rebounding, s.defs.sileris = true, true
    local act = A.parse("flay rebounding curare", m)
    local result, landed, coat = A.apply(s, act, m)
    expect(result).toBe("flay.rebounding")
    expect(coat).toBeTrue()
    expect(s.defs.sileris).toBeFalse()
    expect(landed[1]).toBe("paralysis")
    local _, parts = A.lines(act, result, s, coat)
    expect(parts[1].name).toBe("sileris.down")
    expect(parts[2].name).toBe("flay.whip")
    -- X 5328: the whip landed and the coating stayed.
    local s2 = state({})
    s2.defs.sileris = true
    local r2, landed2, c2 = A.apply(s2, A.parse("flay shield curare", m), m)
    expect(r2).toBe("flay")
    expect(c2).toBeFalse()
    expect(s2.defs.sileris).toBeTrue()
    expect(landed2[1]).toBe("paralysis")
  end)
  it("a bare FLAY leaves the shield, unless the order is auto (attack.flay.order)", function()
    local s = state({})
    s.defs.shield = true
    local result = A.apply(s, A.parse("flay curare", m), m)
    expect(result).toBe("flay")
    expect(s.defs.shield).toBeTrue()
    local auto = model({ flayOrder = "auto" })
    result = A.apply(s, A.parse("flay curare", auto), auto)
    expect(result).toBe("flay.shield")
  end)
  it("a DSTAB on a shield is the block line, and a rebounded one adds the rebound line (kb_events names)", function()
    local s = state({})
    s.defs.shield = true
    local act = A.parse("dstab curare kalmia", m)
    expect(A.lines(act, A.apply(s, act, m), s)).toBe("blocked.shield")
    s.defs.shield, s.defs.rebounding = false, true
    local name, parts = A.lines(act, A.apply(s, act, m), s)
    expect(name).toBe("dstab")
    -- The second-venom line follows every DSTAB that reaches the victim, hit or rebounded (kb_events census).
    expect(parts[1].name).toBe("dstab.second")
    expect(parts[2].name).toBe("rebounded")
  end)
  it("a limb-break venom breaks the left limb, then the right (venom.epseth)", function()
    local s = state({})
    local _, landed = A.apply(s, A.parse("dstab epseth epseth", m), m)
    expect(landed[1]).toBe("brokenleftleg")
    expect(landed[2]).toBe("brokenrightleg")
  end)
  it("a damaged left leg: the venom breaks the right one (venom_to_aff:233-238)", function()
    local s = state({ "damagedleftleg" })
    local _, landed = A.apply(s, A.parse("dstab epseth curare", m), m)
    expect(landed[1]).toBe("brokenrightleg")
  end)
  it("sileris blocks a BITE", function()
    local s = state({})
    s.defs.sileris = true
    local result, landed = A.apply(s, A.parse("bite curare", m), m)
    expect(result).toBe("sileris")
    expect(#landed).toBe(0)
  end)
  it("slickness strips the coating as it lands, and prints sileris.down (defence.sileris.slickness, X 144-146)", function()
    local s = state({})
    s.defs.sileris = true
    local act = A.parse("dstab curare gecko", m)
    local result, landed, coat = A.apply(s, act, m)
    expect(result).toBe("hit")
    expect(landed[2]).toBe("slickness")
    expect(coat).toBeTrue()
    expect(s.defs.sileris).toBeFalse()
    local _, parts = A.lines(act, result, s, coat)
    expect(parts[1].name).toBe("dstab.second")
    expect(parts[2].name).toBe("sileris.down")
    -- With slickness already on, nothing lands and the coating stays.
    local s2 = state({ "slickness" })
    s2.defs.sileris = true
    local _, _, c2 = A.apply(s2, A.parse("dstab curare gecko", m), m)
    expect(c2).toBeFalse()
    expect(s2.defs.sileris).toBeTrue()
    -- A FLAY whose defence is gone strips nothing, but its whip's slickness strips the coating (review R5-engine-1).
    local s3 = state({})
    s3.defs.sileris = true
    local act3 = A.parse("flay shield gecko", m)
    local r3, landed3, c3 = A.apply(s3, act3, m)
    expect(r3).toBe("flay")
    expect(landed3[1]).toBe("slickness")
    expect(c3).toBeTrue()
    expect(s3.defs.sileris).toBeFalse()
    local _, parts3 = A.lines(act3, r3, s3, c3)
    expect(parts3[1].name).toBe("sileris.down")
    -- A give strips it too, and the BITE after it lands (review R4-engine-1: it printed [sileris]).
    local out = run({ "give slickness", "bite curare" }, nil, env({ gap = 1.0 }), start({ defs = { sileris = true } }))
    expect(find(out, "defence", "sileris.down") ~= nil).toBeTrue()
    expect(find(out, "attack", "bite").result).toBe("hit")
  end)
  it("refuses a DSTAB with one venom and an unknown venom", function()
    local act, why = A.parse("dstab curare", m)
    expect(act).toBeNil()
    expect(why ~= nil).toBeTrue()
    act = A.parse("dstab curare nothing", m)
    expect(act).toBeNil()
  end)
  it("refuses a wait of 0 s or less, which would drop the rest of the script", function()
    expect(A.parse("wait 0", m)).toBeNil()
    expect(A.parse("wait -1", m)).toBeNil()
  end)
  it("refuses a wait under A.MIN_WAIT: 1.83 + 1e-17 is 1.83, so the next action never ran on time (review ENG-5)", function()
    expect(A.parse("wait 1e-17", m)).toBeNil()
    expect(A.parse("wait 0.009", m)).toBeNil()
    expect(A.parse("wait 0.01", m) ~= nil).toBeTrue()
  end)
  it("refuses a wait that is not a finite number: NaN and inf passed the test and stopped the run (review ENG-5)", function()
    for _, w in ipairs({ "wait nan", "wait inf", "wait 1e400", "wait -inf" }) do
      expect(A.parse(w, m)).toBeNil()
    end
  end)
  it("a last wait holds the run open: the tail starts when it ends", function()
    local out = run({ "dstab curare kalmia", "wait 10" }, m, env({ tail = 2.5, horizon = 60 }))
    expect(close(out.stopAt, 1.83 + 10 + 2.5)).toBeTrue()
  end)
end)

describe("server-side curing", function()
  it("acts after the SSC delay, and the eat comes back after its clock", function()
    local out = run({ "dstab curare kalmia" })
    local eat = find(out, "cure", "eat")
    expect(close(eat.t, 0.14)).toBeTrue()
    -- kb_events' shape: an eat's args are the channel and the item.
    expect(eat.args[1]).toBe("eat")
    expect(eat.args[2]).toBe("bloodroot")
    local back = find(out, "recover", "eat")
    expect(close(back.t, 0.14 + 1.5)).toBeTrue()
  end)
  it("focus takes a mental first, and anorexia last (focus.order)", function()
    expect(V.pickFocus(state({ "anorexia", "stupidity" }), model())).toBe("stupidity")
    expect(V.pickFocus(state({ "anorexia" }), model())).toBe("anorexia")
  end)
  it("the eat takes the top priority with phi 1", function()
    expect(V.pickEat(state({ "asthma", "paralysis" }), model(), env(), nil)).toBe("paralysis")
  end)
  it("the smoke raises rebounding when it has nothing to cure, and the aura comes 8.49 s later", function()
    local out = run({ "wait 1" }, model(), env({ defences = { rebounding = true }, tail = 10 }))
    local smoke = find(out, "cure", "smoke")
    expect(close(smoke.t, 0.14)).toBeTrue()
    local up = find(out, "defence", "rebounding.up")
    expect(close(up.t, 0.14 + 8.49)).toBeTrue()
  end)
  it("the shield waits for paralysis to go (defence.shield.while_paralysed)", function()
    -- A short re-raise delay, so paralysis is the only thing that holds the shield.
    local m = model({ shield = { cost = 3.4, whileParalysed = false, reraise = { median = 0.05, sd = 0 } } })
    local out = run({ "give paralysis" }, m, env({ defences = { shield = true } }), start({ shieldFrom = 0 }))
    local shield = find(out, "defence", "shield.up")
    local cured = find(out, "lose", "paralysis")
    expect(shield.t >= cured.t).toBeTrue()
  end)
  it("a shield down at the start with no FLAY stays down: only a FLAY starts a re-raise (review R3-fork-1)", function()
    local out = run({ "wait 3" }, nil, env({ defences = { shield = true }, tail = 10 }))
    expect(find(out, "defence", "shield.up")).toBeNil()
    -- A shield up at the start and stripped in the run comes back.
    out = run({ "flay shield" }, nil, env({ defences = { shield = true }, tail = 10 }), start({ defs = { shield = true } }))
    expect(close(find(out, "defence", "shield.up").t, 5.83)).toBeTrue()
  end)
  it("after a FLAY the next DSTAB lands: the shield comes back after its delay (defence.shield.reraise)", function()
    local m = model()
    local out = run({ "flay shield", "dstab curare kalmia" }, m, env({ defences = { shield = true }, tail = 10 }),
                    start({ defs = { shield = true } }))
    local strike = find(out, "attack", "dstab")
    expect(strike ~= nil).toBeTrue()
    expect(close(strike.t, 1.83)).toBeTrue()
    expect(strike.result).toBe("hit")
    local up = find(out, "defence", "shield.up")
    expect(close(up.t, 5.83)).toBeTrue()
    -- The shield costs its equilibrium (defence.shield.cost).
    expect(close(find(out, "recover", "eq", 5.83).t, 5.83 + 3.4)).toBeTrue()
  end)
end)

describe("the shield and a class cure (review ENG-1)", function()
  it("a pending class cure takes equilibrium before the shield", function()
    -- The shield is due at 1.00. Asthma lands at 0.90, so FITNESS is pending for 0.90 + 0.14. The shield waits for it,
    -- then rises in the same moment. Before the fix the shield rose at 1.00 and FITNESS waited for its equilibrium.
    local only = model({ classcure = FITNESS, lists = { eat = {}, smoke = {}, salve = {}, focus = {}, random = { "asthma" } },
                         shield = { cost = 3.4, whileParalysed = true, reraise = { median = 1.0, sd = 0 } } })
    local out = run({ "wait 0.9", "give asthma" }, only, env({ defences = { shield = true }, tail = 5 }),
                    start({ ready = { tree = 30 }, shieldFrom = 0 }))
    local fit, up, fitAt, upAt
    for i, ev in ipairs(out.events) do
      if ev.name == "fitness" and not fit then fit, fitAt = ev, i end
      if ev.name == "shield.up" and not up then up, upAt = ev, i end
    end
    expect(close(fit.t, 1.04)).toBeTrue()
    expect(close(up.t, 1.04)).toBeTrue()
    expect(fitAt < upAt).toBeTrue()
  end)
end)

describe("the timed effects (timed.hypochondria)", function()
  it("hypochondria brings nausea, lethargy and impatience on time", function()
    -- Nothing cures here: anorexia shuts the eat, slickness the salve, asthma the smoke, impatience the focus and
    -- paralysis the tree.
    local out = run({ "give hypochondria anorexia slickness asthma paralysis impatience" }, model(), env({ tail = 10 }))
    local nausea = find(out, "gain", "nausea")
    local lethargy = find(out, "gain", "lethargy")
    expect(close(nausea.t, 3.12)).toBeTrue()
    expect(close(lethargy.t, 6.24)).toBeTrue()
    -- Impatience is already up, so the third step adds nothing.
    expect(find(out, "gain", "impatience", 0)).toBeNil()
    expect(nausea.by).toBe("hypochondria")
  end)
  it("a cured hypochondria ends the chain", function()
    local out = run({ "give hypochondria" }, model(), env({ tail = 10 }))
    expect(find(out, "gain", "nausea")).toBeNil()
  end)
  local HELD = { "hypochondria", "anorexia", "slickness", "asthma", "paralysis", "impatience" }
  it("hypochondria up at the start runs its chain from t0", function()
    local out = run({ "wait 8" }, model(), env({ tail = 2 }), start({ affs = HELD }))
    expect(close(find(out, "gain", "nausea").t, 3.12)).toBeTrue()
  end)
  it("a chain step due before t0 is skipped, not applied late", function()
    local out = run({ "wait 8" }, model(), env({ tail = 2 }), start({ affs = HELD, chainAt = -5 }))
    expect(find(out, "gain", "nausea")).toBeNil()
    expect(close(find(out, "gain", "lethargy").t, 1.24)).toBeTrue()
    local stale = run({ "wait 8" }, model(), env({ tail = 2 }), start({ affs = HELD, chainAt = -20 }))
    expect(find(stale, "gain", "nausea")).toBeNil()
    expect(find(stale, "gain", "lethargy")).toBeNil()
  end)
end)

describe("the labels (kb_replay.is_true)", function()
  local lock = { asthma = true, slickness = true, anorexia = true, impatience = true, paralysis = true }
  it("softlock is asthma, slickness or bloodfire, and anorexia", function()
    local soft = V.labels({ asthma = true, bloodfire = true, anorexia = true }, "weariness", false)
    expect(soft).toBeTrue()
  end)
  it("true needs the class cure shut", function()
    local _, tru = V.labels(lock, "weariness", false)
    expect(tru).toBeFalse()
    lock.weariness = true
    _, tru = V.labels(lock, "weariness", false)
    expect(tru).toBeTrue()
    lock.weariness = nil
    _, tru = V.labels(lock, "weariness", true)
    expect(tru).toBeTrue()
  end)
  it("a class with no blocker counts as shut, and sandfever stands for impatience", function()
    local _, tru = V.labels({ asthma = true, slickness = true, anorexia = true, sandfever = true, paralysis = true }, nil, false)
    expect(tru).toBeTrue()
  end)
  it("both arms broken shut a cure whose blocker is not weariness", function()
    local t = { asthma = true, slickness = true, anorexia = true, impatience = true, paralysis = true, leftarm1 = true,
                rightarm2 = true }
    local _, tru = V.labels(t, "stupidity", false)
    expect(tru).toBeTrue()
    _, tru = V.labels(t, "weariness", false)
    expect(tru).toBeFalse()
  end)
  it("the engine's names for broken arms count too (review LUA-N2-1)", function()
    local t = { asthma = true, slickness = true, anorexia = true, impatience = true, paralysis = true,
                brokenleftarm = true, brokenrightarm = true }
    local _, tru = V.labels(t, "stupidity", false)
    expect(tru).toBeTrue()
  end)
end)

describe("the race (kb_events.py's definition)", function()
  it("an eat spent just before the strike makes the strike first: the phase decides", function()
    -- The eat was spent 0.9 s before the first strike, so it is down at the strike (PHASE +0.6). The victim eats at
    -- 0.6 + 0.14, and that eat is still down at the next strike.
    local m = model()
    local out = F.run(start({ ready = { eat = 0.6 } }), script({ "dstab curare kalmia", "dstab curare kalmia" }, m), m,
                      env(), 1)
    local race = out.races[1]
    expect(close(race.phase, 0.6)).toBeTrue()
    expect(race.down).toBeTrue()
    expect(race.winner).toBe("strike")
    expect(close(race.by, 0.6 + 0.14 + 1.5 - 1.83)).toBeTrue()
  end)
  it("from a clean start the herb is back first, and the first strike has no PHASE (no eat spent yet)", function()
    local out = run({ "dstab curare kalmia", "dstab curare kalmia" })
    expect(out.races[1].winner).toBe("herb")
    expect(out.races[1].phase).toBeNil()
  end)
  it("a DSTAB a shield blocked starts no race, but it is the next attack of one before it", function()
    -- The shield is down at 0 (a FLAY at 0) and comes back at 1.0, so the first DSTAB lands and the second is blocked.
    local m = model({ shield = { cost = 3.4, whileParalysed = true, reraise = { median = 1.0, sd = 0 } } })
    local out = run({ "dstab curare kalmia", "dstab curare kalmia" }, m, env({ defences = { shield = true } }),
                    start({ ready = { eat = 0.6 }, shieldFrom = 0 }))
    expect(find(out, "attack", "blocked.shield") ~= nil).toBeTrue()
    expect(#out.races).toBe(1)
    expect(out.races[1].winner).toBe("strike")
    -- With the shield up from the start, both are blocked: no race.
    local blocked = run({ "dstab curare kalmia", "dstab curare kalmia" }, m, env({ defences = { shield = true } }),
                        start({ ready = { eat = 0.6 }, defs = { shield = true } }))
    expect(#blocked.races).toBe(0)
  end)
  it("an attack 10 s or more later pairs with nothing (kb_timing.DISENGAGED)", function()
    local m = model()
    local out = run({ "dstab curare kalmia", "wait 12", "dstab curare kalmia" }, m, env(), start({ ready = { eat = 0.6 } }))
    expect(out.races[1].winner).toBeNil()
    expect(out.races[1].gap > 10).toBeTrue()
  end)
  it("a second DSTAB within BUNDLED is the same attack (kb_events.attacks)", function()
    -- A gap floor under BUNDLED (--gap-floor 0.05) lets a 0.2 s gap run; without it the floor is BUNDLED.
    local out = run({ "dstab curare kalmia", "dstab curare kalmia", "dstab curare kalmia", "wait 2", "dstab curare kalmia" },
                    model(), env({ gap = 0.2, gapFloor = 0.05 }))
    -- Strikes at 0, 0.2, 0.4 and 2.6: the one at 0.2 is inside the first's bundle. from and to are script actions,
    -- so the wait is action 4 and the last DSTAB action 5.
    expect(#out.races).toBe(3)
    expect(out.races[1].from).toBe(1)
    expect(out.races[1].to).toBe(3)
    expect(out.races[2].from).toBe(3)
    expect(out.races[2].to).toBe(5)
  end)
  it("no eat ever spent: the race is unpaired", function()
    -- Every channel is shut: anorexia (eat), slickness (salve), asthma (smoke), impatience (focus), the tree's clock.
    local out = run({ "dstab slike gecko", "dstab curare kalmia" }, model(), env(),
                    start({ affs = { "impatience", "asthma" }, ready = { tree = 30 } }))
    expect(out.races[1].winner).toBeNil()
  end)
end)

describe("the run's edges", function()
  it("a drawn gap never goes under BUNDLED (review LUA-N2-12)", function()
    local lines = { "dstab curare kalmia", "dstab curare kalmia", "dstab curare kalmia", "dstab curare kalmia" }
    for seed = 1, 30 do
      local out = run(lines, nil, env({ median = false, gap = 1.0, gapSd = 0.5 }), nil, seed)
      for i = 2, #out.strikes do
        expect(out.strikes[i].t - out.strikes[i - 1].t >= F.BUNDLED - 1e-9).toBeTrue()
      end
      expect(#out.strikes).toBe(4)
    end
  end)
  it("the median gap is floored too: --gap 0 --median ran one action and stopped (review R3-engine-5)", function()
    local out = run({ "flay", "flay", "flay" }, nil, env({ gap = 0 }))
    expect(#out.strikes).toBe(3)
    expect(close(out.strikes[2].t, F.BUNDLED)).toBeTrue()
    expect(close(out.strikes[3].t, 2 * F.BUNDLED)).toBeTrue()
    expect(out.notRun).toBeNil()
    -- A floor of 0 or less is held at A.MIN_WAIT.
    out = run({ "flay", "flay" }, nil, env({ gap = 0, gapFloor = 0 }))
    expect(close(out.strikes[2].t, A.MIN_WAIT)).toBeTrue()
  end)
  it("the horizon counts the actions it cut (review LUA-N2-3)", function()
    local lines = {}
    for i = 1, 20 do lines[i] = "dstab curare kalmia" end
    local out = run(lines)
    expect(#out.strikes).toBe(17)
    expect(out.notRun).toBe(3)
    expect(run({ "dstab curare kalmia" }).notRun).toBeNil()
  end)
  it("a fork's first action is one gap after the log's last attack, drawn, never before t0 (review LUA-N2-14)", function()
    local lines = { "dstab curare kalmia" }
    expect(close(run(lines, nil, env(), start({ firstAt = nil, firstFrom = -1.0 })).firstAt, 0.83)).toBeTrue()
    expect(run(lines, nil, env(), start({ firstAt = nil, firstFrom = -5.0 })).firstAt).toBe(0)
    local seen = {}
    for seed = 1, 5 do
      local o = run(lines, nil, env({ median = false, gapSd = 0.09 }), start({ firstAt = nil, firstFrom = -1.0 }), seed)
      seen[string.format("%.4f", o.firstAt)] = true
    end
    local n = 0
    for _ in pairs(seen) do n = n + 1 end
    expect(n > 1).toBeTrue()
  end)
  it("a channel whose clock ran out before t0 comes back at t0, with its line (review LUA-N2-6)", function()
    local out = run({ "wait 1" }, nil, env(), start({ ready = { eat = 0 }, downAtStart = { eat = true } }))
    local back = find(out, "recover", "eat")
    expect(back ~= nil).toBeTrue()
    expect(back.t).toBe(0)
  end)
  it("a FLAY of the shield in the log: the shield comes back one re-raise delay after it (review LUA-N2-5)", function()
    -- The fixture's reraise median is 5.83: a FLAY 3.83 s before t0 gives the shield at 2.00. A FLAY long before t0
    -- gives it at t0.
    local out = run({ "wait 3" }, nil, env({ defences = { shield = true } }), start({ shieldFrom = -3.83 }))
    expect(close(find(out, "defence", "shield.up").t, 2.0)).toBeTrue()
    out = run({ "wait 3" }, nil, env({ defences = { shield = true } }), start({ shieldFrom = -30 }))
    expect(find(out, "defence", "shield.up").t).toBe(0)
    -- A victim that does not keep a shield never raises it.
    out = run({ "wait 3" }, nil, env(), start({ shieldFrom = -3.83 }))
    expect(find(out, "defence", "shield.up")).toBeNil()
  end)
  it("a smoke for rebounding in the log: the aura comes up one clock.rebounding after it", function()
    local out = run({ "wait 3" }, nil, env({ defences = { rebounding = true } }), start({ reboundingFrom = -7.49 }))
    expect(close(find(out, "defence", "rebounding.up").t, 1.0)).toBeTrue()
  end)
  it("an apply of the coating in the log: it hardens one defence.sileris.harden later (review R3-fork-8)", function()
    local m = model({ sileris = { harden = { median = 10.0, sd = 0 } } })
    local out = run({ "wait 1", "bite curare" }, m, env(), start({ silerisFrom = -7.0 }))
    expect(close(find(out, "defence", "sileris.up").t, 3.0)).toBeTrue()
    -- The BITE at 1.0 lands; one at 4.0 meets the coating.
    local bite = find(out, "attack", "bite")
    expect(bite ~= nil and bite.result == "hit").toBeTrue()
    out = run({ "wait 4", "bite curare" }, m, env(), start({ silerisFrom = -7.0 }))
    bite = find(out, "attack", "bite")
    expect(bite ~= nil and bite.result == "sileris").toBeTrue()
  end)
  it("an apply does not harden while slickness is on at the mark (defence.sileris.slickness_harden, Z5 4096)", function()
    -- The coating is due at +3.00. Slickness lands at +2.95, and the eat cures it 0.14 s later, after the mark.
    local m = model({ sileris = { harden = { median = 10.0, sd = 0 } } })
    local out = run({ "wait 2.95", "give slickness", "bite curare" }, m, env({ gap = 1.0 }), start({ silerisFrom = -7.0 }))
    expect(close(find(out, "cure", "eat").t, 3.09)).toBeTrue()
    expect(find(out, "defence", "sileris.up")).toBeNil()
    -- A world line says why no coating came (review round 6).
    expect(close(find(out, "defence", "sileris.unhardened").t, 3.0)).toBeTrue()
    expect(find(out, "attack", "bite").result).toBe("hit")
    -- Slickness cured before the mark: the coating hardens (10 of the 43 that hardened took slickness in the wait).
    out = run({ "wait 2.5", "give slickness", "bite curare" }, m, env({ gap = 1.0 }), start({ silerisFrom = -7.0 }))
    expect(close(find(out, "defence", "sileris.up").t, 3.0)).toBeTrue()
    expect(find(out, "attack", "bite").result).toBe("sileris")
  end)
  it("a clock with quantiles is drawn from them and stays in its measured range (review LUA-N2-7)", function()
    local c = { median = 5.826, sd = 4.129, min = 2.59, p10 = 3.238, p90 = 13.821, max = 15.277 }
    expect(V.clock(c, { median = true })).toBe(5.826)
    local rnd = forward.rng(12345)
    local low, high, n = 0, 0, 4000
    for _ = 1, n do
      local v = V.clock(c, { median = false }, rnd)
      expect(v >= c.min and v <= c.max).toBeTrue()
      if v <= c.p10 then low = low + 1 end
      if v >= c.p90 then high = high + 1 end
    end
    expect(low / n > 0.08 and low / n < 0.12).toBeTrue()
    expect(high / n > 0.08 and high / n < 0.12).toBeTrue()
  end)
  it("a tail reaches one p10-p90 width past p10 or p90, never a log's outlier (rule draw.shape)", function()
    -- clock.rebounding: min 0.026 and max 250.253 are lost lines. Its draws stay in 8.397 - 0.178 .. 8.575 + 0.178.
    local c = { median = 8.49, sd = 0.069, min = 0.026, p10 = 8.397, p90 = 8.575, max = 250.253 }
    local lo, hi = V.tails(c)
    expect(close(lo, 8.219)).toBeTrue()
    expect(close(hi, 8.753)).toBeTrue()
    local rnd = forward.rng(777)
    for _ = 1, 2000 do
      local v = V.clock(c, { median = false }, rnd)
      expect(v >= lo - 1e-9 and v <= hi + 1e-9).toBeTrue()
    end
    -- The alternative: the almost normal draw around the median.
    local m, k = 0, 2000
    for _ = 1, k do m = m + V.clock(c, { median = false, clockDraw = "normal" }, rnd) end
    expect(math.abs(m / k - 8.49) < 0.01).toBeTrue()
  end)
  it("the normal draw stays inside min and max (review LUA-N2-7)", function()
    local c = { median = 1.5, sd = 0.5, min = 1.2, max = 1.9 }
    local rnd = forward.rng(4242)
    local atMax, atMin = 0, 0
    for _ = 1, 2000 do
      local v = V.clock(c, { median = false, clockDraw = "normal" }, rnd)
      expect(v >= 1.2 and v <= 1.9).toBeTrue()
      if v == 1.9 then atMax = atMax + 1 end
      if v == 1.2 then atMin = atMin + 1 end
    end
    expect(atMax > 0 and atMin > 0).toBeTrue()
  end)
  it("a clock already run is drawn from the part above the time run, in both shapes (review R3-engine-1)", function()
    -- Elmer's eat, in the normal shape: median 1.492, sd 0.075, so the longest draw is 1.717. After 1.59 s every draw
    -- ends later than 1.59, and the median of that part is above 1.59. Before the fix most draws ended the clock at once.
    local c = { median = 1.492, sd = 0.075, min = 1.2, max = 2.5 }
    local normal = { median = false, clockDraw = "normal" }
    local rnd = forward.rng(99)
    for _ = 1, 2000 do
      local v = V.clockAfter(c, normal, rnd, 1.59)
      expect(v > 1.59 and v <= 1.717 + 1e-9).toBeTrue()
    end
    local mid = V.clockAfter(c, { median = true, clockDraw = "normal" }, nil, 1.59)
    expect(mid > 1.59 and mid < 1.717).toBeTrue()
    -- Past the longest draw the clock ends now; under min the whole spread is left (the plain median).
    expect(V.clockAfter(c, normal, rnd, 1.8)).toBe(1.8)
    expect(close(V.clockAfter(c, { median = true, clockDraw = "normal" }, nil, 0.5), 1.492)).toBeTrue()
    -- The quantile shape, for the same case.
    local q = { median = 1.492, sd = 0.075, min = 1.2, p10 = 1.41, p90 = 1.593, max = 2.5 }
    for _ = 1, 500 do
      local v = V.clockAfter(q, { median = false }, rnd, 1.59)
      expect(v > 1.59 and v <= 1.776 + 1e-9).toBeTrue()
    end
  end)
end)

describe("the arm names in the true label (review LUA-N2-1)", function()
  local base = { asthma = true, slickness = true, anorexia = true, impatience = true, paralysis = true }
  local function with(left, right)
    local t = {}
    for k in pairs(base) do t[k] = true end
    t[left], t[right] = true, true
    return t
  end
  it("a damaged or mangled arm counts as broken on either side", function()
    for _, pair in ipairs({ { "damagedleftarm", "brokenrightarm" }, { "brokenleftarm", "damagedrightarm" },
                            { "mangledleftarm", "brokenrightarm" }, { "brokenleftarm", "mangledrightarm" } }) do
      local _, tru = V.labels(with(pair[1], pair[2]), "stupidity", false)
      expect(tru).toBeTrue()
    end
    -- One arm alone does not.
    local one = with("damagedleftarm", "damagedleftarm")
    local _, tru = V.labels(one, "stupidity", false)
    expect(tru).toBeFalse()
  end)
end)

describe("the run's end", function()
  it("holds until a spent eat comes back, so the stream has its recovery line (review ENG-3)", function()
    local out = run({ "dstab curare kalmia", "dstab curare kalmia" }, nil, env({ gap = 1.0, tail = 0.3 }))
    local back = find(out, "recover", "eat", 1.0)
    expect(back ~= nil).toBeTrue()
    expect(out.stopAt >= back.t).toBeTrue()
  end)
  it("the hold passes the horizon, so the last paired race keeps its recovery line (review R3-engine-3)", function()
    -- The eat goes at 0.14 and is back at 1.64. The second DSTAB at 1.0 finds it down. The horizon is 1.5.
    local out = run({ "dstab curare kalmia", "dstab curare kalmia" }, nil, env({ gap = 1.0, tail = 0.3, horizon = 1.5 }))
    expect(out.notRun).toBeNil()
    expect(close(find(out, "recover", "eat", 1.0).t, 1.64)).toBeTrue()
    -- The horizon cuts the third DSTAB (at 2.0), and the run still holds for the eat down at the second.
    out = run({ "dstab curare kalmia", "dstab curare kalmia", "dstab curare kalmia" }, nil,
              env({ gap = 1.0, tail = 0.3, horizon = 1.5 }))
    expect(out.notRun).toBe(1)
    expect(#out.strikes).toBe(2)
    expect(close(find(out, "recover", "eat", 1.0).t, 1.64)).toBeTrue()
  end)
end)

describe("the random streams", function()
  it("the stream seeds are not shifted copies: two streams' first draws do not move together over seeds", function()
    local n, sx, sy, sxx, syy, sxy = 400, 0, 0, 0, 0, 0
    for seed = 1, n do
      local x = forward.rng(F.streamSeed(seed, 1))()
      local y = forward.rng(F.streamSeed(seed, 2))()
      sx, sy, sxx, syy, sxy = sx + x, sy + y, sxx + x * x, syy + y * y, sxy + x * y
    end
    local cov = sxy / n - (sx / n) * (sy / n)
    local corr = cov / math.sqrt((sxx / n - (sx / n) ^ 2) * (syy / n - (sy / n) ^ 2))
    expect(math.abs(corr) < 0.15).toBeTrue()
  end)
  local function names(out)
    local parts = {}
    for _, ev in ipairs(out.events) do parts[#parts + 1] = string.format("%s:%s:%.6f", ev.kind, ev.name, ev.t) end
    return table.concat(parts, " ")
  end
  local lines = { "dstab curare kalmia", "dstab curare kalmia", "dstab gecko slike", "dstab curare vernalius" }
  it("one seed gives one stream", function()
    local e = env({ median = false, gapSd = 0.09 })
    expect(names(run(lines, nil, e, nil, 7))).toBe(names(run(lines, nil, e, nil, 7)))
  end)
  it("another seed gives another", function()
    local e = env({ median = false, gapSd = 0.09 })
    expect(names(run(lines, nil, e, nil, 7)) == names(run(lines, nil, e, nil, 8))).toBeFalse()
  end)
end)
