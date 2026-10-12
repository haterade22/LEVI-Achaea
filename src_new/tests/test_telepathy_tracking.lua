--- test_telepathy_tracking.lua -- blackout and disrupted on the target, and the lock refusal
--
-- Blackout lasts 4 s and is cured by time (AFFLICTION SHOW, kb/raw/live/affliction_show/
-- blackout.txt). Both of its recorders, Psion LIGHTSTEAL (525) and Knight CONCUSS (snb/008), ran
-- a raw tempTimer(3.5, ...) that a repeat never cancelled, so the first timer erased the second
-- blackout early; 525 also called "blackout" to the party on every lightsteal, standing target or
-- not, naming the global `target`. MIND DISRUPT (telepathy_tekura/007) kept `disrupted` for a flat
-- 10 s that the target's CONCENTRATE line (788) did not cancel. These tests drive the REAL trigger
-- bodies through the REAL tracker (V3 + 017) on a mock clock -- the mock's getEpoch is os.time,
-- 1 s resolution, too coarse to tell 3.9 s from 4 -- and run the REAL patterns against the lines
-- (trigger_lib). Every global the loaded files create or change is restored at the end.

local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains

local TL = dofile("src_new/tests/trigger_lib.lua")
local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local T = "Agathon"

-- A mock clock. Timers fire in order of their due time; string callbacks run as Mudlet runs them.
local now, timers, nextId = 0, {}, 0
local function clock()
  now, timers, nextId = 0, {}, 0
  getEpoch = function() return now end
  tempTimer = function(d, fn)
    nextId = nextId + 1
    timers[nextId] = { at = now + d, fn = fn }
    return nextId
  end
  killTimer = function(id) timers[id] = nil end
end

local function advanceTo(t)
  while true do
    local id
    for k, tm in pairs(timers) do
      if tm.at <= t and (not id or tm.at < timers[id].at or (tm.at == timers[id].at and k < id)) then id = k end
    end
    if not id then break end
    local tm = timers[id]
    timers[id] = nil
    now = tm.at
    if type(tm.fn) == "string" then assert(loadstring(tm.fn))() else tm.fn() end
  end
  now = t
end

-- Run a trigger or alias body as Mudlet would. Reads fall through to the real tracker in _G;
-- whatever the body writes as a global (mindlocked, tinvest) stays in rec.env.
local function run(path, ctx)
  ctx = ctx or {}
  local fh = assert(io.open(path, "r"), "no such file: " .. path)
  local src = fh:read("*a")
  fh:close()
  local fn = assert(loadstring(assert(src:match("%]%]%-%-\r?\n(.*)$")), "=" .. path))
  local rec = { sent = {}, deleted = 0 }
  local env = {
    matches = ctx.matches, multimatches = ctx.multimatches,
    line = ctx.line or (ctx.matches and ctx.matches[1]) or "",
    -- the real isTargeted compares names case-insensitively
    isTargeted = function(n) return n:lower() == target:lower() end,
    send = function(c) rec.sent[#rec.sent + 1] = c end,
    sendAll = function(...) for _, c in ipairs({ ... }) do rec.sent[#rec.sent + 1] = c end end,
    deleteFull = function() rec.deleted = rec.deleted + 1 end,
    partyrelay = ctx.partyrelay or false,
    ataxia = { afflictions = {} },
  }
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  fn()
  rec.env = env
  return rec
end

local function sentMatching(rec, pat)
  local n = 0
  for _, c in ipairs(rec.sent) do if c:find(pat) then n = n + 1 end end
  return n
end

-- A fresh target with nothing on it, at t = 0.
local function world()
  clock()
  tAffs, affTimers = {}, {}
  ataxiaTemp = {}
  target = T
  zgui = nil
  -- 017 registers its display handler by NAME ("tarGained"), which the mock would try to call.
  raiseEvent = function() end
  checkTargetLocks = function() end
  ataxiaEcho = function() end
  resetStatesV3()
end

local ok, err = pcall(function()
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",
}) do
  local loaded, why = pcall(dofile, f)
  if not loaded then error("Failed to load " .. f .. ": " .. tostring(why)) end
end

describe("blackout on the target lasts the game's 4 s", function()
  it("has its duration in the shared table (AFFLICTION SHOW: 4 seconds, cured by time)", function()
    expect(ataxia_TARGET_AFF_SECONDS.blackout).toBe(4)
  end)

  it("ataxia_tarAffTimed keeps it at 3.9 s and drops it at 4 s", function()
    world()
    ataxia_tarAffTimed("blackout")
    advanceTo(3.9)
    expect(haveAff("blackout")).toBeTrue()
    advanceTo(4)
    expect(haveAff("blackout")).toBeFalse()
  end)
end)

-- 525 is a multiline trigger: the strike line, a one-line spacer, then any line, which the body
-- compares with the faulty-technique line. So its body reads multimatches. The lightsteal line is
-- in no log (kb/raw/logs); it is built from the trigger's own pattern.
local function lightsteal(person, third)
  return {
    { "You slash a translucent dagger across the eyes of " .. person .. ", viciously robbing him of sight.", person },
    {},
    { third or "(the line after the spacer)" },
  }
end

describe("Psion LIGHTSTEAL (525) records blackout only when it lands", function()
  it("a prone target is blacked out until 4 s, not 3.5 s", function()
    world()
    tarAffed("prone")
    run(TRG .. "525_Blackout.lua", { multimatches = lightsteal(T) })
    expect(haveAff("blackout")).toBeTrue()
    advanceTo(3.9)
    expect(haveAff("blackout")).toBeTrue()
    advanceTo(4)
    expect(haveAff("blackout")).toBeFalse()
  end)

  it("a standing target gets no blackout and no party call; the mana read still goes out", function()
    world()
    local r = run(TRG .. "525_Blackout.lua", { multimatches = lightsteal(T), partyrelay = true })
    expect(haveAff("blackout")).toBeFalse()
    expect(sentMatching(r, "^pt ")).toBe(0)
    expect(sentMatching(r, "^contemplate Agathon$")).toBe(1)
  end)

  it("striking someone else records and calls nothing, even while our target is prone", function()
    world()
    tarAffed("prone")
    local r = run(TRG .. "525_Blackout.lua", { multimatches = lightsteal("Claes"), partyrelay = true })
    expect(haveAff("blackout")).toBeFalse()
    expect(#r.sent).toBe(0)
  end)

  it("the party call names the person the game named, not the typed target", function()
    world()
    target = "agathon"
    tarAffed("prone")
    local r = run(TRG .. "525_Blackout.lua", { multimatches = lightsteal(T), partyrelay = true })
    expect(sentMatching(r, "^pt Agathon: blackout$")).toBe(1)
  end)

  it("a blow robbed by faulty technique records and sends nothing", function()
    world()
    tarAffed("prone")
    local faulty = "Your blow strikes " .. T .. " but is robbed of much of its impact by your faulty technique."
    local r = run(TRG .. "525_Blackout.lua", { multimatches = lightsteal(T, faulty), partyrelay = true })
    expect(haveAff("blackout")).toBeFalse()
    expect(#r.sent).toBe(0)
  end)
end)

local CONCUSS = "You pivot rapidly and bring your shield around to batter the head of " .. T .. "."

describe("Knight CONCUSS (snb/008) records blackout for 4 s from the latest one", function()
  it("a second concuss 2 s later is not cut short by the first one's clock", function()
    world()
    tarAffed("prone")
    run(TRG .. "snb/008_Blackout.lua", { matches = { CONCUSS, T } })
    advanceTo(2)
    run(TRG .. "snb/008_Blackout.lua", { matches = { CONCUSS, T } })
    advanceTo(5)
    expect(haveAff("blackout")).toBeTrue()
    advanceTo(6)
    expect(haveAff("blackout")).toBeFalse()
  end)

  it("a standing target gets none", function()
    world()
    run(TRG .. "snb/008_Blackout.lua", { matches = { CONCUSS, T } })
    expect(haveAff("blackout")).toBeFalse()
  end)
end)

-- Our MIND DISRUPT success line is in no log (Mystor's client replaces it); built from the
-- trigger's own pattern. The CONCENTRATE line is logged (Mystor, vNTjvghY:732, c.iJVmpL:358).
local DISRUPT = "You quickly attack " .. T .. "'s mind from multiple directions, upsetting his equilibrium."
local CONCENTRATE = T .. "'s eyes lose their focus suddenly."

describe("disrupted lasts until the target concentrates (007, 788)", function()
  it("the CONCENTRATE line clears it and cancels the backstop clock", function()
    world()
    run(TRG .. "telepathy_tekura/007_Disrupt.lua", { matches = { DISRUPT, T } })
    expect(haveAff("disrupted")).toBeTrue()
    expect(ataxiaTemp.tarAffTimers ~= nil and ataxiaTemp.tarAffTimers.disrupted ~= nil).toBeTrue()
    advanceTo(1)
    run(TRG .. "788_Target_Concentrated.lua", { matches = { CONCENTRATE, T } })
    expect(haveAff("disrupted")).toBeFalse()
    expect(ataxiaTemp.tarAffTimers.disrupted).toBeNil()
  end)

  it("a re-disrupt at 8 s is still up at 12 s; the backstop ends it 10 s after the last", function()
    world()
    run(TRG .. "telepathy_tekura/007_Disrupt.lua", { matches = { DISRUPT, T } })
    advanceTo(8)
    run(TRG .. "telepathy_tekura/007_Disrupt.lua", { matches = { DISRUPT, T } })
    advanceTo(12)
    expect(haveAff("disrupted")).toBeTrue()
    advanceTo(18)
    expect(haveAff("disrupted")).toBeFalse()
  end)

  it("someone else's concentrate leaves ours alone", function()
    world()
    run(TRG .. "telepathy_tekura/007_Disrupt.lua", { matches = { DISRUPT, T } })
    run(TRG .. "788_Target_Concentrated.lua", { matches = { "Claes's eyes lose their focus suddenly.", "Claes" } })
    expect(haveAff("disrupted")).toBeTrue()
  end)
end)

local NO_LOCK = "You do not possess a mindlock."
local LOCK_GAG = TRG .. "allies_enemies/012_LOCK_GAG.lua"

describe("the lock-state lines (allies_enemies/012)", function()
  it("'You do not possess a mindlock.' clears mindlocked and stays on screen", function()
    local r = run(LOCK_GAG, { line = NO_LOCK, matches = { NO_LOCK } })
    expect(rawget(r.env, "mindlocked")).toBe(false)
    expect(r.deleted).toBe(0)
  end)

  it("the lock-attempt lines are still gagged", function()
    for _, ln in ipairs({
      "You must cease your current lock attempt before trying another.",
      "You focus your mind, and begin to concentrate on forming a mind lock with " .. T .. ".",
      "You continue to delve deeper and deeper into the mind of " .. T .. ".",
    }) do
      local r = run(LOCK_GAG, { line = ln, matches = { ln, T } })
      expect(rawget(r.env, "mindlocked")).toBe(false)
      expect(r.deleted).toBe(1)
    end
  end)
end)

local TELE = "src_new/aliases/levi_ataxia/for_levi/levi_062424/telepathy/"
local SCRIPTS = "src_new/scripts/levi_ataxia/levi/levi_scripts/"

describe("the telepathy aliases", function()
  it("mp sends MIND PARALYSE, the spelling the game accepted (attacker log :1063-1064, :1067)", function()
    world()
    local r = run(TELE .. "006_MIND_PARALYZE.lua", { matches = { "mp" } })
    expect(#r.sent).toBe(1)
    expect(r.sent[1]).toBe("queue addclear free mind paralyse Agathon")
  end)

  it("mrap and disruptmind are gone: mrap read `affstrack`, which nothing assigns, and nothing called disruptmind", function()
    for _, path in ipairs({ TELE .. "013_Mind_Rape.lua", SCRIPTS .. "telepathy/001_DISRUPT.lua" }) do
      local fh = io.open(path, "r")
      if fh then fh:close() end
      if fh then error(path .. " is back") end
    end
  end)
end)

-- The comments cite kb/raw by line. kb/raw is kept verbatim, so a number that is right stays
-- right, and each must point at what its comment quotes. The first cut of 006 cited :1059
-- ("Health lost: 11 (raw).") for the send at :1064, and the first cut of 012 took its own line
-- for the refusal of a MIND command that needs a lock, which the logs show is another line.
local function slurp(path)
  local fh = assert(io.open(path, "rb"), "no such file: " .. path)
  local s = fh:read("*a")
  fh:close()
  return (s:gsub("\r\n", "\n"))
end

-- Lines a..b of a file, joined with "\n".
local function linesOf(path, a, b)
  local out, n = {}, 0
  for ln in (slurp(path) .. "\n"):gmatch("([^\n]*)\n") do
    n = n + 1
    if n > b then break end
    if n >= a then out[#out + 1] = ln end
  end
  return table.concat(out, "\n")
end

describe("the comments' log citations point at the lines they quote", function()
  local ATTACKER = "kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt"
  local LOCKLESS = "kb/raw/logs/2026-10-11_mystor_shikudo-vs-apostate_win_LcJC-rJ5.txt"
  for _, c in ipairs({
    -- { file, its citation, the log, what the cited lines must hold }
    { TELE .. "006_MIND_PARALYZE.lua", ATTACKER .. ":1063-1064", ATTACKER,
      "mp\nqueue addclearfull eb mind paralyse Claes" },  -- the alias and its expansion
    { TELE .. "006_MIND_PARALYZE.lua", ":1067 landed", ATTACKER, "You reach out with your mind and paralyse Claes." },
    { LOCK_GAG, LOCKLESS .. ":7-10", LOCKLESS,            -- refused once per command, before any lock
      "mind print|mind sapience\nYou require a mindlock to perform that ability." },
  }) do
    local file, cite, log, quote = c[1], c[2], c[3], c[4]
    it(file:match("[^/]+$") .. " cites " .. cite:match("[^/]+$"), function()
      expect(slurp(file)).toContain(cite)
      local a, b = cite:match(":(%d+)%-?(%d*)")
      local text = linesOf(log, tonumber(a), tonumber(b) or tonumber(a))
      if not text:find(quote, 1, true) then
        error(cite .. " should hold '" .. quote .. "', but reads:\n" .. text, 0)
      end
    end)
  end
end)

-- The REAL patterns against the lines, as the server wraps them (119-124 columns for this user;
-- 100 for a narrower client). Every line here fits on one row, so the whole pattern must match it.
describe("the triggers still match their lines (trigger_lib)", function()
  local WIDTHS = { 100, 119, 124 }

  local function oneRow(ln, w)
    local rows = TL.wrap(ln, w)
    if #rows ~= 1 then error("wraps at " .. w .. ": " .. ln) end
    return rows[1]
  end

  it("525 matches the lightsteal line and keeps the spacer its body indexes past", function()
    local p = TL.patterns(TRG .. "525_Blackout.lua")
    expect(#p).toBe(3)
    expect(p[2].type).toBe(5)   -- the one-line spacer, so multimatches[3] is the line after it
    -- The strike pattern is unanchored and Mudlet runs it as a search; trigger_lib evaluates
    -- anchored patterns only, so the search is spelled `^.*` + pattern.
    local strike = p[1].pat
    if strike:sub(1, 1) ~= "^" then strike = "^.*" .. strike end
    for _, w in ipairs(WIDTHS) do
      expect(TL.matches(strike, p[1].type, oneRow(lightsteal(T)[1][1], w))).toBeTrue()
    end
  end)

  it("007 matches our MIND DISRUPT line; 788 the logged CONCENTRATE line", function()
    for _, w in ipairs(WIDTHS) do
      expect(TL.anyMatches(TL.patterns(TRG .. "telepathy_tekura/007_Disrupt.lua"), oneRow(DISRUPT, w))).toBeTrue()
      expect(TL.anyMatches(TL.patterns(TRG .. "788_Target_Concentrated.lua"), oneRow(CONCENTRATE, w))).toBeTrue()
    end
  end)

  it("012 still owns the no-lock line, and never the logged lock refusal it would gag", function()
    local p = TL.patterns(LOCK_GAG)
    expect(TL.anyMatches(p, NO_LOCK)).toBeTrue()
    expect(TL.anyMatches(p, "You require a mindlock to perform that ability.")).toBeFalse()
  end)
end)
end)

-- Restore the shared Lua state.
table.contains = savedContains
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
