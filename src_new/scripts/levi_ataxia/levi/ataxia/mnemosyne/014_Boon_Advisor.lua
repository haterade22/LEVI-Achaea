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
  -- DAMAGE THAT SCALES WITH A STAT (v4.7.362, user: "Mental Prowess ... score 38, +4% damage. These
  -- should be weighted high. There is also another one called brute force and another one based on
  -- dex. This is free damage based on your str, int or dex stat."). The generic parser reads only
  -- the one percentage in the sentence (0.8 a point -> 3), but the bonus multiplies by a stat we
  -- already have, so it is always-on damage many times that size. A flat, high bonus on top.
  statScalingDamage = 40,
  -- A COST IS ONLY CHEAP IF WE CAN TAKE IT (v4.7.331, user: "if a boon gives us something but
  -- costs an affliction or something we dont have immunity for, it should be scored significantly
  -- lower as the cost isn't worth it for the benefit"). A permanent affliction we cannot cure runs
  -- for the rest of the run, so it is not a small deduction from a big benefit -- it devalues the
  -- benefit itself. Hence a HAIRCUT on everything the boon earned, plus a flat charge; and hence
  -- next to nothing when we are already immune to exactly that affliction.
  drawbackKeep = 0.5,       -- how much of the boon's own score survives an un-immune cost
  drawbackAffFlat = 35,     -- ...and a flat charge on top, per affliction
  drawbackImmune = -2,      -- we are immune to it: all but free, and still worth naming
  drawback = -12,           -- a cost we cannot classify (kept for callers outside this file)
  -- A STAT TRADED AWAY IS NOT AN AFFLICTION (v4.7.332, user: "Ogre is a bit different. Because it
  -- is giving us something for removing a stat. I would rate those higher than corrupted breath
  -- for example. Or losing a stat but gaining X is a lot better"). Losing 2% critical strike for
  -- 10% resistance to all damage is a TRADE -- both sides are numbers, and the loss is bounded.
  -- So it is charged in the same currency as the gain (a straight subtraction, no haircut) and
  -- named in the summary, where before it was invisible and free.
  lossPerPct = 1.0,         -- "lose 2% critical strike chance" -> -2
  conflictsHeld = -100,     -- cannot be taken alongside a boon we hold
  inert = -60,              -- needs a spirit we are not attuned to
  combo = 3,
  echoHeld = 5,             -- an (ECHO) offer strengthens a boon we already hold
  categoryShort = 10,       -- a category we hold fewer of than the others this run
  comboStep = 12,           -- carries a COMBO recipe forward (v4.7.328)
  comboCompletes = 35,      -- ...and this one finishes it: the reward is free
  restoration = 8,          -- "Restore your resources instead."
  restorationLowHealth = 40, -- ...worth more than a permanent boon when we are hurt
  restorationLowAt = 50,    -- health percent
  rerollBelow = 20,         -- suggest a reroll when the best option scores under this
}

-- Per class, only what DIFFERS from the default (merged over it). Empty until play says otherwise;
-- e.g. `M.BOON_CLASS_WEIGHTS.bard = { category = { offence = 20 } }`.
M.BOON_CLASS_WEIGHTS = M.BOON_CLASS_WEIGHTS or {}

-- The stat-scaling damage boons by NAME (v4.7.362), so they score high even before they have been
-- contemplated -- all three are in M.BOON_UNDESCRIBED, and an undescribed boon otherwise earns only
-- its category and rarity. A contemplated description that says "for each point of <stat>" is caught
-- as well (Trainwreck: "2% bonus damage for each point of strength, intelligence and dexterity").
M.BOON_STAT_DAMAGE = {
  ["Brute Force"] = "strength",
  ["Mental Prowess"] = "intelligence",
  ["Deadly Finesse"] = "dexterity",
}

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

-- WHAT A BOON TAKES BACK IN NUMBERS (v4.7.332): "You lose 2% critical strike chance", "but lose
-- 10% magical resistance", "but lose 1 constitution". Returns a list of { pct | stat, amount, what }.
--
-- Deliberately NOT "reduced by"/"weakness to": `_resistFrom` already reads those as negative
-- resistances and the advisor already charges them, so matching them here would bill the same
-- clause twice. This reads the word LOSE, which no benefit clause uses.
function M._costLosses(desc)
  local out = {}
  if type(desc) ~= "string" then return out end
  local low = desc:lower()
  for n, what in low:gmatch("lose%s+(%d+)%%%s+([%a][%a%s]*)") do
    -- The name runs to the end of its clause: "2% critical strike chance, but you gain..." is
    -- three words, not one, and a comma or full stop ends it. A greedy capture can still run into
    -- the next clause when it is joined by a conjunction, so cut there too.
    for _, joiner in ipairs({ " and ", " but ", " while ", " however" }) do
      local at = what:find(joiner, 1, true)
      if at then what = what:sub(1, at - 1) end
    end
    what = what:gsub("%s+$", "")
    if what ~= "" then out[#out + 1] = { kind = "pct", amount = tonumber(n), what = what } end
  end
  for n, what in low:gmatch("lose%s+(%d+)%s+points?%s+of%s+(%a+)") do
    out[#out + 1] = { kind = "stat", amount = tonumber(n), what = what }
  end
  for n, what in low:gmatch("lose%s+(%d+)%s+(%a+)") do
    if what ~= "points" and what ~= "point" then
      out[#out + 1] = { kind = "stat", amount = tonumber(n), what = what }
    end
  end
  return out
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

  -- COMBO CREDIT DOES NOT NEED A DESCRIPTION (v4.7.329). A recipe names its components, and most of
  -- those we have never contemplated -- so scoring them only when we hold their text meant the
  -- seeded recipes paid nothing for exactly the boons they name.
  -- COMBO RECIPES (v4.7.328). A component is worth more than itself: several of them buy another
  -- boon outright. Only recipes the game has shown us (see 015_Boon_Combos).
  --
  -- ONLY THE BEST CHAIN COUNTS (review). Scoring every recipe a boon feeds made combo credit
  -- unbounded -- two near-complete chains paid 35 + 35, enough to outweigh the -100 for a boon we
  -- cannot even hold beside one we have. You can only claim the boon once, so it earns one
  -- chain's worth; the rest are named in the summary without adding to the score.
  local bestCombo, bestPts = nil, 0
  for _, reward in ipairs((M.comboFeeds and M.comboFeeds(name)) or {}) do
    local prog = M.comboProgress and M.comboProgress(reward, ctx.held)
    if prog and not prog.complete and not ctx.held[name] then
      local completes = (prog.have + 1 >= prog.need)
      local pts = completes and W.comboCompletes or W.comboStep
      local text = completes and ("completes " .. reward)
        or ((prog.have + 1) .. "/" .. prog.need .. " toward " .. reward)
      r.effects[#r.effects + 1] = text
      if pts > bestPts then
        bestPts, bestCombo = pts, (completes and ("COMPLETES the " .. reward .. " combo") or text)
      end
    end
  end
  if bestCombo then add(r, bestPts, bestCombo) end

  -- Free damage from a stat we already have (v4.7.362) -- before the description check, because the
  -- named ones score whether or not we have contemplated them.
  local statDmg = M.BOON_STAT_DAMAGE[name]
    or (desc and desc:lower():match("for each point of ([%a, ]-%a)%s+you have"))
    or (desc and desc:lower():match("for each point of (%a+)"))
  if statDmg then
    add(r, W.statScalingDamage, "damage scales with your " .. statDmg)
    r.effects[#r.effects + 1] = "damage scales with " .. statDmg
  end


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

  -- WHAT IT TAKES BACK IN NUMBERS: charged like a gain, not like an affliction (v4.7.332).
  for _, loss in ipairs((M._costLosses and M._costLosses(desc)) or {}) do
    local pts, text
    if loss.kind == "pct" then
      pts, text = loss.amount * W.lossPerPct, "-" .. loss.amount .. "% " .. loss.what
    else
      local per = (loss.what == "constitution") and W.constitutionPerPoint or W.statPerPoint
      pts, text = loss.amount * per, "-" .. loss.amount .. " " .. loss.what
    end
    add(r, -pts, "costs " .. text:gsub("^%-", ""))
    r.effects[#r.effects + 1] = text
  end

  -- THE COSTS, CLASSIFIED BY WHETHER WE CAN SHRUG THEM OFF. `_boonDrawbacks` returns the
  -- affliction names a boon inflicts on us, so each one can be checked against what this run has
  -- made us immune to. The charge itself is applied at the end, once the boon's own worth is known.
  local costsOpen = {}
  for _, c in ipairs((M._boonDrawbacks and M._boonDrawbacks(desc)) or {}) do
    if ctx.immune[c] then
      add(r, W.drawbackImmune, "cost: " .. c .. ", which you are immune to")
      r.effects[#r.effects + 1] = "cost: " .. c .. " (immune)"
    else
      costsOpen[#costsOpen + 1] = c
      r.flags[#r.flags + 1] = "cost: " .. c .. " -- NOT immune"
    end
  end

  local cw = (M._conflictsFor and M._conflictsFor(name, ctx.held)) or {}
  for _, n in ipairs(cw) do
    if ctx.held[n] then
      add(r, W.conflictsHeld, "conflicts with " .. n)
      r.flags[#r.flags + 1] = "CONFLICTS with " .. n .. " (you have it)"
      r.blocked = "conflicts with " .. n
    end
  end

  local spirit = M._spiritGate and M._spiritGate(desc)
  if spirit and M._attuned and M._attuned(spirit) == false then
    add(r, W.inert, "inert without " .. spirit)
    r.flags[#r.flags + 1] = "inert: needs " .. spirit
    r.blocked = r.blocked or ("it needs " .. spirit)
  end

  -- THE UN-IMMUNE COST, CHARGED LAST (v4.7.331). Half of what the boon earned, plus a flat charge
  -- per affliction: a permanent affliction devalues the benefit it is attached to rather than
  -- subtracting a fixed amount from it, so a big enough number could otherwise buy any price.
  -- Only ever a deduction -- a boon already scoring at or below zero is not "improved" by a cost.
  if #costsOpen > 0 then
    local cut = (r.score > 0) and math.floor(r.score * (1 - W.drawbackKeep) + 0.5) or 0
    add(r, -(cut + W.drawbackAffFlat * #costsOpen),
      "costs " .. table.concat(costsOpen, ", ") .. " and you are not immune")
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
    local effects = table.concat(r.effects, ", ")
    if #effects > 160 then effects = effects:sub(1, 157) .. "..." end
    if effects ~= "" then cecho("\n      <grey>" .. effects .. "<reset>") end
    if #r.flags > 0 then
      cecho("\n      <indian_red>" .. table.concat(r.flags, "; ") .. "<reset>")
    end
  end
  -- A BOON WE CANNOT USE NEVER TAKES THE RECOMMENDATION (review, v4.7.328). A conflict with a boon
  -- we hold, or a spirit we are not attuned to, is a fact no score should be able to outvote --
  -- and combo credit could: the old arithmetic recommended a boon we could not hold. Rank still
  -- decides among the usable ones; when every option is blocked, we say so rather than pretend.
  local best, second
  for _, r in ipairs(ranked) do
    if not r.blocked then
      if not best then best = r elseif not second then second = r; break end
    end
  end
  local allBlocked = best == nil
  if allBlocked then best, second = ranked[1], ranked[2] end
  local margin = second and (best.score - second.score) or best.score
  M.echo("<green>RECOMMEND<reset> <gold>" .. best.name .. "<reset> -- " .. reasons(best, 3)
    .. (best.blocked and ("<grey>, but <indian_red>" .. best.blocked) or "")
    .. (second and ("<grey> (ahead of " .. second.name .. " by " .. margin .. ")") or "") .. "<reset>.")
  if allBlocked then
    M.echo("<yellow>Every option has a problem<reset> -- there is no clean pick on this screen.")
  end
  if best.score < W.rerollBelow and (M._rerollsLeft or 0) > 0 then
    M.echo("<yellow>Every option is weak<reset> -- consider <white>BOON REROLL<reset> ("
      .. M._rerollsLeft .. " left).")
  end
  M._lastAdvice = { list = list, ranked = ranked, at = os.time() }
  return ranked
end
