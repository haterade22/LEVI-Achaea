--[[mudlet
type: script
name: Two Hand Raze
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    TWO HANDED SHIELD BREAK: CARVE WITH A BASTARD SWORD, SPLINTER WITH A WARHAMMER (v4.7.452)

    User: "When in 2 handed, if I am wielding a bastard sword it should carve, warhammer splinter."
    The game's refusal, pasted with it:

        You must be wielding a warhammer to splinter an opponent's defences.

    Both are Weaponmastery, so all four knights have both (kb/classes/<knight>.md: CARVE needs a
    Bastard Sword, SPLINTER a Warhammer). Until now the Infernal basher always sent SPLINTER and the
    Paladin, Runewarden and Unnamable bashers always sent CARVE, whatever was in hand.

    THE WEAPON IS READ FROM GMCP. Inventory items carry `attrib`; an `l` or `L` in it means
    wielded. `Char.Items.List` (location "inv") replaces the picture, `Char.Items.Update`, `Add` and
    `Remove` change one item. A wielded name with "warhammer" means SPLINTER; one with "bastard"
    means CARVE. With no inventory seen yet, one `Char.Items.Inv` request is sent.

    THE REFUSAL TEACHES TOO (trigger 790). If SPLINTER is refused, we hold no warhammer: the belief
    becomes "bastard sword" and the round is re-sent, so the stale raze is replaced by CARVE at once.
    The carve refusal line is not captured; GMCP covers that direction.

    Unknown weapon: each class keeps its old default (`fallback`), so nothing changes for a
    character the package cannot read.

    ARC AND BISECT NEED THE SWORD (v4.7.455, user: "we need to use bastard for bisect and arc and
    not hammer"). ARC swings a sword and BISECT needs an edged runeblade, so a warhammer in hand
    gets both refused. `ataxiaBasher_twoHandWield("bastard", sp)` puts `wield bastard` in front of
    them (Runewarden and Infernal, Two Handed only); nothing is sent when GMCP shows it in hand.

    NORMAL ROUNDS USE THE WEAPON WITH THE HIGHER MEASURED DPS (user: "Hammer is faster but I think
    sword does more damage. Maybe code something in to check the dps of each"). Every damage line
    of a normal round (slaughter, plus the battlerage and pet hits that ride it) goes into a ledger
    under the weapon in hand, timed with the same gap rule as `bashStats_recordDamage`. Until each
    weapon has TWOHAND_MIN_SECS of fighting, the round wields the one with less time; then the one
    with more damage per second, and it changes only for a lead above TWOHAND_MARGIN.
    `bash twohand` shows it, pins a weapon or resets the ledger. The ledger is SAVED (it lives on
    `ataxiaBasher`) and is one figure for all denizens.
]]--

ataxiaTemp = ataxiaTemp or {}

local function isWielded(item)
  local a = type(item) == "table" and item.attrib
  return type(a) == "string" and (a:find("l", 1, true) or a:find("L", 1, true)) ~= nil
end

-- "warhammer" / "bastard" / nil for one item name. Any HAMMER is the warhammer and any SWORD the
-- bastard sword (v4.7.461): an artefact keeps its own name, and "a Hellforge Hammer" was read as
-- unknown, so a Runewarden sent its default CARVE with it in hand and was refused every round.
local function weaponKind(name)
  if type(name) ~= "string" then return nil end
  local n = name:lower()
  if n:find("hammer", 1, true) then return "warhammer" end
  if n:find("bastard", 1, true) or n:find("sword", 1, true) then return "bastard" end
  return nil
end

-- The wielded two-hander, from the items we know are wielded.
function ataxiaBasher_twoHandWeapon()
  local wielded = ataxiaTemp.wieldedItems
  if type(wielded) == "table" then
    for _, name in pairs(wielded) do
      local k = weaponKind(name)
      if k then return k end
    end
  end
  return ataxiaTemp.twoHandLearned
end

-- The shield-break command for a Two Handed knight. `fallback` is the class's old verb.
function ataxiaBasher_twoHandRaze(tgt, fallback)
  local kind = ataxiaBasher_twoHandWeapon()
  if not kind and not ataxiaTemp.wieldInvAsked and sendGMCP then
    ataxiaTemp.wieldInvAsked = true
    pcall(sendGMCP, "Char.Items.Inv")
  end
  local verb = (kind == "warhammer" and "splinter") or (kind == "bastard" and "carve") or fallback
  return verb .. " " .. tostring(tgt)
end

-- `wield <word><sp>` when `want` ("bastard" / "warhammer") is not the weapon GMCP shows in hand
-- (an unknown hand counts as not), else "". A repeat wield of the held weapon is harmless.
function ataxiaBasher_twoHandWield(want, sp)
  if ataxiaBasher_twoHandWeapon() == want then return "" end
  local ab = ataxiaBasher or {}
  -- The item ID from the inventory when we know it: a keyword may not fit an artefact's name
  -- ("wield warhammer" for "a Hellforge Hammer"). A word set by the user wins.
  ataxiaTemp.twoHandIds = ataxiaTemp.twoHandIds or {}
  local ids = ataxiaTemp.twoHandIds
  -- The weapon in hand now goes back in by its ID after the swap (v4.7.463: the user's ledger
  -- held "Apocalypse" as wielded, with no ID learned, because no inventory list came after a reload).
  for id, name in pairs(ataxiaTemp.wieldedItems or {}) do
    local k = weaponKind(name)
    if k and not ids[k] then
      ids[k] = id
      ataxiaTemp.twoHandSeen = ataxiaTemp.twoHandSeen or {}
      ataxiaTemp.twoHandSeen[k] = id
    end
  end
  -- No ID for the weapon we want: ask GMCP for the inventory, at most every 30 s. This round
  -- uses the keyword; the next rounds use the ID.
  local nowT = (getEpoch and getEpoch()) or 0
  if not ids[want] and sendGMCP and nowT - (ataxiaTemp.twoHandInvAskAt or -1e9) >= 30 then
    ataxiaTemp.twoHandInvAskAt = nowT
    pcall(sendGMCP, "Char.Items.Inv")
  end
  local word = (want == "bastard" and (ab.twoHandSwordWord or ids.bastard or "bastard"))
    or (ab.twoHandHammerWord or ids.warhammer or "warhammer")
  return "wield " .. word .. (sp or "")
end

TWOHAND_MIN_SECS = TWOHAND_MIN_SECS or 120 -- fighting seconds per weapon before DPS decides
TWOHAND_MARGIN = TWOHAND_MARGIN or 0.03    -- the other weapon must lead by more than this

local function ledger(kind)
  ataxiaBasher.twoHandDps = ataxiaBasher.twoHandDps or {}
  local l = ataxiaBasher.twoHandDps[kind]
  -- v = 2: `dmg`/`hits` are NON-CRIT only (v4.7.457). A v4.7.455 ledger counted crits in `dmg`,
  -- so it starts again rather than mixing the two.
  if type(l) ~= "table" or l.v ~= 2 then
    l = { v = 2, dmg = 0, secs = 0, hits = 0, crits = 0 }
    ataxiaBasher.twoHandDps[kind] = l
  end
  return l
end

-- CRITS ARE TAKEN OUT (v4.7.457, user: "You have to account for criticals, basically removing them
-- as it will be inconsistent"). A crit multiplies one hit by 2x to 64x, so a few of them decide
-- the comparison. But a crit hit is not set to zero: the faster weapon swings more often and so
-- crits more often per second, and zeroing those hits would count against it. Each crit counts
-- as one AVERAGE NON-CRIT hit of the same weapon: DPS = (dmg / hits) * (hits + crits) / secs.
local function dps(l)
  local s, h = tonumber(l.secs) or 0, tonumber(l.hits) or 0
  if s <= 0 or h <= 0 then return 0 end
  return ((tonumber(l.dmg) or 0) / h) * (h + (tonumber(l.crits) or 0)) / s
end

-- The weapon for a NORMAL (single-target) round.
function ataxiaBasher_twoHandPick()
  local mode = ataxiaBasher and ataxiaBasher.twoHandMode
  if mode == "warhammer" or mode == "bastard" then return mode end
  local h, b = ledger("warhammer"), ledger("bastard")
  if h.secs < TWOHAND_MIN_SECS or b.secs < TWOHAND_MIN_SECS then
    if h.secs == b.secs then return ataxiaBasher_twoHandWeapon() or "warhammer" end
    return (h.secs < b.secs) and "warhammer" or "bastard"
  end
  local held = ataxiaBasher_twoHandWeapon()
  local hd, bd = dps(h), dps(b)
  if held == "warhammer" and bd <= hd * (1 + TWOHAND_MARGIN) then return "warhammer" end
  if held == "bastard" and hd <= bd * (1 + TWOHAND_MARGIN) then return "bastard" end
  return (bd > hd) and "bastard" or "warhammer"
end

-- Called from bashStats_recordDamage for every hit we deal. Counts only normal rounds
-- (`ataxiaTemp.twoHandRound == "single"`, set by the class round builders), in PvE, with a known
-- weapon. A gap is fighting time only when it is short AND the weapon did not change across it.
function ataxiaBasher_twoHandRecord(amount)
  amount = tonumber(amount) or 0
  if amount <= 0 or ataxiaTemp.twoHandRound ~= "single" then return end
  if type(target) ~= "number" or not (ataxiaBasher and ataxiaBasher.enabled) then return end
  local kind = ataxiaBasher_twoHandWeapon()
  if not kind then
    ataxiaBasher_twoHandUnseen()
    return
  end
  local nowT = (getEpoch and getEpoch()) or 0
  local l = ledger(kind)
  local before = l.secs
  local prevAt, prevKind = ataxiaTemp.twoHandLastAt, ataxiaTemp.twoHandLastKind
  if prevAt and prevKind == kind then
    local gap = nowT - prevAt
    if gap > 0 and gap <= (bashStats_COMBAT_GAP or 10) then l.secs = l.secs + gap end
  end
  ataxiaTemp.twoHandLastAt, ataxiaTemp.twoHandLastKind = nowT, kind
  -- trigger 334 sets the flag on the crit line; 350 clears it after this damage line.
  if bashStats and bashStats.lastHitWasCrit then
    l.crits = (tonumber(l.crits) or 0) + 1
  else
    l.dmg = l.dmg + amount
    l.hits = l.hits + 1
  end
  ataxiaBasher_twoHandProgress(kind, before, l)
end

-- WHAT THE PLAYER SEES (v4.7.460, user: "bash twohand auto doesnt echo or anything for the player
-- to understand it is working"). The ledger and the pick were silent. Three kinds of line now:
--   * sampling progress, at each 30 s of a weapon's fighting time, and when its sample is done;
--   * the weapon a round wields and why, only when the weapon or the reason changes
--     (`ataxiaBasher_twoHandSay`, called by the Infernal and Runewarden round builders);
--   * once a minute, that GMCP does not show the weapon in hand, so nothing is measured.
local SAMPLE_STEP = 30

local function say(text)
  if ataxiaEcho then ataxiaEcho("<gold>(2H)<reset> " .. text) end
end

function ataxiaBasher_twoHandProgress(kind, before, l)
  local min = TWOHAND_MIN_SECS
  if before >= min then return end
  if l.secs >= min then
    say(string.format("<white>%s<reset> sampled: <white>%.0f<reset> dps over %.0fs (%d hits, %d crits).",
      kind, dps(l), l.secs, l.hits, tonumber(l.crits) or 0))
    local other = ledger(kind == "warhammer" and "bastard" or "warhammer")
    if other.secs >= min then
      say("Both weapons sampled. Normal rounds now use <white>" .. ataxiaBasher_twoHandPick()
        .. "<reset>. (bash twohand)")
    end
  elseif math.floor(l.secs / SAMPLE_STEP) > math.floor(before / SAMPLE_STEP) then
    say(string.format("sampling <white>%s<reset>: %.0f/%ds, %.0f dps so far.", kind, l.secs, min, dps(l)))
  end
end

-- Why normal rounds use `pick`: "pinned", "sampling" or "dps", with the text for the echo.
local function why(pick)
  local mode = ataxiaBasher and ataxiaBasher.twoHandMode
  if mode == "warhammer" or mode == "bastard" then return "pinned", "pinned by bash twohand " .. mode end
  local h, b = ledger("warhammer"), ledger("bastard")
  if h.secs < TWOHAND_MIN_SECS or b.secs < TWOHAND_MIN_SECS then
    local l = ledger(pick)
    return "sampling", string.format("sampling, %.0f/%ds", l.secs, TWOHAND_MIN_SECS)
  end
  return "dps", string.format("higher DPS: warhammer %.0f, bastard %.0f", dps(h), dps(b))
end

-- `round` is "normal" (the pick), "arc" or "bisect" (the bastard sword). Echoes on a change only.
function ataxiaBasher_twoHandSay(round)
  local want, reason, text
  if round == "normal" then
    want = ataxiaBasher_twoHandPick()
    reason, text = why(want)
  else
    want, reason, text = "bastard", round, round .. " needs the sword"
  end
  local key = want .. "|" .. reason
  if ataxiaTemp.twoHandSaid == key then return end
  ataxiaTemp.twoHandSaid = key
  local held = ataxiaBasher_twoHandWeapon()
  say(string.format("%s rounds: <white>%s<reset> (%s)%s", (round == "normal") and "Normal" or round,
    want, text, (held and held ~= want) and (", wielding it now") or ""))
end

-- Called when a normal round is recorded nothing because GMCP shows no two-hander in hand.
function ataxiaBasher_twoHandUnseen()
  local nowT = (getEpoch and getEpoch()) or 0
  if nowT - (ataxiaTemp.twoHandUnseenAt or -1e9) < 60 then return end
  ataxiaTemp.twoHandUnseenAt = nowT
  say("No warhammer or bastard sword shows as wielded in GMCP, so DPS is not measured. "
    .. "Wield one, or check: ii warhammer / ii bastard.")
end

function ataxiaBasher_twoHandReset()
  ataxiaBasher.twoHandDps = {}
  ataxiaTemp.twoHandLastAt, ataxiaTemp.twoHandLastKind = nil, nil
end

-- Lines for `bash twohand`. With no weapon known, it asks GMCP for the inventory (the user's
-- screenshot read "in hand unknown").
function ataxiaBasher_twoHandReport()
  local out = {}
  if not ataxiaBasher_twoHandWeapon() and sendGMCP then
    pcall(sendGMCP, "Char.Items.Inv")
    out[#out + 1] = "weapon in hand unknown: asked GMCP for the inventory -- type bash twohand again"
  end
  for _, k in ipairs({ "warhammer", "bastard" }) do
    local l = ledger(k)
    out[#out + 1] = string.format("%-9s %8.0f dps  %6.0fs  %5d hits  %4d crits%s", k, dps(l), l.secs,
      l.hits, tonumber(l.crits) or 0,
      (l.secs < TWOHAND_MIN_SECS) and "  (sampling)" or "")
  end
  out[#out + 1] = string.format("mode %s, in hand %s, normal rounds use %s",
    tostring((ataxiaBasher and ataxiaBasher.twoHandMode) or "auto"),
    tostring(ataxiaBasher_twoHandWeapon() or "unknown"), ataxiaBasher_twoHandPick())
  return out
end

-- GMCP inventory feed: keep id -> name for wielded items, and the id of each kind of two-hander
-- we carry (`ataxiaTemp.twoHandIds`, for the wield command).
local function noteId(item)
  local k = type(item) == "table" and weaponKind(item.name)
  if not k then return end
  -- Any wielded sword is the two-hander, but a carried one may be a one-handed longsword: an
  -- unwielded sword counts only when its name says "bastard".
  if k == "bastard" and not isWielded(item) and not item.name:lower():find("bastard", 1, true) then
    return
  end
  ataxiaTemp.twoHandIds = ataxiaTemp.twoHandIds or {}
  ataxiaTemp.twoHandIds[k] = tostring(item.id)
  -- A sword seen WIELDED is the two-hander for good (user: "Apocalypse, a blackrock sword of
  -- black-hued steel"), so its ID outlives a new inventory list taken with the hammer in hand.
  if isWielded(item) then
    ataxiaTemp.twoHandSeen = ataxiaTemp.twoHandSeen or {}
    ataxiaTemp.twoHandSeen[k] = tostring(item.id)
  end
end

-- After a full list: a sword with no "bastard" in its name and not in hand is found by the ID we
-- saw wielded, else it is the ONLY sword carried. Two unnamed swords stay unknown.
local function findSword(list)
  if ataxiaTemp.twoHandIds.bastard then return end
  local seen = ataxiaTemp.twoHandSeen and ataxiaTemp.twoHandSeen.bastard
  local only, count = nil, 0
  for _, it in ipairs(list) do
    if type(it) == "table" and weaponKind(it.name) == "bastard" then
      if seen and tostring(it.id) == seen then
        ataxiaTemp.twoHandIds.bastard = seen
        return
      end
      only, count = tostring(it.id), count + 1
    end
  end
  if count == 1 then ataxiaTemp.twoHandIds.bastard = only end
end

function ataxiaBasher_wieldItemsEvent(event)
  local items = gmcp and gmcp.Char and gmcp.Char.Items
  if not items then return end
  if event == "gmcp.Char.Items.List" then
    local l = items.List
    if type(l) ~= "table" or l.location ~= "inv" then return end
    ataxiaTemp.wieldedItems = {}
    ataxiaTemp.twoHandIds = {}
    for _, it in ipairs(l.items or {}) do
      if isWielded(it) then ataxiaTemp.wieldedItems[tostring(it.id)] = it.name end
      noteId(it)
    end
    findSword(l.items or {})
    ataxiaTemp.twoHandLearned = nil -- a fresh picture outranks a refusal's guess
    return
  end
  local key = (event == "gmcp.Char.Items.Update" and "Update")
    or (event == "gmcp.Char.Items.Add" and "Add")
    or (event == "gmcp.Char.Items.Remove" and "Remove")
  local m = key and items[key]
  if type(m) ~= "table" or m.location ~= "inv" or type(m.item) ~= "table" then return end
  ataxiaTemp.wieldedItems = ataxiaTemp.wieldedItems or {}
  local id = tostring(m.item.id)
  if key ~= "Remove" then noteId(m.item) end
  if key ~= "Remove" and isWielded(m.item) then
    ataxiaTemp.wieldedItems[id] = m.item.name
    ataxiaTemp.twoHandLearned = nil
  else
    ataxiaTemp.wieldedItems[id] = nil
  end
end

-- A refused shield break: we do not hold `wrong`, so we hold the other two-hander. Learn that and
-- re-send the round, so the refused raze is replaced at once.
local function razeRefused(wrong)
  ataxiaTemp.twoHandLearned = (wrong == "warhammer") and "bastard" or "warhammer"
  if ataxiaTemp.wieldedItems then
    for id, name in pairs(ataxiaTemp.wieldedItems) do
      if weaponKind(name) == wrong then ataxiaTemp.wieldedItems[id] = nil end
    end
  end
  if type(target) ~= "number" then return end           -- PvE only
  if not (ataxiaBasher and ataxiaBasher.enabled) or ataxiaBasher.paused then return end
  if ataxiaTemp.swarmHold then return end               -- a pull chain is queued; do not wipe it
  local nowT = (getEpoch and getEpoch()) or 0
  if ataxiaTemp.splinterRefusedAt and (nowT - ataxiaTemp.splinterRefusedAt) < 1 then return end
  ataxiaTemp.splinterRefusedAt = nowT
  if ataxiaBasher_attack then ataxiaBasher_attack() end
end

-- Trigger 790: "You must be wielding a warhammer to splinter an opponent's defences."
function ataxiaBasher_splinterRefused() razeRefused("warhammer") end

-- Trigger 799 (v4.7.461): "You must be wielding a two handed sword to carve through an opponent's
-- defences." The user's log: a Runewarden with "a Hellforge Hammer" sent CARVE three times in a
-- second, and nothing learned from the refusal.
function ataxiaBasher_carveRefused() razeRefused("bastard") end

-- Reload-safe registration: kill the previous ids first so a SYSUPDATE cannot stack handlers.
ataxiaTemp.wieldHandlers = ataxiaTemp.wieldHandlers or {}
for _, id in ipairs(ataxiaTemp.wieldHandlers) do
  if killAnonymousEventHandler then pcall(killAnonymousEventHandler, id) end
end
ataxiaTemp.wieldHandlers = {}
for _, ev in ipairs({ "gmcp.Char.Items.List", "gmcp.Char.Items.Update",
                      "gmcp.Char.Items.Add", "gmcp.Char.Items.Remove" }) do
  ataxiaTemp.wieldHandlers[#ataxiaTemp.wieldHandlers + 1] = registerAnonymousEventHandler(ev,
    function(event) if ataxiaBasher_wieldItemsEvent then ataxiaBasher_wieldItemsEvent(event) end end)
end
