--- test_bash_balance_echo.lua -- the bash console shows the recovery time (v4.7.423)
--
-- User: "When bashing I cannot see my EQ recover (time)". The bash console's "Got equilibrium!" and
-- "Got limb balance!" lines carried no time, and the equilibrium line sat behind the 1s throttle
-- that dedupes the two limb-balance lines, so a balance line just before it swallowed it. The time
-- comes from the 014_Balance_Timers stopwatches, read before the recovery trigger stops them.

require("mock_mudlet")

local _saved = {
  cecho = cecho, getStopWatchTime = getStopWatchTime, zgui = zgui, ataxiagui = ataxiagui,
  target = target, ataxiaBasher = ataxiaBasher, ataxia = ataxia, bashBalSub = bashBalSub,
  ataxia_gotbal = ataxia_gotbal, tempTimer = tempTimer, deleteFull = deleteFull,
  eqStarted = ataxiaEQStopwatchStarted, eqId = ataxiaEQStopwatch,
  balStarted = ataxiaBalStopwatchStarted, balId = ataxiaBalStopwatch,
}

local shown, watchTime = {}, 2.314
cecho = function(win, text) shown[#shown + 1] = { win = win, text = text } end
getStopWatchTime = function() return watchTime end
zgui = true

dofile("src_new/scripts/levi_ataxia/levi/ataxia/014_Balance_Timers.lua")

local function reset()
  shown = {}
  ataxiaEQStopwatchStarted, ataxiaEQStopwatch = true, 7
  ataxiaBalStopwatchStarted, ataxiaBalStopwatch = true, 8
end

local function runTrigger(path, stubs)
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a"); fh:close()
  local chunk = assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
  local saved = {}
  for k, v in pairs(stubs) do saved[k] = _G[k]; _G[k] = v end
  local ok, err = pcall(chunk)
  for k in pairs(stubs) do _G[k] = saved[k] end
  if not ok then error(err) end
end

describe("bash console recovery time", function()
  it("reads a running stopwatch without stopping it", function()
    reset()
    expect(ataxia_balWatchText("eq")).toBe("2.31s")
    expect(ataxia_balWatchText("bal")).toBe("2.31s")
  end)

  it("is empty when no stopwatch is running", function()
    reset(); ataxiaEQStopwatchStarted = false
    expect(ataxia_balWatchText("eq")).toBe("")
    reset(); ataxiaBalStopwatch = nil
    expect(ataxia_balWatchText("bal")).toBe("")
  end)

  it("puts the time on the console line, and leaves it off when there is none", function()
    reset()
    ataxia_bashBalEcho("Got equilibrium!", "eq")
    expect(shown[1].win).toBe("bashDisplay")
    expect(shown[1].text).toBe("\n<yellow>BAL| <goldenrod>Got equilibrium! <white>(2.31s)")
    ataxiaEQStopwatchStarted = false
    ataxia_bashBalEcho("Got equilibrium!", "eq")
    expect(shown[2].text).toBe("\n<yellow>BAL| <goldenrod>Got equilibrium!")
  end)

  it("the EQ trigger prints the time while bashing, even right after a balance line", function()
    reset()
    target = 1234
    ataxiaBasher = { enabled = true, manual = false }
    ataxia = { afflictions = {} }
    bashBalSub = 99 -- a limb-balance line printed less than 1s ago
    runTrigger("src_new/triggers/levi_ataxia/for_levi/leviticus/balances/007_EQ.lua", {
      deleteFull = function() end, ataxia_gotbal = function() end,
    })
    expect(#shown).toBe(1)
    expect(shown[1].text).toBe("\n<yellow>BAL| <goldenrod>Got equilibrium! <white>(2.31s)")
  end)
end)

cecho, getStopWatchTime, zgui, ataxiagui = _saved.cecho, _saved.getStopWatchTime, _saved.zgui, _saved.ataxiagui
target, ataxiaBasher, ataxia, bashBalSub = _saved.target, _saved.ataxiaBasher, _saved.ataxia, _saved.bashBalSub
ataxiaEQStopwatchStarted, ataxiaEQStopwatch = _saved.eqStarted, _saved.eqId
ataxiaBalStopwatchStarted, ataxiaBalStopwatch = _saved.balStarted, _saved.balId
