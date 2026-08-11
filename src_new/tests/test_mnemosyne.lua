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
    M.reportBoonsOffered({ { name = "Reaper" } })
    expect(sent[1].payload.class).toBe(nil)
    expect(sent[1].payload.race).toBe(nil)
    expect(sent[1].payload.offered[1].name).toBe("Reaper") -- the post still goes
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

  it("loads, and carries descriptions for every entry", function()
    withSeed(function()
      dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/010_Boon_Seed.lua")
      local st = M.boonDbStats()
      expect(st.total > 250).toBeTrue()
      expect(st.described).toBe(st.total)   -- a row with no effect text is not worth seeding
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
      expect(M._boonDrawbacks(seed["Coarse Flesh"].description)[1]).toBe("timeflux")
      expect(M._boonDrawbacks(seed["Corrupted Blood"].description)[1]).toBe("nausea")
    end)
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
    M.explore.moving = movedDir and true or false
    M.explore.fromDir = movedDir
    MAP._lastMoveDir = nil
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

  it("a non-planar step does not move us on the grid", function()
    fresh()
    look({ down = 0 })
    MAP.drMoved("down")
    expect(MAP.dr.x).toBe(0)
    expect(MAP.dr.y).toBe(0)
  end)

  MAP.drForce = nil -- restore for anything after us
end)
