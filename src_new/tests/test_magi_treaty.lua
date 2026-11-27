-- test_magi_treaty.lua -- the Magi treaty run (alias `treaties`): mage/007_Treaty_Run.lua and the two
-- completion triggers in magi_offense_tracking/017 and 018.
--
-- The run walks to the workshop (room 33671) unless we stand in it, takes the material from the rift
-- ("outr 1 <commodity>"), sends "treaty form <name>" when eq and balance are up, and waits for the
-- game's completion line. The two lines are the captured ones (kb/raw/live/treaty_*_2026-11-27.txt),
-- delivered through the triggers' REAL patterns (trigger_lib). Time is a hand-moved clock. One shared
-- Lua state: every global is restored at the end.

local before = {}
for k, v in pairs(_G) do before[k] = v end

local TL = dofile("src_new/tests/trigger_lib.lua")
local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/magi_offense_tracking/"
local ASH_FILE, STONE_FILE = TRG .. "017_Treaty_Formed_Ashbeast.lua", TRG .. "018_Treaty_Formed_Stoneback.lua"
local ASH_LINE = "At last you find yourself freed of the Ashbeast's choking shroud as a scouring voice proclaims,"
  .. " \"Thus is our agreement written!\""
local STONE_LINE = "At last, there is a resolute sense of unyielding acceptance. As you withdraw your will from the"
  .. " communication a deep, rumbling voice intones, \"Thus is agreement made.\""

local sent, echoes, timers, handlers, now, gotos = {}, {}, {}, {}, 0, {}

send = function(cmd) sent[#sent + 1] = cmd end
ataxiaEcho = function(m) echoes[#echoes + 1] = m end
tempTimer = function(d, fn) timers[#timers + 1] = { at = now + d, fn = fn }; return #timers end
killTimer = function(id) if timers[id] then timers[id].dead = true end end
registerAnonymousEventHandler = function(ev, fn) handlers[#handlers + 1] = { ev = ev, fn = fn }; return #handlers end
killAnonymousEventHandler = function(id) if handlers[id] then handlers[id].dead = true end end
local function raise(ev) for _, h in ipairs(handlers) do if not h.dead and h.ev == ev then h.fn() end end end
local function advance(sec)
  now = now + sec
  for _, t in ipairs(timers) do
    if not t.dead and t.at <= now then t.dead = true; t.fn() end
  end
end
local function liveTimers() local n = 0 for _, t in ipairs(timers) do if not t.dead then n = n + 1 end end return n end
local function liveHandlers() local n = 0 for _, h in ipairs(handlers) do if not h.dead then n = n + 1 end end return n end

ataxiaTemp = {}
ataxiaBasher = nil
ataxia = { vitals = { eq = true, bal = true } }
mmp = { gotoRoom = function(r) gotos[#gotos + 1] = r end }
gmcp = { Room = { Info = { num = "100" } } }

local loadErr
local okLoad, errLoad = pcall(dofile, "src_new/scripts/levi_ataxia/levi/levi_scripts/mage/007_Treaty_Run.lua")
if not okLoad then loadErr = tostring(errLoad) end

local function reset(room)
  sent, echoes, timers, handlers, now, gotos = {}, {}, {}, {}, 0, {}
  ataxiaTemp = {}
  ataxiaBasher = nil
  ataxia.vitals.eq, ataxia.vitals.bal = true, true
  gmcp.Room.Info.num = tostring(room)
end
local function lastEcho() return echoes[#echoes] or "" end
local function fire(file, line) return TL.anyMatches(TL.patterns(file), line) end
-- Deliver a game line the way the triggers do: the matching trigger's body calls onFormed.
local function deliver(line)
  if fire(ASH_FILE, line) then ataxiaTreaty_onFormed("ashbeast") end
  if fire(STONE_FILE, line) then ataxiaTreaty_onFormed("stoneback") end
end
local function has(s, part) return s:find(part, 1, true) ~= nil end

local ok, err = pcall(function()
if loadErr then error(loadErr, 0) end

describe("treaty run", function()
  it("starts in the workshop: outr, then form, no walk", function()
    reset(33671)
    ataxiaTreaty_start()
    expect(#gotos).toBe(0)
    expect(sent[1]).toBe("outr 1 charcoal")
    expect(sent[2]).toBe("treaty form ashbeast")
  end)

  it("walks when elsewhere, then starts on arrival", function()
    reset(100)
    ataxiaTreaty_start()
    expect(gotos[1]).toBe(33671)
    expect(#sent).toBe(0)
    gmcp.Room.Info.num = "33671"
    raise("mmapper arrived")
    expect(sent[1]).toBe("outr 1 charcoal")
    expect(liveHandlers()).toBe(0)
  end)

  it("stops when the room on arrival is not the workshop", function()
    reset(100)
    ataxiaTreaty_start()
    raise("mmapper arrived")
    advance(1)
    expect(ataxiaTemp.treatyRun).toBe(nil)
    expect(#sent).toBe(0)
    expect(has(lastEcho(), "not the workshop")).toBe(true)
    expect(liveTimers()).toBe(0)
    expect(liveHandlers()).toBe(0)
  end)

  it("stops on a failed path and kills its handlers and timers", function()
    reset(100)
    ataxiaTreaty_start()
    raise("mmapper failed path")
    expect(ataxiaTemp.treatyRun).toBe(nil)
    expect(has(lastEcho(), "no path")).toBe(true)
    expect(liveTimers()).toBe(0)
    expect(liveHandlers()).toBe(0)
  end)

  it("stops when the walk takes longer than 90 s", function()
    reset(100)
    ataxiaTreaty_start()
    advance(91)
    expect(ataxiaTemp.treatyRun).toBe(nil)
    expect(has(lastEcho(), "walking")).toBe(true)
    expect(liveHandlers()).toBe(0)
  end)

  it("waits for eq and balance before TREATY FORM", function()
    reset(33671)
    ataxia.vitals.eq = false
    ataxiaTreaty_start()
    expect(sent[1]).toBe("outr 1 charcoal")
    expect(#sent).toBe(1)
    advance(2)
    expect(#sent).toBe(1)
    ataxia.vitals.eq = true
    advance(1)
    expect(sent[2]).toBe("treaty form ashbeast")
    advance(2)
    expect(#sent).toBe(2)
  end)

  it("stops when a treaty is not formed within 60 s", function()
    reset(33671)
    ataxiaTreaty_start()
    advance(61)
    expect(ataxiaTemp.treatyRun).toBe(nil)
    expect(has(lastEcho(), "timed out")).toBe(true)
    expect(liveTimers()).toBe(0)
  end)

  it("refuses to start while autobash runs, and while a run is active", function()
    reset(33671)
    ataxiaBasher = { enabled = true }
    ataxiaTreaty_start()
    expect(#sent).toBe(0)
    expect(has(lastEcho(), "autobash")).toBe(true)
    ataxiaBasher = nil
    ataxiaTreaty_start()
    local n = #sent
    ataxiaTreaty_start()
    expect(#sent).toBe(n)
    expect(has(lastEcho(), "already active")).toBe(true)
  end)

  it("the real completion lines fire the real patterns, each its own treaty only", function()
    expect(fire(ASH_FILE, ASH_LINE)).toBe(true)
    expect(fire(STONE_FILE, ASH_LINE)).toBe(false)
    expect(fire(STONE_FILE, STONE_LINE)).toBe(true)
    expect(fire(ASH_FILE, STONE_LINE)).toBe(false)
  end)

  it("a full run ends after stoneback, formed in order, with nothing left running", function()
    reset(33671)
    ataxiaTreaty_start()
    deliver(ASH_LINE)
    expect(sent[3]).toBe("outr 1 stone")
    expect(sent[4]).toBe("treaty form stoneback")
    deliver(STONE_LINE)
    expect(ataxiaTemp.treatyRun).toBe(nil)
    expect(#sent).toBe(4)
    expect(has(lastEcho(), "ashbeast, stoneback")).toBe(true)
    expect(liveTimers()).toBe(0)
  end)

  it("ignores a completion when no run is active, and the wrong treaty during one", function()
    reset(33671)
    deliver(ASH_LINE)
    expect(#echoes).toBe(0)
    ataxiaTreaty_start()
    deliver(STONE_LINE)
    expect(has(lastEcho(), "ignored")).toBe(true)
    expect(ataxiaTemp.treatyRun.waiting).toBe("ashbeast")
  end)

  it("treaties stop ends the run, and says so when none is active", function()
    reset(33671)
    ataxiaTreaty_stop("test")
    expect(has(lastEcho(), "no treaty run")).toBe(true)
    ataxiaTreaty_start()
    ataxiaTreaty_stop("by you")
    expect(ataxiaTemp.treatyRun).toBe(nil)
    expect(liveTimers()).toBe(0)
  end)
end)

end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
