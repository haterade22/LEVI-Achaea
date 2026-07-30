--[[mudlet
type: script
name: Horn Of Plenty
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

-- HORN OF PLENTY -- automatic feeding when starvation starts costing us fights.
--
-- Why this exists: starvation does not just tick damage, it knocks you UNCONSCIOUS.
-- A live log (2026-07-29, Mnemosyne jungle) shows the failure mode exactly -- "Your legs
-- collapse from under you and consciousness leaves you as you pass out." followed by a
-- wall of "You are unconscious and thus incapable of action." while a puma, two
-- cockatrices and our own hyena chewed through ~10k health. No cure, no flee, no attack:
-- every safety net in the system is useless while unconscious. Feeding is the fix, and it
-- has to be automatic because by the time you notice, you cannot act.
--
-- The horn holds up to 6 items and resets to us, so an unnecessary eat costs almost
-- nothing -- but a missed one can cost a run.
--
-- Flow: PROBE HORN -> capture the first item id from the listing -> GET <id> FROM HORN ->
-- EAT <id>. The id has to be read from the probe because the contents are randomised
-- ("loaf545957", "potpie268371", "pork528142" ...), and they change as the horn refills.

ataxia = ataxia or {}
ataxiaTemp = ataxiaTemp or {}

-- Seconds before another feed attempt may run. Long enough that a burst of hunger lines
-- can't queue a dozen probes, short enough to retry if the first attempt was eaten.
local FEED_COOLDOWN = 20
-- How long to wait for the probe listing before giving up on the capture.
local PROBE_TIMEOUT = 3

-- Tear down a capture in flight (idempotent -- safe to call twice).
local function hornCleanup()
  if ataxiaTemp.hornTrigger then pcall(killTrigger, ataxiaTemp.hornTrigger) end
  if ataxiaTemp.hornTimer then pcall(killTimer, ataxiaTemp.hornTimer) end
  ataxiaTemp.hornTrigger, ataxiaTemp.hornTimer = nil, nil
end

-- Probe the horn, take the first item it lists, and eat it.
--   reason  -- shown in the echo so the log says WHY we fed (starving / manual / ...)
--   force   -- skip the cooldown (the `horn` alias passes this)
function ataxia_hornFeed(reason, force)
  if not force then
    local last = tonumber(ataxiaTemp.hornFedAt) or 0
    if (getEpoch() - last) < FEED_COOLDOWN then return false end
  end
  ataxiaTemp.hornFedAt = getEpoch()
  hornCleanup()

  -- The listing rows look like:  "loaf545957"            a small loaf of waybread
  -- Take the FIRST row only, then disarm -- we want one item, not six.
  ataxiaTemp.hornTrigger = tempRegexTrigger([[^"(\w+)"\s+(.+)$]], function()
    local id, what = matches[2], matches[3]
    hornCleanup()
    local sp = (ataxia.settings and ataxia.settings.separator) or ";"
    send("get " .. id .. " from horn" .. sp .. "eat " .. id, false)
    if ataxiaEcho then
      ataxiaEcho("Horn of plenty: eating <green>" .. tostring(what) .. "<reset>"
        .. (reason and (" (" .. reason .. ")") or "") .. ".")
    end
  end)

  -- Backstop: no listing (horn missing, empty, or the probe was eaten) -> stop listening
  -- rather than leaving a catch-all regex armed over ordinary combat text.
  ataxiaTemp.hornTimer = tempTimer(PROBE_TIMEOUT, function()
    if ataxiaTemp.hornTrigger and ataxiaEcho then
      ataxiaEcho("<red>Horn of plenty: no items listed<reset> -- is the horn carried and stocked?")
    end
    hornCleanup()
  end)

  send("probe horn", false)
  return true
end

-- Called by the hunger triggers. Kept separate from the feed itself so the "are we
-- actually in trouble" decision lives in one place.
function ataxia_hornOnHungry(state)
  ataxia_hornFeed(state or "hungry")
end
