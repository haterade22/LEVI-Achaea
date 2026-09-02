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

-- ---------------------------------------------------------------------------
-- OBLIGATE CARNIVORE + HEALING METABOLISM (Mnemosyne boons, v4.7.294)
-- ---------------------------------------------------------------------------
--
--   Obligate Carnivore: "You can EAT corpses, restoring hunger and small amounts of endurance
--                        and willpower."
--   Healing Metabolism: "Your health elixirs are 50% more effective while you possess the
--                        satiation defence."
--
-- Held together these change food from an EMERGENCY into an UPKEEP. The horn exists because
-- starvation knocks you unconscious; satiation is the opposite end of the same axis -- a defence
-- worth holding for the elixir bonus, which in the tower is a real fraction of our survivability.
--
-- WHY CORPSES OUTRANK THE HORN, always, whenever the boon is held: a corpse is free and arrives
-- by itself (`340_Slain`: "...retrieving the corpse"), while the horn holds SIX charges and
-- refills on its own clock. Spending a horn charge on hunger we could have eaten off the floor is
-- the one avoidable cost here. So `ataxia_hornOnHungry` tries a corpse first and falls back.
--
-- NO COMMAND IS GUESSED. Every piece is proven in this tree:
--   * `ii corpse`                    -- `aliases/.../176_Butchering.lua`
--   * that listing's rows -> an id   -- `triggers/733_Corpse_Found.lua` parses exactly this shape
--   * that id used as an item ref    -- `misc_scripts/001_Queue_Scanning`: `butcher <id> for reagent`
--   * `eat <id>`                     -- `ataxia_hornFeed` above, on horn item ids
-- The boon supplies the verb ("You can EAT corpses") and the rest is assembly. A bare `eat corpse`
-- would have been shorter and would have assumed how the game disambiguates a noun we hold several
-- of; the id form assumes nothing.
--
-- ON THE FREE QUEUE. Eating shares the EATING balance with every cure-herb (the whole reason the
-- PvE curing profile exists, v4.7.172), so a corpse eaten mid-fight can delay a real cure. It is
-- sent `queue add free` -- the shape `butcher` already uses -- and the CALLERS decide when: the
-- hunger path is an emergency and fires immediately, while the satiation top-up waits for a kill,
-- which is the moment a fight is ending rather than peaking.

local CORPSE_PROBE_TIMEOUT = 3
-- Long enough that a burst of kills cannot queue a probe each, short enough to hold satiation
-- across a normal clearing pace. Corpses are free, so the cost of erring long is only the buff.
local CORPSE_EAT_COOLDOWN = 45

local function corpseCleanup()
  if ataxiaTemp.corpseTrigger then pcall(killTrigger, ataxiaTemp.corpseTrigger) end
  if ataxiaTemp.corpseTimer then pcall(killTimer, ataxiaTemp.corpseTimer) end
  ataxiaTemp.corpseTrigger, ataxiaTemp.corpseTimer = nil, nil
end

-- Probe our corpses, take the first, eat it. Returns false when the boon is absent or the
-- throttle is closed, so a caller can fall through to the horn.
function ataxia_carnivoreEat(reason, force)
  if not mnemObligateCarnivore then return false end
  if not force then
    local last = tonumber(ataxiaTemp.corpseAteAt) or 0
    if (getEpoch() - last) < CORPSE_EAT_COOLDOWN then return false end
  end
  -- Stamped on the ATTEMPT as well as on the confirmed line, because the probe may find nothing
  -- at all -- and without this an empty inventory would re-probe on every single kill.
  ataxiaTemp.corpseAteAt = getEpoch()
  corpseCleanup()

  -- The same row shape `733_Corpse_Found` already parses off `ii corpse`. FIRST match only, then
  -- disarm: we want one corpse, not the whole inventory.
  ataxiaTemp.corpseTrigger = tempRegexTrigger([[^\s+(.+)the corpse of (.+)$]], function()
    local id, what = string.trim(matches[2]), matches[3]
    corpseCleanup()
    send("queue add free eat " .. id, false)
    if ataxiaEcho then
      ataxiaEcho("Obligate Carnivore: eating <green>the corpse of " .. tostring(what) .. "<reset>"
        .. (reason and (" (" .. reason .. ")") or "") .. ".")
    end
  end)

  -- Backstop: no corpses listed. Silent by design -- an empty pack is the normal state between
  -- kills, and a warning here would fire constantly and teach the user to ignore the channel.
  ataxiaTemp.corpseTimer = tempTimer(CORPSE_PROBE_TIMEOUT, corpseCleanup)

  send("ii corpse", false)
  return true
end

-- Confirmed by the game (trigger `highlighting/061`), so the throttle is re-stamped from the line
-- that proves we ate rather than only from the attempt. Same reasoning as every cooldown here: an
-- eaten command has not spent anything.
function ataxia_carnivoreAte()
  mnemObligateCarnivore = true   -- self-proving: this line only prints with the boon up
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.corpseAteAt = getEpoch()
end

-- Satiation upkeep, called from the kill trigger. HEALING METABOLISM is what makes this worth
-- doing at all: without it a corpse is just food and the horn's emergency path suffices; with it,
-- the satiation defence is a 50% elixir multiplier and letting it lapse costs healing we cannot
-- get back mid-fight. Fired on a KILL because that is when a corpse exists AND the fight is
-- ending -- eating mid-round would contend with cure-herbs for the eating balance.
function ataxia_carnivoreTopUp()
  if not (mnemObligateCarnivore and mnemHealingMetabolism) then return false end
  return ataxia_carnivoreEat("satiation upkeep")
end

-- Called by the hunger triggers. Kept separate from the feed itself so the "are we
-- actually in trouble" decision lives in one place.
--
-- CORPSE FIRST while Obligate Carnivore is held (v4.7.294): it is free where a horn charge is one
-- of six. `ataxia_carnivoreEat` is FORCED here -- this path only runs when the game has told us we
-- are starving, and starvation ends in unconsciousness, so a throttle meant for upkeep must not
-- stand in front of an emergency.
function ataxia_hornOnHungry(state)
  if mnemObligateCarnivore and ataxia_carnivoreEat(state or "hungry", true) then return end
  ataxia_hornFeed(state or "hungry")
end
