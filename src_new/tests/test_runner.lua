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

if #test_files == 0 then
  print("\nNo test files found (test_*.lua in src_new/tests/)")
  print("Create test files like: src_new/tests/test_example.lua")
else
  for _, file in ipairs(test_files) do
    print("\n--- Loading: " .. file .. " ---")
    mock.reset()
    local ok, err = pcall(dofile, file)
    if not ok then
      failed = failed + 1
      table.insert(errors, { name = "Loading " .. file, err = err })
      print("  ERROR loading file: " .. tostring(err))
    end
  end
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
