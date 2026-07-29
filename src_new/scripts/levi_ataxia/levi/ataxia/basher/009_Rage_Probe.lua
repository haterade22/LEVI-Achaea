--[[mudlet
type: script
name: Rage Probe
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

-- RAGE PROBE (v4.7.141) -- measure a rage-threshold damage bonus from live play.
--
-- Some gear pays a flat damage bonus while battlerage sits at or above a threshold
-- (live example: "+23% damage so long as you have 40 battlerage or more"). Before
-- spending hours on an A/B trial of hold-the-floor vs spend-freely, this answers the
-- prior question cheaply: does the bonus exist, does it apply to our bash attacks,
-- and how big is it really?
--
-- Method: every NON-CRIT damage line is recorded with the rage we had at the time
-- (`bash probe on`, then just bash normally -- rage naturally oscillates across the
-- threshold, so ordinary play produces both arms). Crits are counted but EXCLUDED:
-- their heavy tail (16x/32x/64x) swamps a 23% signal.
--
-- Two views over the same samples:
--   report -- mean non-crit hit at >= threshold vs < threshold, per mob, + the ratio
--             (a real +23% shows as ~1.23). Hits inside the AMBIGUITY BAND around the
--             threshold are skipped: ataxia.vitals.rage is last-prompt (pre-attack)
--             data, so boundary hits misclassify.
--   bands  -- mean per 10-rage band, which shows where the step ACTUALLY is (and
--             catches a second breakpoint from other gear) instead of assuming 40.
--
-- Samples are keyed by mob AND class: different denizens have different armour, and
-- switching class mid-probe would otherwise blend two damage profiles.

ataxiaBasher = ataxiaBasher or {}

local SAMPLE_CAP = 1500  -- FIFO; keeps the saved ataxiaBasher table bounded
local BAND = 10          -- rage bucket width for the band view
local AMBIGUITY = 4      -- +/- around the threshold, discarded (stale vitals)
local MIN_N = 30         -- per-bucket sample count before a ratio means much

-- Load-time init: ataxiaTemp/ataxiaBasher survive a SYSUPDATE reload, so use `or`
-- (a live probe keeps running across an update instead of losing its samples).
ataxiaBasher.rageProbe = ataxiaBasher.rageProbe or { on = false, at = 40, crits = 0, samples = {} }

local function P() return ataxiaBasher.rageProbe end
local function echo(msg)
  if cecho then pcall(cecho, "\n<a_darkcyan>(<a_darkmagenta>PROBE<a_darkcyan>): <lavender>" .. tostring(msg))
  else print(msg) end
end

--------------------------------------------------------------------------------
-- Pure functions (no Mudlet API -- unit tested in test_rage_probe.lua)
--------------------------------------------------------------------------------

-- "hi" at/above the threshold, "lo" below it, nil inside the ambiguity band.
function ataxiaBasher_rageProbeBucket(rage, at)
  rage, at = tonumber(rage), tonumber(at) or 40
  if not rage then return nil end
  if rage >= at + AMBIGUITY then return "hi" end
  if rage < at - AMBIGUITY then return "lo" end
  return nil
end

-- Append a sample {r=rage, d=damage, m=mob, c=class}, FIFO-capped.
function ataxiaBasher_rageProbeRecord(state, sample)
  if not (state and type(sample) == "table") then return end
  state.samples = state.samples or {}
  state.samples[#state.samples + 1] = sample
  local over = #state.samples - SAMPLE_CAP
  if over > 0 then
    local kept = {}
    for i = over + 1, #state.samples do kept[#kept + 1] = state.samples[i] end
    state.samples = kept
  end
end

-- Per-mob hi/lo means + ratio, plus a TOTALS row. `filter` (optional) matches mob or
-- class substrings (case-insensitive). Rows are sorted by sample count, descending.
function ataxiaBasher_rageProbeRows(state, filter)
  local by, rows = {}, {}
  local tHiSum, tHiN, tLoSum, tLoN = 0, 0, 0, 0
  for _, s in ipairs((state and state.samples) or {}) do
    local mob = s.m or "?"
    local hay = (mob .. " " .. tostring(s.c or "")):lower()
    if not filter or filter == "" or hay:find(tostring(filter):lower(), 1, true) then
      local b = ataxiaBasher_rageProbeBucket(s.r, state.at)
      if b then
        by[mob] = by[mob] or { mob = mob, hiSum = 0, hiN = 0, loSum = 0, loN = 0 }
        local e = by[mob]
        if b == "hi" then
          e.hiSum, e.hiN = e.hiSum + (s.d or 0), e.hiN + 1
          tHiSum, tHiN = tHiSum + (s.d or 0), tHiN + 1
        else
          e.loSum, e.loN = e.loSum + (s.d or 0), e.loN + 1
          tLoSum, tLoN = tLoSum + (s.d or 0), tLoN + 1
        end
      end
    end
  end
  for _, e in pairs(by) do
    local hiMean = e.hiN > 0 and (e.hiSum / e.hiN) or 0
    local loMean = e.loN > 0 and (e.loSum / e.loN) or 0
    rows[#rows + 1] = {
      mob = e.mob, hiN = e.hiN, hiMean = hiMean, loN = e.loN, loMean = loMean,
      ratio = (loMean > 0 and hiMean > 0) and (hiMean / loMean) or nil,
    }
  end
  table.sort(rows, function(a, b) return (a.hiN + a.loN) > (b.hiN + b.loN) end)
  local hiMean = tHiN > 0 and (tHiSum / tHiN) or 0
  local loMean = tLoN > 0 and (tLoSum / tLoN) or 0
  return rows, {
    mob = "ALL", hiN = tHiN, hiMean = hiMean, loN = tLoN, loMean = loMean,
    ratio = (loMean > 0 and hiMean > 0) and (hiMean / loMean) or nil,
  }
end

-- Mean damage per 10-rage band -- reveals the real breakpoint. Returns an ascending
-- array of {lo, hi, n, mean}. Bands with no samples are omitted.
function ataxiaBasher_rageProbeBands(state, filter)
  local acc, out = {}, {}
  for _, s in ipairs((state and state.samples) or {}) do
    local r = tonumber(s.r)
    local hay = ((s.m or "") .. " " .. tostring(s.c or "")):lower()
    if r and (not filter or filter == "" or hay:find(tostring(filter):lower(), 1, true)) then
      local b = math.floor(r / BAND)
      acc[b] = acc[b] or { sum = 0, n = 0 }
      acc[b].sum, acc[b].n = acc[b].sum + (s.d or 0), acc[b].n + 1
    end
  end
  local keys = {}
  for b in pairs(acc) do keys[#keys + 1] = b end
  table.sort(keys)
  for _, b in ipairs(keys) do
    out[#out + 1] = { lo = b * BAND, hi = b * BAND + BAND - 1, n = acc[b].n, mean = acc[b].sum / acc[b].n }
  end
  return out
end

--------------------------------------------------------------------------------
-- Live hook + commands
--------------------------------------------------------------------------------

-- Called from trigger 350_Damage_Dealt for every damage line we deal (BEFORE the
-- crit flag is reset, so `wasCrit` is still meaningful).
function ataxiaBasher_rageProbeHit(amount, dtype, wasCrit)
  local st = P()
  if not st.on then return end
  if wasCrit then st.crits = (st.crits or 0) + 1; return end
  local amt = tonumber(amount)
  if not amt or amt <= 0 then return end
  local rage = tonumber(ataxia and ataxia.vitals and ataxia.vitals.rage)
  if not rage then return end
  local mob = "?"
  if type(target) == "number" and ataxia and ataxia.denizensHere and ataxia.denizensHere[target] then
    mob = ataxia.denizensHere[target]
  elseif type(target) == "string" then
    mob = target
  end
  local class = (gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class) or "?"
  ataxiaBasher_rageProbeRecord(st, { r = rage, d = amt, m = mob, c = class })
end

local function fmt(n) return string.format("%.0f", n or 0) end

local function reportCmd(filter)
  local st = P()
  local rows, tot = ataxiaBasher_rageProbeRows(st, filter)
  echo("rage probe -- mean NON-CRIT hit, rage >=" .. st.at .. " vs <" .. st.at
    .. " (band +/-" .. AMBIGUITY .. " skipped)")
  if #rows == 0 then
    echo("  no samples yet -- 'bash probe on' then bash for 15-30 minutes.")
    return
  end
  for _, r in ipairs(rows) do
    local ratio = r.ratio and string.format("%.2fx", r.ratio) or "--"
    local thin = (r.hiN < MIN_N or r.loN < MIN_N) and " <dark_orange>(thin)<lavender>" or ""
    echo(string.format("  %-34s hi %s (n=%d)  lo %s (n=%d)  ratio %s%s",
      tostring(r.mob):sub(1, 34), fmt(r.hiMean), r.hiN, fmt(r.loMean), r.loN, ratio, thin))
  end
  local ratio = tot.ratio and string.format("%.2fx", tot.ratio) or "--"
  echo(string.format("  %-34s hi %s (n=%d)  lo %s (n=%d)  ratio %s",
    "TOTAL (mixed mobs -- per-mob rows are the real answer)",
    fmt(tot.hiMean), tot.hiN, fmt(tot.loMean), tot.loN, ratio))
  echo("  crits excluded: " .. (st.crits or 0) .. ". Need >=" .. MIN_N
    .. " hits per bucket ON THE SAME MOB before trusting a ratio.")
end

local function bandsCmd(filter)
  local st = P()
  local bands = ataxiaBasher_rageProbeBands(st, filter)
  echo("rage probe -- mean NON-CRIT hit per rage band (where is the real step?)")
  if #bands == 0 then echo("  no samples yet.") return end
  for _, b in ipairs(bands) do
    echo(string.format("  %2d-%2d  mean %-7s n=%d", b.lo, b.hi, fmt(b.mean), b.n))
  end
end

local function dumpCmd(n)
  local st = P()
  local want = tonumber(n) or 20
  local s = st.samples or {}
  echo("rage probe -- last " .. math.min(want, #s) .. " of " .. #s .. " samples (rage, damage, mob)")
  for i = math.max(1, #s - want + 1), #s do
    echo(string.format("  %3d  %-7s %s", s[i].r or -1, fmt(s[i].d), tostring(s[i].m)))
  end
end

function ataxiaBasher_rageProbeCommand(verb, rest)
  local st = P()
  verb = (verb or ""):lower()
  if verb == "on" then
    st.on = true
    echo("ON at threshold " .. st.at .. " -- bash normally; 'bash probe report' when you have samples.")
  elseif verb == "off" then
    st.on = false
    echo("OFF (" .. #(st.samples or {}) .. " samples kept).")
  elseif verb == "at" then
    local v = tonumber(rest)
    if not v then echo("usage: bash probe at <rage>") return end
    st.at = v
    echo("threshold set to " .. v .. " (re-run 'bash probe report' -- samples are reused).")
  elseif verb == "report" or verb == "" then
    reportCmd(rest)
  elseif verb == "bands" then
    bandsCmd(rest)
  elseif verb == "dump" then
    dumpCmd(rest)
  elseif verb == "clear" then
    st.samples, st.crits = {}, 0
    echo("samples cleared.")
  elseif verb == "status" then
    local rows, tot = ataxiaBasher_rageProbeRows(st, nil)
    echo((st.on and "ON" or "OFF") .. " | threshold " .. st.at .. " | samples " .. #(st.samples or {})
      .. " (hi " .. tot.hiN .. " / lo " .. tot.loN .. ", crits skipped " .. (st.crits or 0) .. ")"
      .. " | rage now " .. tostring(ataxia and ataxia.vitals and ataxia.vitals.rage))
  else
    echo("bash probe on|off|at <n>|report [filter]|bands [filter]|dump [n]|clear|status")
  end
end
