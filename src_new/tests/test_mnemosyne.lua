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
  -- The client's transient state (watchdog id, send stamp, replay tally) lives here since v4.7.336.
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mnemHttp = nil
  M._capturing = false
  M.run = { active = active and true or false, publicId = nil, ripple = 0,
            pendingMonsters = {}, lastOffered = {} }
  M._mobCandidate = nil
  M._mobTrig = nil
  -- The deferred-offer slot is process-wide and survives a run; a leftover from an earlier test
  -- would now be FLUSHED by the next _offerAfterRipple rather than silently dropped.
  M._pendingOffer = nil
  M._pendingRerolls = nil
  M._offerTimer = nil
  -- The reroll chain lives on ataxiaTemp (never serialized), not on M.run.
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.mnemRerolls = nil
  ataxiaTemp.mnemOfferChain = nil
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

-- ─── A queue that came back from disk (v4.7.336) ─────────────────────────────
--
-- The live save held `_busy = true` and 711 unsent requests: one save caught a POST in flight,
-- deepMerge restored the flag on the next start with no request and no watchdog behind it, and
-- `_pump` returned early forever. These rebuild that state exactly -- plain request tables with
-- no callbacks (functions are stripped on save), a busy flag, no send stamp.

describe("a queue restored from disk (the nine-run wedge)", function()
  -- What deepMerge hands back: data only.
  local function restored(endpoints)
    local q = {}
    for i, ep in ipairs(endpoints) do
      q[i] = { endpoint = ep, payload = { token = "OLDTOKEN", n = i }, tries = 0 }
    end
    return q
  end

  local function quietly(fn)
    local real, said = M.echo, {}
    M.echo = function(m) said[#said + 1] = tostring(m) end
    local ok, err = pcall(fn, said)
    M.echo = real
    if not ok then error(err, 0) end
    return said
  end

  local function joined(said) return table.concat(said, "\n") end

  it("resumes and drains the restored queue in order, then the new request", function()
    reset(true)
    M._queue = restored({ "/death", "/run_start", "/ripple_level" })
    M._busy = true
    local said = quietly(function()
      M._resumeQueue("restored from disk")
      expect(#sent).toBe(1)
      expect(sent[1].url).toContain("/death")      -- the head that was in flight is sent again
      M.reportBoss("a dragon")                      -- a new request queues BEHIND the backlog
      expect(#sent).toBe(1)
      completeHead({ ok = true })
      completeHead({ ok = true })
      completeHead({ ok = true })
      expect(#sent).toBe(4)
      expect(sent[2].url).toContain("/run_start")
      expect(sent[3].url).toContain("/ripple_level")
      expect(sent[4].url).toContain("/boss")
    end)
    expect(joined(said)).toContain("Resuming")
    expect(joined(said)).toContain("3")
  end)

  it("a restored busy flag cannot wedge the queue even without the loader's call", function()
    -- The seam the bug lived in: `_enqueue` -> `_pump` with `_busy` true and nothing on the wire.
    -- Before v4.7.336 this returned early forever and sent nothing.
    reset(true)
    M._queue = restored({ "/death" })
    M._busy = true
    quietly(function() M.reportBoss("a dragon") end)
    expect(#sent).toBe(1)
    expect(sent[1].url).toContain("/death")
  end)

  it("sends the CURRENT token, not the one saved with the request", function()
    reset(true)
    M._queue = restored({ "/death" })
    M._busy = true
    quietly(function() M._resumeQueue("restored from disk") end)
    expect(sent[1].payload.token).toBe("TESTTOKEN")
  end)

  it("keeps timer ids OFF the saved namespace", function()
    reset(true)
    M.reportBoss("a dragon")
    expect(M._watchdog).toBeNil()
    expect(ataxiaTemp.mnemHttp.watchdog ~= nil).toBeTrue()
    expect(type(ataxiaTemp.mnemHttp.sentAt)).toBe("number")
  end)

  it("forgets, but never kills, a legacy watchdog id that came back from disk", function()
    reset(true)
    local mock = require("mock_mudlet")
    local stranger = tempTimer(99, function() end) -- whatever inherited the saved id
    M._watchdog = stranger
    M._queue = restored({ "/death" })
    M._busy = true
    quietly(function() M._resumeQueue("restored from disk") end)
    expect(M._watchdog).toBeNil()
    expect(mock.active_timers[stranger] ~= nil).toBeTrue()
    killTimer(stranger)
  end)

  it("aggregates a replay's refusals and failures into ONE summary", function()
    reset(true)
    M._queue = restored({ "/ripple_level", "/death", "/boss" })
    M._busy = true
    local said = quietly(function()
      M._resumeQueue("restored from disk")
      completeHead({ ok = false, message = "ripple lower than current" })
      completeHead({ ok = true })
      M._onError(nil, "Bad Request", M._baseUrl() .. "/boss")
    end)
    local text = joined(said)
    expect(text).toContain("Backlog replay done")
    expect(text).toContain("1 sent OK")
    expect(text).toContain("1 refused")
    expect(text).toContain("1 failed")
    expect(text).toContain("ripple lower than current") -- the first problem is named
    expect(text:find("Request failed", 1, true) == nil).toBeTrue()
    expect(text:find("refused<reset>", 1, true) == nil).toBeTrue()
    local summaries = 0
    for _, s in ipairs(said) do if s:find("Backlog replay done", 1, true) then summaries = summaries + 1 end end
    expect(summaries).toBe(1)
    expect(ataxiaTemp.mnemHttp.replayLeft).toBeNil()
  end)

  it("still echoes a failure for a request made THIS session", function()
    reset(true)
    local said = quietly(function()
      M.reportBoss("a dragon")
      M._onError(nil, "Bad Request", M._baseUrl() .. "/boss")
    end)
    expect(joined(said)).toContain("Request failed")
  end)

  it("a second resume mid-replay keeps the tally and does not double the summary", function()
    -- The reinstall path and the loader path can both run in one session.
    reset(true)
    M._queue = restored({ "/death", "/boss" })
    M._busy = true
    local said = quietly(function()
      M._resumeQueue("package reloaded")
      completeHead({ ok = true })
      M._resumeQueue("restored from disk")  -- the /boss in flight is sent again
      completeHead({ ok = true })
    end)
    local summaries = 0
    for _, s in ipairs(said) do if s:find("Backlog replay done", 1, true) then summaries = summaries + 1 end end
    expect(summaries).toBe(1)
    expect(joined(said)).toContain("2 sent OK")
  end)

  it("drops malformed restored entries instead of wedging on them", function()
    reset(true)
    M._queue = { "junk", { payload = {} }, { endpoint = "/boss", payload = { boss = "x" } } }
    M._busy = true
    quietly(function() M._resumeQueue("restored from disk") end)
    expect(#M._queue).toBe(1)
    expect(sent[1].url).toContain("/boss")
  end)

  it("an empty queue resumes silently", function()
    reset(true)
    local said = quietly(function() expect(M._resumeQueue("package reloaded")).toBe(0) end)
    expect(#said).toBe(0)
    expect(M._busy).toBeFalse()
  end)
end)

describe("the busy backstop (a lost watchdog)", function()
  it("times the head out when the send is older than STALE_BUSY", function()
    reset(true)
    local real = M.echo
    M.echo = function() end
    local ok, err = pcall(function()
      M.reportMonsters("orcs")
      expect(#sent).toBe(1)
      -- The watchdog was killed by someone else's killTimer; the send is long past due.
      ataxiaTemp.mnemHttp.watchdog = nil
      ataxiaTemp.mnemHttp.sentAt = getEpoch() - (M.STALE_BUSY + 5)
      M.reportBoss("a dragon")
      expect(#sent).toBe(2)
      expect(sent[2].url).toContain("/boss")
      expect(M._queue[1].endpoint).toBe("/boss")
    end)
    M.echo = real
    if not ok then error(err, 0) end
  end)

  it("does NOT overrule the watchdog while the request is still young", function()
    reset(true)
    M.reportMonsters("orcs")
    ataxiaTemp.mnemHttp.sentAt = getEpoch() - (M.REQUEST_TIMEOUT - 5)
    M.reportBoss("a dragon")
    expect(#sent).toBe(1)                          -- still waiting on /monsters
    expect(M._queue[1].endpoint).toBe("/monsters")
  end)

  it("runs the timed-out head's onError, exactly as the watchdog would", function()
    reset(false)
    local real = M.echo
    M.echo = function() end
    local ok, err = pcall(function()
      M.startRun()
      expect(M.run.active).toBeTrue()
      ataxiaTemp.mnemHttp.sentAt = getEpoch() - (M.STALE_BUSY + 5)
      M.reportBoss("a dragon")
      expect(M.run.active).toBeFalse()             -- startRun's onError undid the optimism
    end)
    M.echo = real
    if not ok then error(err, 0) end
  end)
end)

describe("mnem queue", function()
  it("groups pending requests by endpoint, most first", function()
    reset(true)
    M._queue = {
      { endpoint = "/ripple_level", payload = {} }, { endpoint = "/boss", payload = {} },
      { endpoint = "/ripple_level", payload = {} },
    }
    local order, counts = M.queueCounts()
    expect(order[1]).toBe("/ripple_level")
    expect(counts["/ripple_level"]).toBe(2)
    expect(counts["/boss"]).toBe(1)
  end)

  it("queueInfo reports a busy flag with no send behind it as stale", function()
    reset(true)
    M._queue = { { endpoint = "/death", payload = {} } }
    M._busy = true
    local qi = M.queueInfo()
    expect(qi.pending).toBe(1)
    expect(qi.head).toBe("/death")
    expect(qi.stale).toBeTrue()
    M._busy = false
  end)

  it("`mnem queue clear` drops everything and says how many", function()
    reset(true)
    M._queue = {
      { endpoint = "/death", payload = {} }, { endpoint = "/boss", payload = {} },
    }
    M._busy = true
    local real, said = M.echo, {}
    M.echo = function(m) said[#said + 1] = tostring(m) end
    local ok, err = pcall(M.command, "queue clear")
    M.echo = real
    if not ok then error(err, 0) end
    expect(#M._queue).toBe(0)
    expect(M._busy).toBeFalse()
    expect(table.concat(said, "\n")).toContain("Dropped <white>2")
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
    expect(sent[1].url).toContain("/run_pause")     -- ...and the server is TOLD (v4.7.298)
    completeHead({ ok = true })                     -- serial queue: let the pause finish
    M.onRunStart()                                  -- re-enter the same wade
    expect(sent[2].url).toContain("/run_exists")    -- resume, not /run_start
    for _, s in ipairs(sent) do
      if s.url:find("/run_start") then error("paused re-wade must not start a new run") end
    end
    expect(M.run.paused).toBeNil()                  -- flag consumed
  end)

  -- GATED ON _auto(), NOT _inRun() (deep review). `run.active` is our BELIEF about the server,
  -- and it is false in exactly the window that matters: after a reload mid-run, until the delayed
  -- /run_exists answers -- a request with no onError, so a slow tracker leaves it false
  -- indefinitely. The whisper trigger is exact and Mnemosyne-only, so if the game says we paused,
  -- the run exists and the server is the authority.
  it("posts /run_pause even when our own run.active belief is false", function()
    reset(false)                                     -- telemetry on, run.active false
    M.onRunPause()
    expect(M.run.paused).toBeTrue()
    expect(sent[1].url).toContain("/run_pause")
  end)

  it("does not post /run_pause with reporting switched off", function()
    reset(true)
    ataxia.settings.reporting.enabled = false
    M.onRunPause()
    expect(M.run.paused).toBeTrue()
    expect(#sent).toBe(0)
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

-- ─── Session stats (the `tarc` HUD) reset on a fresh run, not a resume ───────
--
-- User, from a live tarc screenshot: "Anytime our RUN STARTED this information should reset."
-- Placed beside the AUDIT baseline logic in M.onRunStart (v4.7.291) for the identical reason: a
-- pause (`WHISPER ... beseech that it grow still`) does not end the run server-side, so the next
-- wade re-enters the SAME run, and wiping kills/gold/DPS on a mere pause/resume would lose real
-- progress for nothing the user asked for.
describe("session stats reset on a fresh run, kept across a resume", function()
  local calls
  local realReset

  local function statsSetup()
    calls = {}
    realReset = resetBashingStats
    resetBashingStats = function(silent) calls[#calls + 1] = silent end
  end

  local function statsTeardown()
    resetBashingStats = realReset
  end

  it("resets on a genuinely fresh wade", function()
    reset(false)
    statsSetup()
    M.onRunStart()
    expect(#calls).toBe(1)
    expect(calls[1]).toBeTrue()       -- silent -- no "stats reset" spam on every dive
    statsTeardown()
  end)

  it("does NOT reset when resuming a paused run", function()
    reset(true)
    M.run.ripple = 3
    M.onRunPause()
    statsSetup()
    M.onRunStart()                    -- re-enter the same wade
    expect(#calls).toBe(0)
    statsTeardown()
  end)

  -- ABOVE the `_auto()` gate, like the audit baseline: session stats are a core basher feature
  -- and must reset on a fresh dive even for a user who has REST telemetry turned off entirely.
  it("still resets with telemetry OFF (the shipped default)", function()
    reset(false)
    ataxia.settings.reporting.enabled = false
    statsSetup()
    M.onRunStart()
    expect(#calls).toBe(1)
    statsTeardown()
    ataxia.settings.reporting.enabled = true
  end)

  it("resets again on the NEXT fresh run after a resume", function()
    reset(true)
    M.onRunPause()
    statsSetup()
    M.onRunStart()                    -- resume: no reset
    expect(#calls).toBe(0)
    M.onRunEnd()                      -- confirmed end
    M.onRunStart()                    -- a genuinely new dive
    expect(#calls).toBe(1)
    statsTeardown()
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

  -- RACE + CLASS (v4.7.220). Optional strings on BoonsOfferedRequest; they are what makes the
  -- offer data answerable at all -- "does Bard see Songstep more often" cannot be asked of a
  -- pile of undifferentiated offers.
  it("tags the post with the character's class and race", function()
    reset(true)
    gmcp = gmcp or {}; gmcp.Char = gmcp.Char or {}
    gmcp.Char.Status = { class = "Bard", race = "Xoran" }
    M.reportBoonsOffered({ { name = "Songstep" } })
    expect(sent[1].payload.class).toBe("Bard")
    expect(sent[1].payload.race).toBe("Xoran")
  end)

  -- "Earth Lord" and "Earth Lady" are one class wearing a gender suffix. Leaving them distinct
  -- would halve every per-class count in the queries this data exists to answer.
  it("normalises the Lord/Lady gender suffix off the class", function()
    reset(true)
    gmcp.Char.Status = { class = "earth Elemental Lord", race = "Human" }
    M.reportBoonsOffered({ { name = "Tantrum" } })
    expect(sent[1].payload.class).toBe("Earth Elemental")
    expect(sent[1].payload.race).toBe("Human")
  end)

  -- Omitted, never guessed: both fields are optional server-side, and a literal "unknown"
  -- would show up in the queries as its own cohort -- worse than a smaller honest sample.
  it("omits the fields entirely when GMCP has not reported them", function()
    reset(true)
    gmcp.Char.Status = { class = "", race = nil }
    M.reportBoonsOffered({ { name = "Iron Throat" } })
    expect(sent[1].payload.class).toBe(nil)
    expect(sent[1].payload.race).toBe(nil)
    expect(sent[1].payload.offered[1].name).toBe("Iron Throat") -- the post still goes
  end)

  it("survives GMCP not being populated at all", function()
    reset(true)
    local saved = gmcp.Char
    gmcp.Char = nil
    M.reportBoonsOffered({ { name = "Sharp Mind" } })
    expect(sent[1].url).toContain("/boons_offered")
    expect(sent[1].payload.class).toBe(nil)
    gmcp.Char = saved
  end)

  -- Every /boons_offered we have committed, IN ORDER, without double-counting: the serial
  -- queue posts the head immediately and leaves it in _queue until the server answers, so an
  -- in-flight request appears in BOTH sent and _queue[1].
  local function offeredNames()
    local out = {}
    for _, r in ipairs(sent) do
      if r.payload and r.payload.offered then out[#out + 1] = r.payload.offered[1].name end
    end
    for i, q in ipairs(M._queue) do
      if not (i == 1 and M._busy) and q.payload and q.payload.offered then
        out[#out + 1] = q.payload.offered[1].name
      end
    end
    return out
  end

  -- Fire ONLY the offer-wait timer. mock_mudlet.fire_timers() fires every pending timer in
  -- the process and then wipes the table, which would detonate captures armed by earlier
  -- tests in this file; matching on the delay keeps the blast radius to the thing under test.
  --
  -- SNAPSHOT THE MATCHING IDS BEFORE MUTATING (found live, 2026-09-02, the mock_mudlet.fire_timers
  -- fix applies here too): the offer-wait callback (`_flushPendingOffer`) arms its OWN follow-up
  -- timer -- the v4.7.295 catalogue trickle -- so deleting and calling inside one `pairs()` pass
  -- adds a key to the very table being walked. Undefined in Lua, and table-size-dependent: it did
  -- not fail every run, only once enough OTHER tests had left enough timers behind to push the
  -- hash part over a rehash boundary at exactly this call.
  local function fireOfferWait()
    local mock = require("mock_mudlet")
    local ids = {}
    for id, t in pairs(mock.active_timers) do
      if t.delay == M.OFFER_RIPPLE_WAIT and type(t.callback) == "function" then
        ids[#ids + 1] = id
      end
    end
    for _, id in ipairs(ids) do
      local t = mock.active_timers[id]
      mock.active_timers[id] = nil
      if t then t.callback() end
    end
  end

  -- -------------------------------------------------------------------------
  -- THE OFFER MUST CARRY THE RIGHT RIPPLE (v4.7.279)
  -- -------------------------------------------------------------------------
  --
  -- Reported by the tracker's author: "you're sending boons a ripple late so you're not
  -- sending the boons that are initially offered". BoonsOfferedRequest has no ripple field,
  -- so the server files an offer under whatever our last /ripple_level said -- and we only
  -- ever sent that on GO!, i.e. at the START of a wave. An offer posted at the boon screen
  -- therefore landed under the ripple we had just finished, and the FIRST offer of a run
  -- landed with no /ripple_level ever having been sent at all.
  it("does not post the offer until a ripple has been reported", function()
    reset(true)
    M._offerAfterRipple({ { name = "Songstep", description = "d" } })
    expect(#sent).toBe(0)                       -- nothing on the wire yet
    expect(M._pendingOffer ~= nil).toBeTrue()
  end)

  -- ORDER ON THE WIRE IS THE WHOLE POINT: /ripple_level has to be enqueued first, or the
  -- server files the offer against the previous ripple exactly as before.
  it("posts it behind /ripple_level once the ripple line arrives", function()
    reset(true)
    M._offerAfterRipple({ { name = "Songstep", description = "d" } })
    M.onRipple(4)
    local urls = {}
    for _, r in ipairs(sent) do urls[#urls + 1] = r.url end
    -- the queue is serial, so only the head is on the wire; the rest are queued in order
    local order = {}
    for _, r in ipairs(sent) do order[#order + 1] = r.url end
    for _, q in ipairs(M._queue) do order[#order + 1] = q.endpoint end
    local iRipple, iOffer
    for i, u in ipairs(order) do
      if u:find("/ripple_level", 1, true) and not iRipple then iRipple = i end
      if u:find("/boons_offered", 1, true) and not iOffer then iOffer = i end
    end
    expect(iRipple ~= nil).toBeTrue()
    expect(iOffer ~= nil).toBeTrue()
    expect(iRipple < iOffer).toBeTrue()
  end)

  -- BOUNDED, BECAUSE DEFERRING THIS IS WHAT BROKE IT BEFORE. v4.7.91 removed a deferral that
  -- could stall and silently drop the whole report; this one must post regardless.
  it("posts anyway if the ripple line never comes", function()
    reset(true)
    M._offerAfterRipple({ { name = "Songstep", description = "d" } })
    expect(#sent).toBe(0)
    fireOfferWait()                          -- the wait elapses, no wade status reply
    expect(sent[1].url).toContain("/boons_offered")
    expect(sent[1].payload.offered[1].name).toBe("Songstep")
  end)

  it("posts exactly once when both the ripple and the timeout land", function()
    reset(true)
    M._offerAfterRipple({ { name = "Songstep", description = "d" } })
    M.onRipple(4)
    fireOfferWait()
    expect(#offeredNames()).toBe(1)
  end)

  -- REGRESSION (found live, 2026-09-02): `_flushPendingOffer` arms its own follow-up timer (the
  -- v4.7.295 catalogue trickle) FROM INSIDE the offer-wait timer's own callback. Firing a timer
  -- that arms another timer is an ordinary, common pattern in this codebase -- but both
  -- `mock_mudlet.fire_timers()` and this file's own `fireOfferWait()` used to walk
  -- `mock.active_timers` with a bare `pairs()` loop, so the new timer being added mutated the
  -- very table the loop was iterating: `invalid key to 'next'`. It did not fail every run --
  -- Lua's hash part only breaks like this near a rehash boundary, so it was a table-SIZE-
  -- dependent flake that surfaced only when enough OTHER tests happened to have left enough
  -- timers lying around. Pinned directly here so the "arm one timer from another's callback"
  -- shape can never silently regress in the harness again.
  it("does not corrupt timer iteration when the flush arms its own follow-up timer", function()
    reset(true)
    M.history = M.history or {}
    M.history.boonLibrary = M.history.boonLibrary or {}
    M._offerAfterRipple({ { name = "Songstep", description = "d" } })
    local ok = pcall(fireOfferWait)
    expect(ok).toBeTrue()
    expect(#offeredNames()).toBe(1)
  end)

  -- A second offer screen must not be posted with the first screen's list, and the first
  -- screen's timer must not fire against it.
  --
  -- CHANGED IN v4.7.298 (deep review): the first screen is now FLUSHED rather than discarded.
  -- Discarding was right when a second screen close behind the first meant a duplicate capture;
  -- the reroll feature makes two distinct, meaningful screens a normal event, and dropping the
  -- earlier one loses exactly what was rerolled away. The original intent -- no cross-
  -- contamination between the two lists -- is what this now asserts.
  it("a new offer screen flushes the pending one instead of discarding it", function()
    reset(true)
    M._offerAfterRipple({ { name = "First", description = "d" } })
    M._offerAfterRipple({ { name = "Second", description = "d" } })
    fireOfferWait()
    local names = offeredNames()
    expect(#names).toBe(2)
    expect(names[1]).toBe("First")    -- posted with ITS OWN list...
    expect(names[2]).toBe("Second")   -- ...and the second with its own
  end)

  -- The one case where losing it beats sending it: the offer belongs to a run that is over.
  it("a run boundary drops the pending offer rather than filing it under the next run", function()
    reset(true)
    M._offerAfterRipple({ { name = "First", description = "d" } })
    M._resetRun()
    expect(M._pendingOffer).toBeNil()
    M._offerAfterRipple({ { name = "Second", description = "d" } })
    fireOfferWait()
    local names = offeredNames()
    expect(#names).toBe(1)
    expect(names[1]).toBe("Second")
  end)

  -- BREAK-BACK GAP, CLOSED. The tests above call M._offerAfterRipple directly, so reverting
  -- onBoonsOffered to post immediately -- the exact bug being fixed -- passed all of them.
  -- Same shape as the guard-inside-a-trigger trap (v4.7.260): a seam the suite never crosses
  -- is a seam the suite cannot defend. This drives the REAL offer screen through the real
  -- capture, by feeding lines to the temp trigger the mock records.
  it("the offer SCREEN itself defers -- nothing posts until the ripple", function()
    reset(true)
    local mock = require("mock_mudlet")
    M._capturing = false
    M.onBoonsOffered()

    -- Feed the block exactly as the game prints it: header already matched by the trigger,
    -- then a divider, the offers, and the BOON CLAIM footer that closes the capture.
    local feed = {
      "----------------------------------------",
      "Songstep:      Your dances are free.",
      "Iron Throat:   Gain 25% resistance to asphyxiation damage.",
      "Type BOON CLAIM <name> to choose.",
    }
    for _, ln in ipairs(feed) do
      line = ln
      for _, t in pairs(mock.active_triggers) do
        if t.regex and t.pattern == "^.*$" and type(t.callback) == "function" then t.callback() end
      end
    end

    -- The capture is done and the boons are parsed...
    expect(M.run.lastOffered[1]).toBe("Songstep")
    -- ...but NOTHING is on the wire yet, because the ripple is not current.
    expect(#offeredNames()).toBe(0)

    -- The ripple arrives and it goes out behind /ripple_level.
    M.onRipple(3)
    local names = offeredNames()
    expect(#names).toBe(1)
    expect(names[1]).toBe("Songstep")
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

-- AFFLICTION IMMUNITY FROM BOONS (v4.7.224). User: "We select boons that make us immune to an
-- affliction and I would love for it to echo on the boon option screen to be able to state we
-- have the immunity to this boon's downside." Sure-Footed's real text, from the offer screen:
-- "You are immune to the dizziness affliction."
describe("boon-granted affliction immunity", function()
  local echoes
  local function capture(fn)
    echoes = {}
    local real = M.echo
    M.echo = function(msg) echoes[#echoes + 1] = tostring(msg) end
    local ok, err = pcall(fn)
    M.echo = real
    if not ok then error(err) end
  end
  local function saw(frag)
    for _, e in ipairs(echoes) do if e:find(frag, 1, true) then return true end end
    return false
  end
  local function claims(...)
    M.history = M.history or {}
    M.history.run = 7
    M.history.claims = { ... }
  end

  it("reads the immunity out of a boon description", function()
    expect(M._immunityFrom("You are immune to the dizziness affliction.")).toBe("dizziness")
    expect(M._immunityFrom("Restore your resources instead.")).toBe(nil)
    expect(M._immunityFrom(nil)).toBe(nil)
  end)

  -- A lazy `(.-)` between two anchors will happily swallow a clause. Bound it, or a sentence
  -- that merely contains both words invents an affliction nobody has ever had.
  it("refuses a runaway match rather than inventing an affliction", function()
    expect(M._immunityFrom("immune to the sort of thing that causes affliction")).toBe(nil)
  end)

  -- ONE BOON, SEVERAL IMMUNITIES (v4.7.236). Live miss, user-supplied:
  --   Outlaw:        "You are immune to the justice and guilt afflictions."
  --   Corrupted Mind: "Your psychic resistance is increased by 66% but you suffer permanent guilt."
  -- The single-capture version grabbed "justice and guilt" and its own runaway-guard threw it
  -- away for containing a space, so Outlaw registered NOTHING and Corrupted Mind was never
  -- flagged as free.
  it("reads BOTH afflictions out of a multi-grant", function()
    local list = M._immunitiesFrom("You are immune to the justice and guilt afflictions.")
    expect(#list).toBe(2)
    expect(list[1]).toBe("justice")
    expect(list[2]).toBe("guilt")
  end)

  it("still reads a single grant, and still refuses runaway text", function()
    local one = M._immunitiesFrom("You are immune to the dizziness affliction.")
    expect(#one).toBe(1)
    expect(one[1]).toBe("dizziness")
    -- The guard survives -- it just runs per PART now, so a genuine clause is still rejected.
    expect(#M._immunitiesFrom("immune to the sort of thing that causes affliction")).toBe(0)
    expect(#M._immunitiesFrom("Restore your resources instead.")).toBe(0)
  end)

  it("registers every affliction from a multi-grant as held", function()
    claims({ run = 7, name = "Outlaw",
             description = "You are immune to the justice and guilt afflictions." })
    local imm = M.runImmunities()
    expect(imm.justice).toBe("Outlaw")
    expect(imm.guilt).toBe("Outlaw")
  end)

  -- The whole point of the report: Outlaw makes Corrupted Mind free.
  it("flags Corrupted Mind as free once Outlaw is held", function()
    claims({ run = 7, name = "Outlaw",
             description = "You are immune to the justice and guilt afflictions." })
    capture(function()
      M._echoImmunities({
        { name = "Corrupted Mind",
          description = "Your psychic resistance is increased by 66% but you suffer permanent guilt." },
      })
    end)
    expect(saw("IMMUNE")).toBeTrue()
    expect(saw("Corrupted Mind")).toBeTrue()
    expect(saw("Outlaw")).toBeTrue()
    expect(saw("Free for us")).toBeTrue()
  end)

  -- ...and without it, the cost is still named. "guilt" and "justice" were held out of the
  -- cost list as ordinary English; the cost-clause restriction already does that job.
  it("names guilt and nausea as costs when we do NOT hold the immunity", function()
    claims({ run = 7, name = "Beeline", description = "You may now utilise prism tattoos." })
    capture(function()
      M._echoImmunities({
        { name = "Corrupted Mind",
          description = "Your psychic resistance is increased by 66% but you suffer permanent guilt." },
        { name = "Corrupted Blood",
          description = "Your poison resistance is increased by 66% but you suffer permanent nausea." },
      })
    end)
    expect(saw("Corrupted Mind")).toBeTrue()
    expect(saw("guilt")).toBeTrue()
    expect(saw("Corrupted Blood")).toBeTrue()
    expect(saw("nausea")).toBeTrue()
    expect(saw("not immune")).toBeTrue()
  end)

  -- COSTS CAN NAME SEVERAL TOO (v4.7.237) -- the mirror of the multi-grant fix, found the
  -- same way, on a live offer screen:
  --   "Corrupted Cold: Your cold resistance is increased by 66%, but you suffer permanent
  --    dehydration and tenderskin."
  -- Returning only the first is worse than saying nothing: a boon whose price is two
  -- afflictions reads as though it costs one.
  local COLD = "Your cold resistance is increased by 66%, but you suffer permanent dehydration and tenderskin."

  it("reads BOTH costs out of one clause", function()
    local costs = M._boonDrawbacks(COLD)
    expect(#costs).toBe(2)
    local set = {}
    for _, c in ipairs(costs) do set[c] = true end
    expect(set.dehydration).toBeTrue()
    expect(set.tenderskin).toBeTrue()
  end)

  it("names both when we block neither", function()
    claims({ run = 7, name = "Beeline", description = "You may now utilise prism tattoos." })
    capture(function()
      M._echoImmunities({ { name = "Corrupted Cold", description = COLD } })
    end)
    expect(saw("Corrupted Cold")).toBeTrue()
    expect(saw("dehydration")).toBeTrue()
    expect(saw("tenderskin")).toBeTrue()
    expect(saw("not immune")).toBeTrue()
  end)

  -- PARTLY free is not free. Blocking one of two costs and calling the boon "free for us" is
  -- the kind of confident wrong answer that gets someone killed on a boon screen.
  it("says PARTLY IMMUNE when it blocks only one of two costs", function()
    claims({ run = 7, name = "Camelskin",
             description = "You are immune to the dehydration affliction." })
    capture(function()
      M._echoImmunities({ { name = "Corrupted Cold", description = COLD } })
    end)
    expect(saw("PARTLY IMMUNE")).toBeTrue()
    expect(saw("Camelskin")).toBeTrue()
    expect(saw("tenderskin")).toBeTrue()   -- the one still owed
    expect(saw("Free for us")).toBeFalse()
  end)

  it("says fully IMMUNE only when every cost is blocked", function()
    claims({ run = 7, name = "Thickhide",
             description = "You are immune to the dehydration and tenderskin afflictions." })
    capture(function()
      M._echoImmunities({ { name = "Corrupted Cold", description = COLD } })
    end)
    expect(saw("Free for us")).toBeTrue()
    expect(saw("PARTLY")).toBeFalse()
  end)

  -- The rest of that live screen, which must stay quiet or be reported as a grant.
  it("handles the rest of the screen correctly", function()
    claims({ run = 7, name = "Beeline", description = "You may now utilise prism tattoos." })
    capture(function()
      M._echoImmunities({
        { name = "Hyperfixate", description = "You are immune to the confusion affliction." },
        { name = "Iron Throat", description = "Gain 25% resistance to asphyxiation damage." },
        { name = "Restoration", description = "Restore your resources instead." },
      })
    end)
    expect(saw("GRANTS IMMUNITY")).toBeTrue()
    expect(saw("Hyperfixate")).toBeTrue()
    expect(saw("confusion")).toBeTrue()
    -- A pure resistance boon has no affliction cost and must not be dressed up as having one.
    expect(saw("Iron Throat")).toBeFalse()
    expect(saw("Restoration")).toBeFalse()
  end)

  -- A BOON CAN BE BOTH A GRANT AND A COST (v4.7.238). Live:
  --   "Inflammable: You are immune to burning, but suffer permanent shivering."
  -- Two assumptions broke at once: the grant pattern required "the <x> affliction" (this says
  -- neither), and _boonDrawbacks bailed out entirely on any line containing a grant.
  local INFLAM = "You are immune to burning, but suffer permanent shivering."

  it("reads a grant phrased without 'the' or 'affliction'", function()
    local list = M._immunitiesFrom(INFLAM)
    expect(#list).toBe(1)
    expect(list[1]).toBe("burning")
  end)

  it("still finds the cost on a boon that is ALSO a grant", function()
    local costs = M._boonDrawbacks(INFLAM)
    expect(#costs).toBe(1)
    expect(costs[1]).toBe("shivering")
  end)

  -- The protection that check was there for has to survive: a grant sitting INSIDE the cost
  -- clause is still a grant, and must not be reported as a price.
  it("still refuses a grant that lives in the cost clause", function()
    expect(#M._boonDrawbacks("Your damage is halved, but you are immune to the nausea affliction."))
      .toBe(0)
  end)

  -- Reporting ONLY the grant sells the boon as pure upside -- the same confident-wrong-answer
  -- failure as calling a partly-blocked boon "free". A first version of this test asserted
  -- only that the grant was named, and passed while the price was silently dropped.
  it("reports Inflammable as a grant AND names its price", function()
    claims({ run = 7, name = "Beeline", description = "You may now utilise prism tattoos." })
    capture(function()
      M._echoImmunities({ { name = "Inflammable", description = INFLAM } })
    end)
    expect(saw("GRANTS IMMUNITY")).toBeTrue()
    expect(saw("burning")).toBeTrue()
    expect(saw("but costs")).toBeTrue()
    expect(saw("shivering")).toBeTrue()
  end)

  it("a grant with no price says nothing about costs", function()
    claims({ run = 7, name = "Beeline", description = "You may now utilise prism tattoos." })
    capture(function()
      M._echoImmunities({
        { name = "Hyperfixate", description = "You are immune to the confusion affliction." } })
    end)
    expect(saw("GRANTS IMMUNITY")).toBeTrue()
    expect(saw("but costs")).toBeFalse()
  end)

  -- `burning` is deliberately NOT in the cost list: it is also a damage type ("deals burning
  -- damage"), which a cost clause cannot disambiguate. It works as a GRANT because that path
  -- reads the affliction out of the sentence rather than scanning for known names.
  it("does not treat burning as a cost, since it is also a damage type", function()
    expect(#M._boonDrawbacks("Your attacks are stronger, but you deal burning damage instead."))
      .toBe(0)
  end)

  -- The rest of that screen. Font of Life mentions "afflictions" and must NOT be mistaken for
  -- an immunity grant.
  it("does not read 'cure two afflictions' as an immunity", function()
    expect(#M._immunitiesFrom(
      "The Earthmother empowers your tree tattoo to now cure two afflictions.")).toBe(0)
    claims({ run = 7, name = "Beeline", description = "You may now utilise prism tattoos." })
    capture(function()
      M._echoImmunities({
        { name = "Font of Life",
          description = "The Earthmother empowers your tree tattoo to now cure two afflictions." },
        { name = "Razor Leaf",
          description = "When touching your tree tattoo, razor-sharp leaves will descend upon the locale, dealing damage to all denizens present." },
      })
    end)
    expect(saw("Font of Life")).toBeFalse()
    expect(saw("Razor Leaf")).toBeFalse()
  end)

  -- REAL BOONS FROM THE COMMUNITY CATALOGUE (v4.7.240). Found by running this parser over all
  -- 294 boons at mediaresachaea.github.io/mnemosyne-boons rather than waiting for each shape
  -- to turn up on an offer screen -- which is how the previous five gaps were found, one
  -- release at a time. Exactly one grant was under-read, and three affliction names were
  -- missing from the cost list.
  it("reads a comma list that runs on into more prose", function()
    -- Careless Whisperer. Stopping at the first comma read ONE of three; the per-part guard
    -- is what drops the trailing clause, so the capture can afford to be generous.
    local g = M._immunitiesFrom(
      "You are immune to masochism, hallucinations, and paranoia, and you always walk with a zealous warding against the Outer Cold.")
    expect(#g).toBe(3)
    local set = {}
    for _, x in ipairs(g) do set[x] = true end
    expect(set.masochism).toBeTrue()
    expect(set.hallucinations).toBeTrue()
    expect(set.paranoia).toBeTrue()
  end)

  it("reads a bare two-item 'and' list", function()
    local g = M._immunitiesFrom("You are immune to lethargy and weariness.")
    expect(#g).toBe(2)
  end)

  -- Candour: the grant clause is followed by more sentence. The lazy match must stop at
  -- "affliction" rather than swallowing "by the clarity of the Lightbringer".
  it("stops at 'affliction' when the sentence continues", function()
    local g = M._immunitiesFrom(
      "You are immune to the blackout affliction by the clarity of the Lightbringer.")
    expect(#g).toBe(1)
    expect(g[1]).toBe("blackout")
  end)

  it("names the three afflictions that were missing from the cost list", function()
    expect(M._boonDrawbacks("You are immune to slickness, but suffer permanent timeflux.")[1])
      .toBe("timeflux")
    expect(M._boonDrawbacks(
      "Your electric resistance is increased by 66% but you suffer permanent fulmination.")[1])
      .toBe("fulmination")
    expect(M._boonDrawbacks("Your movement is faster but you suffer permanent hamstrung.")[1])
      .toBe("hamstrung")
  end)

  -- Coarse Flesh is the grant-AND-cost shape again, from real data this time.
  it("reads Coarse Flesh as both a grant and a cost", function()
    local d = "You are immune to slickness, but suffer permanent timeflux."
    expect(M._immunitiesFrom(d)[1]).toBe("slickness")
    expect(M._boonDrawbacks(d)[1]).toBe("timeflux")
  end)

  -- Non-affliction costs must stay silent rather than being forced into an affliction name.
  it("stays silent on costs that are not afflictions", function()
    expect(#M._boonDrawbacks("Tumbling completes instantly but incurs a 50% increased balance cost.")).toBe(0)
    expect(#M._boonDrawbacks("Gain 15% physical resistance, but lose 10% magical resistance.")).toBe(0)
    expect(#M._boonDrawbacks(
      "Your balance recovers 30% faster, but you can no longer be healed above 30% health.")).toBe(0)
  end)

  -- The cost-clause restriction, tested directly. Break it and an affliction named ANYWHERE --
  -- including in a boon that CURES it -- gets reported as a cost. Neither of the two
  -- screen-level tests catches that on its own, which is why this is here.
  it("only reads an affliction as a cost when a cost clause introduces it", function()
    expect(M._boonDrawback("Your poison resistance is increased by 66% but you suffer permanent nausea."))
      .toBe("nausea")
    -- Same affliction, no cost clause: this boon is doing us a favour.
    expect(M._boonDrawback("Cures your nausea instantly.")).toBe(nil)
    expect(M._boonDrawback("Your nausea recovery is twice as fast.")).toBe(nil)
  end)

  -- An immunity GRANT names an affliction and would otherwise read as a cost -- reporting a
  -- boon's benefit as its drawback is the precise opposite of the truth.
  it("never reads an immunity grant as a cost", function()
    expect(M._boonDrawback("You are immune to the haemophilia affliction.")).toBe(nil)
    -- The case that actually exercises the guard: a cost clause PRECEDING the grant, so the
    -- affliction sits inside the scanned tail. Without it, the boon's benefit is reported as
    -- its drawback -- the precise opposite of the truth. (A first pass at this test used the
    -- bare grant above, which has no cost marker at all and so could never fail.)
    expect(M._boonDrawback("Your damage is halved, but you are immune to the nausea affliction."))
      .toBe(nil)
  end)

  -- A real cost that is not an affliction must not be dressed up as one.
  it("does not invent an affliction for a non-affliction cost", function()
    expect(M._boonDrawback("Potash is 200% stronger, but you can no longer drink health or mana."))
      .toBe(nil)
  end)

  it("collects immunities from THIS run's claims only", function()
    claims(
      { run = 7, name = "Sure-Footed", description = "You are immune to the dizziness affliction." },
      { run = 6, name = "Iron Throat",  description = "You are immune to the asthma affliction." },
      { run = 7, name = "Beeline",      description = "You may now utilise prism tattoos." }
    )
    local imm = M.runImmunities()
    expect(imm.dizziness).toBe("Sure-Footed")
    expect(imm.asthma).toBe(nil) -- last run's boon is not ours any more
  end)

  it("calls out an offered boon whose drawback we already block", function()
    claims({ run = 7, name = "Sure-Footed", description = "You are immune to the dizziness affliction." })
    capture(function()
      M._echoImmunities({
        { name = "Vertigo Step", description = "Move faster, but you suffer dizziness." },
        { name = "Restoration",  description = "Restore your resources instead." },
      })
    end)
    expect(saw("IMMUNE")).toBeTrue()
    expect(saw("Vertigo Step")).toBeTrue()
    expect(saw("Sure-Footed")).toBeTrue()
    expect(saw("Restoration")).toBeFalse() -- no drawback we block: stays quiet
  end)

  -- The grant says "dizziness"; a drawback may say "dizzy", and no stemming turns one into the
  -- other safely. The alias table is data for exactly this, extended as real lines are seen.
  it("matches a known alternate word form", function()
    claims({ run = 7, name = "Sure-Footed", description = "You are immune to the dizziness affliction." })
    capture(function()
      M._echoImmunities({ { name = "Whirl", description = "Spin fast enough to become dizzy." } })
    end)
    expect(saw("IMMUNE")).toBeTrue()
    expect(saw("Whirl")).toBeTrue()
  end)

  -- The per-boon match can only catch wording we have seen, so the standing list is shown when
  -- nothing matched. Without it a missed drawback reads as "no drawback", which is worse than
  -- saying nothing at all.
  it("still states what we are immune to when no offered boon names one", function()
    claims({ run = 7, name = "Sure-Footed", description = "You are immune to the dizziness affliction." })
    capture(function()
      M._echoImmunities({ { name = "Restoration", description = "Restore your resources instead." } })
    end)
    expect(saw("Immune this run")).toBeTrue()
    expect(saw("dizziness")).toBeTrue()
  end)

  -- REQUIREMENT EXTENDED, v4.7.225 (user: "would be excellent to see if we are immune or
  -- not"). This used to assert silence when we hold nothing. Saying nothing answers only half
  -- the question -- a boon with a cost we do NOT block is exactly as worth knowing at the
  -- moment of choosing, so it is now called out as such.
  it("calls out a cost we do NOT block, rather than staying silent", function()
    claims({ run = 7, name = "Beeline", description = "You may now utilise prism tattoos." })
    capture(function()
      M._echoImmunities({
        { name = "Corrupted Blood",
          description = "Your poison resistance is increased by 66% but you suffer permanent nausea." },
      })
    end)
    expect(saw("not immune")).toBeTrue()
    expect(saw("nausea")).toBeTrue()
  end)

  -- ...but a boon with no cost at all must stay quiet. Annotating everything is noise, and
  -- noise on the offer screen is what makes the useful lines get skipped.
  -- THE REAL OFFER SCREEN, verbatim (user screenshot, 2026-08-06). Six boons, and every branch
  -- of the annotation appears in it exactly once -- which is why it is worth keeping as a
  -- fixture rather than six synthetic ones.
  local SCREEN = {
    { name = "Corrupted Blood",
      description = "Your poison resistance is increased by 66% but you suffer permanent nausea." },
    { name = "Crystal Blue Protection",
      description = "Upon killing a denizen, you have a 10% chance of gaining the prismatic defence for 5 seconds." },
    { name = "Rage-Fuelled",
      description = "When slaying a denizen, your next battlerage attack will cost no resource." },
    { name = "Plasmatic", description = "You are immune to the haemophilia affliction." },
    { name = "Stone Stomach",
      description = "Your tash'la heritage increases the effects of potash (not moss) by 200% and potash has a 50% reduced cooldown, but you can no longer drink health or mana." },
    { name = "Restoration", description = "Restore your resources instead." },
  }

  it("annotates the live offer screen correctly, holding nothing", function()
    claims({ run = 7, name = "Beeline", description = "You may now utilise prism tattoos." })
    capture(function() M._echoImmunities(SCREEN) end)
    -- Plasmatic is the immunity on the table: say what taking it buys.
    expect(saw("GRANTS IMMUNITY")).toBeTrue()
    expect(saw("Plasmatic")).toBeTrue()
    expect(saw("haemophilia")).toBeTrue()
    -- Corrupted Blood's cost is a real affliction we do not block.
    expect(saw("Corrupted Blood")).toBeTrue()
    expect(saw("nausea")).toBeTrue()
    expect(saw("not immune")).toBeTrue()
    -- Stone Stomach's "but you can no longer drink health or mana" is a real cost, but NOT an
    -- affliction -- so it must not be dressed up as one. The clause marker is present; the
    -- affliction is not, and that distinction is the whole point of matching names.
    expect(saw("Stone Stomach")).toBeFalse()
    -- Pure-benefit boons stay quiet.
    expect(saw("Restoration")).toBeFalse()
    expect(saw("Rage-Fuelled")).toBeFalse()
    expect(saw("Crystal Blue")).toBeFalse()
  end)

  it("flips Corrupted Blood to FREE once we hold the matching immunity", function()
    claims(
      { run = 7, name = "Iron Gut", description = "You are immune to the nausea affliction." }
    )
    capture(function() M._echoImmunities(SCREEN) end)
    expect(saw("IMMUNE")).toBeTrue()
    expect(saw("Corrupted Blood")).toBeTrue()
    expect(saw("Iron Gut")).toBeTrue()
    expect(saw("Free for us")).toBeTrue()
    expect(saw("not immune")).toBeFalse()
    -- ...and the standing list still names it, so a cost the matcher missed is still visible.
    expect(saw("Immune this run")).toBeTrue()
  end)

  it("stays quiet for a boon with no cost and no immunity", function()
    claims({ run = 7, name = "Beeline", description = "You may now utilise prism tattoos." })
    capture(function()
      M._echoImmunities({ { name = "Restoration", description = "Restore your resources instead." } })
    end)
    expect(#echoes).toBe(0)
  end)
end)

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

  -- The confirmed wade-end is the NORMAL way out of the tower (the SURVEY paths are the
  -- "walked out / stale flag" ones), and it is what releases every tower-only mode: no-flee,
  -- and the PvE curing profile that is deliberately held across a mid-wade basher stop.
  it("clears inMnemosyne and raises 'mnemosyne left' through the shared hook", function()
    reset(true)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    local raised = {}
    local realRaise = raiseEvent
    raiseEvent = function(e, ...) raised[#raised + 1] = e; return realRaise(e, ...) end
    local ok, err = pcall(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua")
      M.onRunEnd()
    end)
    raiseEvent = realRaise
    if not ok then error(err) end
    expect(ataxiaBasher.inMnemosyne).toBeFalse()
    expect(raised).toContain("mnemosyne left")
  end)

  -- basher/001 is a separate file, so this is a cross-file global call -- the crash class in
  -- bug-patterns.md. It must degrade to clearing the flag rather than stranding no-flee ON.
  it("still clears inMnemosyne if the shared hook is unavailable", function()
    reset(true)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    local realHook = ataxiaBasher_mnemLeft
    ataxiaBasher_mnemLeft = nil
    local ok, err = pcall(M.onRunEnd)
    ataxiaBasher_mnemLeft = realHook
    if not ok then error(err) end
    expect(ataxiaBasher.inMnemosyne).toBeFalse()
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

describe("bosses named this run are remembered for the corpse-eat skip list (v4.7.305)", function()
  it("onObjective records every boss and _resetRun clears them", function()
    reset(true)
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemBossNames = nil
    M.onObjective("defeat Giacinto, the Golden")
    M.onObjective("defeat 3 waves of enemies") -- not a boss
    M.onObjective("defeat Seasone the Industrious")
    expect(ataxiaTemp.mnemBossNames["Giacinto, the Golden"]).toBeTrue()
    expect(ataxiaTemp.mnemBossNames["Seasone the Industrious"]).toBeTrue()
    local n = 0
    for _ in pairs(ataxiaTemp.mnemBossNames) do n = n + 1 end
    expect(n).toBe(2)
    M._resetRun()
    expect(ataxiaTemp.mnemBossNames).toBeNil()
  end)
end)

-- "You consider for a time, but no information comes to you on such a boon." (v4.7.308)
describe("a boon name the game refuses is remembered, skipped, and retryable", function()
  it("marks the name in flight unknown and drops it from the gaps", function()
    reset(true)
    M.history.boonUnknown = nil
    M.BOON_SEED = M.BOON_SEED or {}
    M.BOON_SEED["Antimagic Shell"] = {}         -- a name-only hole, as the announcement left it
    local before = M.boonGaps()
    local present = false
    for _, n in ipairs(before) do if n == "Antimagic Shell" then present = true end end
    expect(present).toBeTrue()
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.contemplating = "Antimagic Shell"
    expect(M.onContemplateUnknown()).toBeTrue()
    expect(M.boonUnknown("Antimagic Shell")).toBeTrue()
    expect(ataxiaTemp.contemplating).toBeNil()
    local after = M.boonGaps()
    for _, n in ipairs(after) do expect(n ~= "Antimagic Shell").toBeTrue() end
    M.BOON_SEED["Antimagic Shell"] = nil
  end)

  it("does nothing when no contemplate is in flight (someone typed it by hand)", function()
    reset(true)
    M.history.boonUnknown = nil
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.contemplating = nil
    expect(M.onContemplateUnknown()).toBeFalse()
    expect(next(M.history.boonUnknown or {})).toBeNil()
  end)

  -- v4.7.328, user: "When I pick a boon before it gets contemplated, this pops up. It is wrong.
  -- It just means I picked it before the skill had time to look and the option isnt there
  -- anymore." The name was on the OFFER SCREEN, so the game printed it: the spelling is right and
  -- the refusal means the screen closed. Blacklisting it cost a real boon out of the catalogue.
  it("a refused name the game itself just offered is NOT blacklisted", function()
    reset(true)
    M.history.boonUnknown = nil
    M.run = M.run or {}
    M.run.lastOffered = { "Hawk Eyes", "Fae-Lapse", "(ECHO) Restoration" }
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.contemplating = "Hawk Eyes"
    local said, realEcho = {}, M.echo
    M.echo = function(m) said[#said + 1] = tostring(m) end
    local ok, err = pcall(function()
      expect(M.onContemplateUnknown()).toBeTrue()
      expect(M.boonUnknown("Hawk Eyes")).toBeFalse()
      expect(next(M.history.boonUnknown or {})).toBeNil()
      expect(M._offerGone()).toBeTrue()
      -- an echo offer of an offered boon counts as offered too
      ataxiaTemp.contemplating = "Restoration"
      expect(M.onContemplateUnknown()).toBeTrue()
      expect(M.boonUnknown("Restoration")).toBeFalse()
    end)
    M.echo = realEcho
    M.run.lastOffered, M._offerGoneAt = {}, nil
    if not ok then error(err, 0) end
    expect(table.concat(said, " "):find("no longer on the screen", 1, true) ~= nil).toBeTrue()
    expect(table.concat(said, " "):find("does not recognise", 1, true)).toBeNil()
  end)

  it("a name we never saw offered is still blacklisted -- that one IS our spelling", function()
    reset(true)
    M.history.boonUnknown = nil
    M.run = M.run or {}
    M.run.lastOffered = { "Fae-Lapse" }
    M._offerGoneAt = nil
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.contemplating = "Antimagic Shell"
    local realEcho = M.echo
    M.echo = function() end
    local ok, err = pcall(function()
      expect(M.onContemplateUnknown()).toBeTrue()
      expect(M.boonUnknown("Antimagic Shell")).toBeTrue()
    end)
    M.echo = realEcho
    M.run.lastOffered = {}
    if not ok then error(err, 0) end
  end)

  it("a claim closes the screen, so the chain stops asking for that screen's boons", function()
    reset(true)
    M.run = M.run or {}
    M.run.lastOffered = { "Hawk Eyes", "Fae-Lapse" }
    M.offerScreenGone("claim")
    local asked, realSend, realCapture = {}, send, M._captureContemplate
    send = function(c) local n = c:match("^boon contemplate (.+)$"); if n then asked[#asked + 1] = n end end
    M._captureContemplate = function(cb) cb({ rarity = "common", description = "d" }) end
    local realTimer = tempTimer
    tempTimer = function(_, f) f(); return 1 end
    local realSave, realEcho = M._historySave, M.echo
    M._historySave, M.echo = function() end, function() end
    local ok, err = pcall(function()
      local ctx = M._fillCtx({}, true)
      ctx.offered = { { name = "Hawk Eyes" }, { name = "Fae-Lapse" } }
      M._boonFillNext({ "Hawk Eyes", "Fae-Lapse", "Some Gap" }, 1, 0, ctx)
    end)
    send, M._captureContemplate, tempTimer = realSend, realCapture, realTimer
    M._historySave, M.echo = realSave, realEcho
    M.run.lastOffered, M._offerGoneAt = {}, nil
    if not ok then error(err, 0) end
    expect(#asked).toBe(1)          -- only the unrelated gap
    expect(asked[1]).toBe("Some Gap")
  end)

  it("a new offer screen re-opens the window, and clears an old wrong blacklist", function()
    reset(true)
    M.history.boonUnknown = { ["Hawk Eyes"] = 1 }
    M.offerScreenGone("claim")
    expect(M._offerGone()).toBeTrue()
    local mock = require("mock_mudlet")
    local realAuto = M._auto
    M._auto = function() return true end
    M.run = M.run or {}
    M.run.active, M.history.run = true, M.history.run or 1
    local goneAfter
    local ok, err = pcall(function()
      M._capturing = false
      M.onBoonsOffered()
      goneAfter = M._offerGone() -- read BEFORE the cleanup below, or it proves nothing
      for _, ln in ipairs({ "----------------------------------------",
                            "Hawk Eyes:   You see further.",
                            "Type BOON CLAIM <name> to choose." }) do
        line = ln
        for _, tr in pairs(mock.active_triggers) do
          if tr.regex and tr.pattern == "^.*$" and type(tr.callback) == "function" then tr.callback() end
        end
      end
    end)
    M._auto = realAuto
    M._pendingOffer, M._offerGoneAt = nil, nil
    if not ok then error(err, 0) end
    expect(M.boonUnknown("Hawk Eyes")).toBeFalse() -- the game printed it: it exists
    expect(goneAfter).toBeFalse()                  -- a fresh screen: its boons are askable again
  end)

  it("BOON CLAIM itself closes the screen -- before any refusal can happen", function()
    reset(true)
    M.run = M.run or {}
    M.run.active, M.run.lastOffered = true, { "Hawk Eyes", "Fae-Lapse" }
    M._offerGoneAt = nil
    local realAuto, realReport, realRecord, realArm, realFlag, realEcho =
      M._auto, M.reportBoonsSelected, M._recordClaim, M._armClaimVerify, M.latchBoonFlag, M.echo
    M._auto = function() return true end
    M.reportBoonsSelected, M._recordClaim, M._armClaimVerify = function() end, function() end, function() end
    M.latchBoonFlag, M.echo = function() end, function() end
    local gone
    local ok, err = pcall(function()
      M.onBoonClaim("Hawk Eyes")
      gone = M._offerGone()
    end)
    M._auto, M.reportBoonsSelected, M._recordClaim = realAuto, realReport, realRecord
    M._armClaimVerify, M.latchBoonFlag, M.echo = realArm, realFlag, realEcho
    M.run.lastOffered, M._offerGoneAt = {}, nil
    if not ok then error(err, 0) end
    expect(gone).toBeTrue()
  end)

  it("the closed-screen window goes stale, so a later refusal is read as a real one", function()
    local saved = M._offerGoneAt
    M._offerGoneAt = ((getEpoch and getEpoch()) or os.time()) - 300
    local stale = M._offerGone()
    M._offerGoneAt = saved
    expect(stale).toBeFalse()
  end)

  it("the one-time repair clears a list built under the old rule, once", function()
    local saved = { u = M.history.boonUnknown, f = M.history.boonUnknownFix, c = M._boonUnknownCleared }
    M.history.boonUnknown = { ["Hawk Eyes"] = 1, ["Fae-Lapse"] = 2 }
    M.history.boonUnknownFix = nil
    M._boonUnknownCleared = nil
    local realFile, realLoad = getMudletHomeDir, table.load
    getMudletHomeDir = function() return "/nowhere" end
    table.load = function() return false end
    local ok, err = pcall(function()
      M._historyLoad()
      expect(next(M.history.boonUnknown)).toBeNil()
      expect(M.history.boonUnknownFix).toBe(328)
      expect(M._boonUnknownCleared).toBe(2)
      -- ...and only once: a name refused later must stick
      M.history.boonUnknown = { ["Real Typo"] = 1 }
      M._historyLoad()
      expect(M.boonUnknown("Real Typo")).toBeTrue()
    end)
    getMudletHomeDir, table.load = realFile, realLoad
    M.history.boonUnknown, M.history.boonUnknownFix, M._boonUnknownCleared = saved.u, saved.f, saved.c
    if not ok then error(err, 0) end
  end)

  it("retry clears the mark so a corrected spelling is asked again", function()
    reset(true)
    M.history.boonUnknown = { ["Antimagic Shell"] = 1 }
    expect(M.boonUnknownRetry("Antimagic Shell")).toBeTrue()
    expect(M.boonUnknown("Antimagic Shell")).toBeFalse()
    expect(M.boonUnknownRetry("Antimagic Shell")).toBeFalse() -- not on the list any more
  end)

  it("the fill records which name it is contemplating", function()
    reset(true)
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.contemplating = nil
    local sentCmds, realSend = {}, send
    send = function(c) table.insert(sentCmds, c) end
    M._boonFillNext({ "Ogre's Speed" }, 1, 0)
    send = realSend
    M._fillBusyAt = nil -- its next step is queued and never runs; it must not hold the lock
    expect(ataxiaTemp.contemplating).toBe("Ogre's Speed")
    expect(sentCmds[#sentCmds]).toBe("boon contemplate Ogre's Speed")
    if M._captureForceFinish then pcall(M._captureForceFinish) end
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

  it("clears mnemDeadlyFlourish AND its run-scoped stamps on the confirmed onRunEnd", function()
    reset(true)
    mnemDeadlyFlourish = true
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.bardFlourishAt, ataxiaTemp.bardFlourishPendingAt, ataxiaTemp.bardFlourishSideSince = 1, 2, 3
    M.onRunEndMaybe() -- deferred maybe must NOT clear the boon yet
    expect(mnemDeadlyFlourish).toBeTrue()
    M.onRunEnd() -- confirmation fired -> boon and its clocks gone
    expect(mnemDeadlyFlourish).toBeFalse()
    expect(ataxiaTemp.bardFlourishAt).toBeNil()
    expect(ataxiaTemp.bardFlourishPendingAt).toBeNil()
    expect(ataxiaTemp.bardFlourishSideSince).toBeNil()
  end)

  it("clears mnemDeathStare AND its per-ripple charge state on the confirmed onRunEnd", function()
    reset(true)
    mnemDeathStare = true
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.deathStareRipple, ataxiaTemp.deathStareUsed, ataxiaTemp.deathStareTries = 3, true, 2
    ataxiaTemp.deathStarePendingAt, ataxiaTemp.deathStarePendingTarget = 1, 7
    M.onRunEndMaybe()
    expect(mnemDeathStare).toBeTrue()
    M.onRunEnd()
    expect(mnemDeathStare).toBeFalse()
    expect(ataxiaTemp.deathStareRipple).toBeNil()
    expect(ataxiaTemp.deathStareUsed).toBeNil()
    expect(ataxiaTemp.deathStareTries).toBeNil()
    expect(ataxiaTemp.deathStarePendingAt).toBeNil()
    expect(ataxiaTemp.deathStarePendingTarget).toBeNil()
  end)

  it("clears mnemSearingLight AND its per-room wall state on the confirmed onRunEnd", function()
    reset(true)
    mnemSearingLight = true
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.lightwallRoom, ataxiaTemp.lightwallDir = 50, "n"
    ataxiaTemp.lightwallBlocked = { north = true }
    ataxiaTemp.lightwallRipple, ataxiaTemp.lightwallRooms = 3, { [50] = true }
    M.onRunEndMaybe()
    expect(mnemSearingLight).toBeTrue()
    M.onRunEnd()
    expect(mnemSearingLight).toBeFalse()
    expect(ataxiaTemp.lightwallRoom).toBeNil()
    expect(ataxiaTemp.lightwallDir).toBeNil()
    expect(ataxiaTemp.lightwallBlocked).toBeNil()
    expect(ataxiaTemp.lightwallRipple).toBeNil()
    expect(ataxiaTemp.lightwallRooms).toBeNil()
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

  -- Was the Reaper tally until 2026-09-01 removed that boon from the game. Retargeted onto Kai
  -- Unleashed rather than deleted: what the pair was really pinning is that a run-scoped
  -- `ataxiaTemp` stamp dies with the run and does NOT die on the unconfirmed maybe, and that
  -- invariant outlived the boon that motivated it.
  it("clears a boon flag AND its ataxiaTemp stamp on the confirmed onRunEnd", function()
    reset(true)
    mnemKaiUnleashed = true
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.kaiUnleashedAt = 42
    M.onRunEndMaybe() -- deferred maybe must NOT clear the boon yet
    expect(mnemKaiUnleashed).toBeTrue()
    expect(ataxiaTemp.kaiUnleashedAt).toBe(42)
    M.onRunEnd() -- confirmation fired -> boons gone, stamp dies with the run
    expect(mnemKaiUnleashed).toBeFalse()
    expect(ataxiaTemp.kaiUnleashedAt).toBeNil()
  end)
end)

-- The Reaper tithe counter's tests lived here. Reaper was DELETED from the game on
-- 2026-09-01, so `M.onReaperTithe` is gone and there is nothing left to assert -- a test for a
-- line the game can no longer print passes forever and defends nothing.

-- ─── Boss tactics: Seasone tree reserve ──────────────────────────────────────

describe("Seasone tree reserve", function()
  local function captureSend(fn)
    local captured, realSend = {}, send
    send = function(cmd) captured[#captured + 1] = cmd end
    local ok, err = pcall(fn, captured)
    send = realSend
    if not ok then error(err) end
  end

  local function bossReset()
    reset(false)
    ataxiaBasher = { inMnemosyne = true }
    M._treeReserved, M._treeCuringOff = nil, nil
    -- reset() does NOT touch ataxiaTemp, and the burst tally lives there. Without this the
    -- tests below leak a count into each other and the SECOND one to run silently exercises
    -- the disengage branch instead of the banking branch it claims to test -- it still
    -- passes, which is what makes the leak dangerous rather than merely untidy.
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.phialBursts, ataxiaTemp.phialSpendTree = nil, nil
    M.swarm, M.phialDisengage = nil, nil
  end

  it("reserves the tree once when Seasone is the objective (any run state)", function()
    bossReset()
    captureSend(function(captured)
      M.onObjective("defeat Seasone the Industrious")
      M.onObjective("defeat Seasone the Industrious") -- status re-read: no re-send
      expect(#captured).toBe(1)
      expect(captured[1]).toBe("curing tree off")
    end)
    expect(M._treeReserved).toBeTrue()
    ataxiaBasher = nil
  end)

  it("ignores non-reserve bosses and wave objectives, and gates on the tower", function()
    bossReset()
    captureSend(function(captured)
      M.onObjective("defeat a colossal magma elemental")
      M.onObjective("defeat 3 waves of enemies")
      ataxiaBasher = nil -- outside the tower: even Seasone must not toggle curing
      M.onObjective("defeat Seasone the Industrious")
      expect(#captured).toBe(0)
    end)
    expect(M._treeReserved).toBeNil()
  end)

  -- REQUIREMENT CHANGED, v4.7.213, from a death log. These two used to assert that the burst
  -- touches tree IMMEDIATELY (v4.7.138). It does not any more, and the reason is a corpse:
  -- Seasone bursts REPEATEDLY -- twice in ~8 seconds -- so spending the tattoo on the first
  -- (survivable, 51% HP) lock left none for the second at 27%, which killed us. The burst now
  -- ARMS a watcher; the tree goes out only when the lock is still up AND it is actually
  -- dangerous. This is a deliberate behaviour change, not a test bent to pass.
  it("phial burst RELEASES the reserve but BANKS the tree (v4.7.213)", function()
    bossReset()
    M._treeReserved = true
    ataxia.vitals = { hpp = 90 }
    captureSend(function(captured)
      M.onSeasonePhials()
      expect(#captured).toBe(1)
      expect(captured[1]).toBe("curing tree on") -- handed back to SSC...
      -- ...but NOT spent: no "touch tree" while we are healthy and the lock is fresh.
    end)
    expect(M._treeReserved).toBeNil()
    expect(ataxiaTemp.phialLockAt ~= nil).toBeTrue() -- watcher armed
    M._phialTreeStop()
    ataxiaBasher = nil
  end)

  it("still arms without the reserve (missed Objective line)", function()
    bossReset()
    ataxia.vitals = { hpp = 90 }
    captureSend(function(captured)
      M.onSeasonePhials() -- must not be a no-op: that was the v4.7.138 regression
      expect(#captured).toBe(0)  -- nothing to release, nothing to spend yet
    end)
    expect(ataxiaTemp.phialLockAt ~= nil).toBeTrue()
    M._phialTreeStop()
    ataxiaBasher = nil
  end)

  it("spends the tree at once when HP is already low", function()
    bossReset()
    ataxiaTemp = { usedTree = nil }
    ataxia.vitals = { hpp = 27 }          -- the HP we actually died at
    ataxia.afflictions = { anorexia = true, asthma = true }
    captureSend(function(captured)
      M.onSeasonePhials()
      M._phialTreeTick()
      expect(captured[#captured]).toBe("touch tree")
    end)
    ataxiaBasher = nil
  end)

  it("spends it after the grace period even at healthy HP", function()
    bossReset()
    ataxiaTemp = { usedTree = nil }
    ataxia.vitals = { hpp = 95 }
    ataxia.afflictions = { slickness = true }
    captureSend(function(captured)
      M.onSeasonePhials()
      M._phialTreeTick()
      expect(#captured).toBe(0)               -- healthy + fresh: SSC gets its chance
      -- 10s: past the 5s grace, but inside the 25s window after which the watcher gives up
      -- (30s here made it stand down, correctly -- my first value, not a code bug).
      ataxiaTemp.phialLockAt = getEpoch() - 10 -- ...and failed
      M._phialTreeTick()
      expect(captured[#captured]).toBe("touch tree")
    end)
    ataxiaBasher = nil
  end)

  -- DISENGAGE ON THE SECOND BURST (v4.7.215). Rationing ONE tattoo only ever buys ONE extra
  -- burst, and the death log has her throwing more than two -- so the second burst is not a
  -- cue to cure harder, it is the cue to leave while we can still act.
  it("leaves on the second burst, and only the second", function()
    bossReset()
    ataxiaTemp = { usedTree = nil, phialBursts = nil }
    ataxia.vitals = { hpp = 90 }
    ataxia.afflictions = {}
    local calls = {}
    M.swarm = { disengage = function(why) calls[#calls + 1] = why; return true end }
    captureSend(function()
      M.onSeasonePhials()
      expect(#calls).toBe(0)                       -- burst one is survivable: stand and fight
      expect(ataxiaTemp.phialSpendTree).toBeNil()  -- ...and the tattoo stays banked for it
      M.onSeasonePhials()
      expect(#calls).toBe(1)
      expect(calls[1]).toBe("phial burst #2")
      -- Leaving ends the banking: there is no burst three to save the charge for.
      expect(ataxiaTemp.phialSpendTree).toBeTrue()
    end)
    M._phialTreeStop()
    M.swarm = nil
    ataxiaBasher = nil
  end)

  -- The unbank must actually reach the watcher, not just set a flag: the tick's own
  -- healthy-and-recent hold is what kept the tree banked, and it has to yield to it.
  it("unbanking overrides the healthy-and-recent hold", function()
    bossReset()
    ataxiaTemp = { usedTree = nil, phialBursts = nil }
    ataxia.vitals = { hpp = 95 }               -- healthy: the tick would normally hold
    ataxia.afflictions = { slickness = true }  -- but the lock is up
    M.swarm = { disengage = function() return true end }
    captureSend(function(captured)
      M.onSeasonePhials()
      M._phialTreeTick()
      expect(#captured).toBe(0)                -- burst one: still banked
      M.onSeasonePhials()                      -- burst two: unbank
      M._phialTreeTick()
      expect(captured[#captured]).toBe("touch tree")
    end)
    M._phialTreeStop()
    M.swarm = nil
    ataxiaBasher = nil
  end)

  it("counts bursts per ripple -- a new ripple is a new fight", function()
    bossReset()
    ataxiaTemp = { usedTree = nil, phialBursts = nil }
    ataxia.vitals = { hpp = 90 }
    ataxia.afflictions = {}
    local calls = 0
    M.swarm = { disengage = function() calls = calls + 1; return true end }
    captureSend(function()
      M.onSeasonePhials()
      M.onRipple(4)                            -- her ripple ended; the tally must not carry
      M.onSeasonePhials()
      expect(calls).toBe(0)                    -- this is burst ONE again, not two
    end)
    M._phialTreeStop()
    M.swarm = nil
    ataxiaBasher = nil
  end)

  -- SPLINTERBARK is the case the old early-return silently broke: the tree is tainted, so
  -- the escape ladder is the only answer left -- and it was the one path that never ran.
  it("leaves on the FIRST burst when Splinterbark has tainted the tree", function()
    bossReset()
    M._treeCuringOff = true
    ataxiaTemp = { usedTree = nil, phialBursts = nil }
    ataxia.vitals = { hpp = 90 }
    local calls = {}
    M.swarm = { disengage = function(why) calls[#calls + 1] = why; return true end }
    captureSend(function(captured)
      M.onSeasonePhials()
      expect(#calls).toBe(1)
      expect(calls[1]).toBe("phial burst #1")
      -- A tainted tree is never touched or re-enabled, disengage or not.
      expect(#captured).toBe(0)
      expect(ataxiaTemp.phialSpendTree).toBeNil()
      expect(ataxiaTemp.phialLockAt).toBeNil()   -- no watcher: there is nothing to spend
    end)
    M._treeCuringOff = nil
    M.swarm = nil
    ataxiaBasher = nil
  end)

  it("honours phialDisengage (0 disables, 3 stands longer)", function()
    bossReset()
    ataxiaTemp = { usedTree = nil, phialBursts = nil }
    ataxia.vitals = { hpp = 90 }
    ataxia.afflictions = {}
    local calls = 0
    M.swarm = { disengage = function() calls = calls + 1; return true end }
    M.phialDisengage = 0
    captureSend(function()
      M.onSeasonePhials(); M.onSeasonePhials(); M.onSeasonePhials()
      expect(calls).toBe(0)
      ataxiaTemp.phialBursts = nil
      M.phialDisengage = 3
      M.onSeasonePhials(); M.onSeasonePhials()
      expect(calls).toBe(0)
      M.onSeasonePhials()
      expect(calls).toBe(1)
    end)
    M._phialTreeStop()
    M.phialDisengage, M.swarm = nil, nil
    ataxiaBasher = nil
  end)

  -- THE FULL LOCK IS A DIFFERENT EVENT FROM THE BURST (v4.7.235). User: "When we get imp sli
  -- ast ano we should be touching tree and also shielding would help here. So pause the attack
  -- touch tree and shield as we dont have paralysis yet."
  --
  -- v4.7.213 was right that the BURST is not the moment to spend the tattoo. But once all four
  -- land, slickness blocks salves and anorexia blocks eating -- there is no cure route left
  -- that does not start with the tattoo, so waiting out treeGrace just donates five seconds.
  it("stops swinging, trees and shields on the FULL lock", function()
    bossReset()
    ataxiaTemp = { usedTree = nil }
    ataxia.vitals = { hpp = 90 }
    ataxia.defences = {}
    ataxia.afflictions = { anorexia = true, slickness = true, asthma = true, impatience = true }
    captureSend(function(captured)
      expect(M._phialLockResponse()).toBeTrue()
      -- `cq all` FIRST: whatever is queued was decided before the lock existed, and every
      -- attack sends `queue addclearfull` -- which is what ate the escape in the death log.
      expect(captured[1]:find("cq all", 1, true) ~= nil).toBeTrue()
      expect(captured[1]:find("touch tree", 1, true) ~= nil).toBeTrue()
      expect(captured[1]:find("touch shield", 1, true) ~= nil).toBeTrue()
    end)
    expect(ataxiaTemp.phialHold).toBeTrue()   -- attack paused
    ataxiaBasher = nil
  end)

  it("does nothing until ALL FOUR are up", function()
    bossReset()
    ataxiaTemp = {}
    ataxia.afflictions = { anorexia = true, slickness = true, asthma = true } -- no impatience
    captureSend(function(captured)
      expect(M._phialLockResponse()).toBeFalse()
      expect(#captured).toBe(0)
    end)
    expect(ataxiaTemp.phialHold).toBe(nil)
    ataxiaBasher = nil
  end)

  -- A shield needs an arm and a free action. Paralysed, the command is a refusal that costs
  -- the round -- and the round is the only thing we have left.
  it("skips the shield while paralysed, but still trees", function()
    bossReset()
    ataxiaTemp = { usedTree = nil }
    ataxia.defences = {}
    ataxia.afflictions = { anorexia = true, slickness = true, asthma = true,
                           impatience = true, paralysis = true }
    captureSend(function(captured)
      expect(M._phialLockResponse()).toBeTrue()
      expect(captured[1]:find("touch tree", 1, true) ~= nil).toBeTrue()
      expect(captured[1]:find("touch shield", 1, true)).toBe(nil)
    end)
    ataxiaBasher = nil
  end)

  it("skips a shield we already have", function()
    bossReset()
    ataxiaTemp = { usedTree = nil }
    ataxia.defences = { shield = true }
    ataxia.afflictions = { anorexia = true, slickness = true, asthma = true, impatience = true }
    captureSend(function(captured)
      expect(M._phialLockResponse()).toBeTrue()
      expect(captured[1]:find("touch shield", 1, true)).toBe(nil)
    end)
    ataxiaBasher = nil
  end)

  -- The tattoo is on cooldown: sending it is a guaranteed refusal, and Splinterbark taints it
  -- outright. Neither should stop the shield going up.
  it("skips the tree on cooldown and still shields", function()
    bossReset()
    ataxiaTemp = { usedTree = true }
    ataxia.defences = {}
    ataxia.afflictions = { anorexia = true, slickness = true, asthma = true, impatience = true }
    captureSend(function(captured)
      expect(M._phialLockResponse()).toBeTrue()
      expect(captured[1]:find("touch tree", 1, true)).toBe(nil)
      expect(captured[1]:find("touch shield", 1, true) ~= nil).toBeTrue()
    end)
    ataxiaBasher = nil
  end)

  -- Once per lock, not once per tick: the watcher fires every second and this must not become
  -- a stream of cq-all, which would wipe whatever curing SSC has queued.
  it("responds once per lock, not on every tick", function()
    bossReset()
    ataxiaTemp = { usedTree = nil }
    ataxia.defences = {}
    ataxia.afflictions = { anorexia = true, slickness = true, asthma = true, impatience = true }
    captureSend(function(captured)
      M._phialLockResponse()
      M._phialLockResponse()
      M._phialLockResponse()
      expect(#captured).toBe(1)
    end)
    ataxiaBasher = nil
  end)

  it("is inert outside the tower", function()
    bossReset()
    ataxiaBasher = nil
    ataxiaTemp = {}
    ataxia.afflictions = { anorexia = true, slickness = true, asthma = true, impatience = true }
    captureSend(function(captured)
      expect(M._phialLockResponse()).toBeFalse()
      expect(#captured).toBe(0)
    end)
  end)

  -- The banking only pays off if the tree survives a lock SSC handles itself.
  it("keeps the tree banked when the lock clears on its own", function()
    bossReset()
    ataxiaTemp = { usedTree = nil }
    ataxia.vitals = { hpp = 27 }
    ataxia.afflictions = {}               -- SSC already broke it
    captureSend(function(captured)
      M.onSeasonePhials()
      M._phialTreeTick()
      expect(#captured).toBe(0)
    end)
    expect(ataxiaTemp.phialLockAt).toBe(nil) -- watcher stood down
    ataxiaBasher = nil
  end)

  it("never fires into a cooldown -- that was the 'glows faintly' spam", function()
    bossReset()
    ataxiaTemp = { usedTree = true }      -- tattoo already spent
    ataxia.vitals = { hpp = 10 }
    ataxia.afflictions = { anorexia = true }
    captureSend(function(captured)
      M.onSeasonePhials()
      M._phialTreeTick()
      expect(#captured).toBe(0)
    end)
    expect(ataxiaTemp.phialLockAt ~= nil).toBeTrue() -- still waiting, not given up
    M._phialTreeStop()
    ataxiaBasher = nil
  end)

  it("fires the moment the tree comes off cooldown, via the ready line", function()
    bossReset()
    ataxiaTemp = { usedTree = true }
    ataxia.vitals = { hpp = 10 }
    ataxia.afflictions = { anorexia = true }
    captureSend(function(captured)
      M.onSeasonePhials()
      M._phialTreeTick()
      expect(#captured).toBe(0)
      ataxiaTemp.usedTree = nil           -- "You may utilise the tree tattoo again."
      M.onTreeReady()
      expect(captured[#captured]).toBe("touch tree")
    end)
    ataxiaBasher = nil
  end)

  it("a tainted tree is never spent, however bad it gets", function()
    bossReset()
    M._treeCuringOff = true
    ataxiaTemp = { usedTree = nil }
    ataxia.vitals = { hpp = 5 }
    ataxia.afflictions = { anorexia = true }
    captureSend(function(captured)
      M.onSeasonePhials()
      M._phialTreeTick()
      expect(#captured).toBe(0)
    end)
    M._treeCuringOff = nil
    ataxiaBasher = nil
  end)

  it("never re-enables a Splinterbark-tainted tree", function()
    bossReset()
    M._treeReserved, M._treeCuringOff = true, true
    captureSend(function(captured)
      M.onSeasonePhials()
      expect(#captured).toBe(0) -- reserve cleared, but the tainted tree stays off
    end)
    expect(M._treeReserved).toBeNil()
    M._treeCuringOff = nil
    ataxiaBasher = nil
  end)

  it("releaseTreeReserve restores on ripple/run boundaries, no-op otherwise", function()
    bossReset()
    M._treeReserved = true
    captureSend(function(captured)
      M.releaseTreeReserve()
      M.releaseTreeReserve()
      expect(#captured).toBe(1)
      expect(captured[1]).toBe("curing tree on")
    end)
    ataxiaBasher = nil
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

-- ─── Last Word affix pacing ──────────────────────────────────────────────────
--
-- "Denizens explode on death!" (captured live 2026-08-02). The damage lands at the exact
-- moment the room goes quiet -- the moment the sweep would otherwise walk on -- so this is a
-- PACING affix like Haemophiliac, and shares its 90% post-clear gate (user spec). It does NOT
-- share the bleed clause: an explosion is instantaneous, so there is nothing for SSC to clot
-- down and nothing to wait on but regeneration.

describe("Last Word explode-on-death pacing", function()
  it("onLastWordSeen arms the flag only inside the tower", function()
    reset(true)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = false
    mnemLastWord = false
    M.onLastWordSeen()
    expect(mnemLastWord).toBeFalse() -- a `mnem affixes` read outside a run must not arm it
    ataxiaBasher.inMnemosyne = true
    M.onLastWordSeen()
    expect(mnemLastWord).toBeTrue()
    M.onLastWordSeen() -- transition-guarded: a status re-read is a no-op
    expect(mnemLastWord).toBeTrue()
    ataxiaBasher.inMnemosyne = false
  end)

  it("_lastWordHold holds the sweep below 90% HP", function()
    mnemLastWord = false
    ataxia.vitals = { hpp = 40 }
    expect(M._lastWordHold()).toBeFalse() -- no affix: never hold
    mnemLastWord = true
    expect(M._lastWordHold()).toBeTrue()
    ataxia.vitals = { hpp = 89 }
    expect(M._lastWordHold()).toBeTrue()  -- just under the line: still hold
    ataxia.vitals = { hpp = 90 }
    expect(M._lastWordHold()).toBeFalse() -- "at least 90 percent" (user spec) -- 90 goes
    ataxia.vitals = { hpp = 100 }
    expect(M._lastWordHold()).toBeFalse()
    mnemLastWord = false
  end)

  it("ignores the bleed -- an explosion is instantaneous, there is nothing to clot", function()
    mnemLastWord = true
    ataxia.vitals = { hpp = 95, bleed = 900 }
    expect(M._lastWordHold()).toBeFalse() -- unlike _haemoHold, which would still hold here
    mnemLastWord = false
  end)

  it("never wedges on a missing HP reading", function()
    mnemLastWord = true
    ataxia.vitals = {} -- blackout / no charstats yet
    expect(M._lastWordHold()).toBeFalse() -- defaults to 100, so the sweep keeps moving
    mnemLastWord = false
  end)

  it("is independent of Haemophiliac -- either one holding is enough", function()
    mnemLastWord, mnemHaemophiliac = true, false
    ataxia.vitals = { hpp = 50, bleed = 0 }
    expect(M._lastWordHold()).toBeTrue()
    expect(M._haemoHold()).toBeFalse()
    mnemLastWord, mnemHaemophiliac = false, true
    expect(M._lastWordHold()).toBeFalse()
    expect(M._haemoHold()).toBeTrue()
    mnemHaemophiliac = false
  end)

  it("clears on the confirmed run end", function()
    reset(true)
    mnemLastWord = true
    M.onRunEnd()
    expect(mnemLastWord).toBeFalse()
  end)
end)

-- PER-RIPPLE PERFORMANCE PROBE (v4.7.204). Everything else that knows about the bard's bash
-- performance is REACTIVE -- the fade line, the "not in fact performing" error, the "already
-- performing" refusal -- and all of them need something to go wrong first. PERFORMANCE is the
-- one cheap way to ASK, and the boon screen is exactly where a performance can lapse unseen.
describe("bard PERFORMANCE probe after the boon screen", function()
  local sent, realSend, realTimer, fired
  local function arm(class)
    sent, fired = {}, nil
    realSend, realTimer = send, tempTimer
    send = function(c) table.insert(sent, c) end
    tempTimer = function(_, fn) fired = fn; return 1 end
    gmcp = gmcp or {}; gmcp.Char = gmcp.Char or {}
    gmcp.Char.Status = { class = class }
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.enabled = true
    ataxiaTemp = {}
    ataxiaBasher_bardCompose = function() table.insert(sent, "RECOMPOSED") end
  end
  local function disarm() send, tempTimer = realSend, realTimer end

  -- `PERFORMANCE SHOW`: the bare verb is not a command (the game answers it with its syntax
  -- help). This assertion previously pinned "performance" -- verifying WHAT we send with no
  -- notion of whether it was real, exactly as the `boons` test did before v4.7.203. The
  -- sub-verb assertion below is the part that would actually have caught it.
  it("asks for PERFORMANCE SHOW as a bard", function()
    arm("Bard"); M._bardPerformanceCheck()
    expect(sent[1]).toBe("performance show")
    disarm()
  end)

  it("sends a SUB-VERB, never the bare command", function()
    arm("Bard"); M._bardPerformanceCheck()
    -- Valid forms are SHOW / END / SUSPEND / RESUME. Bare `performance` returns syntax help,
    -- which trigger 001 cannot parse -- so the probe would time out and recompose every time.
    expect(sent[1] ~= "performance").toBeTrue()
    expect(sent[1]:match("^performance %a+$") ~= nil).toBeTrue()
    disarm()
  end)

  it("is inert for every other class", function()
    arm("Runewarden"); M._bardPerformanceCheck()
    expect(#sent).toBe(0)
    disarm()
  end)

  it("is inert while the basher is off", function()
    arm("Bard"); ataxiaBasher.enabled = false
    M._bardPerformanceCheck()
    expect(#sent).toBe(0)
    disarm()
  end)

  it("does NOT recompose when the performance answers", function()
    arm("Bard"); M._bardPerformanceCheck()
    ataxiaTemp.bardPerfProbe = nil   -- what trigger 001 does on the "shall last another N" line
    fired()
    expect(table.concat(sent, ",")).toBe("performance show") -- probe only, no recompose
    disarm()
  end)

  it("DOES recompose when nothing answers -- whatever the game said", function()
    arm("Bard"); M._bardPerformanceCheck()
    fired()                           -- window elapsed, probe never cleared
    expect(sent[2]).toBe("RECOMPOSED")
    expect(ataxiaTemp.bardPerfProbe).toBe(nil)
    disarm()
  end)
end)

-- v4.7.333, user: "Rimewrought: Perpetual ice coats your body, rendering tattoos ineffective..."
-- -- "When we have this ongoing effect or affix. We cannot use tattoos."
describe("Rimewrought affix -- the tattoos that stop working", function()
  it("arms only inside the tower, once, and turns the game's tree curing off", function()
    reset(true)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = false
    mnemRimewrought, M._treeCuringOff = false, nil
    local realSend, sends = send, {}
    send = function(c) sends[#sends + 1] = tostring(c) end
    local ok, err = pcall(function()
      M.onRimewroughtSeen()
      expect(mnemRimewrought).toBeFalse()   -- outside the tower it does nothing
      ataxiaBasher.inMnemosyne = true
      M.onRimewroughtSeen()
      expect(mnemRimewrought).toBeTrue()
      expect(M._treeCuringOff).toBeTrue()   -- the tree is a tattoo too
      expect(table.concat(sends, " "):find("curing tree off", 1, true) ~= nil).toBeTrue()
      local n = #sends
      M.onRimewroughtSeen()                 -- a status re-read sends nothing more
      expect(#sends).toBe(n)
    end)
    send = realSend
    ataxiaBasher.inMnemosyne = false
    mnemRimewrought, M._treeCuringOff = false, nil
    if not ok then error(err, 0) end
  end)

  -- v4.7.334, user: "We need to not keepup mindseye, cloak, (anything else that is a tattoo)
  -- because it will just spam. So take off defences keepup and we can reput it back on when that
  -- affix is gone."
  it("takes the tattoo defences off keep-up, and puts back exactly those at run end", function()
    reset(true)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    mnemRimewrought, M._treeCuringOff, M._rimeTattoosOff = false, nil, nil
    local savedDefs, savedTables = ataxia.settings.defences, ataxiaTables
    ataxia.settings.defences = { current = "bash",
      defup = { bash = { mindseye = true, cloak = true, insomnia = true } }, keepup = { bash = {} } }
    ataxiaTables = { classDefences = { tattoos = { mindseye = "mindseye", cloak = "cloak",
      mosstattoo = "mosstattoo" } } }
    local realSend, sends = send, {}
    send = function(c) sends[#sends + 1] = tostring(c) end
    local ok, err = pcall(function()
      M.onRimewroughtSeen()
      local all = table.concat(sends, " | ")
      expect(all:find("cloak reset", 1, true) ~= nil).toBeTrue()
      expect(all:find("mindseye reset", 1, true) ~= nil).toBeTrue()
      expect(all:find("insomnia", 1, true)).toBeNil()   -- not a tattoo: left alone
      expect(all:find("mosstattoo", 1, true)).toBeNil() -- a tattoo we never asked to keep up
      expect(#M._rimeTattoosOff).toBe(2)
      -- the saved profile itself is untouched: an affix must not edit config that outlives it
      expect(ataxia.settings.defences.defup.bash.cloak).toBeTrue()
      sends = {}
      M.onRunEnd()
      local back = table.concat(sends, " | ")
      expect(back:find("cloak 25", 1, true) ~= nil).toBeTrue()
      expect(back:find("mindseye 25", 1, true) ~= nil).toBeTrue()
      expect(M._rimeTattoosOff).toBeNil()
      expect(M.restoreTattooKeepup()).toBeFalse() -- nothing owed twice
    end)
    send = realSend
    ataxia.settings.defences, ataxiaTables = savedDefs, savedTables
    ataxiaBasher.inMnemosyne = false
    mnemRimewrought, M._treeCuringOff, M._rimeTattoosOff = false, nil, nil
    if not ok then error(err, 0) end
  end)

  it("says nothing to SSC when no tattoo is on keep-up", function()
    local savedDefs, savedTables = ataxia.settings.defences, ataxiaTables
    ataxia.settings.defences = { current = "bash", defup = { bash = { insomnia = true } }, keepup = {} }
    ataxiaTables = { classDefences = { tattoos = { cloak = "cloak" } } }
    local realSend, sends = send, {}
    send = function(c) sends[#sends + 1] = tostring(c) end
    local ok, err = pcall(function()
      expect(M.stripTattooKeepup()).toBeFalse()
      expect(#sends).toBe(0)
    end)
    send = realSend
    ataxia.settings.defences, ataxiaTables = savedDefs, savedTables
    if not ok then error(err, 0) end
  end)

  it("the basher stops spending actions on a shield that cannot work", function()
    local saved = mnemRimewrought
    mnemRimewrought = false
    expect(ataxiaBasher_tattoosDead()).toBeFalse()
    mnemRimewrought = true
    expect(ataxiaBasher_tattoosDead()).toBeTrue()
    mnemRimewrought = saved
  end)

  it("the lock-breaker drops the shield half, and the tree with it", function()
    reset(true)
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.usedTree, ataxiaTemp.phialHold = nil, nil
    ataxia.afflictions = ataxia.afflictions or {}
    ataxia.defences = ataxia.defences or {}
    local realSend, sends = send, {}
    send = function(c) sends[#sends + 1] = tostring(c) end
    mnemRimewrought, M._treeCuringOff = true, true -- as onRimewroughtSeen leaves them
    local ok, err = pcall(function()
      local fired = M._lockBreak and M._lockBreak() or false
      expect(fired).toBeFalse() -- nothing left to send: both halves are tattoos
      expect(table.concat(sends, " "):find("touch", 1, true)).toBeNil()
    end)
    send = realSend
    mnemRimewrought, M._treeCuringOff = false, nil
    if ataxiaTemp then ataxiaTemp.phialHold = nil end
    if not ok then error(err, 0) end
  end)

  it("clears on the confirmed run end -- tattoos work again outside", function()
    reset(true)
    mnemRimewrought = true
    M.onRunEnd()
    expect(mnemRimewrought).toBeFalse()
  end)

  it("trigger 096 hands the status line to the module", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/096_Rimewrought.lua")
    local src = f:read("*a"); f:close()
    expect(src:find("Perpetual ice coats your body", 1, true) ~= nil).toBeTrue()
    expect(src:find("ataxia.mnemosyne.onRimewroughtSeen()", 1, true) ~= nil).toBeTrue()
  end)

  it("trigger 097 hands the Famine line to the module", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/097_Famine.lua")
    local src = f:read("*a"); f:close()
    expect(src:find("Taking damage has a chance to make you more hungry", 1, true) ~= nil).toBeTrue()
    expect(src:find("ataxia.mnemosyne.onFamineSeen()", 1, true) ~= nil).toBeTrue()
  end)
end)

describe("Bravado affix -- the mitigations that stop working", function()
  it("onBravadoSeen arms the flag only inside the tower", function()
    reset(true)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = false
    mnemBravado = false
    M.onBravadoSeen()
    expect(mnemBravado).toBeFalse()
    ataxiaBasher.inMnemosyne = true
    M.onBravadoSeen()
    expect(mnemBravado).toBeTrue()
    M.onBravadoSeen() -- transition-guarded: a status re-read is a no-op
    expect(mnemBravado).toBeTrue()
    ataxiaBasher.inMnemosyne = false
    mnemBravado = false
  end)

  it("clears on the confirmed run end -- barriers work again outside", function()
    reset(true)
    mnemBravado = true
    M.onRunEnd()
    expect(mnemBravado).toBeFalse()
  end)
end)

-- TANTRUM (v4.7.209): "Your first battlerage ability per ripple costs no rage." Rage-Fuelled's
-- twin -- same ataxiaTemp.brFreeCharge state, armed per RIPPLE instead of per KILL -- so the
-- entire payoff (rageAfford's 37 sites, the 8 culling gates, brCommit/brSent) comes for free.
describe("Tantrum -- a free battlerage once per ripple", function()
  local function arm(ripple)
    reset(true)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    ataxiaTemp = {}
    mnemTantrum = true
    M.run.ripple = ripple or 1
  end

  it("banks the charge on a fresh ripple", function()
    arm(3); M.tantrumArm()
    expect(ataxiaTemp.brFreeCharge).toBeTrue()
  end)

  it("does nothing without the boon", function()
    arm(3); mnemTantrum = false; M.tantrumArm()
    expect(ataxiaTemp.brFreeCharge).toBe(nil)
  end)

  it("is inert outside the tower", function()
    arm(3); ataxiaBasher.inMnemosyne = false; M.tantrumArm()
    expect(ataxiaTemp.brFreeCharge).toBe(nil)
    ataxiaBasher.inMnemosyne = false
  end)

  -- The guard that matters: the flag can be re-latched mid-ripple (relatchBoons, a BOONS row,
  -- the claim alias), and without this each of those would hand out ANOTHER free battlerage
  -- in a ripple whose first was already spent.
  it("does NOT re-bank within the same ripple after the charge was spent", function()
    arm(3); M.tantrumArm()
    ataxiaTemp.brFreeCharge = nil          -- spent on the first battlerage
    M.tantrumArm()                          -- a BOONS re-read, say
    expect(ataxiaTemp.brFreeCharge).toBe(nil)
  end)

  it("banks again on the NEXT ripple", function()
    arm(3); M.tantrumArm()
    ataxiaTemp.brFreeCharge = nil
    M.run.ripple = 4
    M.tantrumArm()
    expect(ataxiaTemp.brFreeCharge).toBeTrue()
  end)

  it("onRipple arms it, and does so before the telemetry gate", function()
    arm(5)
    ataxiaTemp.brFreeCharge, ataxiaTemp.tantrumRipple = nil, nil
    M.run.ripple = 5
    M.onRipple(6)
    expect(ataxiaTemp.brFreeCharge).toBeTrue()
  end)

  it("clears on the confirmed run end", function()
    arm(3); M.tantrumArm()
    M.onRunEnd()
    expect(mnemTantrum).toBeFalse()
    expect(ataxiaTemp.tantrumRipple).toBe(nil)
  end)

  it("coexists with Rage-Fuelled -- one boolean, either source", function()
    arm(3)
    mnemRageFuelled = true
    M.tantrumArm()
    expect(ataxiaTemp.brFreeCharge).toBeTrue()  -- not a counter; one charge is one charge
    mnemRageFuelled = false
  end)
end)


-- `M.reaperOnWade` (spare the tally across a pause-resume wade) went with the boon, 2026-09-01.

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

-- THE BOON DATABASE (v4.7.239). User: "I would love to do a boons database that captures all
-- of the boons and their effects for safe storage."
--
-- The catalogue itself already existed (M.history.boonLibrary, fed by every offer screen).
-- What it lacked was a viewer and storage of its OWN. A boon's description is shown exactly
-- once -- the BOONS list you read to see what you own has no descriptions at all -- so the
-- catalogue is genuinely irreplaceable, and it was living inside the same file as run counters
-- and claims, which are rewritten constantly and worthless next week.
describe("boon database", function()
  local function lib(t)
    M.history = M.history or {}
    M.history.boonLibrary = t
  end

  it("counts what it actually knows, not just how many names", function()
    lib({
      Outlaw = { description = "You are immune to the justice and guilt afflictions.", rarity = "uncommon" },
      Beeline = { description = "You may now utilise prism tattoos." },
      Mystery = {},
    })
    local st = M.boonDbStats()
    expect(st.total).toBe(3)
    expect(st.described).toBe(2)
    expect(st.rarity).toBe(1)
  end)

  -- A merge, never a replace: the offer screen supplies the description, the BOONS list the
  -- rarity, the detail screen maxEchoes. An import must only ever ADD -- otherwise restoring a
  -- backup could blank richer data than it carries.
  it("merges an import without blanking anything richer", function()
    lib({ Outlaw = { description = "You are immune to the justice and guilt afflictions." } })
    local added, enriched = M._boonDbMerge({
      Outlaw  = { description = "", rarity = "uncommon" },   -- fills rarity, keeps description
      Newcomer = { description = "Something new.", rarity = "rare" },
    })
    expect(added).toBe(1)
    expect(enriched).toBe(1)
    expect(M.history.boonLibrary.Outlaw.description)
      .toBe("You are immune to the justice and guilt afflictions.")
    expect(M.history.boonLibrary.Outlaw.rarity).toBe("uncommon")
    expect(M.history.boonLibrary.Newcomer.rarity).toBe("rare")
  end)

  it("ignores junk rather than storing it", function()
    lib({})
    local added = M._boonDbMerge({ [""] = { description = "x" }, Good = { description = "y" } })
    expect(added).toBe(1)
    expect(M.history.boonLibrary[""]).toBe(nil)
    expect(M._boonDbMerge("not a table")).toBe(0)
  end)

  it("is idempotent -- re-importing the same file changes nothing", function()
    lib({})
    local src = { Outlaw = { description = "You are immune to the justice and guilt afflictions.",
                             rarity = "uncommon" } }
    local a1 = M._boonDbMerge(src)
    local a2, e2 = M._boonDbMerge(src)
    expect(a1).toBe(1)
    expect(a2).toBe(0)
    expect(e2).toBe(0)
  end)

  -- The filter is the point of the viewer: "immune" should find every immunity boon, because
  -- that is the question you have while an offer screen is up.
  it("filters on the effect text, not just the name", function()
    lib({
      Outlaw   = { description = "You are immune to the justice and guilt afflictions." },
      Plasmatic = { description = "You are immune to the haemophilia affliction." },
      Beeline  = { description = "You may now utilise prism tattoos." },
    })
    local shown = {}
    local realEcho, realCecho = M.echo, cecho
    M.echo = function() end
    cecho = function(t) shown[#shown + 1] = tostring(t) end
    M.reportBoonDb("immune")
    M.echo, cecho = realEcho, realCecho
    local blob = table.concat(shown, " ")
    expect(blob:find("Outlaw", 1, true) ~= nil).toBeTrue()
    expect(blob:find("Plasmatic", 1, true) ~= nil).toBeTrue()
    expect(blob:find("Beeline", 1, true)).toBe(nil)
  end)

  -- v4.7.327, user: "For our boon database we should also capture the boons category! Offence,
  -- Defence, etc." It was stored since v4.7.298 but never shown, counted or searchable.
  it("shows each boon's category, counts them, and filters on it", function()
    lib({
      ["Elder Wisdom"]      = { description = "The Jade Empress increases your intelligence by 1.", category = "Offence" },
      ["Ashaxei's Mirror"]  = { description = "Gain 1 reflections.", category = "Defence" },
      ["Fae-Lapse"]         = { description = "Amnesia.", category = "Utility" },
      ["Unseen"]            = { description = "Never contemplated." },
    })
    local shown, said = {}, {}
    local realEcho, realCecho = M.echo, cecho
    M.echo = function(m) said[#said + 1] = tostring(m) end
    cecho = function(s) shown[#shown + 1] = tostring(s) end
    local ok, err = pcall(function()
      M.reportBoonDb()
      local all = table.concat(shown, " ")
      expect(all:find("Elder Wisdom<reset>", 1, true) ~= nil).toBeTrue()
      expect(all:find("<white>Offence", 1, true) ~= nil).toBeTrue()
      local header = table.concat(said, " ")
      expect(header:find("<white>Defence<grey> 1", 1, true) ~= nil).toBeTrue()
      expect(header:find("1 not yet contemplated", 1, true) ~= nil).toBeTrue()
      shown = {}
      M.reportBoonDb("offence")
      local only = table.concat(shown, " ")
      expect(only:find("Elder Wisdom", 1, true) ~= nil).toBeTrue()
      expect(only:find("Mirror", 1, true)).toBe(nil)
      expect(M.boonDbStats().categories.Utility).toBe(1)
    end)
    M.echo, cecho = realEcho, realCecho
    if not ok then error(err, 0) end
  end)
end)

-- THE SEED CATALOGUE (v4.7.240): 294 boons from the community database at
-- mediaresachaea.github.io/mnemosyne-boons, so the database is useful on day one instead of
-- only for boons this character has personally been offered.
-- GENERIC BOON LATCH + the consumers it enables (v4.7.241). User: "understand we need those
-- boons for those skills to work" -- so every consumer is gated on its flag and a boon we do
-- not hold must change NOTHING.
describe("generic boon latch", function()
  local function clean()
    M.clearBoonFlags()
  end

  it("arms the flag for a known boon", function()
    clean()
    expect(M.latchBoonFlag("Vitalising Tincture")).toBe("mnemVitalisingTincture")
    expect(mnemVitalisingTincture).toBeTrue()
    clean()
  end)

  -- An (ECHO) row names the SAME boon: a second copy does not make it a different one, and the
  -- user's own export has 37 of them.
  it("treats an (ECHO) row as the same boon", function()
    clean()
    expect(M.latchBoonFlag("(ECHO) Font of Life")).toBe("mnemFontOfLife")
    expect(mnemFontOfLife).toBeTrue()
    clean()
  end)

  it("ignores a boon it has no consumer for", function()
    clean()
    expect(M.latchBoonFlag("Beeline")).toBe(nil)
    expect(M.latchBoonFlag(nil)).toBe(nil)
  end)

  it("clears every flag on a run end -- boons are per-run", function()
    M.latchBoonFlag("Shadow Tempo")
    expect(mnemShadowTempo).toBeTrue()
    M.clearBoonFlags()
    expect(mnemShadowTempo).toBeFalse()
  end)
end)

-- THE BUG THIS ANALYSIS FOUND. _phialFullLock required all four afflictions to be actively on
-- us -- but `Coarse Flesh` grants immunity to SLICKNESS and `Kevadrin's Patience` to
-- IMPATIENCE. Holding either made the full lock unreachable, so the tree-and-shield response
-- never fired against the exact fight it was written for.
describe("phial lock vs an affliction we cannot get", function()
  local function locked(affs, claimsList)
    ataxiaBasher = { inMnemosyne = true }
    ataxiaTemp = { usedTree = nil }
    ataxia.defences = {}
    ataxia.afflictions = affs
    M.history = M.history or {}
    M.history.run = 7
    M.history.claims = claimsList or {}
    return M._phialFullLock()
  end

  it("still needs all four when we hold no immunity", function()
    expect(locked({ anorexia = true, slickness = true, asthma = true })).toBeFalse()
    expect(locked({ anorexia = true, slickness = true, asthma = true, impatience = true })).toBeTrue()
  end)

  it("counts an immune affliction as satisfied", function()
    -- Coarse Flesh: immune to slickness. Slickness will never land, so the other three ARE
    -- the full lock -- the best version of it available, not an exception to it.
    local claims = { { run = 7, name = "Coarse Flesh",
                       description = "You are immune to slickness, but suffer permanent timeflux." } }
    expect(locked({ anorexia = true, asthma = true, impatience = true }, claims)).toBeTrue()
  end)

  it("does not fire on a partial lock just because we hold an immunity", function()
    local claims = { { run = 7, name = "Coarse Flesh",
                       description = "You are immune to slickness, but suffer permanent timeflux." } }
    expect(locked({ anorexia = true, asthma = true }, claims)).toBeFalse()
  end)
end)

-- FONT OF LIFE: the tattoo cures two, so it buys one more burst before leaving.
describe("Font of Life shifts the disengage", function()
  it("leaves on burst two without it, three with it", function()
    ataxiaBasher = { inMnemosyne = true }
    ataxia.afflictions = {}
    ataxia.vitals = { hpp = 90 }
    local calls = 0
    M.swarm = { disengage = function() calls = calls + 1; return true end }

    mnemFontOfLife = false
    ataxiaTemp = { phialBursts = nil }
    M.onSeasonePhials(); M.onSeasonePhials()
    expect(calls).toBe(1)
    M._phialTreeStop()

    calls = 0
    mnemFontOfLife = true
    ataxiaTemp = { phialBursts = nil }
    M.onSeasonePhials(); M.onSeasonePhials()
    expect(calls).toBe(0)          -- the tattoo is worth twice as much: stay one more burst
    M.onSeasonePhials()
    expect(calls).toBe(1)
    M._phialTreeStop()
    mnemFontOfLife = false
    M.swarm = nil
    ataxiaBasher = nil
  end)
end)

describe("boon seed catalogue", function()
  -- The seed populates the shared library, so save and restore around it -- this file's other
  -- tests build their own fixtures on M.history and must not inherit 294 rows.
  local saved
  local function withSeed(fn)
    saved = M.history.boonLibrary
    M.history.boonLibrary = {}
    local ok, err = pcall(fn)
    M.history.boonLibrary = saved
    if not ok then error(err) end
  end

  -- Was `described == total` ("a row with no effect text is not worth seeding") until 2026-09-01
  -- added 30 boons whose EFFECTS the announcement did not state. Seeding the names anyway is
  -- deliberate -- it turns an unknown into a visible hole -- but the invariant has to get
  -- STRICTER, not looser, or a genuine omission hides among the intentional ones. So: every
  -- undescribed entry must be DECLARED in `M.BOON_UNDESCRIBED`, and every declared name must
  -- actually be in the seed. A hole has to be admitted before it is allowed.
  it("describes every entry except the holes it declares", function()
    withSeed(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      local st = M.boonDbStats()
      expect(st.total > 250).toBeTrue()

      local declared = {}
      for _, n in ipairs(M.BOON_UNDESCRIBED) do
        expect(M.BOON_SEED[n] ~= nil).toBeTrue()   -- declared but absent = a stale declaration
        declared[n] = true
      end
      for name, rec in pairs(M.BOON_SEED) do
        if not (rec.description and rec.description ~= "") then
          expect(declared[name]).toBeTrue()        -- undeclared hole = an accidental omission
        end
      end
      -- NOT `described == total - #declared`. `Cavalry` is on the announcement's "new boons"
      -- list and our catalogue already had its text -- so the announcement's "new" is not
      -- strictly new, and the `or {}` in the seeding loop correctly kept the description it
      -- found. A declared name that turns out to be described is fine; the two checks above are
      -- the real invariant, and arithmetic over both sets would only re-break on the next one.
      expect(#M.BOON_UNDESCRIBED > 0).toBeTrue()
    end)
  end)

  -- The merge is fill-only, which is right for enrichment and WRONG when the game rewrites a
  -- boon: every earlier release had already merged the old text into the library, so a corrected
  -- seed reaches nobody without this. `_bonusDesc` prefers the library, so the stale number would
  -- have landed on the bonuses panel as fact.
  it("retcons a changed boon over the library, but only once", function()
    withSeed(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      M.history.boonSeedEpoch = nil
      M.history.boonLibrary["Coarse Flesh"] = { description = "STALE", rarity = "rare" }
      M.history.boonLibrary["Reaper"] = { description = "a boon that no longer exists" }
      local fixed, dropped = M._boonSeedRetcon()
      expect(fixed > 0).toBeTrue()
      expect(dropped).toBe(1)
      expect(M.history.boonLibrary["Coarse Flesh"].description)
        .toBe(M.BOON_SEED["Coarse Flesh"].description)
      expect(M.history.boonLibrary["Reaper"]).toBeNil()

      -- ONCE. A later in-game sighting is newer than the seed and must not be reverted on the
      -- next load -- an unconditional rewrite is the fill-only rule broken the other way.
      M.history.boonLibrary["Coarse Flesh"].description = "SEEN IN GAME, NEWER THAN THE SEED"
      local again = M._boonSeedRetcon()
      expect(again).toBe(0)
      expect(M.history.boonLibrary["Coarse Flesh"].description)
        .toBe("SEEN IN GAME, NEWER THAN THE SEED")
    end)
  end)

  -- THE POINT OF A MERGE: what YOU saw in-game always wins. A seed that overwrote observed
  -- data would be worse than no seed at all.
  it("never overwrites a description observed in-game", function()
    withSeed(function()
      M.history.boonLibrary = { Outlaw = { description = "MY OWN OBSERVED TEXT" } }
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      expect(M.history.boonLibrary.Outlaw.description).toBe("MY OWN OBSERVED TEXT")
      -- ...but it may FILL a field we did not have.
      expect(M.history.boonLibrary.Outlaw.rarity ~= nil).toBeTrue()
    end)
  end)

  it("is idempotent -- reloading changes nothing", function()
    withSeed(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      local added, enriched = M._boonDbMerge(M.BOON_SEED)
      expect(added).toBe(0)
      expect(enriched).toBe(0)
    end)
  end)

  -- The seed is only worth having if the parsers can read it: these are the shapes that cost
  -- five separate releases to discover one offer screen at a time.
  it("parses the shapes that took five releases to find", function()
    withSeed(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      local seed = M.BOON_SEED
      expect(#M._immunitiesFrom(seed["Careless Whisperer"].description)).toBe(3)
      expect(#M._immunitiesFrom(seed["Energetic"].description)).toBe(2)
      expect(M._immunitiesFrom(seed["Coarse Flesh"].description)[1]).toBe("slickness")
      expect(M._boonDrawbacks(seed["Corrupted Blood"].description)[1]).toBe("nausea")
      -- Coarse Flesh USED to be the grant-and-cost example ("but suffer permanent timeflux").
      -- 2026-09-01 removed the cost, so it now pins the opposite: a boon with no downside must
      -- report no downside. Left here rather than deleted because the derive-from-the-sentence
      -- design is exactly what made this a one-line change instead of a code change.
      expect(#M._boonDrawbacks(seed["Coarse Flesh"].description)).toBe(0)
      -- Meathead's cost changed stupidity -> confusion, which is not cosmetic: stupidity EATS
      -- QUEUED COMMANDS, and half this package queues.
      expect(M._boonDrawbacks(seed["Meathead"].description)[1]).toBe("confusion")
    end)
  end)
end)

-- ─── BOON CONTEMPLATE: the meta block is open-ended (v4.7.288) ───────────────
--
-- The 2026-09-01 announcement adds a boon's CATEGORY to this screen, and for an unlocked boon a
-- line naming what unlocked it. We have never seen the wording, so the parser matches the SHAPE:
-- while still in the meta block, `Label: value` is meta. The damage this prevents is not cosmetic
-- -- a polluted description reaches `_learnBoon`, which OVERWRITES, and the library outranks the
-- seed in `_bonusDesc`, so it lands on the bonuses panel as fact.

-- ─── Keeping the boon catalogue current (v4.7.295) ──────────────────────────
--
-- The catalogue cannot be rebuilt: a description is shown ONCE, on a screen that is gone a second
-- later. So the holes matter, and until now `boonFill` could only reach boons we were CURRENTLY
-- HOLDING -- which is the smaller half, since the holes are precisely the boons we have never been
-- offered (25 declared outright after the 2026-09-01 rebalance, plus four we automate and have no
-- text for at all).

describe("boon catalogue gaps", function()
  local saveSeed, saveLib, saveOwned

  local function gapsSetup()
    saveSeed, saveLib = M.BOON_SEED, M.history.boonLibrary
    saveOwned = ataxiaTemp and ataxiaTemp.boonsOwned
    M.BOON_SEED = {
      ["Described Boon"] = { description = "It does a thing." },
      ["Seed Hole"]      = {},                    -- a declared name-only entry
    }
    M.history.boonLibrary = {
      ["Library Hole"] = { rarity = "rare" },     -- learned a rarity, never the text
      ["Library Full"] = { description = "Known." },
    }
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.boonsOwned = { ["Owned Hole"] = true, ["Described Boon"] = true }
  end

  local function gapsRestore()
    M.BOON_SEED, M.history.boonLibrary = saveSeed, saveLib
    if ataxiaTemp then ataxiaTemp.boonsOwned = saveOwned end
  end

  local function has(t, v)
    for _, x in ipairs(t) do if x == v then return true end end
    return false
  end

  -- THE WIDENED POOL is the whole point: a boon we have never held is exactly the one whose text
  -- we are missing, and `BOON CONTEMPLATE <name>` answers for any name, held or not.
  it("collects holes from the seed, the library AND what we hold", function()
    gapsSetup()
    local g = M.boonGaps()
    expect(has(g, "Seed Hole")).toBeTrue()
    expect(has(g, "Library Hole")).toBeTrue()
    expect(has(g, "Owned Hole")).toBeTrue()
    gapsRestore()
  end)

  it("never reports a name we already have text for, from either source", function()
    gapsSetup()
    local g = M.boonGaps()
    expect(has(g, "Described Boon")).toBeFalse()  -- described in the seed
    expect(has(g, "Library Full")).toBeFalse()    -- described in the library
    gapsRestore()
  end)

  -- A name in two sources is one gap, not two -- otherwise the batch spends two CONTEMPLATEs on it.
  it("counts a name appearing in two sources exactly once", function()
    gapsSetup()
    M.BOON_SEED["Library Hole"] = {}
    local n = 0
    for _, x in ipairs(M.boonGaps()) do if x == "Library Hole" then n = n + 1 end end
    expect(n).toBe(1)
    gapsRestore()
  end)

  it("is sorted, so a batch is deterministic across runs", function()
    gapsSetup()
    local g = M.boonGaps()
    local sorted = true
    for i = 2, #g do if g[i] < g[i - 1] then sorted = false end end
    expect(sorted).toBeTrue()
    gapsRestore()
  end)
end)

-- THE TRICKLE. Each fill is a CONTEMPLATE and a captured block, and `_captureLines` holds ONE
-- global slot whose second caller force-finishes the first (v4.7.93) -- the race v4.7.279 had to
-- unpick when enrichment silently dropped whole offer reports. So the automatic path must never
-- take the slot from anyone.
describe("the automatic catalogue trickle", function()
  it("REFUSES while another capture holds the slot", function()
    local saveSeed = M.BOON_SEED
    M.BOON_SEED = { ["A Hole"] = {} }
    M._capturing = true
    expect(M._boonFillTrickle()).toBeFalse()
    M._capturing = false
    M.BOON_SEED = saveSeed
  end)

  it("does nothing when the catalogue has no gaps", function()
    local saveSeed, saveLib = M.BOON_SEED, M.history.boonLibrary
    local saveOwned = ataxiaTemp and ataxiaTemp.boonsOwned
    M.BOON_SEED = { ["Full"] = { description = "text" } }
    M.history.boonLibrary = {}
    if ataxiaTemp then ataxiaTemp.boonsOwned = {} end
    M._capturing = false
    expect(M._boonFillTrickle()).toBeFalse()
    M.BOON_SEED, M.history.boonLibrary = saveSeed, saveLib
    if ataxiaTemp then ataxiaTemp.boonsOwned = saveOwned end
  end)
end)

describe("contemplate meta lines", function()
  it("keeps unknown Label: value lines out of the description, and records them", function()
    local info = M._parseContemplate({
      "Category: Offensive",
      "Rarity: legendary",
      "Can echo: Yes",
      "Maximum echoes: 3",
      "Unlocked by: Iron Throat",
      "Your attacks burn with a righteous fire.",
      "",
      '"A quote."',
    })
    expect(info.description).toBe("Your attacks burn with a righteous fire.")
    expect(info.rarity).toBe("legendary")
    expect(info.num_echoes_possible).toBe(3)
    expect(info.meta["Category"]).toBe("Offensive")
    expect(info.meta["Unlocked by"]).toBe("Iron Throat")
    expect(info.quote).toBe("A quote.")
  end)

  -- The rule must not eat a description. It applies ONLY while still in the meta block, so a
  -- colon in prose is safe -- and prose is what actually follows the labels.
  it("does not treat a colon inside the description as a meta line", function()
    local info = M._parseContemplate({
      "Rarity: common",
      "Your options are simple: hit harder.",
      "And it keeps going.",
    })
    expect(info.description).toBe("Your options are simple: hit harder. And it keeps going.")
    expect(info.meta).toBeNil()
  end)

  it("still parses a screen with no new lines at all", function()
    local info = M._parseContemplate({
      "Rarity: common",
      "Can echo: No",
      "Gain 1 additional dexterity.",
    })
    expect(info.description).toBe("Gain 1 additional dexterity.")
    expect(info.num_echoes_possible).toBe(0)
    expect(info.meta).toBeNil()
  end)
end)

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

  -- THE DEATH (v4.7.318): the patrol had no lava filter at all. Once the grid was swept it
  -- round-robined every visited room INCLUDING the lava one, and a denizen left standing in it
  -- made that room the one the patrol kept returning to -- 5,890 on every entry, until dead.
  -- The TARGET check (v4.7.318) is what guards a route whose last hop the edge/path checks
  -- cannot resolve: `pathKnown` infers a REVERSE link when only the far side reported the exit,
  -- and from our side that hop has no edge and no destination id. (v4.7.319 note: the previous
  -- fixture here put two rooms south of room 1, so the second `onRoom` overwrote the edge and the
  -- old assertion passed by walking straight INTO the lava through a prose door.)
  it("never patrols INTO a lava room reached by a link only the lava room reported", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 0 }, nil)                 -- our side: no south exit known
    MAP.onRoom(3, "C", { west = 1, south = 0 }, "east")   -- walked 1 -> 3
    MAP.onRoom(1, "A", { east = 0 }, "west")              -- back in 1; grid swept
    MAP.rooms[2] = { visited = true, exits = { north = 1 }, edges = {}, x = 0, y = -1 } -- lava, reports 1 as its north
    M.explore.lavaRooms = { [2] = { at = 1 } }
    M.explore.lavaEdges = {}                              -- we never splashed from 1
    M.explore.patrolQueue = nil
    M.explore.patrolLoops = 0
    -- Sorted queue: 2 (lava) before 3. `pathKnown(1, 2)` = {"s"} via the reverse link; from 1
    -- that hop has no edge and no id, so `_pathIsLavaFree` cannot see it. Only the TARGET test can.
    local step = M._nextPatrolStep()
    expect(step).toBe("e")           -- to room 3, never "s" into the lava
    for _, num in ipairs(M.explore.patrolQueue) do expect(num ~= 2).toBeTrue() end
  end)

  it("never patrols across a known lava EDGE either", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil)
    MAP.onRoom(2, "B", { west = 1 }, "east")
    MAP.onRoom(1, "A", { east = 2 }, "west") -- standing in A
    M.explore.lavaRooms = {}
    M.explore.lavaEdges = { [1] = { east = { at = 1 } } } -- the door itself is condemned
    M.explore.patrolQueue = nil
    M.explore.patrolLoops = 0
    expect(M._nextPatrolStep()).toBeNil() -- 2 is the only target and its only route is the lava door
  end)

  -- v4.7.319, deep review, probe-confirmed LIVELOCK: a lava room with an unwalked exit of its
  -- own was a valid backtrack TARGET, refused only at the first step -- from two rooms away the
  -- sweep walked adjacent, refused, the patrol stepped away, the sweep step reset the patrol
  -- counters, forever. The lava room's own doors are not the sweep's to finish.
  it("never backtracks TOWARD a lava room, even one with an unswept door", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil)
    MAP.onRoom(2, "B", { west = 1, east = 3 }, "east")
    MAP.onRoom(3, "LAVA", { west = 2, south = 0 }, "east")  -- lava keeps an unwalked south
    MAP.onRoom(2, "B", { west = 1, east = 3 }, "west")
    MAP.onRoom(1, "A", { east = 2 }, "west")                -- standing in 1, two rooms away
    M.explore.lavaRooms = { [3] = { at = 1 } }
    M.explore.lavaEdges = { [2] = { east = { at = 1 } } }
    expect(M._nextExploreStep()).toBeNil()                 -- NOT "e" toward the lava
  end)

  -- The TARGET exclusion is what guards a lava room reached by a link only the lava room
  -- reported (`pathKnown` infers the reverse; from our side that hop has no edge and no id, so
  -- the path walk cannot see it).
  it("never backtracks toward a lava room reached by a link only the lava room reported", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 0 }, nil)
    MAP.onRoom(3, "C", { west = 1 }, "east")
    MAP.onRoom(1, "A", { east = 0 }, "west")               -- standing in 1; 1 has no known south
    MAP.rooms[2] = { visited = true, exits = { north = 1, south = 0 }, edges = {}, x = 0, y = -1 }
    M.explore.lavaRooms = { [2] = { at = 1 } }              -- lava, with an unswept south of its own
    M.explore.lavaEdges = {}
    expect(M._nextExploreStep()).toBeNil()                 -- NOT "s" toward the lava
  end)

  it("never backtracks along a route that passes THROUGH lava to a clean target", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil)
    MAP.onRoom(2, "LAVA", { west = 1, east = 3 }, "east")
    MAP.onRoom(3, "C", { west = 2, north = 0 }, "east")     -- clean room beyond the lava, unswept north
    MAP.onRoom(2, "LAVA", { west = 1, east = 3 }, "west")
    MAP.onRoom(1, "A", { east = 2 }, "west")                -- standing in 1
    M.explore.lavaRooms = { [2] = { at = 1 } }
    M.explore.lavaEdges = { [1] = { east = { at = 1 } } }
    expect(M._nextExploreStep()).toBeNil()                 -- the only route runs through 2
  end)

  -- The v4.7.256 first-step rule is not enough: here the first step is clean and the lava is
  -- the SECOND hop. The old code walked toward it, refused on arrival, and re-selected forever.
  it("never backtracks when the lava is a later hop, not the first", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil)
    MAP.onRoom(2, "B", { west = 1, east = 3 }, "east")
    MAP.onRoom(3, "LAVA", { west = 2, east = 4 }, "east")
    MAP.onRoom(4, "D", { west = 3, north = 0 }, "east")     -- unswept north beyond the lava
    MAP.onRoom(3, "LAVA", { west = 2, east = 4 }, "west")
    MAP.onRoom(2, "B", { west = 1, east = 3 }, "west")
    MAP.onRoom(1, "A", { east = 2 }, "west")                -- standing in 1
    M.explore.lavaRooms = { [3] = { at = 1 } }
    M.explore.lavaEdges = { [2] = { east = { at = 1 } } }
    expect(M._nextExploreStep()).toBeNil()                 -- first hop 1->2 is clean; 2->3 is not
  end)

  it("_pathIsLavaFree walks every resolvable hop", function()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil)
    MAP.onRoom(2, "B", { west = 1, east = 3 }, "east")
    MAP.onRoom(3, "LAVA", { west = 2 }, "east")
    MAP.onRoom(1, "A", { east = 2 }, nil)
    M.explore.lavaRooms = { [3] = { at = 1 } }
    M.explore.lavaEdges = {}
    expect(M._pathIsLavaFree(1, { "e" })).toBeTrue()       -- 1 -> 2 is clean
    expect(M._pathIsLavaFree(1, { "e", "e" })).toBeFalse() -- the second hop enters 3
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

describe("explore wears armour before sweeping (v4.7.175)", function()
  local M = ataxia.mnemosyne
  it("sends WEAR ARMOUR, and directly rather than queued", function()
    if not (M and M._wearArmour) then return end
    local seen = {}
    local realSend = send
    send = function(cmd) table.insert(seen, cmd) end
    M._wearArmour()
    send = realSend
    expect(#seen).toBe(1)
    expect(seen[1]).toBe("wear armour")
    -- Queued would be wiped by the basher's next `queue addclearfull`.
    expect(seen[1]:find("queue", 1, true)).toBe(nil)
  end)
end)

describe("boon flags re-latch once per run (v4.7.188)", function()
  local M = ataxia.mnemosyne
  -- The guard lives on ataxiaTemp, NOT on ataxia.mnemosyne: `ataxia` is serialized, and a
  -- guard restored true from disk after a reload would silently defeat the whole function
  -- (the boon flags it restores are bare globals that do NOT persist). Review finding,
  -- fixed v4.7.192 -- these tests reset the same field the code reads, so they would have
  -- kept passing against the buggy version had they used a private helper instead.
  it("sends BOONS once, then never again until the run resets", function()
    if not (M and M._relatchBoons) then return end
    local seen = {}
    local realSend = send
    send = function(cmd) table.insert(seen, cmd) end
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemBoonsRelatched = nil
    M._relatchBoons()
    M._relatchBoons()
    M._relatchBoons()
    send = realSend
    expect(#seen).toBe(1)          -- once per run, not per ripple
    -- `BOON CLAIMED`, not `BOONS` (v4.7.203). BOONS is not a command: the game answers it
    -- with its syntax help, which lists exactly BOON CLAIMED / OPTIONS / CLAIM / CONTEMPLATE.
    -- This assertion previously pinned "boons" -- it verified WHAT we send without any check
    -- that the string was a real command, so it passed happily for the entire time the
    -- feature was a no-op. Hence the second assertion below.
    expect(seen[1]).toBe("boon claimed")
  end)

  it("uses the `boon <verb>` form every other boon command uses", function()
    if not (M and M._relatchBoons) then return end
    local seen = {}
    local realSend = send
    send = function(cmd) table.insert(seen, cmd) end
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemBoonsRelatched = nil
    M._relatchBoons()
    send = realSend
    -- The package's other boon commands are `boon claim <name>` and `boon contemplate <name>`.
    -- A bare `boons` is the odd one out, and that was the tell.
    expect(seen[1]:match("^boon ") ~= nil).toBeTrue()
    expect(seen[1]).toBe("boon claimed")
  end)

  it("re-arms when a new run starts", function()
    if not (M and M._relatchBoons) then return end
    local n = 0
    local realSend = send
    send = function() n = n + 1 end
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemBoonsRelatched = nil
    M._relatchBoons()
    ataxiaTemp.mnemBoonsRelatched = nil   -- what 001_Run_Start does
    M._relatchBoons()
    send = realSend
    expect(n).toBe(2)
  end)

  it("the guard is NOT on the serialized ataxia namespace", function()
    if not (M and M._relatchBoons) then return end
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemBoonsRelatched = nil
    local realSend = send
    send = function() end
    M._relatchBoons()
    send = realSend
    expect(ataxiaTemp.mnemBoonsRelatched).toBeTrue()
    expect(M._boonsRelatched).toBe(nil)   -- would survive a reload and defeat the relatch
  end)
end)

-- ============================================================================
-- v4.7.243 -- the ice-slip recovery re-sends the RIGHT command
-- ============================================================================
--
-- Death log, caves beneath Kuthalebak: "pull move lost -- retry 1 -> n" then
-- "You slip and fall on the ice as you try to leave" then "slipped on the ice -- up and going
-- again", against a room reporting "An icewall is here, blocking passage to the north".
--
-- M.onIceSlip re-sent via M._exploreMove, which sends a BARE `stand;<dir>` walk -- discarding
-- the leap/backflip the tactical retreat was. A walk into our own icewall silently fails, and
-- MAX_ICE_SLIPS is 15. That is the thirteen seconds we spent in the room that killed us.
describe("ice-slip recovery during a tactical retreat (v4.7.243)", function()
  local M = ataxia.mnemosyne
  local realSend, realSwarm

  local function slipping(tactical)
    realSend, realSwarm = send, M.swarm
    M.explore.on = true
    M.explore.moving = true
    M.explore.fromDir = "s"
    M.explore.fromRoom = 200
    M.explore.iceSlips = 0
    M.explore.tacticalMove = tactical and true or false
  end
  local function restore() send = realSend; M.swarm = realSwarm end

  -- The explorer's wall reflex follows the saddle (v4.7.345) -- tested by BEHAVIOUR since
  -- v4.7.351: the deep review's mutation run found only a source-text search guarding it.
  it("a wall is mountjumped from the saddle, leapt on foot", function()
    local realVerb, realSent = ataxiaBasher_mountVerb, ataxiaBasher_jumpSent
    local mounted, recorded = true, nil
    ataxiaBasher_mountVerb = function(fallback) return mounted and "mountjump" or fallback end
    ataxiaBasher_jumpSent = function(dir, verb) recorded = verb end
    local out = {}
    local ok, err = pcall(function()
      slipping(false) -- ONCE: it captures the real `send`, and a second call would capture our stub
      send = function(c) out[#out + 1] = c end
      M.swarm = { moveLocked = function() return false end }
      M.onWallBlocked()
      mounted = false
      M.explore.moving, M.explore.iceSlips = true, 0
      M.onWallBlocked()
    end)
    restore()
    ataxiaBasher_mountVerb, ataxiaBasher_jumpSent = realVerb, realSent
    if not ok then error(err, 0) end
    expect((out[1] or ""):find("mountjump s", 1, true) ~= nil).toBeTrue()
    expect((out[2] or ""):find("leap s", 1, true) ~= nil).toBeTrue()
    expect(recorded).toBe("leap") -- and it recorded what it sent, for the refusal to recover
  end)

  it("hands a TACTICAL slip back to the swarm instead of walking", function()
    slipping(true)
    local walked, handed = 0, 0
    send = function() walked = walked + 1 end
    M.swarm = { moveLocked = function() return false end,
                onMoveFailed = function() handed = handed + 1 end }
    M.onIceSlip()
    expect(handed).toBe(1)   -- S.onMoveFailed re-sends `stand;<moveVerb> <dir>`
    expect(walked).toBe(0)   -- ...and NOT a bare walk
    expect(M.explore.moving).toBeFalse()
    restore()
  end)

  it("still re-sends the plain walk for an ordinary sweep step", function()
    slipping(false)
    local walked, handed = 0, 0
    send = function() walked = walked + 1 end
    M.swarm = { moveLocked = function() return false end,
                onMoveFailed = function() handed = handed + 1 end }
    M.onIceSlip()
    expect(walked).toBe(1)
    expect(handed).toBe(0)
    restore()
  end)

  -- 15 re-sends is defensible for an idle sweep and indefensible under fire: at ~2,150 HP/s
  -- each one costs roughly a second of standing in the room we are fleeing.
  --
  -- Asserted via _exploreTick, which ONLY the give-up branch calls: under the budget we hand
  -- back to the swarm and let it retry, over it we abandon the exit entirely.
  it("gives up on a tactical retreat's exit after 3 slips, not 15", function()
    slipping(true)
    local handed, ticks = 0, 0
    local realTick = M._exploreTick
    send = function() end
    M._exploreTick = function() ticks = ticks + 1 end
    M.swarm = { moveLocked = function() return false end,
                onMoveFailed = function() handed = handed + 1 end }
    for i = 1, 4 do
      M.explore.moving = true
      M.explore.tacticalMove = true
      M.onIceSlip()
      if i < 4 then expect(ticks).toBe(0) end -- still inside the budget: retry, do not abandon
    end
    expect(ticks).toBe(1)  -- the 4th slip exceeded 3 and gave up on the exit
    expect(handed).toBe(4) -- the swarm is told every time either way
    M._exploreTick = realTick
    restore()
  end)

  it("does nothing at all while a tumble is in flight", function()
    slipping(true)
    local walked, handed = 0, 0
    send = function() walked = walked + 1 end
    M.swarm = { moveLocked = function() return true end,
                onMoveFailed = function() handed = handed + 1 end }
    M.onIceSlip()
    expect(walked).toBe(0)
    expect(handed).toBe(0)
    expect(M.explore.iceSlips).toBe(0) -- not even counted against the budget
    restore()
  end)

  -- RUBBLE (v4.7.357): a slow clamber is a move in progress, not a failed one. Without the grace
  -- the 5s timeout re-sends the step (restarting the clamber) and, after MOVE_RETRIES, condemns a
  -- real exit.
  it("a clamber over rubble re-arms the move timeout instead of re-sending", function()
    local mock = require("mock_mudlet")
    local realSend2, realSwarm2 = send, M.swarm
    local sent = 0
    local ok, err = pcall(function()
      send = function() sent = sent + 1 end
      M.swarm = { moveLocked = function() return false end }
      M.explore.on = true
      M._exploreMove("s")
      expect(sent).toBe(1)
      local first = M._explMoveT
      expect(mock.active_timers[first].delay).toBe(5)
      M.onClamber()
      expect(mock.active_timers[first]).toBeNil()       -- the 5s timeout is gone...
      expect(mock.active_timers[M._explMoveT].delay).toBe(10) -- ...replaced by the grace
      expect(sent).toBe(1)                               -- and nothing was re-sent
      local second = M._explMoveT
      M.onClamber()                                      -- once per sent move
      expect(M._explMoveT).toBe(second)
    end)
    if M._explMoveT then killTimer(M._explMoveT); M._explMoveT = nil end
    M.explore.moving, M.explore.on = false, false
    send, M.swarm = realSend2, realSwarm2
    if not ok then error(err, 0) end
  end)

  -- The realistic stale state: the last move's callback is still stored, its timer already gone,
  -- and nothing in flight (a manual walk over rubble). Must not conjure a timeout from it.
  it("a clamber with no move of ours in flight does nothing", function()
    local realCb = M._explMoveOnTimeout
    M.explore.moving, M.explore.clambered, M._explMoveT = false, false, nil
    M._explMoveOnTimeout = function() end
    M.onClamber()
    local armed = M._explMoveT
    if armed then killTimer(armed); M._explMoveT = nil end
    M._explMoveOnTimeout = realCb
    expect(armed).toBeNil()
  end)

  it("a tactical move gets the same grace, and the grace still ends in the old failure path", function()
    local mock = require("mock_mudlet")
    local realSwarm2, realTick = M.swarm, M._scheduleTick
    local failed = 0
    local ok, err = pcall(function()
      M.swarm = { onMoveFailed = function() failed = failed + 1 end }
      M._scheduleTick = function() end
      M._tacticalArm("e", 3)
      expect(mock.active_timers[M._explMoveT].delay).toBe(3)
      M.onClamber()
      local id = M._explMoveT
      local t = mock.active_timers[id]
      expect(t.delay).toBe(10)
      expect(failed).toBe(0)
      t.callback()                                       -- the grace runs out, still in the room
      killTimer(id)
      expect(failed).toBe(1)
      expect(M.explore.moving).toBeFalse()
    end)
    if M._explMoveT then killTimer(M._explMoveT); M._explMoveT = nil end
    M.explore.moving, M.explore.tacticalMove = false, false
    M.swarm, M._scheduleTick = realSwarm2, realTick
    if not ok then error(err, 0) end
  end)

  it("_exploreMove refuses to move under the tumble lock", function()
    slipping(false)
    local walked = 0
    send = function() walked = walked + 1 end
    M.swarm = { moveLocked = function() return true end }
    M._exploreMove("s", true)
    expect(walked).toBe(0)
    restore()
  end)
end)

-- ============================================================================
-- v4.7.249 -- the ripple is 4x4, and that is evidence against dementia
-- ============================================================================
--
-- User, 2026-08-11: "We KNOW the exits we have available. We know it is a 4 X 4 so we should
-- know." Dementia (Creville's Legacy) hallucinates the room wholesale -- a real Achaea room
-- name, a real room number, an NPC that is not there, and invented exits, all arriving down
-- the same gmcp channel the map trusts.
describe("the 4x4 grid constrains what can be a real exit", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map

  -- A west-to-east corridor of four rooms spans the whole grid: nothing further east or
  -- west can exist, whatever the game claims.
  local function fullWidthRow()
    MAP.reset()
    MAP.onRoom(1, "A", { east = 2 }, nil)
    MAP.onRoom(2, "B", { west = 1, east = 3 }, "east")
    MAP.onRoom(3, "C", { west = 2, east = 4 }, "east")
    MAP.onRoom(4, "D", { west = 3 }, "east")
  end

  it("allows any exit while the ripple is barely mapped", function()
    MAP.reset()
    MAP.onRoom(1, "A", { north = 0, east = 0, south = 0, west = 0 }, nil)
    expect(MAP.exitFitsGrid(1, "north")).toBeTrue()
    expect(MAP.exitFitsGrid(1, "west")).toBeTrue()
  end)

  it("rejects the exit that would make the row FIVE wide", function()
    fullWidthRow()
    local minx, maxx = MAP.bounds()
    expect(maxx - minx + 1).toBe(4)          -- the row already spans the grid
    expect(MAP.exitFitsGrid(4, "east")).toBeFalse()
    expect(MAP.exitFitsGrid(1, "west")).toBeFalse()
    -- ...but the perpendicular axis is still empty, so north/south stay legal
    expect(MAP.exitFitsGrid(4, "north")).toBeTrue()
  end)

  it("never rejects a non-planar exit -- the holding room's descent is real", function()
    fullWidthRow()
    expect(MAP.exitFitsGrid(4, "down")).toBeTrue()
    expect(MAP.exitFitsGrid(4, "up")).toBeTrue()
  end)

  it("never rejects on ignorance (unplaced room, unknown room)", function()
    fullWidthRow()
    expect(MAP.exitFitsGrid(999, "east")).toBeTrue()
  end)

  -- THE ACTUAL BUG: a faked link used to drag the layout across the map, putting every room
  -- placed through it in the wrong cell. Now the lie simply fails to place.
  it("relayout keeps the layout inside the 4x4 despite a faked exit", function()
    fullWidthRow()
    -- Dementia invents a fifth room east of D, and reports it as a real destination.
    MAP.onRoom(5, "Meadows east of the Pachacacha", { west = 4 }, "east")
    MAP.rooms[4].exits.east = 5
    MAP.relayout()
    local minx, maxx, miny, maxy = MAP.bounds()
    expect(maxx - minx + 1 <= MAP.GRID).toBeTrue()
    expect(maxy - miny + 1 <= MAP.GRID).toBeTrue()
  end)

  it("the sweep will not spend a move on an impossible exit", function()
    fullWidthRow()
    M.explore.failed = {}
    -- D reports an east exit it cannot have; the only real work is elsewhere.
    MAP.rooms[4].exits.east = 0
    MAP.current = 4
    local step = M._nextExploreStep()
    expect(step).toBe(nil) -- not "e": the grid says east cannot exist
  end)

  it("still sweeps a legitimate unexplored exit on the free axis", function()
    fullWidthRow()
    M.explore.failed = {}
    MAP.rooms[4].exits.north = 0   -- perpendicular axis is empty, so this is plausible
    MAP.current = 4
    expect(M._nextExploreStep()).toBe("n")
  end)

  it("GRID is configurable rather than hardcoded in the check", function()
    fullWidthRow()
    expect(MAP.exitFitsGrid(4, "east")).toBeFalse()
    MAP.GRID = 5
    expect(MAP.exitFitsGrid(4, "east")).toBeTrue()
    MAP.GRID = 4
  end)
end)

-- ============================================================================
-- v4.7.250 -- dead reckoning, when the room ID itself is a lie
-- ============================================================================
--
-- User, 2026-08-11: "the gmcp room id will be changed every time we look because of dementia
-- that we cannot cure, so we need to track by exits and map it out like that."
describe("dead reckoning under dementia", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map

  local function demented(on)
    MAP.drForce = on and true or false
    ataxia.afflictions = ataxia.afflictions or {}
  end

  local function fresh()
    demented(true)
    MAP.reset()
    M.explore.failed = {}
    M.explore.moving = false
    M.explore.fromDir = nil
  end

  -- Drive the REAL arrival path (MAP.drArrive), not a reimplementation of it -- an earlier
  -- draft of these tests rebuilt the logic in this helper and therefore passed while the
  -- handler was broken. The explorer's move state is what drArrive reads to decide whether we
  -- moved, so set that rather than passing a direction.
  local function look(exits, movedDir)
    -- Mirror the real flow: _exploreMove ARMS the reckoning for exactly one step, and the
    -- first arrival consumes it. Without arming, drArrive must not advance -- that is the
    -- v4.7.251 contract that stops several room events inside one move from double-stepping.
    M.explore.moving = movedDir and true or false
    M.explore.fromDir = movedDir
    MAP._lastMoveDir = nil
    if movedDir then MAP.drArm(movedDir) end
    MAP.drArrive(exits)
    M.explore.moving = false
    M.explore.fromDir = nil
  end

  it("is off when dementia is not up", function()
    demented(false)
    expect(MAP.drActive()).toBeFalse()
    MAP.drForce = nil
  end)

  -- THE CORE FAILURE: three looks at the SAME room used to mint three rooms.
  it("three looks at one room stay ONE room", function()
    fresh()
    look({ north = 111 })
    look({ north = 222 })   -- dementia renumbers everything...
    look({ north = 333 })   -- ...and renumbers it again
    local n = 0
    for _ in pairs(MAP.rooms) do n = n + 1 end
    expect(n).toBe(1)
    expect(MAP.current).toBe("dr:0,0")
  end)

  it("keys rooms by where WE are, not by what the server calls it", function()
    fresh()
    look({ north = 0 })
    look({ south = 0 }, "north")
    expect(MAP.current).toBe("dr:0,1")
    look({ north = 0 }, "south")
    expect(MAP.current).toBe("dr:0,0")   -- back where we started, same key
    local n = 0
    for _ in pairs(MAP.rooms) do n = n + 1 end
    expect(n).toBe(2)                    -- two real cells, not four phantoms
  end)

  -- "track by exits": the DIRECTION set is the fingerprint, the destination id is noise.
  it("keeps exit directions but discards the faked destinations", function()
    fresh()
    look({ north = 987654, west = 123456 })
    local r = MAP.rooms["dr:0,0"]
    expect(r.exits.north).toBe(0)
    expect(r.exits.west).toBe(0)
  end)

  -- Without the walked edge, every exit reads unexplored forever and backtracking is impossible.
  it("records the walked edge so the sweep can backtrack", function()
    fresh()
    look({ north = 0, south = 0 })
    look({ south = 0 }, "north")
    expect(MAP.rooms["dr:0,0"].edges.north).toBe("dr:0,1")
    expect(MAP.rooms["dr:0,1"].edges.south).toBe("dr:0,0")
  end)

  it("coordinates come straight from the key -- no BFS to mislead", function()
    fresh()
    look({ north = 0 })
    look({ south = 0, east = 0 }, "north")
    look({ west = 0 }, "east")
    MAP.relayout()
    expect(MAP.rooms["dr:1,1"].x).toBe(1)
    expect(MAP.rooms["dr:1,1"].y).toBe(1)
    expect(MAP.rooms["dr:0,0"].x).toBe(0)
  end)

  it("the sweep still finds unexplored exits on synthetic keys", function()
    fresh()
    look({ north = 0, east = 0 })
    MAP.relayout()
    local step = M._nextExploreStep()
    expect(step ~= nil).toBeTrue()
  end)

  -- The 4x4 bound from v4.7.249 still applies, now over dead-reckoned coordinates.
  it("still refuses to leave the 4x4", function()
    fresh()
    look({ east = 0 })
    look({ west = 0, east = 0 }, "east")
    look({ west = 0, east = 0 }, "east")
    look({ west = 0, east = 0 }, "east")
    MAP.relayout()
    expect(MAP.exitFitsGrid("dr:3,0", "east")).toBeFalse()
  end)

  it("a new ripple restarts the reckoning at its own origin", function()
    fresh()
    look({ east = 0 })
    look({ west = 0 }, "east")
    expect(MAP.dr.x).toBe(1)
    MAP.reset()
    expect(MAP.dr.x).toBe(0)
    expect(MAP.dr.y).toBe(0)
  end)

  -- THE LIVE LOOP: under dementia several room events land inside one move's window. Each
  -- used to advance the reckoning again, so the map believed we were rooms away from where we
  -- actually stood -- and the explorer, seeing every event as an arrival, issued another move.
  -- The log shows "room clear -> moving e" eight times in five seconds.
  it("advances ONCE per move, however many room events arrive", function()
    fresh()
    look({ east = 0 })
    M.explore.moving = true
    M.explore.fromDir = "east"
    MAP.drArm("east")
    MAP.drArrive({ west = 0 })   -- the real arrival
    MAP.drArrive({ west = 0 })   -- a second event inside the same window
    MAP.drArrive({ west = 0 })   -- and a third
    expect(MAP.dr.x).toBe(1)     -- one step east, not three
    M.explore.moving = false
    M.explore.fromDir = nil
  end)

  it("a failure disarms, so nothing is credited", function()
    fresh()
    look({ east = 0 })
    MAP.drArm("east")
    MAP.drDisarm()
    MAP.drArrive({ east = 0 })
    expect(MAP.dr.x).toBe(0)
  end)

  -- "if needed the auto mapper should do a QL to see room exits" (user). The prose exits line
  -- carries DIRECTIONS only -- exactly the half that survives dementia, since gmcp's table
  -- carries invented destinations keyed to invented room ids.
  it("parses the prose exits line", function()
    local e = MAP.parseExitsLine("You see exits leading northeast, southeast, and south.")
    expect(e ~= nil).toBeTrue()
    expect(e.northeast).toBeTrue()
    expect(e.southeast).toBeTrue()
    expect(e.south).toBeTrue()
    expect(e.north).toBe(nil)
  end)

  it("parses the two-exit form", function()
    local e = MAP.parseExitsLine("You see exits leading north and west.")
    expect(e.north).toBeTrue()
    expect(e.west).toBeTrue()
  end)

  it("ignores anything that is not that line", function()
    expect(MAP.parseExitsLine("You have no idea where you are.")).toBe(nil)
    expect(MAP.parseExitsLine(nil)).toBe(nil)
  end)

  it("records the parsed exits against the dead-reckoned cell", function()
    fresh()
    look({})
    expect(MAP.onExitsLine("You see exits leading north and west.")).toBeTrue()
    local r = MAP.rooms[MAP.drHereKey()]
    expect(r.exits.north).toBe(0)
    expect(r.exits.west).toBe(0)
  end)

  -- A direction that has stopped being reported is a direction the room does not have.
  -- Merging would leave the sweep walking into a wall it was already told about.
  it("REPLACES the exit set rather than merging", function()
    fresh()
    look({ north = 0, east = 0, south = 0 })
    MAP.onExitsLine("You see exits leading north and west.")
    local r = MAP.rooms[MAP.drHereKey()]
    expect(r.exits.east).toBe(nil)
    expect(r.exits.south).toBe(nil)
    expect(r.exits.west).toBe(0)
  end)

  -- v4.7.260 reversed this. It WAS inert outside dementia, on the reasoning that gmcp's table
  -- is richer -- true, but it assumed gmcp has the exits at all, and in the tower it may not.
  -- Outside dead reckoning the text now BACKFILLS: it adds directions gmcp did not give and
  -- never overwrites a real destination id, which relayout needs for coordinates.
  it("BACKFILLS with honest room ids rather than being inert", function()
    MAP.drForce = false
    MAP.reset()
    MAP.onRoom(80, "a room", { north = 81 }, nil)   -- gmcp knows north, with a real dest
    expect(MAP.onExitsLine("You see exits leading north and west.")).toBeTrue()
    local r = MAP.rooms[80]
    expect(r.exits.north).toBe(81)                  -- the real id survives
    expect(r.exits.west).toBe(0)                    -- the missing one is added
    MAP.drForce = true
  end)

  -- The room that stopped the sweep dead had exactly ONE exit, and the singular wording is
  -- what the game prints for it.
  it("parses the single-exit wording", function()
    local e = MAP.parseExitsLine("You see a single exit leading northeast.")
    expect(e ~= nil).toBeTrue()
    expect(e.northeast).toBeTrue()
  end)

  it("records a single-exit room outside dementia -- the live failure", function()
    MAP.drForce = false
    MAP.reset()
    MAP.onRoom(90, "A place of death.", {}, nil)     -- gmcp gave NOTHING
    expect(MAP.onExitsLine("You see a single exit leading northeast.")).toBeTrue()
    expect(MAP.rooms[90].exits.northeast).toBe(0)
    MAP.drForce = true
  end)

  it("a non-planar step does not move us on the grid", function()
    fresh()
    look({ down = 0 })
    MAP.drMoved("down")
    expect(MAP.dr.x).toBe(0)
    expect(MAP.dr.y).toBe(0)
  end)

  MAP.drForce = nil -- restore for anything after us
end)

-- ============================================================================
-- v4.7.254 -- boiling lava: leave by any door
-- ============================================================================
--
-- User: "We need to move rooms if the room is lava." 5,890 UNBLOCKABLE per tick against the
-- 10,939 HP in that prompt -- 54% of the pool, two ticks is a death.
describe("boiling lava", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map
  local sentCmds, realSend

  local function room(exits, fromDir)
    -- Earlier scenarios in this file nil ataxiaBasher out; the explorer gates everything on it.
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    MAP.drForce = false
    MAP.reset()
    if fromDir then
      -- SIMULATE THE REAL ARRIVAL (v4.7.297), not just `explore.fromDir` in isolation. A real
      -- sweep step records the walked edge BOTH ways (MAP.onRoom), so the door we just came
      -- through shows up as EXPLORED to `MAP.unexploredExits` -- the fact `_lavaExit` now needs
      -- to tell "the room we just left" apart from genuinely new territory. Without this, room
      -- 50 has no recorded edges at all and every one of its exits reads as unexplored, which is
      -- not what a mid-sweep lava splash actually looks like.
      MAP.onRoom(1, "the previous room", {}, nil)
      MAP.onRoom(50, "In the depths of a murky lake.", exits, fromDir)
    else
      MAP.onRoom(50, "In the depths of a murky lake.", exits, nil)
    end
    M.explore.on = true
    M.explore.fromDir = fromDir
    M.explore.fromRoom = nil   -- stale values here would mark an edge out of the wrong room
    M.explore.lavaRooms = {}
    M.explore.lavaEdges = {}
    M.explore.failed = {}
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemLavaAt = nil
    ataxiaTemp.mnemLavaQlAt = nil
    -- v4.7.262: a lava EPISODE is now stateful (anchor + stray count), and MAP publishes the
    -- resolved arrival. Leaving any of them set leaks one scenario's geography into the next --
    -- which is exactly the class of bug this block exists to catch.
    ataxiaTemp.mnemLavaRoom, ataxiaTemp.mnemLavaStray = nil, nil
    ataxiaTemp.mnemLavaDir = nil
    MAP._lastArrival = nil
    realSend = send
    sentCmds = {}
    send = function(c) table.insert(sentCmds, c) end
  end
  local function restore() send = realSend; MAP.drForce = nil end
  local function moved()
    for _, c in ipairs(sentCmds) do
      if c:find("stand", 1, true) and not c:find("ql", 1, true) then return c end
    end
  end

  it("leaves immediately, toward the room not yet explored", function()
    -- We walked EAST to get here, so WEST is the room we just left; NORTHWEST is unswept.
    -- User-directed (2026-09-03, live log): a forced lava move should buy sweep progress, not
    -- walk us back into a room already cleared -- "w" would be provably safe but is a wasted
    -- step, where "nw" both escapes the lava and advances the sweep.
    room({ west = 0, northwest = 0 }, "e")
    M.onLava()
    local cmd = moved()
    expect(cmd ~= nil).toBeTrue()
    expect(cmd:match("stand;(%a+)$")).toBe("nw")
    restore()
  end)

  -- The escape ladder refuses unvalidated exits by user decision. Lava is the exception:
  -- staying costs half the pool per tick, so any door beats the floor.
  it("takes ANY exit when there is no way back", function()
    room({ east = 0, northwest = 0 }, nil)
    M.onLava()
    expect(moved() ~= nil).toBeTrue()
    restore()
  end)

  it("marks the room so the sweep never routes back in", function()
    room({ east = 0 }, nil)
    M.onLava()
    expect(M.explore.lavaRooms[50] ~= nil).toBeTrue() -- v4.7.262: a record, not a bare true
    restore()
  end)

  it("prefers an exit that does not lead into another lava room", function()
    room({ east = 60, northwest = 61 }, nil)
    MAP.onRoom(60, "burned", {}, nil)
    MAP.current = 50
    M.explore.lavaRooms[60] = true          -- east is known lava
    M.onLava()
    local cmd = moved()
    expect(cmd ~= nil).toBeTrue()
    expect(cmd:find("nw", 1, true) ~= nil).toBeTrue()
    restore()
  end)

  -- The one case the sweep cannot save us from: say so rather than fail silently.
  it("asks for a look and warns when no exit is known", function()
    room({}, nil)
    M.onLava()
    expect(moved()).toBe(nil)
    local asked = false
    for _, c in ipairs(sentCmds) do if c == "ql" then asked = true end end
    expect(asked).toBeTrue()
    restore()
  end)

  it("re-sends on every tick -- an eaten move must be retried", function()
    room({ east = 0 }, nil)
    M.onLava()
    local first = #sentCmds
    M.onLava()
    expect(#sentCmds > first).toBeTrue()
    restore()
  end)

  it("roomLava reports while it is eating us, and expires after we leave", function()
    room({ east = 0 }, nil)
    M.onLava()
    expect(M.roomLava()).toBeTrue()
    ataxiaTemp.mnemLavaAt = getEpoch() - 60
    expect(M.roomLava()).toBeFalse()
    restore()
  end)

  it("is inert outside the tower", function()
    room({ east = 0 }, nil)
    ataxiaBasher.inMnemosyne = false
    M.onLava()
    expect(moved()).toBe(nil)
    ataxiaBasher.inMnemosyne = true
    restore()
  end)

  -- Directly on `_lavaExit`, mirroring the integration test above: unexplored outranks the
  -- room we just left.
  it("ranks the unexplored exit above the room we just left", function()
    room({ west = 0, northwest = 0 }, "e")
    expect(M._lavaExit()).toBe("nw")
    M.explore.fromDir = nil -- clearing the explorer's OWN bookkeeping changes nothing here --
    expect(M._lavaExit()).toBe("nw") -- the map already recorded "w" as walked, not this field
    restore()
  end)

  -- THE DEATH (v4.7.318). Enter a well-trodden lava room -- dozens of corpses, every door
  -- already walked -- with a denizen in it. Nothing is unexplored, so the old chooser fell to
  -- "back", the way we came. The entry damage was already paid; retreating bought nothing and
  -- guaranteed paying it again, because the denizen drew the patrol straight back in. Forward
  -- passes through ONCE. From the log: exits north (back) and east (walked, forward) -> east.
  it("ranks a WALKED forward door above the room we just left", function()
    room({ north = 0, east = 0 }, "s") -- came in from the north; both doors already walked
    MAP.rooms[50].edges.east = 99      -- east was walked on an earlier pass -- NOT unexplored
    expect(M._lavaExit()).toBe("e")    -- not "n"
    restore()
  end)

  -- Deep review (v4.7.318): a prose-sourced exit stores destination 0, so `_exitTarget` cannot
  -- resolve it and the room test is blind -- but `lavaEdges[cur][d]` remembers the door we once
  -- splashed through from HERE. Two adjacent lava rooms is exactly this.
  it("refuses a forward door that is a known lava EDGE even with no destination id", function()
    room({ north = 0, east = 0 }, "s")
    MAP.rooms[50].edges.east = 99
    M.explore.lavaEdges[50] = { east = { at = 1 } } -- we splashed east from here once
    expect(M._lavaExit()).toBe("n")    -- back, not into the lava we remember
    restore()
  end)

  -- Mutation review: the earlier fixture's forward door sorted AFTER back, so the exclusion
  -- was never what made it pass. Here back (east) sorts BEFORE forward (north).
  it("excludes the way we came even when it sorts first", function()
    room({ east = 0, north = 0 }, "w") -- came in from the west: back = east
    MAP.rooms[50].edges.north = 99
    expect(M._lavaExit()).toBe("n")    -- not "e"
    restore()
  end)

  -- When every door is lava, the fallback still returns SOMETHING (a door beats the floor);
  -- the order is: first sorted planar door that is not lava, else the first sorted planar door.
  it("the fallback pass picks the first non-lava door before any lava door", function()
    room({ east = 77, north = 0 }, nil)
    MAP.rooms[50].edges.east, MAP.rooms[50].edges.north = 77, 88
    M.explore.lavaRooms[77] = { at = 1 }        -- east leads into known lava
    M.explore.lavaEdges[50] = { north = { at = 1 } } -- north is a known lava edge
    -- both forward doors are lava; no inbound -> back is nil; fallback tie-break = first sorted
    expect(M._lavaExit()).toBe("e")
    restore()
  end)

  it("still refuses a forward door that leads into KNOWN lava", function()
    room({ north = 0, east = 77 }, "s")
    MAP.rooms[50].edges.east = 77
    M.explore.lavaRooms[77] = { at = 1 } -- east is lava too
    expect(M._lavaExit()).toBe("n")    -- back is the only door that is not lava
    restore()
  end)

  -- The room we just left is still the fallback once there is nothing left to explore --
  -- exactly the old "back the way we came" guarantee, just ranked below progress instead of
  -- above it.
  it("falls back to the previous room once nothing is unexplored", function()
    room({ west = 0 }, "e") -- west is the only exit, and it is the room we just left
    expect(M._lavaExit()).toBe("w")
    restore()
  end)

  -- SORTED, not pairs order, still applies to the unexplored pass -- reaching the same
  -- conclusion regardless of table iteration order.
  it("the unexplored pass is sorted, not pairs-order roulette", function()
    room({ west = 0, northwest = 0, south = 0 }, "e") -- west is back; nw and south are new
    local first = M._lavaExit()
    for _ = 1, 10 do expect(M._lavaExit()).toBe(first) end
    expect(first).toBe("nw") -- alphabetically first of the two unexplored options
    restore()
  end)

  it("picks the same door every time -- no pairs-order roulette", function()
    room({ west = 0, northwest = 0, south = 0 }, nil)
    local first = M._lavaExit()
    for _ = 1, 10 do expect(M._lavaExit()).toBe(first) end
    restore()
  end)

  -- Re-entering a room that has boiled us is never worth exploration credit.
  it("the sweep will not route back into a lava room", function()
    -- Do NOT visit room 60: arriving there would record the walked edge and the exit would
    -- stop counting as unexplored, so the test would pass for the wrong reason.
    room({ east = 60 }, nil)
    M.explore.failed = {}
    expect(M._nextExploreStep()).toBe("e")   -- normally worth exploring
    M.explore.lavaRooms[60] = true
    expect(M._nextExploreStep()).toBe(nil)   -- ...but not once it has boiled us
    restore()
  end)
end)

-- ============================================================================
-- v4.7.278 -- what the WADE STATUS block was still throwing away
-- ============================================================================
--
-- From reviewing MediaRes' standalone Mnemosyne tracker: it reads `Wave progress` and
-- `Remaining lives` out of the same block we already parse for affixes, and confirms boon
-- claims on `A fulgent eddy falls still.` We had none of the three.
describe("wade status: lives and wave progress", function()
  local M = ataxia.mnemosyne

  it("records both numbers off the status block", function()
    M.run = M.run or {}
    M.run.lives, M.run.waveProgress = nil, nil
    M.onLivesLeft("3")
    M.onWaveProgress("75")
    expect(M.run.lives).toBe(3)
    expect(M.run.waveProgress).toBe(75)
  end)

  it("ignores a non-numeric reading rather than blanking what it knows", function()
    M.run.lives = 2
    M.onLivesLeft("many")
    expect(M.run.lives).toBe(2)
  end)

  -- THE DISTINCTION THAT MATTERS: an affix is re-read from every ripple's status block, so it
  -- is cleared per ripple. A life spent is spent for the whole dive.
  it("keeps lives across a ripple change", function()
    M.run.lives = 2
    M.run.active = true
    M.onRipple(7)
    expect(M.run.lives).toBe(2)
  end)

  it("clears lives on a RUN boundary", function()
    M.run.lives, M.run.waveProgress = 2, 50
    M._resetRun()
    expect(M.run.lives).toBe(nil)
    expect(M.run.waveProgress).toBe(nil)
  end)
end)

-- `A fulgent eddy falls still.` -- our boon flags latch at SEND time, so a REFUSED claim arms
-- automation for a boon we do not hold. The confirmation is the game's own proof.
describe("boon claim verification", function()
  local M = ataxia.mnemosyne

  local function armed(name)
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemClaimPending, ataxiaTemp.mnemClaimConfirms = nil, nil
    M._armClaimVerify(name)
  end

  it("arms on the claim and clears on the confirmation", function()
    armed("Warmarch")
    expect(ataxiaTemp.mnemClaimPending ~= nil).toBeTrue()
    M.onBoonClaimConfirmed()
    expect(ataxiaTemp.mnemClaimPending).toBe(nil)
    expect(ataxiaTemp.mnemClaimConfirms).toBe(1)
  end)

  it("does not warn while the claim is still fresh", function()
    armed("Warmarch")
    ataxiaTemp.mnemClaimConfirms = 1 -- the line is known to fire for us
    expect(M.checkClaimVerify()).toBe(nil)
    expect(ataxiaTemp.mnemClaimPending ~= nil).toBeTrue() -- still pending, not consumed
  end)

  it("warns once the window passes -- the claim may never have landed", function()
    armed("Warmarch")
    ataxiaTemp.mnemClaimConfirms = 1
    ataxiaTemp.mnemClaimPending.at = (getEpoch() - 30)
    expect(M.checkClaimVerify()).toBe("Warmarch")
    expect(ataxiaTemp.mnemClaimPending).toBe(nil) -- consumed: warn once, not every ripple
  end)

  -- THE GUARD THAT KEEPS IT HONEST. This wording is second-hand -- adopted from another
  -- player's script, never seen in our own logs. Until we have seen it fire at least once we
  -- cannot tell "the claim failed" from "the game does not print that line to us", and warning
  -- on the latter after every claim trains the user to ignore the warning.
  it("stays quiet if that line has NEVER been seen", function()
    armed("Warmarch")
    ataxiaTemp.mnemClaimConfirms = nil
    ataxiaTemp.mnemClaimPending.at = (getEpoch() - 30)
    expect(M.checkClaimVerify()).toBe(nil)
  end)

  -- A confirmation with nothing pending is normal: the user can claim from the game's own
  -- menu without going through our alias.
  it("tolerates a confirmation we never armed", function()
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemClaimPending, ataxiaTemp.mnemClaimConfirms = nil, nil
    M.onBoonClaimConfirmed()
    expect(ataxiaTemp.mnemClaimConfirms).toBe(1)
  end)
end)

-- ============================================================================
-- v4.7.285 -- FURY ON at every wade entry
-- ============================================================================
--
-- User: "When runewarden and have this boon, every time we enter the wade (go down into the
-- main rooms) we should ensure we do FURY ON." Fury of Ages makes FURY worth holding almost
-- permanently, and the boon screen is a gap in which it can lapse -- exactly like the armour
-- and the Bard's performance this check sits beside.
describe("wade entry: fury", function()
  local M = ataxia.mnemosyne
  local sent, realSend, realIsClass

  local function setup(class, boon)
    infFuryOfAges = boon and true or false
    gmcp = gmcp or {}; gmcp.Char = gmcp.Char or {}
    gmcp.Char.Status = { class = class }
    -- This suite does not load the class helpers, so the real ataxia_isClass is absent and the
    -- gate would return early on every case -- including the ones that must SEND. Stubbed to the
    -- part of its behaviour these tests exercise (exact class match off gmcp), and restored
    -- afterwards: files share one Lua state, and a leaked global here rewrites what a later
    -- suite measures.
    realIsClass = ataxia_isClass
    ataxia_isClass = function(what)
      local c = gmcp and gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class
      return type(c) == "string" and c:lower() == tostring(what):lower()
    end
    sent = {}
    realSend = send
    send = function(c) table.insert(sent, c) end
  end
  local function restore()
    send = realSend
    ataxia_isClass = realIsClass
    infFuryOfAges = false
  end
  local function sentFury()
    for _, c in ipairs(sent) do if c == "fury on" then return true end end
    return false
  end

  it("sends fury on for a Runewarden holding the boon", function()
    setup("Runewarden", true)
    M._furyCheck()
    expect(sentFury()).toBeTrue()
    restore()
  end)

  it("covers the Infernal too -- same boon, same ability", function()
    setup("Infernal", true)
    M._furyCheck()
    expect(sentFury()).toBeTrue()
    restore()
  end)

  it("does nothing without the boon", function()
    setup("Runewarden", false)
    M._furyCheck()
    expect(sentFury()).toBeFalse()
    restore()
  end)

  -- Listed explicitly rather than via ataxia_isClass("knight"), which is true for all three
  -- knights -- a Paladin has an eagle and no fury, and ordering one would be a rejected command.
  it("does nothing for a class without fury", function()
    setup("Paladin", true)
    M._furyCheck()
    expect(sentFury()).toBeFalse()
    restore()
  end)

  -- THE REFUSAL IS AN ANSWER, so the check does not gate on our own flag: gating on
  -- ataxiaTemp.infFuryOn would make the verification believe itself. If fury is already up the
  -- game says so, and trigger 056 reads that as confirmation.
  -- THE TESTS ABOVE CANNOT CATCH AN UNWIRED CHECK, because every one calls M._furyCheck()
  -- directly and none crosses the seam where the call lives -- deleting the call from
  -- _exploreResume passed all of them. Same gap as v4.7.279's offer timing, and the same
  -- answer: read the source and pin the wiring. There are TWO per-wade entry points and the
  -- user asked for EVERY descent, so both are required.
  it("is wired into BOTH wade entry points, beside the armour", function()
    local f = io.open("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/008_Explorer.lua")
    expect(f ~= nil).toBeTrue()
    local src = f:read("*a"); f:close()

    -- `_wearArmour` is the established per-ripple entry idiom: exploreOn (first sweep) and
    -- _exploreResume (after every boon screen). Fury must ride with it at both.
    local paired, from = 0, 1
    while true do
      local i = src:find("M._wearArmour()", from, true)
      if not i then break end
      -- within the next few lines of that call site
      local window = src:sub(i, i + 260)
      if window:find("M._furyCheck()", 1, true) then paired = paired + 1 end
      from = i + 1
    end
    expect(paired).toBe(2)
  end)

  it("still asks when we already believe fury is up", function()
    setup("Runewarden", true)
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.infFuryOn = true
    M._furyCheck()
    expect(sentFury()).toBeTrue()
    ataxiaTemp.infFuryOn = nil
    restore()
  end)
end)

-- ============================================================================
-- v4.7.255 -- a boss that runs away
-- ============================================================================
--
-- User: "When fighting this boss, we need to follow him out and continue attacking."
--   Lyaeus, the travelling bard flails in panic.
--   ... a satyri bard strolls out to the southeast, ...
-- The two lines name him DIFFERENTLY -- proper name on the panic, generic description on the
-- departure -- so the panic latches identity and the departure supplies direction.
describe("following a fleeing boss", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map
  local sentCmds, realSend

  local function fighting(bossName)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne, ataxiaBasher.enabled = true, true
    MAP.drForce = false
    MAP.reset()
    MAP.onRoom(70, "boss room", { southeast = 0 }, nil)
    M.explore.on = true
    M.run = M.run or {}
    M.run.boss = bossName
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.bossChases, ataxiaTemp.bossPanicAt, ataxiaTemp.escapeMode = nil, nil, nil
    ataxiaTemp.mnemLavaAt = nil
    ataxia.vitals = ataxia.vitals or {}
    ataxia.vitals.hpp = 90
    if M.swarm then M.swarm.state = "idle" end
    realSend = send; sentCmds = {}
    send = function(c) table.insert(sentCmds, c) end
  end
  local function restore() send = realSend; MAP.drForce = nil end
  local function followed()
    for _, c in ipairs(sentCmds) do if c:find("stand", 1, true) then return c end end
  end

  it("follows the boss out", function()
    fighting("Lyaeus, the travelling bard")
    M.onDenizenPanic("Lyaeus, the travelling bard")
    M.onDenizenFled("southeast")
    local cmd = followed()
    expect(cmd ~= nil).toBeTrue()
    expect(cmd:find("se", 1, true) ~= nil).toBeTrue()
    restore()
  end)

  -- The departure line alone could be any wandering denizen.
  it("does not chase a departure with no panic behind it", function()
    fighting("Lyaeus, the travelling bard")
    M.onDenizenFled("southeast")
    expect(followed()).toBe(nil)
    restore()
  end)

  it("ignores a panic from something that is not the boss", function()
    fighting("Lyaeus, the travelling bard")
    M.onDenizenPanic("a mindless thrall")
    M.onDenizenFled("southeast")
    expect(followed()).toBe(nil)
    restore()
  end)

  it("matches loosely -- the Objective and the room rarely word it identically", function()
    fighting("Lyaeus")
    M.onDenizenPanic("Lyaeus, the travelling bard")
    expect(M._isBossName("Lyaeus, the travelling bard")).toBeTrue()
    M.onDenizenFled("southeast")
    expect(followed() ~= nil).toBeTrue()
    restore()
  end)

  -- Adding a pursuit to a retreat is how a retreat becomes a death.
  it("never chases while escaping", function()
    fighting("Lyaeus")
    M.onDenizenPanic("Lyaeus")
    ataxiaTemp.escapeMode = true
    expect(M._chaseRefusal("southeast")).toBe("escaping")
    M.onDenizenFled("southeast")
    expect(followed()).toBe(nil)
    restore()
  end)

  it("never chases while too hurt", function()
    fighting("Lyaeus")
    M.onDenizenPanic("Lyaeus")
    ataxia.vitals.hpp = 10
    expect(M._chaseRefusal("southeast")).toBe("too hurt to chase")
    restore()
  end)

  it("never chases out of lava", function()
    fighting("Lyaeus")
    M.onDenizenPanic("Lyaeus")
    ataxiaTemp.mnemLavaAt = getEpoch()
    expect(M._chaseRefusal("southeast")).toBe("lava")
    ataxiaTemp.mnemLavaAt = nil
    restore()
  end)

  -- A boss kiting us across the grid is its own hazard.
  it("spends a bounded chase budget", function()
    fighting("Lyaeus")
    local n = 0
    for _ = 1, 10 do
      M.onDenizenPanic("Lyaeus")
      M.onDenizenFled("southeast")
    end
    for _, c in ipairs(sentCmds) do if c:find("stand", 1, true) then n = n + 1 end end
    expect(n).toBe(4)
    expect(M._chaseRefusal("southeast")).toBe("chase budget spent")
    restore()
  end)

  it("one departure per panic -- the latch is consumed", function()
    fighting("Lyaeus")
    M.onDenizenPanic("Lyaeus")
    M.onDenizenFled("southeast")
    sentCmds = {}
    M.onDenizenFled("southeast")   -- a second departure, no new panic
    expect(followed()).toBe(nil)
    restore()
  end)

  it("is inert with the basher off", function()
    fighting("Lyaeus")
    M.onDenizenPanic("Lyaeus")
    ataxiaBasher.enabled = false
    expect(M._chaseRefusal("southeast")).toBe("basher off")
    ataxiaBasher.enabled = true
    restore()
  end)

  -- -------------------------------------------------------------------------
  -- The SECOND departure grammar (v4.7.272)
  -- -------------------------------------------------------------------------
  --
  --   Celepharn, High Priest of Life flails in panic.
  --   The muted rustling of fabric accompanies Celepharn as he departs east.
  --
  -- v4.7.255 assumed "out to the <direction>" was the fragment every denizen shares. It is not --
  -- this boss uses a different frame, so the panic latched, the departure never matched, and the
  -- chase written for exactly this situation never ran.
  local DEPARTS = "The muted rustling of fabric accompanies Celepharn as he departs east."
  local OUT_TO  = "...a satyri bard strolls out to the southeast, the music fading in his wake."
  -- The trigger's own pattern, kept here so the two grammars are pinned rather than assumed.
  local FLED_PAT = "%f[%a]out to the%s+(%a+)%f[%A]"
  local function parseFled(text)
    local d = text:match(FLED_PAT)
    if not d then d = text:match("departs?%s+to the%s+(%a+)%f[%A]") end
    if not d then d = text:match("departs?%s+(%a+)%f[%A]") end
    local DIRS = { north = 1, northeast = 1, east = 1, southeast = 1, south = 1,
                   southwest = 1, west = 1, northwest = 1, up = 1, down = 1 }
    return (d and DIRS[d:lower()]) and d:lower() or nil
  end

  it("reads the direction out of BOTH departure grammars", function()
    expect(parseFled(OUT_TO)).toBe("southeast")
    expect(parseFled(DEPARTS)).toBe("east")
    -- and still refuses arbitrary prose, because the DIRECTIONS are what is enumerated
    expect(parseFled("He departs quietly, muttering.")).toBe(nil)
  end)

  -- THE TEST ABOVE CANNOT CATCH A REVERT, because it re-implements the grammar in Lua patterns
  -- rather than using the trigger's perl regex -- the "a guard inside a trigger is a guard the
  -- suite cannot see" trap that already cost this codebase a live bug (v4.7.260). Lua cannot
  -- execute a perl regex, so the next best thing is to read the trigger and assert its pattern
  -- still carries both frames. It would fail the moment someone narrows it back.
  it("the trigger itself still carries both frames and enumerates directions", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/066_Boss_Fled.lua")
    expect(f ~= nil).toBeTrue()
    local src = f:read("*a"); f:close()
    local pat = src:match("%- pattern: ([^\n]+)")
    expect(pat ~= nil).toBeTrue()
    expect(pat:find("out to the", 1, true) ~= nil).toBeTrue()   -- Lyaeus
    expect(pat:find("departs?", 1, true) ~= nil).toBeTrue()     -- Celepharn
    -- The directions must stay enumerated: a bare capture would match arbitrary prose, which is
    -- the whole reason the VERBS are not enumerated instead.
    expect(pat:find("northeast", 1, true) ~= nil).toBeTrue()
    expect(pat:find("southwest", 1, true) ~= nil).toBeTrue()
  end)

  it("follows a boss that DEPARTS rather than strolling out to", function()
    fighting("Celepharn, High Priest of Life")
    M.onDenizenPanic("Celepharn, High Priest of Life")
    MAP.onRoom(70, "boss room", { east = 0 }, nil)
    M.onDenizenFled("east", DEPARTS)
    local cmd = followed()
    expect(cmd ~= nil).toBeTrue()
    expect(cmd:find("e", 1, true) ~= nil).toBeTrue()
    restore()
  end)

  -- The line names him, so identity is PROVEN rather than inferred from the 6s window.
  it("recognises the boss's own name in the departure line", function()
    fighting("Celepharn, High Priest of Life")
    M.onDenizenPanic("Celepharn, High Priest of Life")
    expect(M._fledLineNames(DEPARTS)).toBeTrue()
    restore()
  end)

  -- ...and the absence of a name must NEVER veto: Lyaeus's departure calls him "a satyri bard",
  -- so a nameless line is the ORIGINAL case and still has to be followed.
  it("still follows a departure line that names nobody", function()
    fighting("Lyaeus, the travelling bard")
    M.onDenizenPanic("Lyaeus, the travelling bard")
    expect(M._fledLineNames(OUT_TO)).toBeFalse()
    M.onDenizenFled("southeast", OUT_TO)
    expect(followed() ~= nil).toBeTrue()
    restore()
  end)
end)

-- ============================================================================
-- v4.7.256 -- never walk back into the lava
-- ============================================================================
--
-- Death log, 08:36. v4.7.254 marked the lava room but nothing stopped us RE-ENTERING it:
--   moving n -> splash 6874 -> flee s -> "room clear -> moving n" -> splash 6874
--   -> flee s -> moving n -> splash 6874 -> "LOW HP (20%) retreating -> n" -> splash -> DEAD.
-- Three separate paths led back in, and none consulted the lava memory.
describe("never walking back into lava", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map

  -- The grid from the log: a stone tunnel (100) with the lava corridor (200) to its north,
  -- and the corridor has an unexplored northwest exit beyond it.
  local function afterSplash()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne, ataxiaBasher.enabled = true, true
    MAP.drForce = false
    MAP.reset()
    M.explore.lavaRooms, M.explore.lavaEdges, M.explore.failed = {}, {}, {}
    -- Only ONE way on from the tunnel, and it is the lava room: that is what made the lava a
    -- transit node in the log rather than a place we merely visited.
    MAP.onRoom(100, "In a stone tunnel.", { north = 0 }, nil)
    M.explore.fromRoom, M.explore.fromDir = 100, "n"
    MAP.onRoom(200, "A corridor inside the Gnoll fortress.", { south = 100, northwest = 0 }, "north")
    local realSend = send; send = function() end
    M.onLava()                       -- we splashed on arrival
    send = realSend
  end

  it("remembers the EDGE, not just the room", function()
    afterSplash()
    expect(M.roomIsLava(200)).toBeTrue()
    expect(M.edgeIsLava(100, "north")).toBeTrue()
    MAP.drForce = nil
  end)

  -- The edge is what saves us: gmcp gives no destination id for an unvisited neighbour, so
  -- room-keyed marking alone is unusable from the room next door.
  it("refuses the step even with no destination id known", function()
    afterSplash()
    MAP.rooms[100].exits.north = 0   -- gmcp never filled it
    expect(M._exitTarget(100, "north")).toBe(nil)
    expect(M.edgeIsLava(100, "north")).toBeTrue()
    MAP.drForce = nil
  end)

  -- THE ONE THAT KILLED US. Once the lava room was walked its exits stopped counting as
  -- unexplored, so the earlier filter never saw them -- but the unexplored NW exit BEYOND it
  -- made the lava room the shortest path, and the sweep took it three times.
  it("will not backtrack THROUGH the lava room", function()
    afterSplash()
    MAP.current = 100
    local step = M._nextExploreStep()
    expect(step).toBe(nil)           -- the only route out is through lava: stay put
    MAP.drForce = nil
  end)

  it("still sweeps a route that does not touch lava", function()
    afterSplash()
    MAP.rooms[100].exits.east = 0    -- a clean unexplored exit appears
    MAP.current = 100
    expect(M._nextExploreStep()).toBe("e")
    MAP.drForce = nil
  end)

  -- An edge marked out of a room we were never next to would refuse a good exit forever.
  it("does not record an edge from a stale fromRoom", function()
    afterSplash()
    M.explore.lavaRooms, M.explore.lavaEdges = {}, {}
    MAP.current = 200
    M.explore.fromRoom = 200          -- stale: says we came from the room we are standing in
    M.explore.fromDir = "n"
    local realSend = send; send = function() end
    M.onLava()
    send = realSend
    expect(M.explore.lavaEdges[200]).toBe(nil)
    MAP.drForce = nil
  end)
end)

-- ---------------------------------------------------------------------------
-- Room numbers are only meaningful within one ripple (v4.7.260)
-- ---------------------------------------------------------------------------
describe("room-keyed memory dies with the ripple", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map

  local function inTower()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne, ataxiaBasher.enabled = true, true
    MAP.drForce = false
    ataxiaTemp = ataxiaTemp or {}
  end

  it("clears lava, condemned exits and chase counters on a new ripple", function()
    inTower()
    MAP._ripple = 1
    M.explore.lavaRooms = { [65420] = true }
    M.explore.lavaEdges = { [65314] = { north = true } }
    M.explore.failed = { [65314] = { west = true } }
    M.explore.fromRoom, M.explore.fromDir = 65314, "n"
    ataxiaTemp.bossChases = 4

    MAP.onRipple(2)

    expect(M.explore.lavaEdges[65314]).toBe(nil)
    expect(M.explore.lavaRooms[65420]).toBe(nil)
    expect(M.explore.failed[65314]).toBe(nil)
    expect(M.explore.fromRoom).toBe(nil)
    expect(ataxiaTemp.bossChases).toBe(nil)
    MAP.drForce = nil
  end)

  -- The reported bug, end to end: ripple 2 opens in a cavern whose only exit is north, and the
  -- sweep refuses it as lava because an EARLIER ripple reused room id 65314.
  it("does not refuse an exit on lava learned in a previous ripple", function()
    inTower()
    MAP._ripple = 1
    MAP.reset()
    MAP.onRoom(65314, "A corridor.", { north = 65420 }, nil)
    M.explore.fromRoom, M.explore.fromDir = 65314, "n"
    local realSend = send; send = function() end
    MAP.onRoom(65420, "Boiling lava.", { south = 65314 }, "north")
    M.onLava("You splash into boiling lava!")
    send = realSend
    -- Pass the real entry line: onLava now distinguishes the splash (entry) from the struggle
    -- (tick), and only the splash may speak for a room mid-episode.
    expect((M._stepRefusal(65314, "north") or ""):find("leads into lava", 1, true) ~= nil).toBeTrue()

    MAP.onRipple(2) -- new level, same ids come back around
    MAP.onRoom(65314, "An empty cavern.", { north = 65420 }, nil)
    expect(M._stepRefusal(65314, "north")).toBe(nil)
    MAP.drForce = nil
  end)
end)


-- ---------------------------------------------------------------------------
-- The phantom lava edge (v4.7.262)
-- ---------------------------------------------------------------------------
describe("lava marks only what the map witnessed", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map
  local realSend, sentCmds

  local SPLASH = "You splash into boiling lava!"
  local TICK = "You continue to struggle in the boiling grasp of the lava as it eats away at your body."

  local function setup()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    MAP.drForce = false
    MAP.reset()
    M.explore.on = true
    M.explore.lavaRooms, M.explore.lavaEdges, M.explore.failed = {}, {}, {}
    M.explore.fromRoom, M.explore.fromDir = nil, nil
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemLavaAt, ataxiaTemp.mnemLavaRoom, ataxiaTemp.mnemLavaStray = nil, nil, nil
    ataxiaTemp.mnemLavaDir = nil
    ataxiaTemp.mnemLavaQlAt = nil
    MAP._lastArrival = nil
    realSend = send; sentCmds = {}
    send = function(c) table.insert(sentCmds, c) end
  end
  local function restore() send = realSend; MAP.drForce = nil end

  -- THE REPORTED BUG. A tumble moved us without arming, so the armed pair named a door on the
  -- far side of the grid and the splash condemned it forever.
  it("condemns the edge we ACTUALLY walked, not the one we armed", function()
    setup()
    MAP.onRoom(50, "Darkened corridor.", { northeast = 0, northwest = 0 }, nil)
    M.explore.fromRoom, M.explore.fromDir = 50, "nw"  -- armed a sweep step northwest...
    MAP._lastMoveDir = "ne"                           -- ...but something tumbled us NORTHEAST
    MAP.onRoom(70, "A river of boiling lava.", { southwest = 50 }, nil)
    M.onLava(SPLASH)
    expect(M.explore.lavaEdges[50] ~= nil).toBeTrue()
    expect(M.explore.lavaEdges[50].northeast ~= nil).toBeTrue()
    expect(M.explore.lavaEdges[50].northwest).toBe(nil) -- THE PHANTOM
    restore()
  end)

  it("records no edge at all when the map cannot prove how we arrived", function()
    setup()
    MAP.onRoom(50, "A river of boiling lava.", { north = 0 }, nil)
    MAP._lastArrival = nil
    M.explore.fromRoom, M.explore.fromDir = 999, "nw" -- a room we are not next to
    M.onLava(SPLASH)
    expect(M.explore.lavaEdges[999]).toBe(nil)
    expect(M.explore.lavaRooms[50] ~= nil).toBeTrue() -- the ROOM mark still stands
    restore()
  end)

  -- The DISCRIMINATING case for the adjacency check. The anchor is a room we really do know --
  -- so the "is it in the map?" guard passes -- but the edge it names does not lead to where we
  -- are standing. The old guard (from ~= cur) accepted exactly this, which is the bug.
  it("refuses an armed anchor that is KNOWN but not adjacent", function()
    setup()
    MAP.onRoom(50, "Darkened corridor.", { northeast = 70, northwest = 60 }, nil)
    MAP.onRoom(60, "Hallway of spoils.", { southeast = 50 }, "northwest")
    MAP._lastArrival = nil                            -- the map cannot witness this arrival
    MAP.onRoom(70, "A river of boiling lava.", { southwest = 50 }, nil)
    MAP._lastArrival = nil
    M.explore.fromRoom, M.explore.fromDir = 50, "nw"  -- 50 nw leads to 60, NOT to 70
    M.onLava(SPLASH)
    expect((M.explore.lavaEdges[50] or {}).northwest).toBe(nil)
    expect(M.explore.lavaRooms[70] ~= nil).toBeTrue()
    restore()
  end)

  it("a trailing struggle tick does not condemn the room we escaped into", function()
    setup()
    MAP.onRoom(50, "Lava.", { west = 60 }, nil)
    M.onLava(SPLASH)
    expect(M.explore.lavaRooms[50] ~= nil).toBeTrue()
    MAP.onRoom(60, "Hallway of spoils.", { east = 50 }, "west") -- the escape LANDS
    M.onLava(TICK)                                              -- ...and a buffered tick arrives
    expect(M.explore.lavaRooms[60]).toBe(nil)                   -- a perfectly good room
    expect((M.explore.lavaEdges[50] or {}).west).toBe(nil)      -- the escape edge
    restore()
  end)

  -- The bound matters more than the guard: refusing forever would cost a death.
  it("believes the SECOND mismatched tick -- a missed entry line must not strand us", function()
    setup()
    MAP.onRoom(50, "Lava.", { west = 60 }, nil)
    M.onLava(SPLASH)
    MAP.onRoom(60, "Also lava, entry line missed.", { east = 50 }, "west")
    M.onLava(TICK)
    M.onLava(TICK)
    expect(M.explore.lavaRooms[60] ~= nil).toBeTrue()
    restore()
  end)

  it("keeps escaping by the SAME door on every tick", function()
    setup()
    -- Simulate the real arrival (walked north to get here), so the map records SOUTH as the
    -- explored back door and NORTH -- a continuing, never-walked corridor -- as the unexplored
    -- pick v4.7.297 now prefers. The episode must still remember and reuse ONE door across
    -- ticks regardless of which door that is.
    MAP.onRoom(1, "before", {}, nil)
    MAP.onRoom(50, "Lava.", { south = 0, north = 0 }, "n")
    M.explore.fromDir = "n"
    M.onLava(SPLASH)
    M.onLava(TICK)
    M.onLava(TICK)
    local seen = 0
    for _, c in ipairs(sentCmds) do
      local d = c:find("stand", 1, true) and c:match("stand;(%a+)$")
      if d then seen = seen + 1; expect(d).toBe("n") end
    end
    expect(seen > 1).toBeTrue() -- proves more than one tick actually queued a move
    restore()
  end)

  it("a glance does not graft the neighbour's exits onto our room", function()
    setup()
    MAP.onRoom(67777, "Darkened corridor.", { northeast = 67869, northwest = 67738 }, nil)
    MAP.onGlance("northwest")
    MAP.onExitsLine("You see exits leading north and southeast.") -- the NEIGHBOUR's exits
    local ex = MAP.rooms[67777].exits
    expect(ex.north).toBe(nil)
    expect(ex.southeast).toBe(nil)
    expect(ex.northeast).toBe(67869)
    MAP.onExitsLine("You see exits leading northeast and northwest.") -- token spent: ours lands
    expect(MAP.rooms[67777].exits.northeast).toBe(67869)
    restore()
  end)

  it("a refusal names WHICH lava fact caused it", function()
    setup()
    MAP.onRoom(50, "Darkened corridor.", { northwest = 0 }, nil)
    M.explore.lavaEdges[50] = { northwest = { at = 1, ripple = 7, why = "walked in" } }
    local why = M._stepRefusal(50, "northwest") or ""
    expect(why:find("edge remembered", 1, true) ~= nil).toBeTrue()
    expect(why:find("ripple 7", 1, true) ~= nil).toBeTrue()
    restore()
  end)

  it("a resumed sweep inherits no adjacency claim", function()
    setup()
    M.explore.fromRoom, M.explore.fromDir = 4242, "nw"
    M._exploreResume("test")
    expect(M.explore.fromRoom).toBe(nil)
    expect(M.explore.fromDir).toBe(nil)
    restore()
  end)
end)

-- ---------------------------------------------------------------------------
-- The boon-screen ql storm (v4.7.263)
-- ---------------------------------------------------------------------------
describe("an empty gmcp push is silence, not a denial", function()
  local MAP = ataxia.mnemosyne.map

  local function tower()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    MAP.drForce = false
    MAP.reset()
  end

  -- THE ENGINE of the storm: every push rebuilt exits from the tower's empty gmcp table, so
  -- whatever the room's own description had just taught us was erased -- including on the push
  -- that our own `ql` had caused. Ask, wipe, find nothing, ask again.
  it("keeps the exits we already have when gmcp reports none", function()
    tower()
    MAP.onRoom(50, "A corridor.", { north = 51 }, nil)
    MAP.onRoom(50, "A corridor.", {}, nil)
    expect(MAP.rooms[50].exits.north).toBe(51)
    MAP.onRoom(50, "A corridor.", nil, nil)
    expect(MAP.rooms[50].exits.north).toBe(51)
    MAP.drForce = nil
  end)

  -- The wipe's actual purpose, which must survive: a direction gmcp STOPS naming, in a push
  -- where it names others, is a direction the room does not have.
  it("still drops a direction a non-empty push stopped reporting", function()
    tower()
    MAP.onRoom(50, "A corridor.", { north = 51, east = 52 }, nil)
    MAP.onRoom(50, "A corridor.", { north = 51 }, nil)
    expect(MAP.rooms[50].exits.east).toBe(nil)
    expect(MAP.rooms[50].exits.north).toBe(51)
    MAP.drForce = nil
  end)

  it("a text-derived exit survives a later empty push", function()
    tower()
    MAP.onRoom(50, "A corridor.", {}, nil)
    MAP.onExitsLine("You see a single exit leading northeast.")
    expect(MAP.rooms[50].exits.northeast).toBe(0)
    MAP.onRoom(50, "A corridor.", {}, nil)
    expect(MAP.rooms[50].exits.northeast).toBe(0)
    MAP.drForce = nil
  end)
end)

describe("room sub-events are not arrivals", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map

  -- gmcp.Room is a PREFIX event: Room.Players / AddPlayer / RemovePlayer / WrongDir all raise
  -- it. Acting on those meant another player walking in rebuilt our exits, and -- worse --
  -- Room.WrongDir credited a dead-reckoning step for a move the server had just REFUSED.
  it("a bare gmcp.Room raise does not advance the dead reckoning", function()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    MAP.drForce = true
    MAP.reset()
    gmcp = gmcp or {}
    gmcp.Room = { Info = { num = 900, name = "A cell.", exits = { east = 0 } } }
    local wasOn = M.explore.on
    M.explore.on = false -- keep 008's handler inert; this test is about 005
    MAP.drArm("east")
    raiseEvent("gmcp.Room")
    expect(MAP.dr.x).toBe(0) -- a Players push must move nothing
    raiseEvent("gmcp.Room.Info")
    expect(MAP.dr.x).toBe(1) -- a real arrival does
    M.explore.on = wasOn
    MAP.drForce = nil
  end)
end)

describe("the arrival handler never asks for exits", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map

  it("sends no ql however many times it runs on an exitless room", function()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher.enabled = true
    MAP.drForce = false
    MAP.reset()
    MAP.onRoom(50, "Wading the Mnemosyne.", {}, nil)
    M.explore.on = true
    M.explore.moving = false
    local realSend, sent = send, {}
    send = function(c) table.insert(sent, c) end
    for _ = 1, 5 do M._onExploreRoom() end
    send = realSend
    local qls = 0
    for _, c in ipairs(sent) do if c == "ql" then qls = qls + 1 end end
    expect(qls).toBe(0)
    M.explore.on = false
    MAP.drForce = nil
  end)
end)

-- ---------------------------------------------------------------------------
-- The pause suspends NAVIGATION only (v4.7.263)
-- ---------------------------------------------------------------------------
describe("navigation suspension", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map

  it("names its refusal, and is silent when clear", function()
    M.explore.pausedAtBoon = false
    expect(M._navRefusal()).toBe(nil)
    M.explore.pausedAtBoon = true
    expect(M._navRefusal()).toBe("paused at the boon screen")
    M.explore.pausedAtBoon = false
  end)

  -- THE REGRESSION THAT MATTERED. The old gate sat above the swarm delegation, so pausing the
  -- sweep also froze every swarm state machine -- the escape ladder fired once and then had no
  -- clock to leave `recovering`.
  it("a paused tick still reaches the swarm", function()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    MAP.drForce = false
    MAP.reset()
    MAP.onRoom(50, "A corridor.", { north = 51 }, nil)
    M.explore.on = true
    M.explore.moving = false
    M.explore.pausedAtBoon = true
    local called = false
    local realSwarm = M.swarm
    M.swarm = { onTick = function() called = true; return false end }
    local realSend, sent = send, {}
    send = function(c) table.insert(sent, c) end
    M._exploreTick()
    send = realSend
    M.swarm = realSwarm
    expect(called).toBeTrue()
    -- ...and having reached it, the sweep itself still navigates nowhere.
    local moved = false
    for _, c in ipairs(sent) do if c:find("stand", 1, true) then moved = true end end
    expect(moved).toBeFalse()
    M.explore.pausedAtBoon = false
    M.explore.on = false
    MAP.drForce = nil
  end)

  it("refuses a boss chase while paused", function()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher.enabled = true
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.bossPanicAt = getEpoch()
    ataxiaTemp.escapeMode = nil
    M.explore.pausedAtBoon = true
    expect(M._chaseRefusal("southeast")).toBe("paused at the boon screen")
    M.explore.pausedAtBoon = false
  end)
end)

-- ---------------------------------------------------------------------------
-- "There are no obvious exits." -- an answer, not silence (v4.7.263)
-- ---------------------------------------------------------------------------
describe("a told-zero room", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map

  local function tower()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    MAP.drForce = false
    MAP.reset()
  end

  it("is not parsed as an exits list", function()
    expect(MAP.parseExitsLine("There are no obvious exits.")).toBe(nil)
  end)

  it("records the zero without touching the exit graph", function()
    tower()
    MAP.onRoom(90, "Wading the Mnemosyne.", { down = 91 }, nil)
    expect(MAP.onNoExits()).toBeTrue()
    expect(MAP.rooms[90].exitsTextZero).toBeTrue()
    -- THE DESCENT: "no OBVIOUS exits" is not "no exits".
    expect(MAP.rooms[90].exits.down).toBe(91)
    expect(M._stepRefusal(90, "down")).toBe(nil)
    MAP.drForce = nil
  end)

  it("is inert outside the tower", function()
    tower()
    MAP.onRoom(90, "A closet.", {}, nil)
    ataxiaBasher.inMnemosyne = false
    -- inMnem() is an OR: an active telemetry run also counts as being in the tower.
    local wasRun = M.run and M.run.active
    if M.run then M.run.active = false end
    expect(MAP.onNoExits()).toBeFalse()
    if M.run then M.run.active = wasRun end
    expect(MAP.rooms[90].exitsTextZero).toBe(nil)
    ataxiaBasher.inMnemosyne = true
    MAP.drForce = nil
  end)

  -- The v4.7.262 regression in a new hat: a glanced dead end prints this line inside the
  -- GLANCED block, and marking our own room from it would be exactly that bug.
  it("spends the glance token so a neighbour's dead end is not ours", function()
    tower()
    MAP.onRoom(90, "A corridor.", { north = 91 }, nil)
    MAP.onGlance("north")
    expect(MAP.onNoExits()).toBeFalse()          -- that was the NEIGHBOUR's line
    expect(MAP.rooms[90].exitsTextZero).toBe(nil)
    expect(MAP.onNoExits()).toBeTrue()           -- token spent: this one is ours
    MAP.drForce = nil
  end)

  it("a later exits line retracts the zero", function()
    tower()
    MAP.onRoom(90, "A corridor.", {}, nil)
    MAP.onNoExits()
    expect(MAP.rooms[90].exitsTextZero).toBeTrue()
    MAP.onExitsLine("You see a single exit leading northeast.")
    expect(MAP.rooms[90].exitsTextZero).toBe(nil)
    MAP.drForce = nil
  end)

  -- _exploreStop restores the basher and clears `explore.on`, and exploreOnGo only UN-pauses --
  -- so stopping here would kill the sweep for the rest of the run.
  it("holds the sweep instead of switching it off", function()
    tower()
    ataxiaBasher.enabled = true
    MAP.onRoom(90, "Wading the Mnemosyne.", {}, nil)
    MAP.onNoExits()
    M.explore.on = true
    M.explore.moving = false
    M.explore.pausedAtBoon = false
    M.explore._noExitHolds = nil
    local realSend = send; send = function() end
    M._exploreTick()
    send = realSend
    expect(M.explore.on).toBeTrue()
    expect((tonumber(M.explore._noExitHolds) or 0) > 0).toBeTrue()
    M.explore.on = false
    MAP.drForce = nil
  end)
end)

-- ---------------------------------------------------------------------------
-- Attune-gated boons (v4.7.264)
-- ---------------------------------------------------------------------------
describe("a boon that names a spirit", function()
  local M = ataxia.mnemosyne
  local HYDRA = "When attuned to Arius, your attacks will trigger a terrible roar which strikes another random denizen in the location."
  local RESOLVE = "While attuned to Garon, all damage you take will be reduced by an additional 10%."

  local function spirits(attunes, profiles)
    shaman = shaman or {}
    shaman.spiritlore = { attunements = attunes, profiles = profiles or {} }
  end

  -- Parse the SENTENCE, not a boon->spirit table: every one of these descriptions names its own
  -- spirit, so a lookup table would cover today's four and go stale on the fifth.
  it("reads the spirit out of the description", function()
    expect(M._spiritGate(HYDRA)).toBe("Arius")
    expect(M._spiritGate(RESOLVE)).toBe("Garon")
    expect(M._spiritGate("Your bisect attack now executes denizens.")).toBe(nil)
    expect(M._spiritGate(nil)).toBe(nil)
  end)

  it("answers attuned / not attuned", function()
    spirits({ "Garon", "Arius", "Marak" })
    expect(M._attuned("Arius")).toBeTrue()
    expect(M._attuned("Aspar")).toBeFalse()
  end)

  -- Three states on purpose. On a non-Shaman, or before the first SPIRIT BINDINGS read, "not
  -- attuned" would be a confident wrong answer at a screen where the user is choosing.
  it("says UNKNOWN rather than guessing when the attunements have never been read", function()
    shaman = shaman or {}
    shaman.spiritlore = { attunements = {} }
    expect(M._attuned("Arius")).toBe(nil)
    shaman.spiritlore = nil
    expect(M._attuned("Arius")).toBe(nil)
  end)

  it("names a profile that would satisfy it, deterministically", function()
    spirits({ "Aelkesh", "Marak", "Ri'shen" }, {
      Zebra = { attunements = { "Garon", "Marak", "Arius" } },
      Bashing = { attunements = { "Arius", "Garon", "Marak" } },
    })
    expect(M._profileWith("Garon")).toBe("Bashing") -- sorted, so never pairs-order roulette
    expect(M._profileWith("Aspar")).toBe(nil)
  end)

  it("warns on claim only when the spirit is provably absent", function()
    local said = {}
    local realEcho = M.echo
    M.echo = function(t) table.insert(said, t) end
    M.history = M.history or {}

    spirits({ "Aelkesh", "Marak", "Ri'shen" })
    M._warnAttuneOnClaim2 = nil
    M.echo = function(t) table.insert(said, t) end
    -- description comes from the seed DB via _histBoonInfo
    M._warnAttuneOnClaim("Knight's Resolve")
    local warned = false
    for _, t in ipairs(said) do if t:find("INERT", 1, true) then warned = true end end
    expect(warned).toBeTrue()

    said = {}
    spirits({ "Garon", "Marak", "Arius" })
    M._warnAttuneOnClaim("Knight's Resolve")
    expect(#said).toBe(0) -- attuned: nothing to say
    M.echo = realEcho
  end)
end)

-- ---------------------------------------------------------------------------
-- Timequake (v4.7.264)
-- ---------------------------------------------------------------------------
describe("Timequake distortion", function()
  local M = ataxia.mnemosyne

  local function setup(n, age)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.shielded = false
    ataxiaBasher.distortionAt = nil
    ataxiaBasher.dwAgeCap = nil
    ataxiaTables = ataxiaTables or {}
    ataxiaTables.depthswalker = { age = age or 0 }
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.dwDistortRoom, ataxiaTemp.dwDistortRefusedAt = nil, nil
    gmcp = gmcp or {}
    gmcp.Room = { Info = { num = 500 } }
    M._denizenCount = function() return n end
    dwTimequake = true
  end

  it("distorts at 2+ denizens, once per room", function()
    setup(2)
    expect(ataxiaBasher_dwTimequake(";")).toBe("chrono distortion;")
    expect(ataxiaBasher_dwTimequake(";")).toBe("") -- same room
    gmcp.Room.Info.num = 501
    expect(ataxiaBasher_dwTimequake(";")).toBe("chrono distortion;")
  end)

  it("is inert below the threshold and without the boon", function()
    setup(1)
    expect(ataxiaBasher_dwTimequake(";")).toBe("")
    setup(3); dwTimequake = false
    expect(ataxiaBasher_dwTimequake(";")).toBe("")
    dwTimequake = true
  end)

  -- 300 age is a large spend and age is the class's PvP currency; bashing must not price out the
  -- chrono kit, so it shares chrono blur's cap rather than inventing a second one.
  it("respects the age cap", function()
    setup(3, 500)
    expect(ataxiaBasher_dwTimequake(";")).toBe("")
  end)

  -- The game's refusal outranks our room key, because under dementia that key is a lie.
  it("stops trying after the game says it is already distorted", function()
    setup(3)
    ataxiaBasher_dwDistortMark(true)
    gmcp.Room.Info.num = 777 -- a NEW room id -- exactly what dementia mints on every look
    expect(ataxiaBasher_dwTimequake(";")).toBe("")
  end)
end)

-- ---------------------------------------------------------------------------
-- Aeonic cash-in: degenerate / deteriorate (v4.7.265)
-- ---------------------------------------------------------------------------
-- The real denizen-model functions, captured BEFORE anything stubs them. Two suites below
-- replace these globals, and a stub that outlives its suite silently rewrites what every later
-- test is measuring -- which is exactly what happened to the aeon wear-off tests (v4.7.268).
_REAL_ds = { hasAff = ataxiaBasher_dsHasAff, resolve = ataxiaBasher_dsResolveNameToId,
             clearAff = ataxiaBasher_dsClearAff }

describe("cashing a denizen affliction into an aeonic nuke", function()
  local affs, realHasAff

  local function setup(age)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.shielded = false
    ataxiaBasher.dwAeonic = nil
    ataxiaBasher.dwAgeCap = nil
    ataxiaTables = ataxiaTables or {}
    ataxiaTables.depthswalker = { age = age or 0 }
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.dwAeonicAt = nil
    target = 4242 -- numeric: the denizen model is PvE-only
    affs = {}
    -- SAVE AND RESTORE. Stubbing a global and walking away leaks it into every later suite --
    -- these two stubs silently broke the aeon-wear-off tests further down the file.
    realHasAff = realHasAff or ataxiaBasher_dsHasAff
    ataxiaBasher_dsHasAff = function(_, a) return affs[a] == true end
  end

  it("uses DETERIORATE on a mind-addled denizen", function()
    setup()
    affs.aeon = true
    local cmd, aff, cost = ataxiaBasher_dwAeonicPick()
    expect(cmd).toBe("chrono deteriorate 4242")
    expect(aff).toBe("aeon")
    expect(cost).toBe(300)
  end)

  it("uses DEGENERATE on a physically-plagued denizen", function()
    setup()
    affs.sensitivity = true
    local cmd, _, cost = ataxiaBasher_dwAeonicPick()
    expect(cmd).toBe("chrono degenerate 4242")
    expect(cost).toBe(700)
  end)

  -- 300 age against 700 for the same stated effect.
  it("prefers the cheaper deteriorate when both are available", function()
    setup()
    affs.aeon, affs.weakness = true, true
    expect(ataxiaBasher_dwAeonicPick()).toBe("chrono deteriorate 4242")
  end)

  -- chrono erasure CONSUMES weakness/amnesia, so the two cash-ins compete for them.
  it("sorts amnesia last so erasure and deteriorate rarely fight", function()
    setup()
    affs.amnesia, affs.charm = true, true
    local _, aff = ataxiaBasher_dwAeonicPick()
    expect(aff).toBe("charm")
  end)

  it("is silent when the denizen carries nothing it can use", function()
    setup()
    affs.stun = true -- tracked, but not a trigger for either ability
    expect(ataxiaBasher_dwAeonicPick()).toBe(nil)
    expect(ataxiaBasher_dwAeonicCashIn()).toBe("")
  end)

  it("is PvE-only -- a player target never reads the denizen model", function()
    setup()
    affs.aeon = true
    target = "someone"
    expect(ataxiaBasher_dwAeonicPick()).toBe(nil)
  end)

  it("respects the age cap and the shield", function()
    setup(500); affs.aeon = true
    expect(ataxiaBasher_dwAeonicCashIn()).toBe("")
    setup(); affs.aeon = true; ataxiaBasher.shielded = true
    expect(ataxiaBasher_dwAeonicCashIn()).toBe("")
  end)

  -- THE CORRECTION THAT MATTERED (v4.7.267, from a live log). v4.7.265 HELD the command for 4s,
  -- reasoning that re-sending would waste the affliction. The opposite is true: every rebuild
  -- sends "queue addclearfull", which WIPES the line queued 0.3s earlier -- so a hold means the
  -- next rebuild replaces our queued cast with a plain swing before balance ever comes up, and
  -- the command is sent once then deleted. The echo fired while nothing landed.
  it("REPLAYS the command verbatim so each addclearfull re-queues it", function()
    setup(); affs.aeon = true
    expect(ataxiaBasher_dwAeonicCashIn()).toBe("chrono deteriorate 4242")
    expect(ataxiaBasher_dwAeonicCashIn()).toBe("chrono deteriorate 4242") -- not ""
    expect(ataxiaBasher_dwAeonicCashIn()).toBe("chrono deteriorate 4242")
  end)

  -- Releasing the replay is not enough: the affliction is still recorded, so the next rebuild
  -- would cash in again at 300-700 age. On a 30s amnesia that is five casts for one application.
  it("spends the affliction on confirmation so it does not re-cast", function()
    setup(); affs.aeon = true
    local cleared = {}
    ataxiaBasher_dsClearAff = function(_, a) cleared[a] = true; affs[a] = nil end
    expect(ataxiaBasher_dwAeonicCashIn()).toBe("chrono deteriorate 4242")
    ataxiaBasher_dwAeonicConfirm()
    expect(cleared.aeon).toBeTrue()
    expect(ataxiaBasher_dwAeonicCashIn()).toBe("") -- nothing left to cash in
  end)

  -- Last statement of the suite: put the real model back. A stub that outlives its suite rewrites
  -- what every later test is measuring, which is how this file broke its own aeon tests.
  it("restores the real denizen model on the way out", function()
    ataxiaBasher_dsHasAff = realHasAff
    ataxiaBasher_dsClearAff = _REAL_ds.clearAff or ataxiaBasher_dsClearAff
    expect(type(ataxiaBasher_dsHasAff)).toBe("function")
  end)
end)

-- ---------------------------------------------------------------------------
-- Dragon SCORCH reacting to a self-healing denizen (v4.7.266)
-- ---------------------------------------------------------------------------
describe("scorching a denizen that healed itself", function()
  local sent, realSend, affs, realResolve, realHasAff2

  local function setup(opts)
    opts = opts or {}
    -- `or send`, NOT a bare capture: the last test in this block calls setup() TWICE before its
    -- single restore(), so a bare capture takes the FIRST setup's recorder as "the real send" and
    -- restore() then installs that recorder globally -- leaking it into every test file sorted
    -- after this one. test_runner loads all files into one Lua state, and test_swarm_tactics.lua
    -- captures `local _mockSend = send` AT LOAD TIME, so its own restore went on to install this
    -- recorder too. Same idempotent-capture idiom as realResolve/realHasAff2 below (v4.7.316).
    realSend = realSend or send
    sent = {}
    send = function(c) table.insert(sent, c) end
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.enabled, ataxiaBasher.paused = true, false
    ataxiaBasher.scorchAuto = nil
    ataxiaBasher.rageFloor = nil
    ataxia = ataxia or {}
    ataxia.vitals = ataxia.vitals or {}
    ataxia.vitals.rage = opts.rage or 50
    ataxia.denizensHere = {}
    gmcp = gmcp or {}
    gmcp.Char = gmcp.Char or {}
    gmcp.Char.Status = { class = opts.class or "Dragon" }
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.scorchAt, ataxiaTemp.brGlobalReadyAt, ataxiaTemp.brFreeCharge = nil, nil, nil
    affs = {}
    realResolve = realResolve or ataxiaBasher_dsResolveNameToId
    realHasAff2 = realHasAff2 or ataxiaBasher_dsHasAff
    ataxiaBasher_dsResolveNameToId = function() return opts.id end
    ataxiaBasher_dsHasAff = function(_, a) return affs[a] == true end
  end
  -- Restores the REAL implementations as well as send: a stub left behind here made two
  -- later tests read a denizen model that was not there (v4.7.268).
  local function restore()
    send = realSend
    ataxiaBasher_dsResolveNameToId = realResolve
    ataxiaBasher_dsHasAff = realHasAff2
  end

  it("scorches the resolved denizen id", function()
    setup({ id = 8181 })
    expect(ataxiaBasher_dragonScorch("a monstrous hellhound")).toBeTrue()
    expect(sent[1]).toBe("scorch 8181")
    restore()
  end)

  -- The healer is usually NOT our target -- in the capture it lunged at a party member -- so a
  -- keyword fallback keeps it working when the model cannot resolve an id.
  it("falls back to the name's last word when the id is unknown", function()
    setup({ id = nil })
    expect(ataxiaBasher_dragonScorch("a monstrous hellhound")).toBeTrue()
    expect(sent[1]).toBe("scorch hellhound")
    restore()
  end)

  it("does not scorch a denizen that is already inhibited", function()
    setup({ id = 8181 })
    affs.inhibit = true
    expect(ataxiaBasher_dragonScorch("a monstrous hellhound")).toBeFalse()
    expect(#sent).toBe(0)
    restore()
  end)

  it("respects the 25s cooldown and the rage cost", function()
    setup({ id = 8181 })
    expect(ataxiaBasher_dragonScorch("a monstrous hellhound")).toBeTrue()
    -- Clear the shared ~1s BR cooldown that the first send armed, so ONLY the ability's own 25s
    -- cooldown can refuse the second call. Without this the test passes with the 25s check
    -- deleted -- the global gate masks it, which is exactly what the first version did.
    ataxiaTemp.brGlobalReadyAt = nil
    expect(ataxiaBasher_dragonScorch("a monstrous hellhound")).toBeFalse() -- the 25s cooldown
    setup({ id = 8181, rage = 5 })
    expect(ataxiaBasher_dragonScorch("a monstrous hellhound")).toBeFalse() -- 18 rage
    restore()
  end)

  -- It must not queue a second battlerage behind one the rotation already sent.
  it("honours and arms the shared battlerage cooldown", function()
    setup({ id = 8181 })
    ataxiaTemp.brGlobalReadyAt = (getEpoch() or 0) + 5
    expect(ataxiaBasher_dragonScorch("a monstrous hellhound")).toBeFalse()
    setup({ id = 8181 })
    ataxiaBasher_dragonScorch("a monstrous hellhound")
    expect((tonumber(ataxiaTemp.brGlobalReadyAt) or 0) > (getEpoch() or 0)).toBeTrue()
    restore()
  end)

  it("is inert on another class and when switched off", function()
    setup({ id = 8181, class = "Runewarden" })
    expect(ataxiaBasher_dragonScorch("a monstrous hellhound")).toBeFalse()
    setup({ id = 8181 }); ataxiaBasher.scorchAuto = false
    expect(ataxiaBasher_dragonScorch("a monstrous hellhound")).toBeFalse()
    restore()
  end)
end)

-- ---------------------------------------------------------------------------
-- Aeon wearing off a denizen (v4.7.268)
-- ---------------------------------------------------------------------------
describe("aeon wear-off clears the denizen model", function()
  -- Trigger 016 matches `^(.+) abruptly begins to move at normal speed again\.$` and hands the
  -- captured name to ataxiaBasher_dsResolveNameToId, which is an EXACT lowercase match against
  -- ataxia.denizensHere. That resolver is the only interesting logic in the trigger, and it is
  -- what these pin -- the aeonic cash-in spends 300 age off this flag, so a stale aeon buys
  -- nothing and a failed clear leaves one.
  --
  -- State is built DIRECTLY rather than through ataxiaBasher_dsSetAff: several suites in this
  -- project replace that global at file scope without restoring it, so a test that depends on it
  -- measures whichever stub loaded last (v4.7.268 -- three separate leaks found this way).
  -- dsAdd/dsGet are untouched, and the setter itself is covered by test_denizen_state.
  -- LOAD THE MODULE. This file never did, so every ataxiaBasher_ds* global here was whatever
  -- leaked in from an earlier test file -- and three separate files stub them at file scope
  -- without restoring (v4.7.268). Loading 008 re-defines them to the real implementations, which
  -- is both the fix and the guarantee that these tests measure the shipped code.
  ataxiaTemp = ataxiaTemp or {}
  dofile("src_new/scripts/levi_ataxia/levi/ataxia/basher/008_Denizen_State.lua")

  local function seed(names, aeonOn)
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.enabled = true
    ataxia = ataxia or {}
    ataxia.denizensHere = names
    ataxiaTemp = ataxiaTemp or {}
    ataxiaBasher_dsReset()
    for id, nm in pairs(names) do
      local ds = ataxiaBasher_dsAdd(id, nm)
      if ds and id == aeonOn then ds.affs.aeon = { endsAt = nil } end -- nil = until cleared
    end
  end

  it("resolves a proper-named denizen with a comma in it", function()
    seed({ [259973] = "Celepharn, High Priest of Life" }, 259973)
    expect(ataxiaBasher_dsHasAff(259973, "aeon", 1000)).toBeTrue()
    local id = ataxiaBasher_dsResolveNameToId("Celepharn, High Priest of Life", nil, "aeon", 1000)
    expect(id).toBe(259973)
    ataxiaBasher_dsClearAff(id, "aeon")
    expect(ataxiaBasher_dsHasAff(259973, "aeon", 1000)).toBeFalse()
  end)

  -- The line capitalises the article at the start of a sentence ("An haruspex...") while
  -- denizensHere holds it lowercase; the resolver lowercases both, so this must hold.
  it("resolves across the sentence-initial capital", function()
    seed({ [8181] = "an haruspex of Life" }, 8181)
    expect(ataxiaBasher_dsResolveNameToId("An haruspex of Life", nil, "aeon", 1000)).toBe(8181)
  end)

  -- Two identically-named mobs, one aeoned: preferAff is what stops the clear landing on the
  -- wrong one and leaving a phantom aeon for the cash-in to spend 300 age on.
  it("prefers the denizen that actually carries the aeon", function()
    seed({ [1] = "an haruspex of Life", [2] = "an haruspex of Life" }, 2)
    expect(ataxiaBasher_dsResolveNameToId("An haruspex of Life", nil, "aeon", 1000)).toBe(2)
  end)
end)

-- --- v4.7.298: the rest of the tracker's schema -----------------------------
--
-- `BoonInfo` had eight fields (nine since v4.7.322) and we were sending two; `BoonsOfferedRequest` has a
-- `reroll_count` we had never sent; `/run_pause` existed and was never called. These cover the
-- three, plus the catalogue plumbing that had been parsing fields and dropping them.

-- Swap the boon catalogue for the duration of one test. The library is process-wide state that
-- `reset()` deliberately does NOT clear (it is a persisted catalogue, not run state), so a test
-- that seeds it must put it back or it leaks into every test that runs after it.
local function withLibrary(entries, fn)
  local saved = M.history.boonLibrary
  M.history.boonLibrary = entries
  local ok, err = pcall(fn)
  M.history.boonLibrary = saved
  if not ok then error(err, 0) end
end

-- Payloads for every /boons_offered committed, in order, from BOTH sources -- the serial queue
-- posts the head and leaves it in _queue until the server answers.
local function offeredPayloads()
  local out = {}
  for _, r in ipairs(sent) do
    if r.payload and r.payload.offered then out[#out + 1] = r.payload end
  end
  for i, q in ipairs(M._queue) do
    if not (i == 1 and M._busy) and q.payload and q.payload.offered then
      out[#out + 1] = q.payload
    end
  end
  return out
end

describe("boons_offered enrichment from the local catalogue", function()
  it("fills rarity/quote/category/unlocked_by/conflicts_with/echoes the screen never prints", function()
    reset(true)
    withLibrary({
      ["Iron Throat"] = {
        description = "catalogue copy",
        rarity = "uncommon",
        maxEchoes = 3,
        quote = "A voice like gravel.",
        category = "Defensive",
        unlockedBy = "Sharp Mind",
        conflictsWith = { "Glass Jaw", "Hammer and Anvil" },
      },
    }, function()
      M.reportBoonsOffered({
        { name = "Iron Throat", description = "Gain 25% resistance to asphyxiation damage." },
      })
      local b = sent[1].payload.offered[1]
      -- FILL, NEVER OVERWRITE: the offer screen is authoritative for the description.
      expect(b.description).toBe("Gain 25% resistance to asphyxiation damage.")
      expect(b.rarity).toBe("uncommon")
      expect(b.quote).toBe("A voice like gravel.")
      expect(b.category).toBe("Defensive")
      expect(b.unlocked_by).toBe("Sharp Mind")          -- camelCase -> snake_case at the boundary
      expect(b.num_echoes_possible).toBe(3)
      expect(#b.conflicts_with).toBe(2)
      expect(b.conflicts_with[2]).toBe("Hammer and Anvil")
    end)
  end)

  -- The caller's list is also what goes to local history and seeds run.lastOffered.
  it("returns a copy -- the caller's list is never mutated", function()
    reset(true)
    local list = { { name = "Iron Throat" } }
    withLibrary({ ["Iron Throat"] = { rarity = "rare", conflictsWith = { "Glass Jaw" } } }, function()
      M.reportBoonsOffered(list)
      expect(sent[1].payload.offered[1].rarity).toBe("rare")
      expect(list[1].rarity).toBeNil()
      expect(list[1].conflicts_with).toBeNil()
    end)
  end)

  it("posts unchanged when the catalogue has never seen the boon", function()
    reset(true)
    withLibrary({}, function()
      M.reportBoonsOffered({ { name = "Never Seen", description = "d" } })
      local b = sent[1].payload.offered[1]
      expect(b.name).toBe("Never Seen")
      expect(b.description).toBe("d")
      expect(b.rarity).toBeNil()
      expect(b.conflicts_with).toBeNil()
    end)
  end)

  -- An empty Lua table has no array/object distinction, so yajl may encode {} where the schema
  -- wants []. Omitting the key already says "we know of no conflicts".
  it("omits conflicts_with rather than sending an empty table", function()
    reset(true)
    withLibrary({ ["Iron Throat"] = { conflictsWith = {} } }, function()
      M.reportBoonsOffered({ { name = "Iron Throat" } })
      expect(sent[1].payload.offered[1].conflicts_with).toBeNil()
    end)
  end)

  -- A catalogue entry must never blank something the screen supplied.
  it("does not overwrite a field the offer screen already carried", function()
    reset(true)
    withLibrary({ ["Iron Throat"] = { rarity = "common", quote = "catalogue quote" } }, function()
      M.reportBoonsOffered({ { name = "Iron Throat", rarity = "legendary" } })
      expect(sent[1].payload.offered[1].rarity).toBe("legendary")
      expect(sent[1].payload.offered[1].quote).toBe("catalogue quote") -- the one it lacked
    end)
  end)
end)

describe("reroll_count inference", function()
  -- Drive the REAL offer screen through the real capture, the way the v4.7.279 break-back test
  -- does: calling _rerollBump directly would leave the wiring in onBoonsOffered undefended, and
  -- that wiring (bumping BEFORE lastOffered is overwritten) is the whole trick.
  local function feedScreen(rows)
    local mock = require("mock_mudlet")
    M._capturing = false
    M.onBoonsOffered()
    local feed = { "----------------------------------------" }
    for _, r in ipairs(rows) do feed[#feed + 1] = r end
    feed[#feed + 1] = "Type BOON CLAIM <name> to choose."
    for _, ln in ipairs(feed) do
      line = ln
      for _, t in pairs(mock.active_triggers) do
        if t.regex and t.pattern == "^.*$" and type(t.callback) == "function" then t.callback() end
      end
    end
  end

  local A = { "Songstep:      Your dances are free.", "Iron Throat:   Resist asphyxiation." }
  local B = { "Tantrum:       Free battlerage.", "Sharp Mind:    Think faster." }

  it("sends 0 on an ordinary single offer screen", function()
    reset(true)
    feedScreen(A)
    M.onRipple(3)
    expect(offeredPayloads()[1].reroll_count).toBe(0)
  end)

  it("counts a second screen with DIFFERENT boons and no claim in between", function()
    reset(true)
    feedScreen(A)
    feedScreen(B)
    M.onRipple(3)
    local p = offeredPayloads()
    expect(p[#p].reroll_count).toBe(1)
  end)

  -- A reprint is not evidence of anything: same names, so it neither counts nor resets.
  it("ignores an identical re-print of the same screen", function()
    reset(true)
    feedScreen(A)
    feedScreen(A)
    M.onRipple(3)
    local p = offeredPayloads()
    expect(p[#p].reroll_count).toBe(0)
  end)

  -- Negotiator's Prospero's Fortune opens a second screen AFTER a claim. That is a second pick,
  -- not a reroll, and the claim is what distinguishes them.
  it("a claim between two screens starts a fresh chain", function()
    reset(true)
    feedScreen(A)
    M.onBoonClaim("Songstep")
    feedScreen(B)
    M.onRipple(3)
    local p = offeredPayloads()
    expect(p[#p].reroll_count).toBe(0)
  end)

  -- GO! means a wave was fought, so the next screen is a new offer however the claim went.
  it("GO! ends the chain even when no claim was detected", function()
    reset(true)
    feedScreen(A)
    M.onGo()
    feedScreen(B)
    M.onRipple(3)
    local p = offeredPayloads()
    expect(p[#p].reroll_count).toBe(0)
  end)

  it("accumulates across several rerolls in one chain", function()
    reset(true)
    feedScreen(A)
    feedScreen(B)
    feedScreen(A)
    expect(M._rerollCount()).toBe(2)
  end)

  it("a fresh run never inherits the last one's tally", function()
    reset(true)
    ataxiaTemp.mnemRerolls = 4
    ataxiaTemp.mnemOfferChain = true
    M._resetRun()
    expect(M._rerollCount()).toBe(0)
    -- the CHAIN too, or the next first screen reads as 1
    expect(ataxiaTemp.mnemOfferChain).toBeFalse()
  end)

  -- THE SERIALIZATION RULE (deep review). `M.run` is a plain table inside `ataxia`, which
  -- `ataxia_saveSettings` writes to disk WHOLESALE, and `deepMerge` lets the disk value win on
  -- load. A per-screen counter kept there comes back stuck at whatever was last saved. This
  -- asserts the state is NOT on the serialized namespace -- the v4.7.192-194 rule.
  it("keeps the chain off the serialized namespace", function()
    reset(true)
    feedScreen(A)
    feedScreen(B)
    expect(M._rerollCount()).toBe(1)
    expect(M.run.rerolls).toBeNil()
    expect(M.run.offerChain).toBeNil()
  end)

  -- The failure this guards: a run that ended mid-chain leaves the chain open, and the next
  -- run's FIRST screen necessarily differs from the (empty) previous names.
  it("the first screen of a new run is never a reroll, even after a mid-chain end", function()
    reset(true)
    feedScreen(A)                 -- chain opens
    M.startRun()                  -- new dive: _resetRun runs
    feedScreen(B)
    expect(M._rerollCount()).toBe(0)
  end)

  -- Defence in depth: even with the flag forced on, no previous names means no reroll.
  it("refuses to count a reroll with no previous screen to differ from", function()
    reset(true)
    ataxiaTemp.mnemOfferChain = true
    M.run.lastOffered = {}
    M._rerollBump({ { name = "Songstep" } })
    expect(M._rerollCount()).toBe(0)
  end)

  -- THE SNAPSHOT (deep review). The POST is deferred to the ripple line or a 3s timeout, and a
  -- claim zeroes the chain the instant it fires -- so reading the live count at send time made
  -- the LAST screen of a chain, the most informative row there is, report 0.
  it("reports the count the screen was captured with, even if a claim lands first", function()
    reset(true)
    feedScreen(A)
    feedScreen(B)                       -- reroll #1, pending
    M.onBoonClaim("Tantrum")            -- player claims before the ripple line arrives
    expect(M._rerollCount()).toBe(0)    -- chain correctly closed...
    M.onRipple(3)
    local p = offeredPayloads()
    expect(p[#p].reroll_count).toBe(1)  -- ...but the pending screen keeps its own count
  end)

  -- A re-print is not evidence either way -- and that has to mean it produces no REPORT either,
  -- not merely no count. It used to re-send `wade status` and post a duplicate row.
  it("an identical re-print does not produce a second /boons_offered", function()
    reset(true)
    feedScreen(A)
    M.onRipple(3)
    local before = #offeredPayloads()
    feedScreen(A)                       -- same screen printed again
    M.onRipple(4)
    expect(#offeredPayloads()).toBe(before)
  end)
end)

describe("M._promoteMeta() -- contemplate labels we now know the name of", function()
  it("promotes Category and Unlocked by, and leaves meta whole", function()
    local info = M._promoteMeta({ meta = { ["Category"] = "Offensive", ["Unlocked by"] = "Sharp Mind" } })
    expect(info.category).toBe("Offensive")
    expect(info.unlockedBy).toBe("Sharp Mind")
    -- meta is the mechanism that learns the NEXT label; promotion reads it, never consumes it.
    expect(info.meta["Category"]).toBe("Offensive")
  end)

  it("is case-insensitive on the label", function()
    local info = M._promoteMeta({ meta = { ["category"] = "Defensive" } })
    expect(info.category).toBe("Defensive")
  end)

  -- v4.7.298 kept Conflicts unpromoted until we had seen the line. v4.7.325: we have (the user's
  -- Careless Whisperer block), so it promotes -- as a LIST -- and meta keeps the raw value.
  it("promotes Conflicts with as a list, and meta keeps the raw value", function()
    local info = M._promoteMeta({ meta = { ["Conflicts with"] = "Glass Jaw, Iron Throat." } })
    expect(info.conflictsWith[1]).toBe("Glass Jaw")
    expect(info.conflictsWith[2]).toBe("Iron Throat")
    expect(info.meta["Conflicts with"]).toBe("Glass Jaw, Iron Throat.")
  end)

  -- A value long enough to have wrapped cannot be trusted, so it is refused rather than stored
  -- truncated. This is what makes "category and unlockedBy provably cannot wrap" enforced
  -- rather than assumed.
  it("refuses a promoted value long enough to have wrapped", function()
    local long = string.rep("x", 61)
    local info = M._promoteMeta({ meta = { ["Unlocked by"] = long } })
    expect(info.unlockedBy).toBeNil()
    expect(info.meta["Unlocked by"]).toBe(long)   -- still recorded, just not trusted
  end)

  it("accepts a normal-length value", function()
    local info = M._promoteMeta({ meta = { ["Unlocked by"] = "Midnight Snow's Icy Heart" } })
    expect(info.unlockedBy).toBe("Midnight Snow's Icy Heart")
  end)

  -- "Unlocked by: None" must not become a boon called None -- fill-never-blank would then let it
  -- outrank the real answer when we finally saw it.
  it("refuses placeholder values", function()
    expect(M._promoteMeta({ meta = { ["Unlocked by"] = "None" } }).unlockedBy).toBeNil()
    expect(M._promoteMeta({ meta = { ["Unlocked by"] = "N/A" } }).unlockedBy).toBeNil()
    expect(M._promoteMeta({ meta = { ["Category"] = "none." } }).category).toBeNil()
  end)

  -- Two labels map to unlockedBy; with a first-wins guard, pairs() order would make the winner
  -- arbitrary. Sorted iteration makes it deterministic.
  it("is deterministic when two labels map to one field", function()
    local meta = { ["Unlocked by"] = "Sharp Mind", ["Unlocks from"] = "Iron Throat" }
    local first = M._promoteMeta({ meta = meta }).unlockedBy
    for _ = 1, 20 do
      expect(M._promoteMeta({ meta = meta }).unlockedBy).toBe(first)
    end
  end)

  it("leaves an unrecognised label alone, in meta", function()
    local info = M._promoteMeta({ meta = { ["Whatever"] = "something" } })
    expect(info.whatever).toBeNil()
    expect(info.meta["Whatever"]).toBe("something")
  end)

  it("is a no-op with no meta block at all", function()
    local info = M._promoteMeta({ description = "d" })
    expect(info.description).toBe("d")
    expect(info.category).toBeNil()
  end)

  -- The live path: _parseContemplate must hand back promoted fields, not just meta.
  it("_parseContemplate promotes on the way out", function()
    local info = M._parseContemplate({
      "Rarity: uncommon",
      "Category: Defensive",
      "Your fire damage is increased.",
      "",
      '"A line of flavour."',
    })
    expect(info.rarity).toBe("uncommon")
    expect(info.category).toBe("Defensive")
    expect(info.description).toBe("Your fire damage is increased.")
    expect(info.quote).toBe("A line of flavour.")
  end)
end)

describe("the catalogue keeps what a CONTEMPLATE prints", function()
  it("_learnBoon stores quote/category/unlockedBy/conflictsWith", function()
    withLibrary({}, function()
      local rec = M._learnBoon("Iron Throat", "desc", "Uncommon", 2, {
        quote = "q", category = "Defensive", unlockedBy = "Sharp Mind",
        conflictsWith = { "Glass Jaw" },
      })
      expect(rec.description).toBe("desc")
      expect(rec.rarity).toBe("uncommon")   -- lowercased, as before
      expect(rec.maxEchoes).toBe(2)
      expect(rec.quote).toBe("q")
      expect(rec.category).toBe("Defensive")
      expect(rec.unlockedBy).toBe("Sharp Mind")
      expect(rec.conflictsWith[1]).toBe("Glass Jaw")
    end)
  end)

  it("copies conflictsWith rather than aliasing the caller's table", function()
    withLibrary({}, function()
      local mine = { "Glass Jaw" }
      local rec = M._learnBoon("Iron Throat", "d", nil, nil, { conflictsWith = mine })
      mine[1] = "MUTATED"
      expect(rec.conflictsWith[1]).toBe("Glass Jaw")
    end)
  end)

  it("still fills without blanking -- a later call with nothing new keeps what is there", function()
    withLibrary({}, function()
      M._learnBoon("Iron Throat", "desc", "rare", 1, { quote = "q" })
      local rec = M._learnBoon("Iron Throat", nil, nil, nil, nil)
      expect(rec.description).toBe("desc")
      expect(rec.quote).toBe("q")
    end)
  end)

  -- The old merge named its three fields inline, so the four added in the same release would
  -- have been dropped on BOTH paths -- a saved catalogue would lose them on every round trip.
  it("_boonDbMerge carries every field on the ADD path", function()
    withLibrary({}, function()
      M._boonDbMerge({ ["Iron Throat"] = { description = "d", rarity = "rare", maxEchoes = 2,
                                           quote = "q", category = "Defensive",
                                           unlockedBy = "Sharp Mind",
                                           conflictsWith = { "Glass Jaw" } } })
      local rec = M.boonInfo("Iron Throat")
      expect(rec.quote).toBe("q")
      expect(rec.category).toBe("Defensive")
      expect(rec.unlockedBy).toBe("Sharp Mind")
      expect(rec.conflictsWith[1]).toBe("Glass Jaw")
    end)
  end)

  it("_boonDbMerge fills the new fields on the ENRICH path without blanking", function()
    withLibrary({ ["Iron Throat"] = { description = "kept", category = "Defensive" } }, function()
      local _, enriched = M._boonDbMerge({
        ["Iron Throat"] = { description = "ignored", category = "Offensive", quote = "new" },
      })
      local rec = M.boonInfo("Iron Throat")
      expect(rec.description).toBe("kept")      -- never blanked or replaced
      expect(rec.category).toBe("Defensive")    -- ditto
      expect(rec.quote).toBe("new")             -- the gap it could fill
      expect(enriched).toBe(1)
    end)
  end)
end)

describe("OkResponse is actually read", function()
  -- An HTTP 200 carrying ok:false is the server saying the operation did NOT happen. It used to
  -- be logged as a success and never shown.
  it("surfaces an ok:false refusal with the server's message", function()
    reset(true)
    local said = {}
    local savedEcho = M.echo
    M.echo = function(msg) said[#said + 1] = tostring(msg) end
    M.reportBoss("Seasone")
    completeHead({ ok = false, message = "no active run" })
    M.echo = savedEcho
    expect(#said).toBe(1)
    expect(said[1]).toContain("refused")
    expect(said[1]).toContain("no active run")
  end)

  -- It surfaces; it does not re-route. onOk still runs, because we have never seen this server
  -- answer ok:false and startRun's error path would silently stop reporting for the whole dive.
  it("still runs the success callback on ok:false", function()
    reset(true)
    local ran = false
    local savedEcho = M.echo
    M.echo = function() end
    M._enqueue("/boss", { boss = "x" }, function() ran = true end)
    completeHead({ ok = false, message = "nope" })
    M.echo = savedEcho
    expect(ran).toBeTrue()
  end)

  it("says nothing extra on an ordinary ok:true", function()
    reset(true)
    local said = {}
    local savedEcho = M.echo
    M.echo = function(msg) said[#said + 1] = tostring(msg) end
    M.reportBoss("Seasone")
    completeHead({ ok = true })
    M.echo = savedEcho
    expect(#said).toBe(0)
  end)
end)

-- --- Deep-review coverage gaps ----------------------------------------------

describe("_nameSet / _sameOffer (the reroll guard's own primitives)", function()
  -- Only ever exercised indirectly before, so nothing proved the dedup branch actually deduped
  -- rather than double-counting -- which would make two screens compare unequal on size alone.
  it("dedupes repeated names when counting", function()
    local set, n = M._nameSet({ { name = "A" }, { name = "A" }, { name = "B" } })
    expect(n).toBe(2)
    expect(set["A"]).toBeTrue()
    expect(set["B"]).toBeTrue()
  end)

  it("accepts bare strings as well as {name=} tables", function()
    local _, n = M._nameSet({ "A", "B" })
    expect(n).toBe(2)
  end)

  it("ignores empty and non-string names", function()
    local _, n = M._nameSet({ { name = "" }, { name = 42 }, { name = "A" } })
    expect(n).toBe(1)
  end)

  it("treats a differently-ordered but identical set as the same offer", function()
    expect(M._sameOffer({ "A", "B" }, { { name = "B" }, { name = "A" } })).toBeTrue()
  end)

  it("treats a same-size but different set as different", function()
    expect(M._sameOffer({ "A", "B" }, { { name = "A" }, { name = "C" } })).toBeFalse()
  end)

  it("never calls an empty previous set the same", function()
    expect(M._sameOffer({}, { { name = "A" } })).toBeFalse()
  end)
end)

describe("_enrichOffer does not overwrite non-string fields either", function()
  -- The existing no-overwrite test only covered a STRING field (rarity). num_echoes_possible and
  -- conflicts_with use a different nil-check and were a separate, untested code path.
  it("keeps an echo count the offer already carried", function()
    reset(true)
    local saved = M.history.boonLibrary
    M.history.boonLibrary = { ["Iron Throat"] = { maxEchoes = 9 } }
    M.reportBoonsOffered({ { name = "Iron Throat", num_echoes_possible = 2 } })
    M.history.boonLibrary = saved
    expect(sent[1].payload.offered[1].num_echoes_possible).toBe(2)
  end)

  it("keeps a conflicts list the offer already carried", function()
    reset(true)
    local saved = M.history.boonLibrary
    M.history.boonLibrary = { ["Iron Throat"] = { conflictsWith = { "FromCatalogue" } } }
    M.reportBoonsOffered({ { name = "Iron Throat", conflicts_with = { "FromScreen" } } })
    M.history.boonLibrary = saved
    expect(sent[1].payload.offered[1].conflicts_with[1]).toBe("FromScreen")
  end)

  it("copies the conflicts list rather than aliasing the catalogue's table", function()
    reset(true)
    local saved = M.history.boonLibrary
    local shared = { "Glass Jaw" }
    M.history.boonLibrary = { ["Iron Throat"] = { conflictsWith = shared } }
    M.reportBoonsOffered({ { name = "Iron Throat" } })
    local posted = sent[1].payload.offered[1].conflicts_with
    M.history.boonLibrary = saved
    posted[1] = "MUTATED"
    expect(shared[1]).toBe("Glass Jaw")
  end)
end)

-- ---------------------------------------------------------------------------
-- v4.7.322: `combo_boon`, the ninth BoonInfo field. The only sample of the game's wording is the
-- corruption it left in the tracker's catalogue (GET /boons/export, 2026-09-18):
--   "Combo Boon?:        Yes Gain 25% resistance to cold damage."
-- Every test that swaps shared state restores it BEFORE its assertions and under pcall, so a
-- throwing body cannot leak into the rest of this file.
-- ---------------------------------------------------------------------------
local function withLibrary(lib, fn)
  local saved = M.history.boonLibrary
  M.history.boonLibrary = lib
  local ok, err = pcall(fn)
  local after = M.history.boonLibrary
  M.history.boonLibrary = saved
  if not ok then error(err, 0) end
  return after
end

-- Stubs the contemplate machinery for one `_boonFillNext` run; restores everything it touched.
local function withContemplate(lines, fn)
  local realCap, realTimer, realSend, realSave, realEcho = M._captureContemplate, tempTimer, send, M._historySave, M.echo
  local realContemplating = ataxiaTemp and ataxiaTemp.contemplating
  local realBusy = M._fillBusyAt
  M._fillBusyAt = nil -- a chain another test left half-run must not hold the v4.7.326 lock
  local echoes = {}
  M._captureContemplate = function(cb) cb(type(lines) == "table" and M._parseContemplate(lines) or lines) end
  tempTimer = function(_, f) f(); return 1 end -- run the next step at once
  send = function() end
  M._historySave = function() end
  M.echo = function(m) echoes[#echoes + 1] = tostring(m) end
  local ok, err = pcall(fn)
  M._captureContemplate, tempTimer, send, M._historySave, M.echo = realCap, realTimer, realSend, realSave, realEcho
  ataxiaTemp.contemplating = realContemplating
  M._fillBusyAt = realBusy
  if not ok then error(err, 0) end
  return echoes
end

local AZURE = {
  "Rarity:                 common",
  "Can echo:               Yes",
  "Combo Boon?:        Yes",
  "Gain 25% resistance to cold damage.",
  "",
  '"A line of flavour."',
}

describe("Combo Boon?: -- a label that ends in a question mark", function()
  it("is meta, not the start of the description (the tracker's corruption, reproduced)", function()
    local info = M._parseContemplate({
      "Rarity:                 common",
      "Can echo:               Yes",
      "Maximum echoes:         2",
      "Combo Boon?:        Yes",
      "Gain 25% resistance to cold damage.",
      "",
      '"A line of flavour."',
    })
    expect(info.description).toBe("Gain 25% resistance to cold damage.")
    expect(info.comboBoon).toBeTrue()
    expect(info.meta["Combo Boon?"]).toBe("Yes")
    expect(info.num_echoes_possible).toBe(2)
    expect(info.quote).toBe("A line of flavour.")
  end)

  it("reads No as false -- an answer, not an absence", function()
    local info = M._parseContemplate({ "Rarity: rare", "Combo Boon?: No", "Desc.", "", '"Q."' })
    expect(info.comboBoon).toBeFalse()
    expect(info.description).toBe("Desc.")
  end)

  it("promotes only a spelled-out yes/no", function()
    expect(M._promoteMeta({ meta = { ["Combo Boon?"] = "Sometimes" } }).comboBoon).toBeNil()
    expect(M._promoteMeta({ meta = { ["Combo Boon?"] = "yes." } }).comboBoon).toBeTrue()
    expect(M._promoteMeta({ meta = { ["Combo Boon?"] = " NO " } }).comboBoon).toBeFalse()
    expect(M._promoteMeta({ meta = { ["Combo Boon?"] = "Y" } }).comboBoon).toBeNil()
    expect(M._promoteMeta({ meta = { ["Combo Boon?"] = "true" } }).comboBoon).toBeNil()
  end)

  it("keeps a value already set, and ignores a label never seen", function()
    expect(M._promoteMeta({ comboBoon = false, meta = { ["Combo Boon?"] = "Yes" } }).comboBoon).toBeFalse()
    -- "Combo Boon" (no ?) sorts first; were it promoted it would override the real label.
    expect(M._promoteMeta({ meta = { ["Combo Boon?"] = "Yes", ["Combo Boon"] = "No" } }).comboBoon).toBeTrue()
    expect(M._promoteMeta({ meta = { ["Combo Boon"] = "Yes" } }).comboBoon).toBeNil()
  end)

  it("still refuses prose that merely contains a question mark", function()
    local info = M._parseContemplate({ "Rarity: rare", "Ready? Your crits: doubled.", "", '"Q."' })
    expect(info.description).toBe("Ready? Your crits: doubled.")
    expect(info.meta).toBeNil()
  end)

  it("allows ONE '?' before the colon and no other punctuation", function()
    for _, ln in ipairs({ "Hark!: the tide turns.", "Why??: Because.", "Mr.: Nobody." }) do
      local info = M._parseContemplate({ "Rarity: rare", ln, "", '"Q."' })
      expect(info.description).toBe(ln)
      expect(info.meta).toBeNil()
    end
  end)

  it("keeps the word bound for '?' labels: three words is a label, four is prose", function()
    local three = M._parseContemplate({ "Rarity: rare", "Is Combo Boon?: Yes", "Desc.", "", '"Q."' })
    expect(three.meta["Is Combo Boon?"]).toBe("Yes")
    expect(three.description).toBe("Desc.")
    local four = M._parseContemplate({ "Rarity: rare", "Is This Combo Boon?: Yes", "", '"Q."' })
    expect(four.description).toBe("Is This Combo Boon?: Yes")
    expect(four.meta).toBeNil()
  end)

  -- Unseen, but nothing rules it out: the line printed AFTER the text must not be glued onto it.
  it("a padded label printed after the description is meta too", function()
    local info = M._parseContemplate({ "Rarity: common", "Gain 25% resistance to cold damage.",
      "Combo Boon?:        Yes", "", '"Q."' })
    expect(info.description).toBe("Gain 25% resistance to cold damage.")
    expect(info.comboBoon).toBeTrue()
  end)

  it("...while an unpadded 'Label: text' line in the description stays prose", function()
    local info = M._parseContemplate({ "Rarity: common", "Your blows land harder.",
      "Note: this stays prose.", "", '"Q."' })
    expect(info.description).toBe("Your blows land harder. Note: this stays prose.")
    expect(info.meta).toBeNil()
  end)

  it("does not store the game's 'Unset' as a category", function()
    local info = M._parseContemplate({ "Category:           Unset", "Desc.", "", '"Q."' })
    expect(info.category).toBeNil()
    expect(info.description).toBe("Desc.")
  end)
end)

describe("a screen line glued onto a description", function()
  it("peels the tracker's exact corruptions and our own", function()
    local rest, meta = M._splitGluedMeta("Combo Boon?:        Yes Gain 25% resistance to cold damage.")
    expect(rest).toBe("Gain 25% resistance to cold damage.")
    expect(meta["Combo Boon?"]).toBe("Yes")
    rest, meta = M._splitGluedMeta("Category:           Unset Your aeonics aeon ability can target denizens.")
    expect(rest).toBe("Your aeonics aeon ability can target denizens.")
    expect(meta["Category"]).toBe("Unset")
    -- Deadly Finesse, in the user's catalogue: two WADE STATUS lines and no text at all.
    rest, meta = M._splitGluedMeta("Denizen levels increased by:  70 Denizen speed increased by:   2")
    expect(rest).toBe("")
    expect(meta["Denizen levels increased by"]).toBe("70")
    expect(meta["Denizen speed increased by"]).toBe("2")
  end)

  it("leaves real prose alone -- a single space after a colon is not padding", function()
    for _, d in ipairs({ "Your options are simple: hit harder.", "Gain 25% resistance to cold damage.",
                         "Your fire damage: increased by 15%.", "Warning: this hurts." }) do
      local rest, meta = M._splitGluedMeta(d)
      expect(rest).toBe(d)
      expect(meta).toBeNil()
    end
  end)

  it("_learnBoon never stores it, and keeps what the label said", function()
    local lib = withLibrary({ ["Deadly Finesse"] = { description = "Good text." } }, function()
      M._learnBoon("Azure Scales", "Combo Boon?:        Yes Gain 25% resistance to cold damage.")
      M._learnBoon("Curse of Time", "Category:           Unset Your aeonics aeon ability can target denizens.")
      M._learnBoon("Deadly Finesse", "Denizen levels increased by:  70 Denizen speed increased by:   2")
    end)
    expect(lib["Azure Scales"].description).toBe("Gain 25% resistance to cold damage.")
    expect(lib["Azure Scales"].comboBoon).toBeTrue()
    expect(lib["Curse of Time"].description).toBe("Your aeonics aeon ability can target denizens.")
    expect(lib["Curse of Time"].category).toBeNil()                  -- "Unset" is a placeholder
    expect(lib["Deadly Finesse"].description).toBe("Good text.")      -- garbage never overwrites
  end)

  it("repairs a catalogue saved before this version, once, and says what it did", function()
    local realSave = M._historySave
    M._historySave = function() end
    local n1, names, n2
    local lib = withLibrary({
      ["Deadly Finesse"] = { description = "Denizen levels increased by:  70 Denizen speed increased by:   2" },
      ["Azure Scales"] = { description = "Combo Boon?:        Yes Gain 25% resistance to cold damage." },
      ["Iron Throat"] = { description = "Gain 25% resistance to asphyxiation damage." },
    }, function()
      n1, names = M._boonDbRepair()
      n2 = M._boonDbRepair()
    end)
    M._historySave = realSave
    expect(n1).toBe(2)
    expect(names[1]).toBe("Azure Scales")
    expect(names[2]).toBe("Deadly Finesse")
    expect(n2).toBe(0)                                               -- idempotent
    expect(lib["Deadly Finesse"].description).toBeNil()               -- a gap again, re-learnable
    expect(lib["Azure Scales"].description).toBe("Gain 25% resistance to cold damage.")
    expect(lib["Azure Scales"].comboBoon).toBeTrue()
    expect(lib["Iron Throat"].description).toBe("Gain 25% resistance to asphyxiation damage.")
  end)
end)

describe("the offer screen cannot learn a label as a boon", function()
  it("drops a meta line printed on its own row, and splits one glued to a boon", function()
    local out = M._cleanOfferList({
      { name = "Azure Scales", description = "Combo Boon?:        Yes Gain 25% resistance to cold damage." },
      { name = "Combo Boon?", description = "Yes" },
      { name = "Category", description = "Defence" },
      { name = "Iron Throat", description = "Gain 25% resistance to asphyxiation damage." },
    })
    expect(#out).toBe(2)
    expect(out[1].name).toBe("Azure Scales")
    expect(out[1].description).toBe("Gain 25% resistance to cold damage.")
    expect(out[1].combo_boon).toBeTrue()
    expect(out[2].name).toBe("Iron Throat")
    expect(out[2].combo_boon).toBeNil()
  end)

  -- Through the REAL offer capture, as the game would print it (the v4.7.279 seam test's shape).
  it("the live screen: no fake boon reaches the reroll list or the catalogue", function()
    reset(true)
    local mock = require("mock_mudlet")
    local lib = withLibrary({}, function()
      M._capturing = false
      M.onBoonsOffered()
      for _, ln in ipairs({
        "----------------------------------------",
        "Azure Scales:   Gain 25% resistance to cold damage.",
        "Combo Boon?:        Yes",
        "Iron Throat:    Gain 25% resistance to asphyxiation damage.",
        "Type BOON CLAIM <name> to choose.",
      }) do
        line = ln
        for _, t in pairs(mock.active_triggers) do
          if t.regex and t.pattern == "^.*$" and type(t.callback) == "function" then t.callback() end
        end
      end
    end)
    M._pendingOffer = nil
    expect(#M.run.lastOffered).toBe(2)
    expect(M.run.lastOffered[1]).toBe("Azure Scales")
    expect(M.run.lastOffered[2]).toBe("Iron Throat")
    expect(lib["Combo Boon?"]).toBeNil()
    expect(lib["Azure Scales"].description).toBe("Gain 25% resistance to cold damage.")
  end)
end)

describe("the offer screen: a meta line glued onto a boon", function()
  it("reaches the catalogue as combo status, not as text", function()
    reset(true)
    local mock = require("mock_mudlet")
    local lib = withLibrary({}, function()
      M._capturing = false
      M.onBoonsOffered()
      for _, ln in ipairs({
        "----------------------------------------",
        "Azure Scales:   Combo Boon?:        Yes",
        "Gain 25% resistance to cold damage.",
        "Type BOON CLAIM <name> to choose.",
      }) do
        line = ln
        for _, t in pairs(mock.active_triggers) do
          if t.regex and t.pattern == "^.*$" and type(t.callback) == "function" then t.callback() end
        end
      end
    end)
    M._pendingOffer = nil
    expect(lib["Azure Scales"].description).toBe("Gain 25% resistance to cold damage.")
    expect(lib["Azure Scales"].comboBoon).toBeTrue()
  end)
end)

-- The repair must run on its own at load: nothing else would ever fix a stored corruption.
describe("the catalogue repairs itself when it loads", function()
  it("peels a glued description on load", function()
    local lib = withLibrary({
      ["Deadly Finesse"] = { description = "Denizen levels increased by:  70 Denizen speed increased by:   2" },
    }, function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/007_History.lua")
    end)
    expect(lib["Deadly Finesse"].description).toBeNil()
    expect(M._repairedBoons ~= nil and M._repairedBoons[1]).toBe("Deadly Finesse")
    M._repairedBoons = nil
  end)
end)

describe("comboBoon in the catalogue", function()
  it("_learnBoon stores false as well as true, and nothing else", function()
    local lib = withLibrary({}, function()
      M._learnBoon("Azure Scales", "d", nil, nil, { comboBoon = true })
      M._learnBoon("Iron Throat", "d", nil, nil, { comboBoon = false })
      M._learnBoon("Glass Jaw", "d", nil, nil, { comboBoon = "Yes" })
    end)
    expect(lib["Azure Scales"].comboBoon).toBeTrue()
    expect(lib["Iron Throat"].comboBoon).toBeFalse()
    expect(lib["Glass Jaw"].comboBoon).toBeNil()
  end)

  it("a known No survives a merge and is never overwritten by an import", function()
    local lib = withLibrary({ ["Iron Throat"] = { description = "d", comboBoon = false } }, function()
      M._boonDbMerge({
        ["Iron Throat"] = { description = "d", comboBoon = true },
        ["Azure Scales"] = { description = "d", comboBoon = false },
      })
    end)
    expect(lib["Iron Throat"].comboBoon).toBeFalse()
    expect(lib["Azure Scales"].comboBoon).toBeFalse()
  end)

  it("an import's No fills a record that had no answer", function()
    local enriched
    local lib = withLibrary({ ["Iron Throat"] = { description = "d" } }, function()
      local _, e = M._boonDbMerge({ ["Iron Throat"] = { comboBoon = false } })
      enriched = e
    end)
    expect(lib["Iron Throat"].comboBoon).toBeFalse()
    expect(enriched).toBe(1)
  end)

  it("an import of the wrong type is no value -- and does not block a real one later", function()
    local lib = withLibrary({ ["Stale"] = { description = "d", comboBoon = "yes" } }, function()
      M._boonDbMerge({
        ["Fresh"] = { description = "d", comboBoon = "yes", conflictsWith = { "Glass Jaw", 7, "" } },
        ["Stale"] = { comboBoon = true },
      })
    end)
    expect(lib["Fresh"].comboBoon).toBeNil()
    expect(#lib["Fresh"].conflictsWith).toBe(1)                     -- names only
    expect(lib["Fresh"].conflictsWith[1]).toBe("Glass Jaw")
    expect(lib["Stale"].comboBoon).toBeTrue()                        -- the wrong-typed value was no answer
  end)

  it("the seed marks the ten combo boons, and the merge carries it into the catalogue", function()
    local saveSeed, saveCombo = M.BOON_SEED, M.BOON_COMBO
    local lib = withLibrary({}, function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
    end)
    local combo, seed = M.BOON_COMBO, M.BOON_SEED
    M.BOON_SEED, M.BOON_COMBO = saveSeed or seed, saveCombo or combo
    expect(#combo).toBe(10)
    for _, name in ipairs(combo) do
      expect(seed[name] ~= nil and seed[name].comboBoon).toBeTrue()
      expect(lib[name] ~= nil and lib[name].comboBoon).toBeTrue()
    end
    local n = 0
    for _, rec in pairs(seed) do if rec.comboBoon ~= nil then n = n + 1 end end
    expect(n).toBe(10)                                               -- no boon is seeded as NOT combo
  end)

  it("mnem boondb counts them", function()
    local st
    withLibrary({ A = { comboBoon = true, comboChecked = true }, B = { comboBoon = false }, C = {},
                  D = { contemplatedAt = 5 } },
      function() st = M.boonDbStats() end)
    expect(st.combo).toBe(1)
    expect(st.checked).toBe(2)
  end)
end)

describe("mnem boonfill learns combo status", function()
  it("keeps a contemplate's answer in the catalogue", function()
    local lib = withLibrary({}, function()
      withContemplate({ "Rarity: common", "Combo Boon?: No", "d", "", '"Q."' }, function()
        M._boonFillNext({ "Iron Throat" }, 1, 0)
      end)
    end)
    expect(lib["Iron Throat"] ~= nil).toBeTrue()
    expect(lib["Iron Throat"].comboBoon).toBeFalse()
    expect(lib["Iron Throat"].contemplatedAt ~= nil).toBeTrue()
  end)

  -- The root cause of Deadly Finesse: the capture caught a WADE STATUS block.
  it("learns nothing from a block that is not a contemplate", function()
    local lib = withLibrary({}, function()
      withContemplate({ "Denizen levels increased by:  70", "Denizen speed increased by:   2" }, function()
        M._boonFillNext({ "Deadly Finesse" }, 1, 0)
      end)
    end)
    expect(lib["Deadly Finesse"]).toBeNil()
  end)

  -- v4.7.324 (user: "they constantly change these to be different or add things to them"): a
  -- whole contemplate's text replaces ours, and the change is said out loud.
  it("a whole contemplate rewrites a described boon's text, and says it changed", function()
    local echoes
    local lib = withLibrary({ ["Azure Scales"] = { description = "Gain 10% resistance to cold damage." } }, function()
      echoes = withContemplate(AZURE, function()
        M._boonFillNext({ "Azure Scales" }, 1, 0, M._fillCtx({ ["Azure Scales"] = true }))
      end)
    end)
    expect(lib["Azure Scales"].description).toBe("Gain 25% resistance to cold damage.")
    expect(lib["Azure Scales"].comboBoon).toBeTrue()
    expect(lib["Azure Scales"].quote).toBe("A line of flavour.")
    expect(lib["Azure Scales"].contemplatedAt ~= nil).toBeTrue()
    expect(table.concat(echoes, "\n"):find("Azure Scales changed", 1, true) ~= nil).toBeTrue()
  end)

  it("an unchanged text is not reported as a change", function()
    local echoes
    withLibrary({ ["Azure Scales"] = { description = "Gain 25%  resistance to cold damage." } }, function()
      echoes = withContemplate(AZURE, function()
        M._boonFillNext({ "Azure Scales" }, 1, 0, M._fillCtx({ ["Azure Scales"] = true }))
      end)
    end)
    expect(table.concat(echoes, "\n"):find("Azure Scales changed", 1, true)).toBeNil()
  end)

  -- A block cut short (a timeout, or another capture force-finishing it) is not the whole text.
  it("a contemplate that did not end on its closing divider changes nothing", function()
    local realCap = M._captureContemplate
    local lib
    local ok, err = pcall(function()
      lib = withLibrary({ ["Azure Scales"] = { description = "Old text." } }, function()
        withContemplate(AZURE, function()
          M._captureContemplate = function(cb)
            local info = M._parseContemplate({ "Rarity: common", "Gain 25% resistance" })
            info.complete = false
            cb(info)
          end
          M._boonFillNext({ "Azure Scales" }, 1, 0, M._fillCtx({ ["Azure Scales"] = true }))
        end)
      end)
    end)
    M._captureContemplate = realCap
    if not ok then error(err, 0) end
    expect(lib["Azure Scales"].description).toBe("Old text.")
    expect(lib["Azure Scales"].contemplatedAt).toBeNil()
  end)

  it("the whole catalogue is the queue: never-contemplated first (seeded combo first), then the stalest", function()
    local gaps
    withLibrary({
      ["Zeal"] = { description = "d" },
      ["Azure Scales"] = { description = "d", comboBoon = true },
      ["Alpha"] = { description = "d" },
      ["Recent"] = { description = "d", contemplatedAt = 2000 },
      ["Stale"] = { description = "d", contemplatedAt = 1000 },
      ["Legacy"] = { description = "d", comboChecked = true },   -- v4.7.322's mark: long ago
      ["(ECHO) Zeal"] = { description = "d" },
      ["No Text"] = {},
    }, function() gaps = M.boonMetaGaps() end)
    expect(#gaps).toBe(6)
    expect(gaps[1]).toBe("Azure Scales")
    expect(gaps[2]).toBe("Alpha")
    expect(gaps[3]).toBe("Zeal")
    expect(gaps[4]).toBe("Legacy")
    expect(gaps[5]).toBe("Stale")
    expect(gaps[6]).toBe("Recent")
  end)

  it("takes description gaps first and fills the batch from the combo pass", function()
    local realNext, realGaps, realEcho = M._boonFillNext, M.boonGaps, M.echo
    local got
    M._boonFillNext = function(todo, i, learned, ctx) got = { todo = todo, ctx = ctx } end
    M.boonGaps = function() return { "Hole One", "Hole Two" } end
    M.echo = function() end
    local realBusy = M._fillBusyAt
    M._fillBusyAt = nil
    local ok, err = pcall(function()
      withLibrary({ ["Alpha"] = { description = "d" }, ["Beta"] = { description = "d" } },
        function() M.boonFill(3) end)
    end)
    M._boonFillNext, M.boonGaps, M.echo, M._fillBusyAt = realNext, realGaps, realEcho, realBusy
    if not ok then error(err, 0) end
    expect(#got.todo).toBe(3)
    expect(got.todo[1]).toBe("Hole One")
    expect(got.todo[2]).toBe("Hole Two")
    expect(got.todo[3]).toBe("Alpha")
    expect(got.ctx.meta["Alpha"]).toBeTrue()
    expect(got.ctx.meta["Hole One"]).toBeNil()
  end)

  -- The open question the pass exists to settle: does CONTEMPLATE print the line at all?
  it("says so when a seeded combo boon's contemplate had no combo line", function()
    local echoes
    withLibrary({ ["Azure Scales"] = { description = "d", comboBoon = true } }, function()
      echoes = withContemplate({ "Rarity: common", "Gain 25% resistance to cold damage.", "", '"Q."' },
        function()
          M._boonFillNext({ "Azure Scales" }, 1, 0, M._fillCtx({ ["Azure Scales"] = true }))
        end)
    end)
    local said = table.concat(echoes, "\n")
    expect(said:find("No 'Combo Boon?' line on Azure Scales", 1, true) ~= nil).toBeTrue()
  end)

  it("end to end: raw CONTEMPLATE lines -> catalogue -> /boons_offered carries combo_boon", function()
    reset(true)
    withLibrary({}, function()
      withContemplate(AZURE, function() M._boonFillNext({ "Azure Scales" }, 1, 0) end)
      M.reportBoonsOffered({ { name = "Azure Scales", description = "Gain 25% resistance to cold damage." } })
    end)
    expect(sent[1].payload.offered[1].combo_boon).toBeTrue()
  end)
end)

describe("mnem boonfill recheck", function()
  it("clears the contemplated mark so the pass asks again, and keeps the answers", function()
    local realSoon = M._historySaveSoon
    M._historySaveSoon = function() end
    local n, gaps
    local lib = withLibrary({
      ["Azure Scales"] = { description = "d", comboBoon = true, comboChecked = true },
      ["Iron Throat"] = { description = "d", contemplatedAt = 5 },
      ["Glass Jaw"] = { description = "d" },
    }, function()
      n = M.boonRecheck()
      gaps = M.boonMetaGaps()
    end)
    M._historySaveSoon = realSoon
    expect(n).toBe(2)
    expect(lib["Azure Scales"].comboChecked).toBeNil()
    expect(lib["Iron Throat"].contemplatedAt).toBeNil()                 -- the cycle starts over
    expect(lib["Azure Scales"].comboBoon).toBeTrue()                   -- the answer stays
    expect(#gaps).toBe(3)
  end)

  it("is reachable as a command", function()
    local realEcho, realSoon, said = M.echo, M._historySaveSoon, nil
    M.echo = function(m) said = tostring(m) end
    M._historySaveSoon = function() end
    local lib = withLibrary({ ["Iron Throat"] = { description = "d", comboChecked = true } }, function()
      M.command("boonfill recheck")
    end)
    M.echo, M._historySaveSoon = realEcho, realSoon
    expect(lib["Iron Throat"].comboChecked).toBeNil()
    expect(said ~= nil and said:find("1", 1, true) ~= nil).toBeTrue()
  end)
end)

describe("every offered boon is contemplated, every screen (v4.7.324)", function()
  -- Records the contemplates a run sends; each capture answers with a whole block. Timers are
  -- QUEUED and run in order after the call returns, as Mudlet runs them -- firing them inline would
  -- reverse the order of the sends and hide the wait-for-the-slot path.
  local function run(lib, fn)
    local asked, queue, said, delays = {}, {}, {}, {}
    local realCap, realTimer, realSend, realSave, realEcho = M._captureContemplate, tempTimer, send, M._historySave, M.echo
    local realContemplating = ataxiaTemp and ataxiaTemp.contemplating
    local realBusy = M._fillBusyAt
    M._fillBusyAt = nil
    M._captureContemplate = function(cb)
      cb(M._parseContemplate({ "Rarity: common", "Some text.", "", '"Q."' }))
    end
    tempTimer = function(d, f) queue[#queue + 1] = f; delays[#delays + 1] = d; return #queue end
    send = function(c) local n = c:match("^boon contemplate (.+)$"); if n then asked[#asked + 1] = n end end
    M._historySave = function() end
    M.echo = function(m) said[#said + 1] = tostring(m) end
    local out
    local ok, err = pcall(function()
      out = withLibrary(lib, function()
        fn()
        local guard = 0
        while #queue > 0 and guard < 200 do guard = guard + 1; table.remove(queue, 1)() end
      end)
    end)
    M._captureContemplate, tempTimer, send, M._historySave, M.echo = realCap, realTimer, realSend, realSave, realEcho
    ataxiaTemp.contemplating = realContemplating
    M._fillBusyAt = realBusy
    if not ok then error(err, 0) end
    return asked, out, said, delays
  end

  it("contemplates each offered boon -- echoes as their base boon -- plus one gap", function()
    local realGaps = M.boonGaps
    M.boonGaps = function() return { "Hole" } end
    local asked
    local ok, err = pcall(function()
      asked = run({ ["Desperation"] = { description = "d" }, ["Restoration"] = { description = "d" } }, function()
        M._capturing = false
        M._boonScreenContemplate({ { name = "Desperation" }, { name = "(ECHO) Restoration" },
                                   { name = "Berkana Surround" }, { name = "Desperation" } })
      end)
    end)
    M.boonGaps = realGaps
    if not ok then error(err, 0) end
    expect(#asked).toBe(4)
    expect(asked[1]).toBe("Desperation")
    expect(asked[2]).toBe("Restoration")
    expect(asked[3]).toBe("Berkana Surround")
    expect(asked[4]).toBe("Hole")
  end)

  -- It runs after EVERY offer screen, so it must not narrate a run that found nothing new.
  it("stays quiet when nothing changed, and speaks when something did", function()
    local realGaps = M.boonGaps
    M.boonGaps = function() return {} end -- no description gap rides along this time
    local ok, err = pcall(function()
      local _, _, said = run({ ["Desperation"] = { description = "Some text." } }, function()
        M._capturing = false
        M._boonScreenContemplate({ { name = "Desperation" } })
      end)
      local _, _, said2 = run({ ["Desperation"] = { description = "Old text." } }, function()
        M._capturing = false
        M._boonScreenContemplate({ { name = "Desperation" } })
      end)
      local quiet, loud = table.concat(said, "\n"), table.concat(said2, "\n")
      expect(quiet:find("Boon catalogue updated", 1, true)).toBeNil()
      expect(loud:find("Desperation changed", 1, true) ~= nil).toBeTrue()
      expect(loud:find("Boon catalogue updated", 1, true) ~= nil).toBeTrue()
    end)
    M.boonGaps = realGaps
    if not ok then error(err, 0) end
  end)

  it("never starts while another capture holds the slot", function()
    local asked = run({}, function()
      M._capturing = true
      expect(M._boonScreenContemplate({ { name = "Desperation" } })).toBeFalse()
      M._capturing = false
    end)
    expect(#asked).toBe(0)
  end)

  it("stops at GO! -- the next wave's captures own the slot", function()
    local asked = run({}, function()
      M._capturing = false
      local realCap = M._captureContemplate
      M._captureContemplate = function(cb)
        M._fillGen = (M._fillGen or 0) + 1 -- GO! lands while the first block is being read
        realCap(cb)
      end
      M._boonScreenContemplate({ { name = "A" }, { name = "B" }, { name = "C" } })
    end)
    expect(#asked).toBe(1)
  end)

  it("waits for another capture rather than cutting it short, then gives up", function()
    local asked, _, _, delays = run({}, function()
      M._capturing = false
      local realCap = M._captureContemplate
      M._captureContemplate = function(cb)
        realCap(cb)
        M._capturing = true -- a WADE STATUS capture takes the slot after the first block
      end
      M._boonScreenContemplate({ { name = "A" }, { name = "B" } })
    end)
    M._capturing = false
    expect(#asked).toBe(1)
    local waits = 0
    for _, d in ipairs(delays) do if d == 1 then waits = waits + 1 end end
    expect(waits).toBe(5) -- five one-second waits, then it stops rather than spin
  end)

  it("GO! moves the wave counter", function()
    local before = M._fillGen or 0
    M.onGo()
    expect(M._fillGen).toBe(before + 1)
  end)

  it("the posted offer schedules it, with that offer's boons", function()
    reset(true)
    local realScreen, realTimer = M._boonScreenContemplate, tempTimer
    local got
    M._boonScreenContemplate = function(list) got = list end
    tempTimer = function(_, f) f(); return 1 end
    local ok, err = pcall(function()
      M._pendingOffer = { { name = "Desperation", description = "d" } }
      M._flushPendingOffer("test")
    end)
    M._boonScreenContemplate, tempTimer = realScreen, realTimer
    if not ok then error(err, 0) end
    expect(got ~= nil and got[1].name).toBe("Desperation")
  end)

  it("the capture says whether the block ended on its closing divider", function()
    local mock = require("mock_mudlet")
    local function feed(lines)
      for _, ln in ipairs(lines) do
        line = ln
        for _, t in pairs(mock.active_triggers) do
          if t.regex and t.pattern == "^.*$" and type(t.callback) == "function" then t.callback() end
        end
      end
    end
    M._capturing = false
    local whole
    M._captureContemplate(function(info) whole = info end)
    feed({ "Azure Scales:", "----------", "Rarity: common", "Gain 25% resistance.", "----------" })
    expect(whole ~= nil and whole.complete).toBeTrue()
    local cut
    M._captureContemplate(function(info) cut = info end)
    feed({ "Azure Scales:", "----------", "Rarity: common", "Gain 25%" })
    M._captureForceFinish()
    expect(cut ~= nil and cut.complete).toBeFalse()
  end)
end)

-- ---------------------------------------------------------------------------
-- v4.7.325: boon conflicts. User, with a BOON CONTEMPLATE block: "This should be echo the
-- conflicts and highlight them."
-- ---------------------------------------------------------------------------
local CARELESS = {
  "Rarity:             rare",
  "Category:           Utility",
  "Can echo:           No",
  "Conflicts With:     Self-Preservation and Truther",
  "",
  "You are immune to masochism, hallucinations, and paranoia, and you always walk with a zealous warding against the Outer ",
  "Cold.",
  "",
  '"With a whisper, the blaze lit up the heavens, and all that dwelt in dark beneath the sky was scourged clean."',
}

describe("the Conflicts With line", function()
  it("parses the user's Careless Whisperer block", function()
    local info = M._parseContemplate(CARELESS)
    expect(info.rarity).toBe("rare")
    expect(info.category).toBe("Utility")
    expect(info.num_echoes_possible).toBe(0)
    expect(#info.conflictsWith).toBe(2)
    expect(info.conflictsWith[1]).toBe("Self-Preservation")
    expect(info.conflictsWith[2]).toBe("Truther")
    expect(info.description).toBe("You are immune to masochism, hallucinations, and paranoia, and you always walk "
      .. "with a zealous warding against the Outer Cold.")
    expect(info.quote:find("With a whisper", 1, true) == 1).toBeTrue()
  end)

  it("keeps a boon name that has ' and ' inside it", function()
    local known = { ["Hammer and Anvil"] = true, ["Truther"] = true }
    local names = M._splitBoonList("Hammer and Anvil and Truther", known)
    expect(#names).toBe(2)
    expect(names[1]).toBe("Hammer and Anvil")
    expect(names[2]).toBe("Truther")
    local oxford = M._splitBoonList("Brute Force, Deadly Finesse, and Mental Prowess.", {})
    expect(#oxford).toBe(3)
    expect(oxford[3]).toBe("Mental Prowess")
  end)

  it("takes a wrapped list's tail only while it is still boon names", function()
    local lib = withLibrary({ Alpha = { description = "d" }, Beta = { description = "d" },
                              ["Gamma Ray"] = { description = "d" } }, function()
      local info = M._parseContemplate({ "Rarity: rare", "Conflicts With:     Alpha, Beta and", "Gamma Ray",
        "", "Your blows land harder.", "", '"Q."' })
      expect(#info.conflictsWith).toBe(3)
      expect(info.conflictsWith[3]).toBe("Gamma Ray")
      expect(info.description).toBe("Your blows land harder.")
      -- the older layout, with no blank line: the description is NOT swallowed into the list
      local old = M._parseContemplate({ "Rarity: rare", "Conflicts With:     Alpha", "Your blows land harder." })
      expect(#old.conflictsWith).toBe(1)
      expect(old.description).toBe("Your blows land harder.")
    end)
  end)

  it("reads 'None' as no conflicts", function()
    expect(M._parseContemplate({ "Rarity: rare", "Conflicts With: None", "Desc." }).conflictsWith).toBeNil()
  end)

  it("mnem boonfill stores the list, and the tracker gets it", function()
    reset(true)
    local lib = withLibrary({}, function()
      withContemplate(CARELESS, function() M._boonFillNext({ "Careless Whisperer" }, 1, 0) end)
      M.reportBoonsOffered({ { name = "Careless Whisperer" } })
    end)
    expect(lib["Careless Whisperer"].conflictsWith[2]).toBe("Truther")
    expect(sent[1].payload.offered[1].conflicts_with[1]).toBe("Self-Preservation")
  end)
end)

-- Swap the seed for one test; put it back even if the body throws.
local function withSeed(seed, fn)
  local saved = M.BOON_SEED
  M.BOON_SEED = seed
  local ok, err = pcall(fn)
  M.BOON_SEED = saved
  if not ok then error(err, 0) end
end

describe("conflicts are echoed and highlighted", function()
  -- A run in which we claimed Truther.
  local function holding(fn)
    local savedClaims, savedRun, savedActive = M.history.claims, M.history.run, M.run and M.run.active
    M.history.claims = { { name = "Truther", run = 7 } }
    M.history.run = 7
    M.run = M.run or {}
    M.run.active = true
    local ok, err = pcall(fn)
    M.history.claims, M.history.run, M.run.active = savedClaims, savedRun, savedActive
    if not ok then error(err, 0) end
  end
  local function capture(fn)
    local said, realEcho = {}, M.echo
    M.echo = function(m) said[#said + 1] = tostring(m) end
    local ok, err = pcall(fn)
    M.echo = realEcho
    if not ok then error(err, 0) end
    return table.concat(said, "\n")
  end

  it("the contemplate line: every name highlighted, the one we hold in red", function()
    local picked = {}
    local realSel, realFg = selectString, fg
    local current
    selectString = function(s) current = s; return 1 end
    fg = function(c) picked[current] = c end
    local out
    local ok, err = pcall(function()
      holding(function() out = capture(function() M.onConflictsLine("Self-Preservation and Truther"); M._calloutFlush() end) end)
    end)
    selectString, fg = realSel, realFg
    if not ok then error(err, 0) end
    expect(picked["Truther"]).toBe("red")
    expect(picked["Self-Preservation"]).toBe("gold") -- the summary's colour for a name we do not hold
    expect(out:find("CONFLICT", 1, true) ~= nil).toBeTrue()
    expect(out:find("Truther<reset> (you have it)", 1, true) ~= nil).toBeTrue()
  end)

  it("only THIS run's claims count as held -- not an earlier run's, not outside a run", function()
    local outside, earlier
    holding(function()
      M.run.active = false -- the claim is this run's, but no run is going
      outside = capture(function() M.onConflictsLine("Self-Preservation and Truther"); M._calloutFlush() end)
      M.run.active = true
      M.history.claims = { { name = "Truther", run = 6 } } -- claimed in an earlier run
      earlier = capture(function() M.onConflictsLine("Self-Preservation and Truther"); M._calloutFlush() end)
    end)
    expect(outside:find("you have it", 1, true)).toBeNil()
    expect(outside:find("conflicts with", 1, true) ~= nil).toBeTrue()
    expect(earlier:find("you have it", 1, true)).toBeNil()
  end)

  it("says nothing for 'None'", function()
    expect(capture(function() M.onConflictsLine("None."); M._calloutFlush() end)).toBe("")
  end)

  it("the offer screen warns, from either side of the pair", function()
    local out
    withLibrary({ ["Careless Whisperer"] = { description = "d", conflictsWith = { "Self-Preservation", "Truther" } },
                  ["Truther"] = { description = "d" },
                  ["Glass Jaw"] = { description = "d" },
                  ["Iron Throat"] = { description = "d", conflictsWith = { "Glass Jaw" } } }, function()
      holding(function()
        withSeed({}, function() -- no seed echo text, so only conflicts are called out
          out = capture(function()
            M._echoBoonCallouts({ { name = "Careless Whisperer" }, { name = "Self-Preservation" }, { name = "Glass Jaw" } })
          end)
        end)
      end)
    end)
    expect(out:find("CONFLICT<reset> -- <gold>Careless Whisperer", 1, true) ~= nil).toBeTrue()
    expect(out:find("Self-Preservation<reset> (also offered)", 1, true) ~= nil).toBeTrue()
    expect(out:find("Glass Jaw", 1, true) == nil).toBeTrue() -- Iron Throat is not held or offered
  end)

  it("a held boon's own list warns about an offered one the catalogue has no list for", function()
    local out
    withLibrary({ ["Truther"] = { description = "d", conflictsWith = { "Careless Whisperer" } },
                  ["Careless Whisperer"] = { description = "d" } }, function()
      holding(function()
        withSeed({}, function() out = capture(function() M._echoBoonCallouts({ { name = "Careless Whisperer" } }) end) end)
      end)
    end)
    expect(out:find("Truther<reset> (you have it)", 1, true) ~= nil).toBeTrue()
  end)

  it("the live offer screen runs it", function()
    reset(true)
    local mock = require("mock_mudlet")
    local out
    withLibrary({ ["Careless Whisperer"] = { description = "d", conflictsWith = { "Truther" } } }, function()
      holding(function()
        out = capture(function()
          M._capturing = false
          M.onBoonsOffered()
          for _, ln in ipairs({ "----------------------------------------",
                                "Careless Whisperer:   You are immune to masochism.",
                                "Type BOON CLAIM <name> to choose." }) do
            line = ln
            for _, tr in pairs(mock.active_triggers) do
              if tr.regex and tr.pattern == "^.*$" and type(tr.callback) == "function" then tr.callback() end
            end
          end
        end)
      end)
    end)
    M._pendingOffer = nil
    expect(out:find("CONFLICT", 1, true) ~= nil).toBeTrue()
  end)

  it("trigger 092 feeds the line to the module", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/092_Boon_Conflicts.lua")
    local src = f:read("*a"); f:close()
    expect(src:find("- pattern: ^Conflicts [Ww]ith:\\s+(.+)$", 1, true) ~= nil).toBeTrue()
    expect(src:find("M.onConflictsLine(matches[2])", 1, true) ~= nil).toBeTrue()
  end)
end)

-- ---------------------------------------------------------------------------
-- v4.7.326: combo and echo called out. User, with Flameheart's block: "Also should called out if
-- the boon can combo and echo."
-- ---------------------------------------------------------------------------
local FLAMEHEART = {
  "Rarity:             uncommon",
  "Category:           Utility",
  "Combo Boon?:        Yes",
  "Can echo:           No",
  "",
  "You are immune to the frozen affliction.",
  "",
  '"His hatred burned like fire, swathing the icy loathing in his heart."',
}

describe("contemplate call-outs: combo, echo, conflicts", function()
  local function capture(fn)
    local said, realEcho = {}, M.echo
    M.echo = function(m) said[#said + 1] = tostring(m) end
    local ok, err = pcall(fn)
    M.echo = realEcho
    if not ok then error(err, 0) end
    return table.concat(said, "\n")
  end
  local function feed(lines)
    M._callout, M._calloutT = nil, nil -- nothing left over from another test
    for _, ln in ipairs(lines) do
      if ln:find("^Conflicts") then M.onConflictsLine(ln:match(":%s+(.+)$")) else M.onCalloutLine(ln) end
    end
    M._calloutFlush()
  end

  it("parses Flameheart: the Combo Boon? line is CONTEMPLATE's", function()
    local info = M._parseContemplate(FLAMEHEART)
    expect(info.comboBoon).toBeTrue()
    expect(info.category).toBe("Utility")
    expect(info.num_echoes_possible).toBe(0)
    expect(info.description).toBe("You are immune to the frozen affliction.")
  end)

  it("a combo boon that cannot echo: one line, says COMBO, says nothing about echoing", function()
    local out = capture(function() feed(FLAMEHEART) end)
    expect(out:find("COMBO boon", 1, true) ~= nil).toBeTrue()
    expect(out:find("echo", 1, true)).toBeNil()
    local lines = 0
    for _ in out:gmatch("[^\n]+") do lines = lines + 1 end
    expect(lines).toBe(1)
  end)

  it("an echoing boon with conflicts: every call-out, in one line, in a fixed order", function()
    local out = capture(function()
      feed({ "Rarity: rare", "Combo Boon?:        Yes", "Can echo:           Yes", "Maximum echoes:     3",
             "Conflicts With:     Self-Preservation and Truther" })
    end)
    local c, e, x = out:find("COMBO", 1, true), out:find("can echo (max 3)", 1, true), out:find("conflicts with", 1, true)
    expect(c ~= nil and e ~= nil and x ~= nil).toBeTrue()
    expect(c < e and e < x).toBeTrue()
  end)

  -- The user's Elder Wisdom block (2026-09-19): "maxiumum echos also".
  it("Elder Wisdom: combo, and the maximum echo count, from the real block", function()
    local ELDER = {
      "Rarity:             common",
      "Category:           Offence",
      "Combo Boon?:        Yes",
      "Can echo:           Yes",
      "Maximum echoes:     5",
      "",
      "The Jade Empress increases your intelligence by 1.",
      "",
      '"It is the curse of the wise to be correct while the oblivious ignore your words."',
    }
    local info = M._parseContemplate(ELDER)
    expect(info.comboBoon).toBeTrue()
    expect(info.num_echoes_possible).toBe(5)
    expect(info.category).toBe("Offence")
    expect(info.description).toBe("The Jade Empress increases your intelligence by 1.")
    local picked = {}
    local realSel, realFg, current = selectString, fg, nil
    selectString = function(s) current = s; return 1 end
    fg = function(c) picked[current] = c end
    local out
    local ok, err = pcall(function() out = capture(function() feed(ELDER) end) end)
    selectString, fg = realSel, realFg
    if not ok then error(err, 0) end
    expect(out:find("COMBO boon<reset>; <cyan>can echo (max 5)", 1, true) ~= nil).toBeTrue()
    expect(picked["5"]).toBe("cyan")
    -- ...and once contemplated, the offer screen says the same
    local offer
    withLibrary({}, function()
      M._learnBoon("Elder Wisdom", info.description, info.rarity, info.num_echoes_possible,
        { comboBoon = info.comboBoon })
      offer = capture(function() M._echoBoonCallouts({ { name = "Elder Wisdom" } }) end)
    end)
    expect(offer:find("COMBO boon<reset>; <cyan>can echo (max 5)", 1, true) ~= nil).toBeTrue()
  end)

  it("'Can echo: Yes' alone still says so", function()
    expect(capture(function() feed({ "Can echo:           Yes" }) end):find("can echo", 1, true) ~= nil).toBeTrue()
  end)

  it("nothing to call out prints nothing", function()
    expect(capture(function() feed({ "Rarity: common", "Combo Boon?:        No", "Can echo:           No" }) end)).toBe("")
  end)

  it("highlights the Yes and the echo count in place", function()
    local picked = {}
    local realSel, realFg, current = selectString, fg, nil
    selectString = function(s) current = s; return 1 end
    fg = function(c) picked[current] = c end
    local ok, err = pcall(function()
      capture(function() feed({ "Combo Boon?:        Yes", "Maximum echoes:     3" }) end)
    end)
    selectString, fg = realSel, realFg
    if not ok then error(err, 0) end
    expect(picked["Yes"]).toBe("green")
    expect(picked["3"]).toBe("cyan")
  end)

  it("the offer screen calls them out from the catalogue", function()
    local out
    withLibrary({ ["Flameheart"] = { description = "d", comboBoon = true, maxEchoes = 0 },
                  ["Iron Throat"] = { description = "d", maxEchoes = 2 },
                  ["Plain"] = { description = "d" } }, function()
      withSeed({}, function()
        out = capture(function()
          M._echoBoonCallouts({ { name = "Flameheart" }, { name = "Iron Throat" }, { name = "Plain" } })
        end)
      end)
    end)
    expect(out:find("<gold>Flameheart<reset> -- <pale_green>COMBO boon", 1, true) ~= nil).toBeTrue()
    expect(out:find("<gold>Iron Throat<reset> -- <cyan>can echo (max 2)", 1, true) ~= nil).toBeTrue()
    expect(out:find("Plain", 1, true)).toBeNil()
    expect(out:find("Flameheart<reset> -- <pale_green>COMBO boon<reset>; <cyan>can echo", 1, true)).toBeNil()
  end)

  it("trigger 093 feeds the three meta lines and both block boundaries to the module", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/093_Boon_Callouts.lua")
    local src = f:read("*a"); f:close()
    expect(src:find("- pattern: ^Combo Boon\\?:\\s+(\\w+)", 1, true) ~= nil).toBeTrue()
    expect(src:find("- pattern: ^Can echo:\\s+(\\w+)", 1, true) ~= nil).toBeTrue()
    expect(src:find("- pattern: ^Maximum echoes:\\s+(\\d+)", 1, true) ~= nil).toBeTrue()
    expect(src:find("M.onCalloutLine(line)", 1, true) ~= nil).toBeTrue()
    expect(src:find("- pattern: ^Rarity:\\s+", 1, true) ~= nil).toBeTrue()
    expect(src:find("- pattern: ^-{3,}", 1, true) ~= nil).toBeTrue()
  end)

  -- The grep above passes a commented-out call; this runs the trigger body.
  it("trigger 093's body really hands `line` to M.onCalloutLine", function()
    local got, realOn, savedLine, savedAtaxia = {}, M.onCalloutLine, line, ataxia
    M.onCalloutLine = function(ln) got[#got + 1] = ln end
    ataxia = { mnemosyne = M }
    line = "Combo Boon?:        Yes"
    local ok, err = pcall(dofile, "src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/093_Boon_Callouts.lua")
    M.onCalloutLine, line, ataxia = realOn, savedLine, savedAtaxia
    if not ok then error(err, 0) end
    expect(#got).toBe(1)
    expect(got[1]).toBe("Combo Boon?:        Yes")
  end)

  -- The review's worry: the call-outs are module-global, and a chain sends the next contemplate
  -- 0.5s after the last one closed. Each block must get its own line, under its own boon.
  it("two blocks back to back: the divider and the next Rarity keep their summaries apart", function()
    local realT = tempTimer
    tempTimer = function() return 1 end -- the quiet timer never fires: only the boundaries print
    local out
    local ok, err = pcall(function()
      M._callout, M._calloutT = nil, nil
      out = capture(function()
        for _, ln in ipairs({ "Rarity:             uncommon", "Combo Boon?:        Yes", "Can echo:           No",
                              "--------------------------------------------------------------------------------",
                              "Rarity:             common", "Combo Boon?:        No", "Can echo:           Yes",
                              "Maximum echoes:     2" }) do
          M.onCalloutLine(ln)
        end
        -- no closing divider on the second: the next block's Rarity line closes it
        M.onCalloutLine("Rarity:             rare")
      end)
    end)
    tempTimer = realT
    M._callout, M._calloutT = nil, nil
    if not ok then error(err, 0) end
    local lines = {}
    for l in out:gmatch("[^\n]+") do lines[#lines + 1] = l end
    expect(#lines).toBe(2)
    expect(lines[1]:find("COMBO", 1, true) ~= nil and lines[1]:find("echo", 1, true) == nil).toBeTrue()
    expect(lines[2]:find("can echo (max 2)", 1, true) ~= nil and lines[2]:find("COMBO", 1, true) == nil).toBeTrue()
  end)

  it("a boundary with nothing gathered prints nothing, and a flush takes its timer with it", function()
    M._callout, M._calloutT = nil, nil
    expect(capture(function() M.onCalloutLine("----------------------------------------") end)).toBe("")
    expect(capture(function() M.onCalloutLine("Rarity:             common") end)).toBe("")
    local killed, realK = {}, killTimer
    killTimer = function(id) killed[#killed + 1] = id end
    local ok, err = pcall(function()
      capture(function()
        M.onCalloutLine("Combo Boon?:        Yes")
        local id = M._calloutT
        M.onCalloutLine("----------------------------------------")
        expect(M._calloutT).toBeNil()
        expect(killed[#killed]).toBe(id)
      end)
    end)
    killTimer = realK
    M._callout, M._calloutT = nil, nil
    if not ok then error(err, 0) end
  end)

  -- The backstop, on a virtual clock: blocks at the chain's pace with no boundary lines at all.
  it("the quiet window alone still gives one summary per block at the chain's pace", function()
    local now, q, delays = 0, {}, {}
    local realT, realK = tempTimer, killTimer
    tempTimer = function(d, f) delays[#delays + 1] = d; q[#q + 1] = { at = now + d, f = f }; return #q end
    killTimer = function(id) if q[id] then q[id].dead = true end end
    local function advance(dt)
      now = now + dt
      for _, tm in ipairs(q) do if not tm.dead and not tm.done and tm.at <= now then tm.done = true; tm.f() end end
    end
    local out
    local ok, err = pcall(function()
      M._callout, M._calloutT = nil, nil
      out = capture(function()
        M.onCalloutLine("Combo Boon?:        Yes"); M.onCalloutLine("Can echo:           No")
        advance(0.6)
        M.onCalloutLine("Combo Boon?:        No"); M.onCalloutLine("Can echo:           Yes")
        M.onCalloutLine("Maximum echoes:     2")
        advance(0.6)
      end)
    end)
    tempTimer, killTimer = realT, realK
    M._callout, M._calloutT = nil, nil
    if not ok then error(err, 0) end
    local lines = {}
    for l in out:gmatch("[^\n]+") do lines[#lines + 1] = l end
    expect(#lines).toBe(2)
    expect(lines[1]:find("COMBO", 1, true) ~= nil and lines[1]:find("echo", 1, true) == nil).toBeTrue()
    expect(lines[2]:find("can echo (max 2)", 1, true) ~= nil and lines[2]:find("COMBO", 1, true) == nil).toBeTrue()
    for _, d in ipairs(delays) do expect(d > 0 and d < 0.5).toBeTrue() end
  end)

  it("'Maximum echoes' first, then 'Can echo: Yes' -- the count survives", function()
    local out = capture(function()
      M._callout, M._calloutT = nil, nil
      M.onCalloutLine("Maximum echoes:     4"); M.onCalloutLine("Can echo:           Yes"); M._calloutFlush()
    end)
    expect(out:find("can echo (max 4)", 1, true) ~= nil).toBeTrue()
  end)

  it("no echo count in the catalogue: the seed's echo text still says 'can echo'", function()
    local out, zero
    withLibrary({ ["Argent Scales"] = { description = "d" }, ["Bare"] = { description = "d", maxEchoes = 0 } }, function()
      withSeed({ ["Argent Scales"] = { description = "d", echo = "Gain 50% resistance to electric damage." },
                 ["Bare"] = { description = "d", echo = "x" } }, function()
        out = capture(function() M._echoBoonCallouts({ { name = "Argent Scales" } }) end)
        zero = capture(function() M._echoBoonCallouts({ { name = "Bare" } }) end)
      end)
    end)
    expect(out:find("<gold>Argent Scales<reset> -- <cyan>can echo<reset>.", 1, true) ~= nil).toBeTrue()
    expect(zero).toBe("") -- a contemplated "Can echo: No" (maxEchoes 0) outranks the seed's text
  end)

  it("an '(ECHO) Name' offer is called out from its base boon's record", function()
    local out
    withLibrary({ ["Elder Wisdom"] = { description = "d", comboBoon = true, maxEchoes = 5 } }, function()
      out = capture(function() M._echoBoonCallouts({ { name = "(ECHO) Elder Wisdom" } }) end)
    end)
    expect(out:find("<gold>Elder Wisdom<reset> -- <pale_green>COMBO boon<reset>; <cyan>can echo (max 5)", 1, true) ~= nil).toBeTrue()
  end)
end)

-- ---------------------------------------------------------------------------
-- v4.7.326 review: "Can echo: Yes" with no "Maximum echoes" line parses as 1 -- a FLOOR, which the
-- offer screen then printed as "(max 1)", a count the game never gave.
-- ---------------------------------------------------------------------------
describe("the echo floor", function()
  local function capture(fn)
    local said, realEcho = {}, M.echo
    M.echo = function(m) said[#said + 1] = tostring(m) end
    local ok, err = pcall(fn)
    M.echo = realEcho
    if not ok then error(err, 0) end
    return table.concat(said, "\n")
  end

  it("is marked only when no count was printed, whichever line comes first", function()
    local bare = M._parseContemplate({ "Rarity:             common", "Can echo:           Yes", "", "Desc." })
    expect(bare.num_echoes_possible).toBe(1)
    expect(bare.echoFloor).toBeTrue()
    local counted = M._parseContemplate({ "Rarity: common", "Can echo:           Yes", "Maximum echoes:     3", "", "D." })
    expect(counted.num_echoes_possible).toBe(3)
    expect(counted.echoFloor).toBeNil()
    local first = M._parseContemplate({ "Rarity: common", "Maximum echoes:     3", "Can echo:           Yes", "", "D." })
    expect(first.echoFloor).toBeNil()
    expect(M._parseContemplate({ "Rarity: common", "Can echo:           No", "", "D." }).echoFloor).toBeNil()
  end)

  it("a contemplate stores it, and the offer screen says 'can echo', not '(max 1)'", function()
    local lib, out
    lib = withLibrary({}, function()
      withContemplate({ "Rarity:             common", "Can echo:           Yes", "", "Desc." }, function()
        M._boonFillNext({ "Floor Boon" }, 1, 0)
      end)
      withSeed({}, function()
        out = capture(function() M._echoBoonCallouts({ { name = "Floor Boon" } }) end)
      end)
    end)
    expect(lib["Floor Boon"].maxEchoes).toBe(1)
    expect(lib["Floor Boon"].echoFloor).toBeTrue()
    expect(out:find("<cyan>can echo<reset>.", 1, true) ~= nil).toBeTrue()
    expect(out:find("max 1", 1, true)).toBeNil()
  end)

  it("never replaces a real count, and a real count clears it", function()
    local lib = withLibrary({}, function()
      M._learnBoon("Real", "d", nil, 5)
      M._learnBoon("Real", "d", nil, 1, { echoFloor = true })
      M._learnBoon("Later", "d", nil, 1, { echoFloor = true })
      M._learnBoon("Later", "d", nil, 4)
    end)
    expect(lib["Real"].maxEchoes).toBe(5)
    expect(lib["Real"].echoFloor).toBeNil()
    expect(lib["Later"].maxEchoes).toBe(4)
    expect(lib["Later"].echoFloor).toBeNil()
  end)

  it("a stray flag beside a real count is ignored on the offer screen", function()
    local out
    withLibrary({ ["Odd"] = { description = "d", maxEchoes = 3, echoFloor = true } }, function()
      withSeed({}, function() out = capture(function() M._echoBoonCallouts({ { name = "Odd" } }) end) end)
    end)
    expect(out:find("can echo (max 3)", 1, true) ~= nil).toBeTrue()
  end)

  it("survives the boon database round trip, and only as a boolean", function()
    local lib = withLibrary({}, function()
      M._boonDbMerge({ ["A"] = { description = "d", maxEchoes = 1, echoFloor = true },
                       ["B"] = { description = "d", maxEchoes = 1, echoFloor = "yes" } })
    end)
    expect(lib["A"].echoFloor).toBeTrue()
    expect(lib["B"].echoFloor).toBeNil()
  end)
end)

-- ---------------------------------------------------------------------------
-- v4.7.326 review: one contemplate chain at a time. The per-offer chain and a `mnem boonfill` typed
-- while it runs would take turns at the capture slot and interleave their contemplates.
-- ---------------------------------------------------------------------------
describe("one contemplate chain at a time", function()
  local function busy(at, fn)
    local saved = M._fillBusyAt
    M._fillBusyAt = at
    local ok, err = pcall(fn)
    M._fillBusyAt = saved
    if not ok then error(err, 0) end
  end
  local function now() return (getEpoch and getEpoch()) or os.time() end

  it("mnem boonfill refuses while a chain runs, and sends nothing", function()
    local said, realEcho, realSend, sends = {}, M.echo, send, 0
    M.echo = function(m) said[#said + 1] = tostring(m) end
    send = function() sends = sends + 1 end
    local ok, err = pcall(function()
      busy(now(), function()
        withLibrary({ ["Gap"] = {} }, function() M.boonFill() end)
      end)
    end)
    M.echo, send = realEcho, realSend
    if not ok then error(err, 0) end
    expect(table.concat(said, " "):find("already running", 1, true) ~= nil).toBeTrue()
    expect(sends).toBe(0)
  end)

  it("the per-offer chain does not start while one runs", function()
    local started
    busy(now(), function()
      withLibrary({ ["Elder Wisdom"] = { description = "d" } }, function()
        started = M._boonScreenContemplate({ { name = "Elder Wisdom" } })
      end)
    end)
    expect(started).toBeFalse()
  end)

  it("a lock nobody has touched for a while is stale, not held", function()
    local held
    busy(now() - 100, function() held = M._fillBusy() end)
    expect(held).toBeFalse()
  end)

  it("a chain holds the lock while it runs and lets go when it finishes", function()
    local during, after
    withLibrary({}, function()
      withContemplate(FLAMEHEART, function()
        local realCap = M._captureContemplate
        M._captureContemplate = function(cb) during = M._fillBusy(); realCap(cb) end
        M._boonFillNext({ "Flameheart" }, 1, 0, M._fillCtx({}, true))
        after = M._fillBusyAt -- read before withContemplate puts the old value back
      end)
    end)
    expect(during).toBeTrue()
    expect(after).toBeNil()
  end)
end)

describe("combo_boon on /boons_offered", function()
  local function offer(lib, entry)
    reset(true)
    withLibrary(lib, function() M.reportBoonsOffered({ entry }) end)
    return sent[1].payload.offered[1]
  end

  it("sends true and false when the catalogue knows", function()
    expect(offer({ ["Azure Scales"] = { comboBoon = true } }, { name = "Azure Scales" }).combo_boon).toBeTrue()
    expect(offer({ ["Iron Throat"] = { comboBoon = false } }, { name = "Iron Throat" }).combo_boon).toBeFalse()
  end)

  it("omits it when the catalogue does not know -- never a guessed false", function()
    expect(offer({ ["Iron Throat"] = { description = "d" } }, { name = "Iron Throat" }).combo_boon).toBeNil()
    expect(offer({}, { name = "Unheard Of" }).combo_boon).toBeNil()
    expect(offer({ ["Iron Throat"] = { comboBoon = "yes" } }, { name = "Iron Throat" }).combo_boon).toBeNil()
  end)

  -- The tracker's author settled the definition (2026-09-21): "combo_boon argument in
  -- boons_offered endpoint should be set to true if the boon contemplate block has Combo Boon? Yes
  -- in it". This traces that end to end -- the block's own line, through the catalogue, onto the
  -- wire -- rather than trusting the field in isolation.
  it("is the CONTEMPLATE block's own answer, from the block to the payload", function()
    local yes, no
    reset(true) -- one POST per reset: the queue is serial, so a second would still be waiting
    withLibrary({}, function()
      withContemplate(FLAMEHEART, function() M._boonFillNext({ "Flameheart" }, 1, 0) end)
      M.reportBoonsOffered({ { name = "Flameheart" } })
      yes = sent[1].payload.offered[1].combo_boon
    end)
    -- "Combo Boon?: No" has never been seen in the wild (a non-combo block appears to omit the
    -- line entirely); this pins what we would send if it ever prints.
    reset(true)
    withLibrary({}, function()
      withContemplate({ "Rarity:             common", "Combo Boon?:        No", "Can echo:           No",
                        "", "Plain text.", "", '"Q."' }, function()
        M._boonFillNext({ "Plain Boon" }, 1, 0)
      end)
      M.reportBoonsOffered({ { name = "Plain Boon" } })
      no = sent[1].payload.offered[1].combo_boon
    end)
    expect(yes).toBeTrue()
    expect(no).toBeFalse()
  end)

  it("never overwrites a value the offer already carried", function()
    expect(offer({ ["Iron Throat"] = { comboBoon = true } },
      { name = "Iron Throat", combo_boon = false }).combo_boon).toBeFalse()
  end)
end)

describe("/ripple_level takes whole numbers only", function()
  it("setRipple refuses 2.5 and still sends 3", function()
    reset(true)
    M.setRipple(2.5)
    expect(#sent).toBe(0)
    M.setRipple(3)
    expect(sent[1].url).toContain("/ripple_level")
  end)

  it("mnem ripple 2.5 says how to use it instead of sending", function()
    reset(true)
    local realEcho, said = M.echo, nil
    M.echo = function(m) said = tostring(m) end
    local ok, err = pcall(M.command, "ripple 2.5")
    M.echo = realEcho
    if not ok then error(err, 0) end
    expect(#sent).toBe(0)
    expect(said ~= nil and said:find("whole number", 1, true) ~= nil).toBeTrue()
  end)
end)

describe("_boonDbMerge respects the types of the fields it copies", function()
  -- Making the merge field-driven put a TABLE through a loop written for strings.
  it("copies conflictsWith rather than aliasing the source (ADD path)", function()
    local saved = M.history.boonLibrary
    M.history.boonLibrary = {}
    local src = { ["Iron Throat"] = { description = "d", conflictsWith = { "Glass Jaw" } } }
    M._boonDbMerge(src)
    local rec = M.boonInfo("Iron Throat")
    M.history.boonLibrary = saved
    rec.conflictsWith[1] = "MUTATED"
    expect(src["Iron Throat"].conflictsWith[1]).toBe("Glass Jaw")
  end)

  it("copies conflictsWith rather than aliasing the source (ENRICH path)", function()
    local saved = M.history.boonLibrary
    M.history.boonLibrary = { ["Iron Throat"] = { description = "kept" } }
    local src = { ["Iron Throat"] = { conflictsWith = { "Glass Jaw" } } }
    M._boonDbMerge(src)
    local rec = M.boonInfo("Iron Throat")
    M.history.boonLibrary = saved
    rec.conflictsWith[1] = "MUTATED"
    expect(src["Iron Throat"].conflictsWith[1]).toBe("Glass Jaw")
  end)

  -- A table is never == "", so an empty list used to pass the "is there data" test, merge as
  -- though it were data, and then permanently pass the "already filled" test -- with nothing to
  -- ever refill it, since boonGaps only chases a missing description.
  it("does not store an empty conflicts list as if it were data", function()
    local saved = M.history.boonLibrary
    M.history.boonLibrary = {}
    M._boonDbMerge({ ["Iron Throat"] = { description = "d", conflictsWith = {} } })
    local rec = M.boonInfo("Iron Throat")
    expect(rec.conflictsWith).toBeNil()
    -- ...and a real list can still fill it afterwards
    M._boonDbMerge({ ["Iron Throat"] = { conflictsWith = { "Glass Jaw" } } })
    local after = M.boonInfo("Iron Throat")
    M.history.boonLibrary = saved
    expect(after.conflictsWith[1]).toBe("Glass Jaw")
  end)
end)

describe("the server's message on a successful call", function()
  it("does not echo, but does not lose the message either", function()
    reset(true)
    local said = {}
    local savedEcho = M.echo
    M.echo = function(msg) said[#said + 1] = tostring(msg) end
    M.reportBoss("Seasone")
    completeHead({ ok = true, message = "recorded" })
    M.echo = savedEcho
    expect(#said).toBe(0)   -- ok:true is not a user-facing event
  end)
end)

describe("_clearStaleRun -- run state must not survive a reload", function()
  -- `M.run` lives under `ataxia`, which ataxia_saveSettings writes WHOLESALE, and deepMerge ends
  -- in an unconditional dst[k] = v -- so every scalar here came back from disk and won.
  it("clears everything a previous session could have left behind", function()
    reset(true)
    M.run.active = true
    M.run.ripple = 30
    M.run.publicId = "abc123"
    M.run.boss = "Seasone the Industrious"
    M.run.lastOffered = { "Songstep" }
    M.run.lives = 1
    M.run.waveProgress = 7
    M.run.pendingMonsters = { "a host of malagmae" }
    M.run.paused = true

    M._clearStaleRun()

    expect(M.run.active).toBeFalse()
    expect(M.run.ripple).toBe(0)
    expect(M.run.publicId).toBeNil()
    expect(M.run.boss).toBeNil()
    expect(#M.run.lastOffered).toBe(0)
    expect(M.run.lives).toBeNil()
    expect(M.run.waveProgress).toBeNil()
    expect(#M.run.pendingMonsters).toBe(0)
    expect(M.run.paused).toBeNil()
  end)

  -- It routes through _resetRun, so the transient state that lives elsewhere goes too.
  it("also clears the reroll chain and any deferred offer", function()
    reset(true)
    ataxiaTemp.mnemRerolls = 3
    ataxiaTemp.mnemOfferChain = true
    M._offerAfterRipple({ { name = "Songstep", description = "d" } })
    sent = {}

    M._clearStaleRun()

    expect(M._rerollCount()).toBe(0)
    expect(ataxiaTemp.mnemOfferChain).toBeFalse()
    expect(M._pendingOffer).toBeNil()
  end)

  -- `active` and `boss` are deliberately NOT in _resetRun -- startRun sets active true and then
  -- calls it, and boss is re-learned from each ripple's Objective line. On load neither is true,
  -- so this clears both itself; a regression that folded them into _resetRun would break startRun.
  it("does not disturb startRun's own use of _resetRun", function()
    reset(false)
    M.startRun()
    expect(M.run.active).toBeTrue()   -- _resetRun must not have cleared it
  end)

  -- The consumers that are NOT gated on telemetry are why this matters with reporting off:
  -- run.boss steers the Bard's dance and makes the legend deck withhold Xylthus; run.ripple
  -- feeds the swarm's depth-scaled thresholds.
  it("leaves a stale boss unable to reach the gameplay readers", function()
    reset(true)
    M.run.boss = "Seasone the Industrious"
    M._clearStaleRun()
    expect(M.run.boss).toBeNil()
  end)
end)

-- ---------------------------------------------------------------------------
-- GLANCE RECON before stepping into a never-walked room (v4.7.318, user-directed)
--
--   Glancing to the south, you see:
--   Molten lava bubbles and churns. The nebulous form of a phantom grizzly bear lumbers here.
--   You see exits leading north and east.
--
-- The rule is "enter and pass through": entry damage is sunk, a denizen in the lava is drawn out
-- by us moving on. So the glance never refuses -- it PLANS the forward door so onLava fires it on
-- the splash rather than deriving one under fire.
-- ---------------------------------------------------------------------------
describe("glance recon before a never-walked door", function()
  local M = ataxia.mnemosyne
  local MAP = ataxia.mnemosyne.map
  local sent, realSend, realTimer, realKill, timers
  local swarmSaved, swarmSavedFlag -- describe-local, not on the production module table

  local function setup()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    ataxiaBasher.enabled = true
    MAP.drForce = false
    MAP.reset()
    MAP.onRoom(1, "A long corridor.", { south = 0 }, nil) -- south never walked
    M.explore.on = true
    M.explore.moving = false
    M.explore.pausedAtBoon = false
    M.explore.glance = nil
    M.explore.lavaRooms, M.explore.lavaEdges, M.explore.failed = {}, {}, {}
    ataxia.denizensHere = {}
    ataxia.defences = ataxia.defences or {}
    ataxia.defences.blindness = nil
    ataxia.settings = ataxia.settings or {}
    ataxia.settings.reporting = ataxia.settings.reporting or {}
    ataxia.settings.reporting.glance = nil
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.mnemLavaPlan, ataxiaTemp.mnemLavaAt, ataxiaTemp.mnemLavaRoom = nil, nil, nil
    ataxiaTemp.mnemLavaStray, ataxiaTemp.mnemLavaDir = nil, nil
    MAP._lastArrival, MAP._glanceSkip = nil, nil
    realSend, realTimer, realKill = send, tempTimer, killTimer
    sent, timers = {}, {}
    send = function(c) table.insert(sent, c) end
    tempTimer = function(d, f) table.insert(timers, { d = d, f = f }); return #timers end
    killTimer = function() return true end
    -- the tick decides nothing while the swarm claims it; make the swarm silent
    swarmSaved, swarmSavedFlag = M.swarm, true
    M.swarm = { onTick = function() return false end, moveLocked = function() return false end,
                escapeOn = function() end, reset = function() end, state = "idle" }
  end
  -- IDEMPOTENT: the it-wrapper below calls this after every body, so a second call must be a
  -- no-op -- a bare `M.swarm = swarmSaved` on the second pass would nil the real swarm.
  local function restore()
    if not swarmSavedFlag then return end
    send, tempTimer, killTimer = realSend, realTimer, realKill
    M.swarm = swarmSaved; swarmSaved, swarmSavedFlag = nil, nil
    M.explore.on = false; M.explore.moving = false; M.explore.glance = nil
    MAP.drForce = nil
  end
  -- Every test runs its body under pcall so restore() is unconditional: a failed assertion
  -- otherwise leaves the timer/send mocks and the stubbed swarm installed for every file loaded
  -- after this one (the v4.7.316 leak, in a new hat).
  local rawIt = it
  local function it(name, fn)
    rawIt(name, function()
      local ok, err = pcall(fn)
      restore()
      if not ok then error(err, 0) end
    end)
  end
  local function has(frag)
    for _, c in ipairs(sent) do if c:find(frag, 1, true) then return true end end
    return false
  end

  it("glances a never-walked door instead of walking it, and holds while pending", function()
    setup()
    M._exploreTick()
    expect(has("glance south")).toBeTrue()
    expect(has("stand")).toBeFalse()          -- no move yet
    M._exploreTick()                            -- pending: still no move, no second glance
    local glances = 0
    for _, c in ipairs(sent) do if c:find("glance", 1, true) then glances = glances + 1 end end
    expect(glances).toBe(1)
    expect(has("stand")).toBeFalse()
  end)

  it("moves once the glanced exits line lands, and does not glance that door twice", function()
    setup()
    M._exploreTick()                            -- glance south
    MAP.onGlance("south")                       -- trigger 071: the header arms the token
    MAP.onExitsLine("You see exits leading north and east.") -- spends it -> published
    expect(M.explore.glance.done).toBeTrue()
    expect(ataxiaTemp.mnemLavaPlan).toBeNil()   -- no lava line: nothing to plan
    M._exploreTick()
    expect(has("stand;s")).toBeTrue()           -- now it walks (short dir on the wire)
  end)

  it("plans the forward door when the glance shows lava", function()
    setup()
    M._exploreTick()
    MAP.onGlance("south")
    M.onLavaSeen()                              -- trigger 090, inside the glance
    MAP.onExitsLine("You see exits leading north and east.")
    local plan = ataxiaTemp.mnemLavaPlan
    expect(plan ~= nil).toBeTrue()
    expect(plan.room).toBe(1)
    expect(plan.dir).toBe("south")
    expect(plan.fwd).toBe("east")               -- (north is back; it sorts after east anyway -- see the sort-first test)
    M._exploreTick()
    expect(has("stand;s")).toBeTrue()           -- STILL enters -- the user's rule
  end)

  it("a dead-end lava room yields an empty plan, and is still entered", function()
    setup()
    M._exploreTick()
    MAP.onGlance("south")
    M.onLavaSeen()
    MAP.onExitsLine("You see a single exit leading north.")
    expect(ataxiaTemp.mnemLavaPlan.fwd).toBeNil()
    M._exploreTick()
    expect(has("stand;s")).toBeTrue()
  end)

  it("onLava fires the PLANNED door on the splash, and spends the plan", function()
    setup()
    M._exploreTick()
    MAP.onGlance("south")
    M.onLavaSeen()
    MAP.onExitsLine("You see exits leading north and east.")
    M._exploreTick()                            -- walks south
    -- Arrive in the lava room the way the map would record it (from 1, via south).
    MAP.onRoom(2, "A long corridor.", { north = 1, east = 0 }, "south")
    M.explore.moving = false
    sent = {}
    M.onLava("You splash into boiling lava!")
    expect(has("stand;e")).toBeTrue()           -- the planned door, not "n" (back)
    expect(ataxiaTemp.mnemLavaPlan).toBeNil()   -- spent
  end)

  it("a plan for a DIFFERENT entry is ignored", function()
    setup()
    ataxiaTemp.mnemLavaPlan = { room = 99, dir = "west", fwd = "east", at = 0 }
    MAP.onRoom(2, "A long corridor.", { north = 1, east = 0 }, "south")
    M.explore.moving = false
    sent = {}
    M.onLava("You splash into boiling lava!")
    -- No matching plan -> the ordinary chooser (forward beats back): east anyway here, but the
    -- stale plan must be left alone, not consumed.
    expect(ataxiaTemp.mnemLavaPlan ~= nil).toBeTrue()
  end)

  it("times out and walks anyway when the glance yields nothing (blind / darkness)", function()
    setup()
    M._exploreTick()
    expect(has("glance south")).toBeTrue()
    expect(#timers).toBe(1)
    timers[1].f()                               -- GLANCE_TIMEOUT fires
    expect(M.explore.glance.done).toBeTrue()
    M._exploreTick()
    expect(has("stand;s")).toBeTrue()
  end)

  -- A BACKTRACK step is over a door we already walked; it needs no recon. (The sweep's own
  -- selector only ever returns a walked door when backtracking, so that is the case to pin.)
  it("does not glance a door it has already walked -- a backtrack moves at once", function()
    setup()
    MAP.onRoom(2, "B", { west = 1, north = 0 }, "east") -- walked 1 -> 2; 2 keeps an unexplored north
    MAP.onRoom(1, "A dead end.", { east = 2 }, "west")    -- back in 1; nothing unexplored here
    M.explore.moving = false
    sent = {}
    M._exploreTick()                            -- backtrack toward 2 via the walked east door
    expect(has("glance")).toBeFalse()
    expect(has("stand;e")).toBeTrue()
  end)

  -- Deep review (v4.7.318): the description line prints for OUR room too (arrival, LOOK, the
  -- watchdog's ql). Only a line inside the glanced BLOCK -- header token armed for this
  -- direction -- may mark the neighbour as lava.
  it("ignores a lava description line that is not inside the glanced block", function()
    setup()
    M._exploreTick()                            -- glance south pending; no header yet
    M.onLavaSeen()                              -- our own room's description, say
    expect(M.explore.glance.lava).toBeFalse()
    MAP.onGlance("east")                        -- a header for some OTHER direction
    M.onLavaSeen()
    expect(M.explore.glance.lava).toBeFalse()
    MAP.onGlance("south")                       -- now the right block
    M.onLavaSeen()
    expect(M.explore.glance.lava).toBeTrue()
  end)

  -- Deep review (v4.7.318): _scheduleTick is last-call-wins. If we were moved mid-glance the
  -- arrival owns the clock; the resolve must not kill its settle with a 0.1s re-tick.
  it("does not re-tick on resolve if we are no longer in the room we glanced from", function()
    setup()
    M._exploreTick()                            -- glance from room 1
    timers = {}                                 -- forget the timeout timer for the count below
    MAP.onRoom(7, "Somewhere else.", { north = 1 }, "south") -- moved mid-glance
    MAP.onGlance("south")
    MAP.onExitsLine("You see exits leading north and east.")
    expect(M.explore.glance.done).toBeTrue()
    local reticked = false
    for _, tm in ipairs(timers) do if tm.d == 0.1 then reticked = true end end
    expect(reticked).toBeFalse()
  end)

  it("re-ticks on resolve when still in the room we glanced from", function()
    setup()
    M._exploreTick()
    timers = {}
    MAP.onGlance("south")
    MAP.onExitsLine("You see exits leading north and east.")
    local reticked = false
    for _, tm in ipairs(timers) do if tm.d == 0.1 then reticked = true end end
    expect(reticked).toBeTrue()
  end)

  -- Deep review (v4.7.318): a glance whose timer was lost must not hold the sweep forever.
  it("force-resolves a wedged glance at the gate instead of holding forever", function()
    setup()
    M._exploreTick()                            -- glance pending, timer armed (mock: never fires)
    M.explore.glance.at = M.explore.glance.at - 100 -- pretend it is 100s old
    sent = {}
    M._exploreTick()                            -- gate: stale -> resolve -> proceed
    expect(M.explore.glance.done).toBeTrue()
    expect(has("stand;s")).toBeTrue()
  end)

  -- Mutation review (q): a foreign block must not resolve OUR glance.
  it("a block for a different direction neither resolves nor pollutes the pending glance", function()
    setup()
    M._exploreTick()                            -- glance south pending
    MAP.onGlance("east")
    MAP.onExitsLine("You see exits leading west and south.")
    expect(M.explore.glance.done).toBeFalse()
    expect(M.explore.glance.exits).toBeNil()
    MAP.onGlance("south")                       -- now the real one
    M.onLavaSeen()
    MAP.onExitsLine("You see exits leading north and east.")
    expect(ataxiaTemp.mnemLavaPlan.fwd).toBe("east")
  end)

  it("a glance header whose word is not a direction resolves nothing", function()
    setup()
    M._exploreTick()                            -- glance south pending
    MAP.onGlance("about")                       -- "Glancing about, you see:" -- not a direction
    MAP.onExitsLine("You see exits leading north and east.")
    expect(M.explore.glance.done).toBeFalse()
  end)

  -- Mutation review (r2): prove the PLANNED door is used, in a fixture where `_lavaExit` alone
  -- would choose differently (an unexplored west vs the planned, already-walked east).
  it("onLava uses the planned door where _lavaExit would have chosen another", function()
    setup()
    ataxiaTemp.mnemLavaPlan = { room = 1, dir = "south", fwd = "east", at = 0 }
    MAP.onRoom(2, "A long corridor.", { north = 1, east = 0, west = 0 }, "south")
    MAP.rooms[2].edges.east = 99                -- east walked -> _lavaExit would take unexplored west
    M.explore.moving = false
    sent = {}
    M.onLava("You splash into boiling lava!")
    expect(has("stand;e")).toBeTrue()
    expect(has("stand;w")).toBeFalse()
  end)

  -- Mutation review (t): a planned door the room does not actually have is dropped.
  it("onLava drops a planned door the room does not have", function()
    setup()
    ataxiaTemp.mnemLavaPlan = { room = 1, dir = "south", fwd = "east", at = 0 }
    MAP.onRoom(2, "A long corridor.", { north = 1, west = 0 }, "south")
    M.explore.moving = false
    sent = {}
    M.onLava("You splash into boiling lava!")
    expect(has("stand;e")).toBeFalse()
    expect(has("stand;w")).toBeTrue()
    expect(ataxiaTemp.mnemLavaPlan).toBeNil()   -- spent either way
  end)

  -- Deep review (HIGH): the planned door was never lava-checked -- the exits line carries no
  -- ids, so the splash is the first moment `edgeIsLava` can be asked.
  it("onLava refuses a planned door that leads into KNOWN lava", function()
    setup()
    ataxiaTemp.mnemLavaPlan = { room = 1, dir = "south", fwd = "east", at = 0 }
    MAP.onRoom(2, "A long corridor.", { north = 1, east = 66, west = 0 }, "south")
    M.explore.lavaRooms[66] = { at = 1 }
    M.explore.moving = false
    sent = {}
    M.onLava("You splash into boiling lava!")
    expect(has("stand;e")).toBeFalse()
    expect(has("stand;w")).toBeTrue()
  end)

  -- Deep review (HIGH, probe-confirmed): the plan was gated on `first` (episode timing), so a
  -- second lava room entered within LAVA_EPISODE_GAP skipped its plan and inherited the FIRST
  -- room's remembered door -- "n", the way we came.
  it("onLava consumes the plan on a SPLASH even inside a previous lava episode", function()
    setup()
    -- a lava episode is live: we escaped room 9 north 2s ago
    ataxiaTemp.mnemLavaAt = ((getEpoch and getEpoch()) or 0) - 2
    ataxiaTemp.mnemLavaRoom = 9
    ataxiaTemp.mnemLavaDir = "n"
    ataxiaTemp.mnemLavaPlan = { room = 1, dir = "south", fwd = "east", at = 0 }
    -- east is WALKED and west is not, so `_lavaExit` alone would choose "w": only the plan
    -- produces "e". (Without this the test passed for the wrong reason -- the plan is usually
    -- dominated by the chooser, per the mutation review.)
    MAP.onRoom(2, "Another lava room.", { north = 1, east = 0, west = 0 }, "south")
    MAP.rooms[2].edges.east = 99
    M.explore.moving = false
    sent = {}
    M.onLava("You splash into boiling lava!")
    expect(has("stand;e")).toBeTrue()           -- the plan
    expect(has("stand;w")).toBeFalse()          -- not the chooser
    expect(has("stand;n")).toBeFalse()          -- not room 9's remembered door
  end)

  it("the remembered door is only for the SAME room's struggle ticks", function()
    setup()
    ataxiaTemp.mnemLavaAt = ((getEpoch and getEpoch()) or 0) - 2
    ataxiaTemp.mnemLavaRoom = 9                 -- episode anchor is a DIFFERENT room
    ataxiaTemp.mnemLavaDir = "n"
    MAP.onRoom(2, "Another lava room.", { north = 1, east = 0 }, "south")
    M.explore.moving = false
    sent = {}
    local tick = "You continue to struggle in the boiling grasp of the lava as it eats away at your body."
    M.onLava(tick)                              -- v4.7.262: the FIRST tick naming a new room is a stray, ignored
    expect(has("stand")).toBeFalse()
    M.onLava(tick)                              -- the second is adopted (entry line missed)
    -- first=false, anchor (9) ~= cur (2) -> room 9's remembered "n" must NOT be inherited -> derive
    expect(has("stand;e")).toBeTrue()           -- forward beats back
    expect(has("stand;n")).toBeFalse()
  end)

  -- Mutation review (v): the no-exits branch publishes too.
  it("a glanced dead end resolves through the no-exits line", function()
    setup()
    M._exploreTick()
    MAP.onGlance("south")
    M.onLavaSeen()
    MAP.onNoExits()
    expect(M.explore.glance.done).toBeTrue()
    expect(ataxiaTemp.mnemLavaPlan.fwd).toBeNil()
    M._exploreTick()
    expect(has("stand;s")).toBeTrue()
  end)

  -- Mutation review (w, x): lifecycle clears.
  it("a ripple reset drops the pending glance and the plan", function()
    setup()
    M._exploreTick()
    ataxiaTemp.mnemLavaPlan = { room = 1, dir = "south", fwd = "east", at = 0 }
    M.onRippleReset()
    expect(M.explore.glance).toBeNil()
    expect(ataxiaTemp.mnemLavaPlan).toBeNil()
  end)

  it("a ripple reset lifts the flyer latch (v4.7.321 review)", function()
    setup()
    local realSwarm = M.swarm
    M.swarm = { grounded = true }
    M.onRippleReset()
    local after = M.swarm.grounded
    M.swarm = realSwarm
    expect(after).toBeNil()
  end)

  it("explore stop drops the pending glance and its timer", function()
    setup()
    M._exploreTick()
    expect(M.explore.glance ~= nil).toBeTrue()
    M._exploreStop("test")
    expect(M.explore.glance).toBeNil()
    expect(M._glanceT).toBeNil()
  end)

  -- Deep review (MEDIUM, reproduced): after v4.7.318 stopped the resolve re-ticking on a room
  -- change, the settle tick hit the gate, saw the stale glance, returned with nothing scheduled
  -- -- a 30s stall. A glance for a room we have left is dropped at the gate, not waited for.
  it("a glance pending for a room we have LEFT is dropped, not waited for", function()
    setup()
    M._exploreTick()                            -- glance from 1, pending
    MAP.onRoom(7, "Elsewhere.", { north = 1, east = 0 }, "south") -- moved mid-glance
    M.explore.moving = false
    sent = {}
    M._exploreTick()                            -- the settle tick
    expect(M.explore.glance == nil or M.explore.glance.room == 7).toBeTrue() -- old one gone
    expect(has("glance east")).toBeTrue()       -- and the new room's door is glanced at once
  end)

  -- Deep review: nothing to see while BLIND -- the Monk/BM keeper holds it up in the tower.
  it("does not glance while blind", function()
    setup()
    ataxia.defences.blindness = true
    M._exploreTick()
    ataxia.defences.blindness = nil
    expect(has("glance")).toBeFalse()
    expect(has("stand;s")).toBeTrue()
  end)

  -- The status line was DEFINED in the first cut of this change and called from nowhere -- a
  -- function with no caller is dead code however good it is. Pin that status and why print it.
  it("mnem explore status and why both show the glance state", function()
    setup()
    M._exploreTick()                            -- glance south pending
    local said = {}
    local realEcho, realCecho = M.echo, cecho
    M.echo = function(s) said[#said + 1] = tostring(s) end
    cecho = function(s) said[#said + 1] = tostring(s) end
    pcall(M.exploreStatus)
    pcall(M.exploreWhy)
    M.echo, cecho = realEcho, realCecho
    local n = 0
    for _, s in ipairs(said) do
      if s:find("glance recon: on -- PENDING s", 1, true) then n = n + 1 end
    end
    expect(n).toBe(2)
  end)

  it("mnem explore glance off persists and stops the recon", function()
    setup()
    M.command("explore glance off")
    expect(ataxia.settings.reporting.glance).toBeFalse()
    M._exploreTick()
    expect(has("glance")).toBeFalse()
    M.command("explore glance on")
    expect(ataxia.settings.reporting.glance).toBeTrue()
  end)

  it("can be switched off", function()
    setup()
    ataxia.settings.reporting.glance = false
    M._exploreTick()
    expect(has("glance")).toBeFalse()
    expect(has("stand;s")).toBeTrue()
  end)
end)

-- v4.7.319, deep review, reproduced: `glance south` ends in a direction and the send capture
-- took the last word of EVERY command, so a room change with no move of ours inside the window
-- recorded a phantom walked edge on the glanced door (and a phantom lava edge if that room was
-- lava). Only a command that can MOVE us may set the last move direction.
describe("the send capture ignores look verbs", function()
  local MAP = ataxia.mnemosyne.map
  it("a glance does not set the last move direction; a move still does", function()
    ataxiaBasher = ataxiaBasher or {}
    ataxiaBasher.inMnemosyne = true
    MAP._lastMoveDir = nil
    raiseEvent("sysDataSendRequest", "glance south")
    expect(MAP._lastMoveDir).toBeNil()
    raiseEvent("sysDataSendRequest", "squint east")
    expect(MAP._lastMoveDir).toBeNil()
    raiseEvent("sysDataSendRequest", "queue addclear free stand;south")
    expect(MAP._lastMoveDir).toBe("south")
    MAP._lastMoveDir = nil
  end)
end)

-- v4.7.320: Sharp Mind joins the generic registry -- it arms the Monk transmute top-up.
describe("Sharp Mind latches through the boon registry", function()
  local M = ataxia.mnemosyne
  it("latches from the plain row and from an (ECHO) row", function()
    mnemSharpMind = nil
    expect(M.BOON_FLAGS["Sharp Mind"]).toBe("mnemSharpMind")
    expect(M.latchBoonFlag("Sharp Mind")).toBe("mnemSharpMind")
    expect(mnemSharpMind).toBeTrue()
    mnemSharpMind = nil
    expect(M.latchBoonFlag("(ECHO) Sharp Mind")).toBe("mnemSharpMind")
    expect(mnemSharpMind).toBeTrue()
    M.clearBoonFlags()
    expect(mnemSharpMind).toBeFalse()
    mnemSharpMind = nil
  end)
end)

-- ---------------------------------------------------------------------------
-- v4.7.327: the boon advisor. User: "After it boon contemplates the boon selection, it should give
-- us a summary ... start recommending some boons" -- "Defensive boons are a priority" -- "It
-- depends on the boons we have" -- "Each class will be different."
-- ---------------------------------------------------------------------------
dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/011_Bonuses.lua")
dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/014_Boon_Advisor.lua")

-- The user's live screen (2026-09-19), as the catalogue knew it after the contemplates.
local LIVE_LIB = {
  ["Haskor's Bravado"] = { description = "Your attacks have a 5% chance to afflict the target with recklessness. This may only occur every 5 seconds.",
                           category = "Offence", rarity = "uncommon", maxEchoes = 5 },
  ["Fae-Lapse"] = { description = "There is a 5% chance you give the denizen you are attacking amnesia. This may only occur every 5 seconds.",
                    category = "Utility", rarity = "rare", maxEchoes = 5 },
  ["Ashaxei's Mirror"] = { description = "When taking elemental damage greater than 20% of your health, gain 1 reflections.",
                           category = "Defence", rarity = "uncommon", comboBoon = true, maxEchoes = 0 },
  ["Restoration"] = { description = "Restore your resources instead." },
}
local LIVE_OFFER = { { name = "Haskor's Bravado" }, { name = "Fae-Lapse" }, { name = "Ashaxei's Mirror" }, { name = "Restoration" } }

-- Ashaxei's Mirror's real contemplate block (the same screenshot).
local MIRROR = {
  "Rarity:             uncommon",
  "Category:           Defence",
  "Combo Boon?:        Yes",
  "Can echo:           No",
  "",
  "When taking elemental damage greater than 20% of your health, gain 1 reflections.",
  "",
  "\"In the seventh century after Seleucar's fall, the White Dragon fell to the machinations of the vile Dala'myrr,",
  "perishing over desert sands.\"",
}

-- A fresh copy per test: a contemplate WRITES into the library, and a shared fixture would carry
-- one test's learning into the next.
local function copyLib(lib)
  local out = {}
  for name, rec in pairs(lib) do
    local r = {}
    for k, v in pairs(rec) do r[k] = v end
    out[name] = r
  end
  return out
end

describe("the boon advisor", function()
  -- Every piece of shared state these tests touch, put back even if a test throws.
  local function advising(opts, fn)
    local saved = { claims = M.history.claims, run = M.history.run, active = M.run and M.run.active,
                    gmcp = gmcp, rerolls = M._rerollsLeft, classW = M.BOON_CLASS_WEIGHTS,
                    echo = M.echo, cecho = cecho, advice = M._lastAdvice }
    local said = {}
    M.history.claims = opts.claims or {}
    M.history.run = 9
    M.run = M.run or {}
    M.run.active = true
    gmcp = { Char = { Status = { class = opts.class }, Vitals = opts.vitals or { hp = "100", maxhp = "100" } } }
    M._rerollsLeft = opts.rerolls
    M.BOON_CLASS_WEIGHTS = opts.classWeights or {}
    M.echo = function(m) said[#said + 1] = tostring(m) end
    cecho = function(m) said[#said + 1] = tostring(m) end
    local ok, res = pcall(function()
      local out
      withLibrary(copyLib(opts.lib or LIVE_LIB), function()
        withSeed(opts.seed or {}, function() out = fn() end)
      end)
      return out
    end)
    M.history.claims, M.history.run, M.run.active = saved.claims, saved.run, saved.active
    gmcp, M._rerollsLeft, M.BOON_CLASS_WEIGHTS = saved.gmcp, saved.rerolls, saved.classW
    M.echo, cecho, M._lastAdvice = saved.echo, saved.cecho, saved.advice
    if not ok then error(res, 0) end
    return res, table.concat(said, "\n")
  end
  local function claim(name) return { name = name, run = 9 } end

  it("the user's live screen: defence first recommends Ashaxei's Mirror, and says why", function()
    local ranked, out = advising({}, function() return M.offerSummary(LIVE_OFFER) end)
    expect(ranked[1].name).toBe("Ashaxei's Mirror")
    expect(out:find("RECOMMEND<reset> <gold>Ashaxei's Mirror", 1, true) ~= nil).toBeTrue()
    expect(out:find("Defence", 1, true) ~= nil).toBeTrue()
    expect(out:find("5% recklessness on hit", 1, true) ~= nil).toBeTrue() -- what Bravado does, in short
    expect(out:find("5% amnesia on hit", 1, true) ~= nil).toBeTrue() -- Fae-Lapse's other wording
    expect(out:find("<pale_green>combo", 1, true) ~= nil).toBeTrue()
    expect(#ranked).toBe(4)
  end)

  it("an immunity we already have is worth nothing, and says so", function()
    local lib = { ["Plasmatic"] = { description = "You are immune to the haemophilia affliction.", category = "Defence" },
                  ["Held Blood"] = { description = "You are immune to the haemophilia affliction." },
                  ["Quill"] = { description = "You are immune to the amnesia affliction.", category = "Defence" } }
    local ranked = advising({ lib = lib, claims = { claim("Held Blood") } }, function()
      return M.rankOffer({ "Plasmatic", "Quill" })
    end)
    expect(ranked[1].name).toBe("Quill")
    expect(table.concat(ranked[2].flags, " "):find("already immune to haemophilia", 1, true) ~= nil).toBeTrue()
  end)

  it("a boon that conflicts with one we hold goes to the bottom, flagged", function()
    local lib = { ["Careless Whisperer"] = { description = "d", category = "Defence", conflictsWith = { "Truther" } },
                  ["Truther"] = { description = "d" }, ["Plain Offence"] = { description = "d", category = "Offence" } }
    local ranked = advising({ lib = lib, claims = { claim("Truther") } }, function()
      return M.rankOffer({ "Careless Whisperer", "Plain Offence" })
    end)
    expect(ranked[2].name).toBe("Careless Whisperer")
    expect(table.concat(ranked[2].flags, " "):find("CONFLICTS with Truther", 1, true) ~= nil).toBeTrue()
  end)

  it("a resistance counts for less where we already resist that type", function()
    local lib = { ["Fire Held"] = { description = "Gain 30% resistance to fire damage." },
                  ["More Fire"] = { description = "Gain 20% resistance to fire damage.", category = "Defence" },
                  ["Some Cold"] = { description = "Gain 20% resistance to cold damage.", category = "Defence" } }
    local seed = { ["Fire Held"] = { description = "Gain 30% resistance to fire damage." } }
    local ranked = advising({ lib = lib, seed = seed, claims = { claim("Fire Held") } }, function()
      return M.rankOffer({ "More Fire", "Some Cold" })
    end)
    expect(ranked[1].name).toBe("Some Cold")
    expect(ranked[1].score > ranked[2].score).toBeTrue()
  end)

  it("a category we are short of gets a push", function()
    local lib = { ["O1"] = { description = "d", category = "Offence" }, ["O2"] = { description = "d", category = "Offence" },
                  ["Shield"] = { description = "d", category = "Defence" } }
    local ranked = advising({ lib = lib, claims = { claim("O1"), claim("O2") } }, function()
      return M.rankOffer({ "Shield" })
    end)
    local why = {}
    for _, p in ipairs(ranked[1].parts) do why[#why + 1] = p.why end
    expect(table.concat(why, "; "):find("you hold fewer Defence boons", 1, true) ~= nil).toBeTrue()
  end)

  it("each class can weigh it differently: a class override wins over the default", function()
    local lib = { ["Hit Hard"] = { description = "d", category = "Offence" }, ["Stand Firm"] = { description = "d", category = "Defence" } }
    local def = advising({ lib = lib, class = "Bard" }, function() return M.rankOffer({ "Hit Hard", "Stand Firm" }) end)
    local bard = advising({ lib = lib, class = "Bard", classWeights = { bard = { category = { offence = 60 } } } },
      function() return M.rankOffer({ "Hit Hard", "Stand Firm" }) end)
    expect(def[1].name).toBe("Stand Firm")
    expect(bard[1].name).toBe("Hit Hard")
    -- only what the class changes: the rest of the table is still the default
    local W = advising({ class = "Bard", classWeights = { bard = { category = { offence = 60 } } } },
      function() return M.boonWeights() end)
    expect(W.category.defence).toBe(M.BOON_WEIGHTS.category.defence)
    expect(W.drawback).toBe(M.BOON_WEIGHTS.drawback)
  end)

  it("Restoration wins when we are hurt, and not when we are healthy", function()
    local healthy = advising({}, function() return M.rankOffer(LIVE_OFFER) end)
    local hurt = advising({ vitals = { hp = "3000", maxhp = "10000" } }, function() return M.rankOffer(LIVE_OFFER) end)
    expect(healthy[1].name ~= "Restoration").toBeTrue()
    expect(hurt[1].name).toBe("Restoration")
  end)

  it("suggests a reroll only when every option is weak AND one is left", function()
    local lib = { ["Meh"] = { description = "You may now utilise prism tattoos." } }
    local _, withOne = advising({ lib = lib, rerolls = 1 }, function() return M.offerSummary({ "Meh" }) end)
    local _, none = advising({ lib = lib, rerolls = 0 }, function() return M.offerSummary({ "Meh" }) end)
    local _, strong = advising({ rerolls = 1 }, function() return M.offerSummary(LIVE_OFFER) end)
    expect(withOne:find("BOON REROLL", 1, true) ~= nil).toBeTrue()
    expect(none:find("BOON REROLL", 1, true)).toBeNil()
    expect(strong:find("BOON REROLL", 1, true)).toBeNil()
  end)

  it("prints when the offer's contemplate chain ends, quiet chain or not", function()
    local _, out = advising({}, function()
      local collect = M.echo
      withContemplate(MIRROR, function()
        M.echo = collect -- withContemplate installs its own collector; read everything in one place
        local ctx = M._fillCtx({ ["Ashaxei's Mirror"] = true }, true)
        ctx.offered = LIVE_OFFER
        M._boonFillNext({ "Ashaxei's Mirror" }, 1, 0, ctx)
      end)
    end)
    expect(out:find("RECOMMEND<reset> <gold>Ashaxei's Mirror", 1, true) ~= nil).toBeTrue()
    expect(out:find("Boon catalogue updated", 1, true)).toBeNil() -- a quiet chain: only the summary
  end)

  it("the offer screen's own chain carries the offer to its end", function()
    local realGaps, realBusy = M.boonGaps, M._fillBusyAt
    local _, out = advising({}, function()
      local collect = M.echo
      M.boonGaps = function() return {} end
      M._fillBusyAt, M._capturing = nil, false
      withContemplate(MIRROR, function()
        M.echo = collect
        expect(M._boonScreenContemplate(LIVE_OFFER)).toBeTrue()
      end)
    end)
    M.boonGaps, M._fillBusyAt = realGaps, realBusy
    expect(out:find("RECOMMEND", 1, true) ~= nil).toBeTrue()
  end)

  it("prints at once when no contemplate chain starts", function()
    local realScreen, realPost, realTimer, realIdle = M._boonScreenContemplate, M._reportBoonsOfferedEnriched, tempTimer, M.BOON_FILL_IDLE
    local _, out = advising({}, function()
      M._boonScreenContemplate = function() return false end -- the slot was busy
      M._reportBoonsOfferedEnriched = function() end
      tempTimer = function(_, f) f(); return 1 end
      M.BOON_FILL_IDLE = 1
      M._pendingOffer = LIVE_OFFER
      local ok, err = pcall(M._flushPendingOffer, "test")
      M._boonScreenContemplate, M._reportBoonsOfferedEnriched, tempTimer, M.BOON_FILL_IDLE = realScreen, realPost, realTimer, realIdle
      if not ok then error(err, 0) end
    end)
    expect(out:find("RECOMMEND<reset> <gold>Ashaxei's Mirror", 1, true) ~= nil).toBeTrue()
  end)

  it("mnem advise re-prints the last offer", function()
    local _, out = advising({}, function()
      M._lastAdvice = { list = LIVE_OFFER }
      M.command("advise")
    end)
    expect(out:find("RECOMMEND", 1, true) ~= nil).toBeTrue()
  end)

  it("trigger 094 reads the reroll count off the footer", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/094_Boon_Rerolls_Left.lua")
    local src = f:read("*a"); f:close()
    expect(src:find("- pattern: ^BOON REROLL to discard these options and see new ones \\((\\d+) remaining\\)", 1, true) ~= nil).toBeTrue()
    local savedMatches, savedAtaxia, savedLeft = matches, ataxia, M._rerollsLeft
    ataxia = { mnemosyne = M }
    matches = { "BOON REROLL to discard these options and see new ones (1 remaining)", "1" }
    local ok, err = pcall(dofile, "src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/094_Boon_Rerolls_Left.lua")
    local got = M._rerollsLeft
    matches, ataxia, M._rerollsLeft = savedMatches, savedAtaxia, savedLeft
    if not ok then error(err, 0) end
    expect(got).toBe(1)
  end)

  it("a new offer screen forgets the last screen's count", function()
    local saved = M._rerollsLeft
    M._rerollsLeft = 3
    local ok, err = pcall(M.onBoonsOffered)
    local got = M._rerollsLeft
    if M._captureForceFinish then pcall(M._captureForceFinish) end
    M._pendingOffer, M._rerollsLeft = nil, saved
    if not ok then error(err, 0) end
    expect(got).toBeNil()
  end)
end)

-- ---------------------------------------------------------------------------
-- v4.7.328: BOON COMBOS. User, with the reward in hand: "With every required boon now in hand, the
-- mist of the Mnemosyne parts and bestows upon you another: Lightning Soul." -- "I got that for
-- finishing the boon combo. We need to boon contemplate those and add them to the database and
-- also start to tie which boons combo together to get to the end path of the boon."
-- ---------------------------------------------------------------------------
dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/015_Boon_Combos.lua")

-- The user's block, verbatim.
local LIGHTNING = {
  "Rarity:             rare",
  "Category:           Defence",
  "Can echo:           No",
  "Unlocked By:        Argent Scales, Electric Mastery, and Energetic",
  "",
  "Gain immunity to electric damage for 60 seconds at the start of each new ripple.",
  "",
  '"Thunderstruck!"',
}

describe("boon combos", function()
  local function holding(names, fn)
    local saved = { claims = M.history.claims, run = M.history.run, active = M.run and M.run.active }
    M.history.claims = {}
    for _, n in ipairs(names) do table.insert(M.history.claims, { name = n, run = 11 }) end
    M.history.run = 11
    M.run = M.run or {}
    M.run.active = true
    local ok, res = pcall(fn)
    M.history.claims, M.history.run, M.run.active = saved.claims, saved.run, saved.active
    if not ok then error(res, 0) end
    return res
  end
  local function capture(fn)
    local said, realEcho, realCecho = {}, M.echo, cecho
    M.echo = function(m) said[#said + 1] = tostring(m) end
    cecho = function(m) said[#said + 1] = tostring(m) end
    local ok, err = pcall(fn)
    M.echo, cecho = realEcho, realCecho
    if not ok then error(err, 0) end
    return table.concat(said, "\n")
  end
  local WITH_CHAIN = {
    ["Lightning Soul"] = { description = "Gain immunity to electric damage for 60 seconds at the start of each new ripple.",
      category = "Defence", rarity = "rare",
      unlocksFrom = { "Argent Scales", "Electric Mastery", "Energetic" }, contemplatedAt = 1 },
    ["Argent Scales"] = { description = "Gain 25% resistance to electric damage.", contemplatedAt = 1 },
    ["Electric Mastery"] = { description = "d", contemplatedAt = 1 },
    ["Energetic"] = { description = "d", contemplatedAt = 1 },
  }

  it("reads the recipe off the reward's own block -- a list, not a 60-character string", function()
    local info = M._parseContemplate(LIGHTNING)
    expect(info.category).toBe("Defence")
    expect(info.num_echoes_possible).toBe(0)
    expect(#info.unlocksFrom).toBe(3)
    expect(info.unlocksFrom[1]).toBe("Argent Scales")
    expect(info.unlocksFrom[3]).toBe("Energetic")
    expect(info.description).toBe("Gain immunity to electric damage for 60 seconds at the start of each new ripple.")
    expect(info.unlockedBy).toBe("Argent Scales, Electric Mastery, and Energetic") -- still a string, for the tracker
  end)

  it("keeps a recipe too long for the meta string cap", function()
    local long = { "Rarity: rare",
      "Unlocked By:        Argent Scales, Ashaxei's Mirror, Ephemeral Guardian, and Silvestri's Grace",
      "", "Desc." }
    local info
    withLibrary({ ["Argent Scales"] = { description = "d" }, ["Ashaxei's Mirror"] = { description = "d" },
                  ["Ephemeral Guardian"] = { description = "d" },
                  ["Silvestri's Grace"] = { description = "d" } }, function()
      info = M._parseContemplate(long)
    end)
    expect(#info.unlocksFrom).toBe(4)
    expect(info.unlockedBy).toBeNil() -- over META_VALUE_MAX: the STRING is dropped, the list is not
  end)

  it("takes a wrapped recipe's tail, like the conflicts line", function()
    local info
    withLibrary({ Alpha = { description = "d" }, Beta = { description = "d" },
                  ["Gamma Ray"] = { description = "d" } }, function()
      info = M._parseContemplate({ "Rarity: rare", "Unlocked By:        Alpha, Beta and", "Gamma Ray",
        "", "Your blows land harder.", "", '"Q."' })
    end)
    expect(#info.unlocksFrom).toBe(3)
    expect(info.unlocksFrom[3]).toBe("Gamma Ray")
    expect(info.description).toBe("Your blows land harder.")
  end)

  it("a contemplate stores the recipe, and the chain index reads it back", function()
    local lib = withLibrary({}, function()
      withContemplate(LIGHTNING, function() M._boonFillNext({ "Lightning Soul" }, 1, 0) end)
      expect(#M.comboChains()["Lightning Soul"]).toBe(3)
      expect(M.comboFeeds("Electric Mastery")[1]).toBe("Lightning Soul")
      expect(M.comboFeeds("(ECHO) Argent Scales")[1]).toBe("Lightning Soul") -- an echo offer is its base boon
      expect(#M.comboFeeds("Unrelated")).toBe(0)
    end)
    expect(lib["Lightning Soul"].unlocksFrom[2]).toBe("Electric Mastery")
    expect(lib["Lightning Soul"].category).toBe("Defence")
  end)

  it("tracks this run's progress toward the reward", function()
    withLibrary(WITH_CHAIN, function()
      holding({ "Argent Scales", "Energetic" }, function()
        local p = M.comboProgress("Lightning Soul")
        expect(p.have).toBe(2)
        expect(p.need).toBe(3)
        expect(p.missing[1]).toBe("Electric Mastery")
        expect(p.complete).toBeFalse()
      end)
      holding({ "Argent Scales", "Energetic", "Electric Mastery", "Lightning Soul" }, function()
        expect(M.comboProgress("Lightning Soul").complete).toBeTrue()
      end)
      expect(M.comboProgress("No Such Boon")).toBeNil()
    end)
  end)

  it("mnem combos shows how far along each recipe is, closest first", function()
    local out
    withLibrary(WITH_CHAIN, function()
      holding({ "Argent Scales" }, function()
        out = capture(function() M.reportCombos() end)
      end)
    end)
    expect(out:find("1/3", 1, true) ~= nil).toBeTrue()
    expect(out:find("Lightning Soul", 1, true) ~= nil).toBeTrue()
    expect(out:find("<green>Argent Scales", 1, true) ~= nil).toBeTrue()   -- held
    expect(out:find("<grey>Electric Mastery", 1, true) ~= nil).toBeTrue() -- still needed
  end)

  it("names the components it has never contemplated, so the chain asks about them", function()
    local lib = { ["Lightning Soul"] = { description = "d", unlocksFrom = { "Argent Scales", "Electric Mastery", "Energetic" }, contemplatedAt = 1 },
                  ["Argent Scales"] = { description = "d", contemplatedAt = 1 },
                  ["Electric Mastery"] = { description = "d" } } -- described, never contemplated
    local gaps
    withLibrary(lib, function() gaps = M.comboGaps() end)
    expect(#gaps).toBe(2)
    expect(gaps[1]).toBe("Electric Mastery")
    expect(gaps[2]).toBe("Energetic")
  end)

  it("the offer screen's chain picks up one component per screen", function()
    local lib = { ["Offered"] = { description = "d" },
                  ["Lightning Soul"] = { description = "d", unlocksFrom = { "Energetic" }, contemplatedAt = 1 } }
    local asked, realGaps = {}, M.boonGaps
    local realNext, realCap, realBusy = M._boonFillNext, M._capturing, M._fillBusyAt
    M.boonGaps = function() return {} end
    M._boonFillNext = function(todo) asked = todo end
    local ok, err = pcall(function()
      withLibrary(lib, function()
        M._capturing, M._fillBusyAt = false, nil
        M._boonScreenContemplate({ { name = "Offered" } })
      end)
    end)
    M.boonGaps, M._boonFillNext = realGaps, realNext
    M._capturing, M._fillBusyAt = realCap, realBusy
    if not ok then error(err, 0) end
    expect(#asked).toBe(2)
    expect(asked[2]).toBe("Energetic")
  end)

  it("the advisor pays for a component, and pays more for the one that completes it", function()
    local lib = copyLib(WITH_CHAIN) -- deep: a contemplate writes into these records
    lib["Electric Mastery"] = { description = "d", category = "Utility", contemplatedAt = 1 }
    lib["Plain"] = { description = "d", category = "Utility" }
    withLibrary(lib, function()
      local one = holding({}, function() return M.scoreBoon("Electric Mastery") end) -- holding DOES return
      local two = holding({ "Argent Scales", "Energetic" }, function() return M.scoreBoon("Electric Mastery") end)
      local plain = holding({}, function() return M.scoreBoon("Plain") end)
      expect(one.score > plain.score).toBeTrue()
      expect(two.score > one.score).toBeTrue()
      expect(table.concat(two.effects, " "):find("completes Lightning Soul", 1, true) ~= nil).toBeTrue()
      expect(table.concat(one.effects, " "):find("1/3 toward Lightning Soul", 1, true) ~= nil).toBeTrue()
      -- ...and nothing for a chain we have already finished
      local done = holding({ "Argent Scales", "Energetic", "Electric Mastery", "Lightning Soul" },
        function() return M.scoreBoon("Electric Mastery") end)
      expect(table.concat(done.effects, " "):find("toward", 1, true)).toBeNil()
      expect(table.concat(done.effects, " "):find("completes", 1, true)).toBeNil()
      expect(done.score).toBe(plain.score) -- a recipe already in hand is worth nothing extra
    end)
  end)

  it("the bestowal records the free boon and says which recipe finished", function()
    local out, claimed
    withLibrary(WITH_CHAIN, function()
      holding({ "Argent Scales", "Electric Mastery", "Energetic" }, function()
        local realRecord, realTimer = M._recordClaim, tempTimer
        M._recordClaim = function(n) claimed = n end
        tempTimer = function() return 1 end
        local ok, err = pcall(function()
          out = capture(function() M.onComboBoonGranted("Lightning Soul") end)
        end)
        M._recordClaim, tempTimer = realRecord, realTimer
        if not ok then error(err, 0) end
      end)
    end)
    expect(claimed).toBe("Lightning Soul")
    expect(out:find("COMBO COMPLETE", 1, true) ~= nil).toBeTrue()
    expect(out:find("Argent Scales, Electric Mastery, Energetic", 1, true) ~= nil).toBeTrue()
  end)

  it("a recipe survives the boon database round trip, and only as a list", function()
    local lib
    lib = withLibrary({}, function()
      M._boonDbMerge({ ["Reward"] = { description = "d", unlocksFrom = { "A", "B" } },
                       ["Junk"] = { description = "d", unlocksFrom = "A and B" } })
    end)
    expect(#lib["Reward"].unlocksFrom).toBe(2)
    expect(lib["Junk"].unlocksFrom).toBeNil() -- a string is not a recipe
  end)

  it("the gap queue is in a stable order, so the same component is asked about first", function()
    local lib = { ["Reward"] = { description = "d", contemplatedAt = 1,
      unlocksFrom = { "Zephyr", "Quill", "Amber", "Mistral", "Basalt", "Nadir" } } }
    local gaps
    withLibrary(lib, function() gaps = M.comboGaps() end)
    expect(#gaps).toBe(6)
    local sorted = {}
    for i, n in ipairs(gaps) do sorted[i] = n end
    table.sort(sorted)
    expect(table.concat(gaps, ",")).toBe(table.concat(sorted, ","))
  end)

  it("mnem combos puts the recipe closest to done first", function()
    local lib = { ["Nearly"] = { description = "d", contemplatedAt = 1, unlocksFrom = { "A", "B", "C" } },
                  ["Barely"] = { description = "d", contemplatedAt = 1, unlocksFrom = { "D", "E" } },
                  ["A"] = { description = "d" }, ["B"] = { description = "d" } }
    local out
    withLibrary(lib, function()
      holding({ "A", "B" }, function() out = capture(function() M.command("combos") end) end)
    end)
    expect(out:find("Nearly", 1, true) < out:find("Barely", 1, true)).toBeTrue()
    expect(out:find("2/3", 1, true) ~= nil).toBeTrue()
    expect(out:find("0/2", 1, true) ~= nil).toBeTrue()
  end)

  -- The guard is on `_histBoonInfo`, which the ADVISOR never calls -- the earlier version of this
  -- test passed with or without it (review, v4.7.328). Call the guarded function itself; the path
  -- that reaches it live is the combo grant's `_recordClaim`.
  it("_histBoonInfo tolerates history.offers not yet loaded", function()
    local saved = M.history.offers
    M.history.offers = nil
    local ok, rarity, desc = pcall(M._histBoonInfo, "Argent Scales")
    M.history.offers = saved
    expect(ok).toBeTrue()
    expect(rarity).toBe("")
    expect(desc).toBe("")
  end)

  it("trigger 095 hands the granted boon's name to the module", function()
    local f = io.open("src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/095_Boon_Combo_Granted.lua")
    local src = f:read("*a"); f:close()
    expect(src:find("bestows upon you another: (.+)\\.$", 1, true) ~= nil).toBeTrue()
    local got, realOn, savedMatches, savedAtaxia = nil, M.onComboBoonGranted, matches, ataxia
    M.onComboBoonGranted = function(n) got = n end
    ataxia = { mnemosyne = M }
    matches = { "whole line", "Lightning Soul" }
    local ok, err = pcall(dofile, "src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/095_Boon_Combo_Granted.lua")
    M.onComboBoonGranted, matches, ataxia = realOn, savedMatches, savedAtaxia
    if not ok then error(err, 0) end
    expect(got).toBe("Lightning Soul")
  end)

  -- v4.7.328 REVIEW: the wrapped recipe naming a boon we have never heard of. The tail was only
  -- taken when every name was already known -- exactly false for a recipe's newest component -- so
  -- the list kept a phantom "and", the real component was lost, and the orphaned line became the
  -- boon's DESCRIPTION and overwrote the catalogue.
  it("takes a wrapped recipe's tail even when the component is one we have never heard of", function()
    local info
    withLibrary({ ["Argent Scales"] = { description = "d" }, ["Electric Mastery"] = { description = "d" } }, function()
      info = M._parseContemplate({
        "Rarity:             rare",
        "Category:           Defence",
        "Can echo:           No",
        "Unlocked By:        Argent Scales, Electric Mastery, and",
        "Zzyzx Ward",
        "",
        "Gain immunity to electric damage for 60 seconds at the start of each new ripple.",
        "",
        '"Thunderstruck!"',
      })
    end)
    expect(#info.unlocksFrom).toBe(3)
    expect(info.unlocksFrom[3]).toBe("Zzyzx Ward")     -- the new component survives
    for _, n in ipairs(info.unlocksFrom) do expect(n ~= "and").toBeTrue() end
    expect(info.description).toBe("Gain immunity to electric damage for 60 seconds at the start of each new ripple.")
    expect(info.quote:find("Thunderstruck", 1, true) ~= nil).toBeTrue()
    expect(info.category).toBe("Defence")
  end)

  it("a list ending in a bare 'and' never yields a boon called 'and'", function()
    local names = M._splitBoonList("Argent Scales, Electric Mastery, and", {})
    expect(#names).toBe(2)
    expect(names[2]).toBe("Electric Mastery")
  end)

  -- A description line still must not be swallowed: the dangling-connector rule only fires when the
  -- value itself is unfinished.
  it("a finished value does not swallow the description line", function()
    local info
    withLibrary({ ["Argent Scales"] = { description = "d" } }, function()
      info = M._parseContemplate({ "Rarity: rare", "Unlocked By:        Argent Scales",
        "", "Gain immunity to electric damage.", "", '"Q."' })
    end)
    expect(#info.unlocksFrom).toBe(1)
    expect(info.description).toBe("Gain immunity to electric damage.")
  end)

  it("the tracker gets a recipe too long for the meta string, from the list", function()
    reset(true)
    withLibrary({ ["Lightning Soul"] = { description = "d",
      unlocksFrom = { "Argent Scales", "Ashaxei's Mirror", "Ephemeral Guardian", "Silvestri's Grace" } } }, function()
      M.reportBoonsOffered({ { name = "Lightning Soul" } })
    end)
    expect(sent[1].payload.offered[1].unlocked_by)
      .toBe("Argent Scales, Ashaxei's Mirror, Ephemeral Guardian, Silvestri's Grace")
  end)

  it("the chain index is cached, and a learnt recipe invalidates it", function()
    withLibrary({ ["R"] = { description = "d", unlocksFrom = { "A" }, contemplatedAt = 1 } }, function()
      local first = M.comboChains()
      expect(M.comboChains()).toBe(first)            -- same table: not rebuilt
      M._learnBoon("R2", "d", nil, nil, { unlocksFrom = { "B", "C" } })
      local after = M.comboChains()
      expect(after ~= first).toBeTrue()              -- a learn invalidates it
      expect(#after["R2"]).toBe(2)
    end)
  end)

  it("names a boon we HOLD but never contemplated -- which is what a granted reward is", function()
    local gaps
    withLibrary({ ["Lightning Soul"] = { description = "d" } }, function() -- granted, never contemplated
      holding({ "Lightning Soul" }, function() gaps = M.comboGaps() end)
    end)
    expect(#gaps).toBe(1)
    expect(gaps[1]).toBe("Lightning Soul")
  end)

  -- v4.7.329, user: "Combo Boons we can add manually to our database" (22 reward blocks pasted from
  -- the game). A recipe is only printed on a block we must spend a contemplate to see, and a combo
  -- reward is never offered -- so without seeding, a chain is invisible until the reward is already
  -- in hand.
  it("the seeded recipes reach the catalogue and the chain index", function()
    local saved = M.history.boonLibrary
    M.history.boonLibrary = {}
    local ok, err = pcall(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      local chains = M.comboChains()
      local n = 0
      for _ in pairs(chains) do n = n + 1 end
      expect(n >= 22).toBeTrue()
      expect(table.concat(chains["Lightning Soul"], ", ")).toBe("Argent Scales, Electric Mastery, Energetic")
      expect(#chains["Ivory Scales"]).toBe(6)                     -- the longest recipe seen
      expect(#chains["Ancient Will"]).toBe(2)                     -- ...and the shortest
      -- TWO components: "Wrath and Righteousness" is itself a boon, which is why the game printed
      -- the line with no commas at all.
      expect(table.concat(chains["Bloodsworn Gods"], ", ")).toBe("Candour, Wrath and Righteousness")
      expect(M.comboFeeds("Azure Scales")[1] ~= nil).toBeTrue()   -- a component feeds its reward
      local rec = M.boonInfo("It All Ogre Now")
      expect(rec.rarity).toBe("legendary")
      expect(rec.category).toBeNil()   -- the game prints "Unset", which is not a category
      expect(M.boonInfo("Roaring Laughter").category).toBe("Offence")
      expect(M.boonInfo("Sea and Sky").maxEchoes).toBe(0)         -- every one says "Can echo: No"
      -- the seed literal must not be aliased into the saved catalogue
      expect(M.BOON_SEED["Lightning Soul"].unlocksFrom ~= M.BOON_COMBO_RECIPES["Lightning Soul"].unlocksFrom).toBeTrue()
      expect(M.boonInfo("Lightning Soul").unlocksFrom ~= M.BOON_COMBO_RECIPES["Lightning Soul"].unlocksFrom).toBeTrue()
    end)
    M.history.boonLibrary = saved
    if not ok then error(err, 0) end
  end)

  it("a seeded recipe never overwrites what a contemplate learnt", function()
    local saved = M.history.boonLibrary
    M.history.boonLibrary = { ["Lightning Soul"] = { description = "The game says something else now.",
      unlocksFrom = { "Something Else" }, category = "Offence" } }
    local ok, err = pcall(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      local rec = M.boonInfo("Lightning Soul")
      expect(rec.description).toBe("The game says something else now.")
      expect(#rec.unlocksFrom).toBe(1)
      expect(rec.category).toBe("Offence")
    end)
    M.history.boonLibrary = saved
    if not ok then error(err, 0) end
  end)

  -- Bloodsworn Gods prints "Candour and Wrath and Righteousness" -- no commas at all. Read against
  -- names we know, that is TWO boons, because "Wrath and Righteousness" is one of them.
  it("reads a recipe whose names are joined by 'and' alone", function()
    local info
    withLibrary({ ["Candour"] = { description = "d" }, ["Wrath and Righteousness"] = { description = "d" } }, function()
      info = M._parseContemplate({ "Rarity:             rare", "Category:           Offence",
        "Can echo:           No", "Unlocked By:        Candour and Wrath and Righteousness",
        "", "You gain the dawnhand defence and deal 10% more fire damage.", "", '"Bloodsworn."' })
    end)
    expect(#info.unlocksFrom).toBe(2)
    expect(info.unlocksFrom[2]).toBe("Wrath and Righteousness")
    expect(info.description).toBe("You gain the dawnhand defence and deal 10% more fire damage.")
  end)

  -- "Sea and Sky" is a boon NAME containing " and ", and it is a recipe's reward: seeding it is
  -- what lets the splitter put it back together when it appears inside a list.
  it("keeps a boon name that contains ' and ' once the seed knows it", function()
    local saved = M.history.boonLibrary
    M.history.boonLibrary = {}
    local ok, err = pcall(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      local names = M._splitBoonList("Sea and Sky and Impetuous")
      expect(#names).toBe(2)
      expect(names[1]).toBe("Sea and Sky")
    end)
    M.history.boonLibrary = saved
    if not ok then error(err, 0) end
  end)

  -- Most components have no description of ours: scoring them only when we had their text meant the
  -- seeded recipes paid nothing for exactly the boons they name (found live, v4.7.329).
  it("a component with no description of ours still earns its combo credit", function()
    local r
    withLibrary({ ["Frost Soul"] = { description = "d", contemplatedAt = 1,
                    unlocksFrom = { "Azure Scales", "Cold Mastery", "Nightwalker" } },
                  ["Azure Scales"] = { description = "d" } }, function()
      withSeed({}, function()
        r = holding({ "Azure Scales" }, function() return M.scoreBoon("Cold Mastery") end)
      end)
    end)
    expect(table.concat(r.effects, " "):find("2/3 toward Frost Soul", 1, true) ~= nil).toBeTrue()
    expect(r.score > 10).toBeTrue()
    expect(table.concat(r.flags, " "):find("not in the catalogue", 1, true) ~= nil).toBeTrue()
  end)

  it("mnem boondb shows a reward's recipe", function()
    local out
    withLibrary(WITH_CHAIN, function()
      out = capture(function() M.reportBoonDb("lightning") end)
    end)
    expect(out:find("combo: <grey>needs Argent Scales, Electric Mastery, Energetic", 1, true) ~= nil).toBeTrue()
  end)

  -- v4.7.328 REVIEW: a granted reward is never offered and never claimed, so the whole claim path
  -- was skipped for it -- combat flags, the bonuses panel and the tracker all missed a boon we hold.
  it("the bestowal does everything a claim does", function()
    local did = {}
    withLibrary(copyLib(WITH_CHAIN), function()
      holding({ "Argent Scales", "Electric Mastery", "Energetic" }, function()
        local real = { rec = M._recordClaim, flag = M.latchBoonFlag, bon = M.bonuses,
                       rep = M.reportBoonReceived, sel = M.reportBoonsSelected,
                       auto = M._auto, timer = tempTimer, echo = M.echo }
        M._recordClaim = function(n) did.claim = n end
        M.latchBoonFlag = function(n) did.flag = n end
        M.bonuses = { refresh = function() did.panel = true end }
        M.reportBoonReceived = function(n) did.posted = n end
        M.reportBoonsSelected = function(n) did.selected = n end -- a grant is NOT a selection
        M._auto = function() return true end
        tempTimer = function() return 1 end
        M.echo = function() end
        local ok, err = pcall(function() M.onComboBoonGranted("Lightning Soul") end)
        M._recordClaim, M.latchBoonFlag, M.bonuses = real.rec, real.flag, real.bon
        M.reportBoonReceived, M.reportBoonsSelected = real.rep, real.sel
        M._auto, tempTimer, M.echo = real.auto, real.timer, real.echo
        if not ok then error(err, 0) end
      end)
    end)
    expect(did.claim).toBe("Lightning Soul")
    expect(did.flag).toBe("Lightning Soul")
    expect(did.panel).toBeTrue()
    expect(did.posted).toBe("Lightning Soul")   -- /boon_received
    expect(did.selected).toBeNil()               -- never /boons_selected: we did not choose it
  end)

  -- The tracker's author (2026-09-21): "added a boons_received endpoint. If you can, use this
  -- instead of boons_offered endpoint to send the combo boons that are granted." The live schema
  -- calls it `/boon_received` and takes ONE BoonInfo.
  it("a granted boon is posted to /boon_received as a whole BoonInfo", function()
    reset(true)
    withLibrary({ ["Lightning Soul"] = { description = "Gain immunity to electric damage for 60 seconds at the start of each new ripple.",
      rarity = "rare", category = "Defence", maxEchoes = 0, comboBoon = nil,
      unlocksFrom = { "Argent Scales", "Electric Mastery", "Energetic" } } }, function()
      M.reportBoonReceived("Lightning Soul")
    end)
    expect(sent[1].url:find("/boon_received", 1, true) ~= nil).toBeTrue()
    local b = sent[1].payload.boon
    expect(b.name).toBe("Lightning Soul")
    expect(b.rarity).toBe("rare")
    expect(b.category).toBe("Defence")
    expect(b.unlocked_by).toBe("Argent Scales, Electric Mastery, Energetic")
    expect(b.num_echoes_possible).toBe(0)
    expect(sent[1].payload.selected).toBeNil()
  end)

  it("reports nothing for an empty name", function()
    reset(true)
    M.reportBoonReceived("")
    M.reportBoonReceived(nil)
    expect(#sent).toBe(0)
  end)

  it("a repeated grant line records nothing the second time", function()
    local claims = 0
    withLibrary(copyLib(WITH_CHAIN), function()
      holding({ "Argent Scales", "Electric Mastery", "Energetic", "Lightning Soul" }, function()
        local realRec, realTimer, realEcho = M._recordClaim, tempTimer, M.echo
        M._recordClaim = function() claims = claims + 1 end
        tempTimer = function() return 1 end
        M.echo = function() end
        local again
        local ok, err = pcall(function() again = M.onComboBoonGranted("Lightning Soul") end)
        M._recordClaim, tempTimer, M.echo = realRec, realTimer, realEcho
        if not ok then error(err, 0) end
        expect(again).toBeFalse() -- already held this run: the line is a replay
      end)
    end)
    expect(claims).toBe(0)
  end)

  it("with no run being tracked it records nothing and says so", function()
    local claims, out = 0, nil
    withLibrary(copyLib(WITH_CHAIN), function()
      local savedActive = M.run and M.run.active
      M.run = M.run or {}
      M.run.active = false
      local realRec, realTimer = M._recordClaim, tempTimer
      M._recordClaim = function() claims = claims + 1 end
      tempTimer = function() return 1 end
      local ok, err = pcall(function()
        out = capture(function() M.onComboBoonGranted("Lightning Soul") end)
      end)
      M._recordClaim, tempTimer, M.run.active = realRec, realTimer, savedActive
      if not ok then error(err, 0) end
    end)
    expect(claims).toBe(0)
    expect(out:find("no run is being tracked", 1, true) ~= nil).toBeTrue()
  end)

  it("queues the granted boon's own contemplate, and retries when the slot is busy", function()
    local delays, tries, screenArg = {}, 0, nil
    withLibrary(copyLib(WITH_CHAIN), function()
      holding({ "Argent Scales", "Electric Mastery", "Energetic" }, function()
        local real = { rec = M._recordClaim, timer = tempTimer, screen = M._boonScreenContemplate,
                       echo = M.echo, rep = M.reportBoonReceived }
        M._recordClaim, M.echo = function() end, function() end
        M.reportBoonReceived = function() end -- its queue arms timers of its own; not what this tests
        M._boonScreenContemplate = function(list)
          tries = tries + 1
          screenArg = list
          return tries >= 3 -- the offer chain holds the slot for the first two attempts
        end
        tempTimer = function(d, fn) delays[#delays + 1] = d; fn(); return 1 end
        local ok, err = pcall(function() M.onComboBoonGranted("Lightning Soul") end)
        M._recordClaim, tempTimer, M._boonScreenContemplate, M.echo = real.rec, real.timer, real.screen, real.echo
        M.reportBoonReceived = real.rep
        if not ok then error(err, 0) end
      end)
    end)
    expect(tries).toBe(3)                    -- retried until it got the slot
    expect(delays[1]).toBe(1)
    expect(delays[2] > delays[1]).toBeTrue() -- and waited longer before trying again
    expect(screenArg[1].name).toBe("Lightning Soul")
  end)

  it("mnem combos says when no run is being tracked, and flags a held reward it never learnt", function()
    local out
    withLibrary({ ["Lightning Soul"] = { unlocksFrom = { "A", "B" }, contemplatedAt = 1 } }, function()
      local savedActive = M.run and M.run.active
      M.run = M.run or {}
      M.run.active = false
      local ok, err = pcall(function() out = capture(function() M.reportCombos() end) end)
      M.run.active = savedActive
      if not ok then error(err, 0) end
    end)
    expect(out:find("No run is being tracked", 1, true) ~= nil).toBeTrue()
    expect(out:find("not contemplated yet", 1, true) ~= nil).toBeTrue()
  end)

  -- v4.7.331, user: "if a boon gives us something but costs an affliction or something we dont
  -- have immunity for, it should be scored significantly lower as the cost isn't worth it for the
  -- benefit". From their live screen: Corrupted Breath, +66% asphyxiation resist for permanent
  -- manaleech, was scoring 97 and being recommended.
  local COSTLY = { description = "Your asphyxiation resistance is increased by 66% but you suffer permanent manaleech.",
                   category = "Defence", rarity = "common", comboBoon = true }

  it("a cost we cannot shrug off guts the score, and says which affliction", function()
    local open, clean
    withLibrary({ ["Corrupted Breath"] = COSTLY,
                  ["Free Gift"] = { description = "Your asphyxiation resistance is increased by 66%.",
                                    category = "Defence", rarity = "common", comboBoon = true } }, function()
      withSeed({}, function()
        open = holding({}, function() return M.scoreBoon("Corrupted Breath") end)
        clean = holding({}, function() return M.scoreBoon("Free Gift") end)
      end)
    end)
    expect(open.score < clean.score / 2).toBeTrue()  -- significantly lower, not a small deduction
    expect(table.concat(open.flags, " "):find("cost: manaleech -- NOT immune", 1, true) ~= nil).toBeTrue()
  end)

  it("...and costs nothing worth speaking of once we are immune to that affliction", function()
    local immune, notImmune
    withLibrary({ ["Corrupted Breath"] = COSTLY,
                  ["Clear Mind"] = { description = "You are immune to the manaleech affliction." } }, function()
      withSeed({}, function()
        notImmune = holding({}, function() return M.scoreBoon("Corrupted Breath") end)
        immune = holding({ "Clear Mind" }, function() return M.scoreBoon("Corrupted Breath") end)
      end)
    end)
    expect(immune.score > notImmune.score * 3).toBeTrue()
    expect(table.concat(immune.effects, " "):find("cost: manaleech (immune)", 1, true) ~= nil).toBeTrue()
    expect(table.concat(immune.flags, " "):find("NOT immune", 1, true)).toBeNil()
  end)

  it("two afflictions cost more than one", function()
    local one, two
    withLibrary({ ["One"] = { description = "Your cold resistance is increased by 66%, but you suffer permanent dehydration.",
                              category = "Defence" },
                  ["Two"] = { description = "Your cold resistance is increased by 66%, but you suffer permanent dehydration and tenderskin.",
                              category = "Defence" } }, function()
      withSeed({}, function()
        one = holding({}, function() return M.scoreBoon("One") end)
        two = holding({}, function() return M.scoreBoon("Two") end)
      end)
    end)
    expect(two.score < one.score).toBeTrue()
  end)

  it("a boon already worth nothing is not IMPROVED by having a cost", function()
    -- The haircut is a FRACTION of the score, so on a boon already below zero an unguarded
    -- version would hand points back -- a cost making a bad boon look better.
    local costly, plain
    withLibrary({ ["Awful"] = { description = "Gain 5% resistance to fire damage, but you suffer permanent stuttering.",
                                category = "Defence", conflictsWith = { "Held Thing" } },
                  ["Awful Free"] = { description = "Gain 5% resistance to fire damage.",
                                     category = "Defence", conflictsWith = { "Held Thing" } },
                  ["Held Thing"] = { description = "d" } }, function()
      withSeed({}, function()
        costly = holding({ "Held Thing" }, function() return M.scoreBoon("Awful") end)
        plain = holding({ "Held Thing" }, function() return M.scoreBoon("Awful Free") end)
      end)
    end)
    expect(costly.score < 0).toBeTrue() -- the conflict still dominates...
    -- ...and the cost costs AT LEAST the flat charge. `<` alone would pass an unguarded haircut,
    -- which on a negative score hands back points and merely subtracts fewer of them.
    expect(costly.score <= plain.score - M.BOON_WEIGHTS.drawbackAffFlat).toBeTrue()
  end)

  it("the costly boon does not take the recommendation from a clean one", function()
    local out
    withLibrary({ ["Corrupted Breath"] = COSTLY,
                  ["Plain Utility"] = { description = "All scaling gear effects are magnified by 30%.",
                                        category = "Utility", rarity = "uncommon" } }, function()
      holding({}, function()
        withSeed({}, function()
          out = capture(function() M.offerSummary({ "Corrupted Breath", "Plain Utility" }) end)
        end)
      end)
    end)
    expect(out:find("RECOMMEND<reset> <gold>Plain Utility", 1, true) ~= nil).toBeTrue()
  end)

  -- v4.7.332, user: "Ogre is a bit different. Because it is giving us something for removing a
  -- stat. I would rate those higher than corrupted breath for example. Or losing a stat but
  -- gaining X is a lot better." A number traded for a number is a TRADE; a permanent affliction
  -- is a price. Before this, the numbers given back were invisible AND free.
  it("reads what a boon takes back in numbers", function()
    local pct = M._costLosses("You lose 2% critical strike chance, but you gain 10% resistance to all damage.")
    expect(#pct).toBe(1)
    expect(pct[1].kind).toBe("pct")
    expect(pct[1].amount).toBe(2)
    expect(pct[1].what).toBe("critical strike chance") -- the whole name, not its first word
    expect(M._costLosses("Gain 15% physical resistance, but lose 10% magical resistance.")[1].what).toBe("magical resistance")
    -- ...and the name still ends at its clause when no comma marks the join
    expect(M._costLosses("You lose 10% magical resistance and gain 5% fire resistance.")[1].what).toBe("magical resistance")
    local stat = M._costLosses("You deal 25% more damage but lose 1 constitution.")
    expect(stat[1].kind).toBe("stat")
    expect(stat[1].what).toBe("constitution")
    expect(M._costLosses("Gain 3 points of strength but lose 2 points of dexterity.")[1].what).toBe("dexterity")
    expect(#M._costLosses("You are immune to nausea.")).toBe(0)
    -- "reduced by" belongs to `_resistFrom`, which the advisor already charges: reading it here
    -- too would bill the same clause twice.
    expect(#M._costLosses("Your fire resistance is reduced by 20%.")).toBe(0)
  end)

  it("a stat traded away is charged, shown, and still beats an affliction", function()
    local ogre, corrupted
    withLibrary({ ["Ogre's Defence"] = { description = "You lose 2% critical strike chance, but you gain 10% resistance to all damage.",
                    category = "Defence", rarity = "uncommon" },
                  ["Corrupted Breath"] = { description = "Your asphyxiation resistance is increased by 66% but you suffer permanent manaleech.",
                    category = "Defence", rarity = "uncommon" } }, function()
      withSeed({}, function()
        ogre = holding({}, function() return M.scoreBoon("Ogre's Defence") end)
        corrupted = holding({}, function() return M.scoreBoon("Corrupted Breath") end)
      end)
    end)
    expect(table.concat(ogre.effects, " "):find("-2% critical strike chance", 1, true) ~= nil).toBeTrue()
    expect(#ogre.flags).toBe(0)                    -- a trade is not a warning
    expect(ogre.score > corrupted.score).toBeTrue() -- ...and it beats the same gain bought with an affliction
  end)

  it("a lost stat costs what the same stat would have earned", function()
    local con, dex
    withLibrary({ ["Con Cost"] = { description = "You deal 25% more damage but lose 1 constitution.", category = "Offence" },
                  ["Dex Cost"] = { description = "You deal 25% more damage but lose 1 dexterity.", category = "Offence" } }, function()
      withSeed({}, function()
        con = holding({}, function() return M.scoreBoon("Con Cost") end)
        dex = holding({}, function() return M.scoreBoon("Dex Cost") end)
      end)
    end)
    expect(con.score < dex.score).toBeTrue() -- constitution is health, and health is survival
  end)

  it("a boon that is inert without a spirit is not recommended either", function()
    local lib = { ["Spirit Gift"] = { description = "While attuned to Ourania, gain 20% resistance to all damage.",
                    category = "Defence", rarity = "rare", contemplatedAt = 1 },
                  ["Plain Utility"] = { description = "You may now utilise prism tattoos.",
                    category = "Utility", contemplatedAt = 1 } }
    local out
    local realAttuned = M._attuned
    M._attuned = function() return false end -- we are not attuned to it
    local ok, err = pcall(function()
      withLibrary(lib, function()
        holding({}, function()
          withSeed({}, function()
            out = capture(function() M.offerSummary({ "Spirit Gift", "Plain Utility" }) end)
          end)
        end)
      end)
    end)
    M._attuned = realAttuned
    if not ok then error(err, 0) end
    expect(out:find("inert: needs Ourania", 1, true) ~= nil).toBeTrue()
    expect(out:find("RECOMMEND<reset> <gold>Plain Utility", 1, true) ~= nil).toBeTrue()
  end)

  it("says a reward we HOLD was never contemplated, instead of showing nothing", function()
    local out
    withLibrary({ ["Lightning Soul"] = { unlocksFrom = { "A", "B" }, contemplatedAt = 1 },
                  ["A"] = { description = "d" }, ["B"] = { description = "d" } }, function()
      holding({ "A", "B", "Lightning Soul" }, function()
        out = capture(function() M.reportCombos() end)
      end)
    end)
    expect(out:find("HELD", 1, true) ~= nil).toBeTrue()
    expect(out:find("not contemplated yet", 1, true) ~= nil).toBeTrue()
  end)

  -- The review's two isolated guards: each was covered only by a case where the OTHER one also
  -- blocked the score, so deleting either alone changed nothing.
  it("pays nothing for a component of a chain already finished, even offered again", function()
    withLibrary(copyLib(WITH_CHAIN), function()
      local done = holding({ "Argent Scales", "Energetic", "Lightning Soul" }, function()
        return M.scoreBoon("Electric Mastery")
      end)
      expect(table.concat(done.effects, " "):find("toward", 1, true)).toBeNil()
      expect(table.concat(done.effects, " "):find("completes", 1, true)).toBeNil()
    end)
  end)

  it("pays nothing for a component we already hold, even offered again", function()
    withLibrary(copyLib(WITH_CHAIN), function()
      local r = holding({ "Argent Scales", "Electric Mastery" }, function()
        return M.scoreBoon("Electric Mastery")
      end)
      expect(table.concat(r.effects, " "):find("toward", 1, true)).toBeNil()
      expect(table.concat(r.effects, " "):find("completes", 1, true)).toBeNil()
    end)
  end)

  -- v4.7.328 REVIEW: combo credit was paid per chain, so two near-complete recipes could outweigh
  -- the penalty for a boon we cannot even hold.
  it("a boon feeding two chains earns one chain's worth, not both", function()
    local lib = copyLib(WITH_CHAIN)
    lib["Twin Reward"] = { description = "d", category = "Defence",
      unlocksFrom = { "Argent Scales", "Electric Mastery" }, contemplatedAt = 1 }
    lib["Electric Mastery"] = { description = "d", category = "Utility", contemplatedAt = 1 }
    local two, one
    withLibrary(lib, function()
      two = holding({ "Argent Scales", "Energetic" }, function() return M.scoreBoon("Electric Mastery") end)
    end)
    local solo = copyLib(lib)
    solo["Twin Reward"] = nil
    withLibrary(solo, function()
      one = holding({ "Argent Scales", "Energetic" }, function() return M.scoreBoon("Electric Mastery") end)
    end)
    expect(two.score).toBe(one.score)                       -- the second chain adds no points...
    expect(#two.effects > #one.effects).toBeTrue()          -- ...but is still named
    expect(table.concat(two.effects, " "):find("Twin Reward", 1, true) ~= nil).toBeTrue()
  end)

  it("never recommends a boon we cannot use while a usable one is on the screen", function()
    local lib = copyLib(WITH_CHAIN)
    lib["Electric Mastery"] = { description = "d", category = "Utility", contemplatedAt = 1,
      conflictsWith = { "Argent Scales" } } -- we hold Argent Scales
    lib["Plain Defence"] = { description = "d", category = "Defence", contemplatedAt = 1 }
    local out
    withLibrary(lib, function()
      holding({ "Argent Scales", "Energetic" }, function()
        withSeed({}, function()
          out = capture(function() M.offerSummary({ "Electric Mastery", "Plain Defence" }) end)
        end)
      end)
    end)
    expect(out:find("RECOMMEND<reset> <gold>Plain Defence", 1, true) ~= nil).toBeTrue()
    expect(out:find("CONFLICTS with Argent Scales", 1, true) ~= nil).toBeTrue()
  end)

  it("when every option has a problem it says so, and says what is wrong with its pick", function()
    local lib = { ["Bad One"] = { description = "d", category = "Defence", contemplatedAt = 1,
                    conflictsWith = { "Argent Scales" } },
                  ["Bad Two"] = { description = "d", category = "Utility", contemplatedAt = 1,
                    conflictsWith = { "Argent Scales" } },
                  ["Argent Scales"] = { description = "d" } }
    local out
    withLibrary(lib, function()
      holding({ "Argent Scales" }, function()
        withSeed({}, function()
          out = capture(function() M.offerSummary({ "Bad One", "Bad Two" }) end)
        end)
      end)
    end)
    expect(out:find("but <indian_red>conflicts with Argent Scales", 1, true) ~= nil).toBeTrue()
    expect(out:find("Every option has a problem", 1, true) ~= nil).toBeTrue()
  end)
end)

-- =====================================================================================
-- THE BOONS ROW ARMS THE GENERIC FLAGS (v4.7.350)
--
-- `M.BOON_FLAGS` claimed it latched from "the BOON CLAIM ... and the BOONS list (on demand, and
-- after a reload)". Only the claim half was real. `M._relatchBoons` sends `boon claimed` once per
-- run so a mid-run reimport can put owned boons back; the rows arrived at trigger
-- `mnemosyne/013_Boons_List_Row`, were recorded, coloured and annotated -- and never latched. The
-- boons with a hand-written row trigger came back; the fifteen that live only in the table did
-- not, Dead Breath and Deathtempest among them. These run the REAL trigger file against the REAL
-- table, because the bug was a missing call between two pieces that each looked correct alone.
describe("the BOONS row arms the generic boon flags", function()
  local ROW = "src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/013_Boons_List_Row.lua"

  -- The row also teaches the boon LIBRARY, which other tests in this file read. Stub that side
  -- so twenty synthetic rows cannot leak into their fixtures (the v4.7.328 shared-fixture lesson).
  -- `inside` defaults to TRUE: the row only arms inside the tower (v4.7.351), and these tests
  -- used to pass only because an EARLIER test in this file had left inMnemosyne set.
  local function withRows(fn, inside)
    local learn, save = M._learnBoon, M._historySaveSoon
    local owned = ataxiaTemp.boonsOwned
    local wasIn = ataxiaBasher.inMnemosyne
    ataxiaBasher.inMnemosyne = (inside ~= false)
    M._learnBoon = function() return {} end
    M._historySaveSoon = function() end
    local ok, err = pcall(fn)
    M._learnBoon, M._historySaveSoon = learn, save
    ataxiaTemp.boonsOwned = owned
    ataxiaBasher.inMnemosyne = wasIn
    matches, line = nil, nil
    if not ok then error(err, 0) end
  end

  local function row(name, echoes, rarity)
    line = name .. "               " .. echoes .. "          " .. rarity
    matches = { line, name, tostring(echoes), rarity }
    dofile(ROW)
  end

  local function clearFlags()
    for _, flag in pairs(M.BOON_FLAGS) do _G[flag] = nil end
  end

  it("a reload's `boon claimed` puts Dead Breath and Deathtempest back", function()
    clearFlags()
    withRows(function()
      row("Dead Breath", 1, "rare")
      row("Deathtempest", 1, "rare")
    end)
    expect(mnemDeadBreath).toBeTrue()
    expect(mnemDeathtempest).toBeTrue()
    clearFlags()
  end)

  it("every boon in the table comes back, not just the two that were noticed", function()
    clearFlags()
    withRows(function()
      for name in pairs(M.BOON_FLAGS) do row(name, 1, "rare") end
    end)
    local missing = {}
    for name, flag in pairs(M.BOON_FLAGS) do
      if _G[flag] ~= true then missing[#missing + 1] = name end
    end
    expect(#missing).toBe(0)
    clearFlags()
  end)

  -- ONLY INSIDE THE TOWER (v4.7.351, deep review). Of the table's twenty consumers exactly one
  -- checks for itself, so a list printed outside a run would have armed the belch and the
  -- soulstorm for ordinary bashing.
  it("arms nothing outside the tower", function()
    clearFlags()
    withRows(function()
      row("Dead Breath", 1, "rare")
      row("Deathtempest", 1, "rare")
    end, false)
    expect(mnemDeadBreath).toBeNil()
    expect(mnemDeathtempest).toBeNil()
  end)

  -- The per-boon row triggers carry the same gate (v4.7.351): run each one's body both ways.
  it("the per-boon rows (098-103) arm only inside the tower", function()
    local T = "src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/"
    local cases = { { "098_Graveborn.lua", "mnemGraveborn" }, { "099_Bloodletters_Fury.lua", "psionBloodletter" },
                    { "100_Razor_Clarity.lua", "psionRazorClarity" }, { "101_Mindbreak.lua", "psionMindbreak" },
                    { "102_Psiwave.lua", "psionPsiwave" }, { "103_Earthquake.lua", "psionEarthquake" } }
    local wasIn = ataxiaBasher.inMnemosyne
    local ok, err = pcall(function()
      for _, c in ipairs(cases) do
        _G[c[2]] = nil
        ataxiaBasher.inMnemosyne = false
        dofile(T .. c[1])
        expect(_G[c[2]]).toBeNil()
        ataxiaBasher.inMnemosyne = true
        dofile(T .. c[1])
        expect(_G[c[2]]).toBeTrue()
        _G[c[2]] = nil
      end
    end)
    ataxiaBasher.inMnemosyne = wasIn
    if not ok then error(err, 0) end
  end)

  it("a row for a boon outside the table arms nothing and breaks nothing", function()
    clearFlags()
    withRows(function() row("Some Boon Nobody Wired", 2, "common") end)
    for _, flag in pairs(M.BOON_FLAGS) do expect(_G[flag]).toBeNil() end
  end)

  it("still records ownership exactly as before -- the latch is an addition, not a swap", function()
    clearFlags()
    local seen
    local learn, save = M._learnBoon, M._historySaveSoon
    local owned = ataxiaTemp.boonsOwned
    M._learnBoon = function(n, _, r) seen = { n, r }; return {} end
    M._historySaveSoon = function() end
    ataxiaTemp.boonsOwned = {}
    local ok, err = pcall(function() row("Deathtempest", 1, "rare") end)
    local ownedNow = ataxiaTemp.boonsOwned["Deathtempest"]
    M._learnBoon, M._historySaveSoon = learn, save
    ataxiaTemp.boonsOwned = owned
    matches, line = nil, nil
    if not ok then error(err, 0) end
    expect(seen[1]).toBe("Deathtempest")
    expect(seen[2]).toBe("rare")
    expect(ownedNow).toBe("rare")
    clearFlags()
  end)
end)

-- =====================================================================================
-- RUN START CLEARS THE WHOLE REGISTRY, and a ripple forgets the gravehands room (v4.7.351).
describe("run and ripple boundaries", function()
  -- The confirmed run END always cleared all of M.BOON_FLAGS; run START cleared only a
  -- hand-written list missing 13 of the 20. A run that ended without its confirmation line left
  -- those boons live into normal bashing. This runs the REAL run-start trigger.
  it("the run-start trigger clears every generically-latched boon", function()
    local realStart, realHere, realRevert = M.onRunStart, ataxiaBasher_mnemHere, ataxiaBasher_berserkersEdgeRevert
    M.onRunStart = function() end
    ataxiaBasher_mnemHere, ataxiaBasher_berserkersEdgeRevert = nil, nil
    for _, flag in pairs(M.BOON_FLAGS) do _G[flag] = true end
    local ok, err = pcall(dofile, "src_new/triggers/levi_ataxia/for_levi/leviticus/mnemosyne/001_Run_Start.lua")
    M.onRunStart, ataxiaBasher_mnemHere, ataxiaBasher_berserkersEdgeRevert = realStart, realHere, realRevert
    local still = {}
    for name, flag in pairs(M.BOON_FLAGS) do
      if _G[flag] then still[#still + 1] = name end
      _G[flag] = nil
    end
    if not ok then error(err, 0) end
    expect(#still).toBe(0)
  end)

  -- The tower reuses room numbers across ripples; the once-per-room gravehands record is keyed on
  -- one, so a reused room read as already summoned-in and was skipped.
  it("a new ripple forgets which room had its gravehands", function()
    ataxiaTemp.infTyrannyRoom, ataxiaTemp.gravehandsAt = 1234, 999
    ataxiaTemp.gravehandsSeen, ataxiaTemp.gravehandsRetried = true, true
    M.onRippleReset()
    expect(ataxiaTemp.infTyrannyRoom).toBeNil()
    expect(ataxiaTemp.gravehandsAt).toBeNil()
    expect(ataxiaTemp.gravehandsSeen).toBeNil()
    expect(ataxiaTemp.gravehandsRetried).toBeNil()
  end)
end)
