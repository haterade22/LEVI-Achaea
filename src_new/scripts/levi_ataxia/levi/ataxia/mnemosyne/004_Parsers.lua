--[[mudlet
type: script
name: Mnemosyne Parsers
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
    MNEMOSYNE RUN TRACKER - GAME-TEXT PARSERS
    ============================================================================
    Turns multi-line game blocks (effects, boons offered) into API payloads.

    Both blocks use a "Name:  <padded>  description" layout inside dashed
    dividers, and descriptions word-wrap onto un-prefixed continuation lines.
    We capture the raw block with a temporary catch-all line trigger (same idea
    as item_catalog's scan), then parse it with pure-Lua string logic that joins
    wrapped continuation lines back onto their entry.

    Gating:
      * onRunStart / onRipple / onGo gate on M._auto() -- they establish or
        bootstrap the run (onRunStart and onRipple both set M.run.active).
      * onMonsters / onEffectsHeader / onBoonsOffered / onBoonClaim gate on
        M._inRun() so the generic-sounding game phrases can't report outside a
        tracked run.

    Depends on 001-003.
    ============================================================================
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

-- Longest plausible boon/effect name; a longer "Name:" match is treated as
-- wrapped continuation text rather than a new entry.
local MAX_NAME_LEN = 40

-- A dashed divider line (game uses ~80 dashes; accept 3+ for robustness).
local function isDivider(ln)
  return ln:match("^%-%-%-+") ~= nil
end

-- ---------------------------------------------------------------------------
-- Generic block capture: catch every line until onLine says "stop" (or the
-- timeout fires), then hand the collected lines to onDone.
--   opts.onLine(line) -> "stop" | "skip" | nil
--   opts.timeout      -> seconds of silence before flushing (backstop)
--   opts.onDone(lines)
-- Reentrancy-guarded: only one capture runs at a time.
-- ---------------------------------------------------------------------------
function M._captureLines(opts)
  if M._capturing then
    M.decho("capture already in progress; ignoring new block")
    return function() end
  end
  M._capturing = true

  local lines, tid, timer = {}, nil, nil
  local done = false

  local function finish()
    if done then return end
    done = true
    M._capturing = false
    if tid then pcall(killTrigger, tid) end
    if timer then pcall(killTimer, timer) end
    local ok, err = pcall(opts.onDone, lines)
    if not ok then M.echo("Parse error: " .. tostring(err)) end
  end

  local function bump()
    if timer then killTimer(timer) end
    timer = tempTimer(opts.timeout or 1.5, finish)
  end

  tid = tempRegexTrigger([[^.*$]], function()
    local ln = line
    local res = opts.onLine and opts.onLine(ln)
    if res == "stop" then return finish() end
    if res ~= "skip" then table.insert(lines, ln) end
    bump()
  end)
  bump()
  return finish
end

-- Parse "Name:  description" lines into {name, description}, joining wrapped
-- continuation lines (no "Name:" prefix) onto the previous entry.
function M._parseNamedBlock(lines)
  local out = {}
  for _, ln in ipairs(lines) do
    if not (ln:match("^%s*$") or isDivider(ln)) then
      local name, desc = ln:match("^(%S.-):%s%s+(%S.*)$")
      if name and #name <= MAX_NAME_LEN then
        out[#out + 1] = {
          name = name:gsub("%s+$", ""),
          description = desc:gsub("%s+$", ""),
        }
      elseif #out > 0 then
        local cont = ln:match("^%s*(%S.-)%s*$")
        if cont then
          out[#out].description = out[#out].description .. " " .. cont
        end
      end
    end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- Handlers (called by trigger bodies)
-- ---------------------------------------------------------------------------

-- "You begin to wade out into the depths of the Mnemosyne..."
function M.onRunStart()
  if M._auto() then M.startRun() end
end

-- "You wade N ripples deep into the tides of memory:" (WADE STATUS output).
-- Seeing this proves we're in a run, so (re)assert active, set the ripple
-- first, then flush any buffered monsters so /ripple_level precedes /monsters.
function M.onRipple(n)
  if not M._auto() then return end
  M.run.active = true
  M.setRipple(n)
  M._flushMonsters()
end

-- "GO!" -- a new wave has begun. Auto-send WADE STATUS so its output drives the
-- ripple-level and effects reporting. Gated on _auto() (not _inRun) so it can
-- bootstrap the run if the run-start line was missed; a stray GO! outside a run
-- just sends a harmless status command that produces no report.
function M.onGo()
  if M._auto() then send("wade status", false) end
end

-- "Ongoing effects:" (inside the ripple status block). Skip the immediate
-- divider, collect effect lines, stop on a blank line or the closing divider.
function M.onEffectsHeader()
  if not M._inRun() then return end
  local skippedDash = false
  M._captureLines({
    timeout = 1.5,
    onLine = function(ln)
      if ln:match("^%s*$") then return "stop" end
      if isDivider(ln) then
        if not skippedDash then
          skippedDash = true
          return "skip"
        end
        return "stop"
      end
      return nil
    end,
    onDone = function(lines)
      local list = M._parseNamedBlock(lines)
      if #list > 0 then M.reportEffects(list) end
    end,
  })
end

-- "As the Mnemosyne stretches ever on... you see flickers of power..."
-- Content sits between two dividers and ends at "BOON CLAIM ...".
function M.onBoonsOffered()
  if not M._inRun() then return end
  local seenDash = false
  M._captureLines({
    timeout = 3,
    onLine = function(ln)
      if ln:find("BOON CLAIM", 1, true) then return "stop" end
      if isDivider(ln) then
        if seenDash then return "stop" end
        seenDash = true
        return "skip"
      end
      if not seenDash then return "skip" end
      return nil
    end,
    onDone = function(lines)
      local list = M._parseNamedBlock(lines)
      if #list > 0 then
        -- Remember canonical names so a later BOON CLAIM can be reported
        -- with the exact spelling the game used.
        M.run.lastOffered = {}
        for _, b in ipairs(list) do table.insert(M.run.lastOffered, b.name) end
        M._reportBoonsOfferedEnriched(list)
      end
    end,
  })
end

-- "In a <flash>, a host of <X> joins the fray." Buffer (accumulate) monster
-- spawns; they arrive just BEFORE the "GO!" that triggers WADE STATUS, and are
-- flushed after /ripple_level in onRipple. We keep the full phrase incl. article.
function M.onMonsters(str)
  if not M._inRun() then return end
  if type(str) ~= "string" then return end
  str = str:gsub("^%s+", ""):gsub("%s+$", "")
  if str == "" then return end
  M.run.pendingMonsters = M.run.pendingMonsters or {}
  for _, m in ipairs(M.run.pendingMonsters) do
    if m == str then return end -- de-dupe repeated spawn lines
  end
  table.insert(M.run.pendingMonsters, str)
end

-- Fires from the BOON CLAIM alias. Only report a selection that matches one of
-- the boons we saw offered (resolving the game's exact spelling); a typo or
-- stale claim reports nothing rather than a bogus selection.
function M.onBoonClaim(name)
  if not M._inRun() then return end
  if type(name) ~= "string" then return end
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then return end
  local canonical
  for _, off in ipairs(M.run.lastOffered or {}) do
    if off:lower() == name:lower() then
      canonical = off
      break
    end
  end
  if not canonical then
    return M.decho("BOON CLAIM '" .. name .. "' not in last offered set; not reporting.")
  end
  M.reportBoonsSelected(canonical)
end

-- Enrichment hook: when the BOON CONTEMPLATE <name> output format is known,
-- probe each offered boon here to fill quote/rarity/num_echoes_possible before
-- reporting. For now we send name + description (already valid per schema).
function M._reportBoonsOfferedEnriched(list)
  M.reportBoonsOffered(list)
end
