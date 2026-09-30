--- test_glass_lily.lua -- DROP LILY every hour (v4.7.367)
--
-- User: "We need to DROP LILY every hour." The hour is counted from the game's drop line, not from
-- the command, so a drop that never happened is retried instead of waiting out the hour.

local mock = require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

function ataxiaEcho() end
function ataxia_saveSettings() end
ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxia.settings.separator = ";"
ataxiaTemp = ataxiaTemp or {}

local NOW = 100000
local realEpoch, realSend = getEpoch, send
getEpoch = function() return NOW end
local sent = {}
send = function(c) sent[#sent + 1] = c end

dofile("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/024_Glass_Lily.lua")

local TRIG = "src_new/triggers/levi_ataxia/for_levi/leviticus/785_Glass_Lily_Dropped.lua"
local LINE = "You let a clouded glass lily fall to the ground, its fragile form crumbling into dust upon impact."

local function reset()
  sent = {}
  NOW = NOW + 100000
  ataxiaTemp.lilyDroppedAt, ataxiaTemp.lilyTriedAt = nil, nil
  ataxia.settings.lilyAuto, ataxia.settings.lilyCount = nil, nil
end

describe("the glass lily: DROP LILY every hour", function()
  it("drops all three straight away on a fresh session -- directly, not queued", function()
    reset()
    ataxia_lilyTick()
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("drop lily;drop lily;drop lily")
  end)

  it("the drop line starts the hour: nothing until 60 minutes have passed", function()
    reset()
    ataxia_lilyTick()
    dofile(TRIG)                          -- the trigger body calls ataxia_lilyDropped()
    NOW = NOW + 3599
    ataxia_lilyTick()
    expect(#sent).toBe(1)
    NOW = NOW + 1
    ataxia_lilyTick()
    expect(#sent).toBe(2)
  end)

  it("an attempt the game never confirmed is retried after 5 minutes, not an hour", function()
    reset()
    ataxia_lilyTick()
    NOW = NOW + 299
    ataxia_lilyTick()
    expect(#sent).toBe(1)
    NOW = NOW + 1
    ataxia_lilyTick()
    expect(#sent).toBe(2)
  end)

  it("off means off; `lily now` drops anyway", function()
    reset()
    ataxia.settings.lilyAuto = false
    ataxia_lilyTick()
    expect(#sent).toBe(0)
    ataxia_lilyDrop("manual", true)
    expect(#sent).toBe(1)
  end)

  it("drops as many as we carry", function()
    reset()
    ataxia.settings.lilyCount = 5
    ataxia_lilyTick()
    local _, n = sent[1]:gsub("drop lily", "")
    expect(n).toBe(5)
  end)

  it("the trigger matches the drop line as the server wraps it", function()
    local pats = TL.patterns(TRIG)
    for _, w in ipairs({ 80, 119 }) do
      expect(TL.anyMatches(pats, TL.wrap(LINE, w)[1])).toBeTrue()
    end
  end)

  it("starting the basher asks the clock instead of dropping three every time", function()
    local f = io.open("src_new/scripts/levi_ataxia/levi/ataxia/genrunning/003_Engaged_Disengage.lua")
    local s = f:read("*a"); f:close()
    expect(s:find('send("drop lily;drop lily;drop lily")', 1, true)).toBeNil()
    expect(s:find('ataxia_lilyDrop("bashing")', 1, true) ~= nil).toBeTrue()
  end)
end)

-- Restore shared state for whoever runs after us (test files share one Lua state).
if ataxia_lilyHandler then pcall(killAnonymousEventHandler, ataxia_lilyHandler) end
getEpoch, send = realEpoch, realSend
ataxiaTemp.lilyDroppedAt, ataxiaTemp.lilyTriedAt = nil, nil
ataxia.settings.lilyAuto, ataxia.settings.lilyCount = nil, nil
