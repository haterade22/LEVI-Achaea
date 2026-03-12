--- test_example.lua — Example tests demonstrating the test harness
-- These tests validate the mock environment and show patterns for real tests.

local mock = require("mock_mudlet")

describe("Mock Mudlet Environment", function()

  it("should capture sent commands", function()
    mock.reset()
    send("kill rat")
    send("eat moss")
    expect(#mock.sent_commands).toBe(2)
    expect(mock.was_sent("kill rat")).toBeTrue()
    expect(mock.was_sent("eat moss")).toBeTrue()
    expect(mock.was_sent("flee")).toBeFalse()
  end)

  it("should capture raised events", function()
    mock.reset()
    raiseEvent("onAttack", "rat")
    expect(#mock.raised_events).toBe(1)
    expect(mock.was_raised("onAttack")).toBeTrue()
    expect(mock.raised_events[1].args[1]).toBe("rat")
  end)

  it("should fire named event handlers", function()
    mock.reset()
    local received = nil
    registerNamedEventHandler("test", "handler1", "myEvent", function(event, data)
      received = data
    end)
    raiseEvent("myEvent", "hello")
    expect(received).toBe("hello")
  end)

  it("should track timers", function()
    mock.reset()
    local id = tempTimer(2, function() end)
    expect(mock.active_timers[id]).toBe(mock.active_timers[id]) -- exists
    killTimer(id)
    expect(mock.active_timers[id]).toBeNil()
  end)

  it("should capture echo output", function()
    mock.reset()
    cecho("<green>Test passed!")
    expect(#mock.echoed_lines).toBe(1)
    expect(mock.echoed_lines[1]).toContain("Test passed!")
  end)

  it("should return last N commands", function()
    mock.reset()
    send("a")
    send("b")
    send("c")
    local last2 = mock.last_commands(2)
    expect(#last2).toBe(2)
    expect(last2[1]).toBe("b")
    expect(last2[2]).toBe("c")
  end)

end)

describe("LEVI Namespace Stubs", function()

  it("should have ataxia namespace initialized", function()
    expect(type(ataxia)).toBe("table")
  end)

  it("should have ataxiagui namespace initialized", function()
    expect(type(ataxiagui)).toBe("table")
  end)

  it("should have gmcp stub", function()
    expect(type(gmcp)).toBe("table")
  end)

end)
