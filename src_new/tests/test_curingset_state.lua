--- test_curingset_state.lua -- CURINGSET LIST parsing, install safety, setup capacity (v4.7.247)
--
-- The fixture is the user's REAL captured output (2026-08-10), duplicate `bashing` and
-- 22-of-22 cap included. Every assertion below is about behaviour that was wrong against
-- exactly this state.

require("mock_mudlet")

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
function ataxiaEcho(...) end
function getEpoch() return 1000 end

dofile("src_new/scripts/levi_ataxia/levi/ataxia/ataxia/009_Curingset_State.lua")

-- Verbatim from the game, including the blank line and the rule.
local REAL = {
  "Your current curing sets",
  "--------------------------------------------------------------------------------",
  "normal (current)",
  "slowcuring",
  "infernal",
  "bashing",
  "waterlord",
  "general",
  "depthswalker",
  "sentinel",
  "occultist",
  "alchemist",
  "apostate",
  "bashing",
  "knights",
  "paladin",
  "serpent",
  "pariah",
  "druid",
  "shikudo",
  "runewarden",
  "priest",
  "unnamable",
  "blademaster",
  "You are using a total of 22 of your allowed 22 curing sets.",
}

describe("ataxia_parseCuringsetList", function()
  it("reads every set, the current one, and the cap", function()
    local cs = ataxia_parseCuringsetList(REAL)
    expect(cs ~= nil).toBeTrue()
    expect(#cs.list).toBe(22)
    expect(cs.current).toBe("normal")
    expect(cs.used).toBe(22)
    expect(cs.allowed).toBe(22)
  end)

  it("preserves the DUPLICATE rather than collapsing it -- each copy eats a slot", function()
    local cs = ataxia_parseCuringsetList(REAL)
    expect(cs.set["bashing"]).toBe(2)
    expect(cs.set["normal"]).toBe(1)
  end)

  it("does not invent the set our bash profile actually wants", function()
    local cs = ataxia_parseCuringsetList(REAL)
    expect(cs.set["bash"]).toBe(nil)   -- the profile's default setname is `bash`, not `bashing`
    expect(cs.set["bashing"]).toBe(2)
  end)

  it("ignores the rule and the header", function()
    local cs = ataxia_parseCuringsetList(REAL)
    for _, name in ipairs(cs.list) do
      expect(name:match("^[%a]")).toBe(name:sub(1, 1))
    end
  end)

  -- A half-read list is worse than none: every caller reads "absent" as "does not exist",
  -- so a truncated capture would have us create a duplicate or refuse a set that is there.
  it("returns nil when the total line never arrived", function()
    local partial = {}
    for i = 1, #REAL - 1 do partial[i] = REAL[i] end
    expect(ataxia_parseCuringsetList(partial)).toBe(nil)
  end)

  it("returns nil on junk", function()
    expect(ataxia_parseCuringsetList(nil)).toBe(nil)
    expect(ataxia_parseCuringsetList({ "you have no idea what this is" })).toBe(nil)
  end)
end)

describe("queries answer UNKNOWN as a third state", function()
  it("nil before any list has been read", function()
    ataxia.curingsets = { list = {}, set = {}, at = nil }
    expect(ataxia_curingsetKnown()).toBeFalse()
    expect(ataxia_curingsetHas("bash")).toBe(nil)
    expect(ataxia_curingsetFull()).toBe(nil)
    expect(ataxia_curingsetFree()).toBe(nil)
  end)

  it("real answers once parsed", function()
    local cs = ataxia_parseCuringsetList(REAL)
    ataxia.curingsets = { list = cs.list, set = cs.set, current = cs.current,
                          used = cs.used, allowed = cs.allowed, at = 1 }
    expect(ataxia_curingsetKnown()).toBeTrue()
    expect(ataxia_curingsetHas("bashing")).toBeTrue()
    expect(ataxia_curingsetHas("bash")).toBeFalse()
    expect(ataxia_curingsetFull()).toBeTrue()
    expect(ataxia_curingsetFree()).toBe(0)
  end)

  it("names the duplicates", function()
    local d = ataxia_curingsetDupes()
    expect(#d).toBe(1)
    expect(d[1].name).toBe("bashing")
    expect(d[1].count).toBe(2)
  end)
end)

-- ============================================================================
-- The install decision. This is the corruption fix: the old install fired
-- `curingset new` / `curingset switch` and then wrote ~55 `curing priority`
-- commands on timers assuming both worked. At 22/22 both fail, the PVP set stays
-- active, and those writes land in it.
-- ============================================================================
dofile("src_new/scripts/levi_ataxia/levi/ataxia/ataxia/001_Default_Curing_Prios.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/ataxia/008_Bash_Curing_Profile.lua")

describe("ataxia_bashInstallDecide", function()
  local full = ataxia_parseCuringsetList(REAL)

  it("ABORTS on the real captured state -- no free slot for `bash`", function()
    local what, why = ataxia_bashInstallDecide(full, "bash")
    expect(what).toBe("abort")
    expect(why:find("22/22", 1, true) ~= nil).toBeTrue()
  end)

  it("aborts rather than guessing when the list could not be read", function()
    expect((ataxia_bashInstallDecide(nil, "bash"))).toBe("abort")
    expect((ataxia_bashInstallDecide({}, "bash"))).toBe("abort")
  end)

  it("proceeds when the set already exists", function()
    expect((ataxia_bashInstallDecide(full, "bashing"))).toBe("abort") -- ...but it is a DUPE
    local one = ataxia_parseCuringsetList({
      "Your current curing sets", "normal (current)", "bash",
      "You are using a total of 2 of your allowed 22 curing sets.",
    })
    expect((ataxia_bashInstallDecide(one, "bash"))).toBe("proceed")
  end)

  -- Switching to a name the game lists twice is ambiguous, so refuse rather than gamble on
  -- which copy receives 55 priority writes.
  it("refuses a DUPLICATE set name", function()
    local what, why = ataxia_bashInstallDecide(full, "bashing")
    expect(what).toBe("abort")
    expect(why:find("listed 2 times", 1, true) ~= nil).toBeTrue()
  end)

  it("creates when absent and there is room", function()
    local room = ataxia_parseCuringsetList({
      "Your current curing sets", "normal (current)",
      "You are using a total of 1 of your allowed 22 curing sets.",
    })
    expect((ataxia_bashInstallDecide(room, "bash"))).toBe("create")
  end)
end)

describe("classDetect.planCuringsets", function()
  dofile("src_new/scripts/levi_ataxia/levi/levi_scripts/class_detect/001_Class_Detect_Engine.lua")

  -- The map names more sets than the game allows, which is why the old setup() could never
  -- succeed and never said so.
  it("wants more sets than the cap allows", function()
    local wanted = classDetect.wantedCuringsets()
    expect(#wanted > 22).toBeTrue()
  end)

  it("creates nothing when the account is already full", function()
    local full = ataxia_parseCuringsetList(REAL)
    local plan = classDetect.planCuringsets(full, classDetect.wantedCuringsets())
    expect(#plan.create).toBe(0)
    expect(#plan.skipped > 0).toBeTrue()
    -- ...and it does not re-create the ones that are already there
    local present = {}
    for _, n in ipairs(plan.present) do present[n] = true end
    expect(present["infernal"]).toBeTrue()
    expect(present["paladin"]).toBeTrue()
  end)

  it("fills only the free slots, deterministically", function()
    local three = ataxia_parseCuringsetList({
      "Your current curing sets", "normal (current)",
      "You are using a total of 19 of your allowed 22 curing sets.",
    })
    local plan = classDetect.planCuringsets(three, classDetect.wantedCuringsets())
    expect(#plan.create).toBe(3)
    -- sorted input -> stable choice of which three, not pairs() order
    expect(plan.create[1] < plan.create[2]).toBeTrue()
    expect(plan.create[2] < plan.create[3]).toBeTrue()
  end)
end)
