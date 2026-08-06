--- test_legend_deck_match.lua -- ldm.matchFullName + the battlerage ready-line feed (v4.7.167)
--
-- matchFullName was broken for EVERY comma-suffixed card and it was the root cause of a
-- whole family of bugs: the charge database never learned the truth (so `initDeck`'s
-- optimistic max stood forever), and the v4.7.166 "no charges" rejection handler never
-- ran at all. Live 2026-07-30: the layer drew Xylthus twice into a wall while reporting
-- "3 charge(s) left".

require("mock_mudlet")

ldm = { db = {}, deck = {} }
for _, k in ipairs({ "Xylthus", "Seasone", "Maran", "Matic", "Covenant", "Morimbuul",
                     "Nicator", "Bakios", "Slith" }) do
  ldm.db[k] = { name = k, max = 3 }
end

local okm = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/legend_deck/003_Legend_Deck_Functions.lua")
if not okm then error("Failed to load the legend deck functions file") end

describe("ldm.matchFullName -- the in-game name to db key", function()
  it("resolves a COMMA-SUFFIXED name (the bug that broke everything)", function()
    expect(ldm.matchFullName("Xylthus, the Outcast")).toBe("Xylthus")
    expect(ldm.matchFullName("Seasone, the Industrious")).toBe("Seasone")
  end)

  it("still resolves the plain and bare-first-word cases it always handled", function()
    expect(ldm.matchFullName("Maran")).toBe("Maran")
    expect(ldm.matchFullName("Maran La'Saen, Seraph of Creation")).toBe("Maran")
  end)

  it("resolves past a leading honorific, which the first-word rule never could", function()
    expect(ldm.matchFullName("Lord Nicator, The Chosen One")).toBe("Nicator")
  end)

  it("is case-insensitive and returns nil for a name we do not carry", function()
    expect(ldm.matchFullName("bakios")).toBe("Bakios")
    expect(ldm.matchFullName("Somebody, the Unknown")).toBe(nil)
    expect(ldm.matchFullName(nil)).toBe(nil)
  end)
end)

-- ---------------------------------------------------------------------------
-- The battlerage ready-line feed (basher/011).
-- ---------------------------------------------------------------------------
ataxiaBasher = ataxiaBasher or {}
ataxiaTemp = {}
local okr = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/basher/011_Battlerage_Ready_Lines.lua")
if not okr then error("Failed to load the battlerage ready-lines file") end

describe("ataxiaBasher_brReady -- the game's own cooldown feed", function()
  it("clears the owned rotation's stamp so the ability is ready NOW", function()
    ataxiaTemp = { rwBrAt = { collide = 999, bulwark = 999 } }
    expect(ataxiaBasher_brReady("Collide")).toBe("collide")
    expect(ataxiaTemp.rwBrAt.collide).toBe(nil)
    expect(ataxiaTemp.rwBrAt.bulwark).toBe(999) -- only the named ability
  end)

  it("is class-agnostic -- one handler serves every owned rotation", function()
    ataxiaTemp = { gdragonBrAt = { psidaze = 1 }, psionBrAt = { whirlwind = 1 }, dwBrAt = { lash = 1 } }
    expect(ataxiaBasher_brReady("Psidaze")).toBe("psidaze")
    expect(ataxiaBasher_brReady("Whirlwind")).toBe("whirlwind")
    expect(ataxiaBasher_brReady("Lash")).toBe("lash")
    expect(ataxiaTemp.gdragonBrAt.psidaze).toBe(nil)
    expect(ataxiaTemp.psionBrAt.whirlwind).toBe(nil)
    expect(ataxiaTemp.dwBrAt.lash).toBe(nil)
  end)

  it("releases an in-flight replay holding that same verb", function()
    ataxiaTemp = { rwBrAt = { etch = 500 }, rwBrPending = { verb = "etch", cmd = "etch rune at 7;" } }
    ataxiaBasher_brReady("Etch")
    expect(ataxiaTemp.rwBrPending).toBe(nil)
  end)

  it("leaves a replay for a DIFFERENT verb alone", function()
    ataxiaTemp = { rwBrAt = { collide = 1 }, rwBrPending = { verb = "onslaught", cmd = "onslaught 7;" } }
    ataxiaBasher_brReady("Collide")
    expect(ataxiaTemp.rwBrPending.verb).toBe("onslaught")
  end)

  -- BARD'S SHARED SLOTS (v4.7.230). Bard's rotation gates on battleRage_Timers.small/large/
  -- special, and nothing mapped a name to them -- so "You can use Moulinet again." was parsed
  -- and dropped, and we sat out the rest of a hardcoded 17s timer the game had already ended.
  it("clears the shared slot a Bard ability gates on", function()
    battleRage_Timers = { small = 11, large = 22, special = 33 }
    ataxiaTemp = {}
    expect(ataxiaBasher_brReady("Moulinet")).toBe("small")
    expect(battleRage_Timers.small).toBe(nil)
    expect(battleRage_Timers.large).toBe(22)    -- only the named ability's slot
    expect(battleRage_Timers.special).toBe(33)

    expect(ataxiaBasher_brReady("Howlslash")).toBe("large")
    expect(battleRage_Timers.large).toBe(nil)
    expect(ataxiaBasher_brReady("Trill")).toBe("special")
    expect(battleRage_Timers.special).toBe(nil)
  end)

  -- The pending timer must be KILLED, not just unhooked. Left alive it fires later and nils
  -- the slot again -- un-gating a NEWER arm early and earning a stream of "you must wait"
  -- refusals. Same stale-timer shape as the stun throttle (v4.7.219) and parry (v4.7.222).
  it("kills the pending timer rather than leaking it", function()
    local killed = {}
    local realKill = killTimer
    killTimer = function(id) killed[#killed + 1] = id; return true end
    battleRage_Timers = { small = 77 }
    ataxiaTemp = {}
    ataxiaBasher_brReady("Moulinet")
    killTimer = realKill
    expect(#killed).toBe(1)
    expect(killed[1]).toBe(77)
  end)

  it("no-ops safely when the slot is already clear", function()
    battleRage_Timers = {}
    ataxiaTemp = {}
    expect(ataxiaBasher_brReady("Moulinet")).toBe("small")
  end)

  -- Cyclone gates on an epoch stamp, not a timer.
  it("clears the cyclone stamp", function()
    battleRage_Timers = {}
    ataxiaTemp = { bardCycloneAt = 999999 }
    expect(ataxiaBasher_brReady("Cyclone")).toBe("cyclone")
    expect(ataxiaTemp.bardCycloneAt).toBe(nil)
  end)

  -- Charm is deliberately NOT cooldown-gated, so it must not map to a slot -- clearing one on
  -- its ready line would free an unrelated ability early.
  it("ignores an ability that is not cooldown-gated", function()
    battleRage_Timers = { small = 5, large = 6, special = 7 }
    ataxiaTemp = {}
    expect(ataxiaBasher_brReady("Charm")).toBe(nil)
    expect(battleRage_Timers.small).toBe(5)
    expect(battleRage_Timers.large).toBe(6)
    expect(battleRage_Timers.special).toBe(7)
  end)

  it("routes Cullingblade to its own flag, not a rotation stamp", function()
    ataxiaTemp = { bladeCooldown = true }
    expect(ataxiaBasher_brReady("Cullingblade")).toBe("culling")
    expect(ataxiaTemp.bladeCooldown).toBe(nil)
  end)

  it("ignores an unknown verb and junk input", function()
    ataxiaTemp = { rwBrAt = { collide = 1 } }
    expect(ataxiaBasher_brReady("Chaosgate")).toBe(nil)
    expect(ataxiaBasher_brReady(nil)).toBe(nil)
    expect(ataxiaTemp.rwBrAt.collide).toBe(1)
  end)
end)

ldm = nil
ataxiaTemp = {}
