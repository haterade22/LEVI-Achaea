--- forward.lua -- step 7, first stage: 20 s forward from a logged board, against a strong attacker.
-- Pure Lua 5.1: no Mudlet calls, no files, no globals. tools/kb_sim.py and test_sim_forward.lua load it.
--
-- It compares the victim's decisions on one board. It does not say who wins a fight, and it does not
-- model how a person adapts. The evidence for each rule is on kb/sim/forward.md.

local M = {}

-- ---------------------------------------------------------------------------------------------
-- Random numbers. math.random gave only 32,767 distinct values, so this file has its own generator.
-- ---------------------------------------------------------------------------------------------

local A, MOD = 16807, 2147483647

--- One step of the Park-Miller generator.
function M.step(x)
  return (A * x) % MOD
end

--- A stream of numbers in (0, 1). Near seeds start near each other, so the first draws are dropped.
function M.rng(seed)
  local x = seed % (MOD - 1) + 1
  for _ = 1, 3 do x = (A * x) % MOD end
  return function()
    x = (A * x) % MOD
    return x / MOD
  end
end

-- Each source has its own stream. A decision then changes only what it touches, so two policies with
-- one seed see the same attacker and the same clocks, and their difference has less noise.
local STREAMS = { "attacker", "eat", "smoke", "salve", "focus", "tree", "pick", "start" }

local function streams(seed)
  local out = {}
  for i, name in ipairs(STREAMS) do
    out[name] = M.rng(seed * 1000003 + i * 7919)
  end
  return out
end

-- A clock with noise. Three uniform draws make an almost normal draw, bounded at 3 standard deviations.
local function noisy(rnd, median, sd)
  return median + (rnd() + rnd() + rnd() - 1.5) * 2 * sd
end

-- ---------------------------------------------------------------------------------------------
-- The attacker. These orders are not a proven worst case: the page says "strong".
-- ---------------------------------------------------------------------------------------------

local FILLER = { "clumsiness", "darkshade", "nausea", "sensitivity", "haemophilia", "addiction" }

M.ATTACKERS = {
  -- Paralysis first spends the victim's eats on the herb that shares nothing with asthma.
  lock = { "paralysis", "asthma", "slickness", "anorexia", "weariness" },
  -- The softlock pieces first.
  soft = { "asthma", "slickness", "anorexia", "paralysis", "weariness" },
  -- Keep the class cure shut first.
  keep = { "weariness", "asthma", "anorexia", "slickness", "paralysis" },
}

local function giveVenoms(s, count, env)
  local order = M.ATTACKERS[env.attacker]
  for i = 1, #order do
    if count == 0 then return end
    local aff = order[i]
    if not s.affs[aff] then
      s.affs[aff] = true
      count = count - 1
    end
  end
  for i = 1, #FILLER do
    if count == 0 then return end
    local aff = FILLER[i]
    if not s.affs[aff] then
      s.affs[aff] = true
      count = count - 1
    end
  end
end

-- A shield turns a two-venom DSTAB into a one-venom FLAY: "flays away your shield defence", then the
-- whip delivers (azbErKcK). The attacker loses one venom, and no time.
local function strike(s, env)
  if s.shield then
    s.shield = false
    s.flays = s.flays + 1
    giveVenoms(s, 1, env)
  else
    giveVenoms(s, 2, env)
  end
end

-- ---------------------------------------------------------------------------------------------
-- The cure channels
-- ---------------------------------------------------------------------------------------------

-- "package" and "packageLate" are the two rules 001_Anti_Priorities.lua runs against a Serpent. astWear sets
-- asthma to 3 with weariness up, which ties with paralysis and slickness. The server's tie order is not
-- known: "package" lets asthma win it, and "packageLate" lets paralysis win it. paraAst sets paralysis
-- to 1 with asthma and slickness up.
local function priority(aff, policy, model, s)
  local herb = policy.herb
  if herb == "asthma" then
    if aff == "asthma" then return 1 end
  elseif herb == "package" or herb == "packageLate" then
    if aff == "paralysis" and s.affs.asthma and s.affs.slickness then return 1 end
    if aff == "asthma" and s.affs.weariness then return herb == "package" and 2.5 or 3.5 end
  end
  return model.prio[aff] or 99
end

--- The affliction an eat takes. Priority picks the herb. Inside the herb, the top affliction wins with
--- chance phi, and otherwise one of the others does: asthma at priority 1 won aurum only 4 of 7.
function M.pickEat(s, policy, env, model, rnd)
  local best, bestPrio
  local list = model.eatList
  for i = 1, #list do
    local aff = list[i]
    if s.affs[aff] then
      local p = priority(aff, policy, model, s)
      if not bestPrio or p < bestPrio then best, bestPrio = aff, p end
    end
  end
  if not best then return nil end
  local herb = model.herb[best]
  local others = {}
  for i = 1, #list do
    local aff = list[i]
    if aff ~= best and s.affs[aff] and model.herb[aff] == herb then others[#others + 1] = aff end
  end
  if #others == 0 or rnd() < env.phi then return best end
  return others[math.floor(rnd() * #others) + 1]
end

--- Focus takes a mental first, and anorexia only with no mental up (LOCK_EXITS in kb_replay.py).
function M.pickFocus(s, policy, model)
  local best, bestPrio
  local list = model.focusList
  for i = 1, #list do
    local aff = list[i]
    if s.affs[aff] then
      local p = priority(aff, policy, model, s)
      if not bestPrio or p < bestPrio then best, bestPrio = aff, p end
    end
  end
  if best then return best end
  return s.affs.anorexia and "anorexia" or nil
end

local function softlocked(s)
  return s.affs.asthma and s.affs.slickness and s.affs.anorexia
end

--- The tree: blocked by paralysis, and it takes one random affliction. "hold" keeps it for a softlock.
local function touchTree(s, t, policy, model, env, st)
  if t < s.ready.tree or s.affs.paralysis then return end
  if policy.tree == "hold" and not softlocked(s) then return end
  local up = {}
  local list = model.allList
  for i = 1, #list do
    if s.affs[list[i]] then up[#up + 1] = list[i] end
  end
  if #up == 0 then return end
  s.affs[up[math.floor(st.tree() * #up) + 1]] = nil
  s.ready.tree = t + noisy(st.tree, model.clocks.tree, model.sd.tree)
end

--- FITNESS needs balance and equilibrium, and weariness refuses it. It spends balance only.
function M.fitnessOpen(s, t)
  return s.affs.asthma and not s.affs.weariness and t >= s.ready.fitness and t >= s.ready.bal and t >= s.ready.eq
end

local function runFitness(s, t, env, model)
  if not M.fitnessOpen(s, t) then return end
  s.affs.asthma = nil
  s.ready.fitness = t + env.lockout
  s.ready.bal = t + model.clocks.fitnessBal
  s.fitness = s.fitness + 1
end

-- A shield needs equilibrium. The shield rows show paralysis cured first, 3 of 4 (kb_sim.py has the row
-- numbers), so paralysis holds it unless env.shieldWhileParalysed says otherwise.
local function raiseShield(s, t, policy, env)
  if policy.eq == "hold" or s.shield or t < s.ready.eq then return end
  if s.affs.paralysis and not env.shieldWhileParalysed then return end
  if policy.eq == "once" and s.shieldsUp > 0 then return end
  s.shield = true
  s.shieldsUp = s.shieldsUp + 1
  s.ready.eq = t + env.eqCost
end

-- Server-side curing runs every open channel at once. FITNESS goes before a shield, as FITNESS spends no
-- equilibrium: a shield first would take the equilibrium FITNESS needs.
local function cure(s, t, policy, env, model, st)
  if t >= s.ready.salve and s.affs.anorexia and not s.affs.slickness then
    s.affs.anorexia = nil
    s.ready.salve = t + noisy(st.salve, model.clocks.salve, model.sd.salve)
  end
  if t >= s.ready.smoke and s.affs.slickness and not s.affs.asthma then
    s.affs.slickness = nil
    s.ready.smoke = t + noisy(st.smoke, model.clocks.smoke, model.sd.smoke)
  end
  if t >= s.ready.focus and not s.affs.impatience then
    local aff = M.pickFocus(s, policy, model)
    if aff then
      s.affs[aff] = nil
      s.ready.focus = t + noisy(st.focus, model.clocks.focus, model.sd.focus)
    end
  end
  if t >= s.ready.eat and not s.affs.anorexia then
    local aff = M.pickEat(s, policy, env, model, st.pick)
    if aff then
      s.affs[aff] = nil
      s.ready.eat = t + noisy(st.eat, model.clocks.eat, model.sd.eat)
    end
  end
  touchTree(s, t, policy, model, env, st)
  runFitness(s, t, env, model)
  raiseShield(s, t, policy, env)
end

--- The replay's `true` label: softlock, impatience, paralysis, and the class cure shut.
function M.closed(s, t)
  return softlocked(s) and s.affs.impatience and s.affs.paralysis
    and (s.affs.weariness or t < s.ready.fitness)
end

-- ---------------------------------------------------------------------------------------------
-- One run
-- ---------------------------------------------------------------------------------------------

local function newState(board, env)
  local s = { affs = {}, ready = {}, shield = false, shieldsUp = 0, flays = 0, fitness = 0 }
  for i = 1, #board.affs do s.affs[board.affs[i]] = true end
  for _, name in ipairs({ "eat", "smoke", "salve", "focus", "tree", "fitness", "bal", "eq" }) do
    s.ready[name] = board.ready and board.ready[name] or 0
  end
  return s
end

-- Timed supply with no attacker line: impatience at env.impFirst, then every env.impEvery. Nil is none.
local function timedImpatience(s, env, t)
  if env.impFirst and t >= s.nextImp then
    s.affs.impatience = true
    s.nextImp = s.nextImp + (env.impEvery or math.huge)
  end
end

-- A hypochondria left up brings impatience 9.31 s after it landed (Z5, one fight). Curing it ends that.
local function hypochondriaChain(s, env, t)
  if s.hchonAt and not s.affs.hypochondria then s.hchonAt = nil end
  if s.affs.hypochondria and not s.hchonAt then s.hchonAt = t end
  if s.hchonAt and t >= s.hchonAt + env.chain then
    s.affs.impatience = true
    s.hchonAt = nil
    s.affs.hypochondria = nil
  end
end

local function nextEvent(s, t, env)
  local best = s.nextStrike
  local ready = s.ready
  for _, name in ipairs({ "eat", "smoke", "salve", "focus", "tree", "fitness", "bal", "eq" }) do
    local at = ready[name]
    if at > t and at < best then best = at end
  end
  if env.impFirst and s.nextImp > t and s.nextImp < best then best = s.nextImp end
  if s.hchonAt and s.hchonAt + env.chain > t and s.hchonAt + env.chain < best then best = s.hchonAt + env.chain end
  return best
end

--- Run one board forward. Returns what happened; it never changes `board`.
function M.run(board, policy, env, model, seed)
  local st = streams(seed)
  local s = newState(board, env)
  local horizon = env.horizon or 20
  local out = { closeAt = nil, softAt = nil, softTime = 0, asthmaOffAt = nil }

  if board.hchonAge and s.affs.hypochondria then s.hchonAt = -board.hchonAge end
  s.nextImp = env.impFirst or math.huge
  -- The board's last strike is not known, so the first one comes inside one gap.
  s.nextStrike = st.start() * env.gap

  local t = 0
  while true do
    timedImpatience(s, env, t)
    hypochondriaChain(s, env, t)
    if t >= s.nextStrike then
      -- FLAY has its own gap to the next attack, when the input gives one.
      local gap = (s.shield and env.flayGap) or env.gap
      strike(s, env)
      s.nextStrike = t + math.max(env.floor or gap, noisy(st.attacker, gap, env.gapSd or 0))
    end
    cure(s, t, policy, env, model, st)

    local soft = softlocked(s)
    if soft and not out.softAt then out.softAt = t end
    if not s.affs.asthma and not out.asthmaOffAt then out.asthmaOffAt = t end
    if M.closed(s, t) then
      out.closeAt = t
      break
    end

    local nextT = nextEvent(s, t, env)
    if nextT > horizon then
      if soft then out.softTime = out.softTime + (horizon - t) end
      break
    end
    if soft then out.softTime = out.softTime + (nextT - t) end
    t = nextT
  end

  out.fitness, out.flays, out.shields, out.affs = s.fitness, s.flays, s.shieldsUp, s.affs
  return out
end

--- Many runs with one policy. `seed + i` is the run's seed, so two policies are paired run by run.
function M.cell(board, policy, env, model, n, seed)
  local r = { n = n, close = 0, soft = 0, softTime = 0, asthmaOff5 = 0, fitness = 0, closeSum = 0 }
  for i = 1, n do
    local o = M.run(board, policy, env, model, seed + i)
    if o.closeAt then
      r.close = r.close + 1
      r.closeSum = r.closeSum + o.closeAt
    end
    if o.softAt then r.soft = r.soft + 1 end
    r.softTime = r.softTime + o.softTime
    if o.asthmaOffAt and o.asthmaOffAt <= 5 then r.asthmaOff5 = r.asthmaOff5 + 1 end
    r.fitness = r.fitness + o.fitness
  end
  return r
end

return M
