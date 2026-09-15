--- test_death_stare.lua -- Death Stare (Mnemosyne boon) + the denizen resistance database
--
-- Death Stare: "CONSIDER now costs 3 seconds of equilibrium and instantly kills any non-boss
-- denizen target. This can only be used once per ripple." User: at 2+ denizens immediately, and
-- at least once per ripple. Counted from the KILL line, so an eaten send retries.
--
-- Resistance database: CONSIDER prints "<mob> has a significant resistance against <type>
-- damage." -- recorded per mob name, unknown mobs CONSIDERed once, and consumers ask
-- `ataxiaBasher_targetResists`/`_targetWeakTo` in their own vocabulary.
--
-- Loads the real basher/001_Bashing_Functions.lua. Files share ONE Lua state: everything touched
-- here is saved at the top and restored at the end.

require("mock_mudlet")

local saved = {
  target = target, secondTarget = secondTarget, ataxia = ataxia, ataxiaBasher = ataxiaBasher,
  ataxiaTemp = ataxiaTemp, gmcp = gmcp, getEpoch = getEpoch, send = send,
  mnemDeathStare = mnemDeathStare, ataxiaEcho = ataxiaEcho, bashConsoleEcho = bashConsoleEcho,
}

target = 7
secondTarget = "a stout footsoldier"
ataxia = { settings = { separator = ";" }, vitals = { rage = 0 }, defences = {}, afflictions = {} }
ataxiaBasher = { enabled = true, inMnemosyne = true, battlerage = {} }
ataxiaTemp = {}
gmcp = {
  Room = { Info = { area = "", num = 5 } },
  Char = { Status = { class = "Runewarden" }, Vitals = {} },
  IRE = { Target = { Info = {} } },
}
function ataxiaEcho() end
function bashConsoleEcho() end

local ok = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")
if not ok then error("Failed to load bashing functions") end

local clock, sent = 700000, {}
getEpoch = function() return clock end
send = function(c) sent[#sent + 1] = c end

local function sentAny(needle)
  for _, c in ipairs(sent) do if c:find(needle, 1, true) then return true end end
  return false
end
local function sentCount(needle)
  local n = 0
  for _, c in ipairs(sent) do if c:find(needle, 1, true) then n = n + 1 end end
  return n
end

local function reset(opts)
  opts = opts or {}
  clock, sent = 700000, {}
  ataxiaTemp = {}
  target = 7
  secondTarget = "a stout footsoldier"
  ataxiaBasher.inMnemosyne = true
  ataxiaBasher.shielded = false
  ataxiaBasher.deathStareAfter = nil
  ataxiaBasher.denizenResist = {}
  mnemDeathStare = (opts.boon ~= false)
  ataxia.mnemosyne = {
    _denizenCount = function() return opts.denizens or 2 end,
    run = { boss = opts.boss, ripple = opts.ripple or 3 },
    map = { _ripple = opts.ripple or 3 },
  }
end

describe("Death Stare -- CONSIDER as the once-per-ripple instant kill", function()
  it("fires at 2+ denizens, prepended with the separator", function()
    reset({ denizens = 2 })
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")
    expect(ataxiaTemp.deathStareTries).toBe(1)
  end)

  it("is inert without the boon, outside the tower, at a player, on a shield, and on the boss", function()
    reset({ boon = false })
    expect(ataxiaBasher_deathStare(";")).toBe("")
    reset(); ataxiaBasher.inMnemosyne = false
    expect(ataxiaBasher_deathStare(";")).toBe("")
    reset(); target = "Grulk"
    expect(ataxiaBasher_deathStare(";")).toBe("")
    reset(); ataxiaBasher.shielded = true
    expect(ataxiaBasher_deathStare(";")).toBe("")
    reset({ boss = "Seasone the Industrious" }); secondTarget = "Seasone"
    expect(ataxiaBasher_deathStare(";")).toBe("")
    expect(ataxiaTemp.deathStareTries or 0).toBe(0) -- a refused gate stamps nothing
  end)

  it("holds alone until the ripple fallback, then fires on whatever is in front of us", function()
    reset({ denizens = 1 })
    expect(ataxiaBasher_deathStare(";")).toBe("")   -- crowd rule: not yet
    clock = clock + 89
    expect(ataxiaBasher_deathStare(";")).toBe("")
    clock = clock + 2                                -- 91s into the ripple
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")
  end)

  -- The ripple clock starts at the first round evaluated in that ripple (the first attack after
  -- GO), so a window is measured from there.
  it("honours a configured fallback window", function()
    reset({ denizens = 1 }); ataxiaBasher.deathStareAfter = 30
    expect(ataxiaBasher_deathStare(";")).toBe("")   -- first round of the ripple stamps its clock
    clock = clock + 29
    expect(ataxiaBasher_deathStare(";")).toBe("")
    clock = clock + 2
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")
  end)

  -- The 0.3s re-queue loop: replay verbatim, bound to the target it was sent for.
  it("replays across the hold for the SAME target only, without restamping", function()
    reset()
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")
    clock = clock + 1
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")
    expect(ataxiaTemp.deathStareTries).toBe(1)
    target = 8 -- the first mob died, retargeted, confirm not yet seen
    expect(ataxiaBasher_deathStare(";")).toBe("")
  end)

  it("counts the charge from the KILL line: confirmed -> spent for the ripple", function()
    reset()
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")
    ataxiaBasher_deathStareConfirm()
    expect(ataxiaTemp.deathStareUsed).toBeTrue()
    expect(ataxiaTemp.deathStarePendingAt).toBeNil()
    clock = clock + 60
    expect(ataxiaBasher_deathStare(";")).toBe("")      -- spent
  end)

  it("the kill line is self-proving and re-latches the flag", function()
    reset({ boon = false })
    ataxiaBasher_deathStareConfirm()
    expect(mnemDeathStare).toBeTrue()
  end)

  -- A send the server ate must not forfeit the ripple's one kill -- but a missed line must not
  -- cost an eq spend every few seconds all ripple either.
  it("retries an UNCONFIRMED send after the retry window, at most three times", function()
    reset()
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")  -- 1
    clock = clock + 5
    expect(ataxiaBasher_deathStare(";")).toBe("")             -- past the hold, inside the retry wait
    clock = clock + 4                                          -- 9s after the send
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")  -- 2
    clock = clock + 9
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")  -- 3
    clock = clock + 9
    expect(ataxiaBasher_deathStare(";")).toBe("")             -- budget spent
    expect(ataxiaTemp.deathStareTries).toBe(3)
  end)

  it("a new ripple is a new charge, keyed on the MAP's ripple (telemetry-independent)", function()
    reset({ ripple = 3 })
    ataxiaBasher_deathStare(";")
    ataxiaBasher_deathStareConfirm()
    expect(ataxiaBasher_deathStare(";")).toBe("")
    ataxia.mnemosyne.map._ripple = 4  -- M.onRipple stamped the map; telemetry's run.ripple did not move
    expect(ataxiaBasher_deathStare(";")).toBe("consider 7;")
    expect(ataxiaTemp.deathStareUsed).toBeNil()
    expect(ataxiaTemp.deathStareTries).toBe(1)
  end)
end)

describe("the denizen resistance database", function()
  it("keys by name with the article stripped, case-insensitively", function()
    expect(ataxiaBasher_resistKey("A stout footsoldier")).toBe("stout footsoldier")
    expect(ataxiaBasher_resistKey("a stout footsoldier")).toBe("stout footsoldier")
    expect(ataxiaBasher_resistKey("the Qurnok guard ")).toBe("qurnok guard")
    expect(ataxiaBasher_resistKey("an earth wyrm")).toBe("earth wyrm")
    expect(ataxiaBasher_resistKey("")).toBeNil()
    expect(ataxiaBasher_resistKey(nil)).toBeNil()
  end)

  it("records resistances, a weakness and the aura on one row", function()
    reset()
    ataxiaBasher_considerAura("A stout footsoldier", "overwhelming power")
    ataxiaBasher_considerResist("a stout footsoldier", "significant", "physical cutting")
    ataxiaBasher_considerResist("a stout footsoldier", "significant", "physical blunt")
    ataxiaBasher_considerWeakness("a stout footsoldier", "significant", "fire")
    local row = ataxiaBasher.denizenResist["stout footsoldier"]
    expect(row ~= nil).toBeTrue()
    expect(row.aura).toBe("overwhelming power")
    expect(row.resist["physical cutting"]).toBe("significant")
    expect(row.resist["physical blunt"]).toBe("significant")
    expect(row.weak["fire"]).toBe("significant")
    expect(row.seenAt).toBe(700000)
  end)

  it("answers consumers in their own vocabulary (substring either way)", function()
    reset()
    ataxiaBasher_considerResist("a stout footsoldier", "significant", "physical cutting")
    ataxiaBasher_considerWeakness("a stout footsoldier", "significant", "fire")
    expect(ataxiaBasher_targetResists("cutting")).toBeTrue()
    expect(ataxiaBasher_targetResists("physical cutting")).toBeTrue()
    expect(ataxiaBasher_targetResists("physical")).toBeTrue()
    expect(ataxiaBasher_targetResists("psychic")).toBeFalse()
    expect(ataxiaBasher_targetWeakTo("fire")).toBeTrue()
    expect(ataxiaBasher_targetWeakTo("cold")).toBeFalse()
    secondTarget = "a lithic cave bat" -- unknown mob: never a guess
    expect(ataxiaBasher_targetResists("cutting")).toBeFalse()
  end)

  it("CONSIDERs an unknown mob once, directly, and never again", function()
    reset({ boon = false })
    expect(ataxiaBasher_considerRecon()).toBeTrue()
    expect(sentCount("consider 7")).toBe(1)
    expect(ataxiaBasher_resistKnown("a stout footsoldier")).toBeTrue() -- the attempt is the record
    expect(ataxiaBasher_considerRecon()).toBeFalse()
    expect(sentCount("consider 7")).toBe(1)
  end)

  it("never CONSIDERs for recon while Death Stare is held -- that CONSIDER is the ripple's kill", function()
    reset({ boon = true })
    expect(ataxiaBasher_considerRecon()).toBeFalse()
    expect(#sent).toBe(0)
  end)

  it("skips a player target and an unnamed one", function()
    reset({ boon = false }); target = "Grulk"
    expect(ataxiaBasher_considerRecon()).toBeFalse()
    reset({ boon = false }); secondTarget = nil
    expect(ataxiaBasher_considerRecon()).toBeFalse()
    expect(#sent).toBe(0)
  end)
end)

-- Restore shared state for whoever runs after us.
target, secondTarget = saved.target, saved.secondTarget
ataxia, ataxiaBasher, ataxiaTemp, gmcp = saved.ataxia, saved.ataxiaBasher, saved.ataxiaTemp, saved.gmcp
getEpoch, send = saved.getEpoch, saved.send
mnemDeathStare = saved.mnemDeathStare
ataxiaEcho, bashConsoleEcho = saved.ataxiaEcho, saved.bashConsoleEcho
