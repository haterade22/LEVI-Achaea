--- victim.lua -- the victim of the whole-fight engine: its cure channels, its class cure and its defences.
-- Pure Lua 5.1: no Mudlet calls, no files, no globals. tools/sim/fight.lua runs it; the rules come from
-- kb/sim/rules.json through tools/theorycraft.py, and each rule there has its tag and its source.
--
-- The victim describes the four loggers' curing. It never predicts a live opponent's herb (master plan:181).

local V = {}

-- The channels server-side curing (SSC) runs, in the order it runs them at one moment. "class" is the class cure.
V.CHANNELS = { "eat", "smoke", "salve", "focus", "tree", "class" }

-- A clock with noise. env.median takes the median. A clock with its measured quantiles (min, p10, median, p90, max)
-- is drawn from them (rule draw.shape): one uniform draw, linear between five points, so a skewed clock keeps its
-- shape (review LUA-N2-7). Each tail holds 10% of the draws and reaches one p10-p90 width past p10 or p90, never past
-- min or max: a log's min and max are often a lost line or a slowing affliction (clock.rebounding: 0.026 and 250.253
-- around a median of 8.49). With env.clockDraw "normal" (the rule's alternative), or a clock with no quantiles, three
-- uniform draws make an almost normal draw (forward.lua:43), held inside min and max.
local QUANTILES = { 0, 0.1, 0.5, 0.9, 1 }
function V.tails(c)
  local w = c.p90 - c.p10
  return math.max(c.min, c.p10 - w), math.min(c.max, c.p90 + w)
end

local function quantiled(c, env)
  return c.p10 and c.p90 and c.min and c.max and env.clockDraw ~= "normal"
end

local function points(c)
  local lo, hi = V.tails(c)
  return { lo, c.p10, c.median, c.p90, hi }
end

-- The value at share u of the draws (0..1), linear between the five points.
local function at(p, u)
  for i = 2, #QUANTILES do
    if u <= QUANTILES[i] then
      local f = (u - QUANTILES[i - 1]) / (QUANTILES[i] - QUANTILES[i - 1])
      return p[i - 1] + f * (p[i] - p[i - 1])
    end
  end
  return p[#p]
end

-- The share of the draws at or below x: the inverse of at().
local function share(p, x)
  if x <= p[1] then return 0 end
  for i = 2, #p do
    if x <= p[i] then
      local span = p[i] - p[i - 1]
      local f = span > 0 and (x - p[i - 1]) / span or 1
      return QUANTILES[i - 1] + f * (QUANTILES[i] - QUANTILES[i - 1])
    end
  end
  return 1
end

-- The normal shape: the sum of three uniform draws (0..3), scaled so that 0 and 3 are the median -/+ 3 sd, held inside
-- min and max. ihShare is the share of the sums at or below s; ihAt is its inverse.
local function ihShare(s)
  if s <= 0 then return 0 end
  if s <= 1 then return s ^ 3 / 6 end
  if s <= 2 then return (-2 * s ^ 3 + 9 * s ^ 2 - 9 * s + 3) / 6 end
  if s < 3 then return 1 - (3 - s) ^ 3 / 6 end
  return 1
end

local function ihAt(u)
  local lo, hi = 0, 3
  for _ = 1, 60 do
    local mid = (lo + hi) / 2
    if ihShare(mid) < u then lo = mid else hi = mid end
  end
  return (lo + hi) / 2
end

local function held(c, v)
  if c.min and v < c.min then v = c.min end
  if c.max and v > c.max then v = c.max end
  return v
end

function V.clock(c, env, rnd)
  if env.median or not rnd then return c.median end
  if quantiled(c, env) then return at(points(c), rnd()) end
  return held(c, c.median + (rnd() + rnd() + rnd() - 1.5) * 2 * (c.sd or 0))
end

--- A clock that has already run `elapsed` seconds without ending: its length, drawn from the part of its spread above
--- elapsed, so a fork never ends it at once (a shield 7.36 s after a FLAY came up at the fork's first moment, az 1500).
--- env.median takes the median of that part, which rests on the shape (rule draw.shape) as a draw does. A clock whose
--- longest draw is at or under elapsed ends now (returns elapsed). Both shapes draw from the part above elapsed: the
--- normal shape through its own share function (review R3-engine-1: it took the larger of elapsed and a plain draw, so
--- most draws ended the clock at once).
function V.clockAfter(c, env, rnd, elapsed)
  if elapsed <= 0 then return V.clock(c, env, rnd) end
  local pick = function(u0) return (env.median or not rnd) and (u0 + 1) / 2 or u0 + rnd() * (1 - u0) end
  if quantiled(c, env) then
    local p = points(c)
    if elapsed >= p[#p] then return elapsed end
    return math.max(elapsed, at(p, pick(share(p, elapsed))))
  end
  local sd = c.sd or 0
  local top = held(c, c.median + 3 * sd)
  if elapsed >= top then return elapsed end
  if sd <= 0 then return math.max(elapsed, held(c, c.median)) end
  -- Under min every draw is above elapsed (a low draw is held at min), so the whole spread is left.
  local u0 = (c.min and elapsed < c.min) and 0 or ihShare((elapsed - c.median) / (2 * sd) + 1.5)
  return math.max(elapsed, held(c, c.median + (ihAt(pick(u0)) - 1.5) * 2 * sd))
end

--- The reaction delay of SSC, from the moment a channel can act to the action (rule ssc.delay).
function V.delay(model, env, rnd)
  local d = model.ssc
  if env.median or not rnd then return d.median end
  return d.min + rnd() * (d.max - d.min)
end

--- Why a channel cannot act now: the affliction that shuts it, "clock", or nil when it is open.
function V.shut(s, ch, model, t)
  if ch == "class" then
    local cc = model.classcure
    if not cc then return "none" end
    if t < s.ready.class then return "clock" end
    for i = 1, #cc.blocked_by do
      if s.affs[cc.blocked_by[i]] then return cc.blocked_by[i] end
    end
    if cc.needs_bal and t < s.ready.bal then return "bal" end
    if cc.needs_eq and t < s.ready.eq then return "eq" end
    return nil
  end
  local aff = model.blocked[ch]
  if aff and s.affs[aff] then return aff end
  if t < s.ready[ch] then return "clock" end
  return nil
end

local function prio(model, aff)
  return model.prio[aff] or 99
end

-- The afflictions up that a list holds, best priority first. Ties go by name, so the order never depends on pairs().
local function upIn(s, list, model)
  local out = {}
  for i = 1, #list do
    if s.affs[list[i]] then out[#out + 1] = list[i] end
  end
  table.sort(out, function(a, b)
    local pa, pb = prio(model, a), prio(model, b)
    if pa ~= pb then return pa < pb end
    return a < b
  end)
  return out
end

--- The affliction an eat takes. Priority picks the herb. Inside the herb, the top affliction wins with chance phi,
--- and otherwise one of the others does (forward.lua:113-134, rule ssc.phi). env.median always takes the top one.
function V.pickEat(s, model, env, rnd)
  local up = upIn(s, model.lists.eat, model)
  local best = up[1]
  if not best then return nil end
  local herb = model.herb[best]
  local others = {}
  for i = 2, #up do
    if model.herb[up[i]] == herb then others[#others + 1] = up[i] end
  end
  if #others == 0 or env.median or not rnd or rnd() < model.phi then return best end
  return others[math.floor(rnd() * #others) + 1]
end

--- Focus takes a mental first, and anorexia only when no mental is up (rule focus.order).
function V.pickFocus(s, model)
  local up = upIn(s, model.lists.focus, model)
  for i = 1, #up do
    if up[i] ~= "anorexia" then return up[i] end
  end
  return up[1]
end

--- One affliction among those a random cure can take: uniform (rule tree.pick), or the top priority with env.median.
function V.pickRandom(s, model, env, rnd, first)
  if first and s.affs[first] then return first end
  local up = upIn(s, model.lists.random, model)
  if #up == 0 then return nil end
  if env.median or not rnd or env.treePick == "priority" then return up[1] end
  table.sort(up)
  return up[math.floor(rnd() * #up) + 1]
end

local function softlocked(s)
  return s.affs.asthma and (s.affs.slickness or s.affs.bloodfire) and s.affs.anorexia
end

--- What the channel would act on now: an affliction, "rebounding" for the smoke that raises it, or nil.
function V.target(s, ch, model, env, rnds)
  if ch == "eat" then return V.pickEat(s, model, env, rnds.pick) end
  if ch == "focus" then return V.pickFocus(s, model) end
  if ch == "smoke" or ch == "salve" then
    local up = upIn(s, model.lists[ch], model)
    if up[1] then return up[1] end
    if ch == "smoke" and env.defences.rebounding and not s.defs.rebounding and not s.reboundingAt then
      return "rebounding"
    end
    return nil
  end
  if ch == "tree" then
    if env.tree == "hold" and not softlocked(s) then return nil end
    local up = upIn(s, model.lists.random, model)
    if up[1] then return "random" end
    return nil
  end
  if ch == "class" then
    local cc = model.classcure
    if cc.cures == "one" then
      local up = upIn(s, model.lists.random, model)
      return up[1] and "random" or nil
    end
    local up = upIn(s, cc.cures, model)
    return up[1]
  end
end

--- Act on a channel. It assumes the channel is open. Returns the afflictions cured (a list), the item, and
--- "rebounding" when the smoke raised the aura instead. A class cure spends its lockout, and the balance and
--- equilibrium its rule names (class.fitness spends balance; class.salt and class.accelerate spend equilibrium).
--- A random class cure takes cc.count afflictions (rule class.accelerate.cures: one, or two when boosted).
function V.act(s, ch, aff, t, model, env, rnds)
  local cc = model.classcure
  local cured = {}
  if ch == "tree" then
    aff = V.pickRandom(s, model, env, rnds.tree)
    s.ready.tree = t + V.clock(model.clocks.tree, env, rnds.tree)
  elseif ch == "class" then
    s.ready.class = t + V.clock(cc.lockout, env, rnds.class)
    if cc.spends_bal then s.ready.bal = t + cc.spends_bal end
    if cc.spends_eq then s.ready.eq = t + cc.spends_eq end
    if aff == "random" then
      for _ = 1, cc.count or 1 do
        local one = V.pickRandom(s, model, env, rnds.class)
        if not one then break end
        s.affs[one] = nil
        cured[#cured + 1] = one
      end
      return cured, nil
    end
  elseif ch == "smoke" and aff == "rebounding" then
    s.ready.smoke = t + V.clock(model.clocks.smoke, env, rnds.smoke)
    s.reboundingAt = t + V.clock(model.clocks.rebounding, env, rnds.smoke)
    -- The logger's own item for it (rule defence.rebounding.smoke): skullcap for herbs, malachite for minerals.
    return cured, model.reboundItem or "skullcap", "rebounding"
  else
    s.ready[ch] = t + V.clock(model.clocks[ch], env, rnds[ch])
  end
  if aff then
    s.affs[aff] = nil
    cured[1] = aff
  end
  local items = model.items[ch]
  return cured, items and aff and items[aff] or nil
end

--- The shield: it needs equilibrium, and paralysis holds it unless the rule says otherwise (defence.shield.*).
function V.shieldOpen(s, model, env, t)
  if not env.defences.shield or s.defs.shield or t < s.ready.eq then return false end
  if s.affs.paralysis and not model.shield.whileParalysed then return false end
  return true
end

function V.raiseShield(s, model, t)
  s.defs.shield = true
  s.ready.eq = t + model.shield.cost
end

--- The labels of kb_replay.py:645-679. terms is the set of afflictions up; classDown is the class cure's clock.
--- blocker is the label's blocker for the victim's class (ACTIVE_CURE_BLOCKERS), nil when the class has none.
function V.labels(terms, blocker, classDown)
  local soft = (terms.asthma and (terms.slickness or terms.bloodfire) and terms.anorexia) and true or false
  local blocked
  if classDown then
    blocked = true
  elseif blocker == nil then
    blocked = true
  else
    -- kb_replay's names (leftarm1, leftarm2) and the engine's (brokenleftarm, from venom.epteth), so the both-arms
    -- clause of is_true fires in a run too (review LUA-N2-1).
    local left = terms.leftarm1 or terms.leftarm2 or terms.brokenleftarm or terms.damagedleftarm or terms.mangledleftarm
    local right = terms.rightarm1 or terms.rightarm2 or terms.brokenrightarm or terms.damagedrightarm
      or terms.mangledrightarm
    local bothArms = left and right
    if bothArms and blocker ~= "weariness" then
      blocked = true
    else
      blocked = terms[blocker] and true or false
    end
  end
  local tru = soft and (terms.impatience or terms.sandfever) and terms.paralysis and blocked
  return soft, tru and true or false
end

return V
