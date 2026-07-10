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
M.history = M.history or { run = 0, claims = {}, offers = {}, affixes = {}, library = {} }

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
end

function M._historySave()
  local fn = histFile()
  if not fn or type(table.save) ~= "function" then return end
  pcall(table.save, fn, M.history)
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
    end
  end
  M._historySave()
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

-- Load persisted history at startup.
M._historyLoad()
