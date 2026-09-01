--[[mudlet
type: script
name: Audit Capture
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
    AUDIT -- THE GAME'S OWN NUMBERS  (v4.7.290, `mnem audit`)
    ============================================================================

    Everything the bonuses panel prints is DERIVED: read out of a boon's description sentence and
    added up by us. That was the right design -- a hand-maintained name->amount table goes stale on
    the entry after the last one someone added (v4.7.287) -- but it has never had a way to be
    WRONG OUT LOUD. A misparsed sentence produces a confident number and nothing contradicts it.
    `Ogre's Defence` sat on the panel as +2% for a day (v4.7.289) and only a screenshot caught it.

    AUDIT is the game reporting its own accounting:

        Audit records:
        Category                Value
        ------------------------------
        Critical Rate:          56.93
        Critical Hit Bonus:     11.75
        Celerity:               2
        Endurance:              +60      -0
        Willpower:              +24      -0
        Cutting:                76.2%
        ...

    Two things come out of that, and the second is the reason to bother:

    1. A BASELINE, captured once at the start of a run (user: "Audit can be used in the very
       beginning"). What we brought in before a single boon was claimed.

    2. A MEASUREMENT. Audit again later and `current - baseline` is what the run's boons ACTUALLY
       bought, in the game's own numbers, against a known set of claims. That is the only way to
       settle how boon resistances combine -- additively, diminishing, multiplicatively -- and this
       package's rule is to measure rather than argue (the shin-augment and rage probes, v4.7.141
       and v4.7.269). Nothing here assumes an answer: the delta is reported, not modelled.

    THE VOCABULARY DOES NOT MATCH OURS, AND THAT IS DATA
    ----------------------------------------------------
    AUDIT names NINE damage types where our boon descriptions name eight:

      * `Electricity` is our `Electric` -- a pure spelling difference, normalised.
      * `Cutting` and `Blunt` are the game's split of what every boon description calls
        "physical". They carry DIFFERENT numbers (76.2% vs 78% in the first capture), so they are
        emphatically NOT one row and are never folded into `Physical`. A boon that grants "10%
        physical resistance" presumably lifts both; how, we have not measured.
      * There is NO `Arcane` row. That is one more point toward Arcane == Magical, which v4.7.289
        deliberately declined to assume -- and it is still not proof, because AUDIT may simply
        predate the naming. Recorded, not acted on.

    WHY THIS DOES NOT USE `_captureLines`
    -------------------------------------
    That helper holds ONE global capture slot, and a second caller force-finishes the first
    (v4.7.93). The wade-entry baseline fires from `_exploreResume`, which runs off `GO!` -- the
    same instant the monster capture is arming. Sharing the slot would make two unrelated features
    race for it, which is the v4.7.282 lesson (a shared single-slot resource where every caller
    assumes it owns the schedule) in a new place. This capture is small enough to own its trigger.
]]--

ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

M.audit = M.audit or {}

-- Rows that are NOT resistances. Everything else in the block is a damage type.
local SCALARS = {
  ["critical rate"] = "critRate",
  ["critical hit bonus"] = "critBonus",
  ["celerity"] = "celerity",
}

-- Rows printed as a bonus/penalty pair ("+60      -0") rather than a single figure.
local PAIRS_ = {
  ["endurance"] = "endurance",
  ["willpower"] = "willpower",
}

-- AUDIT's spelling -> the name the rest of the package uses. Only ONE entry, deliberately:
-- `Cutting` and `Blunt` are absent because they are not aliases of anything we hold -- they are
-- two real types the game tracks separately and our boon text calls neither.
local TYPE_ALIAS = { electricity = "Electric" }

local function titled(name)
  return (name:gsub("^%l", string.upper))
end

-- ---------------------------------------------------------------------------
-- Parse
-- ---------------------------------------------------------------------------

-- One `Label: value` row. Returns nil for a header, a rule, or anything unrecognised -- the block
-- is bracketed by dashed rules and this must not treat one as data.
function M._auditRow(ln)
  if type(ln) ~= "string" then return nil end
  local label, value = ln:match("^%s*([%a][%a%s'-]-)%s*:%s+(%S.*)$")
  if not label or not value then return nil end
  label = label:lower():gsub("%s+$", "")
  -- Thousands separators stripped BEFORE any number is read. `tonumber(value:match("^%d+"))`
  -- stops at the comma, so "1,234" would parse to 1 -- a confidently WRONG number, which is the
  -- one outcome this module exists to prevent. No captured block has exceeded 100 yet; that is a
  -- reason to guard it cheaply, not a reason to assume it never will.
  value = value:gsub("%s+$", ""):gsub("(%d),(%d)", "%1%2")

  local key = PAIRS_[label]
  if key then
    -- "+60      -0" -- the game prints the gain and the loss separately, so keep both. A single
    -- netted number would hide a penalty, and a penalty is the half worth seeing.
    local up, down = value:match("([+-]?%d+)%s+([+-]?%d+)")
    if up then
      return { kind = "pair", key = key, up = tonumber(up), down = tonumber(down) }
    end
    local n = tonumber(value:match("([+-]?%d+%.?%d*)") or "")
    if n then return { kind = "pair", key = key, up = n, down = 0 } end
    return nil
  end

  local n = tonumber(value:match("^([+-]?%d+%.?%d*)") or "")
  if not n then return nil end

  key = SCALARS[label]
  if key then return { kind = "scalar", key = key, value = n } end

  -- A resistance row only if the value was a PERCENTAGE. Anything else with a number in it is a
  -- category we have not seen, and inventing a resistance out of it would put a made-up row on
  -- the panel -- the failure this whole module exists to catch.
  if value:find("%%") then
    return { kind = "resist", key = TYPE_ALIAS[label] or titled(label), value = n }
  end
  return nil
end

-- A whole block. `Category`/`Value` headers, dashed rules and blank lines fall out on their own,
-- because none of them is a `Label: number` row.
function M._parseAudit(lines)
  local out = { resists = {}, at = os.time() }
  local rows = 0
  for _, ln in ipairs(lines or {}) do
    local r = M._auditRow(ln)
    if r then
      rows = rows + 1
      if r.kind == "resist" then
        out.resists[r.key] = r.value
      elseif r.kind == "scalar" then
        out[r.key] = r.value
      else
        out[r.key] = { up = r.up, down = r.down }
      end
    end
  end
  if rows == 0 then return nil end
  return out
end

-- ---------------------------------------------------------------------------
-- Capture
-- ---------------------------------------------------------------------------

-- Armed by the `Audit records:` header (trigger 078), NOT by our own send -- so a manual AUDIT
-- typed by the user is captured exactly like ours. That matters beyond convenience: if the command
-- we send is ever wrong, this still works and the failure is visible (nothing arrives) rather than
-- silent.
--
-- THE HANDLES ARE FILE-SCOPE LOCALS, NEVER FIELDS ON `M` (deep review, v4.7.291). `M` is
-- `ataxia.mnemosyne`, which lives under the wholesale-SERIALIZED `ataxia` namespace: a bare
-- integer written there is saved to disk by `ataxia_saveSettings` and restored by `deepMerge`'s
-- unconditional `dst[k] = v`. A capture is in flight for two to three and a half seconds, and a
-- disconnect inside that window would persist a live trigger id -- which, next session, names
-- whatever temp trigger inherited that number, and the first thing `_auditCapture` does is
-- `killTrigger` it. That is the documented "never serialize a tempTimer id" invariant, and
-- `_captureLines` (004_Parsers) already gets it right by keeping its handles as closure upvalues.
local auditTrig, auditTimer, auditDeadline

-- A SILENCE TIMER IS NOT A DEADLINE (deep review, v4.7.291). The per-line timer below is re-armed
-- by every line the capture sees, so while output keeps arriving it never fires -- and this arms
-- right after `GO!`, in a no-flee tower room where a fresh wave has just spawned and combat is
-- starting. Output does not stop. The consequence is worse than a long capture: the baseline is
-- FIRST-WINS AND PERMANENT (`_auditRecord`), so anything that contaminates it is silent and lasts
-- the whole run, recoverable only by a manual `mnem audit reset`.
--
-- So there are TWO timers, and the second is never re-armed: a hard ceiling from the moment the
-- header was seen. Same reasoning as the dedicated funnel timer of v4.7.282 -- a clock that every
-- caller may push out cannot hold a deadline.
--
-- The line cap is the same guard against a burst that lands INSIDE the ceiling. The real block is
-- eighteen lines; sixty is a wide margin that still bounds a flood.
local AUDIT_MAX_SECONDS = 5
local AUDIT_MAX_LINES = 60

function M._auditCapture()
  if auditTrig then pcall(killTrigger, auditTrig); auditTrig = nil end
  if auditTimer then pcall(killTimer, auditTimer); auditTimer = nil end
  if auditDeadline then pcall(killTimer, auditDeadline); auditDeadline = nil end

  local lines, rules = {}, 0
  local function finish()
    if auditTrig then pcall(killTrigger, auditTrig); auditTrig = nil end
    if auditTimer then pcall(killTimer, auditTimer); auditTimer = nil end
    if auditDeadline then pcall(killTimer, auditDeadline); auditDeadline = nil end
    local rec = M._parseAudit(lines)
    if rec then M._auditRecord(rec) end
  end

  auditTrig = tempRegexTrigger([[^.*$]], function()
    local ln = line
    if type(ln) == "string" and ln:match("^%s*%-%-%-") then
      rules = rules + 1
      -- The block is bracketed by two rules; the second closes it.
      if rules >= 2 then return finish() end
      return
    end
    table.insert(lines, ln)
    if #lines >= AUDIT_MAX_LINES then return finish() end
    if auditTimer then pcall(killTimer, auditTimer) end
    auditTimer = tempTimer(1.5, finish)
  end)
  auditTimer = tempTimer(2, finish)
  auditDeadline = tempTimer(AUDIT_MAX_SECONDS, finish)  -- armed once, never re-armed
end

-- Store a parsed block. The FIRST of a run becomes the baseline and is never overwritten by a
-- later one -- that is the whole point of it, and a baseline that drifts forward measures nothing.
function M._auditRecord(rec)
  M.audit.current = rec
  if not M.audit.baseline then
    M.audit.baseline = rec
    M.audit.baselineRun = (M.history and M.history.run) or nil
  end
  M.audit.pending = nil
  if M.bonuses and M.bonuses.refresh then pcall(M.bonuses.refresh) end
  M.echo("<gold>AUDIT<reset> captured"
    .. (rec.critRate and ("  crit <cyan>" .. rec.critRate .. "%<reset>") or "")
    .. (M.audit.baseline == rec and "  <grey>(baseline)" or ""))
end

-- current - baseline, per field. Returns nil when there is nothing to compare, rather than a
-- table of zeroes: "no second reading yet" and "the boons bought nothing" are different answers
-- and a panel must not render them the same.
-- ROUNDED AT THE SOURCE, because a delta is only ever displayed. AUDIT prints one and two
-- decimal places (`47.4`, `56.93`) and subtracting two such doubles produces binary noise --
-- `76.2 - 56.93` is `19.270000000000003` in Lua 5.1, and `tostring` shows every digit of it. On
-- the one panel section whose whole claim is that it is MEASURED rather than derived, printing
-- that would undermine exactly the thing it exists to provide. Two places is enough to hold
-- everything AUDIT reports, so rounding cannot lose a real difference.
-- Rounded on the MAGNITUDE and the sign reapplied. The obvious
-- `math.floor(n * 100 + (n >= 0 and 0.5 or -0.5)) / 100` is wrong for negatives: `-19.27 * 100`
-- is `-1927.0000000000002`, so subtracting 0.5 and flooring lands on -1928 and reports -19.28 --
-- a rounding fix that introduced its own off-by-one in exactly the direction it was meant to
-- prevent. Caught by the negative-delta test, which is why that test exists.
local function round2(n)
  local sign = n < 0 and -1 or 1
  return sign * math.floor(math.abs(n) * 100 + 0.5) / 100
end

function M._auditDelta()
  local a, b = M.audit.baseline, M.audit.current
  if not (a and b) or a == b then return nil end
  local d = { resists = {} }
  for _, k in ipairs({ "critRate", "critBonus", "celerity" }) do
    if type(a[k]) == "number" and type(b[k]) == "number" and b[k] ~= a[k] then
      d[k] = round2(b[k] - a[k])
    end
  end
  for k, v in pairs(b.resists or {}) do
    local base = (a.resists or {})[k]
    if type(base) == "number" and v ~= base then d.resists[k] = round2(v - base) end
  end
  return d
end

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------

-- Sending is separate from capturing on purpose (see `_auditCapture`). `reset` drops the baseline
-- so the next capture becomes one -- needed when a run was joined late, since a baseline taken
-- after boons were claimed measures nothing and is worse than none.
function M.auditSend(reset)
  if reset then M.audit.baseline, M.audit.baselineRun = nil, nil end
  M.audit.pending = os.time()
  -- Echo-suppressed, matching `send("wade status", false)` in the same GO! cascade: this is
  -- auto-sent once per run and the AUDIT block that follows is unmistakable, so echoing the word
  -- "audit" into a combat log adds a line and tells the reader nothing.
  send("audit", false)
end

-- Once per RUN, not per ripple: a baseline is a run-scoped fact, and re-asking every ripple would
-- put an eighteen-line block into the log at every boon screen for nothing.
function M.auditBaselineOnWade()
  local run = (M.history and M.history.run) or 0
  if M.audit.baseline and M.audit.baselineRun == run then return false end
  M.audit.baseline, M.audit.baselineRun = nil, nil
  M.auditSend(false)
  return true
end

function M.auditReport()
  local a, b = M.audit.baseline, M.audit.current
  if not b then
    return M.echo("<gold>AUDIT<reset> -- nothing captured yet. Type <cyan>mnem audit<reset>.")
  end
  M.echo("<gold>AUDIT<reset>"
    .. (a == b and "  <grey>(baseline only)" or "  <grey>(baseline + current)"))
  cecho("\n  <NavajoWhite>Crit rate <reset>" .. tostring(b.critRate or "?")
    .. "   <NavajoWhite>Crit bonus <reset>" .. tostring(b.critBonus or "?")
    .. "   <NavajoWhite>Celerity <reset>" .. tostring(b.celerity or "?"))

  local names = {}
  for k in pairs(b.resists or {}) do names[#names + 1] = k end
  table.sort(names)
  local d = M._auditDelta()
  for _, k in ipairs(names) do
    cecho("\n    <cyan>" .. k .. "<reset>  " .. b.resists[k] .. "%"
      .. ((d and d.resists[k]) and ("  <green>(" .. (d.resists[k] > 0 and "+" or "")
          .. d.resists[k] .. " since baseline)<reset>") or ""))
  end
  cecho("\n")
end
