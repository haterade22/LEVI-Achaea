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
-- supplies rarity, and the BOON <name> detail screen supplies maxEchoes -- each fills in the
-- fields it knows and never blanks a field another source already filled.
function M._learnBoon(name, description, rarity, maxEchoes)
  if type(name) ~= "string" or name == "" then return end
  M.history.boonLibrary = M.history.boonLibrary or {}
  local rec = M.history.boonLibrary[name] or {}
  if type(description) == "string" and description ~= "" then rec.description = description end
  if type(rarity) == "string" and rarity ~= "" then rec.rarity = rarity:lower() end
  if tonumber(maxEchoes) then rec.maxEchoes = tonumber(maxEchoes) end
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
function M._boonDbMerge(src)
  if type(src) ~= "table" then return 0, 0 end
  M.history.boonLibrary = M.history.boonLibrary or {}
  local added, enriched = 0, 0
  for name, rec in pairs(src) do
    if type(name) == "string" and name ~= "" and type(rec) == "table" then
      local cur = M.history.boonLibrary[name]
      if not cur then
        M.history.boonLibrary[name] = { description = rec.description, rarity = rec.rarity,
                                        maxEchoes = rec.maxEchoes }
        added = added + 1
      else
        local before = tostring(cur.description) .. tostring(cur.rarity) .. tostring(cur.maxEchoes)
        if (cur.description == nil or cur.description == "") and rec.description then
          cur.description = rec.description
        end
        if (cur.rarity == nil or cur.rarity == "") and rec.rarity then cur.rarity = rec.rarity end
        if cur.maxEchoes == nil and rec.maxEchoes then cur.maxEchoes = rec.maxEchoes end
        if before ~= (tostring(cur.description) .. tostring(cur.rarity) .. tostring(cur.maxEchoes)) then
          enriched = enriched + 1
        end
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
  local total, described, rarity, echoes = 0, 0, 0, 0
  for _, rec in pairs(M.history.boonLibrary or {}) do
    total = total + 1
    if type(rec) == "table" then
      if rec.description and rec.description ~= "" then described = described + 1 end
      if rec.rarity and rec.rarity ~= "" then rarity = rarity + 1 end
      if rec.maxEchoes then echoes = echoes + 1 end
    end
  end
  return { total = total, described = described, rarity = rarity, echoes = echoes }
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
    .. " described, " .. st.rarity .. " with rarity"
    .. (f and ("  <grey>(filter: " .. filter .. " -> " .. #names .. ")<reset>") or ""))
  if #names == 0 then return cecho("\n  <grey>(nothing matches)") end

  for _, name in ipairs(names) do
    local rec = lib[name] or {}
    local col = (M.RARITY_COLOUR and rec.rarity and M.RARITY_COLOUR[rec.rarity]) or "cyan"
    cecho("\n  <" .. col .. ">" .. name .. "<reset>"
      .. (rec.rarity and ("  <grey>" .. rec.rarity) or "")
      .. (rec.maxEchoes and ("  <grey>x" .. rec.maxEchoes) or "") .. "<reset>")
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

-- Load persisted history at startup, then merge the standalone catalogue over it.
M._historyLoad()
if M._boonDbLoad then pcall(M._boonDbLoad) end
