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
      2. The COOLDOWN -- keeping the basher from re-sending a refused `shin augment` every 7s for
         up to a minute and a half.

    v4.7.271: ALL FIVE LINES OF THE CYCLE ARE NOW CAPTURED, so both outputs come from the game's
    own wording rather than from a poll and a derivation:

      focus inward (channel) -> channel accepted, 4s to go       (050)
      already beginning      -> REFUSED, still channelling       (051)
      you channel ... into   -> cover STARTS, duration clock on   (052)
      shin energy dissipates -> cover ENDS, cooldown starts       (053)
      may augment once again -> cooldown OVER                     (054)

    That is what makes the second output exact. v4.7.270 had to DERIVE the cooldown from the
    mechanic the user stated ("equal to the duration it was up for") because the end of it was
    invisible; 054 announces it, so the arithmetic is demoted to a backstop for a missed line.
    Where the game speaks about its own state, we listen -- the same rule that made the augment
    refusal outrank our send-time flag, and the distortion refusal outrank ours (v4.7.266).

    The GMCP poll (`ataxia.defences.bodyaugment`, refreshed by Char.Defences Add/Remove, read once
    per assembled round) survives underneath as the backstop for a missed 053. It is a prompt late
    on the down edge, which is why it is no longer the primary: every duration it measured read
    slightly short, and a short duration derived a short cooldown.

    First real measurement, from the capture that supplied 053/054: dissipated at 10:25:09.886,
    ready at 10:25:12.886 -- a 3.0s cooldown. Consistent with "cooldown equals duration" IF the
    augment before it lasted 3s, which is what 3 shin buys and was the default before v4.7.269.
    The same capture times the activation at 10:25:15.257 -> 10:25:18.916 = 3.66s, corroborating
    the stated 4s. One sample is not the curve; that is what the probe accumulates.
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
  ataxiaTemp.bmAugmentEndedAt = nil
end

-- ---------------------------------------------------------------------------
-- The other two lines (v4.7.271, triggers highlighting/053-054)
-- ---------------------------------------------------------------------------
--
-- `The shin energy enhancing your body dissipates.`          -> cover ENDS, cooldown starts
-- `You may augment yourself with shin energy once again.`     -> cooldown OVER
--
-- v4.7.270 asked for exactly these two and recorded them as uncaptured. The second is the more
-- valuable by far: it removes the last arithmetic from the cycle. We were MEASURING the duration
-- and then waiting that long, because "cooldown equal to the duration it was up for" was all we
-- had to go on. The game announces the end, so we wait for the announcement.

-- Shared by the line (exact) and the GMCP poll (a prompt late, kept only as a backstop).
local function augmentCycleEnded(t)
  local dur = t - ataxiaTemp.bmAugmentUpAt
  local spend = ataxiaTemp.bmAugmentUpSpend
  ataxiaTemp.bmAugmentUpAt, ataxiaTemp.bmAugmentUpSpend = nil, nil
  if dur <= 0 then return end
  ataxiaBasher_shinProbeRecord(spend, dur)
  -- The DERIVED cooldown, now a BACKSTOP rather than the authority: if the ready line is missed
  -- we must still be released eventually, or the augment is off for the rest of the run -- the
  -- failure mode this codebase keeps writing down (an optimistic flag cleared only by a
  -- confirmation is a livelock the moment the confirmation cannot arrive). Whichever comes first.
  ataxiaTemp.bmAugmentCdUntil = t + dur
  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert(string.format(
      "<cyan>augment<reset> ended after <white>%.1fs<reset>%s -- waiting for the ready line.",
      dur, spend and (" on <white>" .. spend .. "<reset> shin") or ""))
  end
end

function ataxiaBasher_bmAugmentEnded()
  ataxiaTemp = ataxiaTemp or {}
  -- Stamped even when no cycle was open, because the POLL must not then invent one: GMCP can still
  -- report `bodyaugment` for a prompt or two after this line, and the poll would read that as a
  -- fresh cover starting -- recording a phantom sample and a phantom cooldown from it. A 2s grace
  -- cannot suppress a real cycle: cover cannot restart inside cooldown + the 4s activation.
  ataxiaTemp.bmAugmentEndedAt = now()
  if ataxiaTemp.bmAugmentUpAt then augmentCycleEnded(ataxiaTemp.bmAugmentEndedAt) end
end

-- The cooldown is over because the game said so. Same principle as the augment REFUSAL (v4.7.270)
-- and the Depthswalker distortion refusal (v4.7.266): where the game speaks about its own state,
-- our derived bookkeeping is the fallback, not the authority.
function ataxiaBasher_bmAugmentReady()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.bmAugmentCdUntil = nil
  ataxiaTemp.bmAugmentAttempted = nil
  if killTimer and ataxiaTemp.bmAugmentHoldT then pcall(killTimer, ataxiaTemp.bmAugmentHoldT) end
  ataxiaTemp.bmAugmentHoldT = nil
end

-- THE WATCHER. Called once per assembled round. Returns the epoch before which no augment should
-- be attempted -- 0 when nothing is known, which is now the NORMAL answer, because 054 nils the
-- stamp the moment the game says the cooldown is over.
--
-- Everything below it is the backstop for a missed line, in both directions:
--   defence UP   and no cycle open   -> a missed 052; open one (outside the post-053 grace)
--   defence UP   and one is open     -> nothing to do
--   defence DOWN and one is open     -> a missed 053; close it and derive the cooldown
function ataxiaBasher_bmAugmentWatch()
  ataxiaTemp = ataxiaTemp or {}
  local up = (ataxia and ataxia.defences and ataxia.defences.bodyaugment) and true or false
  local t = now()

  if up then
    -- The GRACE, and it is load-bearing: GMCP can still report the defence for a prompt or two
    -- after the dissipate line, and starting a cycle from that trailing read would record a
    -- near-zero sample AND stamp a near-zero cooldown over the real one. Two seconds cannot hide a
    -- genuine cycle, since the next cover is at least cooldown + 4s of activation away.
    local sinceEnd = t - (tonumber(ataxiaTemp.bmAugmentEndedAt) or -99)
    if not ataxiaTemp.bmAugmentUpAt and sinceEnd > 2 then
      ataxiaTemp.bmAugmentUpAt = t
      -- Snapshot the spend at the moment cover begins: bmAugmentSpent is overwritten by the next
      -- send, and a long augment can outlive several rounds.
      ataxiaTemp.bmAugmentUpSpend = tonumber(ataxiaTemp.bmAugmentSpent)
    end
    return 0 -- it is up; the gate above already refuses on the defence itself
  end

  -- Only reached when the dissipate line was MISSED -- it clears bmAugmentUpAt itself, so this is
  -- the backstop for the down edge exactly as bmAugmentCdUntil is for the cooldown.
  if ataxiaTemp.bmAugmentUpAt then augmentCycleEnded(t) end

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
    .. "\n  is a fixed tax a SHORT augment pays proportionally more of. Timed between the game's own"
    .. "\n  cover-starts and dissipates lines. Set the spend with <white>bash augment <n><reset>.\n")
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
