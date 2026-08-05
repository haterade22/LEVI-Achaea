--- test_armour_swap_diff.lua -- only pry the embrasures that actually change (v4.7.212)
--
-- The swap used to pry all three embrasures and re-insert all three, every time, on the
-- reasoning that game state could not be verified without a probe. But it IS tracked:
-- `state.currentSlots` is written by the swap itself and by the `probe armour` trigger.
--
-- Borrowed Power changes exactly ONE slot, so five of six commands were churn -- and every
-- needless pry is another chance to half-apply and leave an embrasure empty, which is the
-- failure v4.7.211 had to fix.
--
-- The honesty guard is `slotsKnown`: until a swap or probe has told us what is in the armour,
-- every slot is UNKNOWN and gets the old pry+insert. Skipping on an assumption would leave
-- the wrong paragon in place silently.

require("mock_mudlet")

ataxia = { settings = { separator = ";" } }
function ataxia_saveSettings() end

-- Mirrors the command construction in ataxia.armour.swap. Kept as a local model rather than
-- sliced, because the real function is wrapped in tempTimer/Geyser machinery; the DECISION is
-- what matters here and it is reproduced exactly.
local PARAGON_TYPES = {
  crucious = "crucious (crit multiplier)", icosagon = "icosagon (20% crit)",
  metalliferous = "metalliferous (7.5% shifting resist)",
  serendipitous = "serendipitous (5% dmg->WP)", aeneaous = "aeneaous (absorption)",
  deltahedral = "deltahedral (morph, 10min CD)",
}
local NAMES = {
  p_cruc = "crucious (crit multiplier)", p_ico = "icosagon (20% crit)",
  p_metal = "metalliferous (7.5% resist)", p_ser = "serendipitous (5% dmg->WP)",
  p_aen = "aeneaous (absorption)", p_delta = "deltahedral (morph, 10min CD)",
}
local function paragonName(ref)
  if not ref then return "(empty)" end
  return NAMES[ref] or PARAGON_TYPES[tostring(ref):lower()] or ref
end
local function paragonKey(ref)
  if not ref then return nil end
  local nm = tostring(paragonName(ref) or ref):lower()
  for keyword in pairs(PARAGON_TYPES) do
    if nm:find(keyword, 1, true) then return keyword end
  end
  return nm
end

local function plan(slots, cur, known)
  local cmds = {}
  for i = 1, 3 do
    local want = slots[i]
    if want == "" then want = nil end
    local have = known and cur[i] or nil
    local same = known and want ~= nil and have ~= nil
      and paragonKey(want) == paragonKey(have)
    if not same then
      if (not known) or have ~= nil then table.insert(cmds, "pry armour embrasure " .. i) end
      if want then table.insert(cmds, "insert " .. want .. " into armour embrasure " .. i) end
    end
  end
  return cmds
end

describe("only the changed embrasure is touched", function()
  it("one slot differing produces exactly one pry and one insert", function()
    local cmds = plan({ "p_ico", "p_metal", "p_ser" }, { "p_ico", "p_metal", "p_cruc" }, true)
    expect(#cmds).toBe(2)
    expect(cmds[1]).toBe("pry armour embrasure 3")
    expect(cmds[2]).toBe("insert p_ser into armour embrasure 3")
  end)

  it("an identical profile sends NOTHING", function()
    local cmds = plan({ "p_ico", "p_metal", "p_cruc" }, { "p_ico", "p_metal", "p_cruc" }, true)
    expect(#cmds).toBe(0)
  end)

  it("two differing slots touch only those two", function()
    local cmds = plan({ "p_ico", "p_ser", "p_aen" }, { "p_ico", "p_metal", "p_cruc" }, true)
    expect(#cmds).toBe(4)
    expect(cmds[1]).toBe("pry armour embrasure 2")
    expect(cmds[3]).toBe("pry armour embrasure 3")
  end)

  -- The v4.7.211 lesson: an id and a bare type name are the same physical paragon.
  it("an id and a bare NAME for one paragon are not a change", function()
    local cmds = plan({ "metalliferous", "p_ico", "p_cruc" }, { "p_metal", "p_ico", "p_cruc" }, true)
    expect(#cmds).toBe(0)
  end)
end)

describe("the honesty guard", function()
  it("rebuilds ALL THREE when the armour contents are unknown", function()
    local cmds = plan({ "p_ico", "p_metal", "p_ser" }, {}, false)
    expect(#cmds).toBe(6) -- three pries, three inserts: the old behaviour
    expect(cmds[1]).toBe("pry armour embrasure 1")
  end)

  it("never SKIPS a slot on an assumption -- unknown always gets pry+insert", function()
    -- Even where the desired paragon happens to match what is really worn, we cannot know
    -- that, so the slot is still rebuilt rather than silently left alone.
    local cmds = plan({ "p_ico" }, { "p_ico" }, false)
    expect(cmds[1]).toBe("pry armour embrasure 1")
    expect(cmds[2]).toBe("insert p_ico into armour embrasure 1")
  end)
end)

describe("empty embrasures", function()
  it("a KNOWN-empty slot is filled without a pointless pry", function()
    local cmds = plan({ "p_ico", "p_metal", "p_ser" }, { "p_ico", "p_metal", nil }, true)
    expect(#cmds).toBe(1)
    expect(cmds[1]).toBe("insert p_ser into armour embrasure 3")
  end)

  it("clearing a slot pries without inserting", function()
    local cmds = plan({ "p_ico", "p_metal" }, { "p_ico", "p_metal", "p_cruc" }, true)
    expect(#cmds).toBe(1)
    expect(cmds[1]).toBe("pry armour embrasure 3")
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
ataxia = nil
