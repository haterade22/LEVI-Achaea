--[[mudlet
type: script
name: Mnemosyne History
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
    MNEMOSYNE RUN TRACKER - LOCAL HISTORY + REPORTS
    ============================================================================
    Records what we parse each run (offers, claims, ongoing-effect "affixes")
    to a local, persisted store so the player can review runs in-client, and
    keeps an all-time affix library. Separate from the remote tracker: this is
    the local mirror.

    Recording is driven from the parsers (004) at the same points we POST, so
    history is captured during tracked runs (auto-reporting on + token). The
    functions here never gate on the token themselves.

    Persistence uses table.save/table.load to <profile>/mnemosyne_history.lua,
    guarded so the module still loads in a bare (test) environment.

    Depends on 001 (M.echo/_cfg) and 002 (M.run). Loads after them.
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

-- run: local run counter (bumped by startRun). claims/offers/affixes: flat
-- per-record lists tagged with `run`. library: [affixName] = description.
M.history = M.history or { run = 0, claims = {}, offers = {}, affixes = {}, library = {}, boonLibrary = {} }

-- Rarity -> colour, used wherever boons are shown (the BOONS-list annotation, reports).
-- Names verified against misc_scripts/007_Custom_Colour_Table (which wholesale-replaces
-- color_table -- there is no ansi_* namespace here).
M.RARITY_COLOUR = {
  common = "light_goldenrod", uncommon = "green", rare = "purple",
  legendary = "orange", mythical = "magenta",
}
function M.rarityColour(r)
  return M.RARITY_COLOUR[tostring(r or ""):lower()] or "white"
end

-- ---------------------------------------------------------------------------
-- Persistence (guarded so tests / bare environments don't error)
-- ---------------------------------------------------------------------------

local function histFile()
  if type(getMudletHomeDir) ~= "function" then return nil end
  return getMudletHomeDir() .. "/mnemosyne_history.lua"
end

function M._historyLoad()
  local fn = histFile()
  if not fn or type(table.load) ~= "function" then return end
  pcall(table.load, fn, M.history)
  M.history.run = tonumber(M.history.run) or 0
  M.history.claims = M.history.claims or {}
  M.history.offers = M.history.offers or {}
  M.history.affixes = M.history.affixes or {}
  M.history.library = M.history.library or {}
  M.history.boonLibrary = M.history.boonLibrary or {} -- name -> {description, rarity, maxEchoes}
end

function M._historySave()
  local fn = histFile()
  if not fn or type(table.save) ~= "function" then return end
  pcall(table.save, fn, M.history)
  -- ...and the catalogue to its own file, so a bad history write cannot take the one part
  -- that cannot be rebuilt. Both writes are already debounced by the caller.
  if M._boonDbSave then M._boonDbSave() end
end

-- Debounced save. A BOONS list calls _learnBoon once PER ROW (30+ rows is normal), and a
-- table.save of the whole history per row would be absurd -- coalesce to one write next tick.
-- Without this the rarity back-filled from the BOONS list is purely in-memory and dies with
-- the session, since every other _historySave caller sits behind a telemetry gate.
function M._historySaveSoon()
  if M._histSavePending then return end
  M._histSavePending = true
  if type(tempTimer) ~= "function" then M._histSavePending = nil; return M._historySave() end
  tempTimer(0, function()
    M._histSavePending = nil
    M._historySave()
  end)
end

function M._quiet()
  return M._cfg and M._cfg().quiet == true
end

-- ---------------------------------------------------------------------------
-- Recording (called from the parsers)
-- ---------------------------------------------------------------------------

-- Start a new local run (called synchronously from startRun).
function M._historyNewRun()
  M.history.run = (tonumber(M.history.run) or 0) + 1
  M._historySave()
end

-- Latest non-empty rarity/description we recorded for a boon name (offers carry
-- descriptions + rarity; a later claim borrows them).
function M._histBoonInfo(name)
  local rarity, description = "", ""
  for _, o in ipairs(M.history.offers) do
    if o.name == name then
      if o.rarity and o.rarity ~= "" then rarity = o.rarity end
      if o.description and o.description ~= "" then description = o.description end
    end
  end
  return rarity, description
end

-- list: array of { name, description?, rarity? } (post-contemplate enrichment).
function M._recordOffers(list, ripple)
  ripple = ripple or (M.run and M.run.ripple) or 0
  for _, b in ipairs(list or {}) do
    if b.name and b.name ~= "" then
      table.insert(M.history.offers, {
        run = M.history.run, ripple = ripple, name = b.name,
        description = b.description or "", rarity = b.rarity or "",
      })
      M._learnBoon(b.name, b.description, b.rarity) -- all-time catalogue (#boonLibrary)
    end
  end
  M._historySave()
end

-- All-time boon catalogue: name -> { description, rarity, maxEchoes }.
--
-- Why it exists: the OFFER screen tells you what a boon does ("Iron Throat: Gain 25%
-- resistance to asphyxiation damage.") but the BOONS list -- the one you read to see what you
-- already own -- is only `Boon | Echoes | Rarity`, with no description at all. Learning every
-- boon we are ever offered lets us join the two and annotate BOONS with what each one does.
--
-- Merges rather than overwrites: the offer screen supplies the description, the BOONS list
-- supplies rarity, and BOON CONTEMPLATE (`mnem boonfill`) supplies maxEchoes and the rest -- each
-- fills in the fields it knows and never blanks a field another source already filled.
--
-- `extra` (v4.7.298) carries the rest of what a CONTEMPLATE block prints: quote, category,
-- unlockedBy, conflictsWith. All four were already being PARSED and then dropped on the floor --
-- `_boonFillNext` read `info.quote` and `info.meta` and passed neither on -- which is the
-- expensive kind of gap, because a contemplate is a command spent and a captured block, and
-- throwing away half of what it returned means paying for it again to get the rest.
--
-- A TABLE rather than four more positional parameters: the four existing call sites pass 2-4
-- args positionally, so a fifth table arg leaves every one of them correct untouched, and the
-- next field added does not shift anything.
--
-- Same fill-never-blank contract as the fields above -- each source (offer screen, BOONS list,
-- CONTEMPLATE) fills what it knows and never erases what another source already supplied.
local EXTRA_STRINGS = { "quote", "category", "unlockedBy" }

function M._learnBoon(name, description, rarity, maxEchoes, extra)
  if type(name) ~= "string" or name == "" then return end
  -- NEVER STORE A GLUED SCREEN LINE AS TEXT (v4.7.322). This function OVERWRITES the description,
  -- so it is the one place a corrupted one does lasting damage: it replaces good text and lands on
  -- the bonuses panel. Whatever source called us, peel off any `Label:   value` padding-glued to
  -- the front (see `_splitGluedMeta`), keep the rest, and promote what the labels said.
  if type(description) == "string" and M._splitGluedMeta then
    local rest, glued = M._splitGluedMeta(description)
    if glued then
      description = (rest ~= "") and rest or nil
      local p = M._promoteMeta and M._promoteMeta({ meta = glued }) or {}
      local x = {}
      if type(extra) == "table" then for k, v in pairs(extra) do x[k] = v end end
      if x.comboBoon == nil and type(p.comboBoon) == "boolean" then x.comboBoon = p.comboBoon end
      if x.category == nil and type(p.category) == "string" then x.category = p.category end
      extra = x
    end
  end
  M.history.boonLibrary = M.history.boonLibrary or {}
  local rec = M.history.boonLibrary[name] or {}
  if type(description) == "string" and description ~= "" then rec.description = description end
  if type(rarity) == "string" and rarity ~= "" then rec.rarity = rarity:lower() end
  if tonumber(maxEchoes) then
    -- ECHO FLOOR (v4.7.326 review). "Can echo: Yes" with no "Maximum echoes" line parses as 1: a
    -- floor, not a count. Flagged so the offer screen says "can echo" rather than "(max 1)", and
    -- never allowed to replace a real count we already hold.
    local floor = type(extra) == "table" and extra.echoFloor == true
    if not floor then
      rec.maxEchoes, rec.echoFloor = tonumber(maxEchoes), nil
    elseif rec.maxEchoes == nil or rec.echoFloor == true then
      rec.maxEchoes, rec.echoFloor = tonumber(maxEchoes), true
    end
  end
  if type(extra) == "table" then
    for _, f in ipairs(EXTRA_STRINGS) do
      if type(extra[f]) == "string" and extra[f] ~= "" then rec[f] = extra[f] end
    end
    -- Copied, not aliased: the caller's table is a parse result that may be reused or mutated,
    -- and the catalogue is persisted -- it must own its own storage.
    if type(extra.conflictsWith) == "table" and #extra.conflictsWith > 0 then
      local cw = {}
      for i, n in ipairs(extra.conflictsWith) do cw[i] = n end
      rec.conflictsWith = cw
    end
    -- A BOOLEAN (v4.7.322): `false` is an answer ("Combo Boon?: No"), so it is stored like `true`.
    -- A truthiness test here would silently drop every "No".
    if type(extra.comboBoon) == "boolean" then rec.comboBoon = extra.comboBoon end
  end
  M.history.boonLibrary[name] = rec
  return rec
end

-- What do we know about `name`? nil when we have never been offered it.
function M.boonInfo(name)
  if type(name) ~= "string" then return nil end
  return (M.history.boonLibrary or {})[name]
end

-- Record one claimed boon; echoes = how many times we've claimed it this run.
function M._recordClaim(name)
  if not name or name == "" then return end
  -- A spirit-gated boon we cannot benefit from is worth saying out loud at the moment it is
  -- spent, not only when it was offered (v4.7.264). pcall: history recording must not depend on
  -- the Shaman module being present.
  if M._warnAttuneOnClaim then pcall(M._warnAttuneOnClaim, name) end
  local rarity, description = M._histBoonInfo(name)
  local echoes = 1
  for _, c in ipairs(M.history.claims) do
    if c.run == M.history.run and c.name == name then echoes = echoes + 1 end
  end
  table.insert(M.history.claims, {
    run = M.history.run, ripple = (M.run and M.run.ripple) or 0,
    name = name, rarity = rarity, echoes = echoes, description = description,
  })
  M._historySave()
  if not M._quiet() then
    M.echo("Claimed <gold>" .. name .. "<reset>"
      .. (rarity ~= "" and (" (" .. rarity .. ")") or "")
      .. " -- now <gold>" .. echoes .. "<reset> echo(es)")
  end
end

-- list: array of { name, description } from the "Ongoing effects:" block. New to
-- the run -> record; new ever -> add to the all-time library.
function M._recordAffixes(list)
  local run = M.history.run
  for _, a in ipairs(list or {}) do
    if a.name and a.name ~= "" then
      local seen = false
      for _, x in ipairs(M.history.affixes) do
        if x.run == run and x.name == a.name then seen = true break end
      end
      if not seen then
        table.insert(M.history.affixes, { run = run, name = a.name, description = a.description or "" })
        if not M._quiet() then M.echo("Affix <cyan>" .. a.name) end
      end
      if not M.history.library[a.name] then
        M.history.library[a.name] = a.description or ""
      end
    end
  end
  M._historySave()
end

-- Is `name` one of THIS run's ongoing effects? Affixes are recorded per-run by
-- _recordAffixes above, so a match on the current run counter means it is live now.
-- Case-insensitive substring, so "sanguine" finds "Sanguine Restoration".
--
-- Combat reads this: the "Sanguine Restoration" affix ("Pools of blood shall heal nearby
-- denizens.") is exactly when Inhibit earns its rage, since Inhibit stops a denizen healing.
-- See ataxiaBasher_monkBattlerage.
function M.hasAffix(name)
  if type(name) ~= "string" or name == "" then return false end
  local want = name:lower()
  local run = M.history and M.history.run
  for _, a in ipairs((M.history and M.history.affixes) or {}) do
    if a.run == run and type(a.name) == "string" and a.name:lower():find(want, 1, true) then
      return true
    end
  end
  return false
end

-- ---------------------------------------------------------------------------
-- Reports (mnem boons | affixes | library)
-- ---------------------------------------------------------------------------

function M.reportBoons()
  local run = M.history.run
  local rows = {}
  for _, c in ipairs(M.history.claims) do if c.run == run then rows[#rows + 1] = c end end
  M.echo("<gold>Run #" .. run .. " -- claimed boons (" .. #rows .. "):")
  if #rows == 0 then return cecho("\n  <grey>(none recorded yet)") end
  for _, c in ipairs(rows) do
    cecho("\n  <gold>" .. c.name .. "<reset>"
      .. ((c.rarity and c.rarity ~= "") and (" (" .. c.rarity .. ")") or "")
      .. " <grey>x" .. tostring(c.echoes or 1) .. " @ripple " .. tostring(c.ripple or "?"))
    if c.description and c.description ~= "" then cecho("\n      <grey>" .. c.description) end
  end
end

function M.reportAffixes()
  local run = M.history.run
  local rows = {}
  for _, a in ipairs(M.history.affixes) do if a.run == run then rows[#rows + 1] = a end end
  M.echo("<gold>Run #" .. run .. " -- active affixes (" .. #rows .. "):")
  if #rows == 0 then return cecho("\n  <grey>(none recorded yet)") end
  for _, a in ipairs(rows) do
    cecho("\n  <cyan>" .. a.name)
    if a.description and a.description ~= "" then cecho("\n      <grey>" .. a.description) end
  end
end

function M.reportLibrary()
  local names = {}
  for name in pairs(M.history.library) do names[#names + 1] = name end
  table.sort(names)
  M.echo("<gold>Affix library (" .. #names .. " known):")
  if #names == 0 then return cecho("\n  <grey>(empty)") end
  for _, name in ipairs(names) do
    cecho("\n  <cyan>" .. name)
    local d = M.history.library[name]
    if d and d ~= "" then cecho("\n      <grey>" .. d) end
  end
end

-- ---------------------------------------------------------------------------
-- THE BOON DATABASE (v4.7.239)
-- ---------------------------------------------------------------------------
-- User: "I would love to do a boons database that captures all of the boons and their effects
-- for safe storage."
--
-- Most of it already existed: `M.history.boonLibrary` has been learning name + description +
-- rarity + maxEchoes from every offer screen since the catalogue was added. What it did NOT
-- have was any way to LOOK at it, and -- the part that matters -- any storage of its own.
--
-- WHY ITS OWN FILE. A boon's description is shown exactly ONCE, on the offer screen, and never
-- again: the BOONS list you read to see what you own is `Boon | Echoes | Rarity` with no
-- description at all. That makes the catalogue genuinely irreplaceable -- if it is lost, the
-- only way to rebuild it is to be offered every boon in the game again. It was living inside
-- `mnemosyne_history.lua` alongside run counters, claims and offers, which are rewritten
-- constantly and are worth nothing next week. Bundling something irreplaceable with something
-- disposable means one bad write loses both.
--
-- So the catalogue is ALSO written to its own file, and loading MERGES rather than replaces --
-- same semantics as `_learnBoon`, where the offer screen supplies the description, the BOONS
-- list supplies rarity and the detail screen supplies maxEchoes, and no source ever blanks a
-- field another one filled. That makes an import safe: a backup can only ever add.
local function boonDbFile()
  if type(getMudletHomeDir) ~= "function" then return nil end
  return getMudletHomeDir() .. "/mnemosyne_boons.lua"
end

function M._boonDbSave()
  local fn = boonDbFile()
  if not fn or type(table.save) ~= "function" then return false end
  -- Saved as a wrapper table rather than the bare catalogue: a version field costs nothing now
  -- and is the difference between a readable file and a guess if the shape ever changes.
  local ok = pcall(table.save, fn, { version = 1, boons = M.history.boonLibrary or {} })
  return ok and true or false
end

-- Merge a stored catalogue in. Never blanks a field that is already filled -- see above.
--
-- FIELD-DRIVEN SINCE v4.7.298, and that is a correctness change rather than tidying: the old
-- body named description/rarity/maxEchoes three times each, so the four fields added in the same
-- release would have been silently dropped on both the add and the enrich path -- a saved
-- catalogue would round-trip through save/load LOSING them. A merge that enumerates its fields
-- inline is a merge that goes stale the next time the record grows.
M.BOON_DB_FIELDS = { "description", "rarity", "maxEchoes", "quote", "category",
                     "unlockedBy", "conflictsWith", "comboBoon", "echoFloor" }
-- `comboBoon` (v4.7.322) is a boolean. The merge below already treats `false` as FILLED (it is not
-- nil, "" or an empty table) and `mergeValue` passes it through, so a known "No" survives
-- save/load and is never overwritten by an import.

-- A FIELD-DRIVEN LOOP MUST STILL RESPECT THE FIELDS' TYPES (deep review, v4.7.298).
--
-- `conflictsWith` is the only entry above that is a TABLE, and making the merge generic put it
-- through a loop written for strings. Two bugs came with that, both fixed here:
--
--   * A plain `cur[f] = rec[f]` ALIASES the source table rather than copying it -- the exact
--     hazard `_learnBoon` guards against two functions above, for this same field, with a
--     comment saying why. The seed is merged at load time (`010_Boon_Seed.lua`), so aliasing
--     would hand the persisted catalogue a reference to a literal that lives for the session.
--   * A table is never `== ""`, so an empty `{}` passes the "is there anything here" test, is
--     merged as though it were data, and then permanently passes the "already filled" test.
--     Nothing would ever refill it: `boonGaps` selects on a missing DESCRIPTION alone.
local function mergeValue(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for _, item in ipairs(v) do                    -- copied, never aliased
    if type(item) == "string" and item ~= "" then out[#out + 1] = item end -- names only (v4.7.322)
  end
  if #out == 0 then return nil end               -- empty list: no information, do not store it
  return out
end

-- THE TYPE A FIELD MUST HAVE (review, v4.7.322). A hand-edited or foreign import could carry
-- `comboBoon = "yes"`: stored, it would count as FILLED and block every later real answer, and
-- only `_enrichOffer`'s own type test kept it off the wire. A value of the wrong type is now no
-- value -- not merged, and an existing one does not count as filled. Only the non-string fields
-- are listed; the rest keep their existing behaviour.
local FIELD_TYPE = { comboBoon = "boolean", conflictsWith = "table", echoFloor = "boolean" }
local function typed(f, v)
  local want = FIELD_TYPE[f]
  if want and v ~= nil and type(v) ~= want then return nil end
  return v
end

function M._boonDbMerge(src)
  if type(src) ~= "table" then return 0, 0 end
  M.history.boonLibrary = M.history.boonLibrary or {}
  local added, enriched = 0, 0
  for name, rec in pairs(src) do
    if type(name) == "string" and name ~= "" and type(rec) == "table" then
      local cur = M.history.boonLibrary[name]
      if not cur then
        local fresh = {}
        for _, f in ipairs(M.BOON_DB_FIELDS) do fresh[f] = mergeValue(typed(f, rec[f])) end
        M.history.boonLibrary[name] = fresh
        added = added + 1
      else
        local touched = false
        for _, f in ipairs(M.BOON_DB_FIELDS) do
          local have = cur[f]
          local empty = (have == nil) or (have == "")
            or (type(have) == "table" and #have == 0)
            or (have ~= nil and typed(f, have) == nil)
          if empty then
            local v = mergeValue(typed(f, rec[f]))
            if v ~= nil and v ~= "" then
              cur[f] = v
              touched = true
            end
          end
        end
        if touched then enriched = enriched + 1 end
      end
    end
  end
  return added, enriched
end

function M._boonDbLoad()
  local fn = boonDbFile()
  if not fn or type(table.load) ~= "function" then return 0, 0 end
  local blob = {}
  local ok = pcall(table.load, fn, blob)
  if not ok then return 0, 0 end
  -- Accept both shapes: the versioned wrapper, and a bare catalogue in case someone hand-edits
  -- or an older export turns up. Refusing to read a file we clearly understand would be
  -- pedantry at the cost of the backup actually working.
  return M._boonDbMerge(blob.boons or blob)
end

-- What do we actually have? Counts, not a dump -- the dump is the report below.
function M.boonDbStats()
  local total, described, rarity, echoes, combo, checked = 0, 0, 0, 0, 0, 0
  for _, rec in pairs(M.history.boonLibrary or {}) do
    total = total + 1
    if type(rec) == "table" then
      if rec.description and rec.description ~= "" then described = described + 1 end
      if rec.rarity and rec.rarity ~= "" then rarity = rarity + 1 end
      if rec.maxEchoes then echoes = echoes + 1 end
      if rec.comboBoon == true then combo = combo + 1 end        -- v4.7.322
      if rec.contemplatedAt or rec.comboChecked then checked = checked + 1 end
    end
  end
  return { total = total, described = described, rarity = rarity, echoes = echoes,
           combo = combo, checked = checked }
end

-- The viewer. `filter` matches the name OR the description, so "immune" finds every immunity
-- boon and "battlerage" finds everything that touches rage -- which is the question you
-- actually have when you are staring at an offer screen.
function M.reportBoonDb(filter)
  local lib = M.history.boonLibrary or {}
  local names = {}
  local f = (type(filter) == "string" and filter ~= "") and filter:lower() or nil
  for name, rec in pairs(lib) do
    local hay = (name .. " " .. tostring(type(rec) == "table" and rec.description or "")):lower()
    if not f or hay:find(f, 1, true) then names[#names + 1] = name end
  end
  table.sort(names)

  local st = M.boonDbStats()
  M.echo("<gold>Boon database<reset> -- " .. st.total .. " known, " .. st.described
    .. " described, " .. st.rarity .. " with rarity, " .. st.combo .. " combo, "
    .. st.checked .. " contemplated"
    .. (f and ("  <grey>(filter: " .. filter .. " -> " .. #names .. ")<reset>") or ""))
  -- Say what the load-time repair changed (v4.7.322): a description it emptied is text the user
  -- used to see, and a silent change to the catalogue is indistinguishable from data loss.
  if M._repairedBoons and #M._repairedBoons > 0 then
    M.echo("<grey>Repaired at load (a screen line was glued to the text): <cyan>"
      .. table.concat(M._repairedBoons, "<grey>, <cyan>") .. "<grey>. <cyan>mnem boonfill<grey> re-learns any left blank.")
  end
  if #names == 0 then return cecho("\n  <grey>(nothing matches)") end

  for _, name in ipairs(names) do
    local rec = lib[name] or {}
    local col = (M.RARITY_COLOUR and rec.rarity and M.RARITY_COLOUR[rec.rarity]) or "cyan"
    cecho("\n  <" .. col .. ">" .. name .. "<reset>"
      .. (rec.rarity and ("  <grey>" .. rec.rarity) or "")
      .. (rec.maxEchoes and ("  <grey>x" .. rec.maxEchoes) or "")
      .. ((rec.comboBoon == true) and "  <cyan>combo" or "") .. "<reset>")
    if rec.description and rec.description ~= "" then
      cecho("\n      <grey>" .. rec.description)
      -- Annotate with what we parse out of it, so the database answers the question the
      -- offer screen asks rather than just storing prose.
      local grants = M._immunitiesFrom and M._immunitiesFrom(rec.description) or {}
      local costs = M._boonDrawbacks and M._boonDrawbacks(rec.description) or {}
      if #grants > 0 then
        cecho("\n      <pale_green>immune: <cyan>" .. table.concat(grants, "<reset>, <cyan>") .. "<reset>")
      end
      if #costs > 0 then
        cecho("\n      <indian_red>costs: " .. table.concat(costs, ", ") .. "<reset>")
      end
    end
  end
end

-- REPAIR WHAT WAS ALREADY STORED (v4.7.322). `_learnBoon` now refuses a glued screen line, but a
-- catalogue saved before this version can already hold one: the user's did (Deadly Finesse's
-- "description" is two WADE STATUS lines). Nothing would ever fix it -- `boonGaps` skips a boon
-- that HAS a description -- so the text sat on the bonuses panel for good. Peeled here, once per
-- load (cheap, idempotent); a boon left with no text becomes a gap again and is re-learned.
function M._boonDbRepair()
  local lib = M.history and M.history.boonLibrary
  if type(lib) ~= "table" or not M._splitGluedMeta then return 0, {} end
  local fixed = {}
  for name, rec in pairs(lib) do
    if type(rec) == "table" and type(rec.description) == "string" then
      local rest, glued = M._splitGluedMeta(rec.description)
      if glued then
        rec.description = (rest ~= "") and rest or nil
        local p = M._promoteMeta and M._promoteMeta({ meta = glued }) or {}
        if rec.comboBoon == nil and type(p.comboBoon) == "boolean" then rec.comboBoon = p.comboBoon end
        if rec.category == nil and type(p.category) == "string" then rec.category = p.category end
        fixed[#fixed + 1] = name
      end
    end
  end
  table.sort(fixed)
  if #fixed > 0 then
    M._repairedBoons = fixed -- reported by `mnem boondb`
    if M._historySave then pcall(M._historySave) end
  end
  return #fixed, fixed
end

-- Load persisted history at startup, then merge the standalone catalogue over it.
M._historyLoad()
if M._boonDbLoad then pcall(M._boonDbLoad) end
pcall(M._boonDbRepair)
