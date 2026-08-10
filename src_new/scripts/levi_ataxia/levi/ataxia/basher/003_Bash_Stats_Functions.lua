--[[mudlet
type: script
name: Bash Stats Functions
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

--[[mudlet
type: script
name: Bash Stats Functions
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

function resetBashingStats(silent)
	bashStats = {
		criticals = { ["2x"] = 0, ["4x"] = 0, ["8x"] = 0, ["16x"] = 0, ["32x"] = 0, ["64x"] = 0 },
		attacks = 0,
		loginGold = tonumber(gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.gold) or 0,
		gainedGold = 0,
		crits = 0,
		slain = 0,
		mobhits = 0,
		blockedhits = 0,
		-- Damage/DPS fields were added lazily elsewhere (nil until first hit), so combat triggers
		-- that increment them (337_Our_Attacks, denizen_attacks/007+008) crashed on a fresh session.
		-- Initialise them here so bashStats is always complete.
		totalDamage = 0,
		damageByType = {},
		currentBalanceDamage = 0,
		lastBalanceDamage = 0,
		lastBalanceTime = 0,
		lastHitWasCrit = false,
		dpsSessionStart = getEpoch(),
		-- v4.7.207, DPS rework. See bashStats_getDPS for why wall-clock was the wrong
		-- denominator and a single balance the wrong sample.
		dmgSamples = {},   -- {epoch, amount} pairs inside the rolling window
		combatTime = 0,    -- seconds spent ACTUALLY fighting, not wall clock
		lastDamageAt = nil,
		-- Incoming damage, by type ("Health lost: 1488 (physical cutting).")
		incomingByType = {},
		incomingTotal = 0,
		incomingHits = 0,
	}
	if not silent then ataxiaEcho("Bashing statistics have been reset.") end
end

-- Initialise at LOAD so `bashStats` is NEVER nil. It used to be created only by an explicit
-- resetBashingStats() call, so on a fresh login or a SYSUPDATE reload the combat triggers hit
-- `attempt to index global 'bashStats' (a nil value)` on the first attack. Silent (no "reset"
-- echo), and only when absent so a live reload keeps the running counts.
if not bashStats then resetBashingStats(true) end

-- Rolling window for the "Now" figure, and the gap that ends a fight for the "Avg" one.
bashStats_DPS_WINDOW = bashStats_DPS_WINDOW or 10 -- seconds
bashStats_COMBAT_GAP = bashStats_COMBAT_GAP or 10 -- a longer pause is not combat

-- Record a hit WE dealt. Feeds both figures below; called from trigger 350_Damage_Dealt.
--
-- `combatTime` accumulates only the gaps SHORT enough to still be a fight. That is what makes
-- the session average mean something: walking to the next area, resting, hovering to heal, and
-- sitting on the boon screen all stop adding to the denominator, so the number stays a measure
-- of how hard we hit rather than of how long the client has been open.
function bashStats_recordDamage(amount)
  amount = tonumber(amount) or 0
  if not bashStats or amount <= 0 then return end
  local now = getEpoch()
  bashStats.dmgSamples = bashStats.dmgSamples or {}
  bashStats.combatTime = bashStats.combatTime or 0

  local prev = bashStats.lastDamageAt
  if prev then
    local gap = now - prev
    -- Only gaps inside the window count. The first hit of a fight contributes nothing, which
    -- is right: we have no idea when we started swinging, only when we connected.
    if gap > 0 and gap <= bashStats_COMBAT_GAP then
      bashStats.combatTime = bashStats.combatTime + gap
    end
  end
  bashStats.lastDamageAt = now

  table.insert(bashStats.dmgSamples, { now, amount })
  local cutoff = now - bashStats_DPS_WINDOW
  while #bashStats.dmgSamples > 0 and bashStats.dmgSamples[1][1] < cutoff do
    table.remove(bashStats.dmgSamples, 1)
  end
end

-- Record damage we TOOK, by type: "Health lost: 1488 (physical cutting)."
-- Kept separate from bashStats.damageByType, which is our OUTGOING damage.
function bashStats_recordIncoming(amount, dtype)
  amount = tonumber(amount) or 0
  if not bashStats or amount <= 0 then return end
  dtype = tostring(dtype or "unknown"):lower():gsub("^%s+", ""):gsub("%s+$", "")
  bashStats.incomingByType = bashStats.incomingByType or {}
  bashStats.incomingByType[dtype] = (bashStats.incomingByType[dtype] or 0) + amount
  bashStats.incomingTotal = (bashStats.incomingTotal or 0) + amount
  bashStats.incomingHits = (bashStats.incomingHits or 0) + 1
  -- Feed the danger watchdog with the REAL number (v4.7.243). Its own feed is the net HP delta
  -- per prompt, which healing masks: a prompt that takes 2000 and sips 1500 records 500, and a
  -- net-positive prompt records nothing at all. This line is the damage BEFORE any of that.
  if ataxiaBasher_recordIncoming then ataxiaBasher_recordIncoming(amount) end
end

-- The damage type that has cost us the most this session: type, amount, share (0-100).
-- Sorted rather than max-tracked so ties resolve stably and the caller can show a table.
function bashStats_topIncoming()
  if not (bashStats and bashStats.incomingByType) then return nil end
  local best, bestAmt = nil, 0
  for dtype, amt in pairs(bashStats.incomingByType) do
    if amt > bestAmt then best, bestAmt = dtype, amt end
  end
  if not best then return nil end
  local total = bashStats.incomingTotal or 0
  return best, bestAmt, (total > 0 and (bestAmt / total) * 100) or 0
end

-- Every incoming type, biggest first -- for `bashstats` and any future panel.
function bashStats_incomingRanked()
  local out = {}
  if not (bashStats and bashStats.incomingByType) then return out end
  for dtype, amt in pairs(bashStats.incomingByType) do out[#out + 1] = { dtype, amt } end
  table.sort(out, function(a, b)
    if a[2] ~= b[2] then return a[2] > b[2] end
    return a[1] < b[1] -- stable, alphabetical on ties
  end)
  return out
end

-- "Now" and "Avg", as strings.
--
-- REWORKED v4.7.207. Both figures were misleading in different ways:
--
--   Avg was `totalDamage / (now - dpsSessionStart)` -- WALL CLOCK since the stats were reset.
--   Every second not fighting divided the number down, so an hour idle made a perfectly good
--   session read near zero. It measured how long the client had been open, not how hard we
--   hit. Now it divides by `combatTime`, which only accumulates gaps short enough to still be
--   a fight (bashStats_COMBAT_GAP).
--
--   Now was `lastBalanceDamage / lastBalanceTime` -- a SINGLE balance. One crit spiked it,
--   one miss zeroed it, so it flickered too hard to read mid-fight. It is now the rolling
--   `bashStats_DPS_WINDOW` (10s), the same shape the incoming-damage watchdog already uses.
--   Dividing by the whole window rather than by the span of the samples is deliberate: it
--   decays to 0 when we stop hitting, instead of showing the last burst forever.
function bashStats_getDPS()
  if not bashStats then return "0", "0" end

  local combat = tonumber(bashStats.combatTime) or 0
  local sDPS = "0"
  if combat > 0 and (bashStats.totalDamage or 0) > 0 then
    sDPS = string.format("%.1f", bashStats.totalDamage / combat)
  elseif (bashStats.totalDamage or 0) > 0 then
    -- One hit and nothing to measure against yet: fall back to the old wall-clock figure
    -- rather than showing a confident 0.
    local elapsed = getEpoch() - (bashStats.dpsSessionStart or getEpoch())
    if elapsed > 0 then sDPS = string.format("%.1f", bashStats.totalDamage / elapsed) end
  end

  local win, now = 0, getEpoch()
  local cutoff = now - bashStats_DPS_WINDOW
  for _, sample in ipairs(bashStats.dmgSamples or {}) do
    if sample[1] >= cutoff then win = win + (sample[2] or 0) end
  end
  local bDPS = string.format("%.1f", win / bashStats_DPS_WINDOW)

  return sDPS, bDPS
end
