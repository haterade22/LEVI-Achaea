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
    M.run.active = true                 -- pretend startRun already ran
    M.onMonsters("a host of orcs")
    M.run.active = false                -- onRipple must re-assert it
    M.onRipple(3)
    expect(M.run.active).toBeTrue()
    -- ripple 3 (>0) enqueued, monsters flushed behind it
    expect(sent[1].url).toContain("/ripple_level")
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

  it("maps 'Can echo: Yes' to 1", function()
    local info = M._parseContemplate({ "Rarity:  legendary", "Can echo:  Yes", "Desc.", "", '"Q."' })
    expect(info.num_echoes_possible).toBe(1)
    expect(info.rarity).toBe("legendary")
  end)
end)

-- ─── Monster capture (onGo commits the countdown-captured candidate) ─────────

describe("onGo monster capture", function()
  it("commits the captured mob candidate on GO!, trimmed", function()
    reset(true)
    M._mobCandidate = "Grave-soil erupts across Azdun as a ghastly horde of the restless dead rises, drawn forth by dark magics."
    M.onGo()
    expect(#M.run.pendingMonsters).toBe(1)
    expect(M.run.pendingMonsters[1]).toBe("a ghastly horde of the restless dead")
    expect(M._mobCandidate).toBeNil()
  end)

  it("does nothing when there is no candidate", function()
    reset(true)
    M.onGo()
    expect(#M.run.pendingMonsters).toBe(0)
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

  it("returns nil when there is no 'a <quantifier> of <mob>' phrase", function()
    expect(M._extractMob("The boss glares at you menacingly.")).toBeNil()
  end)
end)
