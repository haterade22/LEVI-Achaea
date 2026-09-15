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
-- SENT DIRECTLY, NOT QUEUED (v4.7.304, from a live log). v4.7.294 put the eat on the FREE queue
-- to survive the basher's `queue addclearfull`. It never ate. The kill top-up fires at the exact
-- moment a room clears, and the explorer's own move for that moment is `queue addclear free
-- stand;<dir>` (008_Explorer) -- which CLEARS the free queue before adding the step. The log
-- shows it verbatim: our "eating the corpse of Giacinto" echo, then "room clear -> moving ne",
-- and no eat. EAT needs no balance ("It is balance less" -- user), so there was never anything
-- to queue for: `send("eat <id>")` executes at once, the way the horn's `get;eat` always has.
-- **A queue is a place a command can be deleted from; a balanceless command has no reason to be
-- in one.** The CALLERS still decide WHEN: the hunger path is an emergency and fires immediately,
-- the satiation top-up waits for a kill -- the moment a fight is ending rather than peaking --
-- which is what keeps the eat off the eating balance a cure-herb might need.

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
    send("eat " .. id, false)
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
--
-- THE 5s RE-FIRE THROTTLE LIVES HERE (moved from trigger 374 in v4.7.303, so the observation
-- path above it can stay unthrottled): the standing hunger lines can repeat, the corpse path is
-- FORCED past its own cooldown, and the horn's 20s cooldown covers only its own branch.
local STARVING_RETRY = 5
function ataxia_hornOnHungry(state)
  ataxiaTemp = ataxiaTemp or {}
  local nowT = getEpoch()
  if (nowT - (tonumber(ataxiaTemp.starvingRespondAt) or 0)) < STARVING_RETRY then return false end
  ataxiaTemp.starvingRespondAt = nowT
  if mnemObligateCarnivore and ataxia_carnivoreEat(state or "hungry", true) then return true end
  return ataxia_hornFeed(state or "hungry")
end

-- ---------------------------------------------------------------------------
-- HEALING METABOLISM ALONE: HOLD "UTTERLY SATIATED" OFF THE HORN (v4.7.303, user-directed)
-- ---------------------------------------------------------------------------
--
-- User: "When we have this boon we need to be full satiation. I have a horn which produces
-- food ... Get loaf from horn / eat loaf / If HUNGER is lower than utterly satiated."
--
-- v4.7.294 held satiation only when BOTH boons were up (a corpse top-up on every kill) and said
-- of Metabolism alone "there is no food source". There is: the horn. Six charges on a refill
-- clock is a real cost, and the user has priced it -- the 50% elixir bonus is worth the charges.
--
-- THREE WAYS TO NOTICE HUNGER, because none is complete on its own:
--   1. The SCORE row `| Hunger : <state>` -- the user's stated authority, and the only place the
--      game prints the WORD. It prints only when SCORE is sent, so alone it observes nothing.
--   2. The satiation DEFENCE leaving `gmcp.Char.Defences`. The boon itself calls it "the
--      satiation defence", so it is in DEF and GMCP reports it. Its exact GMCP name is INFERRED
--      (any defence whose name contains "satiat") and unverified -- but a Remove can only follow
--      an Add, so a wrong guess costs nothing: the path simply never fires (the Songstep
--      hawkstep/wavedance reasoning, v4.7.200). Live and free of noise when it does.
--   3. A SCORE on a KILL when the last reading is older than `ataxia.settings.satiatePoll`
--      seconds (default 300; 0 = never) -- the backstop for (2) being wrong. Kill-driven rather
--      than timer-driven on purpose: it runs only while we are actually bashing (the only time
--      hunger burns fast and elixirs matter), at the moment a fight is ending, and it needs no
--      lifecycle wiring of its own.
--
-- A FEED IS VERIFIED. One loaf may not climb the whole hunger ladder, so `SATIATE_VERIFY`
-- seconds after an upkeep feed we SCORE again; a row still below satiated feeds again, FORCED
-- past the horn's 20s cooldown -- bounded at `SATIATE_MAX_CHAIN` per episode, so an empty horn,
-- a refused eat or an unparseable row can never spend charges forever. The episode ends when the
-- row reads "utterly satiated", or falls silent for `SATIATE_EPISODE_GAP`.
--
-- Corpses still outrank the horn whenever Obligate Carnivore is held (unforced, so the corpse
-- throttle stands and a closed one falls through to the horn). The eat itself is the proven
-- `ataxia_hornFeed` path -- `probe horn` -> first listed id -> `get <id> from horn;eat <id>` --
-- so nothing new is guessed about the horn.

local SATIATED = "utterly satiated"
local EMERGENCY_HUNGER = { ["starving to death"] = true, famished = true, ravenous = true }
local SATIATE_VERIFY = 6        -- seconds after an upkeep feed before the confirming SCORE
local SATIATE_MAX_CHAIN = 3     -- feeds per episode before we stop and wait for a fresh reading
local SATIATE_EPISODE_GAP = 300 -- a chain older than this is a stale episode; start a new one
local SATIATE_POLL_DEFAULT = 300

local function satiateVerifyCleanup()
  if ataxiaTemp.satiateVerifyTimer then pcall(killTimer, ataxiaTemp.satiateVerifyTimer) end
  ataxiaTemp.satiateVerifyTimer = nil
end

-- Upkeep feed. Returns true when something was sent.
function ataxia_hornSatiate(state)
  if not mnemHealingMetabolism then return false end
  ataxiaTemp = ataxiaTemp or {}
  local nowT = getEpoch()
  if (nowT - (tonumber(ataxiaTemp.satiateChainAt) or 0)) > SATIATE_EPISODE_GAP then
    ataxiaTemp.satiateChain = 0
  end
  local chain = tonumber(ataxiaTemp.satiateChain) or 0
  if chain >= SATIATE_MAX_CHAIN then return false end

  local reason = "satiation upkeep" .. (state and (" -- " .. tostring(state)) or "")
  local fed = false
  if mnemObligateCarnivore and ataxia_carnivoreEat(reason) then fed = true end
  -- A chained feed forces past the horn's 20s cooldown: the verify comes back in SATIATE_VERIFY
  -- seconds, and the chain bound is what keeps that safe.
  if not fed then fed = ataxia_hornFeed(reason, chain > 0) end
  if not fed then return false end

  ataxiaTemp.satiateChain, ataxiaTemp.satiateChainAt = chain + 1, nowT
  satiateVerifyCleanup()
  ataxiaTemp.satiateVerifyTimer = tempTimer(SATIATE_VERIFY, function()
    ataxiaTemp.satiateVerifyTimer = nil
    if mnemHealingMetabolism then send("score", false) end
  end)
  return true
end

-- The SCORE row, from trigger 374. Records the reading, then routes: emergency states take the
-- starvation path whether or not any boon is held; anything else below "utterly satiated" is
-- upkeep, and "utterly satiated" closes the episode. Returns what it did, for the trigger's echo.
function ataxia_hungerSeen(state)
  state = tostring(state or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.hungerState, ataxiaTemp.hungerSeenAt = state, getEpoch()
  if state == SATIATED then
    ataxiaTemp.satiateChain, ataxiaTemp.satiateChainAt = nil, nil
    satiateVerifyCleanup()
    return "satiated"
  end
  if EMERGENCY_HUNGER[state] then
    return ataxia_hornOnHungry(state) and "emergency" or false
  end
  return ataxia_hornSatiate(state) and "upkeep" or false
end

-- The satiation defence, off GMCP (way 2 above). Substring on "satiat" because the exact GMCP
-- name has never been captured; nothing else in DEF contains it.
local function isSatiationDef(name)
  return type(name) == "string" and name:lower():find("satiat", 1, true) ~= nil
end

function ataxia_satiationLost()
  local rem = gmcp and gmcp.Char and gmcp.Char.Defences and gmcp.Char.Defences.Remove
  local name = type(rem) == "table" and rem[1] or rem
  if not isSatiationDef(name) then return false end
  if not mnemHealingMetabolism then return false end
  return ataxia_hornSatiate("satiation defence lost")
end

-- Kill-driven backstop (way 3 above), called from trigger 340 beside the corpse top-up. With
-- BOTH boons the v4.7.294 corpse top-up already keeps satiation up blind and free, so no SCORE is
-- spent; with Metabolism alone, ask when the last reading is stale.
function ataxia_satiateKillCheck()
  if not mnemHealingMetabolism then return false end
  if mnemObligateCarnivore then return false end
  local poll = tonumber(ataxia.settings and ataxia.settings.satiatePoll)
  if poll == nil then poll = SATIATE_POLL_DEFAULT end
  if poll <= 0 then return false end
  ataxiaTemp = ataxiaTemp or {}
  local nowT = getEpoch()
  if (nowT - (tonumber(ataxiaTemp.hungerSeenAt) or 0)) < poll then return false end
  if (nowT - (tonumber(ataxiaTemp.satiatePolledAt) or 0)) < poll then return false end
  ataxiaTemp.satiatePolledAt = nowT
  send("score", false)
  return true
end

-- Re-registered on every load; the previous registration (a SYSUPDATE reload) is killed first
-- so the handler cannot stack. The id lives on ataxiaTemp, which survives a reload and is never
-- serialized (a timer or handler id on the saved namespace names a stranger after a restart).
ataxiaTemp = ataxiaTemp or {}
if ataxiaTemp.satiateDefHandler and killAnonymousEventHandler then
  pcall(killAnonymousEventHandler, ataxiaTemp.satiateDefHandler)
end
ataxiaTemp.satiateDefHandler = registerAnonymousEventHandler("gmcp.Char.Defences.Remove", function()
  if ataxia_satiationLost then ataxia_satiationLost() end
end)
