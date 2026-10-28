--- test_runeblade_empower.lua -- the `remweap` runeblade job (v4.7.465)
--
-- The job probes every knight weapon and sketches + EMPOWERs only the ones that are not
-- runeblades yet. Each step moves on from a game line, never a timer. These tests load the REAL
-- scripts (023_Weapon_Detect and gear_system/003) and drive the line handlers the temp triggers
-- call.

require("mock_mudlet")

ataxia = { settings = { separator = ";", paused = false } }
function ataxia_Echo() end
function ataxia_saveSettings() end
local toggles = {}
function ataxiaToggle(opt) toggles[#toggles + 1] = opt end

local realTempTimer, realKillTimer, realSend = tempTimer, killTimer, send
local realTempRegexTrigger = tempRegexTrigger
local timers, sent, regexes = {}, {}, {}
tempTimer = function(delay, fn) timers[#timers + 1] = { delay = delay, fn = fn }; return #timers end
killTimer = function(id) if timers[id] then timers[id].killed = true end end
send = function(cmd) sent[#sent + 1] = cmd end
tempRegexTrigger = function(p, fn) regexes[#regexes + 1] = { p = p, fn = fn }; return #regexes end

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/023_Weapon_Detect.lua",
  "src_new/scripts/levi_ataxia/levi/levi_scripts/gear_system/003_Runeblade_Empower.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("failed to load " .. f .. ": " .. tostring(err)) end
end
local R = ataxia.runeblade
R.echo = function() end

-- The user's WEAPONLIST, 2026-10-28 (a cut-down copy: 2 flails, staff and stiletto to drop).
local ROWS = {
  { id = "battleaxe590991", type = "battleaxe" }, { id = "stiletto582195", type = "stiletto" },
  { id = "staff569815", type = "staff" }, { id = "flail408566", type = "flail" },
  { id = "bastard405364", type = "bastard" }, { id = "flail343168", type = "flail" },
}
local realList = ataxia.weaponDetect.list

local function reset(rows)
  timers, sent, regexes, toggles = {}, {}, {}, {}
  ataxia.settings.paused = false
  ataxiaBasher = nil
  gmcp = { Char = { Vitals = { bal = "1", eq = "1", mp = "5000" } } }
  R.state = { running = false }
  ataxia.weaponDetect.list = function(cb) cb(rows) end
end

local function last() return sent[#sent] end

-- Fire the live (not killed, not yet run) timers with this delay.
local function fire(delay)
  local n = 0
  for _, t in ipairs(timers) do
    if t.delay == delay and not t.killed and not t.done then t.done = true; n = n + 1; t.fn() end
  end
  return n
end

-- Answer a probe: months (or nil) and the end-of-probe line.
local function probe(months)
  if months then R.onMonths(months) end
  R.onProbeEnd()
end

describe("runeblade: which weapons", function()
  it("keeps the 7 knight types, by type order then ID number", function()
    local ids = R.filterWeapons(ROWS)
    expect(table.concat(ids, ",")).toBe("flail343168,flail408566,battleaxe590991,bastard405364")
  end)
end)

describe("runeblade: WEAPONLIST keeps the Months column", function()
  it("hands rows with months to the callback", function()
    reset(ROWS)
    ataxia.weaponDetect.list = realList
    local got
    realList(function(rows) got = rows end)
    -- header, separator, one row, separator
    regexes[1].fn()
    regexes[2].fn()
    matches = { "", "battleaxe590991", "174", "172", "162", "n/a" }
    regexes[3].fn()
    regexes[2].fn()
    expect(got ~= nil).toBeTrue()
    expect(got[1].id).toBe("battleaxe590991")
    expect(got[1].months).toBe("n/a")
    expect(sent[1]).toBe("WEAPONLIST")
  end)
end)

describe("runeblade: the job", function()
  it("probes each weapon, then sketches by ID, empowers and verifies a bare one", function()
    reset({ { id = "battleaxe590991", type = "battleaxe" }, { id = "bastard405364", type = "bastard" } })
    R.start()
    expect(last()).toBe("probe battleaxe590991")
    probe(100)                                   -- already a runeblade
    expect(last()).toBe("probe bastard405364")
    probe(nil)                                   -- bare
    expect(toggles[1]).toBe("off")
    expect(last()).toBe("sketch lagul on bastard405364")
    R.onSketchDone()
    expect(last()).toBe("sketch lagua on bastard405364")
    R.onSketchDone()
    expect(last()).toBe("sketch laguz on bastard405364")
    R.onSketchDone()
    expect(last()).toBe("empower bastard405364")
    R.onEmpowerStart()
    R.onEmpowerDone()
    expect(last()).toBe("probe bastard405364")
    probe(100)
    expect(R.state.weapons["bastard405364"].status).toBe("empowered (100 months)")
    expect(R.state.weapons["battleaxe590991"].status).toBe("already (100 months)")
    expect(last()).toBe("sketch gebo on armour")
    for _ = 1, 4 do R.onSketchDone() end
    expect(R.state.running).toBeFalse()
    expect(toggles[2]).toBe("on")
  end)

  it("treats 'no need to duplicate runes' like a finished sketch", function()
    reset({ { id = "flail408566", type = "flail" } })
    R.start()
    probe(nil)
    expect(last()).toBe("sketch lagul on flail408566")
    R.onSketchDone()                             -- the duplicate line calls the same handler
    expect(last()).toBe("sketch lagua on flail408566")
  end)

  it("ignores lines that do not belong to the current step", function()
    reset({ { id = "flail408566", type = "flail" } })
    R.start()
    R.onSketchDone()
    R.onEmpowerDone()
    expect(last()).toBe("probe flail408566")
  end)

  it("reports a weapon with no empowerment after EMPOWER as FAILED", function()
    reset({ { id = "flail408566", type = "flail" } })
    R.start()
    probe(nil)
    for _ = 1, 3 do R.onSketchDone() end
    R.onEmpowerDone()
    probe(nil)
    expect(R.state.weapons["flail408566"].status:find("FAILED", 1, true) ~= nil).toBeTrue()
  end)

  it("holds EMPOWER until there is enough mana", function()
    reset({ { id = "flail408566", type = "flail" } })
    gmcp.Char.Vitals.mp = "1500"
    R.start()
    probe(nil)
    for _ = 1, 3 do R.onSketchDone() end
    expect(last()).toBe("sketch laguz on flail408566")
    gmcp.Char.Vitals.mp = "2400"
    fire(R.config.poll)
    expect(last()).toBe("empower flail408566")
  end)

  it("stops on a timeout and unpauses only if it paused the system", function()
    reset({ { id = "flail408566", type = "flail" } })
    R.start()
    probe(nil)
    fire(R.config.sketchTimeout)
    expect(R.state.running).toBeFalse()
    expect(toggles[1]).toBe("off")
    expect(toggles[2]).toBe("on")

    reset({ { id = "flail408566", type = "flail" } })
    ataxia.settings.paused = true
    R.start()
    probe(nil)
    R.stop()
    expect(#toggles).toBe(0)
  end)

  it("a stale timeout from an earlier step does nothing", function()
    reset({ { id = "flail408566", type = "flail" } })
    R.start()
    probe(nil)                                   -- the probe timeout is now stale
    fire(R.config.probeTimeout)
    expect(R.state.running).toBeTrue()
  end)

  it("list mode probes and reports, and never sketches or pauses", function()
    reset({ { id = "flail408566", type = "flail" } })
    R.list()
    probe(nil)
    expect(R.state.running).toBeFalse()
    expect(#toggles).toBe(0)
    expect(last()).toBe("probe flail408566")
    expect(R.state.weapons["flail408566"].status).toBe("needs runes + empower")
  end)

  it("will not start a run while the basher is on", function()
    reset({ { id = "flail408566", type = "flail" } })
    ataxiaBasher = { enabled = true }
    R.start()
    expect(#sent).toBe(0)
    expect(R.state.running).toBeFalse()
  end)
end)

-- Restore shared state for whoever runs after us (files share one Lua state).
ataxia.weaponDetect.list = realList
tempTimer, killTimer, send, tempRegexTrigger = realTempTimer, realKillTimer, realSend, realTempRegexTrigger
ataxia, ataxiaToggle, ataxiaBasher, gmcp, matches = nil, nil, nil, nil, nil
