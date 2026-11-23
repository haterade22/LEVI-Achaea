--[[mudlet
type: script
name: Numb Debt
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- THE NUMBNESS DEBT (v4.7.512)
--
-- AB Numbness (Kaido 894): "When the numbness wears off, all the damage you would have taken,
-- minus 40%, will be received in one blow." While it is up our health does not move, so the
-- health number is a loan: each hit a denizen lands is owed, and the game collects it in one
-- blow about ten seconds later. The facts and their source are in kb/defences/numbness.md
-- (OURS: 28 cycles of 2026-11-23, kb/raw/live/kaido-numbness-cycles_2026-11-23.txt):
--
--   up     "You grit your teeth and will your pain out of existence."        (highlighting/060)
--   a hit  "You smile as the blow falls painlessly on you."   one line per hit, NO figure, and
--                                                             no "Health lost:" line  (075)
--   down   "You cry out in agony as the effects of your numbness fade away ..."        (074)
--          9.07 to 10.03 s after the up line. The blow has no "Health lost:" line: it shows
--          only as a fall of health in Char.Vitals. Seen: 1,400 to 11,036 of 20,061 health.
--
-- Before this file every safety read the health number as it stood. During the ten seconds
-- they saw full health; at the end the net-delta feed saw 8,591 health go in one prompt, read
-- it as a RATE (8,591 over the 3 s floor = 2,864/s, 4 s to live) and printed "DANGER: Extreme
-- incoming damage". Outside a no-flee area that is a flee, caused by damage ten seconds old.
--
-- So the debt is kept as its own fact, and three things use it:
--   1. `ataxia_effHp` / `ataxia_effHpp`: health minus the debt. The basher's danger level, its
--      time-to-death alarm, the last stand and the swarm ladder read these, so they act on the
--      debt BEFORE the game collects it. A shield or a retreat stops the debt growing.
--   2. Each absorbed hit goes to the rate watchdog when it lands (ataxiaBasher_recordIncoming),
--      at its estimated size. The watchdog is no longer blind while numbness is up.
--   3. The fall of health that pays the debt is not incoming damage a second time: only the
--      part the debt does not explain goes to the net feed (`ataxia_numbNoteDrop`).
--
-- THE SIZE OF ONE ABSORBED HIT is an estimate, because the game prints no figure. It is the
-- LARGER of two readings, each at most SOURCE_AGE seconds old (too small a debt is the unsafe
-- direction):
--   a. DEFER x the mean of our last typed hits ("Health lost: N (type)", never "(raw)");
--   b. the last deferred blow divided by its absorbed hits (our own measurement, exact units).
-- With neither reading a hit is counted as UNKNOWN: it adds no debt, and the blow that pays
-- for it goes to the net feed whole, which is the behaviour before this file.
--
-- State is on ataxiaTemp (a session belief, never saved). Every function is safe when the
-- state is absent, because the vitals handler calls into this file on every prompt.

local DEFER = 0.6        -- AB: "minus 40%". OURS: deferred blow / (hits x typed mean), median 0.60
local MAX_UP = 12        -- s. OURS: up line to down line 9.07-10.03 s (n=24). Older = a missed down line
local SOURCE_AGE = 120   -- s a per-hit reading stays usable (the next room has other denizens)
local TYPED_KEEP = 12    -- typed hits in the mean
local LUMP_WINDOW = 1.0  -- s between the fall of health and the down line, in either order
local COOL_MAX = 14      -- s. OURS: the ready line comes 11.34-12.59 s after the up line (n=14)

local function now() return (getEpoch and getEpoch()) or os.time() end

local function temp()
  ataxiaTemp = ataxiaTemp or {}
  return ataxiaTemp
end

local function killFadeTimer(T)
  if T.numbFadeTimer then
    pcall(killTimer, T.numbFadeTimer)
    T.numbFadeTimer = nil
  end
end

-- The live cycle, or nil. A cycle ends on its down line; this is the bounded stop for a down
-- line that never came (blackout hides it; death and a disconnect skip it).
local function cycle()
  local T = temp()
  local st = T.numb
  if not st then return nil end
  local t = now()
  if st.fadedAt then
    if (t - st.fadedAt) > LUMP_WINDOW then T.numb = nil; return nil end
  elseif (t - st.upAt) > MAX_UP then
    T.numb = nil
    return nil
  end
  return st
end

-- Close a cycle: learn the size of one absorbed hit from the blow, and tell the player.
-- `drop` is the fall of health that paid the debt ({at, amount, from, to}), or nil.
local function settle(st, drop)
  local T = temp()
  killFadeTimer(T)
  T.numb = nil
  T.numbDrop = nil
  local hits = st.hits or 0
  if drop and drop.amount > 0 and hits > 0 then
    T.numbPerHit = { now(), drop.amount / hits }
  end
  if not ataxiaEcho then return end
  local hitWord = (hits == 1) and " absorbed hit" or " absorbed hits"
  if drop and drop.amount > 0 then
    local maxhp = tonumber(ataxia and ataxia.vitals and ataxia.vitals.maxhp) or 0
    local msg = "<orange_red>NUMB WORE OFF: -" .. math.floor(drop.amount) .. " HP<NavajoWhite>"
    if drop.from and drop.to then
      msg = msg .. " (" .. drop.from .. " -> " .. drop.to
      if maxhp > 0 then msg = msg .. ", " .. math.floor(drop.amount / maxhp * 100) .. "% of max" end
      msg = msg .. ")"
    end
    msg = msg .. " from " .. hits .. hitWord .. "."
    local est = math.floor(st.owed or 0)
    if est > 0 then msg = msg .. " Estimate was " .. est .. "." end
    if (st.unknown or 0) > 0 then msg = msg .. " " .. st.unknown .. " had no estimate." end
    ataxiaEcho(msg)
  elseif hits > 0 then
    ataxiaEcho("<orange_red>NUMB WORE OFF<NavajoWhite>: " .. hits .. hitWord
      .. ", but no fall of health seen within " .. LUMP_WINDOW .. "s.")
  else
    ataxiaEcho("<orange_red>NUMB WORE OFF<NavajoWhite>: nothing was absorbed, no health lost.")
  end
end

-- The estimated size of ONE absorbed hit after the 40% is taken off, or nil when we have no
-- reading. See the head of this file for the two readings.
function ataxia_numbHitEstimate()
  local T = temp()
  local t = now()
  local best
  local list = T.numbTyped
  if type(list) == "table" then
    local sum, n = 0, 0
    for _, s in ipairs(list) do
      if (t - s[1]) <= SOURCE_AGE then sum = sum + s[2]; n = n + 1 end
    end
    if n > 0 then best = (sum / n) * DEFER end
  end
  local cal = T.numbPerHit
  if cal and (t - cal[1]) <= SOURCE_AGE and (not best or cal[2] > best) then best = cal[2] end
  return best
end

-- "Health lost: N (type)." from bashStats_recordIncoming. A typed hit is the size of a hit that
-- numbness did NOT absorb, so it is the reading for the next absorbed one. "(raw)" is bleeding:
-- it passes through numbness (OURS: 17 to 290 a line, in 14 of 24 cycles) and says nothing about
-- a denizen's hit.
--
-- A typed line INSIDE a cycle is health that numbness did not defer. Its fall of health was
-- taken off the debt when Char.Vitals reported it (ataxia_numbNoteDrop cannot tell the two
-- apart), so the line gives that part back.
function ataxia_numbNoteTyped(amount, dtype)
  amount = tonumber(amount) or 0
  if amount <= 0 then return end
  local T = temp()
  local st = cycle()
  if st and not st.fadedAt and (st.paid or 0) > 0 then
    local back = math.min(amount, st.paid)
    st.paid = st.paid - back
    st.debt = st.debt + back
  end
  if dtype == "raw" then return end
  T.numbTyped = T.numbTyped or {}
  table.insert(T.numbTyped, { now(), amount })
  while #T.numbTyped > TYPED_KEEP do table.remove(T.numbTyped, 1) end
end

-- NUMB CANNOT BE SENT AGAIN AT ONCE. After the down line the game refuses it ("You may not numb
-- again so soon.") until "You have recovered enough to numb your body once again.", which came
-- 2.05 to 2.74 s after the down line and 11.34 to 12.59 s after the up line (OURS, n=14). The
-- keeper asks here before it spends a round's equilibrium rider on a refusal. COOL_MAX is the
-- bounded stop for a ready line that never came.
function ataxia_numbCooling()
  local T = temp()
  local at = T.numbCoolAt
  if not at then return false end
  if (now() - at) > COOL_MAX then
    T.numbCoolAt = nil
    return false
  end
  return true
end

-- "You have recovered enough to numb your body once again."
function ataxia_numbReady()
  temp().numbCoolAt = nil
end

-- "You may not numb again so soon." With no up line seen, the recovery is the 2-3 s after a
-- down line: wait 3 s, or less when the ready line comes.
function ataxia_numbRefused()
  local T = temp()
  if not ataxia_numbCooling() then T.numbCoolAt = now() - (COOL_MAX - 3) end
end

-- The up line. A second up line inside a cycle keeps the debt: the game has not collected it.
-- `kaido` is true from our own NUMB line (highlighting/060): only that one starts the recovery
-- above. Numbness from another source (the Legend Deck) is not known to share it.
function ataxia_numbRaised(kaido)
  local T = temp()
  if kaido == true then T.numbCoolAt = now() end
  local st = cycle()
  if st and st.fadedAt then settle(st, nil); st = nil end
  if st then st.upAt = now(); return end
  T.numb = { upAt = now(), hits = 0, debt = 0, owed = 0, paid = 0, unknown = 0 }
end

-- The absorbed-hit line. It proves numbness is up, so it starts a cycle when the up line was
-- not seen (the Legend Deck's numbness has another up line; blackout hides ours).
function ataxia_numbAbsorbed()
  local T = temp()
  local st = cycle()
  if not st or st.fadedAt then
    ataxia_numbRaised()
    st = T.numb
  end
  st.hits = st.hits + 1
  local est = ataxia_numbHitEstimate()
  if not est then
    st.unknown = st.unknown + 1
    return
  end
  st.debt = st.debt + est
  st.owed = st.owed + est -- the whole estimate of this cycle, for the echo; `debt` falls as it is paid
  if ataxiaBasher_recordIncoming then ataxiaBasher_recordIncoming(est) end
end

-- Health we owe and have not paid: the debt, and the count of absorbed hits with no estimate.
function ataxia_numbDebt()
  local st = cycle()
  if not st then return 0, 0 end
  return st.debt or 0, st.unknown or 0
end

-- " [numb debt ~8200 HP]" for an alarm echo, or "". An alarm at "100%" health needs its reason.
function ataxia_numbDebtNote()
  local debt, unknown = ataxia_numbDebt()
  if debt >= 1 then return " [numb debt ~" .. math.floor(debt) .. " HP]" end
  if unknown > 0 then return " [numb debt unknown: " .. unknown .. " absorbed]" end
  return ""
end

-- A fall of health from Char.Vitals. Returns the part of it that is NEW incoming damage for the
-- net-delta feed: the whole of it outside a cycle, and inside one only what the debt does not
-- explain. The debt is paid HERE, not on the down line, because Char.Vitals came before the
-- down line in the cycle of 11:15:04 (the alarm that reads it printed first) and the danger
-- level is read between the two: a debt still standing after the health fell would count the
-- same damage twice (.claude/AGENTS.md, "Do not
-- depend on the order of GMCP and text").
function ataxia_numbNoteDrop(amount, from, to)
  amount = tonumber(amount) or 0
  if amount <= 0 then return 0 end
  local T = temp()
  local t = now()
  -- The largest fall of the last LUMP_WINDOW seconds is the blow the down line reports. A
  -- bleeding tick in the same second must not replace it.
  local d = T.numbDrop
  if not d or (t - d.at) > LUMP_WINDOW or amount >= d.amount then
    T.numbDrop = { at = t, amount = amount, from = tonumber(from), to = tonumber(to) }
  end
  local st = cycle()
  if not st then return amount end
  -- The blow is the largest fall of the whole cycle: bleeding ticks are 17 to 290 health.
  if not st.maxDrop or amount >= st.maxDrop.amount then
    st.maxDrop = { at = t, amount = amount, from = tonumber(from), to = tonumber(to) }
  end
  local paid = math.min(amount, st.debt)
  st.debt = st.debt - paid
  st.paid = (st.paid or 0) + paid
  if st.fadedAt then settle(st, st.maxDrop) end -- the down line came first: this is the blow
  return amount - paid
end

-- The down line.
function ataxia_numbFaded()
  local T = temp()
  local st = cycle()
  if st and st.fadedAt then return end -- the same down line twice
  local recent = T.numbDrop
  if recent and (now() - recent.at) > LUMP_WINDOW then recent = nil end
  if not st then
    -- A fade with no cycle seen (blackout hid the lines): the fall of the last second, if any.
    st = { upAt = now(), hits = 0, debt = 0, owed = 0, paid = 0, unknown = 0 }
    if recent then settle(st, recent); return end
  elseif (st.owed or 0) > 0 then
    -- HAS THE BLOW LANDED? Yes when the falls of this cycle paid half of what we estimated. A
    -- bleeding tick in the second before the line pays almost nothing: taking it for the blow
    -- closed the cycle, and the real blow then went to the net feed whole (review, v4.7.512).
    if st.maxDrop and (st.paid or 0) >= 0.5 * st.owed then settle(st, st.maxDrop); return end
  elseif recent then
    settle(st, st.maxDrop or recent) -- no estimate, so no debt to protect: report what fell
    return
  end
  -- No blow yet: Char.Vitals is still to come (ataxia_numbNoteDrop settles), or nothing was
  -- owed. The debt stands until then, and the timer is the bounded stop.
  st.fadedAt = now()
  T.numb = st
  killFadeTimer(T)
  T.numbFadeTimer = tempTimer(LUMP_WINDOW, function()
    local T2 = temp()
    T2.numbFadeTimer = nil
    local cur = T2.numb
    if cur and cur.fadedAt then settle(cur, cur.maxDrop) end
  end)
end

-- Health minus the numbness debt: the health we have when the game collects. 0 and nil keep
-- their meaning for every reader ("unknown": blackout, no reading), so a debt as large as our
-- health gives 1, never 0.
function ataxia_effHp()
  local hp = tonumber(ataxia and ataxia.vitals and ataxia.vitals.hp)
  if not hp or hp <= 0 then return hp end
  local debt = ataxia_numbDebt()
  if debt <= 0 then return hp end
  local eff = hp - debt
  if eff < 1 then eff = 1 end
  return eff
end

-- The same as a percentage of maximum health. Never above the plain reading.
function ataxia_effHpp()
  local v = ataxia and ataxia.vitals
  local hpp = tonumber(v and v.hpp)
  if not hpp or hpp <= 0 then return hpp end
  local debt = ataxia_numbDebt()
  if debt <= 0 then return hpp end
  local hp, maxhp = tonumber(v.hp), tonumber(v.maxhp)
  if not hp or not maxhp or maxhp <= 0 then return hpp end
  local eff = math.floor((hp - debt) / maxhp * 100)
  if eff < 1 then eff = 1 end
  if eff > hpp then eff = hpp end
  return eff
end
