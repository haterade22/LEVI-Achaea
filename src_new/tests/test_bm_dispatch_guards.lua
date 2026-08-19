--- test_bm_dispatch_guards.lua -- Blademaster dispatch visibility and retry (v4.7.275)
--
-- From the 2026-08-19 Grulk (Sentinel) log: 89 dispatch attempts produced 10 outbound actions.
-- Every guard in blademaster.run/sendAttack returned in silence, and the "[BM ...] Target:"
-- status block prints BEFORE the send -- so the screen reported "6 hits to leg double-break"
-- 89 times while nothing left the client. Working out which guard ate which press took two
-- passes over 2,819 lines of log.
--
-- These cover the three things added to stop that recurring: the suppression echo, the bounded
-- prompt retry, and the mode-flap warning.

require("mock_mudlet")
local mock = require("mock_mudlet")

target = "Grulk"
ataxia = { settings = { separator = ";" }, vitals = {}, afflictions = {}, defences = {},
           playersHere = { "Grulk" } }
ataxiaTemp = { class = "Blademaster" }
tAffs = {}
lb = { Grulk = { hits = {} } }
gmcp = { Char = { Vitals = { bal = "1", eq = "1", charstats = {} },
                  Status = { class = "Blademaster" } } }

function affed(what) return ataxia.afflictions[what] end
function ataxia_paused() return false end
function ataxia_isClass(c) return c:lower() == "blademaster" end
function canBals() return ataxia.vitals.bal and ataxia.vitals.eq end
function haveAff() return false end
function combatQueue() return "" end
function ataxia_needLockBreak() return false end
function ataxia_lockBreak() end
function ataxia_canActive() return true end

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/levi_scripts/blademaster/005_CC_BM_Ice.lua")
if not ok then error("Failed to load blademaster/005_CC_BM_Ice.lua") end

local function reset()
  mock.reset()
  ataxia.afflictions = {}
  ataxia.vitals = { bal = true, eq = true }
  ataxia.playersHere = { "Grulk" }
  lb.Grulk.hits = {}
  target = "Grulk"
  blademaster.state.attackInFlight = false
  blademaster.state.lastManualAt = nil
  blademaster.state.lastSuppressAt = nil
  blademaster.state.lastSuppressReason = nil
  blademaster.state.autoRetry = true
  blademaster.state.mode = "double"
end

local function echoed(needle)
  for _, e in ipairs(mock.echoed_lines or {}) do
    if type(e) == "string" and e:find(needle, 1, true) then return true end
  end
  return false
end

describe("blademaster.suppressed -- the silence that cost two hours of forensics", function()
  it("echoes the reason", function()
    reset()
    blademaster.suppressed("target not here")
    expect(echoed("target not here")).toBe(true)
  end)

  -- Debounced per-REASON rather than globally: repeated identical suppressions collapse, but a
  -- CHANGE of reason is the transition worth seeing and must always print.
  it("collapses an identical repeat", function()
    reset()
    blademaster.suppressed("same")
    local n = #mock.echoed_lines
    blademaster.suppressed("same")
    expect(#mock.echoed_lines).toBe(n)
  end)

  it("still prints when the reason CHANGES", function()
    reset()
    blademaster.suppressed("first")
    local n = #mock.echoed_lines
    blademaster.suppressed("second")
    expect(#mock.echoed_lines > n).toBe(true)
  end)
end)

describe("blademaster.retryTick -- bounded by the last MANUAL press", function()
  it("does nothing before any keypress", function()
    reset()
    blademaster.retryTick()
    expect(#mock.sent_commands).toBe(0)
  end)

  -- The window is anchored to markManual, not to the last run, so the loop cannot sustain
  -- itself: press once and we keep swinging, stop pressing and it stops on its own.
  it("fires inside the window after a manual press", function()
    reset()
    blademaster.markManual()
    blademaster.retryTick()
    expect(#mock.sent_commands > 0).toBe(true)
  end)

  it("stands down once the window has expired", function()
    reset()
    blademaster.markManual()
    blademaster.state.lastManualAt = blademaster.state.lastManualAt - (blademaster.config.retryWindow + 5)
    blademaster.retryTick()
    expect(#mock.sent_commands).toBe(0)
  end)

  it("stands down when switched off", function()
    reset()
    blademaster.markManual()
    blademaster.state.autoRetry = false
    blademaster.retryTick()
    expect(#mock.sent_commands).toBe(0)
  end)

  it("does not stack on an attack already in flight", function()
    reset()
    blademaster.markManual()
    blademaster.state.attackInFlight = true
    blademaster.retryTick()
    expect(#mock.sent_commands).toBe(0)
  end)

  -- The states where `queue addclear freestand` could never execute anyway. Re-queueing into
  -- them just replaces the entry that was already waiting.
  it("stands down while prone, paralysed or under aeon", function()
    for _, aff in ipairs({ "prone", "paralysis", "aeon" }) do
      reset()
      blademaster.markManual()
      ataxia.afflictions[aff] = true
      blademaster.retryTick()
      expect(#mock.sent_commands).toBe(0)
    end
  end)

  it("stands down with no target", function()
    reset()
    blademaster.markManual()
    target = ""
    blademaster.retryTick()
    expect(#mock.sent_commands).toBe(0)
    target = "Grulk"
  end)
end)

describe("blademaster.warnModeFlap -- prep abandoned by a mid-fight mode switch", function()
  it("is quiet with nothing on the board", function()
    reset()
    blademaster.warnModeFlap("quad")
    expect(echoed("decays back to 0")).toBe(false)
  end)

  it("is quiet when the mode is unchanged", function()
    reset()
    lb.Grulk.hits["left arm"] = 30.2
    blademaster.warnModeFlap("double")
    expect(echoed("decays back to 0")).toBe(false)
  end)

  -- The exact 2026-08-19 shape: two productive arm swings to 30.2/30.2, then a switch back to
  -- leg prep that abandoned them.
  it("warns when switching away with prep accumulated", function()
    reset()
    blademaster.state.mode = "quad"
    lb.Grulk.hits["left arm"] = 30.2
    lb.Grulk.hits["right arm"] = 30.2
    blademaster.warnModeFlap("double")
    expect(echoed("decays back to 0")).toBe(true)
  end)
end)

describe("blademaster.onTargetDefenceUp -- recalling a committed swing", function()
  it("does nothing when no attack is in flight", function()
    reset()
    blademaster.onTargetDefenceUp("Rebounding")
    expect(#mock.sent_commands).toBe(0)
  end)

  -- addclear REPLACES rather than appends, so one command is the whole correction. A whiffed
  -- raze costs the swing; eating the rebound cost the swing, 615 damage and a self-broken arm.
  it("replaces the pending swing with a raze", function()
    reset()
    blademaster.state.attackInFlight = true
    blademaster.onTargetDefenceUp("Rebounding")
    expect(table.concat(mock.sent_commands, "|"):find("raze Grulk") ~= nil).toBe(true)
  end)

  it("does nothing once the target has left the room", function()
    reset()
    blademaster.state.attackInFlight = true
    ataxia.playersHere = {}
    blademaster.onTargetDefenceUp("Shield")
    expect(#mock.sent_commands).toBe(0)
  end)
end)
