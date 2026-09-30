--[[mudlet
type: script
name: Glass Lily
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- CLOUDED GLASS LILY -- DROP LILY every hour (v4.7.367).
--
-- User: "We need to DROP LILY every hour." TALISMAN INFO LILY:
--
--   a clouded glass lily -- Purchasable in Delos for 300 bound credits. By dropping the lily ...
--   you will get a short-term boost or hindrance to critical hit severity. Getting a boost is more
--   likely than being hindered.
--
-- The drop, in the user's log (three lilies, dropped together):
--
--   You let a clouded glass lily fall to the ground, its fragile form crumbling into dust upon
--   impact.
--   A feeling of superiority washes over you.
--
-- Until now the lilies went down only when the BASHER was switched on (basher_engaged sent
-- `drop lily;drop lily;drop lily`), so a long session got one boost and then nothing. Now:
--
--   * DUE once an hour, counted from the game's own DROP LINE (trigger 785), not from when we
--     sent the command. A drop that never happened (off balance, no lilies, a busy moment) does not
--     start the hour; it is retried after LILY_RETRY. The same lesson as the Psion foresight: a
--     long cooldown is stamped by the confirmation, never by the attempt.
--   * CHECKED on every prompt (gmcp.Char.Vitals), so it happens whether or not we are bashing.
--   * SENT DIRECTLY, never queued: the basher's `queue addclearfull` would delete it, and dropping
--     is not an attack that needs to wait for anything.
--   * AS MANY AS WE CARRY: `ataxia.settings.lilyCount`, default 3 -- the three the old engage line
--     sent and the three in the user's log. `drop lily` with none left is refused and harmless.
--   * The engage path now asks the same question ("due?") instead of dropping unconditionally.
--
-- NOT KNOWN YET: the hindrance line, and what the game says when a lily is dropped too soon (if it
-- says anything). A refusal we cannot see just waits out LILY_RETRY.
--
-- Commands: `lily` (status), `lily on|off`, `lily now`, `lily count <n>` -- aliases/configs/024.

ataxia = ataxia or {}
ataxiaTemp = ataxiaTemp or {}

local LILY_EVERY = 3600   -- seconds from one confirmed drop to the next
local LILY_RETRY = 300    -- an attempt with no drop line: try again after this long

local function now() return (getEpoch and getEpoch()) or os.time() end

function ataxia_lilyEnabled()
  return not (ataxia.settings and ataxia.settings.lilyAuto == false)
end

function ataxia_lilyCount()
  local n = tonumber(ataxia.settings and ataxia.settings.lilyCount) or 3
  return math.max(1, math.floor(n))
end

-- Seconds until the next drop is due (0 = due now).
function ataxia_lilyWait(t)
  t = t or now()
  local sinceDrop = t - (tonumber(ataxiaTemp.lilyDroppedAt) or -1e9)
  local sinceTry = t - (tonumber(ataxiaTemp.lilyTriedAt) or -1e9)
  return math.max(0, LILY_EVERY - sinceDrop, LILY_RETRY - sinceTry)
end

-- Drop every lily we carry if one is due. `force` (the `lily now` command) skips both the
-- switch and the clock. Returns true when it sent.
function ataxia_lilyDrop(reason, force)
  if not force then
    if not ataxia_lilyEnabled() then return false end
    if ataxia_lilyWait() > 0 then return false end
  end
  ataxiaTemp.lilyTriedAt = now()
  local sp = (ataxia.settings and ataxia.settings.separator) or ";"
  local cmds = {}
  for i = 1, ataxia_lilyCount() do cmds[i] = "drop lily" end
  send(table.concat(cmds, sp), false)
  if ataxiaEcho then
    ataxiaEcho("Glass lily: dropping <cyan>" .. #cmds .. "<reset>"
      .. (reason and (" (" .. reason .. ")") or "") .. ".")
  end
  return true
end

-- Trigger 785, on each "You let a clouded glass lily fall to the ground" line: the hour starts now.
-- Several lines arrive together for one batch; each re-stamps the same moment, which is harmless.
function ataxia_lilyDropped()
  ataxiaTemp.lilyDroppedAt = now()
  ataxiaTemp.lilyTriedAt = nil
end

-- Every prompt. Cheap: two subtractions unless a drop is due.
function ataxia_lilyTick()
  ataxia_lilyDrop("hourly")
end

if ataxia_lilyHandler then killAnonymousEventHandler(ataxia_lilyHandler) end
ataxia_lilyHandler = registerAnonymousEventHandler("gmcp.Char.Vitals", "ataxia_lilyTick")
