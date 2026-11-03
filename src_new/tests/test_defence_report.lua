--- test_defence_report.lua -- the defence list prints after the trigger pass (v4.7.474)
-- On Mudlet 5.1.0 the list printed as one long row with no line breaks, and ran off the window.
-- These tests run the REAL prompt trigger body with its globals stubbed; every stub is restored.

local FILE = "src_new/triggers/levi_ataxia/for_levi/leviticus/712_prompt_2.lua"

local function run(capturing)
  local fh = assert(io.open(FILE, "r"))
  local body = fh:read("*a"):match("%]%]%-%-\r?\n(.*)$")
  fh:close()
  local rec = { deleted = 0, reports = 0, timers = {}, closed = nil }
  local stubs = {
    capturing_defences = capturing,
    setTriggerStayOpen = function(name, lines) rec.closed = { name, lines } end,
    deleteLine = function() rec.deleted = rec.deleted + 1 end,
    tempTimer = function(delay, fn) rec.timers[#rec.timers + 1] = { delay = delay, fn = fn }; return 1 end,
    ataxia_reportDefences = function() rec.reports = rec.reports + 1 end,
  }
  local saved = {}
  for k, v in pairs(stubs) do saved[k] = _G[k]; _G[k] = v end
  local ok, err = pcall(assert((loadstring or load)(body)))
  rec.capturing = capturing_defences
  rec.reportsInPass = rec.reports
  if ok then
    for _, t in ipairs(rec.timers) do ok, err = pcall(t.fn) end
  end
  for k in pairs(stubs) do _G[k] = saved[k] end
  if not ok then error(err) end
  return rec
end

describe("defence list prompt (712)", function()
  it("does not print inside the trigger pass", function()
    expect(run(true).reportsInPass).toBe(0)
  end)

  it("prints once, on a zero timer, after the pass", function()
    local r = run(true)
    expect(#r.timers).toBe(1)
    expect(r.timers[1].delay).toBe(0)
    expect(r.reports).toBe(1)
  end)

  it("gags the prompt and ends the capture", function()
    local r = run(true)
    expect(r.deleted).toBe(1)
    expect(r.capturing).toBeNil()
    expect(r.closed[1]).toBe("Defence List")
    expect(r.closed[2]).toBe(0)
  end)

  it("leaves an ordinary prompt alone", function()
    local r = run(nil)
    expect(r.deleted).toBe(0)
    expect(#r.timers).toBe(0)
    expect(r.reports).toBe(0)
  end)
end)
