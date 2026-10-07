-- test_basher_shaman_thrice.lua -- Thrice Cursed: swiftcurse, spend the jinx it banked, swiftcurse
--
-- Boon (v4.7.386): "Your swiftcurses now build jinx charges, and your jinxes deal one extra bleed
-- curse when used." User: "swiftcurse target, get jinx charge, then jinx target to use jinx charge
-- and then swiftcurse".
--
-- Loads the real basher/002_Class_Bashing.lua and the real jinx/002 trigger. Files share ONE Lua
-- state: every global touched here is saved at the top and restored at the bottom.

require("mock_mudlet")

local saved = {
  target = target, ataxia = ataxia, ataxiaBasher = ataxiaBasher, ataxiaTemp = ataxiaTemp,
  shaman = shaman, getEpoch = getEpoch, mnemThriceCursed = mnemThriceCursed,
  curseCharge = curseCharge, swiftcursing = swiftcursing, deleteFull = deleteFull,
  ataxia_isClass = ataxia_isClass,
  ataxiaBasher_assembleBattlerage = ataxiaBasher_assembleBattlerage,
}

target = 7
ataxia = { settings = { separator = ";" }, vitals = { hp = 1000, maxhp = 1000, rage = 0, mp = 3000 },
           defences = {} }
ataxiaBasher = { shielded = false, enabled = true, manual = false,
                 battlerage = { Shaman = { raze = "RAZE" } } }
ataxiaTemp = {}

local ok, err = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/002_Class_Bashing.lua")
if not ok then error("Failed to load class-bashing file: " .. tostring(err)) end
function ataxiaBasher_assembleBattlerage() return "" end

local clock = 900000
getEpoch = function() return clock end

local JINX = "stand;wield shield;jinx bleed bleed 7"
local SWIFT = "stand;wield shield;swiftcurse 7 bleed"

local function reset(opts)
  opts = opts or {}
  clock = 900000
  target = 7
  ataxiaTemp = { canJinx = opts.canJinx, jinxCharge = opts.canJinx and 1 or 0 }
  ataxia.vitals.hp, ataxia.vitals.maxhp = opts.hp or 1000, 1000
  mnemThriceCursed = (opts.boon ~= false)
  curseCharge, swiftcursing = opts.charges or 10, false
  shaman = { spiritlore = { bashType = opts.bashType or "swiftcurse" },
             spiritisbound = function() return false end }
end

-- jinx/002 as the game fires it: the jinx line spends the charge.
local function jinxResolves()
  deleteFull = function() end
  dofile("src_new/triggers/levi_ataxia/for_levi/leviticus/jinx/002_Can't_Jinx.lua")
end

describe("Thrice Cursed -- the swiftcurse rotation spends its jinx charges", function()
  it("swiftcurses while no jinx charge is banked", function()
    reset({ canJinx = false })
    expect(ataxiaBasher_shamanBashing()).toBe(SWIFT)
  end)

  it("jinxes the target the moment a charge is banked", function()
    reset({ canJinx = true })
    expect(ataxiaBasher_shamanBashing()).toBe(JINX)
  end)

  it("goes back to swiftcurse once the jinx has spent the charge", function()
    reset({ canJinx = true })
    expect(ataxiaBasher_shamanBashing()).toBe(JINX)
    jinxResolves()
    expect(ataxiaTemp.canJinx).toBe(false)
    expect(ataxiaBasher_shamanBashing()).toBe(SWIFT)
  end)

  it("jinxes even when the swiftcurse charges need a recharge", function()
    reset({ canJinx = true, charges = 1 })
    expect(ataxiaBasher_shamanBashing()).toBe(JINX)
  end)

  it("without the boon a banked charge is left alone (the swiftcurse rotation as before)", function()
    reset({ canJinx = true, boon = false })
    expect(ataxiaBasher_shamanBashing()).toBe(SWIFT)
  end)

  it("regeneration still wins below 60% health", function()
    reset({ canJinx = true, hp = 500 })
    expect(ataxiaBasher_shamanBashing()).toBe("stand;wield shield;invoke regeneration")
    expect(ataxiaTemp.thriceJinxAt).toBeNil() -- a heal round does not start the stale clock
  end)

  it("the jinx/curse bashtype is untouched", function()
    reset({ canJinx = true, bashType = "jinx" })
    expect(ataxiaBasher_shamanBashing()).toBe("jinx bleed bleed 7")
  end)
end)

describe("Thrice Cursed -- a jinx that never resolves cannot strand the rotation", function()
  it("keeps jinxing while the first send is recent", function()
    reset({ canJinx = true })
    expect(ataxiaBasher_shamanBashing()).toBe(JINX)
    clock = clock + (THRICE_JINX_STALE - 1)
    expect(ataxiaBasher_shamanBashing()).toBe(JINX)
  end)

  it("drops the charge belief and swiftcurses once it is stale", function()
    reset({ canJinx = true })
    expect(ataxiaBasher_shamanBashing()).toBe(JINX)
    clock = clock + THRICE_JINX_STALE
    expect(ataxiaBasher_shamanBashing()).toBe(SWIFT)
    expect(ataxiaTemp.canJinx).toBe(false)
  end)

  -- The round is rebuilt every 0.3s while the jinx waits in the queue: the clock runs from the
  -- FIRST send, or a rebuild loop would keep resetting it and the jinx would never go stale.
  it("is timed from the first send, not from every rebuild", function()
    reset({ canJinx = true })
    local last
    for _ = 1, THRICE_JINX_STALE * 3 do
      last = ataxiaBasher_shamanBashing()
      clock = clock + 0.5
    end
    expect(last).toBe(SWIFT)
  end)

  it("the stale clock is per charge: a resolved jinx clears it", function()
    reset({ canJinx = true })
    expect(ataxiaBasher_shamanBashing()).toBe(JINX)
    clock = clock + 5
    jinxResolves()
    expect(ataxiaTemp.thriceJinxAt).toBeNil()
    -- a fresh charge banked right after is spent, not judged by the old send
    ataxiaTemp.canJinx, ataxiaTemp.jinxCharge = true, 1
    clock = clock + 2
    expect(ataxiaBasher_shamanBashing()).toBe(JINX)
  end)
end)

-- v4.7.387, user pasted the live pair: "Your malign power may be unleashed in the form of a jinx
-- against your victim" / "Your malign power dissipates back to normal levels." -- a charge built
-- and wasted. Two causes, both closed here.
describe("Thrice Cursed -- the charge line arms the jinx and proves the boon", function()
  local TL = dofile("src_new/tests/trigger_lib.lua")
  local F = "src_new/triggers/levi_ataxia/for_levi/leviticus/jinx/001_Can_Jinx.lua"
  local P = TL.patterns(F)

  local function fire(opts)
    opts = opts or {}
    reset({ canJinx = false, boon = false, bashType = opts.bashType })
    ataxiaBasher.inMnemosyne = (opts.tower ~= false)
    ataxiaBasher.manual = true
    ataxia_isClass = function(c) return c == (opts.class or "Shaman") end
    dofile(F)
  end

  it("matches the line with or without its full stop", function()
    expect(TL.anyMatches(P, "Your malign power may be unleashed in the form of a jinx against your victim")).toBeTrue()
    expect(TL.anyMatches(P, "Your malign power may be unleashed in the form of a jinx against your victim.")).toBeTrue()
    expect(TL.anyMatches(P, "Your malign power dissipates back to normal levels.")).toBeFalse()
  end)

  it("arms the jinx and latches the boon: a Shaman swiftcursing in the tower", function()
    fire()
    expect(ataxiaTemp.canJinx).toBeTrue()
    expect(mnemThriceCursed).toBeTrue()
    expect(ataxiaBasher_shamanBashing()).toBe(JINX)
  end)

  it("does not latch outside the tower", function()
    fire({ tower = false })
    expect(ataxiaTemp.canJinx).toBeTrue()
    expect(mnemThriceCursed).toBe(false)
  end)

  it("does not latch on the jinx/curse bashtype (a regular curse charges a jinx anyway)", function()
    fire({ bashType = "jinx" })
    expect(mnemThriceCursed).toBe(false)
  end)

  it("does not latch for another class", function()
    fire({ class = "Serpent" })
    expect(mnemThriceCursed).toBe(false)
  end)
end)

-- Restore
target, ataxia, ataxiaBasher, ataxiaTemp = saved.target, saved.ataxia, saved.ataxiaBasher, saved.ataxiaTemp
shaman, getEpoch, mnemThriceCursed = saved.shaman, saved.getEpoch, saved.mnemThriceCursed
curseCharge, swiftcursing, deleteFull = saved.curseCharge, saved.swiftcursing, saved.deleteFull
ataxiaBasher_assembleBattlerage = saved.ataxiaBasher_assembleBattlerage
ataxia_isClass = saved.ataxia_isClass
