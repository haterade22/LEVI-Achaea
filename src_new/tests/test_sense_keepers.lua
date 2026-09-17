--- test_sense_keepers.lua — Monk/Blademaster DEAF + BLIND keepers (deffing/007)
--
-- From a live log, 12:58:32, six attempts inside 0.15s for one trance:
--   You stare straight ahead and concentrate on a distant focal point.   (x6)
--   The world about you falls silent as the deafness trance sinks upon you.
--
-- The keeper lived in the prompt trigger and its only guard was `incomingdeafness`, set by the
-- trigger matching the game's ATTEMPT ECHO -- so it could not close until our command had made
-- the round trip. Every prompt inside that window re-sent. The hold has to be stamped at SEND
-- time, the only moment we know something is in flight.
--
-- The same block's blind half was unreachable: it read `incommingblindness` (two m's), assigned
-- nowhere, and `nil == false` is FALSE in Lua.

require("mock_mudlet")

-- RESTORE WHAT WE OVERRIDE. test_runner loads every test_*.lua into ONE Lua state, so an
-- override left installed here is inherited by every file sorted after this one -- and worse,
-- a later file that captures `local _mockSend = send` AT LOAD TIME then "restores" OUR recorder
-- rather than the mock. That is exactly what was happening to test_swarm_tactics.lua:16.
-- AGENTS.md (v4.7.257) already names this: a leaked `send` produced 15 unrelated failures from
-- one real one. See restoreGlobals() at the end of this file.
local _realSend, _realEpoch = send, getEpoch

local sent = {}
function send(cmd) sent[#sent + 1] = cmd end

local echoed = {}
local _realEcho = ataxiaEcho
function ataxiaEcho(m) echoed[#echoed + 1] = tostring(m) end

local clock = 10000
function getEpoch() return clock end

ataxia = ataxia or {}
ataxia.defences = {}
ataxiaTemp = {}
gmcp = gmcp or {}
gmcp.Char = { Status = { class = "Monk" } }

dofile("src_new/scripts/levi_ataxia/levi/ataxia/deffing/007_Sense_Keepers.lua")

local function reset(class)
  sent, echoed = {}, {}
  clock = 10000
  ataxia.defences = {}
  ataxiaTemp = {}
  gmcp.Char = { Status = { class = class or "Monk" } }
end

local function countOf(cmd)
  local n = 0
  for _, c in ipairs(sent) do if c == cmd then n = n + 1 end end
  return n
end

describe("Monk/BM sense keepers", function()
  it("raises both senses when neither is up", function()
    reset()
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1)
    expect(countOf("blind")).toBe(1)
  end)

  -- THE BUG: six prompts inside one round trip produced six DEAF.
  it("sends ONE deaf across six prompts inside the hold", function()
    reset()
    for _ = 1, 6 do
      clock = clock + 0.03 -- the live log's cadence: 6 prompts in ~0.15s
      ataxia_senseKeepTick()
    end
    expect(countOf("deaf")).toBe(1)
    expect(countOf("blind")).toBe(1)
  end)

  it("retries once the hold expires -- a lost trance must not be permanent", function()
    reset()
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1)
    -- Pin the VALUE, not the constant: advancing by `ataxia_SENSE_HOLD` reads the very thing
    -- under test, so a hold wrongly set to 600s would leave the keeper effectively off for ten
    -- minutes after any lost trance with the suite still green.
    expect(ataxia_SENSE_HOLD).toBe(10) -- measured (3.2-5.9s trance), not the inherited 6
    clock = clock + 10.1
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(2)
  end)

  it("stops once GMCP reports the defence up", function()
    reset()
    ataxia.defences.deafness = true
    ataxia.defences.blindness = true
    clock = clock + 100
    ataxia_senseKeepTick()
    expect(#sent).toBe(0)
  end)

  -- The game's attempt echo proves something is in flight whoever started it.
  it("a MANUALLY typed DEAF suppresses the keeper's duplicate", function()
    reset()
    ataxia_senseAttemptSeen("deafness")
    -- AN ATTEMPT IS NOT A DEFENCE (v4.7.280). The old triggers wrote
    -- `ataxia.defences.deafness = true` from this line; an INTERRUPTED trance then left us
    -- believing in a defence GMCP never confirmed and so will never Remove -- a keeper
    -- silently off for the session. Without this assertion the whole headline decision of
    -- v4.7.315 can be reverted with the suite still green.
    expect(ataxia.defences.deafness).toBe(nil)
    clock = clock + 0.1
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(0)
    expect(countOf("blind")).toBe(1) -- unrelated sense is untouched
  end)

  -- GMCP is the only authority on whether the defence is up, so the drop/re-raise cycle has
  -- to work off Char.Defences alone.
  it("re-raises as soon as GMCP drops the defence, and holds if the stamp is fresh", function()
    reset()
    ataxia.defences.deafness = true
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(0)          -- up: silent
    ataxia.defences.deafness = nil           -- GMCP Remove ("Your hearing is suddenly restored.")
    clock = clock + 100                      -- any stamp has long aged out
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1)          -- down: re-raised at once
    ataxia.defences.deafness = nil
    clock = clock + 0.1                      -- same drop, stamp still fresh
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1)          -- held, not re-sent
  end)

  it("ignores an attempt echo for a sense it does not keep", function()
    reset()
    ataxia_senseAttemptSeen("numbness") -- must not error, must not stamp anything
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1)
    expect(countOf("blind")).toBe(1)
  end)

  -- The old guard was `incomingdeafness == false` against a global assigned nowhere at load:
  -- nil == false is FALSE, so a fresh session raised nothing until the first manual DEAF.
  it("a missing stamp reads READY, not blocked", function()
    reset()
    ataxiaTemp = {}
    expect(ataxia_senseKeepNeeded({ def = "deafness", stamp = "deafAttemptAt" })).toBeTrue()
  end)

  it("a future-dated stamp cannot disable the keeper forever", function()
    reset()
    ataxiaTemp.deafAttemptAt = clock + 9999
    expect(ataxia_senseKeepNeeded({ def = "deafness", stamp = "deafAttemptAt" })).toBeTrue()
  end)

  -- The switch to reach for if blindness turns out to empty gmcp Char.Items (v4.7.125's shape).
  it("honours the per-sense opt-out, and defaults to ON", function()
    reset()
    expect(ataxia_senseKeepEnabled("blindness")).toBeTrue() -- no config = enabled
    ataxia.settings = { senseKeep = { blindness = false } }
    ataxia_senseKeepTick()
    expect(countOf("blind")).toBe(0)
    expect(countOf("deaf")).toBe(1) -- the other sense is unaffected
    ataxia.settings = nil
  end)

  -- The landed line is what lets the hold be sized for a slow trance (3.2-5.9s measured) without
  -- masking an opponent stripping the defence a moment later.
  it("the landed line collapses the hold, so a STRIP is answered at once", function()
    reset()
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1)
    clock = clock + 4                       -- mid-trance, well inside the hold
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1)         -- held, correctly
    ataxia_senseLanded("deafness")          -- trigger 773
    ataxia.defences.deafness = true         -- GMCP Add follows
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1)         -- up: silent
    ataxia.defences.deafness = nil          -- an opponent strips it immediately
    clock = clock + ataxia_SENSE_LANDED_GRACE + 0.1
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(2)         -- re-raised in ~1.5s, not ~10s
  end)

  -- Collapsing to a GRACE rather than clearing outright: GMCP's Add may lag the landed line,
  -- and a cleared stamp would re-send into a defence that is already coming up.
  it("the landed line leaves a grace for GMCP to catch up", function()
    reset()
    ataxia_senseKeepTick()
    ataxia_senseLanded("deafness")
    ataxia_senseKeepTick()                  -- same instant, GMCP has not reported yet
    expect(countOf("deaf")).toBe(1)         -- no duplicate
  end)

  it("a landed line never writes the defence -- GMCP owns the state", function()
    reset()
    ataxia_senseLanded("deafness")
    expect(ataxia.defences.deafness).toBe(nil)
  end)

  -- "You are already deaf." -- a refusal is a free state probe (the Fury / shin-augment rule).
  it("a refusal takes the FULL hold, so we stop re-probing", function()
    reset()
    ataxia_senseRefused("deafness")
    clock = clock + 5 -- past the landed-line grace, well inside the full hold
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(0)
    clock = clock + 6 -- now past the full hold
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1) -- re-probes rather than giving up forever
  end)

  -- The tempting wrong fix: the game just STATED the state, so write it. That would be a belief
  -- nothing can clear, because a GMCP that never Added will never Remove (v4.7.280).
  it("a refusal never writes the defence, and warns ONCE about the disagreement", function()
    reset()
    ataxia.defences.deafness = nil -- GMCP says down; the game says already deaf
    ataxia_senseRefused("deafness")
    expect(ataxia.defences.deafness).toBe(nil)
    local warned = 0
    for _, m in ipairs(echoed) do
      if m:find("GMCP does not list it", 1, true) then warned = warned + 1 end
    end
    expect(warned).toBe(1)
    clock = clock + 100
    ataxia_senseRefused("deafness")
    ataxia_senseRefused("deafness")
    warned = 0
    for _, m in ipairs(echoed) do
      if m:find("GMCP does not list it", 1, true) then warned = warned + 1 end
    end
    expect(warned).toBe(1) -- still once; a warning after every refusal is one you learn to ignore
  end)

  it("a refusal that AGREES with GMCP says nothing", function()
    reset()
    ataxia.defences.deafness = true
    ataxia_senseRefused("deafness")
    expect(#echoed).toBe(0)
  end)

  it("is inert for every other class", function()
    reset("Bard")
    ataxia_senseKeepTick()
    expect(#sent).toBe(0)
  end)

  it("runs for Blademaster as well as Monk", function()
    reset("Blademaster")
    ataxia_senseKeepTick()
    expect(countOf("deaf")).toBe(1)
  end)
end)

-- Hand the globals back (see the note at the top): every later test_*.lua shares this state.
send, getEpoch, ataxiaEcho = _realSend, _realEpoch, _realEcho
