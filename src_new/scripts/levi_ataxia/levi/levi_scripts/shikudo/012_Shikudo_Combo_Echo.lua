--[[mudlet
type: script
name: Shikudo Combo Echo
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Shikudo Script - Levi
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- THE [SK] SUMMARY LINE (v4.7.456). The user, after a group fight (2026-10-27, log ZQfua3XR): "I
-- would love to highlight or echo our attacks so I can actually see if we are hitting someone." In
-- that log our strike lines were lost among ~400 [LOCK] lines, eight party says per combo, other
-- players' attacks, and affliction tags printed on the wrong rows. So each combo now ends with ONE
-- line of our own:
--
--   [SK] Sadey  HIT 3/3  LA+9.2 LL+9.2 H+9.4  prone dizziness confusion  Rain:3
--   [SK] Akri  MISS 0/3 (reflection 3)  Oak:12
--   [SK] FAILED: no staff (staff489282)
--   [SK] KAI CHOKE -> Crixos
--
-- HOW A COMBO IS READ. The strike ledger (010) already follows each strike from its strike line to
-- the line that settles it, and this file listens to it:
--   * shikudoLedger.strike (587) opens a record if none is open, and counts the strike.
--   * shikudoLedger.expire hands over each strike as it ends: settled by a damage, effect or arm
--     line = a HIT; dropped by a parry, fumble, shield rebound or reflection = a MISS with its
--     reason; neither = unknown ("?"), which the line shows, as the ledger counts it.
--   * The damage line (789 -> shikudoLedger.outcome) gives the limb and the percentage.
--   * The "tar afflicted" event gives what landed on our target while the record is open.
--   * Our reflection lines (triggers 797, 798) drop the strike in flight as "reflection".
--   * The kata line (164) closes the record and gives the chain; the prompt (318) closes it when no
--     kata line came (a refused combo, a parried one).
--
-- While a record is open, tarGained (017) does not print its inline [AFF] tag: the summary lists
-- them, and the inline tags were landing one row off (deleted strike rows, shared cursor). The
-- strike lines themselves are no longer gagged in PvP while this echo is on (gags/001).
--
-- `skecho on|off` (alias shikudo/008). Saved as ataxia.settings.shikudoEcho; default on.

shikudoEcho = shikudoEcho or {}
shikudoEcho.rec = nil -- the open record; a reload drops it

local LIMB_SHORT = {
  head = "H", torso = "T", ["left arm"] = "LA", ["right arm"] = "RA",
  ["left leg"] = "LL", ["right leg"] = "RL",
}

function shikudoEcho.enabled()
  local s = ataxia and ataxia.settings and ataxia.settings.shikudoEcho
  return s ~= false
end

-- Echoes stay ASCII; a name never opens a cecho tag.
local function ascii(s)
  return (tostring(s or ""):gsub("[^\32-\126]", "?"):gsub("[<>]", ""))
end

local function now() return (getEpoch and getEpoch()) or 0 end

local function open()
  if shikudoEcho.rec then return shikudoEcho.rec end
  shikudoEcho.rec = {
    at = now(), target = type(target) == "string" and target or tostring(target),
    strikes = 0, hits = 0, misses = {}, unknown = 0, damage = {}, affs = {}, affSeen = {},
  }
  return shikudoEcho.rec
end

-- Is a record open? tarGained (017) asks, to leave out its inline tag.
function shikudoEcho.recording()
  return shikudoEcho.enabled() and shikudoEcho.rec ~= nil
end

-- shikudoLedger.strike: a strike line (row 1).
function shikudoEcho.onStrike()
  if not shikudoEcho.enabled() then return end
  local r = open()
  r.strikes = r.strikes + 1
end

-- shikudoLedger.expire: the strike that just ended.
function shikudoEcho.onStrikeEnd(cur)
  local r = shikudoEcho.rec
  if not r or type(cur) ~= "table" then return end
  if cur.dropped then
    r.misses[cur.dropped] = (r.misses[cur.dropped] or 0) + 1
  elseif cur.outcome then
    r.hits = r.hits + 1
  else
    r.unknown = r.unknown + 1
  end
end

-- The damage line, from shikudoLedger.outcome:
--   As your blow lands with a crunch, you perceive that you have dealt 9.2% damage to Sadey's left arm.
function shikudoEcho.onDamage(text)
  local r = shikudoEcho.rec
  if not r then return end
  local amount, limb = tostring(text or ""):match("dealt ([%d%.]+)%% damage to .-'s? (%a+ ?%a*)%.")
  if not amount then return end
  limb = limb:lower()
  r.damage[#r.damage + 1] = (LIMB_SHORT[limb] or limb) .. "+" .. amount
end

-- Our reflection lines (797 "The attack harmlessly passes through one of X's reflections.", 798 "A
-- reflection of X blinks out of existence."): the strike in flight hit an image, not the target.
-- Another player's strike prints the same words, so only a line inside our open record, about our
-- target, counts.
function shikudoEcho.onReflection(who)
  local r = shikudoEcho.rec
  if not r or type(who) ~= "string" or not (isTargeted and isTargeted(who)) then return end
  local cur = shikudoLedger and shikudoLedger.cur
  if cur and not cur.dropped and not cur.outcome then
    cur.dropped, cur.outcome = "reflection", "reflection"
  elseif not cur then
    -- The strike's own row was not read (a wrapped or gagged line): still a strike that missed.
    r.strikes = r.strikes + 1
    r.misses.reflection = (r.misses.reflection or 0) + 1
  end
end

-- "tar afflicted": what landed on our target while the record is open.
function shikudoEcho.onAfflicted(_, list)
  local r = shikudoEcho.rec
  if not r or type(list) ~= "table" then return end
  for _, aff in ipairs(list) do
    if type(aff) == "string" and not r.affSeen[aff] then
      r.affSeen[aff] = true
      r.affs[#r.affs + 1] = aff
    end
  end
end

-- A round that never struck: no staff, target dead or gone. Printed at once, red.
function shikudoEcho.failed(why)
  if not shikudoEcho.enabled() then return end
  shikudoEcho.rec = nil
  cecho("\n<red>[SK] FAILED: " .. ascii(why))
end

-- An equilibrium action: KAI CHOKE, MIND CRUSH, a MIND affliction. One line each.
function shikudoEcho.action(what, who, landed)
  if not shikudoEcho.enabled() then return end
  cecho("\n" .. (landed == false and "<yellow>" or "<chartreuse>") .. "[SK] " .. ascii(what)
    .. " -> " .. ascii(who or target))
end

-- The line itself: chartreuse when every strike hit, yellow for some, red for none.
function shikudoEcho.render(r, kata)
  local missN, missWhy = 0, {}
  for why, n in pairs(r.misses) do
    missN = missN + n
    missWhy[#missWhy + 1] = why .. " " .. n
  end
  table.sort(missWhy)
  local total = r.hits + missN + r.unknown
  if total < r.strikes then total = r.strikes end
  local colour = (r.hits > 0 and r.hits >= total and "<chartreuse>")
    or (r.hits > 0 and "<yellow>") or "<red>"
  local word = (r.hits == 0) and "MISS" or "HIT"
  local parts = { "[SK] " .. ascii(r.target), word .. " " .. r.hits .. "/" .. total }
  if #missWhy > 0 then parts[#parts + 1] = "(" .. table.concat(missWhy, ", ") .. ")" end
  if r.unknown > 0 then parts[#parts + 1] = "(" .. r.unknown .. " unseen)" end
  if #r.damage > 0 then parts[#parts + 1] = table.concat(r.damage, " ") end
  if #r.affs > 0 then parts[#parts + 1] = table.concat(r.affs, " ") end
  local form = ataxia and ataxia.vitals and ataxia.vitals.form
  if form or kata then
    parts[#parts + 1] = tostring(form or "?") .. ":" .. tostring(kata or (ataxia.vitals.kata or "?"))
  end
  return colour .. ascii(table.concat(parts, "  "))
end

-- 164 (the kata line, with its count) or 318 (the prompt): the combo is over.
function shikudoEcho.close(kata)
  local r = shikudoEcho.rec
  if not r then return end
  -- The last strike is still in the ledger until the next strike or the prompt: end it here.
  if shikudoLedger and shikudoLedger.cur then shikudoLedger.expire("combo end") end
  shikudoEcho.rec = nil
  if r.strikes == 0 and r.hits == 0 then return end
  cecho("\n" .. shikudoEcho.render(r, kata))
end

-- `skecho on|off`.
function shikudoEcho.command(arg)
  ataxia.settings = ataxia.settings or {}
  if arg == "on" then
    ataxia.settings.shikudoEcho = true
  elseif arg == "off" then
    ataxia.settings.shikudoEcho = false
  end
  if arg == "on" or arg == "off" then
    if ataxia_saveSettings then ataxia_saveSettings(false) end
  end
  if ataxiaEcho then
    ataxiaEcho("Shikudo [SK] combo line: " .. (shikudoEcho.enabled() and "<green>ON" or "<red>OFF")
      .. "<reset>. Change it: skecho on | skecho off")
  end
end

-- Reload-safe registration.
if shikudoEcho.afflictedHandler and killAnonymousEventHandler then
  pcall(killAnonymousEventHandler, shikudoEcho.afflictedHandler)
end
if registerAnonymousEventHandler then
  shikudoEcho.afflictedHandler = registerAnonymousEventHandler("tar afflicted",
    function(event, list) shikudoEcho.onAfflicted(event, list) end)
end
