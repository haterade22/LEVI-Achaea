--- test_gear_audit.lua - Gear Audit summarizer, scoring and table-wrap helpers
-- Covers the pure logic only; display()/displayBis() call cecho and are verified in game.

local GEAR_AUDIT = "src_new/scripts/levi_ataxia/levi/levi_scripts/gear_system/001_Gear_Audit.lua"

-- The file registers event handlers at load; the mock supplies those stubs.
dofile(GEAR_AUDIT)

--------------------------------------------------------------------------------
-- wrapText
--------------------------------------------------------------------------------

describe("gearAudit.wrapText", function()
  it("returns a single line when the text fits", function()
    local lines = gearAudit.wrapText("+7% Dmg", 40)
    expect(#lines).toBe(1)
    expect(lines[1]).toBe("+7% Dmg")
  end)

  it("wraps on word boundaries without exceeding the width", function()
    local text = "Your attacks will deal 20% bonus damage to denizens"
    local lines = gearAudit.wrapText(text, 20)
    expect(#lines).toBeGreaterThan(1)
    for _, l in ipairs(lines) do
      expect(#l <= 20).toBeTrue()
    end
    expect(table.concat(lines, " ")).toBe(text)
  end)

  it("fills a line exactly at the width boundary", function()
    -- "abcde fghij" is exactly 11 chars
    local lines = gearAudit.wrapText("abcde fghij", 11)
    expect(#lines).toBe(1)
    local tight = gearAudit.wrapText("abcde fghij", 10)
    expect(#tight).toBe(2)
  end)

  it("hard-splits a word longer than the column", function()
    local lines = gearAudit.wrapText("supercalifragilistic", 6)
    expect(#lines).toBe(4)
    expect(lines[1]).toBe("superc")
    expect(table.concat(lines, "")).toBe("supercalifragilistic")
  end)

  it("keeps preceding text when a hard-split word follows", function()
    local lines = gearAudit.wrapText("hi supercalifragilistic", 6)
    expect(lines[1]).toBe("hi")
    expect(lines[2]).toBe("superc")
  end)

  it("returns one empty line for empty or nil input", function()
    expect(#gearAudit.wrapText("", 20)).toBe(1)
    expect(gearAudit.wrapText("", 20)[1]).toBe("")
    expect(#gearAudit.wrapText(nil, 20)).toBe(1)
  end)
end)

--------------------------------------------------------------------------------
-- tableRule / tableRow
--------------------------------------------------------------------------------

describe("gearAudit table helpers", function()
  it("builds a rule matching the padded column widths", function()
    -- widths {2, 3} -> "+" + 4 dashes + "+" + 5 dashes + "+"
    expect(gearAudit.tableRule({2, 3})).toBe("+----+-----+")
  end)

  it("pads cells to their column width", function()
    local row = gearAudit.tableRow({4, 6}, {"ab", "cd"}, {"yellow", "green"})
    expect(row).toContain("<yellow>ab   ")
    expect(row).toContain("<green>cd     ")
  end)

  it("renders blank continuation cells at full width", function()
    local row = gearAudit.tableRow({3}, {""}, {"light_grey"})
    expect(row).toBe("<cyan>| <light_grey>    <cyan>|")
  end)
end)

--------------------------------------------------------------------------------
-- consoleWidth
--------------------------------------------------------------------------------

describe("gearAudit.consoleWidth", function()
  it("honours a pinned width", function()
    gearAudit.config.display.width = 90
    expect(gearAudit.consoleWidth()).toBe(90)
    gearAudit.config.display.width = nil
  end)

  it("falls back when getColumnCount is unavailable", function()
    expect(gearAudit.consoleWidth()).toBe(gearAudit.config.display.fallback)
  end)
end)

--------------------------------------------------------------------------------
-- summarizeEffect - existing patterns still work
--------------------------------------------------------------------------------

describe("gearAudit.summarizeEffect - existing patterns", function()
  it("summarizes additional damage", function()
    expect(gearAudit.summarizeEffect({"Your attacks will deal an additional 7% damage."}))
      .toBe("+7% Dmg")
  end)

  it("summarizes celerity with battlerage condition", function()
    local s = gearAudit.summarizeEffect({
      "While you have stored battlerage, this increases your celerity by 2.",
      "This requires you to have battlerage.",
    })
    expect(s).toContain("Celerity +2 w/BR")
    expect(s).toContain("(Battlerage)")
  end)

  it("does not swallow following sentences in the ignore-resistance pattern", function()
    local s = gearAudit.summarizeEffect({
      "Your attacks ignore 8% of a denizen's physical blunt resistance.",
      "Your attacks will deal 12% bonus damage to denizens.",
    })
    expect(s).toContain("Ignore 8% Phys blunt")
    -- the greedy (.+) regression pulled the whole second sentence into the type
    expect(s:find("resistance%.") == nil).toBeTrue()
  end)

  it("keeps the full chance-effect clause", function()
    local s = gearAudit.summarizeEffect({
      "When struck, you have a 5% chance to trigger a defence when one is stripped.",
    })
    expect(s).toContain("trigger a defence when one is stripped")
  end)
end)

--------------------------------------------------------------------------------
-- summarizeEffect - new patterns
--------------------------------------------------------------------------------

describe("gearAudit.summarizeEffect - new patterns", function()
  local cases = {
    {"Your attacks will deal 20% bonus damage to denizens.", "+20% Bonus Dmg"},
    {"Your attacks will generate 16% more rage.", "+16% Rage Gen"},
    {"Causes you to generate 10% less rage.", "-10% Rage Gen"},
    {"Your battlerage abilities will deal 18% more damage.", "+18% BR Dmg"},
    {"Your battlerage abilities will generate 12% more rage.", "+12% BR Rage"},
    {"Increases the damage of your critical hits by 14%.", "+14% Crit Dmg"},
    {"Increases your chance to deal a critical hit by 9%.", "+9% Crit Chance"},
    {"You will lose 5% less experience upon death.", "-5% XP Loss"},
  }

  for _, case in ipairs(cases) do
    it("summarizes: " .. case[1], function()
      expect(gearAudit.summarizeEffect({case[1]})).toContain(case[2])
    end)
  end

  it("labels an on-crit clause, keeping the game's sentence order", function()
    expect(gearAudit.summarizeEffect({"When you critically strike, 16% of the damage is returned as health."}))
      .toBe("Crit: 16% of the damage is returned as health")
  end)

  it("labels a stored-battlerage clause", function()
    expect(gearAudit.summarizeEffect({"While you have any amount of stored battlerage, your health is boosted."}))
      .toContain("w/BR:")
  end)

  it("labels a bleed clause", function()
    expect(gearAudit.summarizeEffect({"When sustaining bleeding from your attacks, denizens take 8% more damage."}))
      .toContain("Bleed:")
  end)

  it("prefers the rage penalty over the bonus form", function()
    local s = gearAudit.summarizeEffect({"Causes you to generate 13% less rage."})
    expect(s).toContain("-13% Rage Gen")
    expect(s:find("+13") == nil).toBeTrue()
  end)
end)

--------------------------------------------------------------------------------
-- summarizeEffect - fallback
--------------------------------------------------------------------------------

describe("gearAudit.summarizeEffect - fallback", function()
  it("returns the full raw text with no truncation marker", function()
    local raw = "Your journey through the Halls of the Dead is measurably shorter than it once was."
    local s = gearAudit.summarizeEffect({raw})
    expect(s).toBe(raw)
    expect(s:find("%.%.$") == nil).toBeTrue()
  end)

  it("joins every raw effect line", function()
    local s = gearAudit.summarizeEffect({"Line one of nonsense.", "Line two of nonsense."})
    expect(s).toContain("Line one of nonsense.")
    expect(s).toContain("Line two of nonsense.")
  end)

  it("returns empty string for no effects", function()
    expect(gearAudit.summarizeEffect({})).toBe("")
    expect(gearAudit.summarizeEffect(nil)).toBe("")
  end)
end)

--------------------------------------------------------------------------------
-- scoreEffect / calculateScore
--------------------------------------------------------------------------------

describe("gearAudit.scoreEffect - new stats", function()
  it("extracts bonus damage", function()
    expect(gearAudit.scoreEffect({"Your attacks will deal 23% bonus damage to denizens."}).bonusDmgPct)
      .toBe(23)
  end)

  it("extracts crit damage and crit chance", function()
    expect(gearAudit.scoreEffect({"Increases the damage of your critical hits by 14%."}).critDmgPct).toBe(14)
    expect(gearAudit.scoreEffect({"Increases your chance to deal a critical hit by 9%."}).critChancePct).toBe(9)
  end)

  it("extracts battlerage damage and rage generation", function()
    expect(gearAudit.scoreEffect({"Your battlerage abilities will deal 18% more damage."}).brDmgPct).toBe(18)
    expect(gearAudit.scoreEffect({"Your battlerage abilities will generate 12% more rage."}).brRageGenPct).toBe(12)
    expect(gearAudit.scoreEffect({"Your attacks will generate 16% more rage."}).rageGenPct).toBe(16)
  end)

  it("scores a rage penalty negatively", function()
    expect(gearAudit.scoreEffect({"Causes you to generate 10% less rage."}).rageGenPct).toBe(-10)
  end)

  it("only scores bleed when a number is present", function()
    expect(gearAudit.scoreEffect({"When sustaining bleeding from your attacks, denizens take 8% more damage."}).bleedDmgPct)
      .toBe(8)
    expect(gearAudit.scoreEffect({"When sustaining bleeding from your attacks, denizens flee."}).bleedDmgPct)
      .toBeNil()
  end)
end)

describe("gearAudit.calculateScore - new stats", function()
  it("gives bonus damage the same weight as additional damage", function()
    local bonus = gearAudit.calculateScore(gearAudit.scoreEffect(
      {"Your attacks will deal 10% bonus damage to denizens."}))
    local additional = gearAudit.calculateScore(gearAudit.scoreEffect(
      {"Your attacks will deal an additional 10% damage."}))
    expect(bonus).toBe(additional)
  end)

  it("lists new stats in the breakdown", function()
    local _, breakdown = gearAudit.calculateScore(gearAudit.scoreEffect(
      {"Increases the damage of your critical hits by 14%."}))
    expect(#breakdown).toBe(1)
    expect(breakdown[1].stat).toBe("Crit Damage")
    expect(breakdown[1].points).toBeGreaterThan(0)
  end)

  it("subtracts points for a rage penalty", function()
    local score = gearAudit.calculateScore(gearAudit.scoreEffect(
      {"Causes you to generate 10% less rage."}))
    expect(score).toBeLessThan(0)
  end)

  it("still applies the battlerage conditional multiplier", function()
    local w = gearAudit.config.bisWeights
    local scored = gearAudit.scoreEffect({
      "Your battlerage abilities will deal 10% more damage.",
      "This requires you to have stored battlerage.",
    })
    expect(scored.brCondition).toBeTrue()
    local score = gearAudit.calculateScore(scored)
    expect(score).toBe(10 * w.brDmgPct * w.brMult)
  end)

  it("still applies the location conditional multiplier", function()
    local w = gearAudit.config.bisWeights
    local scored = gearAudit.scoreEffect({
      "Your attacks will deal 10% bonus damage to denizens.",
      "This requires you to be within an underground location.",
    })
    expect(scored.conditional).toBeTrue()
    local score = gearAudit.calculateScore(scored)
    expect(score).toBe(10 * w.bonusDmgPct * w.conditionalMult)
  end)
end)
