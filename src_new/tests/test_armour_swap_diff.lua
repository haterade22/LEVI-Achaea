--- test_armour_swap_diff.lua -- the armour swap asks the game first (v4.7.212, v4.7.323)
--
-- v4.7.212 taught the swap to pry only the embrasures that change, from `state.currentSlots`.
-- That state is runtime-only, so on a fresh session the swap knew nothing and rebuilt all three
-- blind; and it never knew what we OWN, so a profile naming a paragon we do not have pried the
-- old one out and left the embrasure empty (the v4.7.211 failure mode).
--
-- v4.7.323 (user: "we should be probing the armour to see what paragons we have and what we need
-- when we do armour pvp"): every swap sends `ii paragon` + `probe armour`, plans from the answers,
-- and probes again afterwards to verify.
--
-- These tests load the REAL script and call the real functions. The v4.7.212 version of this file
-- copied the planning logic into the test, and a copy cannot catch a regression in the original.

require("mock_mudlet")

ataxia = { settings = { separator = ";" } }
function ataxia_saveSettings() end

local SRC = "src_new/scripts/levi_ataxia/levi/levi_scripts/gear_system/002_Armour_Paragons.lua"
local TRIG = "src_new/triggers/levi_ataxia/for_levi/leviticus/gear_system/"

-- Timers and sends are captured for the whole file and restored at the end (test files share one
-- Lua state).
local realTempTimer, realSend = tempTimer, send
local timers, sent = {}, {}
tempTimer = function(delay, fn) timers[#timers + 1] = { delay = delay, fn = fn }; return #timers end
send = function(cmd) sent[#sent + 1] = cmd end

local ok, err = pcall(dofile, SRC)
if not ok then error("failed to load " .. SRC .. ": " .. tostring(err)) end
local A = ataxia.armour

local echoes = {}
A.echo = function(m) echoes[#echoes + 1] = tostring(m) end
A.save = function() end

-- Real ids from the user's probe (2026-09-19) and profiles.
local ICO, DELTA, CRUC = "paragon361796", "paragon424404", "paragon514466"
local METAL, AEN, SER = "paragon500167", "paragon417591", "paragon343178"

local function reset()
  timers, sent, echoes = {}, {}, {}
  A.config.paragons = {
    [ICO] = "icosagon (20% crit)", [DELTA] = "deltahedral (morphing)",
    [CRUC] = "crucious (crit multiplier)", [METAL] = "metalliferous (7.5% resist)",
    [AEN] = "aeneaous (absorption)", [SER] = "serendipitous (5% dmg->WP)",
  }
  A.config.paragonEffects = {}
  A.state.swapping = false
  A.state.currentSlots = {}
  A.state.slotsKnown = false
  A.state.embrasures = nil
  A.state.inventory = nil
  A.state.probing, A.state.scanning = false, false
  A.state.probeBuf, A.state.refreshCb = nil, nil
end

-- Run every pending timer with this delay, in the order they were armed.
local function fire(delay)
  local due = {}
  for i, t in ipairs(timers) do
    if t.delay == delay and not t.done then t.done = true; due[#due + 1] = t end
  end
  for _, t in ipairs(due) do t.fn() end
  return #due
end

-- Register extra paragons for the length of fn, and take them back out even if it throws.
local function withParagons(extra, fn)
  for id, name in pairs(extra) do A.config.paragons[id] = name end
  local ok, res = pcall(fn)
  for id in pairs(extra) do A.config.paragons[id] = nil end
  if not ok then error(res, 0) end
  return res
end

local function said(needle)
  for _, m in ipairs(echoes) do if m:find(needle, 1, true) then return true end end
  return false
end

local function sentHas(needle)
  for _, c in ipairs(sent) do if c:find(needle, 1, true) then return true end end
  return false
end

-- The user's probe, exactly as pasted.
local function feedProbe(lines)
  A.onProbeHeader("3")
  for _, ln in ipairs(lines) do A.onProbeLine(ln) end
  fire(0.5) -- PROBE_SETTLE
end
local USER_PROBE = {
  "1: an auspicious icosagon paragon (paragon361796)     critical level increase chance",
  "2: a nacreous deltahedral paragon (paragon424404)     morphing (level 3)",
  "3: a crucious paragon (paragon514466)     critical level gambling",
}

describe("reading `probe armour`", function()
  it("takes the user's probe as ground truth: ids, capacity, names and the game's effect text", function()
    reset()
    A.refresh(function() end, false)
    feedProbe(USER_PROBE)
    expect(A.state.slotsKnown).toBeTrue()
    expect(A.state.currentSlots[1]).toBe(ICO)
    expect(A.state.currentSlots[2]).toBe(DELTA)
    expect(A.state.currentSlots[3]).toBe(CRUC)
    expect(A.state.embrasures).toBe(3)
    expect(A.config.paragonEffects[ICO]).toBe("critical level increase chance")
    expect(A.config.paragonEffects[DELTA]).toBe("morphing (level 3)")
    expect(A.config.paragons[CRUC]:find("crucious", 1, true) ~= nil).toBeTrue()
  end)

  it("an embrasure the probe does not list -- or lists as 'Empty.' -- is empty, not what we believed", function()
    reset()
    A.state.currentSlots, A.state.slotsKnown = { ICO, DELTA, CRUC }, true
    A.refresh(function() end, false)
    feedProbe({ "1: an auspicious icosagon paragon (paragon361796)     critical level increase chance",
                "3: Empty." })
    expect(A.state.currentSlots[1]).toBe(ICO)
    expect(A.state.currentSlots[2]).toBeNil()
    expect(A.state.currentSlots[3]).toBeNil()
  end)

  it("ignores a probe we did not send -- it may be some other armour", function()
    reset()
    A.onProbeHeader("3")
    A.onProbeLine(USER_PROBE[1])
    fire(0.5)
    expect(A.state.slotsKnown).toBeFalse()
    expect(A.state.currentSlots[1]).toBeNil()
  end)

  it("slot lines without the embrasure header are still a snapshot", function()
    reset()
    A.refresh(function() end, false)
    for _, ln in ipairs(USER_PROBE) do A.onProbeLine(ln) end
    fire(0.5)
    expect(A.state.slotsKnown).toBeTrue()
    expect(A.state.currentSlots[3]).toBe(CRUC)
  end)

  it("a probe with no answer times out and says so", function()
    reset()
    local result
    A.refresh(function(r) result = r end)
    expect(fire(3)).toBe(1) -- PROBE_TIMEOUT
    expect(result).toBeFalse()
    expect(A.state.probing).toBeFalse()
    expect(A.state.scanning).toBeFalse()
  end)

  it("refresh asks for both the inventory and the armour", function()
    reset()
    A.refresh(function() end)
    expect(sentHas("ii paragon")).toBeTrue()
    expect(sentHas("probe armour")).toBeTrue()
    A.onInventoryParagon(AEN, "an aeneaous paragon")
    expect(A.state.inventory[AEN]).toBeTrue()
  end)
end)

describe("the plan: only what changes, only what we can supply", function()
  local plan = function(...) return A.planSwap(...) end

  it("one slot differing produces exactly one pry and one insert", function()
    local p = plan({ ICO, METAL, SER }, { ICO, METAL, CRUC }, true)
    expect(#p.cmds).toBe(2)
    expect(p.cmds[1]).toBe("pry armour embrasure 3")
    expect(p.cmds[2]).toBe("insert " .. SER .. " into armour embrasure 3")
  end)

  it("an identical profile sends NOTHING", function()
    expect(#plan({ ICO, METAL, CRUC }, { ICO, METAL, CRUC }, true).cmds).toBe(0)
  end)

  it("an id and a bare NAME for one paragon are not a change", function()
    expect(#plan({ "metalliferous", ICO, CRUC }, { METAL, ICO, CRUC }, true).cmds).toBe(0)
  end)

  it("unknown contents: every slot is rebuilt -- never skipped on an assumption", function()
    local p = plan({ ICO, METAL, SER }, {}, false)
    expect(#p.cmds).toBe(6)
    expect(p.cmds[1]).toBe("pry armour embrasure 1")
  end)

  it("a KNOWN-empty slot is filled without a pointless pry", function()
    local p = plan({ ICO, METAL, SER }, { ICO, METAL, nil }, true)
    expect(#p.cmds).toBe(1)
    expect(p.cmds[1]).toBe("insert " .. SER .. " into armour embrasure 3")
  end)

  it("clearing a slot pries without inserting", function()
    local p = plan({ ICO, METAL }, { ICO, METAL, CRUC }, true)
    expect(#p.cmds).toBe(1)
    expect(p.cmds[1]).toBe("pry armour embrasure 3")
  end)

  -- The old loop said "pry all first" and interleaved pry/insert per slot, so a paragon could
  -- not move between embrasures: its insert went out before the pry that freed it.
  it("pries everything before inserting anything, so a paragon can move", function()
    local p = plan({ CRUC, ICO, DELTA }, { ICO, CRUC, DELTA }, true, {})
    expect(#p.cmds).toBe(4)
    expect(p.cmds[1]).toBe("pry armour embrasure 1")
    expect(p.cmds[2]).toBe("pry armour embrasure 2")
    expect(p.cmds[3]).toBe("insert " .. CRUC .. " into armour embrasure 1")
    expect(p.cmds[4]).toBe("insert " .. ICO .. " into armour embrasure 2")
  end)

  it("a paragon we do not have leaves its embrasure ALONE -- never emptied", function()
    local p = plan({ METAL, DELTA, AEN }, { ICO, DELTA, CRUC }, true, { [AEN] = true })
    expect(#p.missing).toBe(1)
    expect(p.missing[1]).toBe(1)
    for _, c in ipairs(p.cmds) do expect(c:find("embrasure 1", 1, true)).toBeNil() end
    expect(p.cmds[1]).toBe("pry armour embrasure 3")
    expect(p.cmds[2]).toBe("insert " .. AEN .. " into armour embrasure 3")
    expect(p.after[1]).toBe(ICO) -- kept
  end)

  -- Keeping one slot can take away the paragon another was counting on.
  it("resolves the knock-on: a kept paragon is not there for another slot", function()
    -- slot 1 wants METAL (we have none) and holds ICO; slot 2 wants ICO.
    local p = plan({ METAL, ICO, CRUC }, { ICO, SER, CRUC }, true, {})
    expect(#p.missing).toBe(2)
    expect(#p.cmds).toBe(0)
  end)

  -- A profile is a list of TYPES: any paragon of that type we hold will do -- inserted by the id
  -- `ii paragon` showed for it.
  it("inserts the paragon of that type we HOLD, by its id", function()
    local SPARE_AEN = "paragon999999"
    local p = withParagons({ [SPARE_AEN] = "aeneaous (absorption)" }, function()
      return plan({ ICO, DELTA, AEN }, { ICO, DELTA, CRUC }, true, { [SPARE_AEN] = true })
    end)
    expect(p.cmds[2]).toBe("insert " .. SPARE_AEN .. " into armour embrasure 3")
  end)

  -- v4.7.326, the user's log: "insert icosagon" / "insert metalliferous" -> "That is not a valid
  -- paragon." with both in the inventory, after the pry had already emptied embrasure 2.
  it("never sends the bare type word when the inventory shows an id (the live failure)", function()
    local inv = { [SER] = true, [DELTA] = true, [ICO] = true, [METAL] = true } -- the user's `ii paragon`
    for _, slots in ipairs({ { ICO, METAL, CRUC }, { "icosagon", "metalliferous", "crucious" } }) do
      local p = plan(slots, { nil, AEN, CRUC }, true, inv)
      expect(#p.cmds).toBe(3)
      expect(p.cmds[1]).toBe("pry armour embrasure 2")
      expect(p.cmds[2]).toBe("insert " .. ICO .. " into armour embrasure 1")
      expect(p.cmds[3]).toBe("insert " .. METAL .. " into armour embrasure 2")
    end
  end)

  it("with no inventory answer, a slot naming an id inserts THAT id, not another of its type", function()
    local p = withParagons({ ["paragon100000"] = "icosagon (20% crit)" }, function() -- a second, lower id
      return plan({ ICO }, { nil }, true, nil)
    end)
    expect(p.cmds[1]).toBe("insert " .. ICO .. " into armour embrasure 1")
  end)

  it("with no inventory answer, a named slot uses a registered id of that type", function()
    local p = plan({ "icosagon" }, { nil }, true, nil)
    expect(p.cmds[1]).toBe("insert " .. ICO .. " into armour embrasure 1")
  end)

  -- idForType's choice is pinned: the LOWEST id by number, so it is the same every time.
  it("with two of a type registered, a named slot takes the lowest id", function()
    local p = withParagons({ ["paragon999998"] = "icosagon (20% crit)" }, function()
      return plan({ "icosagon" }, { nil }, true, nil)
    end)
    expect(p.cmds[1]).toBe("insert " .. ICO .. " into armour embrasure 1")
  end)

  it("lowest by NUMBER, not by spelling: paragon99999 comes before paragon361796", function()
    local p = withParagons({ ["paragon99999"] = "icosagon (20% crit)" }, function()
      return plan({ "icosagon" }, { nil }, true, nil)
    end)
    expect(p.cmds[1]).toBe("insert paragon99999 into armour embrasure 1")
  end)

  -- The review's case: the registry's icosagon may be the one sitting in an embrasure we keep, and
  -- the game cannot insert a paragon that is still in the armour.
  it("never picks a paragon still sitting in an embrasure this swap keeps", function()
    local SPARE = "paragon999998"
    local p = withParagons({ [SPARE] = "icosagon (20% crit)" }, function()
      return plan({ ICO, "icosagon" }, { ICO, AEN }, true, nil)
    end)
    expect(p.rows[1].action).toBe("keep")
    expect(p.cmds[#p.cmds]).toBe("insert " .. SPARE .. " into armour embrasure 2")
    -- ...but one coming OUT of an embrasure this swap is free to move
    local q = plan({ "crucious", "icosagon" }, { ICO, CRUC }, true, nil)
    expect(q.cmds[3]).toBe("insert " .. CRUC .. " into armour embrasure 1")
    expect(q.cmds[4]).toBe("insert " .. ICO .. " into armour embrasure 2")
  end)

  -- The unknown-contents branch pries all three, so a refused bare word there empties the
  -- embrasure -- and the seeded default profiles are all type words.
  it("contents UNKNOWN, no inventory: a type-word profile still inserts registered ids", function()
    local p = plan({ "icosagon", "metalliferous", "crucious" }, {}, false, nil)
    expect(#p.cmds).toBe(6)
    expect(p.cmds[4]).toBe("insert " .. ICO .. " into armour embrasure 1")
    expect(p.cmds[5]).toBe("insert " .. METAL .. " into armour embrasure 2")
    expect(p.cmds[6]).toBe("insert " .. CRUC .. " into armour embrasure 3")
  end)

  it("a profile written in names works the same as one written in ids", function()
    local p = plan({ "metalliferous", "deltahedral", "aeneaous" }, { ICO, DELTA, CRUC }, true,
      { [METAL] = true, [AEN] = true })
    expect(#p.cmds).toBe(4)
    expect(p.cmds[3]).toBe("insert " .. METAL .. " into armour embrasure 1")
    expect(p.cmds[4]).toBe("insert " .. AEN .. " into armour embrasure 3")
  end)

  it("only a paragon of a type we do not recognise falls back to its id", function()
    local p = plan({ "paragon123456" }, {}, false)
    expect(p.cmds[#p.cmds]).toBe("insert paragon123456 into armour embrasure 1")
    -- ...and with the inventory known, an unresolvable id is simply not something we hold
    local q = plan({ "paragon123456", DELTA, CRUC }, { ICO, DELTA, CRUC }, true, { [AEN] = true })
    expect(q.missing[1]).toBe(1)
    expect(#q.cmds).toBe(0)
  end)

  it("a slot the armour does not have is skipped and reported", function()
    local p = plan({ ICO, DELTA, AEN }, { ICO, DELTA }, true, { [AEN] = true }, 2)
    expect(#p.cmds).toBe(0)
    expect(p.rows[3].action).toBe("noslot")
  end)

  it("with no inventory answer it inserts as asked, like before", function()
    local p = plan({ METAL, DELTA, CRUC }, { ICO, DELTA, CRUC }, true, nil)
    expect(p.cmds[2]).toBe("insert " .. METAL .. " into armour embrasure 1")
  end)
end)

describe("armour <profile> probes, plans, swaps and verifies", function()
  local function pvp() A.config.profiles.pvp = { slots = { METAL, DELTA, AEN }, traits = {} } end

  it("the user's armour into the pvp profile: swaps what it can, reports what it needs", function()
    reset(); pvp()
    A.swap("pvp")
    expect(sentHas("ii paragon")).toBeTrue()
    expect(sentHas("probe armour")).toBeTrue()
    A.onInventoryParagon(AEN, "an aeneaous paragon")   -- no metalliferous in the inventory
    feedProbe(USER_PROBE)
    sent = {}
    fire(2)
    expect(sentHas("pry armour embrasure 3;insert " .. AEN .. " into armour embrasure 3")).toBeTrue()
    expect(sentHas("embrasure 1")).toBeFalse()          -- icosagon stays in: we have no metalliferous
    expect(said("NEED metalliferous")).toBeTrue()
    expect(A.state.swapping).toBeFalse()
    -- ...then it probes again and checks
    sent = {}
    fire(1.5)
    expect(sentHas("probe armour")).toBeTrue()
    expect(sentHas("ii paragon")).toBeFalse()
    feedProbe({ USER_PROBE[1], USER_PROBE[2], "3: an aeneaous paragon (paragon417591)     absorption" })
    expect(said("Verified")).toBeTrue()
  end)

  it("says so when the verification probe disagrees", function()
    reset(); pvp()
    A.swap("pvp")
    A.onInventoryParagon(AEN, "an aeneaous paragon")
    feedProbe(USER_PROBE)
    fire(2)
    fire(1.5)
    feedProbe(USER_PROBE) -- the insert did not take: crucious still in slot 3
    expect(said("did not fully take")).toBeTrue()
  end)

  -- v4.7.326 review: a swap planned without an answer pries blind, and a pry whose insert is then
  -- refused is how v4.7.323 left embrasures EMPTY. No answer now means no pries and no inserts.
  it("no probe answer on a fresh session: nothing is pried or inserted, and it says so", function()
    reset()
    A.config.profiles.words = { slots = { "icosagon", "metalliferous", "crucious" }, traits = { "x" } }
    local ok, err = pcall(function()
      A.swap("words")
      expect(sentHas("trait select x confirm")).toBeTrue() -- the traits still went
      fire(3) -- the refresh times out
      sent = {}
      fire(2)
      expect(sentHas("pry")).toBeFalse()
      expect(sentHas("insert")).toBeFalse()
      expect(said("No answer from the armour probe")).toBeTrue()
      expect(A.state.swapping).toBeFalse()
      expect(fire(1.5)).toBe(0) -- nothing to verify
    end)
    A.config.profiles.words = nil
    if not ok then error(err, 0) end
  end)

  it("an old picture of the armour is not an answer: still no swap", function()
    reset(); pvp()
    A.state.currentSlots, A.state.slotsKnown = { ICO, DELTA, CRUC }, true -- from an earlier swap
    A.swap("pvp")
    fire(3) -- no answer
    sent = {}
    fire(2)
    expect(#sent).toBe(0)
    expect(said("NEED")).toBeFalse()
    expect(A.state.currentSlots[1]).toBe(ICO) -- the picture is not rewritten either
  end)

  it("nothing to change sends nothing and does not verify", function()
    reset()
    A.config.profiles.same = { slots = { ICO, DELTA, CRUC }, traits = {} }
    A.swap("same")
    feedProbe(USER_PROBE)
    sent = {}
    fire(2)
    expect(#sent).toBe(0)
    expect(said("nothing to swap")).toBeTrue()
    expect(fire(1.5)).toBe(0)
  end)
end)

describe("armour probe [profile] and armour scan", function()
  it("probe <profile> is a dry run: it reports, it never pries", function()
    reset()
    A.config.profiles.pvp = { slots = { METAL, DELTA, AEN }, traits = {} }
    A.dispatch("probe pvp")
    A.onInventoryParagon(AEN, "an aeneaous paragon")
    feedProbe(USER_PROBE)
    expect(said("NEED metalliferous")).toBeTrue()
    expect(sentHas("pry")).toBeFalse()
    expect(sentHas("insert")).toBeFalse()
  end)

  it("scan registers what is IN the armour, which `ii paragon` never lists", function()
    reset()
    A.config.paragons = {}
    A.scan()
    expect(sentHas("ii paragon")).toBeTrue()
    expect(sentHas("probe armour")).toBeTrue()
    feedProbe(USER_PROBE)
    expect(A.config.paragons[ICO] ~= nil).toBeTrue()
    expect(said("3 in the armour")).toBeTrue()
  end)
end)

describe("default profiles", function()
  it("are written in paragon NAMES, so they work on any character", function()
    local saved = A.config.profiles
    A.config.profiles = {}
    local ok, err = pcall(A.seedDefaults)
    local seeded = A.config.profiles
    A.config.profiles = saved
    if not ok then error(err, 0) end
    local n = 0
    for _, prof in pairs(seeded) do
      for _, s in ipairs(prof.slots or {}) do
        n = n + 1
        expect(A.PARAGON_TYPES[s] ~= nil).toBeTrue()
      end
    end
    expect(n > 0).toBeTrue()
  end)
end)

describe("the triggers hand the lines to the module", function()
  local function src(name)
    local f = io.open(TRIG .. name); local s = f:read("*a"); f:close(); return s
  end
  it("002 reads paragon AND empty embrasure lines", function()
    local s = src("002_Armour_Probe.lua")
    expect(s:find("- pattern: ^(\\d+): Empty\\.", 1, true) ~= nil).toBeTrue()
    expect(s:find("ataxia.armour.onProbeLine(line)", 1, true) ~= nil).toBeTrue()
  end)
  it("003 opens the snapshot on the embrasure-count header", function()
    local s = src("003_Armour_Probe_Header.lua")
    expect(s:find("- pattern: ^This armour has (\\d+) embrasures?\\.$", 1, true) ~= nil).toBeTrue()
    expect(s:find("ataxia.armour.onProbeHeader(matches[2])", 1, true) ~= nil).toBeTrue()
  end)
  it("001 feeds the inventory", function()
    expect(src("001_Paragon_Inventory.lua"):find("ataxia.armour.onInventoryParagon(matches[2], matches[3])", 1, true) ~= nil).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
tempTimer, send = realTempTimer, realSend
ataxia = nil
