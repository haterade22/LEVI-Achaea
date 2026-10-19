--- test_magi_emanations.lua -- the fire, air and earth emanation triggers fire on a wrapping screen,
--- and the hypothermia trigger no longer writes a latch nothing reads (v4.7.420)
--
-- What was wrong:
--   * enamation/001 (fire), 003 (air) and 004 (earth) matched the WHOLE line with a pattern folded
--     across two YAML lines, where tools/check_wrap.py cannot see it (kb/CONFLICTS.md #2). The
--     lines run 150-164 columns and this user's server wraps at 119-124, so none of the three ever
--     fired there: the fire emanation's two ablaze stacks, the air emanation's paralysis and
--     dizziness and the earth emanation's relay were never recorded. They now follow the water
--     emanation (002, fixed by group M): an opening fragment of the line, and the target's name
--     read from the rows joined until the sentence closes.
--   * the air emanation never gave asthma, which the wiki gives instead of dizziness to a target
--     that is already dizzy (Elementalism.wiki:242).
--   * magi_offense_tracking/005 wrote the st.hypothermia latch, which nothing reads since group M
--     (P3, P7 and `mm status` read hypothermia from V3).
--
-- Kept as it was, on purpose: the fire emanation gives two stacks, and V3 is given ONE application
-- (001's header says why). The last block drives the REAL tracker to show what a second would do.
--
-- The lines are rebuilt word for word from the old patterns (kb/ holds no capture of them). The
-- staff slot is filled with "an elemental staff" (kb's wording, Destroy: "You must be wielding an
-- elemental staff") and with "a primordial staff" (what these patterns named before 31595ff4
-- generalised them); the earth line's closing \w+ with "him", the hypothermia line's with "he".
-- Each line is delivered the way the server sends it -- whole, and wrapped at 100, 119 and 124
-- columns -- one row at a time through the trigger's REAL patterns; a next-row reader reads the
-- row after the one that armed it. The bodies run against a small affliction model behind the
-- public API (haveAff / tarAffed) and the REAL 004 (magi.offense.ptRelay and its state).
-- One shared Lua state: every global is restored at the end.

local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains   -- a Mudlet extension the last block may add; restored at the end

local TL = dofile("src_new/tests/trigger_lib.lua")
local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local MAGE = "src_new/scripts/levi_ataxia/levi/levi_scripts/mage/"
local ATAXIA = "src_new/scripts/levi_ataxia/levi/ataxia/"
local WIDTHS = { false, 100, 119, 124 }   -- false: the whole line on one row
local NAME, LONG, OTHER = "Xarthus", "Abcdefghijkl", "Someoneelse"
local STAFFS = { "an elemental staff", "a primordial staff" }

-- Fresh tables, so the loads below build their own and the restore drops them.
magi = nil
ataxia = { afflictions = {}, settings = {} }
ataxiaTemp, tAffs, affTimers = {}, {}, {}
target = NAME
partyrelay = false
gmcp = { Char = { Vitals = { charstats = {} } } }

-- A failed load is raised inside the protected block below, so the restore at the end still runs.
local loadErr
for _, f in ipairs({ MAGE .. "001_Resonance.lua", MAGE .. "004_Magi_Offense.lua" }) do
  local okLoad, errLoad = pcall(dofile, f)
  if not okLoad then loadErr = "Failed to load " .. f .. ": " .. tostring(errLoad); break end
end

-- Everything a body does, in order, with the row it did it on: tarAffed ("aff"), the party relay
-- ("relay"), cecho ("echo") and the highlight ("bg").
local row, log, has, tails = 0, {}, {}, {}
local function note(kind, data) log[#log + 1] = { kind = kind, row = row, data = data } end

haveAff = function(a) return has[a] == true end
tarAffed = function(...)
  for _, a in ipairs({ ... }) do has[a] = true; note("aff", a) end
end
erAff = function(a) has[a] = nil end
tempLineTrigger = function(from, n, fn) tails[#tails + 1] = { from = from, n = n, fn = fn }; return #tails end
selectCurrentLine, fg = function() end, function() end
bg = function(c) note("bg", c) end
cecho = function(s) note("echo", s) end
isTargeted = function(n) return n == target end

-- The real relay, watched: each body names what it recorded in it, once, on the row it acted on.
if not loadErr then
  local realRelay = magi.offense.ptRelay
  if type(realRelay) ~= "function" then loadErr = "004 defines no magi.offense.ptRelay" end
  magi.offense.ptRelay = function(msg) note("relay", msg); return realRelay(msg) end
end

local function world(affs)
  row, log, has, tails = 0, {}, {}, {}
  for _, a in ipairs(affs or {}) do has[a] = true end
  target = NAME
  local st = magi.offense.state
  st.burns, st.hypothermia = 0, false
  tburns = 0
  magi.calcifying_head = false
end

-- Entries of the log of one kind (and, if given, on one row).
local function logged(kind, onRow)
  local out = {}
  for _, e in ipairs(log) do
    if e.kind == kind and (onRow == nil or e.row == onRow) then out[#out + 1] = e end
  end
  return out
end
local function affsAdded()
  local out = {}
  for _, e in ipairs(logged("aff")) do out[#out + 1] = e.data end
  return out
end

-- The trigger's own regex as a Lua pattern, to fill `matches` the way Mudlet does. Only the shapes
-- these triggers use; anything else raises. `capture` checks it against trigger_lib on every row.
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

-- Mudlet's `matches` for the first of the trigger's patterns that matches `text`, or nil.
local function capture(pats, text)
  for _, p in ipairs(pats) do
    local hit = TL.matches(p.pat, p.type, text)
    local found = { text:find(luaPat(p.pat)) }
    assert(hit == (found[1] ~= nil), "trigger_lib and the Lua pattern disagree on: " .. text)
    if hit then
      local m = { text:sub(found[1], found[2]) }
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

local FIRE, AIR, EARTH = "enamation/001_Fire_Emanation.lua", "enamation/003_Air_Emanation.lua",
  "enamation/004_Earth_Emanation.lua"
local WATER, HYPO = "enamation/002_Water_Emanation.lua", "magi_offense_tracking/005_Hypothermia_1st_Person.lua"
local PATS, BODY = {}, {}   -- filled inside the protected block

-- Deliver `text` as the server would at `width` (false: one row), one row at a time. The trigger
-- runs on every row its patterns match; a next-row reader armed on one row reads the next. Returns
-- the first row the trigger fired on (or nil), how many rows it fired on, and the rows. Readers
-- armed on the LAST row are left in `tails`: one there would read whatever the game sends next.
local function deliver(file, text, width)
  local rows = width and TL.wrap(text, width) or { text }
  local first, fired = nil, 0
  tails = {}
  for i, r in ipairs(rows) do
    row, line = i, r
    local armed = tails
    tails = {}
    local m = capture(PATS[file], r)
    if m then
      matches = m
      first, fired = first or i, fired + 1
      BODY[file]()
    end
    for _, t in ipairs(armed) do
      assert(t.from == 1 and t.n == 1, "a next-row reader must read exactly the next row")
      t.fn()
    end
  end
  return first, fired, rows
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
local function wname(w) return w and ("@" .. w) or "whole" end

-- The lines, rebuilt from the old patterns: <S> is the staff, <T> the target.
local LINES = {
  [FIRE] = "The might of elemental Fire filling you like a scorching river, you lift <S> to point at <T> and"
    .. " unleash a stream of searing flame.",
  [AIR] = "You sweep <S> over your head and a great wind rises, picking up <T> and dashing them violently"
    .. " about before casting them back to the ground.",
  [EARTH] = "The might of elemental Earth thrumming within your bones, you point <S> at <T> and an intangible"
    .. " wave of power strikes forth to smite him.",
  [WATER] = "The might of elemental Water surging through your body, you make the slightest flick with <S>,"
    .. " and the hand of Sllshya descends as a freezing deluge to smash <T>.",
}
local function L(file, name, staff)
  return (LINES[file]:gsub("<S>", staff or STAFFS[1]):gsub("<T>", name))
end
local HYPO_LINE = "You blast <T> with an icy stream of water, and he begins to shiver uncontrollably."

-- The patterns these three triggers had until v4.7.420, as YAML joined their two folded lines.
local OLD = {
  [FIRE] = "^The might of elemental Fire filling you like a scorching river, you lift an? \\w+ staff to point at"
    .. " (\\w+) and unleash a stream of searing flame\\.$",
  [AIR] = "^You sweep an? \\w+ staff over your head and a great wind rises, picking up (\\w+) and dashing them"
    .. " violently about before casting them back to the ground\\.$",
  [EARTH] = "^The might of elemental Earth thrumming within your bones, you point an? \\w+ staff at (\\w+) and an"
    .. " intangible wave of power strikes forth to smite (\\w+)\\.$",
}

-- What each body records on our target, from a clean world.
local RECORDS = {
  [FIRE] = { affs = { "burning" }, relay = "Xarthus: Emanation Fire (burns 2/5)" },
  [AIR] = { affs = { "paralysis", "dizziness" }, relay = "Xarthus: Emanation Air (Paralysis + Dizziness)" },
  [EARTH] = { affs = {}, relay = "Xarthus: Emanation Earth (calcifying)" },
}
local THREE = { FIRE, AIR, EARTH }

-- Every row of a delivery carries the highlight.
local function unpainted(rows)
  local bad = {}
  for i = 1, #rows do
    if #logged("bg", i) == 0 then bad[#bad + 1] = i end
  end
  return bad
end

local ok, err = pcall(function()
if loadErr then error(loadErr, 0) end
for _, f in ipairs({ FIRE, AIR, EARTH, WATER, HYPO }) do PATS[f] = TL.patterns(TRG .. f) end
for _, f in ipairs({ FIRE, AIR, EARTH, HYPO }) do BODY[f] = body(f) end

describe("fire, air and earth emanations: an opening fragment, and the name read when the sentence closes", function()
  it("the old pattern matches each rebuilt line whole (so the rebuild is faithful), and so does the new", function()
    for _, f in ipairs(THREE) do
      for _, staff in ipairs(STAFFS) do
        local text = L(f, NAME, staff)
        expect(TL.matches(OLD[f], 1, text)).toBeTrue()
        expect(#PATS[f]).toBe(1)
        expect(PATS[f][1].type).toBe(1)
        expect(TL.matches(PATS[f][1].pat, 1, text)).toBeTrue()
      end
    end
  end)

  it("each fragment matches only its own emanation, on no row but the first", function()
    for _, f in ipairs(THREE) do
      for _, other in ipairs({ FIRE, AIR, EARTH, WATER }) do
        for _, w in ipairs(WIDTHS) do
          local rows = w and TL.wrap(L(other, LONG), w) or { L(other, LONG) }
          for i, r in ipairs(rows) do
            local hit = TL.anyMatches(PATS[f], r)
            if hit ~= (other == f and i == 1) then
              error(f .. " on " .. other .. " " .. wname(w) .. " row " .. i .. ": " .. tostring(hit))
            end
          end
        end
      end
    end
  end)

  it("fires on the FIRST row and records on the CLOSING row, whole and at 100, 119 and 124 columns", function()
    local bad = {}
    for _, f in ipairs(THREE) do
      for _, staff in ipairs(STAFFS) do
        for _, w in ipairs(WIDTHS) do
          for _, name in ipairs({ NAME, LONG }) do
            world()
            target = name
            local first, fired, rows = deliver(f, L(f, name, staff), w)
            local relays, last = logged("relay"), #rows
            local okAffs = same(affsAdded(), RECORDS[f].affs) and #logged("aff") == #logged("aff", last)
            local why
            if first ~= 1 or fired ~= 1 then why = "fired on row " .. tostring(first) .. " (" .. fired .. " rows)"
            elseif #relays ~= 1 or relays[1].row ~= last then why = #relays .. " relays, not one on row " .. last
            elseif relays[1].data ~= (RECORDS[f].relay:gsub("Xarthus", name)) then why = "relay " .. relays[1].data
            elseif not okAffs then why = "{" .. table.concat(affsAdded(), ", ") .. "}"
            elseif #unpainted(rows) > 0 then why = "row " .. unpainted(rows)[1] .. " not highlighted"
            elseif #tails ~= 0 then why = "a reader is left armed after the sentence closed"
            end
            if why then
              bad[#bad + 1] = f:match("/(%d+)") .. " " .. staff .. " " .. wname(w) .. " " .. name .. ": " .. why
            end
          end
        end
      end
    end
    if #bad > 0 then error(#bad .. " failed: " .. table.concat(bad, "; ")) end
  end)

  it("an emanation at someone else records nothing, but our own cast is still highlighted", function()
    for _, f in ipairs(THREE) do
      for _, w in ipairs(WIDTHS) do
        world()
        local first, _, rows = deliver(f, L(f, OTHER), w)
        local where = f .. " " .. wname(w)
        if first ~= 1 then error(where .. ": did not fire on row 1") end
        if #logged("aff") + #logged("relay") + #logged("echo") ~= 0 then error(where .. ": recorded on " .. OTHER) end
        if magi.offense.state.burns ~= 0 or tburns ~= 0 or magi.calcifying_head then error(where .. ": state changed") end
        if #unpainted(rows) > 0 or #tails ~= 0 then error(where .. ": highlight or reader wrong") end
      end
    end
  end)

  -- Not game text: the line cut where a 100-column row ends, then closed. The reader must stop at
  -- the full stop rather than stay armed for whatever the game sends next.
  it("a cast whose sentence closes without the name records nothing and leaves no reader armed", function()
    for _, f in ipairs(THREE) do
      world()
      local cut = TL.wrap(L(f, NAME), 100)[1] .. "."
      local first, _, rows = deliver(f, cut)
      if first ~= 1 then error(f .. ": did not fire on " .. cut) end
      if #logged("aff") + #logged("relay") ~= 0 then error(f .. ": recorded on " .. cut) end
      if #unpainted(rows) > 0 then error(f .. ": not highlighted") end
      if #tails ~= 0 then error(f .. ": a reader is left armed after '" .. cut .. "'") end
    end
  end)

  it("reproduces the bug: the old folded patterns matched no row at 100, 119 or 124 columns", function()
    for _, f in ipairs(THREE) do
      for _, w in ipairs({ 100, 119, 124 }) do
        for _, r in ipairs(TL.wrap(L(f, NAME), w)) do
          expect(TL.matches(OLD[f], 1, r)).toBeFalse()
        end
      end
    end
  end)
end)

describe("what each emanation records (Elementalism.wiki:242)", function()
  it("fire: two ablaze stacks -- two burns on the offense's counter, capped at 5, and ONE burning", function()
    for _, c in ipairs({ { 0, 2 }, { 1, 3 }, { 3, 5 }, { 4, 5 }, { 5, 5 } }) do
      for _, w in ipairs(WIDTHS) do
        world()
        magi.offense.state.burns = c[1]
        local _, _, rows = deliver(FIRE, L(FIRE, NAME), w)
        expectList(affsAdded(), { "burning" })
        expect(magi.offense.state.burns).toBe(c[2])
        expect(tburns).toBe(c[2])
        -- The counter is echoed onto the closing row and highlighted with it (painted after it).
        local echoes = logged("echo")
        expect(#echoes).toBe(1)
        expect(echoes[1].row).toBe(#rows)
        expect(echoes[1].data).toContain(c[2] .. "/5")
        expect(log[#log].kind).toBe("bg")
      end
    end
  end)

  it("air: paralysis and dizziness; asthma as well when the target is already dizzy", function()
    for _, w in ipairs(WIDTHS) do
      world()
      deliver(AIR, L(AIR, NAME), w)
      expectList(affsAdded(), { "paralysis", "dizziness" })
      expect(logged("relay")[1].data).toBe("Xarthus: Emanation Air (Paralysis + Dizziness)")

      world({ "dizziness" })
      deliver(AIR, L(AIR, NAME), w)
      expectList(affsAdded(), { "paralysis", "dizziness", "asthma" })
      expect(logged("relay")[1].data).toBe("Xarthus: Emanation Air (Paralysis + Asthma)")
    end
  end)

  it("earth: the calcifying flag and the relay, as before, and no affliction", function()
    for _, w in ipairs(WIDTHS) do
      world()
      deliver(EARTH, L(EARTH, NAME), w)
      expect(magi.calcifying_head).toBeTrue()
      expectList(affsAdded(), {})
      expect(#logged("relay")).toBe(1)
    end
  end)
end)

describe("005 hypothermia: the same afflictions, and no latch", function()
  it("records hypothermia and the freeze chain under it, as before", function()
    for _, w in ipairs(WIDTHS) do
      for _, name in ipairs({ NAME, LONG }) do
        world()
        target = name
        local first = deliver(HYPO, (HYPO_LINE:gsub("<T>", name)), w)
        expect(first).toBe(1)
        expectList(affsAdded(), { "hypothermia", "frozen", "shivering", "nocaloric" })
      end
    end
  end)

  it("no longer writes the st.hypothermia latch, which nothing reads", function()
    world()
    deliver(HYPO, (HYPO_LINE:gsub("<T>", NAME)))
    expect(#logged("aff")).toBe(4)
    expect(magi.offense.state.hypothermia).toBeFalse()
  end)

  it("records nothing for another name", function()
    world()
    expect(deliver(HYPO, (HYPO_LINE:gsub("<T>", OTHER)))).toBe(1)
    expect(#logged("aff")).toBe(0)
    expect(magi.offense.state.hypothermia).toBeFalse()
  end)
end)

-- LAST, because it swaps the affliction model above for the real thing: the REAL tracker (007,
-- 008), the REAL public API (017) and the REAL salve trigger (391). From a clean start, once the
-- target has applied mending to its body twice, no burning may be left. A second burning
-- application in 001 fails this: V3 never lowers a burning level of 2 on a mending, so that burning
-- would outlive every cure. Not asserted: after ONE mending V3 already reads no burning while a
-- stack may remain, and a burn already on the target takes V3's level past 1 whatever 001 records.
-- Both are V3's to fix (001's header); asserting them would pin them.
describe("fire: V3 holds one of the two stacks, so no burning outlives the mendings", function()
  it("after the emanation and two body mendings, the target reads no burning", function()
    -- The V3 files initialise these as `X = X or {...}`. Cleared first, the loads build fresh
    -- ones, and the restore at the end puts back, untouched, any an earlier test file left.
    for _, k in ipairs({ "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3",
      "targetBurningLevelV3", "affLastConfirmedV3", "targetDefensesV3", "cureBalancesV3",
      "cureBalanceTimerIDsV3", "passiveCooldownsV3", "negativeConfirmTimersV3", "tAffsV2", "tAffStacksV2" }) do
      _G[k] = nil
    end
    tAffs, affTimers = {}, {}
    for _, f in ipairs({ "017_Affliction_Management.lua", "curing/002_Wide_Groups.lua",
      "affliction_tracking_core/007_Branching_State_Tracker.lua", "affliction_tracking_core/008_V3_Integration.lua" }) do
      dofile(ATAXIA .. f)
    end
    -- What the loaded files do not provide. 017 registers "tar afflicted" by NAME, which the mock's
    -- raiseEvent cannot call, so events go nowhere.
    table.contains = table.contains or function(t, v)
      for _, x in pairs(t) do if x == v then return true end end
      return false
    end
    raiseEvent, checkTargetLocks, zgui = function() end, function() end, nil
    passiveFailsafe, onTargetSalveBodyV2, onTargetSalveSkinV2 = nil, nil, nil
    local salve = body("391_Applied_Body_Skin.lua")

    world()
    resetStatesV3()
    deliver(FIRE, L(FIRE, NAME))
    expect(magi.offense.state.burns).toBe(2)
    expect(haveAff("burning")).toBeTrue()
    for _ = 1, 2 do
      line = NAME .. " takes some salve from a vial and rubs it on his body."
      matches = { line, NAME, "body" }
      salve()
    end
    -- v4.7.430: the application line no longer lowers the counter (general/025's diminish line
    -- does, and none is delivered here); the round reads it as V3 does, through liveBurns.
    expect(magi.offense.state.burns).toBe(2)
    expect(magi.offense.liveBurns()).toBe(0)
    expect(haveAff("burning")).toBeFalse()
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
