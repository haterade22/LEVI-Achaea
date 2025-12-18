--- LEVI Test Suite
-- Main test runner
-- @module tests.run_tests

-- Simple test framework
local tests = {}
local passed = 0
local failed = 0

--- Assert a condition
-- @param condition The condition to check
-- @param message Error message if condition is false
local function assert_true(condition, message)
  if not condition then
    error(message or "Assertion failed")
  end
end

--- Assert equality
-- @param expected Expected value
-- @param actual Actual value
-- @param message Error message
local function assert_equal(expected, actual, message)
  if expected ~= actual then
    error(message or string.format("Expected %s, got %s", tostring(expected), tostring(actual)))
  end
end

--- Run a test
-- @param name Test name
-- @param test_func Test function
local function run_test(name, test_func)
  io.write(string.format("Running test: %s ... ", name))
  local success, err = pcall(test_func)
  if success then
    io.write("PASSED\n")
    passed = passed + 1
  else
    io.write(string.format("FAILED\n  Error: %s\n", tostring(err)))
    failed = failed + 1
  end
end

--- Test: Event registration and raising
local function test_events()
  local events = require("core.events")
  
  local event_data = nil
  local handler = function(data)
    event_data = data
  end
  
  events.register("test_event", handler)
  events.raise("test_event", {value = 42})
  
  assert_equal(42, event_data.value, "Event data should be passed correctly")
end

--- Test: Affliction tracking
local function test_afflictions()
  local afflictions = require("tracking.afflictions")
  
  afflictions.clear_all()
  assert_equal(0, afflictions.count_player(), "Should start with no afflictions")
  
  afflictions.add_player("asthma", "venom")
  assert_true(afflictions.has_player("asthma"), "Should have asthma")
  assert_equal(1, afflictions.count_player(), "Should have 1 affliction")
  
  afflictions.remove_player("asthma")
  assert_true(not afflictions.has_player("asthma"), "Should not have asthma")
  assert_equal(0, afflictions.count_player(), "Should have 0 afflictions")
end

--- Test: Balance tracking
local function test_balances()
  local balances = require("tracking.balances")
  
  balances.reset()
  assert_true(balances.has_balance(), "Should start with balance")
  assert_true(balances.has_equilibrium(), "Should start with equilibrium")
  
  balances.lose_balance()
  assert_true(not balances.has_balance(), "Should not have balance")
  assert_true(not balances.has_both(), "Should not have both")
  
  balances.gain_balance()
  assert_true(balances.has_balance(), "Should have balance again")
  assert_true(balances.has_both(), "Should have both again")
end

--- Test: Curing priorities
local function test_priorities()
  local priorities = require("curing.priorities")
  
  local asthma_priority = priorities.get("asthma")
  local peace_priority = priorities.get("peace")
  
  assert_true(asthma_priority > peace_priority, "Asthma should have higher priority than peace")
  
  local affs = {"peace", "asthma", "clumsiness"}
  priorities.sort(affs)
  assert_equal("asthma", affs[1], "Asthma should be first after sorting")
end

--- Test: Configuration loading
local function test_config()
  local config = require("config.loader")
  
  local cfg = config.get()
  assert_true(cfg ~= nil, "Config should load")
  assert_true(cfg.general ~= nil, "Config should have general section")
end

--- Main test runner
local function main()
  print("=================================")
  print("LEVI Test Suite")
  print("=================================\n")
  
  -- Run all tests
  run_test("Event System", test_events)
  run_test("Affliction Tracking", test_afflictions)
  run_test("Balance Tracking", test_balances)
  run_test("Curing Priorities", test_priorities)
  run_test("Configuration Loading", test_config)
  
  print("\n=================================")
  print(string.format("Results: %d passed, %d failed", passed, failed))
  print("=================================")
  
  if failed > 0 then
    os.exit(1)
  end
end

-- Run tests if this file is executed directly
if arg and arg[0]:match("run_tests%.lua$") then
  main()
end

return {
  run = main,
  assert_true = assert_true,
  assert_equal = assert_equal
}
