--[[mudlet
type: script
name: Boon Advisor
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    WHICH BOON SHOULD I TAKE?  (v4.7.327, `mnem advise`)
    ============================================================================

    User: "After it boon contemplates the boon selection, it should give us a summary of the
    options and information it collected. I would even want it to start recommending some boons
    ... and maybe develop an auto picker." Then: "Defensive boons are a priority. To survive
    more" -- "It depends on the boons we have" -- "Each class will be different."

    So, once the offer screen's boons have been contemplated, one block: every option with its
    category, rarity, combo/echo status, what it actually does in short, and anything WRONG with
    it (already immune, conflicts with a boon we hold, inert without a spirit, a drawback) -- then
    a RECOMMEND line with the reason, and a reroll hint when every option is weak and one is left.

    THE SCORE IS A SUM OF NAMED PARTS, and every part is printed as a reason. A number nobody can
    explain cannot be tuned, and "each class will be different" means it WILL be tuned. The
    weights live in `M.BOON_WEIGHTS` (the defence-first default) with per-class overrides in
    `M.BOON_CLASS_WEIGHTS`, keyed by the GMCP class in lower case. Only the default is filled in:
    class numbers should come from play, not from a guess written here.

    RELATIVE TO WHAT WE HOLD. A resistance counts for less where we already resist that type, an
    immunity we already have counts for nothing, and a category we are short of this run gets a
    bonus -- so the same offer can be read differently at ripple 2 and ripple 12.

    It never claims. An auto-picker is a separate, opt-in step once these recommendations have
    earned trust.
]]--

local M = ataxia.mnemosyne

-- The defence-first default. Each number is "points per unit" of one fact the parsers can read.
M.BOON_WEIGHTS = {
  category = { defence = 30, offence = 15, utility = 12 }, -- the user's "defensive boons are a priority"
  categoryUnknown = 10,     -- never contemplated: we cannot tell
  rarity = { common = 0, uncommon = 3, rare = 6, epic = 8, legendary = 10, mythical = 12 },
  resistPerPct = 1.0,       -- +10% fire resistance = 10 points...
  resistSaturated = 0.4,    -- ...but only 40% of that where we already resist the type
  resistSaturatedAt = 30,   -- "already resist" means this much or more
  resistAllPerPct = 3.0,    -- resistance to ALL damage covers every type
  weaknessPerPct = 1.5,     -- a weakness costs more than the same resistance earns
  immunityNew = 8,          -- per affliction we are not already immune to
  immunityAllRedundant = -20, -- an immunity boon that grants only what we already have
  constitutionPerPoint = 5, -- health is survival
  statPerPoint = 2,
  damagePerPct = 0.8,       -- always-on generic damage
  damageConditionalPerPct = 0.3,
  damageTypePerPct = 0.3,   -- one damage type only
  procPerPct = 2,           -- 5% on-hit affliction = 10
  drawback = -12,           -- per parsed cost
  conflictsHeld = -100,     -- cannot be taken alongside a boon we hold
  inert = -60,              -- needs a spirit we are not attuned to
  combo = 3,
  echoHeld = 5,             -- an (ECHO) offer strengthens a boon we already hold
  categoryShort = 10,       -- a category we hold fewer of than the others this run
  restoration = 8,          -- "Restore your resources instead."
  restorationLowHealth = 40, -- ...worth more than a permanent boon when we are hurt
  restorationLowAt = 50,    -- health percent
  rerollBelow = 20,         -- suggest a reroll when the best option scores under this
}

-- Per class, only what DIFFERS from the default (merged over it). Empty until play says otherwise;
-- e.g. `M.BOON_CLASS_WEIGHTS.bard = { category = { offence = 20 } }`.
M.BOON_CLASS_WEIGHTS = M.BOON_CLASS_WEIGHTS or {}

local function merged(base, over)
  local out = {}
  for k, v in pairs(base) do
    out[k] = (type(v) == "table" and type(over and over[k]) == "table") and merged(v, over[k])
      or (over and over[k] ~= nil and over[k]) or v
  end
  return out
end

function M.boonClass()
  local c = gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class
  return type(c) == "string" and c:lower() or nil
end

function M.boonWeights(class)
  class = class or M.boonClass()
  return merged(M.BOON_WEIGHTS, class and M.BOON_CLASS_WEIGHTS[class] or nil), class
end

-- The wording to judge an offer by: an (ECHO) offer is its seed's echo text when we have it.
local function descFor(name, isEcho)
  if isEcho then
    local seed = M.BOON_SEED and M.BOON_SEED[name]
    if seed and type(seed.echo) == "string" and seed.echo ~= "" then return seed.echo end
  end
  local rec = M.boonInfo and M.boonInfo(name)
  if type(rec) == "table" and type(rec.description) == "string" and rec.description ~= "" then
    return rec.description
  end
  local seed = M.BOON_SEED and M.BOON_SEED[name]
  return seed and seed.description or nil
end

local function healthPct()
  local v = gmcp and gmcp.Char and gmcp.Char.Vitals
  local hp, max = tonumber(v and v.hp), tonumber(v and v.maxhp)
  if hp and max and max > 0 then return hp / max * 100 end
  return nil
end

-- What this run already gives us, read once per offer.
function M._advisorContext()
  local ctx = { held = (M._heldBoons and M._heldBoons()) or {}, cats = {} }
  local totals = (M.bonusTotals and M.bonusTotals()) or {}
  ctx.resists = totals.resists or {}
  ctx.immune = totals.immune or (M.runImmunities and M.runImmunities()) or {}
  for name in pairs(ctx.held) do
    local rec = M.boonInfo and M.boonInfo(name)
    local c = type(rec) == "table" and type(rec.category) == "string" and rec.category:lower() or nil
    if c then ctx.cats[c] = (ctx.cats[c] or 0) + 1 end
  end
  ctx.hp = healthPct()
  return ctx
end

-- Is `cat` the category we hold fewest of (and are we short of it at all)?
local function isShort(ctx, cat)
  if not cat then return false end
  local mine, most = ctx.cats[cat] or 0, 0
  for _, c in ipairs({ "defence", "offence", "utility" }) do most = math.max(most, ctx.cats[c] or 0) end
  return mine < most
end

local function add(r, pts, why)
  pts = math.floor(pts + 0.5)
  if pts == 0 then return end
  r.score = r.score + pts
  r.parts[#r.parts + 1] = { pts = pts, why = why }
end

-- One offered boon, scored against what we hold. Returns
-- { name, echo, rec, category, score, parts = {{pts, why}}, effects = {...}, flags = {...} }.
function M.scoreBoon(offerName, ctx, W)
  W = W or M.boonWeights()
  ctx = ctx or M._advisorContext()
  local isEcho = type(offerName) == "string" and offerName:find("^%(ECHO%)") ~= nil
  local name = M._baseBoonName and M._baseBoonName(offerName) or offerName
  local rec = (M.boonInfo and M.boonInfo(name)) or {}
  local cat = type(rec.category) == "string" and rec.category:lower() or nil
  local r = { name = name, echo = isEcho, rec = rec, category = cat, score = 0, parts = {},
              effects = {}, flags = {} }
  local desc = descFor(name, isEcho)

  if name == "Restoration" then
    add(r, W.restoration, "restores resources")
    if ctx.hp and ctx.hp < W.restorationLowAt then
      add(r, W.restorationLowHealth, "you are at " .. math.floor(ctx.hp) .. "% health")
    end
    r.effects[#r.effects + 1] = "restores your resources"
    return r
  end

  if cat then add(r, W.category[cat] or W.categoryUnknown, rec.category)
  else add(r, W.categoryUnknown, "category unknown") end
  if cat and isShort(ctx, cat) then add(r, W.categoryShort, "you hold fewer " .. rec.category .. " boons") end
  local rar = type(rec.rarity) == "string" and rec.rarity:lower() or nil
  if rar and W.rarity[rar] then add(r, W.rarity[rar], rar) end
  if rec.comboBoon == true then add(r, W.combo, "combo") end
  if isEcho and ctx.held[name] then add(r, W.echoHeld, "strengthens a boon you hold") end

  if not desc then
    r.flags[#r.flags + 1] = "not in the catalogue"
    return r
  end

  -- Resistances, relative to what we already resist.
  local all = desc:match("(%d+)%%%s+resistance to all")
  if all then
    add(r, tonumber(all) * W.resistAllPerPct, "+" .. all .. "% resistance to all damage")
    r.effects[#r.effects + 1] = "+" .. all .. "% all resistance"
  else
    for t, v in pairs((M._resistFrom and M._resistFrom(desc)) or {}) do
      if v > 0 then
        local have = ctx.resists[t] or 0
        local per = have >= W.resistSaturatedAt and W.resistPerPct * W.resistSaturated or W.resistPerPct
        add(r, v * per, "+" .. v .. "% " .. t .. " resistance" .. (have >= W.resistSaturatedAt
          and (" (you have " .. have .. "%)") or ""))
        r.effects[#r.effects + 1] = "+" .. v .. "% " .. t .. " resist"
      else
        add(r, v * W.weaknessPerPct, v .. "% " .. t .. " weakness")
        r.effects[#r.effects + 1] = v .. "% " .. t .. " resist"
      end
    end
  end

  -- Immunities: only the new ones count.
  local grants = (M._immunitiesFrom and M._immunitiesFrom(desc)) or {}
  if #grants > 0 then
    local fresh, dup = {}, {}
    for _, a in ipairs(grants) do
      if ctx.immune[a] then dup[#dup + 1] = a else fresh[#fresh + 1] = a end
    end
    if #fresh > 0 then
      add(r, #fresh * W.immunityNew, "immune to " .. table.concat(fresh, ", "))
      r.effects[#r.effects + 1] = "immune: " .. table.concat(fresh, ", ")
    end
    if #dup > 0 then
      r.flags[#r.flags + 1] = "already immune to " .. table.concat(dup, ", ")
      if #fresh == 0 then add(r, W.immunityAllRedundant, "nothing new") end
    end
  end

  local st = (M._statFrom and M._statFrom(desc)) or {}
  for s, n in pairs(st) do
    if s == "Constitution" then add(r, n * W.constitutionPerPoint, "+" .. n .. " constitution")
    else add(r, n * W.statPerPoint, "+" .. n .. " " .. s:lower()) end
    r.effects[#r.effects + 1] = "+" .. n .. " " .. s:lower()
  end

  local g = M._dmgGenericFrom and M._dmgGenericFrom(desc)
  if g then
    if g.cond then
      add(r, g.pct * W.damageConditionalPerPct, "+" .. g.pct .. "% damage " .. g.cond)
      r.effects[#r.effects + 1] = "+" .. g.pct .. "% damage " .. g.cond
    else
      add(r, g.pct * W.damagePerPct, "+" .. g.pct .. "% damage")
      r.effects[#r.effects + 1] = "+" .. g.pct .. "% damage"
    end
  end
  for t, n in pairs((M._dmgBoostFrom and M._dmgBoostFrom(desc)) or {}) do
    add(r, n * W.damageTypePerPct, "+" .. n .. "% " .. t .. " damage")
    r.effects[#r.effects + 1] = "+" .. n .. "% " .. t .. " damage"
  end
  -- The bonuses parser reads only "Your attacks have a N% chance to afflict the target with X";
  -- the same proc also comes as "There is a 5% chance you give the denizen you are attacking
  -- amnesia" (Fae-Lapse, live 2026-09-19).
  local p = (M._procFrom and M._procFrom(desc)) or (function()
    local n, aff = desc:match("(%d+)%%%s+chance you give the denizen you are attacking%s+(%a+)")
    return n and { chance = tonumber(n), aff = aff:lower() } or nil
  end)()
  if p then
    add(r, p.chance * W.procPerPct, p.chance .. "% " .. p.aff .. " on hit")
    r.effects[#r.effects + 1] = p.chance .. "% " .. p.aff .. " on hit"
  end

  for _, c in ipairs((M._boonDrawbacks and M._boonDrawbacks(desc)) or {}) do
    add(r, W.drawback, "cost: " .. c)
    r.flags[#r.flags + 1] = "cost: " .. c
  end

  local cw = (M._conflictsFor and M._conflictsFor(name, ctx.held)) or {}
  for _, n in ipairs(cw) do
    if ctx.held[n] then
      add(r, W.conflictsHeld, "conflicts with " .. n)
      r.flags[#r.flags + 1] = "CONFLICTS with " .. n .. " (you have it)"
    end
  end

  local spirit = M._spiritGate and M._spiritGate(desc)
  if spirit and M._attuned and M._attuned(spirit) == false then
    add(r, W.inert, "inert without " .. spirit)
    r.flags[#r.flags + 1] = "inert: needs " .. spirit
  end

  -- Nothing parsed: say what it does in the game's own words, shortened.
  if #r.effects == 0 then
    local short = desc:gsub("%s+", " ")
    if #short > 90 then short = short:sub(1, 87) .. "..." end
    r.effects[#r.effects + 1] = short
  end
  return r
end

-- Every offered boon, best first (ties by name, so the order never flickers).
function M.rankOffer(list, ctx, W)
  W = W or M.boonWeights()
  ctx = ctx or M._advisorContext()
  local out, seen = {}, {}
  for _, b in ipairs(type(list) == "table" and list or {}) do
    local n = type(b) == "table" and b.name or b
    if type(n) == "string" and not seen[n] then
      seen[n] = true
      out[#out + 1] = M.scoreBoon(n, ctx, W)
    end
  end
  table.sort(out, function(a, b)
    if a.score ~= b.score then return a.score > b.score end
    return a.name < b.name
  end)
  return out
end

-- `BOON REROLL to discard these options and see new ones (1 remaining).` (trigger mnemosyne/094)
function M.onRerollsRemaining(n)
  M._rerollsLeft = tonumber(n)
end

local function reasons(r, k)
  local parts = {}
  for _, p in ipairs(r.parts) do parts[#parts + 1] = p end
  table.sort(parts, function(a, b) return math.abs(a.pts) > math.abs(b.pts) end)
  local out = {}
  for i = 1, math.min(k, #parts) do out[#out + 1] = parts[i].why end
  return table.concat(out, "; ")
end

-- The block printed once the offer's boons are contemplated (or at once, when no contemplate ran).
function M.offerSummary(list)
  local W, class = M.boonWeights()
  local ranked = M.rankOffer(list, M._advisorContext(), W)
  if #ranked == 0 then return nil end
  M.echo("<gold>Boon options<reset> <grey>-- defence first" .. (class and (", " .. class) or "")
    .. (class and M.BOON_CLASS_WEIGHTS[class] and " weights" or "") .. ":")
  for i, r in ipairs(ranked) do
    local tags = {}
    if r.rec.category then tags[#tags + 1] = "<white>" .. r.rec.category end
    if r.rec.rarity then tags[#tags + 1] = "<" .. M.rarityColour(r.rec.rarity) .. ">" .. r.rec.rarity end
    if r.rec.comboBoon == true then tags[#tags + 1] = "<pale_green>combo" end
    local maxE = tonumber(r.rec.maxEchoes)
    if maxE and maxE > 0 then
      tags[#tags + 1] = "<cyan>echo" .. ((r.rec.echoFloor == true and maxE == 1) and "" or (" x" .. maxE))
    end
    if r.echo then tags[#tags + 1] = "<cyan>(ECHO)" end
    cecho("\n  <grey>" .. i .. ". <gold>" .. r.name .. "<reset>  " .. table.concat(tags, " ")
      .. "  <grey>score <white>" .. r.score .. "<reset>")
    cecho("\n      <grey>" .. table.concat(r.effects, ", ") .. "<reset>")
    if #r.flags > 0 then
      cecho("\n      <indian_red>" .. table.concat(r.flags, "; ") .. "<reset>")
    end
  end
  local best, second = ranked[1], ranked[2]
  local margin = second and (best.score - second.score) or best.score
  M.echo("<green>RECOMMEND<reset> <gold>" .. best.name .. "<reset> -- " .. reasons(best, 3)
    .. (second and ("<grey> (ahead of " .. second.name .. " by " .. margin .. ")") or "") .. "<reset>.")
  if best.score < W.rerollBelow and (M._rerollsLeft or 0) > 0 then
    M.echo("<yellow>Every option is weak<reset> -- consider <white>BOON REROLL<reset> ("
      .. M._rerollsLeft .. " left).")
  end
  M._lastAdvice = { list = list, ranked = ranked, at = os.time() }
  return ranked
end
