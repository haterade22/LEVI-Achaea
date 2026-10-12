--- test_shikudo_ledger.lua -- the Shikudo strike ledger (phase 3a, v4.7.419), and the two
--- duplicate recorders it retires (586; 3rd_person_shikudo/001 without the dedupe).
--
-- Ruku to the arm prints "The staff connects to the right arm with a resounding crack, the limb
-- flopping uselessly." on light and damaged hits alike (absorbed ones are assumed, unseen in a log),
-- and the line names no target, so
-- only a DAMAGED ruku to the arm was ever recorded (578/584, from the damage line). shikudo/010 keeps
-- the strike in flight: 587 opens it, 789 hands it the lines that can end it, the prompt (318)
-- expires it, and it records only on a line.
--
-- Lines are VERBATIM. attacker:N = kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt
-- without its client's ".." and " (8.4%)" suffixes and "Processed Affliction(...)" echoes; Mystor's
-- logs without " Kata is N". The REAL ledger, the REAL trigger patterns (trigger_lib, rows wrapped as
-- the server wraps them) and the REAL trigger bodies, 318's whole body at every prompt, run together
-- in a private environment per test (world()), so no global is replaced -- tempLineTrigger,
-- getEpoch, line, target and the rest are that environment's. It takes only the standard library
-- from _G, so nothing another test file left there can decide a result, and _G is still
-- snapshotted here and restored at the end (one Lua state).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local TL = dofile("src_new/tests/trigger_lib.lua")
local DIR = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local LEDGER = "src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/010_Shikudo_Strike_Ledger.lua"
local F587, F789 = "587_Shikudo_Strike_Start.lua", "789_Shikudo_Strike_Outcome.lua"
local T = "Claes"
local WIDTHS = { 100, 119, 124 }

local RUKU_R = "You spin a full rotation, bringing a twisted oaken staff around in a blur of motion to smash into the right arm of Claes." -- attacker:440, :374, :2568
local RUKU_L = "You spin a full rotation, bringing a twisted oaken staff around in a blur of motion to smash into the left arm of Claes." -- attacker:2572
local RUKU_TORSO = "You spin a full rotation, bringing a twisted oaken staff around in a blur of motion to smash into the torso of Claes." -- attacker:893
-- Ruku to the arm as the FIRST strike of a combo, as 584 matches it. No log has it to the arm; the
-- torso one is attacker:1807 ("...crack against her torso.").
local WHIP_R = "You whip a twisted oaken staff at Claes in a controlled arc, bringing its length to crack against her right arm."
local ARM_R = "The staff connects to the right arm with a resounding crack, the limb flopping uselessly." -- attacker:377
local ARM_L = "The staff connects to the left arm with a resounding crack, the limb flopping uselessly." -- attacker:2575
local PARRY = "Claes parries the attack with a deft manoeuvre." -- attacker:444
local FRONTKICK = "You lash out with a straight kick at the left shoulder of Claes." -- attacker:433
local FUMBLE = "You fumble your strike, the attack going wide." -- attacker:434
local KURO = "Falling back into a low crouch, you lash out with a swift strike at the left thigh of Claes." -- attacker:436
local KURO_FX = "The staff cracks across the left thigh of Claes." -- attacker:437
local TORSO_FX = "Claes staggers as the staff cracks across her ribs, sweat breaking out upon her forehead." -- attacker:895
local LIVE = "Lunging forward, you drive the end of a twisted oaken staff viciously into the solar plexus of Claes." -- attacker:1645
local LIVE_LATER = "Turning with the motion, you channel the momentum of your previous strike into a thrust at the solar plexus of Claes with a twisted oaken staff." -- attacker:832
local LIVE_FX = "The breath of Claes leaves her in an explosive gasp as the end of the staff smashes home." -- attacker:1647
local SHIELD = "A dizzying beam of energy strikes you as your attack rebounds off of Agathon's shield." -- LcJC-rJ5:207
local PROMPT = "H:4360|79% M:4391|88%  15:04:09:172  [ Dominius ][0|96.8|0|0|70.8|94.6] ( -294h 5% )[wear leth]" -- defender:14

local function dmg(limb, pct)
  return "As your blow lands with a crunch, you perceive that you have dealt " .. (pct or "8.4") .. "% damage to "
    .. T .. "'s " .. limb .. "." -- attacker:376
end

-- Every line 789 is written for, with what the ledger must read it as.
local OUTCOMES = {
  { PARRY, "parry" },
  { ARM_R, "arm" },
  { ARM_L, "arm" },
  { TORSO_FX, "effect" },
  { FUMBLE, "fumble" },
  { dmg("right arm"), "damage" },
  { SHIELD, "shield" },
  { KURO_FX, "effect" },
  { LIVE_FX, "effect" },
  { "The staff smashes into the face of Claes with a sickening crunch.", "effect" }, -- attacker:957
  { "The staff connects to the side of Claes's head with a resounding crack.", "effect" }, -- attacker:953
  { "The end of the staff drives viciously into the kidneys of Claes.", "effect" }, -- attacker:2669
  { "The end of the staff smashes into the exposed throat of Claes, crushing cartilage.", "effect" }, -- attacker:2662
  { "The end of your staff smashes the magical shield surrounding Claes in an explosion of translucent shards.", "effect" }, -- attacker:1111
  { "Horror overcomes the face of Agathon as his body locks in paralysis.", "effect" }, -- vNTjvghY:185
  { "The instep of your foot smashes into the left underarm of Claes, throwing her from her feet and sending her spinning to the ground.", "effect" }, -- attacker:362
  { "Your foot catches Claes under the chin, snapping her head back.", "effect" }, -- attacker:839
  { "Your foot drives into the solar plexus of Claes.", "effect" }, -- attacker:1656
  { "You feel the satisfying crunch of bone under the impact of your heel.", "effect" }, -- attacker:72
  { "The staff sweeps the legs out from under Claes, sending her sprawling.", "effect" }, -- attacker:2456
}

-- Every strike line in the attacker log, plus the first-strike ruku to the arm.
local STRIKES = {
  RUKU_R, RUKU_L, RUKU_TORSO, WHIP_R, FRONTKICK, KURO, LIVE, LIVE_LATER,
  "You whip a twisted oaken staff at Claes in a controlled arc, bringing its length to crack against her torso.", -- :1807
  "Dropping into a lower stance, you sweep a twisted oaken staff at the left thigh of Claes.", -- :1898
  "Snapping your leg out to its full extent, you drive a heel into the left knee of Claes.", -- :70
  "You whip a twisted oaken staff at the side of Claes's neck.", -- :829
  "Snapping back into a ready stance, you whirl a twisted oaken staff in a long sweep at the head of Claes.", -- :951
  "Bracing your back foot, you lunge forward with a twisted oaken staff at the face of Claes.", -- :955
  "Reversing your grip on a twisted oaken staff, you drive the top of the weapon into the throat of Claes.", -- :2658
  "You flow around Claes, a twisted oaken staff lashing out in a swift strike at her kidneys.", -- :2665
  "You drive your foot up in a rising kick at the head of Claes.", -- :837
  "You drive your foot up in a rising kick at the torso of Claes.", -- :1654
  "Taking a firm hold of a twisted oaken staff you whip it in a wide sweep at the legs of Claes.", -- :2455
  "Springing off your back foot, the heel of your foot smashes into the temple of Claes with flawless precision.", -- :22
  "Bracing your feet, you drive a twisted oaken staff towards Claes.", -- :1109
}

local function read(path)
  local f = assert(io.open(path, "r"), "no such file: " .. path)
  local s = f:read("*a")
  f:close()
  return s
end

local function body(file)
  return (read(DIR .. file):match("%]%]%-%-\r?\n(.*)$"))
end

local function code(file)
  return (body(file):gsub("%-%-[^\n]*", ""))
end

local function pats(file) return TL.patterns(DIR .. file) end

local function count(list, x)
  local n = 0
  for _, v in ipairs(list) do if v == x then n = n + 1 end end
  return n
end

local NOOP = { "selectString", "selectCurrentLine", "fg", "bg", "setBold", "resetFormat", "deselect",
  "replace", "moveCursor", "moveCursorEnd", "getLineNumber", "cecho", "echo", "deleteFull", "deleteLine" }

-- The Lua standard library is ALL an environment here takes from _G. Test files share one Lua
-- state, and the ledger and the trigger bodies read mutable globals (ignoreThirdPerson above all):
-- a value an earlier file left in _G would decide what they record (review of v4.7.419: with
-- _G.ignoreThirdPerson = true, 10 of these tests failed). Anything else they read is seeded, and
-- a name nobody seeded reads nil, so a missing stub fails loudly rather than borrowing from _G.
local STD = {}
for _, k in ipairs({ "string", "table", "math", "pairs", "ipairs", "next", "type", "tostring", "tonumber",
  "select", "unpack", "rawget", "rawset", "setmetatable", "getmetatable", "pcall", "error", "assert" }) do
  STD[k] = true
end
local function stdOnly(_, k)
  if STD[k] then return _G[k] end
end

-- A Mudlet in miniature: the REAL ledger loaded into a private environment, with the trigger
-- globals stubbed and recorded. Nothing written here reaches _G.
local function world(opts)
  opts = opts or {}
  local w = { affs = {}, sent = {}, echoes = {}, tails = {}, clock = 1000, prompts = 0, disabled = {} }
  local has = {}
  for a, v in pairs(opts.has or {}) do has[a] = v end
  local env = {
    target = opts.target or T,
    line = "",
    partyrelay = opts.partyrelay or false,
    ignoreThirdPerson = false,          -- as 318 leaves it at every prompt
    isTargeted = function(n) return type(n) == "string" and n:lower() == tostring(w.env.target):lower() end,
    tarAffed = function(...)
      for _, a in ipairs({ ... }) do w.affs[#w.affs + 1] = a; has[a] = true end
    end,
    erAff = function(a) has[a] = nil end,
    haveAff = function(a) return has[a] == true end,
    send = function(c) w.sent[#w.sent + 1] = c end,
    ataxia_isClass = function(c) return c:lower() == (opts.class or "monk") end,
    getEpoch = function() return w.clock end,
    tempLineTrigger = function(from, n, fn) w.tails[#w.tails + 1] = { from = from, n = n, fn = fn } end,
    ataxiaEcho = function(s) w.echoes[#w.echoes + 1] = s end,
    ataxiaTemp = {},
    ataxiaTables = { limbData = {} },
    ataxia = { afflictions = {}, settings = { raid = { enabled = false } } },
    tAffs = {},
    -- What 318's WHOLE body reads (prompt(w) runs all of it), set so it takes its quiet branches:
    -- no basher, no class to answer, no limb counts, no room.
    ataxia_promptCommands = function() w.prompts = w.prompts + 1 end,
    haveDef = function() return false end,
    lpreapply = function() end,
    ataxiaBasher = { enabled = false },
    ataxiaNDB_getClass = function() return nil end,
    lb = {},
    gmcp = {},
    isActive = function() return false end,
    disableTrigger = function(name) w.disabled[#w.disabled + 1] = name end,
  }
  for _, n in ipairs(NOOP) do env[n] = function() return 0 end end
  setmetatable(env, { __index = stdOnly })
  w.env = env
  local fn = assert(loadfile(LEDGER))
  setfenv(fn, env)
  fn()
  w.L = env.shikudoLedger
  return w
end

-- Run a trigger's REAL body in the world, as Mudlet would on `ln`.
local function fire(w, file, ln, matches, multimatches)
  local fn = assert(loadstring(body(file), "=" .. file))
  w.env.line = ln
  w.env.matches = matches or { ln }
  w.env.multimatches = multimatches
  setfenv(fn, w.env)
  fn()
end

-- One physical row, as Mudlet runs it: 587 and 789 where their REAL patterns match the row (the
-- gated Shikudo group runs by number), then the one-row temp triggers armed on the row before.
local P587, P789 = pats(F587), pats(F789)
local function row(w, text)
  local tails = w.tails
  w.tails = {}
  if TL.anyMatches(P587, text) then fire(w, F587, text) end
  if TL.anyMatches(P789, text) then fire(w, F789, text) end
  w.env.line = text
  for _, t in ipairs(tails) do t.fn() end
end

-- A game line, wrapped as the server wraps it.
local function feed(w, text, width)
  for _, r in ipairs(TL.wrap(text, width or 119)) do row(w, r) end
end

-- The damage line: its multiline strike trigger fires on it first (563-585 < 789), then 789.
local function damage(w, file, limb, pct)
  local ln = dmg(limb, pct)
  fire(w, file, ln, nil, { { "strike line" }, {}, { ln, pct or "8.4", T, limb } })
  feed(w, ln)
end

-- The prompt: 318's WHOLE body, as Mudlet runs it, then the tails armed on the last row fire on the
-- prompt line. Running all of it (not just its flush line, which a test could read wherever it
-- sat) is what lets these tests see a flush that was moved inside a branch or switched off.
local F318 = "318_Prompt_Trigger.lua"
local function prompt(w)
  fire(w, F318, PROMPT)
  row(w, PROMPT)
end

-- The trigger files of the shipped package, read once: { key, active, pats }.
local ALL
local function allTriggers()
  if ALL then return ALL end
  ALL = {}
  local h = assert(io.popen('find src_new/triggers/levi_ataxia -name "*.lua" 2>/dev/null || dir /b /s src_new\\triggers\\levi_ataxia\\*.lua 2>nul'))
  for p in h:lines() do
    local key = p:gsub("\r$", ""):gsub("\\", "/"):match("for_levi/leviticus/(.+%.lua)$")
    if key then
      local ok, ps = pcall(TL.patterns, DIR .. key)
      if ok then
        ALL[#ALL + 1] = { key = key, active = read(DIR .. key):match("isActive: '(%a+)'") == "yes", pats = ps }
      end
    end
  end
  h:close()
  return ALL
end

-- The switched-on triggers that fire on `text`, in tree order (the 3rd Person Shikudo group, then
-- the gated group, then the rest). `words` narrows the search to patterns written for the line
-- (and keeps the catch-all ^.*$ rows of multiline triggers out); the real pattern decides, and one
-- trigger_lib cannot judge fails the test rather than being skipped.
local function firing(words, text)
  local out = {}
  for _, t in ipairs(allTriggers()) do
    if t.active then
      for _, p in ipairs(t.pats) do
        if p.pat:find(words, 1, true) then
          local ok, hit = pcall(TL.matches, p.pat, p.type, text)
          if not ok then error("cannot judge " .. t.key .. ": " .. p.pat) end
          if hit then out[#out + 1] = t.key; break end
        end
      end
    end
  end
  local function rank(k)
    if k:find("^3rd_person_shikudo/") then return 1 end
    if not k:find("/") then return 2 end
    return 3
  end
  table.sort(out, function(a, b)
    if rank(a) ~= rank(b) then return rank(a) < rank(b) end
    return a < b
  end)
  return out
end

-- Every switched-on trigger written for an effect line, on that line: what the real game would run.
local function effect(w, words, text)
  local keys = firing(words, text)
  for _, k in ipairs(keys) do fire(w, k, text, { text, T }) end
  w.env.line = text
  local tails = w.tails
  w.tails = {}
  for _, t in ipairs(tails) do t.fn() end
  return keys
end

describe("789 hands the ledger every line that can end a strike (v4.7.419)", function()
  it("each pattern matches row 1 of its real line at 100, 119 and 124 columns", function()
    local used = {}
    for _, o in ipairs(OUTCOMES) do
      for _, wd in ipairs(WIDTHS) do
        local r = TL.wrap(o[1], wd)[1]
        local hit = false
        for i, p in ipairs(P789) do
          if TL.matches(p.pat, p.type, r) then hit, used[i] = true, true end
        end
        if not hit then error("789 misses row 1 at width " .. wd .. ": " .. r) end
      end
    end
    for i, p in ipairs(P789) do
      if not used[i] then error("789 pattern matches none of the real lines: " .. p.pat) end
    end
  end)

  it("the ledger reads each of those rows as what it is", function()
    local w = world()
    for _, o in ipairs(OUTCOMES) do
      for _, wd in ipairs(WIDTHS) do
        local r = TL.wrap(o[1], wd)[1]
        local got = w.L.outcome(r)
        if got ~= o[2] then error("read as " .. tostring(got) .. ", not " .. o[2] .. ": " .. r) end
      end
    end
  end)

  it("no pattern is end-anchored or wider than 118 columns, and the trigger is one line", function()
    for _, p in ipairs(P789) do
      expect(p.pat:find("%$$")).toBeNil()
      expect(#p.pat <= 118).toBeTrue()
    end
    expect(read(DIR .. F789):match("isMultiline: '(%a+)'")).toBe("no")
    expect(read(DIR .. F789):match("isActive: '(%a+)'")).toBe("yes")
  end)

  it("it sits in 587's group, so it is open only in our own queued window", function()
    local h = function(f) return read(DIR .. f):match("hierarchy:\r?\n(.-)attributes:") end
    expect(h(F789)).toBe(h(F587))
    expect(h(F789):find("Affs Post Queue - Gated", 1, true) ~= nil).toBeTrue()
  end)

  it("matches no row of a strike line, no kata line and no prompt", function()
    for _, s in ipairs(STRIKES) do
      for _, wd in ipairs(WIDTHS) do
        for _, r in ipairs(TL.wrap(s, wd)) do
          if TL.anyMatches(P789, r) then error("789 matches a strike row: " .. r) end
        end
      end
    end
    for _, ln in ipairs({ "You are now maintaining a kata chain of 3 actions.", PROMPT, -- attacker:34
      "[-|E] [CDBK] H:6068|96% M:5642|95% [54.44] [Gaital]:9 K:100% " }) do         -- c.iJVmpL:2600
      expect(TL.anyMatches(P789, ln)).toBeFalse()
    end
  end)
end)

describe("the ledger records ruku to the arm from its untargeted line", function()
  it("a light ruku: 587 on row 1, its tail 'Claes.', then the arm line -> clumsiness (c.iJVmpL:2597)", function()
    expect(TL.wrap(RUKU_R, 119)[2]).toBe("Claes.")
    local w = world()
    feed(w, RUKU_R, 119)
    expect(w.L.current().done).toBeTrue()
    expect(w.L.current().text).toBe(RUKU_R)
    feed(w, ARM_R)
    expect(#w.affs).toBe(1)
    expect(w.affs[1]).toBe("clumsiness")
    expect(w.L.current().outcome).toBe("arm")
  end)

  it("with the target already clumsy it steps to healthleech, as 578 does", function()
    local w = world({ has = { clumsiness = true } })
    feed(w, RUKU_R, 119)
    feed(w, ARM_R)
    expect(#w.affs).toBe(1)
    expect(w.affs[1]).toBe("healthleech")
  end)

  it("at every width, and for the first-strike ruku (584's line) too", function()
    for _, ln in ipairs({ RUKU_R, WHIP_R }) do
      for _, wd in ipairs(WIDTHS) do
        local w = world()
        feed(w, ln, wd)
        feed(w, ARM_R, wd)
        if #w.affs ~= 1 then error("not recorded at width " .. wd .. ": " .. ln) end
      end
    end
  end)

  it("relays to the party like 578 when partyrelay is on, and only then", function()
    local w = world({ partyrelay = true })
    feed(w, RUKU_R)
    feed(w, ARM_R)
    expect(w.sent[1]).toBe("pt Claes: clumsiness")
    w = world({ partyrelay = true, has = { clumsiness = true } })
    feed(w, RUKU_R)
    feed(w, ARM_R)
    expect(w.sent[1]).toBe("pt Claes: healthleech clumsiness")
    w = world()
    feed(w, RUKU_R)
    feed(w, ARM_R)
    expect(#w.sent).toBe(0)
  end)

  it("a damaged ruku is recorded once: 578 from the damage line, the arm line only clears the flag (attacker:374-377)", function()
    local w = world()
    feed(w, RUKU_R)
    damage(w, "578_1Ruku_arms_(healthleech_clumsy).lua", "right arm")
    expect(rawget(w.env, "ignoreThirdPerson")).toBe(true)
    feed(w, ARM_R)
    expect(count(w.affs, "clumsiness")).toBe(1)
    expect(#w.affs).toBe(1)
    expect(rawget(w.env, "ignoreThirdPerson")).toBeNil()
    expect(w.L.refused).toBe(0)                -- recorded, by 578: not a refusal
  end)

  it("two rukus in one combo: each arm line goes to its own strike (attacker:2568-2575)", function()
    local w = world()
    feed(w, RUKU_R)
    damage(w, "578_1Ruku_arms_(healthleech_clumsy).lua", "right arm")
    feed(w, ARM_R)
    feed(w, RUKU_L)
    damage(w, "578_1Ruku_arms_(healthleech_clumsy).lua", "left arm")
    feed(w, ARM_L)
    expect(#w.affs).toBe(2)
    expect(w.affs[1]).toBe("clumsiness")
    expect(w.affs[2]).toBe("healthleech")
    -- the same with no damage lines, from the arm lines alone
    w = world()
    feed(w, RUKU_R)
    feed(w, ARM_R)
    feed(w, RUKU_L)
    feed(w, ARM_L)
    expect(#w.affs).toBe(2)
    expect(w.affs[1]).toBe("clumsiness")
    expect(w.affs[2]).toBe("healthleech")
  end)

  it("one strike is recorded once, however many arm lines follow it", function()
    local w = world()
    feed(w, RUKU_R)
    feed(w, ARM_R)
    feed(w, ARM_R)
    expect(#w.affs).toBe(1)
    -- and a damaged one: 578 recorded it, the first arm line consumed the flag, and the second
    -- must not record it again from the ledger
    w = world()
    feed(w, RUKU_R)
    damage(w, "578_1Ruku_arms_(healthleech_clumsy).lua", "right arm")
    feed(w, ARM_R)
    feed(w, ARM_R)
    expect(#w.affs).toBe(1)
    expect(w.L.refused).toBe(0)
  end)
end)

describe("the ledger records nothing without proof", function()
  it("a parried ruku, nor an arm line after the parry (attacker:440, 444; :441-442 recorded it anyway)", function()
    local w = world()
    feed(w, RUKU_R)
    feed(w, PARRY)
    expect(w.L.current().dropped).toBe("parry")
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
    expect(w.L.refused).toBe(0)                -- a known outcome, not a refusal
  end)

  it("a parry by someone else leaves our strike open", function()
    local w = world()
    feed(w, RUKU_R)
    feed(w, "Belaziel parries the attack with a deft manoeuvre.") -- EveP2TVe:525
    expect(w.L.current().dropped).toBeNil()
  end)

  it("a fumble drops the strike; the absorbed kuro after it is still an effect (attacker:433-437)", function()
    local w = world()
    feed(w, FRONTKICK)
    feed(w, FUMBLE)
    expect(w.L.current().dropped).toBe("fumble")
    feed(w, KURO)
    fire(w, "3rd_person_shikudo/007_Kuro_(weariness_lethargy).lua", KURO_FX, { KURO_FX, "left", T })
    feed(w, KURO_FX)
    expect(#w.affs).toBe(1)
    expect(w.affs[1]).toBe("weariness")
    expect(w.L.current().outcome).toBe("effect")
    prompt(w)
    expect(w.L.unresolved).toBe(0)
  end)

  it("a shield's rebound drops the strike (LcJC-rJ5:207)", function()
    local w = world()
    feed(w, RUKU_R)
    feed(w, SHIELD)
    expect(w.L.current().dropped).toBe("shield")
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
  end)

  it("a strike at someone else, even with the arm line", function()
    local w = world()
    feed(w, (RUKU_R:gsub("Claes", "Xarthus")))
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
    expect(w.L.refused).toBe(1)
    expect(w.L.lastRefused.why).toBe("other target")
    w = world({ target = "Claesar" })
    feed(w, RUKU_R)
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
    expect(w.L.lastRefused.why).toBe("other target")
  end)

  it("a strike that is not a ruku to that arm", function()
    local w = world()
    feed(w, RUKU_TORSO)
    feed(w, ARM_R)
    feed(w, RUKU_L)
    feed(w, ARM_R)
    feed(w, "You whip a twisted oaken staff at the side of Claes's neck.") -- nervestrike, attacker:829
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
    -- each one said, since an unseen ruku wording (the first-strike whip, which no log has) would
    -- land here too
    expect(w.L.refused).toBe(3)
    expect(w.L.lastRefused.why).toBe("not a ruku to that arm")
    expect(w.L.lastRefused.text).toBe("You whip a twisted oaken staff at the side of Claes's neck.")
  end)

  it("an arm line more than 2 s after its strike", function()
    local w = world()
    feed(w, RUKU_R)
    w.clock = w.clock + 2.5
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
    expect(w.L.refused).toBe(1)
    expect(w.L.lastRefused.why).toBe("stale")
  end)

  it("a strike whose tail never came (no temp trigger fired): the name was never read", function()
    local w = world()
    local row1 = TL.wrap(RUKU_R, 119)[1]
    row(w, row1)
    w.tails = {}
    expect(w.L.current().done).toBeFalse()
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
    -- ...and it is SAID: the arm line came, so it is not unresolved, but it was refused. This is
    -- the live check of the tail read; it used to look exactly like a working ledger.
    expect(w.L.refused).toBe(1)
    expect(w.L.lastRefused.why).toBe("unfinished")
    expect(w.L.lastRefused.text).toBe(row1)
    prompt(w)
    expect(w.L.unresolved).toBe(0)
  end)

  it("with shikudoLedger.debug on, a refused arm line is echoed in ASCII with its reason and text", function()
    local w = world()
    w.L.debug = true
    local row1 = TL.wrap((RUKU_R:gsub("twisted", "tw\195\175sted <red>")), 119)[1]
    row(w, row1)
    w.tails = {}
    feed(w, ARM_R)
    expect(#w.echoes).toBe(1)
    expect(w.echoes[1]:find("(unfinished)", 1, true) ~= nil).toBeTrue()
    expect(w.echoes[1]:find("bringing a tw??sted red oaken staff", 1, true) ~= nil).toBeTrue()
    expect(w.echoes[1]:find("[^\32-\126]")).toBeNil()
    expect(w.echoes[1]:find("<", 1, true)).toBeNil()
    prompt(w)
    expect(#w.echoes).toBe(1)                  -- and not again as unresolved at the prompt
  end)

  it("a non-monk opens no strike", function()
    local w = world({ class = "runewarden" })
    feed(w, RUKU_R)
    expect(w.L.current()).toBeNil()
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
    expect(w.L.refused).toBe(0)                -- no strike in flight: nothing to report
  end)

  it("a flush with no outcome adds 1 to unresolved and records nothing", function()
    local w = world()
    feed(w, RUKU_R)
    prompt(w)
    expect(w.L.current()).toBeNil()
    expect(w.L.unresolved).toBe(1)
    expect(w.L.lastUnresolved).toBe(RUKU_R)
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
    expect(#w.echoes).toBe(0)
  end)

  it("the next strike line expires the last one the same way", function()
    local w = world()
    feed(w, RUKU_R)
    feed(w, KURO)
    expect(w.L.unresolved).toBe(1)
    expect(w.L.current().text).toBe(KURO)
  end)

  it("with shikudoLedger.debug on, an unresolved strike is echoed in ASCII with its text", function()
    local w = world()
    w.L.debug = true
    feed(w, RUKU_R)
    feed(w, ARM_R)
    prompt(w)
    expect(#w.echoes).toBe(0)
    feed(w, (RUKU_R:gsub("twisted", "tw\195\175sted <red>")))
    prompt(w)
    expect(#w.echoes).toBe(1)
    expect(w.echoes[1]:find("[^\32-\126]")).toBeNil()
    expect(w.echoes[1]:find("<", 1, true)).toBeNil()
    expect(w.echoes[1]:find("right arm of Claes.", 1, true) ~= nil).toBeTrue()
  end)

  it("SILENT_COMMIT ships empty; an entry would commit only a strike at our target", function()
    local w = world()
    expect(next(w.L.SILENT_COMMIT)).toBeNil()
    w.L.SILENT_COMMIT[LIVE:sub(1, 38)] = { "asthma" }
    feed(w, LIVE)
    prompt(w)
    expect(#w.affs).toBe(1)
    feed(w, (LIVE:gsub("Claes", "Xarthus")))
    prompt(w)
    expect(#w.affs).toBe(1)
  end)
end)

describe("a strike line cut into rows is read whole", function()
  local LONG = "You spin a full rotation, bringing an ornately carved staff of polished ebony inlaid with silver runes around in a blur of motion to smash into the right arm of Claes."

  it("two rows at the user's wrap, three at 60 columns", function()
    for _, wd in ipairs({ 100, 119, 124, 60 }) do
      local w = world()
      feed(w, LONG, wd)
      expect(w.L.current().text).toBe(LONG)
      feed(w, ARM_R, wd)
      if #w.affs ~= 1 then error("not recorded at width " .. wd) end
    end
    expect(#TL.wrap(LONG, 60)).toBe(3)
  end)

  it("past MAX_TAIL extra rows it stays unfinished and records nothing", function()
    local w = world()
    feed(w, LONG, 40)
    expect(#TL.wrap(LONG, 40) > 3).toBeTrue()
    feed(w, ARM_R)
    expect(#w.affs).toBe(0)
    expect(w.L.lastRefused.why).toBe("unfinished") -- and says so
  end)

  it("a tail row belongs only to the strike that asked for it", function()
    local w = world()
    row(w, TL.wrap(RUKU_R, 119)[1])   -- strike A, cut off: it asks for the next row
    local stale = w.tails[1]
    w.tails = {}
    row(w, TL.wrap(RUKU_L, 119)[1])   -- strike B, cut off too, before A's tail came
    w.env.line = "Xarthus."
    stale.fn()                        -- A's late tail must not finish B
    row(w, "Claes.")                  -- B's own tail
    expect(w.L.current().text).toBe(RUKU_L)
  end)
end)

describe("587 and 318 call the ledger only behind a guard", function()
  it("587 opens the strike with the row it matched, and runs without a ledger", function()
    local c = code(F587)
    expect(c:find("if shikudoLedger and shikudoLedger.strike then shikudoLedger.strike(line) end", 1, true) ~= nil).toBeTrue()
    local _, calls = c:gsub("shikudoLedger%.strike%(", "")
    expect(calls).toBe(1)
    -- no ledger: no error, the flag still cleared
    local env = setmetatable({ line = RUKU_R, ignoreThirdPerson = true }, { __index = stdOnly })
    local fn = assert(loadstring(body(F587)))
    setfenv(fn, env)
    expect(pcall(fn)).toBeTrue()
    expect(rawget(env, "ignoreThirdPerson")).toBeNil()
  end)

  it("318, run whole at the prompt, expires the strike in flight and still closes the gated window", function()
    local _, calls = code(F318):gsub("shikudoLedger", "")
    expect(calls).toBe(3)                      -- one call, behind its guard
    local w = world()
    feed(w, RUKU_R)
    prompt(w)
    expect(w.prompts).toBe(1)                  -- the body ran from its first line...
    expect(w.L.current()).toBeNil()            -- ...through the flush...
    expect(w.L.unresolved).toBe(1)
    expect(count(w.disabled, "Affs Post Queue - Gated")).toBe(1) -- ...to the window's close
    expect(count(w.disabled, "3rd Person Shikudo")).toBe(1)
    -- no ledger loaded: 318 still runs to its end
    w = world()
    w.env.shikudoLedger = nil
    expect(pcall(fire, w, F318, PROMPT)).toBeTrue()
    expect(count(w.disabled, "Affs Post Queue - Gated")).toBe(1)
  end)

  it("789 runs without a ledger", function()
    local env = setmetatable({ line = ARM_R }, { __index = stdOnly })
    local fn = assert(loadstring(body(F789)))
    setfenv(fn, env)
    expect(pcall(fn)).toBeTrue()
  end)
end)

describe("one hit, one record: the two duplicate recorders (v4.7.419)", function()
  it("586 and calls/004 are gone; nothing else records the arm line", function()
    expect(io.open(DIR .. "586_Ruku_torso_(slickness).lua", "r")).toBeNil()
    expect(io.open(DIR .. "calls/004_Ruku_Clumsiness_Healthleech.lua", "r")).toBeNil()
    local keys = firing("with a resounding crack", ARM_R)
    expect(#keys).toBe(2)
    expect(keys[1]).toBe(F789)
    expect(keys[2]).toBe("leviatax/002_GAGS.lua") -- the display gag; it records nothing
    expect(code("leviatax/002_GAGS.lua"):find("tarAffed")).toBeNil()
  end)

  it("a ruku to the torso records slickness once, with or without a damage line (attacker:893-895)", function()
    expect(read(DIR .. "calls/006_Ruku_Torso_Slickness.lua"):match("isActive: '(%a+)'")).toBe("no")
    -- light or absorbed: 3rd_person_shikudo/004 records it, 789 only resolves the strike
    local w = world()
    feed(w, RUKU_TORSO)
    local keys = effect(w, "staggers as the staff cracks across", TORSO_FX)
    expect(#keys).toBe(2)
    expect(count(w.affs, "slickness")).toBe(1)
    expect(w.L.current().outcome).toBe("effect")
    -- damaged: 569 records it from the damage line and sets the flag; 004 skips once
    w = world()
    feed(w, RUKU_TORSO)
    damage(w, "569_2Ruku_torso_(slickness).lua", "torso")
    effect(w, "staggers as the staff cracks across", TORSO_FX)
    expect(count(w.affs, "slickness")).toBe(1)
    expect(rawget(w.env, "ignoreThirdPerson")).toBeNil()
  end)

  it("a damaged livestrike records asthma once (attacker:1645-1647)", function()
    expect(read(DIR .. "calls/007_Livestrike_Asthma.lua"):match("isActive: '(%a+)'")).toBe("no")
    local w = world()
    feed(w, LIVE)
    damage(w, "576_Livestrike_(asthma).lua", "torso", "12.3")
    local keys = effect(w, "The breath of", LIVE_FX)
    expect(keys[1]).toBe("3rd_person_shikudo/001_Livestrike_(asthma).lua")
    expect(count(w.affs, "asthma")).toBe(1)
    expect(rawget(w.env, "ignoreThirdPerson")).toBeNil()
  end)

  it("a livestrike only its effect line proves is still recorded: light, or the later strike", function()
    -- light or absorbed: no damage line
    local w = world()
    feed(w, LIVE)
    effect(w, "The breath of", LIVE_FX)
    expect(count(w.affs, "asthma")).toBe(1)
    -- the later strike (attacker:832-834): its damage line prints, but no strike trigger owns the
    -- strike line, so nothing set the flag and the effect line records it
    w = world()
    feed(w, LIVE_LATER)
    feed(w, dmg("torso", "12.3"))
    effect(w, "The breath of", LIVE_FX)
    expect(count(w.affs, "asthma")).toBe(1)
    expect(w.L.current().outcome).toBe("damage")
  end)
end)

describe("the shared Lua state is untouched", function()
  it("a dedupe flag an earlier test file left in _G changes nothing here", function()
    local saved = rawget(_G, "ignoreThirdPerson")
    _G.ignoreThirdPerson = true
    local ok, err = pcall(function()
      local w = world()
      feed(w, RUKU_R)
      feed(w, ARM_R)
      expect(#w.affs).toBe(1)
      expect(w.affs[1]).toBe("clumsiness")
      feed(w, RUKU_TORSO)
      effect(w, "staggers as the staff cracks across", TORSO_FX)
      expect(count(w.affs, "slickness")).toBe(1)
      prompt(w)
      expect(rawget(_G, "ignoreThirdPerson")).toBe(true) -- neither read nor cleared
    end)
    _G.ignoreThirdPerson = saved
    if not ok then error(err, 0) end
  end)

  it("no ledger, temp trigger or clock leaks into _G", function()
    local w = world()
    feed(w, RUKU_R)
    feed(w, ARM_R)
    prompt(w)
    expect(rawget(_G, "shikudoLedger")).toBeNil()
    expect(rawget(_G, "tempLineTrigger")).toBe(before.tempLineTrigger)
    expect(rawget(_G, "getEpoch")).toBe(before.getEpoch)
  end)
end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
