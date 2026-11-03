--- test_sim_forward.lua -- the rules of tools/sim/forward.lua (plan step 7, first stage).
-- Each case pins one game rule that the engine must follow. kb/sim/forward.md cites the evidence.
-- The first lines also hold the engine to Lua 5.1, which is what kb_sim.py must run it on.

local F = dofile("tools/sim/forward.lua")

local MODEL = {
  clocks = { eat = 1.5, smoke = 1.48, salve = 0.91, focus = 2.43, tree = 13.96, fitnessBal = 2.8 },
  sd = { eat = 0, smoke = 0, salve = 0, focus = 0, tree = 0 },
  prio = { paralysis = 3, slickness = 3, anorexia = 4, impatience = 4, hypochondria = 5, weariness = 6,
           asthma = 7, clumsiness = 7, stupidity = 8 },
  herb = { paralysis = "bloodroot", slickness = "bloodroot", impatience = "goldenseal", stupidity = "goldenseal",
           hypochondria = "lobelia", weariness = "kelp", asthma = "kelp", clumsiness = "kelp" },
  eatList = { "asthma", "clumsiness", "hypochondria", "impatience", "paralysis", "slickness", "stupidity", "weariness" },
  focusList = { "stupidity" },
  allList = { "anorexia", "asthma", "clumsiness", "hypochondria", "impatience", "paralysis", "slickness",
              "stupidity", "weariness" },
}

-- An attacker who never reaches the horizon, unless the case sets a gap.
local function env(over)
  local e = { attacker = "lock", phi = 1, gap = 100, eqCost = 3.4, lockout = 9.81, chain = 9.31, horizon = 20 }
  for k, v in pairs(over or {}) do e[k] = v end
  return e
end

local function policy(over)
  local p = { eq = "hold", tree = "hold", herb = "default" }
  for k, v in pairs(over or {}) do p[k] = v end
  return p
end

local function state(affs, ready)
  local s = { affs = {}, ready = { eat = 0, smoke = 0, salve = 0, focus = 0, tree = 0, fitness = 0, bal = 0, eq = 0 } }
  for _, a in ipairs(affs) do s.affs[a] = true end
  for k, v in pairs(ready or {}) do s.ready[k] = v end
  return s
end

describe("the runtime", function()
  it("is Lua 5.1", function()
    expect(_VERSION).toBe("Lua 5.1")
  end)
end)

describe("the generator", function()
  it("gives the Park-Miller check value after 10,000 steps", function()
    local x = 1
    for _ = 1, 10000 do x = F.step(x) end
    expect(x).toBe(1043618065)
  end)

  it("repeats for one seed and differs for another", function()
    local a, b, c = F.rng(7), F.rng(7), F.rng(8)
    local first = a()
    expect(first).toBe(b())
    expect(first == c()).toBeFalse()
  end)
end)

describe("FITNESS", function()
  it("needs equilibrium", function()
    expect(F.fitnessOpen(state({ "asthma" }, { eq = 2 }), 1) and true or false).toBeFalse()
    expect(F.fitnessOpen(state({ "asthma" }, { eq = 2 }), 2) and true or false).toBeTrue()
  end)

  it("needs balance", function()
    expect(F.fitnessOpen(state({ "asthma" }, { bal = 2 }), 1) and true or false).toBeFalse()
  end)

  it("is refused by weariness", function()
    expect(F.fitnessOpen(state({ "asthma", "weariness" }), 0) and true or false).toBeFalse()
  end)

  it("waits for its lockout", function()
    expect(F.fitnessOpen(state({ "asthma" }, { fitness = 5 }), 1) and true or false).toBeFalse()
  end)

  it("runs while paralysed", function()
    expect(F.fitnessOpen(state({ "asthma", "paralysis" }), 0) and true or false).toBeTrue()
  end)
end)

describe("channels", function()
  local function after(affs, ready, over)
    local o = F.run({ affs = affs, ready = ready }, policy(), env(over), MODEL, 1)
    return o
  end

  it("anorexia shuts eating: asthma stays with weariness up", function()
    local o = after({ "asthma", "weariness", "anorexia", "slickness", "impatience" }, { tree = 50 }, { horizon = 5 })
    expect(o.asthmaOffAt).toBeNil()
  end)

  it("asthma shuts the pipe, so slickness and anorexia stay", function()
    local o = after({ "asthma", "weariness", "anorexia", "slickness", "impatience" }, { tree = 50 }, { horizon = 5 })
    expect(o.softAt).toBe(0)
    expect(o.softTime).toBe(5)
  end)

  it("focus opens eating when impatience is absent", function()
    local o = after({ "asthma", "weariness", "anorexia", "slickness" }, { tree = 50 }, { horizon = 5 })
    expect(o.asthmaOffAt ~= nil).toBeTrue()
  end)

  it("paralysis shuts the tree", function()
    local s = { "asthma", "slickness", "anorexia", "impatience", "paralysis" }
    local o = F.run({ affs = s, ready = { eat = 50 } }, policy({ tree = "now" }), env({ horizon = 15 }), MODEL, 1)
    expect(o.closeAt).toBeNil()   -- FITNESS is open, as no weariness is up.
    expect(o.fitness).toBe(1)
  end)

  it("a held tree waits for a softlock", function()
    local b = { affs = { "clumsiness" }, ready = { eat = 50 } }
    expect(F.run(b, policy({ tree = "hold" }), env({ horizon = 3 }), MODEL, 1).affs.clumsiness).toBeTrue()
    expect(F.run(b, policy({ tree = "now" }), env({ horizon = 3 }), MODEL, 1).affs.clumsiness).toBeNil()
    local soft = { affs = { "asthma", "slickness", "anorexia", "impatience" }, ready = { eat = 50, focus = 50 } }
    expect(F.run(soft, policy({ tree = "hold" }), env({ horizon = 3 }), MODEL, 1).softTime < 3).toBeTrue()
  end)
end)

describe("the herb pick", function()
  local rnd1 = function() return 0.99 end
  local rnd0 = function() return 0.0 end

  it("takes the top priority herb", function()
    local s = state({ "asthma", "paralysis" })
    expect(F.pickEat(s, policy(), env({ phi = 1 }), MODEL, rnd0)).toBe("paralysis")
  end)

  it("moves asthma to the front with the asthma policy", function()
    local s = state({ "asthma", "paralysis" })
    expect(F.pickEat(s, policy({ herb = "asthma" }), env({ phi = 1 }), MODEL, rnd0)).toBe("asthma")
  end)

  it("runs the package's Serpent rules: the tie goes either way", function()
    local s = state({ "asthma", "paralysis", "weariness" })
    expect(F.pickEat(s, policy({ herb = "package" }), env({ phi = 1 }), MODEL, rnd0)).toBe("asthma")
    expect(F.pickEat(s, policy({ herb = "packageLate" }), env({ phi = 1 }), MODEL, rnd0)).toBe("paralysis")
  end)

  it("the package moves paralysis up once slickness joins asthma", function()
    local s = state({ "asthma", "paralysis", "slickness", "weariness" })
    expect(F.pickEat(s, policy({ herb = "package" }), env({ phi = 1 }), MODEL, rnd0)).toBe("paralysis")
  end)

  it("the package leaves asthma alone with no weariness up", function()
    local s = state({ "asthma", "paralysis" })
    expect(F.pickEat(s, policy({ herb = "package" }), env({ phi = 1 }), MODEL, rnd0)).toBe("paralysis")
  end)

  it("can take the other affliction in the herb when phi is below 1", function()
    local s = state({ "asthma", "weariness" })
    expect(F.pickEat(s, policy(), env({ phi = 0.5 }), MODEL, rnd1)).toBe("asthma")
    expect(F.pickEat(s, policy(), env({ phi = 0.5 }), MODEL, rnd0)).toBe("weariness")
  end)

  it("takes a mental with focus before anorexia", function()
    local s = state({ "anorexia", "stupidity" })
    expect(F.pickFocus(s, policy(), MODEL)).toBe("stupidity")
    expect(F.pickFocus(state({ "anorexia" }), policy(), MODEL)).toBe("anorexia")
  end)
end)

describe("the shield", function()
  local board = { affs = { "asthma", "weariness" }, ready = { eat = 50, tree = 50 } }

  it("costs the attacker one venom: FLAY delivers one, DSTAB two", function()
    local e = env({ gap = 1.6, horizon = 2 })
    local held = F.run(board, policy({ eq = "hold" }), e, MODEL, 3)
    local up = F.run(board, policy({ eq = "once" }), e, MODEL, 3)
    expect(held.flays).toBe(0)
    expect(up.flays).toBe(1)
    expect(up.shields).toBe(1)
  end)

  it("takes equilibrium, so FITNESS waits for it", function()
    local b = { affs = { "asthma" }, ready = { eat = 50, tree = 50, fitness = 1 } }
    local e = env({ eqCost = 4, horizon = 8 })
    local held = F.run(b, policy({ eq = "hold" }), e, MODEL, 3)
    local up = F.run(b, policy({ eq = "once" }), e, MODEL, 3)
    expect(held.asthmaOffAt).toBe(1)
    expect(up.asthmaOffAt).toBe(4)
  end)

  it("waits for paralysis unless the input says otherwise", function()
    local b = { affs = { "paralysis" }, ready = { eat = 50, tree = 50 } }
    expect(F.run(b, policy({ eq = "once" }), env({ horizon = 2 }), MODEL, 3).shields).toBe(0)
    expect(F.run(b, policy({ eq = "once" }), env({ horizon = 2, shieldWhileParalysed = true }), MODEL, 3).shields).toBe(1)
  end)

  it("a FLAY can have its own gap to the next attack", function()
    local b = { affs = { "clumsiness" }, ready = { eat = 50, tree = 50, smoke = 50, focus = 50, salve = 50 } }
    local plain = F.run(b, policy({ eq = "once" }), env({ gap = 5, horizon = 6, shieldWhileParalysed = true }), MODEL, 3)
    local quick = F.run(b, policy({ eq = "once" }), env({ gap = 5, flayGap = 1, horizon = 6, shieldWhileParalysed = true }), MODEL, 3)
    local count = function(o) local n = 0; for _ in pairs(o.affs) do n = n + 1 end; return n end
    expect(count(quick) > count(plain)).toBeTrue()
  end)

  it("once means one, always means again when equilibrium returns", function()
    local b = { affs = { "clumsiness" }, ready = { eat = 50, tree = 50 } }
    local e = env({ gap = 1.6, horizon = 15, eqCost = 3, shieldWhileParalysed = true })
    expect(F.run(b, policy({ eq = "once" }), e, MODEL, 3).shields).toBe(1)
    expect(F.run(b, policy({ eq = "always" }), e, MODEL, 3).shields > 1).toBeTrue()
  end)
end)

describe("closure", function()
  it("needs softlock, impatience, paralysis and a shut class cure", function()
    local all = { "asthma", "slickness", "anorexia", "impatience", "paralysis", "weariness" }
    expect(F.closed(state(all), 0) and true or false).toBeTrue()
    for _, missing in ipairs(all) do
      local rest = {}
      for _, a in ipairs(all) do if a ~= missing then rest[#rest + 1] = a end end
      expect(F.closed(state(rest), 0) and true or false).toBeFalse()
    end
  end)

  it("counts the FITNESS lockout as a shut class cure", function()
    local s = { "asthma", "slickness", "anorexia", "impatience", "paralysis" }
    expect(F.closed(state(s, { fitness = 3 }), 1) and true or false).toBeTrue()
    expect(F.closed(state(s, { fitness = 3 }), 4) and true or false).toBeFalse()
  end)

  it("stops the run at a closed board", function()
    local all = { "asthma", "slickness", "anorexia", "impatience", "paralysis", "weariness" }
    local o = F.run({ affs = all, ready = { eat = 50, tree = 50 } }, policy(), env(), MODEL, 1)
    expect(o.closeAt).toBe(0)
  end)
end)

describe("timed supply", function()
  it("lands impatience at its time, with no attacker line", function()
    local b = { affs = { "asthma", "slickness", "anorexia", "paralysis", "weariness" }, ready = { tree = 50, focus = 50 } }
    local o = F.run(b, policy(), env({ impFirst = 4, horizon = 20 }), MODEL, 1)
    expect(o.closeAt).toBe(4)
  end)

  it("a hypochondria left up brings impatience at 9.31 s", function()
    local b = { affs = { "asthma", "slickness", "anorexia", "paralysis", "weariness", "hypochondria" },
                ready = { tree = 50, focus = 50 }, hchonAge = 5.31 }
    local o = F.run(b, policy(), env({ horizon = 20 }), MODEL, 1)
    expect(math.abs(o.closeAt - 4) < 1e-9).toBeTrue()
  end)
end)

describe("a run", function()
  local board = { affs = { "asthma", "weariness" }, ready = {} }
  local e = env({ gap = 1.545, phi = 0.6, impFirst = 2, impEvery = 9.31 })
  local noisy = {}
  for k, v in pairs(MODEL) do noisy[k] = v end
  noisy.sd = { eat = 0.09, smoke = 0.07, salve = 0.05, focus = 0.08, tree = 0.06 }

  it("repeats for one seed", function()
    local a = F.run(board, policy(), e, noisy, 42)
    local b = F.run(board, policy(), e, noisy, 42)
    expect(a.closeAt).toBe(b.closeAt)
    expect(a.softTime).toBe(b.softTime)
    expect(a.fitness).toBe(b.fitness)
  end)

  it("does not change the board", function()
    F.run(board, policy({ eq = "always", tree = "now" }), e, noisy, 42)
    expect(#board.affs).toBe(2)
    expect(next(board.ready)).toBeNil()
  end)

  it("never runs past the horizon", function()
    for seed = 1, 30 do
      local o = F.run(board, policy(), e, noisy, seed)
      expect((o.closeAt or 0) <= 20).toBeTrue()
      expect(o.softTime <= 20 + 1e-9).toBeTrue()
    end
  end)

  it("a cell counts its runs and pairs them by seed", function()
    local r1 = F.cell(board, policy(), e, noisy, 40, 1000)
    local r2 = F.cell(board, policy(), e, noisy, 40, 1000)
    expect(r1.n).toBe(40)
    expect(r1.close).toBe(r2.close)
    expect(r1.softTime).toBe(r2.softTime)
  end)
end)
