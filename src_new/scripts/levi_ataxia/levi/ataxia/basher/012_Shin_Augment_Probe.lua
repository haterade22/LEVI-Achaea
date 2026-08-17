--[[mudlet
type: script
name: Shin Augment Probe
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    SHIN AUGMENT: MEASURE THE DURATION CURVE  (v4.7.270, `bash shinprobe`)
    ============================================================================

    SHIN AUGMENT <amount> (AB 316) buys a 20% damage reduction whose duration SCALES with the shin
    spent -- user-confirmed as roughly 10 seconds at the bottom to about 1.5 minutes at the top,
    and explicitly NOT one shin per second. The AB states no numbers at all, so the curve between
    those two points is unknown, and `ataxiaBasher.bmAugmentAmount` is therefore a guess.

    This measures it from live play, exactly as `basher/009_Rage_Probe.lua` measures a damage
    threshold that no ability text will tell us either: watch the `bodyaugment` defence, time the
    up -> down interval, and pair it with what the round spent.

    TWO OUTPUTS, and the second is the one the code already depends on:

      1. The CURVE -- (spend -> duration) samples, so `bmAugmentAmount` can be chosen rather than
         guessed. `bash shinprobe report`.
      2. The COOLDOWN -- "when it ends it goes on cooldown equal to the duration it was up for".
         That needs no curve: the duration we just measured IS the cooldown, so the watcher returns
         the epoch at which the next augment may be attempted. This is what keeps the basher from
         re-sending a refused `shin augment` every 7s for up to a minute and a half.

    Polled, not triggered, and deliberately: the defence is read from GMCP
    (`ataxia.defences.bodyaugment`), which is already refreshed by Char.Defences Add/Remove, and
    the basher's round runs every prompt -- so a poll costs one table lookup and needs no new line
    capture. The activation line and the wear-off line are both uncaptured; had this been built on
    them it would have needed two triggers that do not exist yet.

    Timing is therefore prompt-granular, not exact. A sample is the interval between the first
    prompt that SAW the defence and the first that saw it gone, so it errs slightly LOW on both
    edges. Good enough to pick a spend from; recorded as approximate rather than presented as
    precise.
]]--

ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}

-- Samples live on the SAVED namespace on purpose (like rageProbe): the whole point is to
-- accumulate them across sessions until the curve is clear. Only the in-flight edge detection is
-- transient, and that lives on ataxiaTemp.
ataxiaBasher.shinProbe = ataxiaBasher.shinProbe or { on = true, samples = {} }

local MAX_SAMPLES = 200 -- a curve needs tens, not thousands; keeps the save file small

local function P() return ataxiaBasher.shinProbe end

local function now()
  return (getEpoch and getEpoch()) or os.time()
end

-- Record one completed cycle. `spend` may be nil when the augment was raised by hand rather than
-- by the basher -- the duration is still worth having, so it is kept with spend = nil rather than
-- discarded. A sample we cannot attribute is still evidence about the range.
function ataxiaBasher_shinProbeRecord(spend, duration)
  local p = P()
  if not p.on then return end
  duration = tonumber(duration)
  if not duration or duration <= 0 then return end
  table.insert(p.samples, { spend = tonumber(spend), dur = duration, at = now() })
  while #p.samples > MAX_SAMPLES do table.remove(p.samples, 1) end
end

-- ---------------------------------------------------------------------------
-- The three captured lines (v4.7.270, triggers highlighting/050-052)
-- ---------------------------------------------------------------------------
--
-- `You focus inward, drawing upon your reserves of shin energy.`                -> channel begins
-- `You are already beginning the process of augmenting your body with shin...`   -> REFUSED
-- `You channel your accumulated shin energy into enhancing your defensive...`    -> cover STARTS
--
-- Together they replace guesswork with observation at every edge: the send is a request, the
-- channel line is acceptance, and the third line is the moment the duration clock starts.

-- Channel accepted. Re-arm the attempt hold from the CONFIRMED start rather than from when we
-- asked, so the 4s activation is timed from second zero of the real window.
function ataxiaBasher_bmAugmentChannel()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.bmAugmentAttempted = true
  if killTimer and ataxiaTemp.bmAugmentHoldT then pcall(killTimer, ataxiaTemp.bmAugmentHoldT) end
  ataxiaTemp.bmAugmentHoldT = tempTimer(7, [[ataxiaTemp.bmAugmentAttempted = nil]])
end

-- THE GAME SAYING NO OUTRANGES OUR BOOKKEEPING. Observed five times in 0.45s during one activation:
-- `shin augment` costs no balance, so it EXECUTES on every re-queue of the round instead of waiting
-- like the swing, and the basher re-queues every prompt. A send-time flag cannot be trusted to have
-- survived; this line cannot be out of date.
function ataxiaBasher_bmAugmentRefused()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.bmAugmentAttempted = true
  ataxiaTemp.bmAugmentRefusals = (tonumber(ataxiaTemp.bmAugmentRefusals) or 0) + 1
  if killTimer and ataxiaTemp.bmAugmentHoldT then pcall(killTimer, ataxiaTemp.bmAugmentHoldT) end
  -- 5s from the refusal: long enough to cover the rest of a 4s activation from any point inside it.
  ataxiaTemp.bmAugmentHoldT = tempTimer(5, [[ataxiaTemp.bmAugmentAttempted = nil]])
end

-- Cover has begun -- start the duration clock here, not at the send (4s early) and not at the first
-- prompt that noticed the defence (up to a prompt late).
function ataxiaBasher_bmAugmentActive()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.bmAugmentAttempted = nil
  if killTimer and ataxiaTemp.bmAugmentHoldT then pcall(killTimer, ataxiaTemp.bmAugmentHoldT) end
  ataxiaTemp.bmAugmentHoldT = nil
  ataxiaTemp.bmAugmentUpAt = now()
  ataxiaTemp.bmAugmentUpSpend = tonumber(ataxiaTemp.bmAugmentSpent)
end

-- THE WATCHER. Called once per assembled round. Returns the epoch before which no augment should
-- be attempted -- 0 when nothing is known -- and records a sample on each completed cycle.
--
-- Three states, and the transitions are the whole function:
--   defence UP   and we had not seen it  -> cycle started; stamp the time and the spend
--   defence UP   and we had              -> nothing to do
--   defence DOWN and we had seen it up   -> cycle ended; duration = now - upAt, and the cooldown
--                                           is EQUAL TO IT, so the next attempt is now + duration
function ataxiaBasher_bmAugmentWatch()
  ataxiaTemp = ataxiaTemp or {}
  local up = (ataxia and ataxia.defences and ataxia.defences.bodyaugment) and true or false
  local t = now()

  if up then
    if not ataxiaTemp.bmAugmentUpAt then
      ataxiaTemp.bmAugmentUpAt = t
      -- Snapshot the spend at the moment cover begins: bmAugmentSpent is overwritten by the next
      -- send, and a long augment can outlive several rounds.
      ataxiaTemp.bmAugmentUpSpend = tonumber(ataxiaTemp.bmAugmentSpent)
    end
    return 0 -- it is up; the gate above already refuses on the defence itself
  end

  if ataxiaTemp.bmAugmentUpAt then
    local dur = t - ataxiaTemp.bmAugmentUpAt
    local spend = ataxiaTemp.bmAugmentUpSpend
    ataxiaTemp.bmAugmentUpAt, ataxiaTemp.bmAugmentUpSpend = nil, nil
    if dur > 0 then
      ataxiaBasher_shinProbeRecord(spend, dur)
      -- The cooldown IS the duration. Stored rather than returned alone so it survives the rounds
      -- between now and its expiry.
      ataxiaTemp.bmAugmentCdUntil = t + dur
      if ataxiaBasher_dsAlert then
        ataxiaBasher_dsAlert(string.format(
          "<cyan>augment<reset> ended after <white>%.1fs<reset>%s -- cooldown until +%.0fs.",
          dur, spend and (" on <white>" .. spend .. "<reset> shin") or "", dur))
      end
    end
  end

  return tonumber(ataxiaTemp.bmAugmentCdUntil) or 0
end

-- Group samples by spend so the curve is readable at a glance. Sorted, because an unordered dump
-- of a curve is not a curve.
function ataxiaBasher_shinProbeRows()
  local by, keys = {}, {}
  for _, s in ipairs(P().samples) do
    local k = s.spend or 0 -- 0 = "raised by hand, spend unknown"
    if not by[k] then by[k] = { n = 0, total = 0, min = nil, max = nil }; keys[#keys + 1] = k end
    local b = by[k]
    b.n, b.total = b.n + 1, b.total + s.dur
    if not b.min or s.dur < b.min then b.min = s.dur end
    if not b.max or s.dur > b.max then b.max = s.dur end
  end
  table.sort(keys)
  local rows = {}
  for _, k in ipairs(keys) do
    local b = by[k]
    rows[#rows + 1] = { spend = k, n = b.n, mean = b.total / b.n, min = b.min, max = b.max }
  end
  return rows
end

function ataxiaBasher_shinProbeReport()
  local rows = ataxiaBasher_shinProbeRows()
  ataxia.echo("<gold>SHIN AUGMENT<reset> -- measured duration by spend"
    .. (P().on and "" or " <indian_red>(probe OFF)<reset>"))
  if #rows == 0 then
    cecho("\n  <DimGrey>no samples yet. Bash as a Blademaster with Bladed Reflexes up; each"
      .. " completed augment records one.\n")
    return
  end
  cecho("\n  <NavajoWhite>spend   n     mean      min      max     sec/shin")
  for _, r in ipairs(rows) do
    local label = (r.spend == 0) and "manual" or tostring(r.spend)
    local per = (r.spend > 0) and string.format("%6.2f", r.mean / r.spend) or "     -"
    cecho(string.format("\n  <white>%-7s<reset>%-5d %6.1fs  %6.1fs  %6.1fs   %s",
      label, r.n, r.mean, r.min, r.max, per))
  end
  -- The two facts worth restating beside the numbers, because they bound what the curve can buy.
  cecho("\n  <DimGrey>cooldown equals the duration, so uptime cannot exceed 50%; the 4s activation"
    .. "\n  is a fixed tax a SHORT augment pays proportionally more of. Timing is prompt-granular"
    .. "\n  and errs low. Set the chosen spend with <white>bash augment <n><reset>.\n")
end

function ataxiaBasher_shinProbeCommand(arg, rest)
  local p = P()
  arg = arg and arg:lower() or "report"
  if arg == "on" or arg == "off" then
    p.on = (arg == "on")
    ataxia.echo("<gold>shin augment probe<reset> " .. (p.on and "<green>ON" or "<indian_red>OFF"))
  elseif arg == "clear" then
    p.samples = {}
    ataxia.echo("<gold>shin augment probe<reset> -- samples cleared.")
  elseif arg == "dump" then
    local n = tonumber(rest) or 10
    ataxia.echo("<gold>shin augment probe<reset> -- last " .. n .. " samples")
    local s = p.samples
    for i = math.max(1, #s - n + 1), #s do
      cecho(string.format("\n  <white>%s<reset> shin -> <white>%.1fs",
        tostring(s[i].spend or "manual"), s[i].dur))
    end
    cecho("\n")
  elseif arg == "status" then
    ataxia.echo("<gold>shin augment probe<reset> " .. (p.on and "<green>ON" or "<indian_red>OFF")
      .. " <reset>-- " .. #p.samples .. " sample(s), spend "
      .. tostring(tonumber(ataxiaBasher.bmAugmentAmount) or 20))
  else
    ataxiaBasher_shinProbeReport()
  end
end
