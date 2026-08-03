--[[mudlet
type: script
name: Mnemosyne Legend Deck
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

-------------------------------------------------------------------------------
--                  MNEMOSYNE LEGEND DECK AUTO-DRAW (v4.7.165)               --
--                                                                           --
--  Condition-driven card layer for the basher, gated to Mnemosyne. The      --
--  pre-existing ldeck automation was MOB-NAME driven (`ataxiaBasher.        --
--  ldeckRules` in genrunning/002 -- "3 mhun knights in the room -> maran")  --
--  which cannot work in the tower: the denizen roster is different every    --
--  ripple. This layer keys off STATE instead (hp, denizen count, bindings,  --
--  battlerage), so it works on any mob the tower throws at us.              --
--                                                                           --
--  The rules (user-specified):                                              --
--    Maran     -- hp <= 20%   (5000hp barrier on the room, 60s)             --
--    Seasone   -- hp <= 35%   (FOR ELIXIR: +10% health elixir, 5 min)       --
--    Morimbuul -- while bound (shrug off denizen ropes/bindings, 5 min)     --
--    Matic     -- 3+ denizens (next attack is a guaranteed high-end crit)   --
--    Covenant  -- when we can AFFORD the battlerage that cashes in the      --
--                 RECKLESSNESS it plants (Blademaster Headstrike / Magi     --
--                 Firefall, 25 rage)                                        --
--    Xylthus   -- same, for the STUN it plants (Runewarden Etch, 25 rage)   --
--                                                                           --
--  ECONOMY. These cards hold 2-3 charges and regenerate ONE PER HOUR, so    --
--  the charge count is the real limiter and every gate here is deliberately --
--  conservative: at most ONE card per round, a per-card minimum interval,   --
--  a hard `ldm.hasCharges` check, and skips when the effect is already up   --
--  (the denizen already carries the affliction, we are already barriered).  --
--                                                                           --
--  IN-FLIGHT REPLAY. The basher rebuilds its command every prompt with      --
--  `queue addclearfull`, which WIPES the queued line -- so stamping the     --
--  interval at build time would drop the draw from the very next rebuild,   --
--  before it ever executed (the v4.7.129 phantom-cooldown bug). The pick is --
--  therefore held PENDING and replayed verbatim until `ldm.onDraw` confirms --
--  it landed (or the ~4s window lapses).                                    --
--                                                                           --
--  Pure decision logic lives in `ataxiaBasher_mnemLdeckPick` (unit-tested   --
--  in tests/test_mnem_ldeck.lua); the glue that stamps and formats is       --
--  `ataxiaBasher_mnemLdeck`.                                                --
-------------------------------------------------------------------------------

ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = ataxiaTemp or {}

-- User-tunable thresholds (persist with ataxiaBasher; `mnem cards ...`).
ataxiaBasher.mnemLdeck = ataxiaBasher.mnemLdeck or {}
do
  local c = ataxiaBasher.mnemLdeck
  if c.enabled == nil then c.enabled = true end
  c.maranAt   = tonumber(c.maranAt)   or 20  -- hp% for the barrier
  c.seasoneAt = tonumber(c.seasoneAt) or 35  -- hp% for the elixir boost
  c.maticAt   = tonumber(c.maticAt)   or 3   -- denizens for the guaranteed crit
  -- Mob-hp floor for the OFFENSIVE cards (Matic/Covenant/Xylthus): below this the
  -- mob dies before the card pays for itself. Defensive draws are never gated on it.
  c.conserveAt = tonumber(c.conserveAt) or 25
end

-- Bindings Morimbuul shrugs off. The user's rule named WEBBED; the card covers
-- "denizen ropes or bindings" generally and every one of these stops the basher
-- dead (they are all in the attack gate), so the whole family is in by default.
-- Narrow it by editing this table if a charge ever feels wasted.
ataxiaBasher.mnemLdeckBindings = ataxiaBasher.mnemLdeckBindings or {
  "webbed", "entangled", "transfixation", "constricted", "snared", "roped",
}

local function now()
  return getEpoch and getEpoch() or 0
end

-- Which battlerage attack cashes in a card-planted affliction, what it costs, and
-- whether it is off cooldown RIGHT NOW. Only classes whose rotation actually READS
-- the affliction are listed -- drawing Covenant as, say, Psion would plant
-- recklessness nothing can spend.
--   recklessness -> Blademaster Headstrike (001:776) / Magi Firefall (001:913)
--   stun         -> Runewarden Etch (002 RW_BR, needsAff {aeon, stun})
-- `ready` matters as much as the rage: a charge spent on an affliction we cannot
-- cash for another 20s is a charge thrown away, and these regenerate hourly.
local CARD_EXPLOIT = {
  Blademaster = { recklessness = { rage = 25, ready = function()
    return now() >= (ataxiaTemp.bmHeadstrikeReadyAt or 0)
  end } },
  Magi = { recklessness = { rage = 25, ready = function()
    return now() >= (ataxiaTemp.magiFirefallReadyAt or 0)
  end } },
  Runewarden = { stun = { rage = 25, ready = function()
    local at = (ataxiaTemp.rwBrAt or {}).etch
    return (not at) or (now() - at) >= 23 -- Etch cooldown (AB)
  end } },
}

-- key      = ldm.deck key (proper case -- charges live under it)
-- cmd      = draw command; "<t>" is substituted with the numeric denizen id
-- gap      = minimum seconds between draws of this card (>= the effect duration,
--            so a redraw only ever RENEWS something that has lapsed)
-- perRoom  = additionally at most once per room
local MNEM_CARDS = {
  { key = "Morimbuul", cmd = "ldeck draw morimbuul",          gap = 300 },
  { key = "Maran",     cmd = "ldeck draw maran",              gap = 65  },
  -- NOTE on the Seasone command shape: the variant is a BARE argument. The card's own
  -- help text reads "DRAW FOR ELIXIR or FOR POISON", which reads like syntax but is not --
  -- "ldeck draw seasone for elixir" is rejected with "You must draw that card for either
  -- ELIXIR or POISON." (live 2026-07-31). ldm.draw appends arguments bare for the same reason.
  { key = "Seasone",   cmd = "ldeck draw seasone elixir",     gap = 300 },
  { key = "Matic",     cmd = "ldeck draw matic",              gap = 45, perRoom = true },
  -- `stampAff` records the affliction ON CONFIRMATION (see the confirm handler).
  -- Covenant has none: it lands charm OR recklessness 50/50 and BOTH game lines are
  -- already captured in BR_AFFS, so the real trigger records the truth. Xylthus's
  -- bind line is not captured yet, hence the stamp. Live capture wanted.
  { key = "Covenant",  cmd = "ldeck draw covenant <t>",       gap = 45, aff = "recklessness" },
  { key = "Xylthus",   cmd = "ldeck draw xylthus <t>",        gap = 45, aff = "stun", stampAff = "stun" },
}

local PENDING_WINDOW = 4 -- seconds a queued-but-unconfirmed draw is replayed

local function charges(key)
  if ldm and ldm.getCharges then return ldm.getCharges(key) end
  -- Legacy proxy (ataxiaTables.ldeckcardscount) as a fallback, and 0 when the
  -- deck module isn't loaded -- unknown charges must never authorise a draw.
  local t = ataxiaTables and ataxiaTables.ldeckcardscount
  return (t and tonumber(t[key])) or 0
end

local function hpp()
  local v = (ataxia and ataxia.vitals and tonumber(ataxia.vitals.hpp)) or 0
  -- 0 is the blackout/unknown reading the rest of the basher also distrusts.
  if v <= 0 then return nil end
  return v
end

local function className()
  local st = gmcp and gmcp.Char and gmcp.Char.Status
  local c = st and st.class
  if type(c) ~= "string" or c == "" then return nil end
  if c.title then c = c:title() else c = c:gsub("^%l", string.upper) end
  return (c:gsub(" Lady", ""):gsub(" Lord", ""))
end

local function denizenCount()
  local M = ataxia and ataxia.mnemosyne
  return (M and M._denizenCount and M._denizenCount()) or 0
end

local function isBound()
  local a = (ataxia and ataxia.afflictions) or {}
  for _, aff in ipairs(ataxiaBasher.mnemLdeckBindings or {}) do
    if a[aff] then return true end
  end
  return false
end

-- Xylthus explicitly does not work on bosses (HELP LEGENDDECK), so never spend a
-- charge on one. The Objective line names the boss ("defeat Seasone the
-- Industrious"); the mob's short description is worded differently, so match on
-- the boss's leading word rather than the whole string.
local function targetIsBoss()
  local M = ataxia and ataxia.mnemosyne
  local boss = M and M.run and M.run.boss
  if type(boss) ~= "string" or boss == "" then return false end
  local nm = secondTarget
  if type(nm) ~= "string" or nm == "" then return false end
  local first = boss:lower():match("[%a]+")
  if not first or #first < 4 then return false end
  return nm:lower():find(first, 1, true) ~= nil
end

-- Is the current target too nearly dead to be worth a card? The battlerage
-- rotations already refuse to spend rage on a mob about to die
-- (`ataxiaBasher.rageConserveThreshold`, five near-identical sites incl.
-- 001:1030 and 002:1477); the same logic applies far MORE strongly here, because
-- rage refills in seconds and these charges refill once an HOUR. A guaranteed
-- crit (Matic) on a mob at 5% is the purest waste in the whole layer.
--
-- The GMCP read is fully guarded: unlike the rotation call sites, this function
-- runs under pcall in assembleAttack (001:621), so an unguarded index on a
-- not-yet-delivered Target.Info would be swallowed and would silently disable the
-- ENTIRE card layer with no error surfaced.
local function targetNearlyDead()
  local floor = tonumber(ataxiaBasher.mnemLdeck and ataxiaBasher.mnemLdeck.conserveAt)
  if not floor or floor <= 0 then return false end
  local ti = gmcp and gmcp.IRE and gmcp.IRE.Target and gmcp.IRE.Target.Info
  local raw = ti and ti.hpperc
  local mobhp = tonumber((tostring(raw or ""):gsub("%%", "")))
  if not mobhp or mobhp <= 0 then return false end -- no reading = never block
  return mobhp <= floor
end

-- Pure-ish decision: the ONE card to draw right now, or nil. `stamps` is the
-- per-card last-draw epoch table (injectable for tests).
function ataxiaBasher_mnemLdeckPick(t, stamps)
  local cfg = ataxiaBasher.mnemLdeck or {}
  if not cfg.enabled then return nil end
  if not ataxiaBasher.inMnemosyne then return nil end
  t = t or now()
  stamps = stamps or ataxiaTemp.mnemLdeckAt or {}

  local hp = hpp()
  local bound = isBound()
  local mobs = denizenCount()
  local class = className()
  local exploit = class and CARD_EXPLOIT[class] or nil
  local rage = (ataxia and ataxia.vitals and tonumber(ataxia.vitals.rage)) or 0
  local room = (gmcp and gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.num) or "unknown"

  for _, card in ipairs(MNEM_CARDS) do
    local want = false

    if card.key == "Morimbuul" then
      want = bound
    elseif card.key == "Maran" then
      -- BRAVADO ("unable to benefit from ... prismatic barriers", v4.7.206) makes Maran's
      -- 5000hp barrier do nothing. These charges regenerate ONE PER HOUR, so this is the
      -- single most wasteful draw the layer could make under that affix.
      want = not mnemBravado and hp ~= nil and hp <= (tonumber(cfg.maranAt) or 20)
    elseif card.key == "Seasone" then
      want = hp ~= nil and hp <= (tonumber(cfg.seasoneAt) or 35)
    elseif card.key == "Matic" then
      want = mobs >= (tonumber(cfg.maticAt) or 3) and not targetNearlyDead()
    elseif card.aff then
      -- "Enough battlerage to do a battlerage attack that benefits from this."
      -- Also needs a live denizen target, and is pointless if the mob already
      -- carries the affliction (or, for Xylthus, cannot be bound at all).
      local ex = exploit and exploit[card.aff]
      want = ex ~= nil
        and type(target) == "number"
        and ataxiaBasher_rageAfford ~= nil
        and ataxiaBasher_rageAfford(rage, ex.rage)
        and (not ex.ready or ex.ready() == true)
        and not targetNearlyDead()
        and not (ataxiaBasher_dsHasAff and ataxiaBasher_dsHasAff(target, card.aff))
      if want and card.key == "Xylthus" and targetIsBoss() then want = false end
    end

    if want and charges(card.key) > 0 then
      local last = tonumber(stamps[card.key]) or -math.huge
      local ready = (t - last) >= card.gap
      if ready and card.perRoom then
        ready = (ataxiaTemp.mnemLdeckRoom or {})[card.key] ~= room
      end
      if ready then
        return card.key, (card.cmd:gsub("<t>", tostring(target))), card
      end
    end
  end

  return nil
end

-- Basher glue: returns "" or "<draw command><sep>" to ride the assembled round.
-- Holds the pick PENDING so the 0.3s addclearfull rebuild loop replays the same
-- draw instead of stamping it away unsent (see the header).
function ataxiaBasher_mnemLdeck(sp)
  sp = sp or (ataxia and ataxia.settings and ataxia.settings.separator) or ";"
  ataxiaTemp.mnemLdeckAt = ataxiaTemp.mnemLdeckAt or {}
  ataxiaTemp.mnemLdeckRoom = ataxiaTemp.mnemLdeckRoom or {}

  local t = now()
  local p = ataxiaTemp.mnemLdeckPending
  if p then
    -- A TARGETED card's replay is only valid for the denizen it was drawn at. Covenant and
    -- Xylthus bake the numeric id into `cmd` via the <t> substitution, and the replay below
    -- resends that string verbatim for up to PENDING_WINDOW seconds -- so a kill inside the
    -- window (the basher retargets immediately) had us drawing an hourly-regenerating card
    -- at a denizen that is no longer there. Drop the pick instead: `Lapse` also holds the
    -- card's interval, which is right, because we genuinely do not know whether the first
    -- send landed.
    --
    -- Keyed on `targeted`, NOT on `target`. Every pending record carries `target` -- the
    -- untargeted cards need it too, because that is who `Confirm` attributes stampAff to --
    -- so testing it here would also drop Maran/Seasone/Morimbuul/Matic on a retarget, and
    -- those commands contain no id to have gone stale. `targeted` is set from the card
    -- TEMPLATE actually containing <t>, which is exactly the condition that makes the
    -- cached string wrong.
    if p.targeted and target ~= p.target then
      ataxiaBasher_mnemLdeckLapse(p.key)
      p = nil
    elseif (t - (p.at or 0)) < PENDING_WINDOW then return p.cmd .. sp end
  end
  if p then
    -- Window lapsed with NO confirmation. Hold the interval so a silently-eaten
    -- draw can't loop forever -- but this is emphatically NOT a confirmation, so
    -- it must not stamp the affliction. Calling Confirm here (v4.7.166) re-opened
    -- the exact phantom-stun hole that release was meant to close.
    ataxiaBasher_mnemLdeckLapse(p.key)
  end

  local key, cmd, card = ataxiaBasher_mnemLdeckPick(t)
  if not key then return "" end

  ataxiaTemp.mnemLdeckPending = {
    key = key, cmd = cmd, at = t,
    stampAff = card and card.stampAff,
    target = (type(target) == "number") and target or nil,
    -- Did the card TEMPLATE bake the denizen id into the command? Only then does a
    -- retarget invalidate the cached replay string (see the guard at the top).
    targeted = (card and card.cmd and card.cmd:find("<t>", 1, true)) ~= nil,
  }
  if card and card.perRoom then
    local room = (gmcp and gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.num) or "unknown"
    ataxiaTemp.mnemLdeckRoom[key] = room
  end

  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert("ldeck draw " .. key .. " (" .. charges(key) .. " charge(s) left)", "gold")
  end
  return cmd .. sp
end

-- The bare draw command for a round the ATTACK GATE blocked (webbed, entangled,
-- aeon...). Nothing else goes out on such a round, so the caller sends this on
-- the free queue -- but it must go exactly ONCE per pick: the basher re-enters
-- every 0.3s and `queue add free` ACCUMULATES (unlike addclearfull, which
-- replaces), so an unguarded resend would stack a dozen draws and empty the
-- card in seconds. Returns nil after the first call for a given pick.
function ataxiaBasher_mnemLdeckFree()
  local p = ataxiaTemp.mnemLdeckPending
  if not p or p.freeSent then return nil end
  p.freeSent = true
  return p.cmd
end

-- CONFIRMATION. Fed by both draw-success lines: `ldm.onDraw` ("You draw forth the
-- power of X") and the generic charge line ("A card depicting X may be used N more
-- times..."), because the wording is not uniform across cards. Stamps the interval
-- from the moment the draw LANDED and releases the pending replay. Safe to call for
-- cards this layer never asked for -- a HAND-drawn card should hold it off too.
--
-- This is also where a card's affliction is recorded on the denizen: **card ->
-- CONFIRMED -> battlerage**. Stamping it at build time (the first cut of v4.7.165)
-- was a lie whenever the draw failed, and it did fail -- a stale `ldm` charge count
-- sent a Xylthus the game rejected ("currently lacks the power to invoke its stored
-- potential") while Etch spent 25 rage on the phantom stun in the very same queued
-- line. Recording it here means the exploiting battlerage fires on the FOLLOWING
-- round, against a denizen that really carries the affliction.
function ataxiaBasher_mnemLdeckConfirm(key)
  if type(key) ~= "string" then return end
  ataxiaTemp.mnemLdeckAt = ataxiaTemp.mnemLdeckAt or {}
  local p = ataxiaTemp.mnemLdeckPending
  if p and p.key == key then
    if p.stampAff and p.target and ataxiaBasher_dsSetAff then
      ataxiaBasher_dsSetAff(p.target, p.stampAff)
    end
    ataxiaTemp.mnemLdeckPending = nil
  end
  ataxiaTemp.mnemLdeckAt[key] = now()
end

-- LAPSE. The pending replay window ran out and no confirmation line ever arrived --
-- the draw may or may not have happened, so the ONLY safe reading is "we do not know".
-- Hold the card's interval (a silently-eaten draw must not re-fire every round) and
-- release the replay, but stamp NOTHING on the denizen: an unacknowledged draw is
-- exactly the phantom whose affliction cost Etch 25 rage in the first place.
function ataxiaBasher_mnemLdeckLapse(key)
  if type(key) ~= "string" then return end
  ataxiaTemp.mnemLdeckAt = ataxiaTemp.mnemLdeckAt or {}
  local p = ataxiaTemp.mnemLdeckPending
  if p and p.key == key then ataxiaTemp.mnemLdeckPending = nil end
  ataxiaTemp.mnemLdeckAt[key] = now()
end

-- REJECTION. "A card depicting X ... currently lacks the power to invoke its stored
-- potential." -- the game's own ground truth about charges, and the ONLY reliable
-- one: `ldm.initDeck` seeds every unseen card at its MAX, so a deck that has never
-- been LDECK LISTed claims full charges for everything and this layer will happily
-- draw into a wall (live 2026-07-30). Zero the count so the charge gate holds, drop
-- the pending replay so it isn't re-sent, and never stamp an affliction: nothing
-- landed.
function ataxiaBasher_mnemLdeckRejected(key)
  if type(key) ~= "string" then return end
  if ldm and ldm.deck and ldm.deck[key] then
    ldm.deck[key].charges = 0
    if ldm.save then pcall(ldm.save) end
  end
  local p = ataxiaTemp.mnemLdeckPending
  if p and p.key == key then ataxiaTemp.mnemLdeckPending = nil end
  ataxiaTemp.mnemLdeckAt = ataxiaTemp.mnemLdeckAt or {}
  ataxiaTemp.mnemLdeckAt[key] = now()
  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert(key .. " has no charges -- held until the deck recharges", "indian_red")
  end
end

-- Ripple / run boundaries: forget the per-room and in-flight state so a new
-- ripple starts clean. Intervals are deliberately NOT cleared -- the charges are
-- global and regenerate hourly, not per ripple.
function ataxiaBasher_mnemLdeckReset()
  ataxiaTemp.mnemLdeckPending = nil
  ataxiaTemp.mnemLdeckRoom = {}
end

-- `mnem cards` status block.
function ataxiaBasher_mnemLdeckStatus()
  local cfg = ataxiaBasher.mnemLdeck or {}
  local out = function(s) if cecho then cecho("\n" .. s) else print(s) end end
  out("<a_darkcyan>Mnemosyne legend deck: "
    .. (cfg.enabled and "<green>ON" or "<indian_red>OFF")
    .. "<reset>  (maran <cyan>" .. tostring(cfg.maranAt) .. "%<reset>, seasone <cyan>"
    .. tostring(cfg.seasoneAt) .. "%<reset>, matic <cyan>" .. tostring(cfg.maticAt) .. "<reset> denizens)")
  local class = className()
  local ex = class and CARD_EXPLOIT[class]
  for _, card in ipairs(MNEM_CARDS) do
    local note = ""
    if card.aff then
      note = ex and ex[card.aff]
        and (" -- " .. card.aff .. ", " .. ex[card.aff].rage .. " rage"
             .. ((not ex[card.aff].ready or ex[card.aff].ready()) and "" or " <grey>(payoff on cooldown)<reset>"))
        or (" -- <grey>no " .. card.aff .. " payoff as " .. tostring(class) .. "<reset>")
    end
    out("  <white>" .. card.key .. "<reset>: <cyan>" .. charges(card.key)
      .. "<reset> charge(s), every " .. card.gap .. "s" .. note)
  end
end
