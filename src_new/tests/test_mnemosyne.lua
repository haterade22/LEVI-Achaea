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
  it("a new offer screen replaces the pending one", function()
    reset(true)
    M._offerAfterRipple({ { name = "First", description = "d" } })
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
    realSend = send
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
