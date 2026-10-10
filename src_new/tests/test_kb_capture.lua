--- test_kb_capture.lua -- `kbcapture` records the game's answers word for word (v4.7.396)
--
-- The capture asks one command at a time, records every line until the next prompt (or a
-- timeout), appends the block to a file and moves on. Parsing is the repo's job
-- (tools/kb_capture_import.py), so these tests pin the RECORDING: what is sent, what is kept,
-- when an answer ends, and the file format the importer splits on. Globals are restored at the end.

require("mock_mudlet")

local saved = {}
for _, k in ipairs({ "send", "tempTimer", "killTimer", "tempRegexTrigger", "killTrigger",
  "ataxiaEcho", "deleteLine", "isPrompt", "ataxiaBasher", "ataxia_defaultCuringPrios",
  "curingTable", "curingTableV3", "salveCureTableV3", "smokeCureTableV3" }) do
  saved[k] = _G[k]
end

local sent, timers, trigs, gagged = {}, {}, {}, 0
send = function(c) sent[#sent + 1] = c end
tempTimer = function(d, fn) timers[#timers + 1] = { d = d, fn = fn, live = true }; return #timers end
killTimer = function(id) if timers[id] then timers[id].live = false end end
tempRegexTrigger = function(p, fn) trigs[#trigs + 1] = { p = p, fn = fn, live = true }; return #trigs end
killTrigger = function(id) if trigs[id] then trigs[id].live = false end end
ataxiaEcho = function() end
deleteLine = function() gagged = gagged + 1 end
ataxiaBasher = { enabled = false }
ataxia_defaultCuringPrios = function() return { paralysis = 3, burning = 9, burning5 = 4, aeon = 2 } end
curingTable = { kelp = { "asthma", "weariness" } }
curingTableV3 = { bloodroot = { "paralysis", "slickness" } }
salveCureTableV3 = { head = { "blindness" } }
smokeCureTableV3 = { "aeon", "disloyalty" }
ataxiaTemp = ataxiaTemp or {}
ataxiaTemp.kbcap = nil

dofile("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/025_KB_Capture.lua")

local FILE = os.tmpname()
local realPath = ataxiaKB.path
ataxiaKB.path = function() return FILE end

local function fileText()
  local f = io.open(FILE, "r")
  if not f then return "" end
  local t = f:read("*a"); f:close(); return t
end

-- Fire the newest live timer of the given delay.
local function fireTimer(delay)
  for i = #timers, 1, -1 do
    local t = timers[i]
    if t.live and t.d == delay then t.live = false; t.fn(); return true end
  end
  return false
end

local function reset()
  sent, timers, trigs, gagged = {}, {}, {}, 0
  ataxiaTemp.kbcap = nil
  ataxiaBasher.enabled = false
  local f = io.open(FILE, "w"); f:close()
end

local ok, err = pcall(function()
describe("kbcapture: affliction names", function()
  it("collects every name our code knows, drops stack suffixes, and is sorted", function()
    local names = ataxiaKB.affNames()
    local set = {}
    for _, n in ipairs(names) do set[n] = true end
    for _, want in ipairs({ "paralysis", "burning", "aeon", "asthma", "slickness", "blindness",
      "disloyalty", "ablaze", "stinky" }) do
      expect(set[want]).toBeTrue()
    end
    expect(set.burning5).toBeNil()
    for i = 2, #names do expect(names[i - 1] < names[i]).toBeTrue() end
  end)

  it("asks AFFLICTION LIST first, then SHOW and WHATCURES for each name", function()
    local cmds = ataxiaKB.afflictionCommands({ "aeon", "asthma" })
    expect(cmds[1]).toBe("affliction list")
    expect(cmds[2]).toBe("affliction show aeon")
    expect(cmds[3]).toBe("whatcures aeon")
    expect(#cmds).toBe(5)
  end)
end)

describe("kbcapture: recording answers", function()
  it("sends one command, keeps its lines, and ends the answer at the prompt", function()
    reset()
    expect(ataxiaKB.start({ "whatcures paralysis", "whatcures asthma" })).toBeTrue()
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("whatcures paralysis")
    ataxiaKB.onLine("The affliction 'paralysis' is cured by: Eat Bloodroot / Eat Magnesium.", false)
    expect(gagged).toBe(1)
    ataxiaKB.onLine("12:00:00 [prompt]", true)
    local text = fileText()
    expect(text).toContain("| whatcures paralysis\n")
    expect(text).toContain("The affliction 'paralysis' is cured by: Eat Bloodroot / Eat Magnesium.\n##### END\n")
    expect(text:find("prompt", 1, true)).toBeNil()
    -- the next command goes out only after the gap
    expect(#sent).toBe(1)
    fireTimer(ataxiaKB.GAP)
    expect(sent[2]).toBe("whatcures asthma")
  end)

  it("a prompt before any answer belongs to something older: keep waiting", function()
    reset()
    ataxiaKB.start({ "affliction show aeon" })
    ataxiaKB.onLine("old prompt", true)
    expect(fileText()).toBe("")
    ataxiaKB.onLine("Aeon: everything is slow.", false)
    ataxiaKB.onLine("prompt", true)
    expect(fileText()).toContain("Aeon: everything is slow.")
  end)

  it("an answer with no prompt is closed by the timeout and marked", function()
    reset()
    ataxiaKB.start({ "whatcures nothing" })
    ataxiaKB.onLine("I know of no such affliction.", false)
    expect(fireTimer(ataxiaKB.CAPTURE_TIMEOUT)).toBeTrue()
    expect(fileText()).toContain("| whatcures nothing | TIMEOUT\nI know of no such affliction.\n##### END")
  end)

  it("finishes after the last command and stops recording lines", function()
    reset()
    ataxiaKB.start({ "whatcures aeon" })
    ataxiaKB.onLine("x", false)
    ataxiaKB.onLine("prompt", true)
    fireTimer(ataxiaKB.GAP)
    expect(ataxiaTemp.kbcap.running).toBeFalse()
    local before = fileText()
    ataxiaKB.onLine("a stray line after the run", false)
    expect(fileText()).toBe(before)
  end)

  it("stop ends the run after the current answer", function()
    reset()
    ataxiaKB.start({ "whatcures a", "whatcures b", "whatcures c" })
    ataxiaKB.stop()
    ataxiaKB.onLine("answer a", false)
    ataxiaKB.onLine("prompt", true)
    fireTimer(ataxiaKB.GAP)
    expect(#sent).toBe(1)
    expect(ataxiaTemp.kbcap.running).toBeFalse()
  end)

  it("refuses to start while the basher is on (the gag would hide a fight)", function()
    reset()
    ataxiaBasher.enabled = true
    expect(ataxiaKB.start({ "whatcures aeon" })).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("refuses a second run while one is going", function()
    reset()
    ataxiaKB.start({ "whatcures a" })
    expect(ataxiaKB.start({ "whatcures b" })).toBeFalse()
    expect(#sent).toBe(1)
  end)
end)
end)

-- restore
ataxiaKB.path = realPath
os.remove(FILE)
ataxiaTemp.kbcap = nil
for k, v in pairs(saved) do _G[k] = v end
if not ok then error(err) end
