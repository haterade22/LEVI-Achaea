--- test_mock_infra.lua -- mock_mudlet.lua's own resilience (found live, 2026-09-02)
--
-- `mock.fire_timers()` walked `mock.active_timers` with a bare `pairs()` loop. A callback that
-- arms a NEW timer -- a self-rearming tick, a retry, exactly the "trickle" shape
-- `_flushPendingOffer` uses (v4.7.295) -- adds a key to that same table while the loop is still
-- iterating it, which is undefined in Lua and surfaced as `invalid key to 'next'`.
--
-- It did not fail every run: Lua's hash part only breaks like this near a rehash boundary, so it
-- was a table-SIZE-dependent flake -- an unrelated test elsewhere in the suite, by leaving a few
-- more timers lying around than usual, could push `active_timers` over that boundary at exactly
-- this call and take down a completely unrelated test. Real Mudlet has no equivalent hazard --
-- its timer registry is not a Lua table this code iterates -- so this was a fragility in the
-- MOCK, not in the shipped pattern, which several production tick loops already use safely.

local mock = require("mock_mudlet")

describe("mock send splits ; as Mudlet's Host::send does (2026-11-01)", function()
  it("records each piece and skips empty ones", function()
    mock.reset()
    mock.send("queue addclear free a;b;;c;")
    expect(table.concat(mock.sent_commands, " | ")).toBe("queue addclear free a | b | c")
  end)

  it("was_sent asks a chain as its pieces in a row, so a negative can still fail", function()
    mock.reset()
    mock.send("cq all;goto 11090")
    expect(mock.was_sent("cq all;goto 11090")).toBeTrue()
    expect(mock.was_sent("cq all")).toBeTrue()
    expect(mock.was_sent("goto 11090;cq all")).toBeFalse()
    mock.reset()
    mock.send("cq all")
    mock.send("touch tree")
    mock.send("goto 11090")
    expect(mock.was_sent("cq all;goto 11090")).toBeFalse()
  end)
end)

describe("mock.fire_timers() survives a callback arming a new timer", function()
  it("does not corrupt iteration when a callback self-rearms", function()
    mock.reset()
    local rearmed = false
    tempTimer(1, function()
      rearmed = true
      tempTimer(1, function() end)   -- the shape that used to break the walk
    end)
    local ok = pcall(mock.fire_timers)
    expect(ok).toBeTrue()
    expect(rearmed).toBeTrue()
  end)

  -- Semantics preserved deliberately: a timer armed BY a callback during the pass is still
  -- discarded rather than fired, matching the pre-fix (accidental) behaviour -- only the crash
  -- is new territory, not the observable result.
  it("still wipes the table unconditionally afterward, including anything just rearmed", function()
    mock.reset()
    tempTimer(1, function() tempTimer(1, function() end) end)
    mock.fire_timers()
    local n = 0
    for _ in pairs(mock.active_timers) do n = n + 1 end
    expect(n).toBe(0)
  end)

  it("fires every timer present at the start of the pass", function()
    mock.reset()
    local fired = {}
    for i = 1, 5 do
      tempTimer(1, function() fired[i] = true end)
    end
    mock.fire_timers()
    for i = 1, 5 do expect(fired[i]).toBeTrue() end
  end)
end)

mock.reset()
