--- test_magi_tracking.lua -- what our Magi triggers record, checked against the wiki and the game's
--- own records (the Tabethys cross-check, kb/raw/players/magi-tabethys-2026-10-12.txt)
--
-- What was wrong:
--   * 022: the moderate-earth (paralysis) and major-water (anorexia) lines -- the "par" and "ano"
--     of the mudslide bonk -- were anchored full lines of 148 and 128 columns with a seven-letter
--     name. This user's server wraps at 119-124, so they never matched; minor water failed for a
--     long name.
--   * 002 water emanation: its pattern was folded across two YAML lines (~180 columns), out of
--     tools/check_wrap.py's sight (kb/CONFLICTS.md #2), so the trigger never fired; and it never
--     recorded the emanation's stuttering.
--   * 021_Freeze recorded weariness and nausea FREEZE does not give, and ignored frostbite; 015
--     recorded a frozen DEHYDRATE does not give; 021_Spell_Outcomes added a burn per FULMINATE.
--   * a resonance blister expired on a bare 15 s timer that a repeat never cancelled and that
--     erased a NEW target's blister; 493 recorded a burning stack nothing names.
--   * P3 (004) cast glaciate on the hypothermia LATCH, without testing frozen.
--   * get_resonance matched the charstats keys case-sensitively and kept a plane whose entry was gone.
--
-- The lines are rebuilt word for word from the patterns (kb/ holds no capture of them); pronouns
-- fill the patterns' \w+ slots, and "an elemental staff" is the wording kb has for a Magi's staff
-- (Destroy: "You must be wielding an elemental staff"). Each line is delivered the way the server
-- sends it -- whole, and wrapped at 100, 119 and 124 columns -- one row at a time through the
-- trigger's REAL patterns. The bodies run against a small affliction model behind the public API
-- (haveAff / tarAffed / erAff), with the REAL ataxia_tarAffTimed (017) and the REAL 001 and 004.
-- One shared Lua state: every global is restored at the end.

local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains

local TL = dofile("src_new/tests/trigger_lib.lua")
local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local MAGE = "src_new/scripts/levi_ataxia/levi/levi_scripts/mage/"
local WIDTHS = { false, 100, 119, 124 }   -- false: the whole line on one row
local NAME, LONG = "Xarthus", "Abcdefghijkl"

-- Fresh tables, so the loads below build their own and the restore drops them.
magi = nil
ataxia = { afflictions = {}, settings = {} }
ataxiaTemp, tAffs, affTimers = {}, {}, {}
target = NAME
targetHealth = 100
partyrelay = false
gmcp = { Char = { Vitals = { charstats = {} } } }

-- A failed load is raised inside the protected block below, so the restore at the end still runs.
local loadErr
for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",   -- ataxia_tarAffTimed
  MAGE .. "001_Resonance.lua",
  MAGE .. "004_Magi_Offense.lua",
}) do
  local okLoad, errLoad = pcall(dofile, f)
  if not okLoad then loadErr = "Failed to load " .. f .. ": " .. tostring(errLoad); break end
end
local REAL_TARAFFED = tarAffed

-- table.contains is a Mudlet extension (the real tarAffed uses it); restored at the end.
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

-- A clock the tests move by hand. String callbacks are run too (the old blister timer was one).
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

-- The affliction model: the public API over one set. `added` and `erased` keep the order.
local has, added, erased, tails = {}, {}, {}, {}
haveAff = function(a) return has[a] == true end
tarAffed = function(...)
  for _, a in ipairs({ ... }) do has[a] = true; added[#added + 1] = a end
end
erAff = function(a) has[a] = nil; erased[#erased + 1] = a end
getAffProbabilityV3 = function(a) return has[a] and 1 or 0 end
tempLineTrigger = function(from, n, fn) tails[#tails + 1] = { from = from, n = n, fn = fn }; return #tails end
selectCurrentLine, fg, bg = function() end, function() end, function() end
isTargeted = function(n) return n == target end
ataxiaEcho = function() end

local function world(affs)
  has, added, erased, tails = {}, {}, {}, {}
  for _, a in ipairs(affs or {}) do has[a] = true end
  now, timers = 0, {}
  target = NAME
  ataxiaTemp = { tarAffTimers = {} }
  local st = magi.offense.state
  st.burns, st.scalded, st.scaldedTimer, st.hypothermia, st.conflagrated = 0, false, nil, false, false
  st.shalestorm, st.calcifiedTorso, st.mode = false, false, "fire"
  tburns = 0
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

-- Mudlet's `matches` for the first of the trigger's patterns that matches `row` (Mudlet fires an
-- OR-trigger on its first matching pattern), or nil.
local function capture(pats, row)
  for _, p in ipairs(pats) do
    local hit = TL.matches(p.pat, p.type, row)
    local found = { row:find(luaPat(p.pat)) }
    assert(hit == (found[1] ~= nil), "trigger_lib and the Lua pattern disagree on: " .. row)
    if hit then
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

local RES, EMAN, FREEZE = "general/022_Resonance_Afflictions.lua", "enamation/002_Water_Emanation.lua",
  "general/021_Freeze.lua"
local DEHYD, SPELLS, BLISTERS = "general/015_Dehydrate.lua", "general/021_Spell_Outcomes.lua", "493_Blisters.lua"
local FAN = "general/022_Increase_Burning.lua"
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

-- 022's twelve lines, each with what it gives (Elementalism.wiki:62).
local RESONANCE = {
  { "minor air", "<T> clutches at his throat as he gasps for breath.", "asthma" },
  { "moderate air", "A vicious wind rises, lashing and flaying at the body of <T> to leave him sensitive and raw.",
    "sensitivity" },
  { "major air", "A dreadful pallor overcomes the features of <T>.", "healthleech" },
  { "minor water", "As you begin to tap your connection with the Elemental Plane of Water, you summon up a"
    .. " freezing wave to deluge <T>.", "frostbite" },
  { "moderate water", "You summon up a flurry of icicles to slash at <T> in a shower of freezing daggers.",
    "stuttering" },
  { "major water", "The might of Elemental Water suffusing you, you tear at the vital fluids which sustain the"
    .. " body of <T> with your will alone.", "anorexia" },
  { "minor earth", "A loud crack emanates from the left leg of <T>.", "brokenleftleg" },
  { "moderate earth", "You bleed off residual power from your connection with the Elemental Plane of Earth,"
    .. " directing it in an unfocussed blast of arcane might at <T>.", "paralysis" },
  { "major earth", "The might of Elemental Earth coursing through you, you smite <T> with the full force of"
    .. " your directed will.", "crackedribs" },
  { "moderate fire", "You will that <T> should burn, and so he does.", "scalded" },
  { "major fire", "The incandescent might of Elemental Fire filling you, you command <T> to burn from within.",
    "blistered" },
  { "major fire, already blistered", "The incandescent might of Elemental Fire filling you, you command the"
    .. " suffering <T> to burn from within.", "burning" },
}
local MAJOR_FIRE = RESONANCE[11][2]
local EMANATION = "The might of elemental Water surging through your body, you make the slightest flick with an"
  .. " elemental staff, and the hand of Sllshya descends as a freezing deluge to smash <T>."

local ok, err = pcall(function()
if loadErr then error(loadErr, 0) end
for _, f in ipairs({ RES, EMAN, FREEZE, DEHYD, SPELLS, BLISTERS, FAN }) do
  PATS[f], BODY[f] = TL.patterns(TRG .. f), body(f)
end

describe("022 resonance: every line arrives in one piece or wrapped, and records its affliction", function()
  it("each line matches exactly one pattern, so the plane and level stay apart", function()
    for _, r in ipairs(RESONANCE) do
      local n = 0
      for _, p in ipairs(PATS[RES]) do
        if TL.matches(p.pat, p.type, T(r[2], NAME)) then n = n + 1 end
      end
      if n ~= 1 then error(r[1] .. " matched " .. n .. " patterns") end
    end
  end)

  it("fires on the FIRST row at 100, 119 and 124 columns, for a short and a long name", function()
    local bad = {}
    for _, r in ipairs(RESONANCE) do
      for _, w in ipairs(WIDTHS) do
        for _, name in ipairs({ NAME, LONG }) do
          world()
          target = name
          local first = deliver(RES, T(r[2], name), w)
          if first ~= 1 or not same(added, { r[3] }) then
            bad[#bad + 1] = r[1] .. " " .. wname(w) .. " " .. name .. " (row " .. tostring(first) .. ", {"
              .. table.concat(added, ", ") .. "})"
          end
        end
      end
    end
    if #bad > 0 then error(#bad .. " failed: " .. table.concat(bad, "; ")) end
  end)

  it("a discharge at someone else records nothing, even when the name is on the next row", function()
    for _, r in ipairs(RESONANCE) do
      for _, w in ipairs(WIDTHS) do
        world()
        deliver(RES, T(r[2], "Someoneelse"), w)
        if #added ~= 0 then error(r[1] .. " " .. wname(w) .. ": recorded " .. added[1] .. " on " .. target) end
      end
    end
  end)

  it("reproduces the bug: the old anchored patterns matched no row at the user's widths", function()
    local old = {
      "^You bleed off residual power from your connection with the Elemental Plane of Earth, directing it in an"
        .. " unfocussed blast of arcane might at (\\w+)\\.$",
      "^The might of Elemental Water suffusing you, you tear at the vital fluids which sustain the body of"
        .. " (\\w+) with your will alone\\.$",
    }
    for i, idx in ipairs({ 8, 6 }) do
      for _, w in ipairs({ 119, 124 }) do
        for _, row in ipairs(TL.wrap(T(RESONANCE[idx][2], NAME), w)) do
          expect(TL.matches(old[i], 1, row)).toBeFalse()
        end
      end
    end
  end)
end)

describe("a resonance blister (022) is on the shared clock: 15 s, no source", function()
  it("expires 15 s after the LAST blister: a second one restarts the clock", function()
    world()
    deliver(RES, T(MAJOR_FIRE, NAME))
    advance(10)
    expect(has.blistered).toBeTrue()
    deliver(RES, T(MAJOR_FIRE, NAME))
    advance(5)    -- 15 s after the first: the old uncancelled timer erased it here
    expect(has.blistered).toBeTrue()
    advance(10)
    expect(has.blistered).toBeNil()
    expectList(erased, { "blistered" })
  end)

  it("never erases a blister from a target we have switched to", function()
    world()
    deliver(RES, T(MAJOR_FIRE, NAME))
    target = "Someoneelse"
    advance(15)
    expect(#erased).toBe(0)
  end)
end)

describe("002 water emanation: a level of freeze, disrupted, AND stuttering", function()
  local cases = {
    { {}, { "nocaloric", "disrupted", "stuttering" } },                        -- insulation stripped
    { { "nocaloric" }, { "shivering", "disrupted", "stuttering" } },
    { { "nocaloric", "shivering" }, { "frozen", "disrupted", "stuttering" } },
  }
  it("fires on the first row and reads the name from the row that ends the sentence", function()
    local bad = {}
    for _, c in ipairs(cases) do
      for _, w in ipairs(WIDTHS) do
        for _, name in ipairs({ NAME, LONG }) do
          world(c[1])
          target = name
          local first = deliver(EMAN, T(EMANATION, name), w)
          if first ~= 1 or not same(added, c[2]) then
            bad[#bad + 1] = wname(w) .. " " .. name .. " (row " .. tostring(first) .. ", {"
              .. table.concat(added, ", ") .. "})"
          end
        end
      end
    end
    if #bad > 0 then error(#bad .. " failed: " .. table.concat(bad, "; ")) end
  end)

  it("an emanation at someone else records nothing", function()
    for _, w in ipairs(WIDTHS) do
      world()
      deliver(EMAN, T(EMANATION, "Someoneelse"), w)
      expect(#added).toBe(0)
    end
  end)
end)

describe("021_Freeze: one stage of the ladder, no weariness or nausea, and frostbite", function()
  local FREEZE_LINE = "You rip the heat from <T>."
  local function freeze(affs)
    world(affs)
    expect(deliver(FREEZE, T(FREEZE_LINE, NAME), 100)).toBe(1)
  end

  it("strips insulation, then shivers, then freezes; nothing else", function()
    freeze({}); expectList(added, { "nocaloric" })
    freeze({ "nocaloric" }); expectList(added, { "shivering" })
    freeze({ "nocaloric", "shivering" }); expectList(added, { "frozen" })
    freeze({ "nocaloric", "shivering", "frozen" }); expectList(added, {})
  end)

  it("frostbite and insulation: the strip AND the next stage, and the frostbite fades", function()
    freeze({ "frostbite" })
    expectList(added, { "nocaloric", "shivering" })
    expectList(erased, { "frostbite" })
    freeze({ "frostbite", "shivering" })
    expectList(added, { "nocaloric", "frozen" })
    expectList(erased, { "frostbite" })
  end)

  it("frostbite without insulation: an ordinary stage, and the frostbite stays", function()
    freeze({ "frostbite", "nocaloric" })
    expectList(added, { "shivering" })
    expect(#erased).toBe(0)
    expect(has.frostbite).toBeTrue()
  end)
end)

describe("015_Dehydrate: the wiki's three outcomes, and no frozen from weariness", function()
  local DEHYDRATE_LINE = "The skin of <T> begins to dry and crack as he grows pale."
  local function dehydrate(affs)
    world(affs)
    expect(deliver(DEHYD, T(DEHYDRATE_LINE, NAME), 100)).toBe(1)
  end

  it("weary, not nauseous: nausea, NOT frozen; the burning is left to the fan line", function()
    dehydrate({ "weariness" })
    expectList(added, { "nausea" })
    expect(has.frozen).toBeNil()
    expect(magi.offense.state.burns).toBe(0)
  end)

  it("the other outcomes (neither; nausea only; both)", function()
    dehydrate({}); expectList(added, { "weariness", "nausea" })
    dehydrate({ "nausea" }); expectList(added, { "weariness", "nocaloric" })   -- a stack of freeze
    dehydrate({ "weariness", "nausea" }); expectList(added, {})
    expect(magi.offense.state.burns).toBe(0)
  end)
end)

-- Tabethys's log (kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt, lines
-- 420-425): a dehydrate on a weary, nauseous target printed its line and then ONE fan line. Both
-- triggers counted it, so one stack read as two (kb/CONFLICTS.md, Resolved 2026-10-19).
describe("015 + 022_Increase_Burning: one dehydrate stack is one burn", function()
  local DEHYDRATE_LINE = "The skin of <T> begins to dry and crack as he grows pale."
  local FAN_LINE = "You fan the heat of <T>'s body into consuming flame."

  it("dehydrate then the fan line, weary + nauseous or weary only: burns go up by 1", function()
    for _, affs in ipairs({ { "weariness", "nausea" }, { "weariness" } }) do
      world(affs)
      expect(deliver(DEHYD, T(DEHYDRATE_LINE, NAME), 100)).toBe(1)   -- 015 did fire
      expect(deliver(FAN, T(FAN_LINE, NAME), 100)).toBe(1)
      expect(magi.offense.state.burns).toBe(1)
      expect(tburns).toBe(1)
    end
  end)

  it("a clean target: weariness + nausea, and no burn without a fan line", function()
    world()
    deliver(DEHYD, T(DEHYDRATE_LINE, NAME), 100)
    expect(magi.offense.state.burns).toBe(0)
    expect(has.weariness).toBeTrue()
    expect(has.nausea).toBeTrue()
  end)
end)

describe("021_Spell_Outcomes: fulminate gives no burn", function()
  local FULMINATE = "You click your fingers and lightning strikes from the air to smite <T>."
  local FIRELASH = "You form a lash of fire, and send it to scorch the flesh of <T>."

  it("leaves the burn counter alone, on a clean target and on one already burning", function()
    for _, w in ipairs(WIDTHS) do
      world()
      expect(deliver(SPELLS, T(FULMINATE, NAME), w)).toBe(1)
      expectList(added, { "fulminated" })
      expect(magi.offense.state.burns).toBe(0)
      expect(tburns).toBe(0)
    end
    world({ "fulminated" })
    magi.offense.state.burns = 2
    deliver(SPELLS, T(FULMINATE, NAME))
    expect(magi.offense.state.burns).toBe(2)
  end)

  it("keeps the chain: fulminated, then epilepsy, then paralysis", function()
    world({ "fulminated" }); deliver(SPELLS, T(FULMINATE, NAME)); expectList(added, { "epilepsy" })
    world({ "fulminated", "epilepsy" }); deliver(SPELLS, T(FULMINATE, NAME)); expectList(added, { "paralysis" })
  end)

  it("firelash still adds its burn", function()
    world()
    deliver(SPELLS, T(FIRELASH, NAME))
    expect(magi.offense.state.burns).toBe(1)
  end)
end)

describe("493 (Fire Lord) blisters: blistered only", function()
  it("no burning stack, the numeric burns counter untouched, and the event is raised", function()
    world()
    local events = {}
    local saved = { tarAffed, raiseEvent, checkTargetLocks, applyAffV3 }
    tarAffed, checkTargetLocks, applyAffV3 = REAL_TARAFFED, function() end, nil
    raiseEvent = function(e, a) events[#events + 1] = { e, a } end
    tAffs, affTimers = { burns = 3 }, {}
    local okRun, errRun = pcall(deliver, BLISTERS,
      "Bending the might of Kkractle upon the pitiful Xarthus, you command that he burn from within.", 100)
    tarAffed, raiseEvent, checkTargetLocks, applyAffV3 = saved[1], saved[2], saved[3], saved[4]
    if not okRun then error(errRun, 0) end
    expect(tAffs.blistered).toBeTrue()
    expect(tAffs.burns).toBe(3)
    expect(tAffs.burning).toBeNil()
    expect(#events).toBe(1)
    expect(events[1][1]).toBe("tar afflicted")
    expect(events[1][2][1]).toBe("blistered")
  end)
end)

describe("004 P3: glaciate needs a frozen target, and reads hypothermia from V3", function()
  local function pick(affs, latch, water)
    world(affs)
    magi.offense.state.hypothermia = latch
    magi.resonance.water, magi.resonance.air, magi.resonance.fire, magi.resonance.earth = water or 2, 2, 0, 0
    targetHealth = 100
    return magi.offense.selectSpell()
  end

  it("not on the latch alone, nor on hypothermia without frozen", function()
    expect(pick({}, true) ~= "cast glaciate at Xarthus").toBeTrue()                 -- both cured
    expect(pick({ "hypothermia" }, true) ~= "cast glaciate at Xarthus").toBeTrue()  -- frozen cured
  end)

  it("on frozen + hypothermia + water and air at 2 or more", function()
    expect(pick({ "frozen", "hypothermia" }, false)).toBe("cast glaciate at Xarthus")
    expect(pick({ "frozen", "hypothermia" }, true)).toBe("cast glaciate at Xarthus")
    expect(pick({ "frozen", "hypothermia" }, false, 1) ~= "cast glaciate at Xarthus").toBeTrue()
  end)

  it("keeps the order: a frozen target whose hypothermia was cured gets hypothermia first", function()
    expect(pick({ "frozen" }, true)).toBe("cast hypothermia at Xarthus")
  end)

  -- What `mm status` prints (magi.offense.status), caught from cecho/echo; both restored at once.
  local function statusText()
    local out, saved = {}, { cecho, echo }
    cecho = function(s) out[#out + 1] = s end
    echo = function(s) out[#out + 1] = s end
    local okS, errS = pcall(magi.offense.status)
    cecho, echo = saved[1], saved[2]
    if not okS then error(errS, 0) end
    return table.concat(out)
  end

  it("mm status shows hypothermia as P3 and P7 read it, not the latch", function()
    -- Cured while the latch still holds: P7 casts hypothermia again, so the status must say no.
    expect(pick({ "frozen" }, true)).toBe("cast hypothermia at Xarthus")
    expect(statusText()).toContain("Hypothermia: <dim_grey>no")
    pick({ "frozen", "hypothermia" }, false)
    expect(statusText()).toContain("Hypothermia: <dodger_blue>YES")
  end)
end)

describe("001 get_resonance: any case, and an absent plane reads 0", function()
  -- Every plane starts at `stale` (a value no assertion expects) unless `stale` is nil, which
  -- keeps the last read; nothing can pass by being left over.
  local function read(stats, stale)
    local r = magi.resonance
    if stale then r.air, r.fire, r.earth, r.water = stale, stale, stale, stale end
    gmcp.Char.Vitals.charstats = stats
    get_resonance()
    return r
  end

  it("reads a key in any case", function()
    local r = read({ "Rwater: Moderate", "rearth: minor" }, 3)
    expect(r.water).toBe(2)
    expect(r.earth).toBe(1)
    r = read({ "RFIRE: Major", "Rair: minor" }, 2)
    expect(r.fire).toBe(3)
    expect(r.air).toBe(1)
  end)

  it("a plane whose entry is absent reads 0, as does a missing charstats", function()
    local r = read({ "Rwater: Moderate", "rearth: minor" }, 3)
    expect(r.air).toBe(0)
    expect(r.fire).toBe(0)
    r = read({ "rearth: minor" })        -- water was 2 a read ago
    expect(r.water).toBe(0)
    expect(r.earth).toBe(1)
    r = read(nil)
    expect(r.earth).toBe(0)
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
