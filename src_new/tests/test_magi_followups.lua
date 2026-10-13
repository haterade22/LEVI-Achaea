--- test_magi_followups.lua -- four Magi trigger fixes (v4.7.420), driven through each trigger's
--- REAL patterns and body
--
-- What was wrong:
--   * staffcast/002, the Glacial crystal's waterbond: its shivering test read `tAffs.shiving`, a
--     key nothing sets, so a shivering target was given 25 or 15 seconds instead of the wiki's 35
--     (kb/raw/wiki/Artificing.wiki:82). And its pattern was the whole line (140 columns with a
--     seven-letter name), folded across two YAML lines where tools/check_wrap.py cannot see it, so
--     on this user's 119-124 wrap the trigger never fired at all (kb/CONFLICTS.md #2).
--     Reading V3 instead of tAffs then showed one more case: a hypothermic target is frozen, but V3
--     can hold hypothermia without frozen (both hypothermia lines give frozen, and on a target V3
--     has not seen shivering, applyFrozenInteractionV3 records shivering instead), so a freeze we
--     did not see got the "only shivering" 35 seconds instead of 45.
--   * magi_offense_tracking/015, ERODE: an eroded insulation was never recorded as `nocaloric`;
--     its map sent `caloric` to erAff instead.
--   * general/020 (a failed conflagrate) zeroed, and general/022_Increase_Burning ("You fan the
--     heat of <T>'s body...") added to, the burns counted on `target` for a line naming anyone.
--
-- The lines are rebuilt word for word from the patterns (kb/ holds no capture of them), with
-- pronouns in the patterns' \w+ slots. ERODE's defence line has the shape both 015 and
-- 335_Mob_Razed parse ("<word> <defence> defence is eroded away."), and its two no-strip lines are
-- 335's own patterns. A single-line trigger gets its line whole and wrapped at 100, 119 and 124
-- columns, one row at a time through its REAL patterns; 015, a multiline trigger, gets
-- `multimatches` built from its own three patterns. The bodies run against a small affliction
-- model behind the public API (haveAff / tarAffed / erAff), with the REAL ataxia_tarAffTimed (017)
-- and the REAL 004; the tests that need what V3 makes of a line (the hypothermia case above) swap
-- in the REAL API over the REAL tracker (007, 008). One shared Lua state: every global, and
-- table.contains, is restored at the end.

local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains

local TL = dofile("src_new/tests/trigger_lib.lua")
local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local WIDTHS = { false, 100, 119, 124 }   -- false: the whole line on one row
local NAME, LONG = "Xarthus", "Abcdefghijkl"

-- Fresh tables, so the loads below build their own and the restore drops them. The V3 files
-- initialise theirs as `X = X or {...}`, so a table an earlier test file left would be reused.
magi = nil
for _, k in ipairs({ "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3",
  "affLastConfirmedV3", "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3",
  "negativeConfirmTimersV3", "tAffsV2", "tAffStacksV2" }) do
  _G[k] = nil
end
ataxia = { afflictions = {}, settings = {} }
ataxiaTemp, tAffs, affTimers = {}, {}, {}
target = NAME
partyrelay = false

-- A failed load is raised inside the protected block below, so the restore at the end still runs.
local loadErr
for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",    -- ataxia_tarAffTimed, the API
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
  "src_new/scripts/levi_ataxia/levi/levi_scripts/mage/004_Magi_Offense.lua",  -- magi.offense
}) do
  local okLoad, errLoad = pcall(dofile, f)
  if not okLoad then loadErr = "Failed to load " .. f .. ": " .. tostring(errLoad); break end
end
local REAL = { haveAff = haveAff, tarAffed = tarAffed, erAff = erAff }
-- table.contains is a Mudlet extension the real tarAffed uses; restored at the end.
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

-- A clock the tests move by hand. String callbacks are run too (002 clears `twaterbond` with one).
local now, timers = 0, {}
tempTimer = function(d, fn) timers[#timers + 1] = { at = now + d, fn = fn }; return #timers end
killTimer = function(id) if timers[id] then timers[id].dead = true end end
local function advance(sec)
  now = now + sec
  for _, t in ipairs(timers) do
    if not t.dead and t.at <= now then
      t.dead = true
      if type(t.fn) == "function" then t.fn() else assert((loadstring or load)(t.fn))() end
    end
  end
end

-- The affliction model: the public API over one set. `added` and `erased` keep the order. tAffs is
-- not written, so a test can make V3's mirror disagree with the tracker.
local has, added, erased, tails = {}, {}, {}, {}
haveAff = function(a) return has[a] == true end
tarAffed = function(...)
  for _, a in ipairs({ ... }) do has[a] = true; added[#added + 1] = a end
end
erAff = function(a) has[a] = nil; erased[#erased + 1] = a end
tempLineTrigger = function(from, n, fn) tails[#tails + 1] = { from = from, n = n, fn = fn }; return #tails end
isTargeted = function(n) return n == target end

local function world(affs)
  has, added, erased, tails = {}, {}, {}, {}
  for _, a in ipairs(affs or {}) do has[a] = true end
  now, timers = 0, {}
  target = NAME
  tAffs = {}
  ataxiaTemp = { tarAffTimers = {} }
  _G.twaterbond = nil   -- 002's flag: nil until a bond sets it
  local st = magi.offense.state
  st.burns, st.conflagrated = 0, false
  tburns = 0
end

-- The REAL tracker in place of the model, for a test that needs what V3 makes of a line rather than
-- what the line says: 017's API over V3 (007, 008), on a fresh target, the clock as above. The
-- model and everything else replaced here come back afterwards, pass or fail.
local function withV3(fn)
  local saved = { haveAff, tarAffed, erAff, raiseEvent, checkTargetLocks, getEpoch, ataxia_boxEcho, zgui }
  world()
  haveAff, tarAffed, erAff = REAL.haveAff, REAL.tarAffed, REAL.erAff
  raiseEvent = function() end           -- 017 registers "tar afflicted" by NAME, which the mock cannot call
  checkTargetLocks = function() end     -- curing/003, not loaded
  getEpoch = function() return 1000 + now end
  ataxia_boxEcho, zgui = function() end, nil   -- pummel-related/002's banner; no target window
  affConfigV3.enabled = true
  resetStatesV3()
  local okRun, errRun = pcall(fn)
  haveAff, tarAffed, erAff, raiseEvent, checkTargetLocks, getEpoch, ataxia_boxEcho, zgui = unpack(saved, 1, 8)
  if not okRun then error(errRun, 0) end
end

-- The trigger's own regex as a Lua pattern, to fill `matches` the way Mudlet does. Only the shapes
-- these triggers use; anything else raises.
local function luaPat(re)
  local out, i = {}, 1
  while i <= #re do
    local c = re:sub(i, i)
    if c == "\\" then
      local n = re:sub(i + 1, i + 1)
      out[#out + 1] = (n == "w") and "[%w_]" or ("%" .. n)
      i = i + 1
    elseif (c == "^" and i == 1) or (c == "$" and i == #re) then
      out[#out + 1] = c
    elseif c == "(" and re:sub(i + 1, i + 1) == "?" then
      error("unsupported group in " .. re)
    elseif c:match("[%(%)%.%+%?%*]") then
      out[#out + 1] = c
    elseif c:match("[%[%]{}|%^%$]") then
      error("unsupported regex syntax '" .. c .. "' in " .. re)
    elseif c:match("[%%%-]") then
      out[#out + 1] = "%" .. c
    else
      out[#out + 1] = c
    end
    i = i + 1
  end
  return table.concat(out)
end

-- Mudlet's `matches` for the first of `pats` that matches `row` (Mudlet fires an OR-trigger on its
-- first matching pattern), or nil. An anchored pattern is checked against trigger_lib on every row.
local function capture(pats, row)
  for _, p in ipairs(pats) do
    local found = { row:find(luaPat(p.pat)) }
    if p.pat:sub(1, 1) == "^" then
      assert(TL.matches(p.pat, p.type, row) == (found[1] ~= nil),
        "trigger_lib and the Lua pattern disagree on: " .. row)
    end
    if found[1] then
      local m = { row:sub(found[1], found[2]) }
      for k = 3, #found do m[#m + 1] = found[k] end
      return m
    end
  end
end

local function body(file)
  local fh = assert(io.open(TRG .. file, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(assert(src:match("%]%]%-%-\r?\n(.*)$"), "no header: " .. file), file))
end

local WATERBOND, ERODE = "staffcast/002_Waterbond_on.lua", "magi_offense_tracking/015_Erode.lua"
local CONFLAG_FAIL, FAN = "general/020_Conflagrated_Fail.lua", "general/022_Increase_Burning.lua"
-- The two hypothermia lines, ours and another Magi's (read, not changed: they set up 002's case).
local HYPO, PUMMEL = "magi_offense_tracking/005_Hypothermia_1st_Person.lua", "pummel-related/002_Hypothermia.lua"
local PATS, BODY = {}, {}   -- filled inside the protected block

-- Deliver `text` as the server would at `width` (false: one row), one row at a time. The trigger
-- runs on every row its patterns match; a next-row reader armed on one row reads the next. Returns
-- the number of the first row the trigger fired on, or nil.
local function deliver(file, text, width)
  local rows = width and TL.wrap(text, width) or { text }
  local first
  tails = {}
  for i, row in ipairs(rows) do
    line = row
    local armed = tails
    tails = {}
    local m = capture(PATS[file], row)
    if m then
      matches = m
      first = first or i
      BODY[file]()
    end
    for _, t in ipairs(armed) do
      assert(t.from == 1 and t.n == 1, "a next-row reader must read exactly the next row")
      t.fn()
    end
  end
  return first
end

local function same(list, want)
  if #list ~= #want then return false end
  for i = 1, #want do if list[i] ~= want[i] then return false end end
  return true
end
local function expectList(list, want)
  if not same(list, want) then
    error("expected {" .. table.concat(want, ", ") .. "} but got {" .. table.concat(list, ", ") .. "}", 2)
  end
end
local function T(tpl, name) return (tpl:gsub("<T>", name)) end
local function wname(w) return w and ("@" .. w) or "whole" end

local BOND = "Even as the wave of cold dissipates, you retain control over the fluid and send it spinning"
  .. " through the air to bind <T> in a watery web."
local CAST = "You cast a spell of erosion at <T>."
local function eroded(def) return "His " .. def .. " defence is eroded away." end
local FAIL = "You bend your will upon <T>, attempting to rouse a conflagration to consume him, but to no avail."
local FANLINE = "You fan the heat of <T>'s body into consuming flame."
local HYPOLINE = "You blast <T> with an icy stream of water, and he begins to shiver uncontrollably."
local PUMMELLINE = "As Zarana blasts <T> with icy water, he begins to shake and tremble uncontrollably."

-- ERODE is a multiline trigger: the cast line, a one-line spacer, then `(.*)` on the line that says
-- what was stripped. In Mudlet a spacer of 1 moves the next condition to the line straight after
-- the cast (TMatchState::lineSpacerMatch) and leaves an empty capture list of its own
-- (TTrigger::match_line_spacer), so the body gets `multimatches` = { cast, {}, that line }.
local function erode(castName, followup)
  local p = PATS[ERODE]
  local m1 = capture({ p[1] }, T(CAST, castName))
  local m3 = capture({ p[3] }, followup)
  assert(m1 and m3, "the erode lines no longer match the trigger's patterns")
  multimatches = { m1, {}, m3 }
  BODY[ERODE]()
end

local ok, err = pcall(function()
if loadErr then error(loadErr, 0) end
for _, f in ipairs({ WATERBOND, ERODE, CONFLAG_FAIL, FAN, HYPO, PUMMEL }) do
  PATS[f], BODY[f] = TL.patterns(TRG .. f), body(f)
end

-- Seconds until the REAL ataxia_tarAffTimed erases the bond, or nil if no bond was given.
local function bondSeconds()
  local id = ataxiaTemp.tarAffTimers.waterbond
  return id and timers[id] and (timers[id].at - now) or nil
end

describe("staffcast/002 waterbond: fires on a wrapped line, and holds for the wiki's time", function()
  -- Artificing.wiki:82: frozen 45 s, only shivering 35, insulation stripped 25, otherwise 15. A
  -- hypothermic target is frozen (Elementalism.wiki:181).
  local LADDER = {
    { {}, 15 },
    { { "nocaloric" }, 25 },
    { { "nocaloric", "shivering" }, 35 },   -- `tAffs.shiving` never reached this case
    { { "shivering" }, 35 },
    { { "nocaloric", "shivering", "frozen" }, 45 },
    { { "frozen" }, 45 },
    { { "nocaloric", "shivering", "hypothermia" }, 45 },   -- V3 after a hypothermia line on a freeze it missed
  }

  it("fires on the first row, reads the name from the row that ends the sentence, times the bond", function()
    local bad = {}
    for _, c in ipairs(LADDER) do
      for _, w in ipairs(WIDTHS) do
        for _, name in ipairs({ NAME, LONG }) do
          world(c[1])
          target = name
          local first = deliver(WATERBOND, T(BOND, name), w)
          local secs = bondSeconds()
          if first ~= 1 or not has.waterbond or secs ~= c[2] or twaterbond ~= true then
            bad[#bad + 1] = "{" .. table.concat(c[1], ",") .. "} " .. wname(w) .. " " .. name .. " (row "
              .. tostring(first) .. ", " .. tostring(secs) .. " s)"
          end
        end
      end
    end
    if #bad > 0 then error(#bad .. " failed: " .. table.concat(bad, "; ")) end
  end)

  it("the bond and twaterbond both end on that time", function()
    world({ "nocaloric", "shivering" })
    deliver(WATERBOND, T(BOND, NAME), 119)
    advance(34)
    expect(has.waterbond).toBeTrue()
    expect(twaterbond).toBeTrue()
    advance(1)
    expect(has.waterbond).toBeNil()
    expect(twaterbond).toBeFalse()
  end)

  it("asks the tracker, not tAffs: the mirror can keep a frozen haveAff no longer gives", function()
    world({ "nocaloric", "shivering" })
    tAffs = { frozen = true }   -- the mirror is rewritten only past 30% or under 1% (syncToOldSystemV3)
    deliver(WATERBOND, T(BOND, NAME))
    expect(bondSeconds()).toBe(35)
  end)

  it("a bond on someone else records nothing", function()
    for _, w in ipairs(WIDTHS) do
      world({ "frozen" })
      deliver(WATERBOND, T(BOND, "Someoneelse"), w)
      expect(#added).toBe(0)
      expect(twaterbond).toBeNil()
      expect(#timers).toBe(0)
    end
  end)

  it("reproduces the bug: the old folded pattern matched no row at the user's widths", function()
    local old = "^Even as the wave of cold dissipates, you retain control over the fluid and send it spinning"
      .. " through the air to bind (\\w+) in a watery web\\.$"
    expect(TL.matches(old, 1, T(BOND, NAME))).toBeTrue()   -- the right words, on a row too long to exist
    for _, w in ipairs({ 119, 124 }) do
      for _, row in ipairs(TL.wrap(T(BOND, NAME), w)) do
        expect(TL.matches(old, 1, row)).toBeFalse()
      end
    end
  end)
end)

describe("staffcast/002 on the REAL tracker: a hypothermic target is frozen", function()
  -- HYPOTHERMIA lands only "if your enemy is already frozen" (Elementalism.wiki:181) and "Prevents
  -- curing the freezing affliction" (kb/raw/live/affliction_show/hypothermia.txt). Both hypothermia
  -- lines give frozen, but on a target V3 has not seen shivering, applyFrozenInteractionV3 records
  -- shivering instead: V3 then holds hypothermia and no frozen (a freeze another Magi laid, a manual
  -- cast, a missed line), and the model above cannot show that.
  it("after our hypothermia line or another Magi's: frozen's 45 s, and the bond lasts that long", function()
    local bad = {}
    for _, c in ipairs({ { HYPO, HYPOLINE }, { PUMMEL, PUMMELLINE } }) do
      for _, w in ipairs({ false, 119 }) do
        withV3(function()
          local fired = deliver(c[1], T(c[2], NAME))
          local hypo = haveAff("hypothermia")
          deliver(WATERBOND, T(BOND, NAME), w)
          local secs = bondSeconds()
          advance(44)
          local held = haveAff("waterbond")
          advance(1)
          if fired ~= 1 or not hypo or secs ~= 45 or not held or haveAff("waterbond") or twaterbond ~= false then
            bad[#bad + 1] = c[1] .. " " .. wname(w) .. " (" .. tostring(secs) .. " s)"
          end
        end)
      end
    end
    if #bad > 0 then error(#bad .. " failed: " .. table.concat(bad, "; ")) end
  end)

  it("the ladder, read from V3 itself", function()
    local bad = {}
    for _, c in ipairs({
      { {}, 15 },
      { { "nocaloric" }, 25 },
      { { "shivering" }, 35 },
      { { "shivering", "frozen" }, 45 },                    -- frozen on a shivering target: V3 holds it
      { { "hypothermia", "shivering", "nocaloric" }, 45 },  -- what the hypothermia lines leave
      { { "hypothermia" }, 45 },
    }) do
      withV3(function()
        for _, a in ipairs(c[1]) do tarAffed(a) end
        deliver(WATERBOND, T(BOND, NAME), 119)
        if bondSeconds() ~= c[2] then
          bad[#bad + 1] = "{" .. table.concat(c[1], ",") .. "} " .. tostring(bondSeconds()) .. " s"
        end
      end)
    end
    if #bad > 0 then error(#bad .. " failed: " .. table.concat(bad, "; ")) end
  end)
end)

describe("015 ERODE: an eroded insulation is recorded as nocaloric, on the line's own word", function()
  it("keeps the shape its body reads: the cast line, a one-line spacer, then the next line", function()
    local p = PATS[ERODE]
    expect(#p).toBe(3)
    expect(p[2].type).toBe(5)
    expect(p[2].pat).toBe("1")
    expect(p[3].pat).toBe("(.*)")
  end)

  it("an eroded insulation records nocaloric (the defence's name, or the salve's)", function()
    for _, def in ipairs({ "insulation", "caloric" }) do
      world()
      erode(NAME, eroded(def))
      expectList(added, { "nocaloric" })
      expectList(erased, { "shield" })   -- the shield strip it always records
    end
  end)

  it("any other defence is not insulation", function()
    world()
    erode(NAME, eroded("rebounding"))
    expectList(added, {})
    expectList(erased, { "shield", "rebounding" })
  end)

  it("a line that names no defence records no nocaloric", function()
    for _, follow in ipairs({ "Your erode spell fails to strip " .. NAME .. " of anything.",
      NAME .. " has no more defences." }) do
      world()
      erode(NAME, follow)
      expectList(added, {})
    end
  end)

  it("an erode at someone else records nothing", function()
    world()
    erode("Someoneelse", eroded("insulation"))
    expectList(added, {})
    expectList(erased, {})
  end)
end)

describe("022_Increase_Burning: only our target's burn", function()
  it("a fan at our target adds one burn, at every width", function()
    for _, w in ipairs(WIDTHS) do
      for _, name in ipairs({ NAME, LONG }) do
        world()
        target = name
        expect(deliver(FAN, T(FANLINE, name), w)).toBe(1)
        expect(magi.offense.state.burns).toBe(1)
        expect(tburns).toBe(1)
        expectList(added, { "burning" })
      end
    end
  end)

  it("a fan at someone else adds nothing", function()
    for _, w in ipairs(WIDTHS) do
      world()
      magi.offense.state.burns, tburns = 2, 2
      expect(deliver(FAN, T(FANLINE, "Someoneelse"), w)).toBe(1)   -- the line is ours, the name is not
      expect(magi.offense.state.burns).toBe(2)
      expect(tburns).toBe(2)
      expectList(added, {})
    end
  end)
end)

describe("020 failed conflagrate: only our target's count is zeroed", function()
  -- 101 columns with a seven-letter name: one row at the user's 119 and 124, two at 100 (an
  -- anchored line, like 021_Spell_Outcomes' dehydrate cast), so 100 is not delivered here.
  local FITS = { false, 119, 124 }

  it("a failure at our target zeroes the burns and the conflagration", function()
    for _, w in ipairs(FITS) do
      for _, name in ipairs({ NAME, LONG }) do
        world()
        target = name
        local st = magi.offense.state
        st.burns, st.conflagrated, tburns = 3, true, 3
        expect(deliver(CONFLAG_FAIL, T(FAIL, name), w)).toBe(1)
        expect(st.burns).toBe(0)
        expect(st.conflagrated).toBeFalse()
        expect(tburns).toBe(0)
      end
    end
  end)

  it("a failure at someone else leaves our target's count alone", function()
    for _, w in ipairs(FITS) do
      world()
      local st = magi.offense.state
      st.burns, st.conflagrated, tburns = 3, true, 3
      expect(deliver(CONFLAG_FAIL, T(FAIL, "Someoneelse"), w)).toBe(1)
      expect(st.burns).toBe(3)
      expect(st.conflagrated).toBeTrue()
      expect(tburns).toBe(3)
    end
  end)
end)

end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
table.contains = savedContains
if not ok then error(err) end
