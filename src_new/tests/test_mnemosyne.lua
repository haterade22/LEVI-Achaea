--- test_mnemosyne.lua
-- Tests for the ataxia.mnemosyne Run Tracker module (HTTP client + reporter +
-- parsers). All Mudlet I/O is mocked; postHTTP/getHTTP are captured so the
-- serial queue can be driven deterministically.

-- ─── Mocks ───────────────────────────────────────────────────────────────────

-- test_runner already loads mock_mudlet, which provides send/cecho/tempTimer
-- (stores callbacks; does NOT auto-fire) / tempRegexTrigger / killTimer /
-- killTrigger / registerAnonymousEventHandler. Do NOT override those -- doing so
-- leaks no-op stubs into other test files and breaks them (test ordering differs
-- across platforms). Only postHTTP/getHTTP/yajl are missing from the mock, and
-- no other test uses them, so define just those.

local sent = {}          -- list of { url, payload } from postHTTP
local lastPayload        -- table most recently handed to yajl.to_string
local decodeNext         -- value yajl.to_value should return

yajl = {
  to_string = function(t) lastPayload = t; return "JSON" end,
  to_value = function(_) return decodeNext end,
}

postHTTP = function(_, url, _) table.insert(sent, { url = url, payload = lastPayload }) end
getHTTP = function(url, _) table.insert(sent, { url = url, payload = "GET" }) end

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}

dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/001_HTTP_Client.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/002_Reporter_API.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/003_Commands.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/004_Parsers.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/005_Ripple_Map.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/007_History.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/008_Explorer.lua")

local M = ataxia.mnemosyne

-- Fresh state before each scenario: enabled + token set, empty queue, run reset.
local function reset(active)
  ataxia.settings = { reporting = { enabled = true, token = "TESTTOKEN", url = M.DEFAULT_URL } }
  M._queue = {}
  M._busy = false
  M._watchdog = nil
  M._capturing = false
  M.run = { active = active and true or false, publicId = nil, ripple = 0,
            pendingMonsters = {}, lastOffered = {} }
  M._mobCandidate = nil
  M._mobTrig = nil
  sent = {}
  lastPayload = nil
  decodeNext = nil
end

-- Simulate the server completing the request at the queue head.
local function completeHead(response)
  local head = M._queue[1]
  if not head then error("completeHead: queue empty") end
  decodeNext = response
  M._onDone(nil, M._baseUrl() .. head.endpoint, response and "BODY" or "")
end

-- ─── _parseNamedBlock (pure) ─────────────────────────────────────────────────

describe("M._parseNamedBlock()", function()
  it("parses a single Name:  description entry", function()
    local out = M._parseNamedBlock({ "Aurum Scales:                Gain 25% resistance to psychic damage." })
    expect(#out).toBe(1)
    expect(out[1].name).toBe("Aurum Scales")
    expect(out[1].description).toBe("Gain 25% resistance to psychic damage.")
  end)

  it("joins a wrapped continuation line onto the previous entry", function()
    local out = M._parseNamedBlock({
      "Boulder:                      You can no longer move normally, but deal significant",
      "damage to all denizens present.",
    })
    expect(#out).toBe(1)
    expect(out[1].name).toBe("Boulder")
    expect(out[1].description).toBe("You can no longer move normally, but deal significant damage to all denizens present.")
  end)

  it("skips blank lines and dividers (80-dash and short)", function()
    local out = M._parseNamedBlock({
      string.rep("-", 80),
      "",
      "Restoration:                  Restore your resources instead.",
      "----",
    })
    expect(#out).toBe(1)
    expect(out[1].name).toBe("Restoration")
  end)

  it("treats an over-long 'Name:' as continuation, not a new entry", function()
    local longName = string.rep("x", 45)
    local out = M._parseNamedBlock({
      "Real Boon:                    A real description.",
      longName .. ":  not a real name because it is too long",
    })
    expect(#out).toBe(1)
    expect(out[1].name).toBe("Real Boon")
  end)

  it("requires two+ spaces after the colon (single-space is not an entry)", function()
    local out = M._parseNamedBlock({ "Name: only one space" })
    expect(#out).toBe(0)
  end)

  it("returns an empty table for empty input", function()
    local out = M._parseNamedBlock({})
    expect(#out).toBe(0)
  end)
end)

-- ─── Config helpers ──────────────────────────────────────────────────────────

describe("M._baseUrl() / M._cfg()", function()
  it("trims trailing slashes from the configured url", function()
    reset()
    ataxia.settings.reporting.url = "http://example.com:8000///"
    expect(M._baseUrl()).toBe("http://example.com:8000")
  end)

  it("falls back to DEFAULT_URL when url is empty", function()
    reset()
    ataxia.settings.reporting.url = ""
    expect(M._baseUrl()).toBe(M.DEFAULT_URL)
  end)

  it("creates ataxia.settings.reporting when absent without clobbering token", function()
    ataxia.settings = {}
    local c = M._cfg()
    expect(type(c)).toBe("table")
    c.token = "abc"
    expect(M._cfg().token).toBe("abc")  -- same persistent table returned
  end)
end)

-- ─── Serial queue ────────────────────────────────────────────────────────────

describe("serial POST queue", function()
  it("sends only one request at a time; head completion advances the queue", function()
    reset()
    M.reportMonsters("orcs")
    M.reportBoss("a dragon")
    expect(#sent).toBe(1)                       -- boss is queued behind monsters
    expect(sent[1].url).toContain("/monsters")
    completeHead({ ok = true })
    expect(#sent).toBe(2)
    expect(sent[2].url).toContain("/boss")
  end)

  it("ignores a done event whose URL is not the queue head's endpoint", function()
    reset()
    M.reportMonsters("orcs")
    expect(M._busy).toBeTrue()
    M._onDone(nil, "http://elsewhere.example/other", "")  -- not our head
    expect(M._busy).toBeTrue()                  -- still in flight, not advanced
    expect(#sent).toBe(1)
  end)

  it("stamps the token onto every payload", function()
    reset()
    M.reportBoss("a dragon")
    expect(sent[1].payload.token).toBe("TESTTOKEN")
    expect(sent[1].payload.boss).toBe("a dragon")
  end)
end)

-- ─── Monster buffering ───────────────────────────────────────────────────────

describe("monster buffering", function()
  it("accumulates and de-dupes spawns without sending immediately", function()
    reset(true)
    M.onMonsters("a host of orcs")
    M.onMonsters("a host of orcs")  -- duplicate
    M.onMonsters("a lone troll")
    expect(#M.run.pendingMonsters).toBe(2)
    expect(#sent).toBe(0)
  end)

  it("does nothing when no run is active (gated on _inRun)", function()
    reset(false)
    M.onMonsters("a host of orcs")
    expect(#M.run.pendingMonsters).toBe(0)
  end)

  it("_flushMonsters joins buffered spawns and clears the buffer", function()
    reset(true)
    M.onMonsters("a host of orcs")
    M.onMonsters("a lone troll")
    M._flushMonsters()
    expect(#sent).toBe(1)
    expect(sent[1].url).toContain("/monsters")
    expect(sent[1].payload.monsters).toBe("a host of orcs; a lone troll")
    expect(#M.run.pendingMonsters).toBe(0)
  end)
end)

-- ─── Ripple guard + bootstrap ────────────────────────────────────────────────

describe("onRipple", function()
  it("asserts run.active and flushes buffered monsters after the ripple", function()
    reset(false)
    ataxiaBasher = { inMnemosyne = true } -- in a dive: onRipple may (re)assert the run
    M.run.active = true                 -- pretend startRun already ran
    M.onMonsters("a host of orcs")
    M.run.active = false                -- onRipple must re-assert it (we're in Mnemosyne)
    M.onRipple(3)
    expect(M.run.active).toBeTrue()
    -- ripple 3 (>0) enqueued, monsters flushed behind it
    expect(sent[1].url).toContain("/ripple_level")
    ataxiaBasher = nil
  end)

  it("does not bootstrap a phantom run from a stray wade line outside Mnemosyne", function()
    reset(false)
    ataxiaBasher = nil                  -- not in a dive
    M.onRipple(7)
    expect(M.run.active).toBeFalse()    -- no phantom run
    expect(#sent).toBe(0)               -- nothing pushed
  end)

  it("skips /ripple_level when n <= current ripple", function()
    reset(true)
    M.run.ripple = 5
    M.onRipple(3)
    for _, s in ipairs(sent) do
      if s.url:find("/ripple_level") then error("should not have sent ripple_level") end
    end
  end)
end)

-- ─── Run lifecycle reset ─────────────────────────────────────────────────────

describe("run lifecycle", function()
  it("startRun clears buffered monsters/offered and resets ripple", function()
    reset(true)
    M.run.pendingMonsters = { "stale monster" }
    M.run.lastOffered = { "Stale Boon" }
    M.run.ripple = 12
    M.startRun()
    expect(#M.run.pendingMonsters).toBe(0)
    expect(#M.run.lastOffered).toBe(0)
    expect(M.run.ripple).toBe(0)
    expect(M.run.active).toBeTrue()
  end)

  it("endRun flushes final-wave monsters, then closes and resets", function()
    reset(true)
    M.run.pendingMonsters = { "a final wave" }
    M.endRun()
    expect(sent[1].url).toContain("/monsters")     -- flushed first (in flight)
    completeHead({ ok = true })                     -- let it finish
    expect(sent[2].url).toContain("/run_end")       -- run_end follows behind it
    expect(M.run.active).toBeFalse()
    expect(#M.run.pendingMonsters).toBe(0)
  end)

  it("a fresh wade (no pause) starts a NEW run", function()
    reset(false)
    M.onRunStart()
    expect(sent[1].url).toContain("/run_start")
  end)

  it("onRunPause marks the run; the next wade RESUMES (run_exists), not a new run_start", function()
    reset(true)
    M.run.ripple = 3
    M.onRunPause()
    expect(M.run.paused).toBeTrue()
    M.onRunStart()                                  -- re-enter the same wade
    expect(sent[1].url).toContain("/run_exists")    -- resume, not /run_start
    for _, s in ipairs(sent) do
      if s.url:find("/run_start") then error("paused re-wade must not start a new run") end
    end
    expect(M.run.paused).toBeNil()                  -- flag consumed
  end)

  it("a genuine startRun/endRun clears a stale pause flag", function()
    reset(true)
    M.run.paused = true
    M.startRun()                                    -- _resetRun clears it
    expect(M.run.paused).toBeNil()
  end)

  it("onRunEnd clears a stale pause flag even with telemetry OFF (no /run_exists on next fresh wade)", function()
    reset(true)
    ataxia.settings.reporting.enabled = false        -- telemetry off (the shipped default)
    M.run.paused = true
    M.onRunEnd()                                      -- _inRun() false -> endRun/_resetRun never run
    expect(M.run.paused).toBeNil()                    -- ...but the unconditional clear still fires
    ataxia.settings.reporting.enabled = true          -- re-enable, then a brand-new dive
    M.onRunStart()
    expect(sent[1].url).toContain("/run_start")       -- fresh run, NOT a resume
    for _, s in ipairs(sent) do
      if s.url:find("/run_exists") then error("a fresh wade after a real end must not resume") end
    end
  end)
end)

-- ─── Boon claim ──────────────────────────────────────────────────────────────

describe("onBoonClaim", function()
  it("reports the canonical name when the claim matches an offered boon", function()
    reset(true)
    M.run.lastOffered = { "Corrupted Lineage", "Aurum Scales" }
    M.onBoonClaim("corrupted lineage")   -- different casing
    expect(#sent).toBe(1)
    expect(sent[1].url).toContain("/boons_selected")
    expect(sent[1].payload.selected[1]).toBe("Corrupted Lineage")
  end)

  it("reports nothing when the claimed name was never offered", function()
    reset(true)
    M.run.lastOffered = { "Corrupted Lineage" }
    M.onBoonClaim("Some Typo")
    expect(#sent).toBe(0)
  end)
end)

-- ─── Boons offered ───────────────────────────────────────────────────────────

describe("boons offered reporting", function()
  it("posts /boons_offered IMMEDIATELY even with contemplate ON (not gated on the slow chain)", function()
    reset(true)
    ataxia.settings.reporting.contemplate = true    -- enrichment ON -- must NOT block the post
    M._reportBoonsOfferedEnriched({
      { name = "Azure Scales", description = "Gain 25% resistance to cold damage." },
      { name = "Iron Throat", description = "Gain 25% resistance to asphyxiation damage." },
    })
    expect(sent[1].url).toContain("/boons_offered")
    expect(sent[1].payload.offered[1].name).toBe("Azure Scales")
    expect(sent[1].payload.offered[2].name).toBe("Iron Throat")
  end)

  it("force-finishes a wedged prior capture instead of dropping the new boon capture", function()
    reset(true)
    -- Simulate a wedged capture still holding the single-slot lock.
    local flushed = false
    M._capturing = true
    M._captureForceFinish = function() flushed = true; M._capturing = false; M._captureForceFinish = nil end
    -- A new capture must flush the stale one and proceed, not be silently ignored.
    M._captureLines({ timeout = 1, onLine = function() return "stop" end, onDone = function() end })
    expect(flushed).toBeTrue()        -- the wedged capture was flushed
    expect(M._capturing).toBeTrue()   -- ...and this capture is now active (not dropped)
    if M._captureForceFinish then M._captureForceFinish() end -- cleanup
  end)
end)

-- ─── Boss objective ──────────────────────────────────────────────────────────

describe("onObjective", function()
  it("reports the boss when the objective is 'defeat <name>'", function()
    reset(true)
    M.onObjective("defeat Seasone the Industrious")
    expect(#sent).toBe(1)
    expect(sent[1].url).toContain("/boss")
    expect(sent[1].payload.boss).toBe("Seasone the Industrious")
  end)

  it("does not report a boss for a normal wave objective", function()
    reset(true)
    M.onObjective("defeat 1 waves of enemies (0/1)")
    expect(#sent).toBe(0)
  end)
end)

-- ─── Run end (true death / release) ──────────────────────────────────────────

describe("onRunEnd", function()
  it("ends the run when in a run", function()
    reset(true)
    M.onRunEnd()
    expect(sent[1].url).toContain("/run_end")
    expect(M.run.active).toBeFalse()
  end)

  it("does nothing when not in a run", function()
    reset(false)
    M.onRunEnd()
    expect(#sent).toBe(0)
  end)
end)

-- ─── Splinterbark tree curing (self-harm safety) ─────────────────────────────

describe("Splinterbark tree curing", function()
  -- Capture game commands (send), not HTTP (sent). Restores send even on failure.
  local function captureSend(fn)
    local captured, realSend = {}, send
    send = function(cmd) captured[#captured + 1] = cmd end
    local ok, err = pcall(fn, captured)
    send = realSend
    if not ok then error(err) end
  end

  it("does nothing when not in a Mnemosyne run", function()
    reset(false)
    ataxiaBasher = nil
    M._treeCuringOff = nil
    captureSend(function(captured)
      M.onSplinterbarkSeen()
      expect(#captured).toBe(0)
    end)
    expect(M._treeCuringOff).toBeNil()
  end)

  it("turns tree curing off once when seen in a run (transition-guarded)", function()
    reset(false)
    ataxiaBasher = { inMnemosyne = true }
    M._treeCuringOff = nil
    captureSend(function(captured)
      M.onSplinterbarkSeen()
      M.onSplinterbarkSeen() -- second status re-read must NOT re-send
      expect(#captured).toBe(1)
      expect(captured[1]).toBe("curing tree off")
    end)
    expect(M._treeCuringOff).toBeTrue()
    ataxiaBasher = nil
  end)

  it("restoreTreeCuring re-enables once, only if it was off", function()
    reset(false)
    M._treeCuringOff = true
    captureSend(function(captured)
      M.restoreTreeCuring()
      M.restoreTreeCuring() -- no-op the second time
      expect(#captured).toBe(1)
      expect(captured[1]).toBe("curing tree on")
    end)
    expect(M._treeCuringOff).toBeNil()
  end)

  it("restoreTreeCuring is a no-op when curing was never turned off", function()
    reset(false)
    M._treeCuringOff = nil
    captureSend(function(captured)
      M.restoreTreeCuring()
      expect(#captured).toBe(0)
    end)
  end)
end)

-- ─── Boon contemplate parsing (pure) ─────────────────────────────────────────

describe("M._parseContemplate()", function()
  it("extracts rarity, echoes, description, and quote", function()
    local info = M._parseContemplate({
      "Rarity:                 rare",
      "Can echo:               No",
      "You can no longer move normally, but when tumbling into a room, you will deal significant damage to all denizens",
      "present.",
      "",
      '"Some unstoppable forces have yet to meet their immovable object. But Heroes do not have time for metaphors."',
    })
    expect(info.rarity).toBe("rare")
    expect(info.num_echoes_possible).toBe(0)
    expect(info.description).toBe("You can no longer move normally, but when tumbling into a room, you will deal significant damage to all denizens present.")
    expect(info.quote).toBe("Some unstoppable forces have yet to meet their immovable object. But Heroes do not have time for metaphors.")
  end)

  it("maps 'Can echo: Yes' to 1 when no Maximum echoes line follows", function()
    local info = M._parseContemplate({ "Rarity:  legendary", "Can echo:  Yes", "Desc.", "", '"Q."' })
    expect(info.num_echoes_possible).toBe(1)
    expect(info.rarity).toBe("legendary")
  end)

  it("reads the real 'Maximum echoes: N' count, overriding the Yes floor", function()
    local info = M._parseContemplate({
      "Rarity:  rare", "Can echo:  Yes", "Maximum echoes:  3", "A description.", "", '"Q."',
    })
    expect(info.num_echoes_possible).toBe(3)
    expect(info.description).toBe("A description.") -- the meta line must not leak into desc
  end)
end)

-- ─── Contemplate merge keeps the offered description ──────────────────────────

describe("M._applyContemplate()", function()
  it("applies rarity/quote/echoes but never overwrites the offered description", function()
    local boon = { name = "Fae-Lapse", description = "There is a 5% chance you give the denizen amnesia." }
    -- Even if contemplate mis-parsed a description (e.g. the BOON CLAIM footer),
    -- the offered description must be preserved.
    M._applyContemplate(boon, {
      rarity = "common", quote = "q", num_echoes_possible = 1,
      description = "BOON CLAIM <boon name> to pick one of the options.",
    })
    expect(boon.description).toBe("There is a 5% chance you give the denizen amnesia.")
    expect(boon.rarity).toBe("common")
    expect(boon.quote).toBe("q")
    expect(boon.num_echoes_possible).toBe(1)
  end)
end)

-- ─── startRun failure recovery (#1) ──────────────────────────────────────────

describe("startRun failure handling", function()
  it("resets run.active when /run_start errors so later pushes don't fire", function()
    reset(false)
    M.startRun()
    expect(M.run.active).toBeTrue() -- optimistic
    expect(M._queue[1].endpoint).toBe("/run_start")
    -- the server 500s the start
    M._onError(nil, "Internal Server Error", M._baseUrl() .. "/run_start")
    expect(M.run.active).toBeFalse() -- undone by the onError callback
    expect(M._inRun()).toBeFalse() -- so no ripple/monsters/etc. gate through afterwards
  end)

  it("also resets run.active when /run_start times out (watchdog path)", function()
    reset(false)
    M.startRun()
    expect(M.run.active).toBeTrue()
    expect(M._busy).toBeTrue()
    M._onTimeout() -- watchdog fires: dropped response / POST silently redirected to GET
    expect(M.run.active).toBeFalse() -- onError ran via the watchdog too
    expect(M._busy).toBeFalse() -- queue advanced
  end)
end)

describe("M._toggleState()", function()
  it("forces on/off and toggles for anything else (no ternary fall-through)", function()
    expect(M._toggleState("on", false)).toBeTrue()
    expect(M._toggleState("on", true)).toBeTrue()
    expect(M._toggleState("off", true)).toBeFalse()
    expect(M._toggleState("off", false)).toBeFalse() -- the bug: must stay off, not toggle
    expect(M._toggleState("", false)).toBeTrue() -- bare arg => toggle
    expect(M._toggleState("", true)).toBeFalse()
  end)
end)

describe("run-end confirmation", function()
  it("clears bardWarmarch only when onRunEnd commits, not on the deferred maybe", function()
    reset(true)
    bardWarmarch = true
    M.onRunEndMaybe() -- arms the confirmation window; must NOT clear the flag yet
    expect(bardWarmarch).toBeTrue()
    M.onRunEnd() -- confirmation fired
    expect(bardWarmarch).toBeFalse()
  end)

  it("clears bmShatteredStar (multislash boon) on the confirmed onRunEnd", function()
    reset(true)
    bmShatteredStar = true
    M.onRunEndMaybe() -- deferred maybe must NOT clear the boon yet
    expect(bmShatteredStar).toBeTrue()
    M.onRunEnd() -- confirmation fired -> boons gone
    expect(bmShatteredStar).toBeFalse()
  end)

  it("clears magiKkractle (elemental-surge boon) on the confirmed onRunEnd", function()
    reset(true)
    magiKkractle = true
    M.onRunEndMaybe() -- deferred maybe must NOT clear the boon yet
    expect(magiKkractle).toBeTrue()
    M.onRunEnd() -- confirmation fired -> boons gone
    expect(magiKkractle).toBeFalse()
  end)

  it("clears mnemHammerAnvil (shield-bypass boon) on the confirmed onRunEnd", function()
    reset(true)
    mnemHammerAnvil = true
    M.onRunEndMaybe() -- deferred maybe must NOT clear the boon yet
    expect(mnemHammerAnvil).toBeTrue()
    M.onRunEnd() -- confirmation fired -> boons gone
    expect(mnemHammerAnvil).toBeFalse()
  end)

  it("clears bmBladedReflexes (shin-augment boon) on the confirmed onRunEnd", function()
    reset(true)
    bmBladedReflexes = true
    M.onRunEndMaybe() -- deferred maybe must NOT clear the boon yet
    expect(bmBladedReflexes).toBeTrue()
    M.onRunEnd() -- confirmation fired -> boons gone
    expect(bmBladedReflexes).toBeFalse()
  end)

  it("clears mnemReaper AND the kill tally on the confirmed onRunEnd", function()
    reset(true)
    mnemReaper = true
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.reaperKills = 42
    M.onRunEndMaybe() -- deferred maybe must NOT clear the boon yet
    expect(mnemReaper).toBeTrue()
    expect(ataxiaTemp.reaperKills).toBe(42)
    M.onRunEnd() -- confirmation fired -> boons gone, tally dies with the run
    expect(mnemReaper).toBeFalse()
    expect(ataxiaTemp.reaperKills).toBeNil()
  end)
end)

-- ─── Reaper tithe counter ────────────────────────────────────────────────────

describe("M.onReaperTithe()", function()
  it("counts each tithe and sets the boon flag (the line is its own proof)", function()
    reset(true)
    mnemReaper = false
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.reaperKills = nil
    M.onReaperTithe()
    expect(mnemReaper).toBeTrue()
    expect(ataxiaTemp.reaperKills).toBe(1)
    M.onReaperTithe()
    M.onReaperTithe()
    expect(ataxiaTemp.reaperKills).toBe(3) -- additive: +3% damage total
  end)

  it("resumes an existing tally (ataxiaTemp survives a SYSUPDATE reload)", function()
    reset(true)
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.reaperKills = "17" -- persisted values can come back as strings
    M.onReaperTithe()
    expect(ataxiaTemp.reaperKills).toBe(18)
  end)
end)

-- ─── Haemophiliac affix pacing ───────────────────────────────────────────────

describe("Haemophiliac wade-slower pacing", function()
  it("onHaemophiliacSeen arms the flag only inside the tower", function()
    reset(true)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = false
    mnemHaemophiliac = false
    M.onHaemophiliacSeen()
    expect(mnemHaemophiliac).toBeFalse() -- a `mnem affixes` read outside a run must not arm it
    ataxiaBasher.inMnemosyne = true
    M.onHaemophiliacSeen()
    expect(mnemHaemophiliac).toBeTrue()
    M.onHaemophiliacSeen() -- transition-guarded: a status re-read is a no-op
    expect(mnemHaemophiliac).toBeTrue()
    ataxiaBasher.inMnemosyne = false
  end)

  it("_haemoHold holds until the bleed is CLOTTED and HP is back", function()
    mnemHaemophiliac = false
    ataxia.vitals = { hpp = 50, bleed = 900 }
    expect(M._haemoHold()).toBeFalse() -- no affix: never hold
    mnemHaemophiliac = true
    expect(M._haemoHold()).toBeTrue()  -- low HP AND bleeding: hold
    ataxia.vitals = { hpp = 95, bleed = 400 }
    expect(M._haemoHold()).toBeTrue()  -- HP fine but STILL BLEEDING: keep clotting (user spec)
    ataxia.vitals = { hpp = 60, bleed = 0 }
    expect(M._haemoHold()).toBeTrue()  -- clotted but HP still down: recover first
    ataxia.vitals = { hpp = 95, bleed = 10 }
    expect(M._haemoHold()).toBeFalse() -- clotted + healed: move on
    ataxia.vitals = { hpp = 95 }       -- no bleed reading at all (charstats missing)
    expect(M._haemoHold()).toBeFalse() -- treated as 0, never wedges
    mnemHaemophiliac = false
  end)

  it("clears on the confirmed run end", function()
    reset(true)
    mnemHaemophiliac = true
    M.onRunEnd()
    expect(mnemHaemophiliac).toBeFalse()
  end)
end)

describe("M.reaperOnWade()", function()
  it("resets the tally on a genuinely fresh wade", function()
    reset(true)
    M.run.paused = nil
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.reaperKills = 12
    expect(M.reaperOnWade()).toBeFalse()
    expect(ataxiaTemp.reaperKills).toBeNil()
  end)

  it("preserves the tally on a resume-after-pause wade (same server-side run)", function()
    reset(true)
    M.run.paused = true -- WADE STILL happened; the next wade re-enters the SAME run
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.reaperKills = 20
    expect(M.reaperOnWade()).toBeTrue()
    expect(ataxiaTemp.reaperKills).toBe(20) -- +20% is server-side truth; the count must survive
    M.run.paused = nil
  end)
end)

-- ─── Boon claim resolution (#4) ──────────────────────────────────────────────

describe("M._resolveClaim()", function()
  local offered = { "Aurum Scales", "Boulder", "Hammer and Nail" }

  it("resolves a slot number to the offered boon at that index", function()
    expect(M._resolveClaim("2", offered)).toBe("Boulder")
  end)

  it("resolves an exact case-insensitive name", function()
    expect(M._resolveClaim("boulder", offered)).toBe("Boulder")
  end)

  it("resolves a unique case-insensitive prefix", function()
    expect(M._resolveClaim("ham", offered)).toBe("Hammer and Nail")
  end)

  it("returns nil for an ambiguous prefix", function()
    expect(M._resolveClaim("a", { "Argent", "Aurum" })).toBeNil()
  end)

  it("returns nil for an out-of-range slot or an unknown name", function()
    expect(M._resolveClaim("9", offered)).toBeNil()
    expect(M._resolveClaim("nope", offered)).toBeNil()
  end)
end)

-- ─── Local run history (#6) ──────────────────────────────────────────────────

describe("local run history", function()
  local function freshHistory()
    M.history = { run = 0, claims = {}, offers = {}, affixes = {}, library = {} }
    ataxia.settings = { reporting = { enabled = true, token = "T", url = M.DEFAULT_URL, quiet = true } }
    M.run = { active = true, ripple = 4, pendingMonsters = {}, lastOffered = {} }
  end

  it("borrows rarity/description from recorded offers and counts echoes per run", function()
    freshHistory()
    M._historyNewRun() -- run 1
    M._recordOffers({ { name = "Boulder", description = "Roll for damage.", rarity = "rare" } })
    M._recordClaim("Boulder")
    M._recordClaim("Boulder") -- stack an echo
    expect(#M.history.claims).toBe(2)
    expect(M.history.claims[1].rarity).toBe("rare")
    expect(M.history.claims[1].description).toBe("Roll for damage.")
    expect(M.history.claims[1].echoes).toBe(1)
    expect(M.history.claims[2].echoes).toBe(2)
    expect(M.history.claims[1].run).toBe(1)
  end)

  it("dedupes affixes per run and grows the all-time library", function()
    freshHistory()
    M._historyNewRun() -- run 1
    M._recordAffixes({ { name = "Frostbite", description = "Chills." }, { name = "Ember", description = "Burns." } })
    M._recordAffixes({ { name = "Frostbite", description = "Chills." } }) -- repeat within the same run
    local run1 = 0
    for _, a in ipairs(M.history.affixes) do if a.run == 1 then run1 = run1 + 1 end end
    expect(run1).toBe(2) -- Frostbite recorded once despite two sightings
    expect(M.history.library["Frostbite"]).toBe("Chills.")
    expect(M.history.library["Ember"]).toBe("Burns.")
  end)

  it("scopes reports to the current run and doesn't error", function()
    freshHistory()
    M._historyNewRun() -- run 1
    M._recordOffers({ { name = "A", description = "d", rarity = "common" } })
    M._recordClaim("A")
    M._historyNewRun() -- run 2: run 1's claims are out of scope now
    local run2 = 0
    for _, c in ipairs(M.history.claims) do if c.run == M.history.run then run2 = run2 + 1 end end
    expect(run2).toBe(0)
    M.reportBoons() -- smoke: must not error
    M.reportAffixes()
    M.reportLibrary()
  end)

  it("bumps the history run when onRipple bootstraps a run (missed start line)", function()
    M.history = { run = 0, claims = {}, offers = {}, affixes = {}, library = {} }
    reset(false)
    ataxiaBasher = { inMnemosyne = true }
    M.onRipple(3) -- start line was missed -> onRipple bootstraps the run
    expect(M.history.run).toBe(1) -- got its own bucket, not run 0
    ataxiaBasher = nil
  end)
end)

-- ─── Explorer (auto-sweep) ───────────────────────────────────────────────────

describe("mnem explore", function()
  local MAP = ataxia.mnemosyne.map

  it("reads room-clear from ataxia.denizensHere (ground truth)", function()
    ataxia.denizensHere = {}
    expect(M._roomHasDenizens()).toBeFalse()
    ataxia.denizensHere = { [123] = "a snarling wolf" }
    expect(M._roomHasDenizens()).toBeTrue()
    ataxia.denizensHere = {}
  end)

  it("onWrongDir condemns + prunes the exit and ends the move (server wall)", function()
    MAP.reset()
    MAP.onRoom(1, "A", { north = 2, east = 0 }, nil) -- in room A; north is a (faked) exit
    M.explore.on = true
    M.explore.moving = true
    M.explore.fromRoom = 1
    M.explore.fromDir = "n"
    M.explore.failed = {}
    M.onWrongDir("n") -- server sends the short dir; normDir -> "north" (long-form keys)
    expect(M.explore.failed[1]["north"]).toBeTrue() -- exit condemned for the session
    expect(MAP.rooms[1].exits["north"]).toBeNil()    -- faked exit pruned from the known graph
    expect(M.explore.moving).toBeFalse()             -- move ended now, not after MOVE_TIMEOUT
    M.explore.on = false
  end)

  it("onWrongDir is a no-op when no explorer move is in flight", function()
    MAP.reset()
    MAP.onRoom(1, "A", { north = 2 }, nil)
    M.explore.on = true
    M.explore.moving = false -- nothing in flight
    M.explore.failed = {}
    M.onWrongDir("n")
    expect(MAP.rooms[1].exits["north"]).toBe(2) -- exit untouched
    expect(next(M.explore.failed)).toBeNil()     -- nothing condemned
    M.explore.on = false
  end)

  it("steps through an unexplored exit of the current room", function()
    MAP.reset()
    MAP.onRoom(1, "A", { north = 0, east = 0 }, nil) -- origin; two unwalked exits
    local dir = M._nextExploreStep()
    expect(dir == "n" or dir == "e").toBeTrue()
  end)

  it("returns nil when the reachable grid is fully swept", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil)
    MAP.onRoom(2, "B", { west = 1 }, nil) -- both exits now walked
    expect(M._nextExploreStep()).toBeNil()
  end)

  it("backtracks toward the nearest room that still has an unexplored exit", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2, north = 0 }, nil) -- A keeps an unexplored north
    MAP.onRoom(2, "B", { west = 1 }, nil) -- standing in B, nothing unexplored here
    expect(M._nextExploreStep()).toBe("w") -- step back west toward A
  end)

  it("takes a room's only exit even if non-planar (the holding room's `down`)", function()
    MAP.reset()
    MAP.onRoom(1, "holding", { down = 0 }, nil) -- ripple holding room: only exit is down into the 4x4
    expect(M._nextExploreStep()).toBe("d")
  end)

  it("never takes a grid room's deeper non-planar exit when planar ones exist", function()
    MAP.reset()
    MAP.onRoom(10, "grid", { north = 0, down = 0 }, nil) -- planar exit + a deeper down
    expect(M._nextExploreStep()).toBe("n") -- planar taken; the down is ignored
  end)

  it("never takes an up/in/out exit -- only `down` is a valid non-planar move", function()
    MAP.reset()
    MAP.onRoom(1, "up-only", { up = 0 }, nil) -- only an up exit; Mnemosyne has no `up`
    expect(M._nextExploreStep()).toBeNil()
    MAP.reset()
    MAP.onRoom(2, "out-only", { out = 0 }, nil) -- likewise no `in`/`out`
    expect(M._nextExploreStep()).toBeNil()
  end)

  it("patrols visited rooms once the grid is swept (to hunt a boss-ripple boss)", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil)
    MAP.onRoom(2, "B", { west = 1, east = 3 }, "east")
    MAP.onRoom(3, "C", { west = 2 }, "east") -- standing in 3; all exits walked
    expect(M._nextExploreStep()).toBeNil() -- nothing unexplored -> would have stopped before
    M.explore.patrolQueue = nil
    M.explore.patrolLoops = 0
    expect(M._nextPatrolStep()).toBe("w") -- re-visits a prior room instead of quitting
    expect(M.explore.patrolLoops).toBe(1) -- one refill = one loop counted
  end)

  it("never patrols UP out of the grid to the holding room", function()
    MAP.reset()
    MAP.onRoom(1, "holding", { down = 2 }, nil)          -- entry holding room: only `down`
    MAP.onRoom(2, "entry", { up = 1, east = 3 }, "down") -- descend into the 4x4 (walked edge up<->down)
    MAP.onRoom(3, "B", { west = 2 }, "east")             -- one grid room over; grid fully walked
    expect(M._nextExploreStep()).toBeNil()               -- nothing unexplored -> would patrol
    M.explore.patrolQueue = nil
    M.explore.patrolLoops = 0
    local step = M._nextPatrolStep()
    expect(step).toBe("w")        -- re-visits grid room 2 via WEST, never `up` toward holding
    -- the pure-vertical holding room (1) is excluded from the patrol queue entirely
    for _, num in ipairs(M.explore.patrolQueue) do expect(num).toBe(2) end
  end)

  it("backtracks toward unexplored via a planar step, never `up`", function()
    MAP.reset()
    MAP.onRoom(1, "holding", { down = 2 }, nil)
    MAP.onRoom(2, "entry", { up = 1, east = 3, north = 0 }, "down") -- entry keeps an unexplored NORTH
    MAP.onRoom(3, "dead", { west = 2 }, "east")                     -- dead-end grid room; nothing unexplored here
    -- Standing in 3 (no unexplored): backtrack to 2 (which has the unexplored north).
    expect(M._nextExploreStep()).toBe("w") -- first step of the backtrack path 3->2, planar; never `up`
  end)

  it("watchdog nudge issues a QL to refresh a stalled room", function()
    ataxia.denizensHere = {}
    M.explore.on = true
    M.explore.moving = false
    local captured, realSend = {}, send
    send = function(cmd) captured[#captured + 1] = cmd end
    local ok = pcall(M._watchdogNudge) -- restore send even if it throws
    send = realSend
    expect(ok).toBeTrue()
    local sawQL = false
    for _, c in ipairs(captured) do if c == "ql" then sawQL = true end end
    expect(sawQL).toBeTrue()
    M.explore.on = false
  end)

  it("watchdog nudge is a no-op when the explorer is off (no stray QL)", function()
    M.explore.on = false
    local captured, realSend = {}, send
    send = function(cmd) captured[#captured + 1] = cmd end
    pcall(M._watchdogNudge)
    send = realSend
    expect(#captured).toBe(0)
  end)

  it("watchdog nudge does NOT QL while a move is in flight (protects the ice-slip loop)", function()
    ataxia.denizensHere = {}
    M.explore.on = true
    M.explore.moving = true -- e.g. mid ice-slip: MAX_ICE_SLIPS must own this, not a ql
    local captured, realSend = {}, send
    send = function(cmd) captured[#captured + 1] = cmd end
    pcall(M._watchdogNudge)
    send = realSend
    expect(#captured).toBe(0)
    M.explore.on = false
    M.explore.moving = false
  end)

  it("arrival handler ends the move only when the room actually changed", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 0 }, nil) -- MAP.current = 1
    M.explore.on = true
    M.explore.moving = true
    M.explore.fromRoom = 1                 -- we left room 1...
    MAP.onRoom(2, "B", { west = 1 }, "east") -- ...and arrived in 2; MAP.current = 2
    M._onExploreRoom()
    expect(M.explore.moving).toBeFalse()   -- genuine arrival: the move ends
    M.explore.on = false
    M.explore.moving = false
  end)

  it("arrival handler ignores a same-room re-push (ql) mid-move -- keeps `moving`", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 0 }, nil) -- MAP.current = 1
    M.explore.on = true
    M.explore.moving = true
    M.explore.fromRoom = 1 -- still in the room we're leaving (ice-slipping); a ql re-pushes room 1
    M._onExploreRoom()
    expect(M.explore.moving).toBeTrue() -- not an arrival: the ice-slip loop is left intact
    M.explore.on = false
    M.explore.moving = false
  end)

  it("opens a settle window on arrival and closes it on the first tick", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 0 }, nil)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    M.explore.on = true
    M.explore.moving = true
    M.explore.fromRoom = 1
    MAP.onRoom(2, "B", { west = 1 }, "east") -- genuine arrival in B
    M._onExploreRoom()
    expect(M.explore.settling).toBeTrue()  -- arrival -> keep the full TICK_DELAY (don't walk past a late-loading mob)
    ataxia.denizensHere = { [1] = "a mob" } -- room has a denizen -> the settle tick waits, not moves
    M._exploreTick()
    expect(M.explore.settling).toBeFalse() -- settle done; subsequent kills now react with FAST_TICK
    M.explore.on = false
    M.explore.moving = false
    ataxia.denizensHere = {}
    ataxiaBasher.inMnemosyne = false
  end)

  it("stops the sweep when slain", function()
    M.explore.on = true
    M.exploreOnDeath("Chief Constable Beck")
    expect(M.explore.on).toBeFalse()
  end)

  it("death is a no-op when not sweeping", function()
    M.explore.on = false
    local ok = pcall(M.exploreOnDeath, "some mob") -- also tolerates a nil/empty killer
    expect(ok).toBeTrue()
    expect(M.explore.on).toBeFalse()
  end)

  it("boon screen PAUSES the sweep and leaves the basher on (no longer disables it)", function()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.enabled = true; ataxiaBasher.manual = true
    M.explore.on = true
    M.explore.pausedAtBoon = false
    M.explore._prevBasher = { enabled = false, manual = false } -- basher was OFF before the sweep
    M.explore._raisedBasher = true
    M.onBoonScreen()
    expect(M.explore.pausedAtBoon).toBeTrue()   -- paused, not stopped
    expect(M.explore.on).toBeTrue()             -- lifecycle stays live (leave-tower/death still restore)
    expect(ataxiaBasher.enabled).toBeTrue()     -- basher NOT turned off
    expect(ataxiaBasher.manual).toBeTrue()      -- still in explore mode
    expect(type(M.explore._prevBasher)).toBe("table") -- original preserved for the real stop
    M.onBoonScreen()                            -- idempotent: a re-read doesn't re-pause/echo-spam
    expect(M.explore.pausedAtBoon).toBeTrue()
    M.explore.on = false; M.explore.pausedAtBoon = false; M.explore._prevBasher = nil
  end)

  it("mnem explore on resumes a boon pause: keeps ORIGINAL basher state, re-asserts explore mode, resets progress", function()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.enabled = true; ataxiaBasher.manual = true -- currently in explore mode
    ataxiaBasher.inMnemosyne = false            -- flickered false between floors: resume must re-assert
    M.explore.on = true
    M.explore.pausedAtBoon = true
    M.explore.hunting = true                     -- stale sweep progress from the prior ripple
    M.explore.patrolQueue = { 99 }
    M.explore.patrolLoops = 3
    M.explore._prevBasher = { enabled = false, manual = false } -- the real pre-sweep state
    M.exploreOn()                               -- resume / un-pause
    expect(M.explore.pausedAtBoon).toBeFalse()  -- un-paused
    expect(M.explore.on).toBeTrue()
    expect(M.explore._prevBasher.enabled).toBeFalse() -- NOT re-saved from the current explore-mode state
    expect(ataxiaBasher.inMnemosyne).toBeTrue() -- explore mode re-asserted
    expect(M.explore.hunting).toBeFalse()       -- progress reset for the new ripple
    expect(M.explore.patrolQueue).toBeNil()
    expect(M.explore.patrolLoops).toBe(0)
    M.explore.on = false; M.explore._prevBasher = nil; ataxiaBasher.inMnemosyne = false
  end)

  it("a paused tick does not navigate, but still stops + restores when the tower is left", function()
    MAP.reset()
    MAP.onRoom(1, "A", { north = 0 }, nil)      -- an unexplored exit a running tick WOULD take
    ataxia.denizensHere = {}
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true             -- inMnem() true
    ataxiaBasher.enabled = true; ataxiaBasher.manual = true
    M.explore.on = true
    M.explore.pausedAtBoon = true
    M.explore.moving = false
    M.explore._prevBasher = { enabled = false, manual = false }
    M.explore._raisedBasher = true
    M._exploreTick()                            -- paused + in tower: must not start a move
    expect(M.explore.moving).toBeFalse()
    expect(M.explore.pausedAtBoon).toBeTrue()
    ataxiaBasher.inMnemosyne = false            -- leave the tower
    M._exploreTick()                            -- a paused tick STILL detects the leave and stops
    expect(M.explore.on).toBeFalse()            -- stopped
    expect(ataxiaBasher.enabled).toBeFalse()    -- basher restored to the original (off)
    M.explore.on = false; M.explore.pausedAtBoon = false; M.explore._prevBasher = nil
  end)

  it("GO auto-resumes a boon pause: LOOKs then un-pauses; no-op when not paused", function()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    M.explore.on = true
    M.explore.pausedAtBoon = true
    M.explore._prevBasher = { enabled = false, manual = false }
    local captured, realSend = {}, send
    send = function(c) captured[#captured + 1] = c end
    M.exploreOnGo()
    send = realSend
    expect(M.explore.pausedAtBoon).toBeFalse()  -- un-paused
    expect(M.explore.on).toBeTrue()
    local sawLook = false
    for _, c in ipairs(captured) do if c == "look" then sawLook = true end end
    expect(sawLook).toBeTrue()                  -- LOOK sent to establish the holding room
    -- and it's a no-op when not paused (never resumes an explorer that isn't at a boon)
    M.explore.pausedAtBoon = false
    local c2, rs2 = {}, send
    send = function(c) c2[#c2 + 1] = c end
    M.exploreOnGo()
    send = rs2
    expect(#c2).toBe(0)
    M.explore.on = false; M.explore._prevBasher = nil; ataxiaBasher.inMnemosyne = false
  end)
end)

-- ─── Ripple map graph (pure) ─────────────────────────────────────────────────

describe("ripple map graph", function()
  local MAP = ataxia.mnemosyne.map

  it("assigns grid coordinates by direction of travel", function()
    MAP.reset()
    MAP.onRoom(100, "Start", { north = 200 }, nil) -- origin -> (0,0)
    MAP.onRoom(200, "North room", { south = 100, east = 300 }, "north")
    expect(MAP.rooms[100].x).toBe(0)
    expect(MAP.rooms[100].y).toBe(0)
    expect(MAP.rooms[200].x).toBe(0)
    expect(MAP.rooms[200].y).toBe(1)
    MAP.onRoom(300, "East room", { west = 200 }, "east")
    expect(MAP.rooms[300].x).toBe(1)
    expect(MAP.rooms[300].y).toBe(1)
  end)

  it("infers direction from the previous room's exits when moveDir is nil", function()
    MAP.reset()
    MAP.onRoom(1, "A", { north = 2 }, nil)
    MAP.onRoom(2, "B", { south = 1 }, nil) -- no moveDir; A.exits.north == 2
    expect(MAP.rooms[2].y).toBe(1)
  end)

  it("places rooms on a later pass once a neighbour's exit back becomes known", function()
    MAP.reset()
    MAP.onRoom(400, "A", { east = 0 }, nil) -- origin; gmcp doesn't know the neighbour yet
    MAP.onRoom(500, "B", { west = 0 }, nil) -- link still unknown both ways
    expect(MAP.rooms[500].x).toBe(0) -- current room is always anchored/visible
    -- re-enter A; gmcp now knows B, so A reports east->500 and relayout links them.
    MAP.onRoom(400, "A", { east = 500 }, nil)
    expect(MAP.rooms[400].x).toBe(0)
    expect(MAP.rooms[500].x).toBe(1)
    expect(MAP.rooms[500].y).toBe(0)
  end)

  it("coerces string exit dest ids so exits-dest inference still matches", function()
    MAP.reset()
    MAP.onRoom(1, "A", { north = "2" }, nil) -- gmcp reports dests as strings
    MAP.onRoom(2, "B", { south = "1" }, nil) -- no moveDir; must still resolve via A.exits.north
    expect(MAP.rooms[2].x).toBe(0)
    expect(MAP.rooms[2].y).toBe(1)
  end)

  it("places a new room from its back-exit when the forward exit is still 0", function()
    MAP.reset()
    -- gmcp reports 0 for a neighbour it doesn't know yet, so the origin's forward
    -- exit to 200 is 0: no forward match, no moveDir, no capture.
    MAP.onRoom(100, "Start", { east = 0 }, nil) -- origin at 0,0
    expect(MAP.rooms[100].x).toBe(0)
    -- but 200 reports a west exit back to the (now known) origin -> reverse infer.
    MAP.onRoom(200, "East room", { west = 100 }, nil)
    expect(MAP.rooms[200].x).toBe(1)
    expect(MAP.rooms[200].y).toBe(0)
    -- and the walked edge is derived in reverse, so pathfinding still works.
    local steps = MAP.path(200, 100)
    expect(#steps).toBe(1)
    expect(steps[1]).toBe("w")
  end)

  it("anchors to any already-placed neighbour, not just the room we came from", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil) -- origin 0,0
    MAP.onRoom(2, "B", { west = 1 }, nil) -- placed at 1,0 via its back-exit
    -- Arrive in 3 from 2, but 3 has no exit back to 2 (one-way) -- only a south
    -- exit to the already-placed room 1. It must anchor off 1.
    MAP.onRoom(3, "C", { south = 1 }, nil)
    expect(MAP.rooms[3].x).toBe(0)
    expect(MAP.rooms[3].y).toBe(1) -- 1 is south of 3, so 3 is north of 1
  end)

  it("marks exits reported but not walked as unexplored", function()
    MAP.reset()
    MAP.onRoom(1, "A", { north = 2, east = 9 }, nil)
    MAP.onRoom(2, "B", { south = 1 }, "north")
    expect(MAP.hasUnexplored(1)).toBeTrue()
    local un = MAP.unexploredExits(1)
    expect(#un).toBe(1)
    expect(un[1]).toBe("east")
    expect(MAP.hasUnexplored(2)).toBeFalse() -- only the south we came from
  end)

  it("pathfinds back through walked edges as short directions", function()
    MAP.reset()
    MAP.onRoom(1, "A", { north = 2 }, nil)
    MAP.onRoom(2, "B", { south = 1, east = 3 }, "north")
    MAP.onRoom(3, "C", { west = 2 }, "east")
    local steps = MAP.path(3, 1)
    expect(#steps).toBe(2)
    expect(steps[1]).toBe("w")
    expect(steps[2]).toBe("s")
  end)

  it("returns nil for an unreachable room", function()
    MAP.reset()
    MAP.onRoom(1, "A", {}, nil)
    MAP.rooms[99] = { num = 99, exits = {}, edges = {} } -- island, no edges
    expect(MAP.path(1, 99)).toBeNil()
  end)

  it("pathKnown routes over the exit graph when the WALKED graph is fragmented", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil) -- A reports an east exit to 2 (but we never walked it)
    -- 2 is placed/known (a neighbour reported it) but has NO walked edge back to 1 -- the demented
    -- tower dropped it. MAP.path (walked-only) can't reach it; pathKnown (known-exit graph) can.
    MAP.rooms[2] = { num = 2, name = "B", exits = { west = 1 }, edges = {}, visited = true }
    expect(MAP.path(1, 2)).toBeNil()          -- walked graph is fragmented
    local steps = MAP.pathKnown(1, 2)
    expect(steps and steps[1]).toBe("e")      -- ...but the known-exit graph routes east to B
  end)

  it("resets the graph only when the ripple number changes", function()
    MAP.reset()
    MAP._ripple = 5
    MAP.onRoom(1, "A", {}, nil)
    MAP.onRipple(5) -- same ripple: keep
    expect(MAP.rooms[1] ~= nil).toBeTrue()
    MAP.onRipple(6) -- new ripple: wipe
    expect(MAP.rooms[1]).toBeNil()
  end)

  it("re-seeds the current room from gmcp after a ripple reset", function()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    gmcp = gmcp or {}
    gmcp.Room = { Info = { num = 500, name = "New level", exits = {} } }
    MAP.reset()
    MAP._ripple = 1
    MAP.onRoom(1, "old room", {}, nil)
    MAP.onRipple(2) -- reset + re-seed the current room from gmcp
    expect(MAP.rooms[1]).toBeNil() -- old level wiped
    expect(MAP.rooms[500] ~= nil).toBeTrue() -- current room re-seeded
    expect(MAP.current).toBe(500)
    gmcp.Room = nil
    ataxiaBasher.inMnemosyne = false
  end)

  it("normalises and shortens directions", function()
    expect(MAP.normDir("n")).toBe("north")
    expect(MAP.normDir("NORTHEAST")).toBe("northeast")
    expect(MAP.shortDir("north")).toBe("n")
    expect(MAP.shortDir("southwest")).toBe("sw")
  end)
end)

-- ─── Monster capture (onGo commits the countdown-captured candidate) ─────────

describe("onGo monster capture", function()
  it("commits the FULL captured spawn line on GO! (tracker convention)", function()
    reset(true)
    M._mobCandidate = "Grave-soil erupts across Azdun as a ghastly horde of the restless dead rises, drawn forth by dark magics."
    M.onGo()
    expect(#M.run.pendingMonsters).toBe(1)
    expect(M.run.pendingMonsters[1]).toBe("Grave-soil erupts across Azdun as a ghastly horde of the restless dead rises, drawn forth by dark magics.")
    expect(M._mobCandidate).toBeNil()
  end)

  it("does nothing when there is no candidate", function()
    reset(true)
    M.onGo()
    expect(#M.run.pendingMonsters).toBe(0)
  end)
end)

-- ─── Post-countdown spawn-line capture (the one-shot trigger's decision) ──────

describe("M._mobCaptureLine()", function()
  it("survives the '0' the trigger self-fires on, then grabs the spawn line", function()
    M._mobCandidate = nil
    -- The `^.*$` trigger is armed while the "0" is being processed and fires on it.
    expect(M._mobCaptureLine("0")).toBeFalse()   -- countdown digit: keep waiting, DON'T stop
    expect(M._mobCandidate).toBeNil()
    expect(M._mobCaptureLine("")).toBeFalse()      -- a blank: keep waiting too
    local spawn = "A multitude of sibilant voices chant in unison as ormyrr warriors and priests march across Krenindala."
    expect(M._mobCaptureLine(spawn)).toBeTrue()    -- first real line: capture + stop
    expect(M._mobCandidate).toBe(spawn)            -- the WHOLE line, verbatim
  end)

  it("stops on GO! (no spawn line this wave) without capturing anything", function()
    M._mobCandidate = nil
    expect(M._mobCaptureLine("0")).toBeFalse()
    expect(M._mobCaptureLine("GO!")).toBeTrue()    -- GO! straight after 0: done, nothing captured
    expect(M._mobCandidate).toBeNil()
  end)

  it("trims surrounding whitespace from the captured spawn line", function()
    M._mobCandidate = nil
    expect(M._mobCaptureLine("   Mandibles clatter as a swarm closes in.  ")).toBeTrue()
    expect(M._mobCandidate).toBe("Mandibles clatter as a swarm closes in.")
  end)
end)

-- ─── Mob phrase extraction (pure) ────────────────────────────────────────────

describe("M._extractMob()", function()
  it("trims flavour and the verb, keeping 'a <quantifier> of <mob>' (single word)", function()
    local mob = M._extractMob("In a dull flash of grey-tinged light, a host of malagmae joins the fray.")
    expect(mob).toBe("a host of malagmae")
  end)

  it("keeps a multi-word mob and stops at the verb", function()
    local mob = M._extractMob("Leaves fall softly on warm winds as a group of dryad handmaidens step out of the forest with a giggle.")
    expect(mob).toBe("a group of dryad handmaidens")
  end)

  it("keeps an adjective between the article and the quantifier", function()
    local mob = M._extractMob("Grave-soil erupts across Azdun as a ghastly horde of the restless dead rises, drawn forth by dark magics.")
    expect(mob).toBe("a ghastly horde of the restless dead")
  end)

  it("handles 'the <mob> of <place>' (mob before 'of')", function()
    local mob = M._extractMob("Heavy splashing echoes through the caverns as the trolls of Riagath wade in from the dark ahead.")
    expect(mob).toBe("the trolls of Riagath")
  end)

  it("returns nil when there is no 'a <quantifier> of <mob>' phrase", function()
    expect(M._extractMob("The boss glares at you menacingly.")).toBeNil()
  end)
end)
