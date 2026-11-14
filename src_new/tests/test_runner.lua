--- test_runner.lua — Minimal test runner for LEVI-Achaea
-- Run with: lua5.1 src_new/tests/test_runner.lua
-- Or:       lua src_new/tests/test_runner.lua

local passed = 0
local failed = 0
local errors = {}

local function describe(name, fn)
  print("\n== " .. name .. " ==")
  fn()
end

local function it(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("  PASS: " .. name)
  else
    failed = failed + 1
    table.insert(errors, { name = name, err = err })
    print("  FAIL: " .. name)
    print("        " .. tostring(err))
  end
end

local function expect(val)
  return {
    toBe = function(expected)
      if val ~= expected then
        error("Expected " .. tostring(expected) .. " but got " .. tostring(val), 2)
      end
    end,
    toBeTrue = function()
      if val ~= true then
        error("Expected true but got " .. tostring(val), 2)
      end
    end,
    toBeFalse = function()
      if val ~= false then
        error("Expected false but got " .. tostring(val), 2)
      end
    end,
    toBeNil = function()
      if val ~= nil then
        error("Expected nil but got " .. tostring(val), 2)
      end
    end,
    toBeGreaterThan = function(expected)
      if not (val > expected) then
        error("Expected " .. tostring(val) .. " > " .. tostring(expected), 2)
      end
    end,
    toBeLessThan = function(expected)
      if not (val < expected) then
        error("Expected " .. tostring(val) .. " < " .. tostring(expected), 2)
      end
    end,
    toContain = function(expected)
      if type(val) == "table" then
        for _, v in ipairs(val) do
          if v == expected then return end
        end
        error("Table does not contain " .. tostring(expected), 2)
      elseif type(val) == "string" then
        if not string.find(val, expected, 1, true) then
          error("String does not contain '" .. expected .. "'", 2)
        end
      else
        error("Cannot check containment on " .. type(val), 2)
      end
    end,
  }
end

-- Make test utilities global
_G.describe = describe
_G.it = it
_G.expect = expect

-- Load mock Mudlet environment
package.path = "./src_new/tests/?.lua;" .. package.path
local mock = require("mock_mudlet")

-- Initialize LEVI namespaces (minimal stubs for testing)
ataxia = ataxia or {}
ataxiagui = ataxiagui or {}
ataxiaNDB = ataxiaNDB or {}
ataxiaTemp = ataxiaTemp or {}
ataxiaTables = ataxiaTables or {}
ataxiaBasher = ataxiaBasher or {}
mmp = mmp or {}
target = ""
pariah = ""

print("=== LEVI-Achaea Test Suite ===")
print("Mock Mudlet environment loaded")

-- Discover and run test files
local test_files = {}
local handle = io.popen('find src_new/tests -name "test_*.lua" -not -name "test_runner.lua" 2>/dev/null || dir /b /s src_new\\tests\\test_*.lua 2>nul')
if handle then
  for file in handle:lines() do
    -- Normalize path separators
    file = file:gsub("\\", "/")
    if not file:match("test_runner%.lua$") and not file:match("mock_mudlet%.lua$") then
      table.insert(test_files, file)
    end
  end
  handle:close()
end

-- Deterministic order on every platform: `find` (CI) and `dir` (Windows) return
-- different orders, and test files share one Lua state -- an order-dependent leak
-- must fail the same way everywhere.
table.sort(test_files)

-- All test files share ONE Lua state, and mock.reset() does not put these globals back. A file that
-- replaces one for its own tests and does not restore it changes every later file (two real cases:
-- a row-latch test passed only because an earlier file left a flag set). REPORT-ONLY since
-- 2026-11-13: the run lists each leak and its exit status does not change. When the list is empty,
-- make a leak a failure.
local WATCHED = { "send", "tempTimer", "getEpoch", "expandAlias", "raiseEvent", "cecho", "echo" }
local leaks = {}
local function watched_now()
  local seen = {}
  for _, name in ipairs(WATCHED) do seen[name] = _G[name] end
  seen["io.open"] = io.open
  seen["math.random"] = math.random
  return seen
end
local function note_leaks(file, before)
  local after = watched_now()
  local names = {}
  for name in pairs(before) do names[#names + 1] = name end
  for name in pairs(after) do if before[name] == nil then names[#names + 1] = name end end
  table.sort(names)
  for _, name in ipairs(names) do
    if after[name] ~= before[name] then
      leaks[#leaks + 1] = "LEAK " .. file .. ": " .. name
    end
  end
end

if #test_files == 0 then
  -- Zero files is NOT RUN, never a pass. Until 2026-11-13 this branch fell through to "All tests
  -- passed!" and exit 0, so a run from the wrong folder (or a listing command that failed) was green.
  print("\nNO TESTS FOUND (test_*.lua in src_new/tests/). Run from the repository root.")
  print("NOT RUN: 0 test files")
  os.exit(2)
else
  for _, file in ipairs(test_files) do
    print("\n--- Loading: " .. file .. " ---")
    mock.reset()
    local before = watched_now()
    local ok, err = pcall(dofile, file)
    if not ok then
      failed = failed + 1
      table.insert(errors, { name = "Loading " .. file, err = err })
      print("  ERROR loading file: " .. tostring(err))
    end
    note_leaks(file, before)
  end
end

if #leaks > 0 then
  print("\n=== Globals left replaced by a test file (report-only): " .. #leaks .. " ===")
  for _, row in ipairs(leaks) do print(row) end
  print("Each later file ran with that replacement. Restore the global at the end of the file, under pcall.")
end

-- Summary
print("\n=== Results ===")
print(string.format("Passed: %d  Failed: %d  Total: %d", passed, failed, passed + failed))

if #errors > 0 then
  print("\nFailures:")
  for i, e in ipairs(errors) do
    print(string.format("  %d) %s: %s", i, e.name, e.err))
  end
  os.exit(1)
else
  print("\nAll tests passed!")
  os.exit(0)
end
