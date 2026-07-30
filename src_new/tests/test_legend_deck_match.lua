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
