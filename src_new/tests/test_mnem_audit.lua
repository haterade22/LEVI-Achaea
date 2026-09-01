--- test_mnem_audit.lua -- AUDIT capture (mnemosyne/013_Audit.lua)
--
-- The fixture below is a REAL block, transcribed from a live screenshot rather than invented, so
-- the column spacing, the mixed `56.93` / `78%` / `+60  -0` value forms and the dashed rules are
-- the ones the parser will actually meet.
--
-- What these pin is the reason the module exists: everything else on the bonuses panel is DERIVED
-- from a boon's description sentence, so a misparse produces a confident number with nothing to
-- contradict it (`Ogre's Defence` read as +2% for a day, v4.7.289). AUDIT is the game's own
-- accounting -- the one input here that can prove us wrong.

require("mock_mudlet")

ataxia = ataxia or {}
ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne
function M.echo() end
M.history = M.history or { run = 1 }

dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/013_Audit.lua")

local BLOCK = {
  "Audit records:",
  "Category                Value",
  "----------------------------------------",
  "Critical Rate:          56.93",
  "Critical Hit Bonus:     11.75",
  "Celerity:               2",
  "Endurance:              +60      -0",
  "Willpower:              +24      -0",
  "Cutting:                76.2%",
  "Blunt:                  78%",
  "Magical:                54%",
  "Fire:                   47.4%",
  "Cold:                   29.8%",
  "Poison:                 33.7%",
  "Asphyxiation:           22%",
  "Electricity:            26.4%",
  "Psychic:                22%",
  "----------------------------------------",
}

local function reset()
  M.audit = {}
  M.history = { run = 1 }
end

describe("audit block parsing", function()
  it("reads every row of a real block", function()
    reset()
    local a = M._parseAudit(BLOCK)
    expect(a.critRate).toBe(56.93)
    expect(a.critBonus).toBe(11.75)
    expect(a.celerity).toBe(2)
    expect(a.resists.Fire).toBe(47.4)
    expect(a.resists.Psychic).toBe(22)
  end)

  -- `Electricity` is AUDIT's spelling of our `Electric`. Every boon description says "electric
  -- damage", so without the alias the measured row and the derived row would never line up.
  it("normalises Electricity onto our Electric row", function()
    local a = M._parseAudit(BLOCK)
    expect(a.resists.Electric).toBe(26.4)
    expect(a.resists.Electricity).toBe(nil)
  end)

  -- CUTTING AND BLUNT ARE NOT `Physical`. The game tracks them separately and they carry
  -- different numbers in this very block (76.2 vs 78), so folding them -- which is the tempting
  -- thing, since every boon description says "physical" -- would invent a figure that is neither.
  it("keeps Cutting and Blunt apart, and never invents a Physical row", function()
    local a = M._parseAudit(BLOCK)
    expect(a.resists.Cutting).toBe(76.2)
    expect(a.resists.Blunt).toBe(78)
    expect(a.resists.Physical).toBe(nil)
  end)

  -- A bonus/penalty pair kept as two numbers. Netting them to +60 would hide a penalty, and the
  -- penalty is the half worth seeing.
  it("keeps the bonus and the penalty of a paired row", function()
    local a = M._parseAudit(BLOCK)
    expect(a.endurance.up).toBe(60)
    expect(a.endurance.down).toBe(0)
    expect(a.willpower.up).toBe(24)
    -- The live block reads "+60  -0", so netting the pair would be INVISIBLE against it -- the
    -- break-back for this passed until the case below was added. A fixture whose two branches
    -- agree is a fixture that tests neither.
    local r = M._auditRow("Endurance:              +60      -15")
    expect(r.up).toBe(60)
    expect(r.down).toBe(-15)
  end)

  -- The block is bracketed by dashed rules and headed by a column row. None of them is data, and
  -- a rule read as a row would put a nonsense entry on the panel.
  it("takes nothing from the rules, the header or the column row", function()
    expect(M._auditRow("----------------------------------------")).toBe(nil)
    expect(M._auditRow("Category                Value")).toBe(nil)
    expect(M._auditRow("Audit records:")).toBe(nil)
  end)

  -- A resistance row is recognised by its PERCENTAGE. A future category we have not seen would
  -- otherwise be silently promoted into a damage type -- a made-up row on the one panel section
  -- whose whole job is to be trustworthy.
  it("refuses to invent a resistance from a non-percentage row", function()
    expect(M._auditRow("Some New Thing:         7")).toBe(nil)
    expect(M._auditRow("Some New Thing:         7%").kind).toBe("resist")
  end)

  it("returns nil for a block with no rows at all", function()
    expect(M._parseAudit({ "Audit records:", "----------" })).toBe(nil)
    expect(M._parseAudit(nil)).toBe(nil)
  end)
end)

describe("baseline and delta", function()
  -- The baseline is the whole point and it must not drift: a baseline that moves forward with
  -- every capture measures nothing at all.
  it("keeps the FIRST capture as the baseline and tracks the latest as current", function()
    reset()
    M._auditRecord(M._parseAudit(BLOCK))
    local later = M._parseAudit(BLOCK)
    later.resists.Fire = 67.4
    M._auditRecord(later)
    expect(M.audit.baseline.resists.Fire).toBe(47.4)
    expect(M.audit.current.resists.Fire).toBe(67.4)
  end)

  it("reports the delta the run's boons actually bought", function()
    reset()
    M._auditRecord(M._parseAudit(BLOCK))
    local later = M._parseAudit(BLOCK)
    later.resists.Fire = 67.4
    later.critRate = 60.93
    M._auditRecord(later)
    local d = M._auditDelta()
    expect(math.floor(d.resists.Fire * 10 + 0.5)).toBe(200)  -- +20.0, float-safe
    expect(d.critRate).toBe(4)
    expect(d.resists.Psychic).toBe(nil)  -- unchanged types are absent, not zero
  end)

  -- "No second reading yet" and "the boons bought nothing" are different answers. Returning a
  -- table of zeroes for the first would print a measurement we never took.
  it("has NO delta from a single reading", function()
    reset()
    M._auditRecord(M._parseAudit(BLOCK))
    expect(M._auditDelta()).toBe(nil)
  end)
end)

describe("the wade-entry baseline", function()
  local sent
  local function withSend(fn)
    local real = send
    sent = {}
    send = function(c) sent[#sent + 1] = c end
    local ok, err = pcall(fn)
    send = real
    if not ok then error(err) end
  end

  -- ONCE PER RUN, unlike its neighbours in the explorer's entry block: re-asking every ripple
  -- would dump an eighteen-line block into the log at every boon screen, and a baseline is a
  -- run-scoped fact anyway.
  it("asks once per run, not once per ripple", function()
    reset()
    withSend(function()
      expect(M.auditBaselineOnWade()).toBeTrue()
      M._auditRecord(M._parseAudit(BLOCK))
      expect(M.auditBaselineOnWade()).toBeFalse()   -- same run, already have one
      expect(#sent).toBe(1)
    end)
  end)

  it("takes a fresh baseline on a NEW run", function()
    reset()
    withSend(function()
      M.auditBaselineOnWade()
      M._auditRecord(M._parseAudit(BLOCK))
      M.history.run = 2
      expect(M.auditBaselineOnWade()).toBeTrue()
      expect(#sent).toBe(2)
    end)
  end)

  -- Joining a run late is the case `reset` exists for: a baseline taken after boons were claimed
  -- measures nothing, so it must be droppable.
  it("mnem audit reset drops the baseline so the next capture becomes one", function()
    reset()
    withSend(function()
      M._auditRecord(M._parseAudit(BLOCK))
      expect(M.audit.baseline ~= nil).toBeTrue()
      M.auditSend(true)
      expect(M.audit.baseline).toBeNil()
    end)
  end)
end)

M.audit = nil
