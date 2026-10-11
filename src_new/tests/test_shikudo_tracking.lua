--- test_shikudo_tracking.lua -- Shikudo hits are recorded on the target (v4.7.413-414)
--
-- Checked against two real combat logs (2026-10-11, kb/raw/logs/): a Shikudo killing a
-- Runewarden (the attacker's view) and a Runewarden killing a Shikudo (the defender's view).
--  * A strike line carries the staff's name and runs to 147 columns, against this user's 119-124
--    server wrap, so each strike trigger matches a START fragment and allows the damage line one
--    row later (v4.7.413).
--  * An attack prints a different line as the first strike of a combo and as a later one (kuro,
--    ruku, needle, jinzuku, livestrike, hiru); effect lines ("The breath of X leaves her...")
--    print whenever the affliction lands, even when a shield absorbs the damage line.
--  * One hit must be recorded once: kuro escalates (weariness, then lethargy).
-- These tests run the REAL patterns against the REAL lines, wrapped as the server wraps them, and
-- run the REAL trigger bodies in a private environment, so nothing they write leaks.

local TL = dofile("src_new/tests/trigger_lib.lua")
local DIR = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local T = "Xarthus"

-- The log's staff, a common long one, and a very long one (only at the user's own wrap).
local STAFFS = {
  { "a twisted oaken staff", { 100, 119, 124 } },
  { "a warped black iron staff coated with rust", { 100, 119, 124 } },
  { "an ornately carved staff of polished ebony inlaid with silver runes", { 119, 124 } },
}

local function fill(s, staff)
  return (s:gsub("<S>", function() return staff end):gsub("<T>", function() return T end))
end

local function dmgLine(limb, pct)
  return "As your blow lands with a crunch, you perceive that you have dealt " .. (pct or "8.4")
    .. "% damage to " .. T .. "'s " .. limb .. "."
end

local function read(file)
  local f = assert(io.open(DIR .. file, "r"), "no such trigger: " .. file)
  local s = f:read("*a")
  f:close()
  return s
end

local function body(file)
  return (read(file):match("%]%]%-%-\r?\n(.*)$"))
end

-- Every strike trigger: { file, real line (<S> staff, <T> target), the limb its damage line names }.
local STRIKES = {
  -- seen in the 2026-10-11 log
  { "563_Nervestrike_(paralysis).lua", "You whip <S> at the side of <T>'s neck.", "head" },
  { "565_Needle2_(crushedthroat).lua", "Reversing your grip on <S>, you drive the top of the weapon into the throat of <T>.", "head" },
  { "567_2Jinzuku_(addiction).lua", "You flow around <T>, <S> lashing out in a swift strike at her kidneys.", "torso" },
  { "568_1Ruku_torso_(slickness).lua", "You whip <S> at <T> in a controlled arc, bringing its length to crack against her torso.", "torso" },
  { "569_2Ruku_torso_(slickness).lua", "You spin a full rotation, bringing <S> around in a blur of motion to smash into the torso of <T>.", "torso" },
  { "570_Risingkick_(damage).lua", "You drive your foot up in a rising kick at the head of <T>.", "head" },
  { "570_Risingkick_(damage).lua", "You drive your foot up in a rising kick at the torso of <T>.", "torso" },
  { "571_Frontkick_(prone).lua", "You lash out with a straight kick at the left shoulder of <T>.", "left arm" },
  { "572_1Kuro_(weariness_lethargy).lua", "Dropping into a lower stance, you sweep <S> at the left thigh of <T>.", "left leg" },
  { "573_2Kuro_(weariness_lethargy).lua", "Falling back into a low crouch, you lash out with a swift strike at the right thigh of <T>.", "right leg" },
  { "574_Hiraku_(ano_stutt).lua", "Bracing your back foot, you lunge forward with <S> at the face of <T>.", "head" },
  { "576_Livestrike_(asthma).lua", "Lunging forward, you drive the end of <S> viciously into the solar plexus of <T>.", "torso" },
  { "577_Flashheel_(break_leg).lua", "Snapping your leg out to its full extent, you drive a heel into the left knee of <T>.", "left leg" },
  { "578_1Ruku_arms_(healthleech_clumsy).lua", "You spin a full rotation, bringing <S> around in a blur of motion to smash into the right arm of <T>.", "right arm" },
  -- not in the logs: built from the trigger's own pre-v4.7.413 full-line pattern
  { "564_Needle_(crushedthroat).lua", "With pinpoint precision, you drive <S> at the throat of <T>.", "head" },
  { "566_1Jinzuku_(addiction).lua", "Stepping to the side of <T>, you drive <S> at her kidneys.", "torso" },
  { "575_Hiru_(dizzy).lua", "Whirling <S> in a tight arc, you bring the weapon around to crash into the side of the head of <T>.", "head" },
  { "580_Spinkick_Torso.lua", "Whirling around, you bring the ball of your foot smashing into the ribs of <T>.", "torso" },
  { "581_Spinkick_Head.lua", "Whirling around, you bring the ball of your foot crashing into the temple of <T>.", "head" },
  { "583_Thrust.lua", "Continuing your kata, you spin <S> in your hands and drive it in a sharp thrust towards the left leg of <T>.", "left leg" },
  { "584_2Ruku_arms_(healthleech_clumsiness)_1.lua", "You whip <S> at <T> in a controlled arc, bringing its length to crack against her right arm.", "right arm" },
  { "585_Dart_1.lua", "Spinning on one foot you bring <S> around in a lightning fast thrust at the left arm of <T>.", "left arm" },
}

-- Strike lines no strike trigger owns (seen in the log), for the strike-start trigger.
local OTHER_STRIKES = {
  "Turning with the motion, you channel the momentum of your previous strike into a thrust at the solar plexus of <T> with <S>.",
  "Snapping back into a ready stance, you whirl <S> in a long sweep at the head of <T>.",
  "Springing off your back foot, the heel of your foot smashes into the temple of <T> with flawless precision.",
  "Taking a firm hold of <S> you whip it in a wide sweep at the legs of <T>.",
  "Bracing your feet, you drive <S> towards <T>.",
}

local NOOP = { "moveCursor", "getLineNumber", "moveCursorEnd", "selectString", "selectCurrentLine", "fg", "bg",
  "setBold", "resetFormat", "replace", "insertText", "cecho", "echo", "deleteFull", "deleteLine",
  "ataxia_boxEcho", "setTriggerStayOpen", "ataxiaEcho", "decho", "hecho", "creplace", "tempTimer", "killTimer" }

-- Run a trigger body as Mudlet would, in its own environment: the globals it writes stay in
-- rec.env (nothing leaks into later test files), and the ones it reads come from ctx.
local function run(file, ctx)
  ctx = ctx or {}
  local fn = assert(loadstring(body(file), "=" .. file))
  local rec = { affs = {}, cured = {}, sent = {} }
  local env = {
    matches = ctx.matches, multimatches = ctx.multimatches,
    line = ctx.line or (ctx.matches and ctx.matches[1]) or "",
    target = T,
    isTargeted = function(n) return n == T end,
    tarAffed = function(...) for _, a in ipairs({ ... }) do rec.affs[#rec.affs + 1] = a end end,
    erAff = function(a) rec.cured[#rec.cured + 1] = a end,
    haveAff = function(a) return (ctx.has or {})[a] == true end,
    send = function(c) rec.sent[#rec.sent + 1] = c end,
    partyrelay = ctx.partyrelay or false,
    ignoreThirdPerson = ctx.ignoreThirdPerson or false,
    ataxiaTemp = ctx.ataxiaTemp or {},
    ataxiaTables = { limbData = {} },
    ataxia = { afflictions = {}, settings = { raid = { enabled = false } } },
    tAffs = {},
    monk = ctx.monk or false,
  }
  for _, n in ipairs(NOOP) do env[n] = function() return 0 end end
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  fn()
  rec.env = env
  return rec
end

local function has(list, x)
  for _, v in ipairs(list) do if v == x then return true end end
  return false
end

local function strike(file, limb, ctx)
  ctx = ctx or {}
  ctx.multimatches = { { "strike line" }, {}, { dmgLine(limb), "8.4", ctx.person or T, limb } }
  return run(file, ctx)
end

local function pats(file) return TL.patterns(DIR .. file) end

describe("Shikudo strike lines fit the server's wrap (logs of 2026-10-11)", function()
  it("each strike trigger's first pattern matches the FIRST ROW of its real line, any staff", function()
    for _, s in ipairs(STRIKES) do
      local p = pats(s[1])[1]
      for _, st in ipairs(STAFFS) do
        for _, w in ipairs(st[2]) do
          local row = TL.wrap(fill(s[2], st[1]), w)[1]
          if not TL.matches(p.pat, p.type, row) then
            error(s[1] .. " misses row 1 at width " .. w .. ": " .. row)
          end
        end
      end
    end
  end)

  it("each strike trigger is a strike, a one-line spacer, then the damage line, within two rows", function()
    for _, s in ipairs(STRIKES) do
      local p = pats(s[1])
      expect(#p).toBe(3)
      expect(p[2].type).toBe(5)
      expect(p[2].pat).toBe("1")
      expect(read(s[1]):match("conditonLineDelta: (%d+)")).toBe("2")
    end
  end)

  it("the damage-line pattern takes its own limb and not every limb", function()
    local limbs = { "head", "torso", "left arm", "right arm", "left leg", "right leg" }
    for _, s in ipairs(STRIKES) do
      local p = pats(s[1])[3]
      expect(p.pat:sub(1, 2) ~= "^^").toBeTrue()
      if not TL.matches(p.pat, p.type, dmgLine(s[3])) then error(s[1] .. " misses " .. dmgLine(s[3])) end
      local n = 0
      for _, l in ipairs(limbs) do
        if TL.matches(p.pat, p.type, dmgLine(l)) then n = n + 1 end
      end
      expect(n).toBeLessThan(6)
    end
  end)

  it("the damage line's captures are % then name (then limb), as the bodies read them", function()
    for _, s in ipairs(STRIKES) do
      local p = pats(s[1])[3].pat
      local b = body(s[1])
      expect(p:find("dealt ([0-9\\.]+)\\% damage to (\\w+)'s ", 1, true) ~= nil).toBeTrue()
      expect(b:find("multimatches%[1%]")).toBeNil()
      if b:find("multimatches%[3%]%[4%]") then
        local groups = select(2, p:gsub("%(", "")) - select(2, p:gsub("%(%?:", ""))
        expect(groups).toBe(3)
      end
    end
  end)
end)

describe("the strike bodies record what landed", function()
  it("flashheel BREAKS the leg it names (the target mends it at once: log 2026-10-11)", function()
    local r = strike("577_Flashheel_(break_leg).lua", "left leg")
    expect(has(r.affs, "brokenleftleg")).toBeTrue()
    expect(r.env.ataxiaTables.limbData.shikFlashheel).toBe(8.4)
    r = strike("577_Flashheel_(break_leg).lua", "right leg")
    expect(has(r.affs, "brokenrightleg")).toBeTrue()
  end)

  it("records nothing when the damage line names someone else", function()
    local r = strike("577_Flashheel_(break_leg).lua", "left leg", { person = "Claes" })
    expect(#r.affs).toBe(0)
    r = strike("576_Livestrike_(asthma).lua", "torso", { person = "Claes" })
    expect(#r.affs).toBe(0)
  end)

  it("livestrike gives asthma; hiru gives dizziness, and confusion too on a prone target", function()
    expect(has(strike("576_Livestrike_(asthma).lua", "torso").affs, "asthma")).toBeTrue()
    local r = strike("575_Hiru_(dizzy).lua", "head")
    expect(has(r.affs, "dizziness")).toBeTrue()
    expect(has(r.affs, "confusion")).toBeFalse()
    r = strike("575_Hiru_(dizzy).lua", "head", { has = { prone = true } })
    expect(has(r.affs, "confusion")).toBeTrue()
  end)

  it("kuro gives weariness, then lethargy once the target is weary", function()
    local r = strike("573_2Kuro_(weariness_lethargy).lua", "right leg")
    expect(has(r.affs, "weariness")).toBeTrue()
    r = strike("573_2Kuro_(weariness_lethargy).lua", "right leg", { has = { weariness = true } })
    expect(has(r.affs, "lethargy")).toBeTrue()
    expect(has(r.affs, "weariness")).toBeFalse()
  end)

  it("a spinkick to the head no longer records a mangled head", function()
    local r = strike("581_Spinkick_Head.lua", "head")
    expect(has(r.affs, "mangledhead")).toBeFalse()
  end)

  it("reads no combo table before one exists (it used to throw)", function()
    for _, f in ipairs({ "563_Nervestrike_(paralysis).lua", "571_Frontkick_(prone).lua",
      "580_Spinkick_Torso.lua", "581_Spinkick_Head.lua" }) do
      local limb = (f:find("Frontkick") and "left arm") or (f:find("Torso") and "torso") or "head"
      strike(f, limb, { ataxiaTemp = {}, partyrelay = true })
    end
    expect(has(strike("563_Nervestrike_(paralysis).lua", "head").affs, "paralysis")).toBeTrue()
  end)
end)

describe("effect lines record what landed", function()
  local function effect(file, ln, name, ctx)
    ctx = ctx or {}
    ctx.matches = { ln, name }
    ctx.line = ln
    return run(file, ctx)
  end

  it("hiru (calls/011): dizziness, plus confusion on a prone target", function()
    local ln = "The staff connects to the side of " .. T .. "'s head with a resounding crack."
    expect(TL.anyMatches(pats("calls/011_Hiru_Dizziness_Blackout.lua"), ln)).toBeTrue()
    local r = effect("calls/011_Hiru_Dizziness_Blackout.lua", ln, T)
    expect(has(r.affs, "dizziness")).toBeTrue()
    expect(has(r.affs, "confusion")).toBeFalse()
    r = effect("calls/011_Hiru_Dizziness_Blackout.lua", ln, T, { has = { prone = true } })
    expect(has(r.affs, "confusion")).toBeTrue()
    expect(#effect("calls/011_Hiru_Dizziness_Blackout.lua", ln, "Claes").affs).toBe(0)
  end)

  it("jinzuku (calls/009) records addiction without throwing", function()
    local ln = "The end of the staff drives viciously into the kidneys of " .. T .. "."
    expect(TL.anyMatches(pats("calls/009_Jinzuku_Addiction.lua"), ln)).toBeTrue()
    expect(has(effect("calls/009_Jinzuku_Addiction.lua", ln, T).affs, "addiction")).toBeTrue()
  end)

  it("hiraku (calls/010) records anorexia and stuttering", function()
    local ln = "The staff smashes into the face of " .. T .. " with a sickening crunch."
    expect(TL.anyMatches(pats("calls/010_Hiraku_Anorexia_Stuttering.lua"), ln)).toBeTrue()
    local r = effect("calls/010_Hiraku_Anorexia_Stuttering.lua", ln, T)
    expect(has(r.affs, "anorexia")).toBeTrue()
    expect(has(r.affs, "stuttering")).toBeTrue()
  end)

  it("sweep (calls/001) records prone", function()
    local ln = "The staff sweeps the legs out from under " .. T .. ", sending her sprawling."
    expect(TL.anyMatches(pats("calls/001_Prone_Staff.lua"), ln)).toBeTrue()
    expect(has(effect("calls/001_Prone_Staff.lua", ln, T).affs, "prone")).toBeTrue()
  end)

  it("frontkick (calls/012) matches the real line, which names the side and wraps", function()
    local ln = "The instep of your foot smashes into the left underarm of " .. T
      .. ", throwing her from her feet and sending her spinning to the ground."
    local p = pats("calls/012_Frontkick.lua")
    for _, w in ipairs({ 100, 119, 124 }) do
      expect(TL.anyMatches(p, TL.wrap(ln, w)[1])).toBeTrue()
    end
    expect(has(effect("calls/012_Frontkick.lua", ln, T).affs, "prone")).toBeTrue()
  end)

  it("needle (calls/013): only the effect line proves it landed; a strike line can be parried", function()
    local strikeLine = "With pinpoint precision, you drive a twisted oaken staff at the throat of " .. T .. "."
    local landed = "The end of the staff smashes into the exposed throat of " .. T .. ", crushing cartilage."
    local p = pats("calls/013_Needle_1.lua")
    expect(TL.anyMatches(p, strikeLine)).toBeTrue()
    expect(TL.anyMatches(p, landed)).toBeTrue()
    expect(has(effect("calls/013_Needle_1.lua", strikeLine, T).affs, "crushedthroat")).toBeFalse()
    expect(has(effect("calls/013_Needle_1.lua", landed, T).affs, "crushedthroat")).toBeTrue()
  end)

  it("nervestrike's strike-line trigger (calls/008) is switched off: the strike line prints on a parry too", function()
    expect(read("calls/008_Nervestrike_Paralyze.lua"):find("isActive: 'no'", 1, true) ~= nil).toBeTrue()
  end)

  it("livestrike's effect line (3rd Person Shikudo/001) gives asthma, whichever line the strike printed", function()
    local ln = "The breath of " .. T .. " leaves her in an explosive gasp as the end of the staff smashes home."
    expect(TL.anyMatches(pats("3rd_person_shikudo/001_Livestrike_(asthma).lua"), ln)).toBeTrue()
    expect(has(effect("3rd_person_shikudo/001_Livestrike_(asthma).lua", ln, T).affs, "asthma")).toBeTrue()
  end)

  it("Mind Confuse and Mind Stupidity are recorded (their helper was in a switched-off script)", function()
    local c = "You direct a powerful pulse of telepathic energy into " .. T .. ", throwing her mind into chaos and confusion."
    expect(TL.anyMatches(pats("telepathy_tekura/002_Confusion.lua"), c)).toBeTrue()
    expect(has(effect("telepathy_tekura/002_Confusion.lua", c, T).affs, "confusion")).toBeTrue()
    local s = "You cast a net of stupidity over " .. T .. "'s mind."
    expect(has(effect("telepathy_tekura/005_Stupidity.lua", s, T).affs, "stupidity")).toBeTrue()
  end)
end)

describe("one hit is recorded once (ignoreThirdPerson)", function()
  local KURO_FX = "The staff cracks across the right thigh of " .. T .. "."
  local function kuroEffect(flag, has_)
    return run("3rd_person_shikudo/007_Kuro_(weariness_lethargy).lua",
      { matches = { KURO_FX, "right", T }, ignoreThirdPerson = flag, has = has_ })
  end

  it("a kuro whose strike trigger recorded it is not recorded again by its effect line", function()
    local r = strike("573_2Kuro_(weariness_lethargy).lua", "right leg")
    expect(rawget(r.env, "ignoreThirdPerson")).toBe(true)
    local fx = kuroEffect(true, { weariness = true })
    expect(#fx.affs).toBe(0)                                -- no second step to lethargy
    expect(rawget(fx.env, "ignoreThirdPerson")).toBeNil()
  end)

  it("a strike line clears the flag, so an absorbed kuro after a ruku to the arm is still recorded", function()
    -- log 2026-10-11, 12:14: a combo ended with ruku to the arm, which has no effect-line partner,
    -- then the next combo's kuro was absorbed by the target's shield (no damage line)
    local fl = strike("578_1Ruku_arms_(healthleech_clumsy).lua", "right arm")
    expect(rawget(fl.env, "ignoreThirdPerson")).toBe(true)
    -- the old bug: with the flag left set, the kuro's effect line was skipped
    expect(#kuroEffect(true).affs).toBe(0)
    -- the fix: the kuro's strike line clears it first
    local st = run("587_Shikudo_Strike_Start.lua", { ignoreThirdPerson = true })
    expect(rawget(st.env, "ignoreThirdPerson")).toBeNil()
    expect(has(kuroEffect(false).affs, "weariness")).toBeTrue()
  end)

  it("the strike-start trigger matches the first row of every strike line", function()
    local p = pats("587_Shikudo_Strike_Start.lua")
    local all = {}
    for _, s in ipairs(STRIKES) do all[#all + 1] = s[2] end
    for _, s in ipairs(OTHER_STRIKES) do all[#all + 1] = s end
    for _, ln in ipairs(all) do
      for _, st in ipairs(STAFFS) do
        local row = TL.wrap(fill(ln, st[1]), 119)[1]
        if not TL.anyMatches(p, row) then error("587 misses: " .. row) end
      end
    end
  end)

  it("and not form changes, parries, kata counts or effect lines", function()
    local p = pats("587_Shikudo_Strike_Start.lua")
    for _, ln in ipairs({
      "Dropping into a lower stance, you snap your weapon into an offensive position, tensing your muscles in",
      "Rising onto the balls of your feet, you prepare to begin the deadly form of the Live Oak.",
      "Twirling your staff, you sink into the calm required for the form of Willows Shaken by the Wind.",
      "You let your eyes fall closed and instinct guide you as you flow into the form of Gaital.",
      T .. " parries the attack with a deft manoeuvre.",
      "You are now maintaining a kata chain of 3 actions.",
      KURO_FX,
    }) do
      expect(TL.anyMatches(p, ln)).toBeFalse()
    end
  end)
end)

describe("lines that had no trigger", function()
  it("losing the telepathic lock (the target died) clears mindlocked", function()
    local ln = "You have lost your telepathic lock upon " .. T .. "."
    local found = false
    for _, p in ipairs(pats("allies_enemies/011_Mind_Lock_Gone.lua")) do
      if p.pat:find("^%^You have lost your telepathic lock") then found = TL.matches(p.pat, p.type, ln) end
    end
    expect(found).toBeTrue()
    local r = run("allies_enemies/011_Mind_Lock_Gone.lua", { matches = { ln, T } })
    expect(rawget(r.env, "mindlocked")).toBe(false)
  end)

  it("Kai Surge: its start fits the wrap, it records prone once, and writes no tAffs", function()
    local ln = "As the power of your kai builds within you, you lift a hand towards " .. T
      .. ". A searing bolt of power leaps forth, blasting him backwards and leaving him lying, twitching, upon the ground."
    local p = pats("monk/002_Kai_Surge.lua")
    expect(TL.anyMatches(p, TL.wrap(ln, 119)[1])).toBeTrue()
    local r = run("monk/002_Kai_Surge.lua", { matches = { ln, T }, partyrelay = true })
    local n = 0
    for _, a in ipairs(r.affs) do if a == "prone" then n = n + 1 end end
    expect(n).toBe(1)
    expect(next(r.env.tAffs)).toBeNil()
    expect(r.sent[1]).toBe("pt " .. T .. ": Kai Surged (prone)")
  end)
end)

describe("calls into monk.shikudo cannot throw (no script we ship defines it)", function()
  local FILES = { "172_Hiru.lua", "173_Sweep.lua", "174_Kuro.lua", "175_Needle.lua", "176_Ruku.lua",
    "177_Risingkick_1.lua", "178_Hiraku.lua", "179_Flashheel_1.lua", "180_Frontkick_1.lua",
    "181_Livestrike_1.lua", "182_Needle_1.lua", "183_Spinkick.lua", "184_Jinzuku.lua", "185_Dart.lua",
    "186_Nervestrike_1.lua" }

  it("runs with no monk namespace", function()
    for _, f in ipairs(FILES) do
      run(f, { matches = { "line", "left", T, T } })
    end
  end)

  it("still hands the hit to monk.shikudo when another package provides it", function()
    local hits = {}
    local fake = { shikudo = { limb_hit = function(limb, how) hits[#hits + 1] = how .. ":" .. tostring(limb) end } }
    run("174_Kuro.lua", { matches = { "line", "left", T }, monk = fake })
    run("179_Flashheel_1.lua", { matches = { "line", "right", T }, monk = fake })
    run("183_Spinkick.lua", { matches = { "line", "crashing", "temple", T }, monk = fake })
    expect(hits[1]).toBe("kuro:left leg")
    expect(hits[2]).toBe("flashheel:right leg")
    expect(hits[3]).toBe("spinkick:head")
  end)

  it("a temple spinkick no longer records prone on US", function()
    local r = run("183_Spinkick.lua", { matches = { "line", "crashing", "temple", T } })
    expect(rawget(r.env, "gotAff")).toBeNil()
    local code = body("183_Spinkick.lua"):gsub("%-%-[^\n]*", "")
    expect(code:find("gotAff%(")).toBeNil()
  end)
end)

describe("trigger_lib understands the damage lines (v4.7.414)", function()
  it("character classes and alternation inside a group", function()
    local p = "^As your blow lands with a crunch, you perceive that you have dealt ([0-9\\.]+)\\% damage to (\\w+)'s (left leg|right leg)\\.$"
    expect(TL.matches(p, 1, dmgLine("left leg"))).toBeTrue()
    expect(TL.matches(p, 1, dmgLine("right leg", "12.25"))).toBeTrue()
    expect(TL.matches(p, 1, dmgLine("torso"))).toBeFalse()
    expect(TL.matches("^x[^,]+,$", 1, "xab,")).toBeTrue()
    expect(TL.matches("^x[^,]+,$", 1, "x,,")).toBeFalse()
    expect(TL.matches("^([\\w'\\-]+)!$", 1, "O'Neil-Smith!")).toBeTrue()
  end)

  it("still raises on what it cannot judge", function()
    expect(pcall(TL.matches, "^a|b", 1, "a")).toBeFalse()
    expect(pcall(TL.matches, "^a[bc", 1, "ab")).toBeFalse()
  end)
end)
