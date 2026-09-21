--[[mudlet
type: script
name: Boon Combos
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
    WHICH BOONS COMBO INTO WHICH  (v4.7.328, `mnem combos`)
    ============================================================================

    User, holding the reward: "With every required boon now in hand, the mist of the Mnemosyne
    parts and bestows upon you another: Lightning Soul." -- "I got that for finishing the boon
    combo. We need to boon contemplate those and add them to the database and also start to tie
    which boons combo together to get to the end path of the boon."

    The recipe is printed on the REWARD's own contemplate -- on the ONE sample we have. Whether a
    component's block also carries the line is UNPROVEN: no component has been contemplated and
    read yet. Nothing here depends on the stronger claim (a recipe found on any block is stored the
    same way), so it is written as the weaker one:

        Lightning Soul:
        Rarity:             rare
        Category:           Defence
        Can echo:           No
        Unlocked By:        Argent Scales, Electric Mastery, and Energetic

    So a chain is learnt the first time we contemplate a reward -- which the per-offer chain now
    does for every boon we are offered. `unlocksFrom` (v4.7.328) is that line as a LIST; the
    `unlockedBy` STRING it came from is still stored and still posted to the tracker.

    WHAT THIS MODULE ADDS:
      * `M.comboChains()`  -- every recipe we know, reward -> components.
      * `M.comboFeeds(name)` -- the reverse: which rewards a boon feeds. Built fresh each call
        from the catalogue, because a contemplate can add a chain at any moment.
      * `M.comboProgress(reward)` -- held / missing for THIS RUN, from the claims.
      * `M.comboGaps()` -- named components we have never contemplated. The contemplate chain asks
        about one per offer screen, so a recipe fills itself in over a few screens instead of
        needing a command.
      * `M.reportCombos(filter)` -- `mnem combos`: what is close, what is done, what is unknown.
      * `M.onComboBoonGranted(name)` -- the bestowal line (trigger mnemosyne/095): records the free
        boon as claimed, says which chain completed, and queues it for contemplation.

    The advisor (014) reads `comboFeeds` so an option that advances or COMPLETES a chain is worth
    more, and says so.

    A note on where recipes come from: only the game's own text. Nothing here guesses a chain from
    names or themes -- an invented recipe would send the advisor chasing a reward that does not
    exist.
]]--

local M = ataxia.mnemosyne

-- reward -> { components }, from the catalogue (the seed has no recipes).
--
-- CACHED ON THE CATALOGUE (review, v4.7.328). Every caller here calls this, and `scoreBoon` calls
-- it once per offered boon -- a full scan of ~400 entries each time, for a table that only changes
-- when a boon is learnt. `_learnBoon` bumps `M._boonLibGen`; the cache also keys on the library
-- TABLE itself, because the tests (and a history reload) swap it wholesale.
function M.comboChains()
  local lib = (M.history and M.history.boonLibrary) or {}
  local gen = M._boonLibGen or 0
  local c = M._comboCache
  if c and c.lib == lib and c.gen == gen then return c.chains end
  local out = {}
  for name, rec in pairs(lib) do
    if type(rec) == "table" and type(rec.unlocksFrom) == "table" and #rec.unlocksFrom > 0 then
      local parts = {}
      for i, n in ipairs(rec.unlocksFrom) do parts[i] = n end
      out[name] = parts
    end
  end
  M._comboCache = { lib = lib, gen = gen, chains = out }
  return out
end

-- Which rewards does this boon feed? (A boon can appear in more than one recipe.)
function M.comboFeeds(name)
  local base = (M._baseBoonName and M._baseBoonName(name)) or name
  local out = {}
  if type(base) ~= "string" then return out end
  for reward, parts in pairs(M.comboChains()) do
    for _, p in ipairs(parts) do
      if p == base then out[#out + 1] = reward; break end
    end
  end
  table.sort(out)
  return out
end

-- This run's progress toward one reward: { reward, parts, held = {}, missing = {}, have, need,
-- complete }. `held` counts a component we have claimed this run; `complete` means the reward
-- itself is already in hand.
function M.comboProgress(reward, held)
  local parts = M.comboChains()[reward]
  if not parts then return nil end
  held = held or (M._heldBoons and M._heldBoons()) or {}
  local p = { reward = reward, parts = parts, held = {}, missing = {},
              complete = held[reward] == true }
  for _, n in ipairs(parts) do
    if held[n] then p.held[#p.held + 1] = n else p.missing[#p.missing + 1] = n end
  end
  p.have, p.need = #p.held, #parts
  return p
end

-- Components a recipe names that we have never contemplated: no description of our own, or never
-- asked. These are what "add them to the database" means, and the offer-screen chain takes one at
-- a time so a recipe completes itself over a few screens.
function M.comboGaps()
  local out, seen = {}, {}
  local function consider(n)
    if type(n) ~= "string" or n == "" or seen[n] then return end
    seen[n] = true
    local rec = M.boonInfo and M.boonInfo(n)
    local known = type(rec) == "table" and rec.contemplatedAt ~= nil
    if not known and not (M.boonUnknown and M.boonUnknown(n)) then out[#out + 1] = n end
  end
  for _, parts in pairs(M.comboChains()) do
    for _, n in ipairs(parts) do consider(n) end
  end
  -- A BOON WE HOLD BUT HAVE NEVER CONTEMPLATED (review, v4.7.328). A combo REWARD is granted, never
  -- offered, so it is in none of the three sources `boonGaps` walks -- if the one contemplate after
  -- the grant does not land (the offer chain usually still holds the capture slot), nothing would
  -- ever ask again and the reward stays unknown for good. Asking here costs one contemplate.
  for n in pairs((M._heldBoons and M._heldBoons()) or {}) do consider(n) end
  table.sort(out) -- a stable queue: the same gap is asked about first every time
  return out
end

-- `mnem combos [filter]`
function M.reportCombos(filter)
  local chains = M.comboChains()
  local held = (M._heldBoons and M._heldBoons()) or {}
  local f = (type(filter) == "string" and filter ~= "") and filter:lower() or nil
  local rows = {}
  for reward in pairs(chains) do
    local p = M.comboProgress(reward, held)
    local hay = (reward .. " " .. table.concat(p.parts, " ")):lower()
    if not f or hay:find(f, 1, true) then rows[#rows + 1] = p end
  end
  -- Closest to done first: it is the one worth knowing about.
  table.sort(rows, function(a, b)
    if a.complete ~= b.complete then return b.complete end
    if a.have ~= b.have then return a.have > b.have end
    return a.reward < b.reward
  end)
  local inRun = (M.run and M.run.active) == true
  local gaps = M.comboGaps()
  M.echo("<gold>Boon combos<reset> -- <white>" .. #rows .. "<grey> recipe(s) known"
    .. (f and (" (filter: " .. filter .. ")") or "")
    .. (#gaps > 0 and (", <cyan>" .. #gaps .. "<grey> component(s) not yet contemplated") or "")
    .. ". <grey>A recipe is learnt from the REWARD's contemplate."
    .. (inRun and "" or " <yellow>No run is being tracked, so nothing counts as held.<grey>"))
  if #rows == 0 then
    return cecho("\n  <grey>(none yet -- they arrive as offered boons are contemplated)")
  end
  for _, p in ipairs(rows) do
    local rec = (M.boonInfo and M.boonInfo(p.reward)) or {}
    local mark = p.complete and "<green>HELD" or ("<white>" .. p.have .. "/" .. p.need)
    cecho("\n  " .. mark .. "<reset> <gold>" .. p.reward .. "<reset>"
      .. (rec.category and ("  <white>" .. rec.category) or "")
      .. (rec.rarity and ("  <" .. M.rarityColour(rec.rarity) .. ">" .. rec.rarity) or "") .. "<reset>")
    local parts = {}
    for _, n in ipairs(p.parts) do
      parts[#parts + 1] = (held[n] and ("<green>" .. n) or ("<grey>" .. n)) .. "<reset>"
    end
    cecho("\n      <grey>needs: " .. table.concat(parts, "<grey>, "))
    if rec.description and rec.description ~= "" then
      cecho("\n      <grey>" .. rec.description)
    else
      -- Also for a reward we HOLD: that is the case where the grant's own contemplate never
      -- landed, and saying nothing there hid it completely (review, v4.7.328).
      cecho("\n      <grey>(not contemplated yet -- <cyan>mnem boonfill<grey> will ask)")
    end
  end
end

-- "With every required boon now in hand, the mist of the Mnemosyne parts and bestows upon you
-- another: Lightning Soul." (trigger mnemosyne/095, live 2026-09-19)
--
-- A boon we never claimed and were never offered: without this it reached neither the run's claims
-- nor the bonuses panel, so a reward we are wearing was invisible to everything that reads them.
function M.onComboBoonGranted(name)
  name = (M._baseBoonName and M._baseBoonName(name)) or name
  if type(name) ~= "string" or name == "" then return false end
  local held = (M._heldBoons and M._heldBoons()) or {}
  -- ONCE PER GRANT (review, v4.7.328). A reconnect replaying the screen, or a pasted log, would
  -- otherwise record a second claim -- and `_recordClaim` reads that as an ECHO, announcing "now 2
  -- echo(es)" for a reward whose own block says it cannot echo.
  if held[name] then return false end
  local p = M.comboProgress(name, held)
  if not (M._quiet and M._quiet()) then
    M.echo("<green>COMBO COMPLETE<reset> -- the Mnemosyne grants <gold>" .. name .. "<reset>"
      .. (p and (" <grey>(" .. table.concat(p.parts, ", ") .. ")") or "") .. "<reset>.")
  end
  -- EVERYTHING A CLAIM DOES (review, v4.7.328). This boon is never offered and never claimed, so
  -- the claim path (`onBoonClaim`) never runs for it: before this it reached the local history and
  -- nothing else -- not the combat flags a boon can latch, not the bonuses panel, not the tracker.
  -- Recording needs a run to belong to; without one the claim would land in the PREVIOUS run's
  -- bucket, so say it and record nothing.
  if not (M.run and M.run.active) then
    M.echo("<grey>(not recorded -- no run is being tracked right now.)")
    return true
  end
  if M._recordClaim then pcall(M._recordClaim, name) end
  if M.latchBoonFlag then pcall(M.latchBoonFlag, name) end
  if M.bonuses and M.bonuses.refresh then pcall(M.bonuses.refresh) end
  -- The tracker's own endpoint for this (v4.7.330): `/boon_received`, not `/boons_selected` --
  -- a combo reward is never offered and never chosen, so reporting it as a selection described an
  -- event that did not happen. Gated like every other report.
  if M._inRun and M._inRun() and M.reportBoonReceived then pcall(M.reportBoonReceived, name) end
  -- Its own contemplate carries the recipe (and the category, and the text), and we have never
  -- seen this boon on an offer screen. The offer chain usually still holds the capture slot right
  -- after a claim, so ONE attempt would quietly do nothing: retry a few times, and `comboGaps`
  -- keeps it on the list if every attempt is beaten to the slot.
  M._contemplateGranted(name, 1)
  return true
end

-- Ask for the granted boon's own block, retrying while something else holds the capture slot.
local GRANT_TRIES, GRANT_GAP = 5, 6
function M._contemplateGranted(name, try)
  if not (tempTimer and M._boonScreenContemplate) then return end
  tempTimer(try == 1 and 1 or GRANT_GAP, function()
    local ok, started = pcall(M._boonScreenContemplate, { { name = name } })
    if not (ok and started) and try < GRANT_TRIES then
      M._contemplateGranted(name, try + 1)
    end
  end)
end
