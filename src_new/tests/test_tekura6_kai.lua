--- test_tekura6_kai.lua -- kai gates outside the Shikudo offenses
-- * TK6 (tekura/002): the parry bypass dismounts a mounted target with KAI SURGE or CRIPPLE
--   before its sweep. It sent the dismount with no kai check (and believed the surge cost 31; the
--   wiki says 45, kb/CONFLICTS.md #9). Now it goes out only with the kai to pay for it, read
--   through monk/004, and a round that cannot pay preps instead of sweeping a rider -- when the
--   mount is this target's. tmounted is one global that no target change resets, so a flag left
--   up by an earlier target still sweeps, as every bypass did before the gate.
-- * The Kai Surge trigger (monk/002): a second surge restarts the no-remount window instead of
--   having the first surge's timer close it early, and it records whom the window holds down.
-- * The kaido aliases (sur, ks, ke, kc, kcr, kh): a typed command goes out whatever we read, with
--   a warning when kai is KNOWN to be short. Four of them used to drop it, silently.
-- Loads the REAL monk/004 and tekura/002, and the real trigger and alias bodies. Every global this
-- file creates or changes is restored at the end (one shared Lua state for all test files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local ROOT = "src_new/"
local KAIKATA = ROOT .. "scripts/levi_ataxia/levi/ataxia/monk/004_Kai_And_Kata.lua"
local TK6 = ROOT .. "scripts/levi_ataxia/levi/levi_scripts/tekura/002_Tekura_6Limb_Offense.lua"
local SURGE = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/monk/002_Kai_Surge.lua"

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
-- A trigger or alias body without its YAML header, as Mudlet runs it.
local function body(p) return assert((loadstring or load)(read(p):match("%]%]%-%-\r?\n(.*)$"), p)) end

-- A clock we move by hand.
local now = 1000
getEpoch = function() return now end

local echoed, sent = {}, {}
cecho = function(s) echoed[#echoed + 1] = s end
ataxiaEcho = function(s) echoed[#echoed + 1] = s end
send = function(c) sent[#sent + 1] = c end
local function allEchoed() return table.concat(echoed, "\n") end
local function ascii(s) return not s:find("[\128-\255]") end

-- cecho reads every <word> as a colour tag, so each one we print must be in OUR palette
-- (misc_scripts/007 replaces Mudlet's).
local PALETTE = { reset = true }
do
  local src = read(ROOT .. "scripts/levi_ataxia/levi/ataxia/misc_scripts/007_Custom_Colour_Table.lua")
  -- Both spellings the table uses: `["NavajoWhite"] = {...}` and `white = {...}`.
  for n in src:gmatch('%["([%w_]+)"%]%s*=') do PALETTE[n] = true end
  for n in src:gmatch('\n%s*([%a_][%w_]*)%s*=%s*{') do PALETTE[n] = true end
end
local function badTag(s)
  for tag in s:gmatch("<([^>]*)>") do
    if not PALETTE[tag] then return tag end
  end
  return nil
end

-- 004 registers a send watcher at load, and TK6 a limb-hit handler: keep both out of the mock.
registerAnonymousEventHandler = function() return 1 end
killAnonymousEventHandler = function() end

ataxia = { vitals = {}, settings = {} }
ataxiaTemp = {}
tAffs = {}
target = "Agathon"
for _, f in ipairs({ KAIKATA, TK6 }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- run() reads these when they exist; another test file may have left one behind.
combatQueue, ataxia_needLockBreak, tekura, affConfigV3 = nil, nil, nil, nil

local PREPPED = 90 -- over the prep line, 100 - 14 (one punch from a break)

-- A target with `kai` of ours (nil = no Kai charstat this session), mounted unless told
-- otherwise. By default all six limbs are prepped but the left leg, and the left leg is the one
-- parried: buildPrepAttack's edge case, the round that reaches the bypass outside a surge window.
-- The mount is Agathon's own: TK6 took its first look at them with the flag down, and trigger 265
-- has set it since (tekura6.mountConfirmed). o.carried: the flag was already up when Agathon
-- became the target -- left by someone else -- and nothing since has said whether they ride.
local function fixture(kai, o)
  o = o or {}
  now = now + 10
  ataxia = { vitals = { kai = kai }, settings = {} }
  ataxiaTemp = { kaiAt = kai and now or nil, parriedLimb = o.parried or "left leg" }
  if o.window then -- our surge landed on o.window (a name), as trigger monk/002 records it
    ataxiaTemp.kaiSurgeWindow, ataxiaTemp.kaiSurgeWho = true, o.window
  end
  tAffs = {}
  tekura6.state.mount = nil -- TK6 has not looked at Agathon yet
  tmounted = o.carried == true
  tekura6.mountConfirmed() -- the first look, which run() takes every round
  tmounted = o.mounted ~= false
  tekura6.config.kaiMode = o.mode or "surge"
  tekura6.state.kaiShortfall = nil -- each test starts with no shortfall echoed
  local hits = {}
  for _, limb in ipairs(tekura6.ALL_LIMBS) do hits[limb] = o.all or PREPPED end
  hits["left leg"] = o.leftLeg or 50
  lb = { Agathon = { hits = hits } }
  echoed, sent = {}, {}
end

local function build() return tekura6.dispatch.buildPrepAttack() end
local function has(s, needle) return s ~= nil and s:find(needle, 1, true) ~= nil end

describe("TK6's dismount waits for the kai to pay for it (tekura/002)", function()
  it("mounted, surge, kai 40: still a combo, with no surge and no sweep", function()
    fixture(40)
    local a = build()
    expect(a ~= nil).toBeTrue()
    expect(has(a, "kai surge")).toBeFalse()
    expect(has(a, "swk")).toBeFalse()
    expect(a:find("^combo Agathon ") ~= nil).toBeTrue()
  end)

  it("kai 45: the round opens with the surge, then the sweep on the parried limb", function()
    fixture(45)
    expect(build()).toBe("kai surge Agathon;combo Agathon swk hfp left hfp left")
  end)

  it("cripple mode: 41 kai is enough, 40 is not", function()
    fixture(41, { mode = "cripple" })
    expect(build():find("^kai cripple Agathon;") ~= nil).toBeTrue()
    fixture(40, { mode = "cripple" })
    expect(has(build(), "kai cripple")).toBeFalse()
  end)

  it("unknown kai (no Kai charstat this session) sends no dismount", function()
    fixture(nil)
    local a = build()
    expect(a ~= nil).toBeTrue()
    expect(has(a, "kai ")).toBeFalse()
    -- a kai restored from disk has no stamp, and counts as unknown too
    fixture(100)
    ataxiaTemp.kaiAt = nil
    expect(has(build(), "kai ")).toBeFalse()
  end)

  it("the fall-through still preps when the parried leg is the only limb left", function()
    fixture(40)
    -- The kick and both punches land on the left leg (50 + 25 + 14 < 100); nothing else is safe.
    expect(build()).toBe("combo Agathon snk left jbp hfp left")
  end)

  it("an unmounted target needs no kai: the sweep goes out at kai 0", function()
    fixture(0, { mounted = false })
    expect(build()).toBe("combo Agathon swk hfp left hfp left")
  end)

  it("echoes a shortfall once, in ASCII, and again only after one was affordable", function()
    fixture(40)
    build()
    build()
    expect(#echoed).toBe(1)
    expect(allEchoed()).toContain("[TK6]")
    expect(allEchoed()).toContain("SURGE needs 45 kai, have 40")
    expect(ascii(allEchoed())).toBeTrue()
    expect(badTag(allEchoed())).toBeNil()
    ataxia.vitals.kai = 45
    build() -- paid for: that shortfall is over
    expect(#echoed).toBe(1)
    ataxia.vitals.kai = 40
    build()
    expect(#echoed).toBe(2)
  end)

  it("says 'unknown' when kai has not been read", function()
    fixture(nil)
    build()
    expect(allEchoed()).toContain("SURGE needs 45 kai, have unknown")
  end)

  -- Our surge just knocked the target down (the window), but nothing clears tmounted after a
  -- surge (only trigger 264 does), and the window opens right after the surge spent its kai.
  it("inside our surge window: no second dismount, and the sweep still goes out at kai 15", function()
    fixture(15, { window = "Agathon", all = 50 })
    local a = build()
    expect(has(a, "kai ")).toBeFalse()
    expect(a).toBe("combo Agathon swk hfp left hfp left")
    expect(#echoed).toBe(0)
    fixture(100, { window = "agathon", all = 50 }) -- isTargeted lowercases the target
    expect(has(build(), "kai ")).toBeFalse()
  end)

  it("a surge window on someone else does not excuse this target's dismount", function()
    fixture(15, { window = "Claes", all = 50 })
    local a = build()
    expect(a ~= nil and a:find("^combo Agathon ") ~= nil).toBeTrue() -- the window branch fell through
    expect(has(a, "swk")).toBeFalse() -- a rider we cannot dismount gets no sweep
    expect(has(a, "kai ")).toBeFalse()
    fixture(45, { window = "Claes", all = 50 })
    expect(build()).toBe("kai surge Agathon;combo Agathon swk hfp left hfp left")
  end)

  -- tmounted is one global, and nothing resets it when the target changes (016 switchTarget): a
  -- flag left up by an earlier target must not cost this one the sweep that went out before.
  it("a mount flag carried over from an earlier target does not withhold the sweep", function()
    fixture(30, { carried = true })
    expect(build()).toBe("combo Agathon swk hfp left hfp left")
    expect(#echoed).toBe(1)
    expect(allEchoed()).toContain("SURGE needs 45 kai, have 30 -- sweeping without it")
    expect(ascii(allEchoed())).toBeTrue()
    expect(badTag(allEchoed())).toBeNil()
    fixture(nil, { carried = true }) -- unknown kai: the same
    expect(build()).toBe("combo Agathon swk hfp left hfp left")
    fixture(45, { carried = true }) -- paid for: the dismount goes out, as it always did
    expect(build()).toBe("kai surge Agathon;combo Agathon swk hfp left hfp left")
  end)

  it("once the flag is seen down on this target, a later one is theirs", function()
    fixture(30, { carried = true })
    tmounted = false -- 264: not mounted
    tekura6.dispatch.run()
    expect(sent[1]).toBe("queue addclear free unwield all;dismount;combo Agathon swk hfp left hfp left")
    tmounted = true -- 265: now they ride
    sent = {}
    tekura6.dispatch.run()
    expect(sent[1]).toBe("queue addclear free unwield all;dismount;combo Agathon snk left jbp hfp left")
    expect(allEchoed()).toContain("SURGE needs 45 kai, have 30 -- no sweep, prepping instead")
  end)

  it("a shortfall said once as 'sweeping' is said again when the round turns to prepping", function()
    fixture(30, { carried = true })
    build()
    expect(#echoed).toBe(1)
    tmounted = false -- seen down (by run()'s look, on a round that did not reach the bypass)...
    tekura6.mountConfirmed()
    tmounted = true -- ...and up again: Agathon's own now
    build()
    expect(#echoed).toBe(2)
    expect(echoed[2]).toContain("-- no sweep, prepping instead")
  end)
end)

describe("the whole TK6 round (tekura6.dispatch.run)", function()
  it("sends the surge only when it is paid for", function()
    fixture(40)
    tekura6.dispatch.run()
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("queue addclear free unwield all;dismount;combo Agathon snk left jbp hfp left")
    fixture(45)
    tekura6.dispatch.run()
    expect(sent[1]).toBe("queue addclear free unwield all;dismount;kai surge Agathon;combo Agathon swk hfp left hfp left")
  end)

  -- The reviewer's case: fight a rider, switch to someone never seen mounted, kai 30.
  it("from a rider to a target never seen mounted, the flag left up costs no sweep", function()
    fixture(30) -- Agathon rides: 265 fired while they were ours
    tekura6.dispatch.run()
    expect(sent[1]).toBe("queue addclear free unwield all;dismount;combo Agathon snk left jbp hfp left")
    lb.Claes = lb.Agathon -- Claes: the same limbs, the same leg parried
    sent = {}
    local ok, err = pcall(function()
      target = "Claes"
      tekura6.dispatch.run()
    end)
    target = "Agathon"
    if not ok then error(err, 0) end
    expect(sent[1]).toBe("queue addclear free unwield all;dismount;combo Claes swk hfp left hfp left")
  end)

  -- run() looks at the flag every round, so a new target's first round with the flag down makes a
  -- later flag theirs, though the bypass itself only looks while the flag is up.
  it("a new target's first round with the flag down makes a later flag theirs", function()
    fixture(30, { mounted = false })
    lb.Claes = lb.Agathon
    local ok, err = pcall(function()
      target = "Claes"
      tekura6.dispatch.run()
      tmounted = true -- 265, about Claes
      sent = {}
      tekura6.dispatch.run()
    end)
    target = "Agathon"
    if not ok then error(err, 0) end
    expect(sent[1]).toBe("queue addclear free unwield all;dismount;combo Claes snk left jbp hfp left")
  end)

  it("tk6status marks a flag that predates the target YES?, in our palette", function()
    fixture(30, { carried = true })
    tekura6.dispatch.status()
    expect(allEchoed()).toContain("Mounted: <yellow>YES?")
    expect(badTag(allEchoed())).toBeNil()
    fixture(30)
    tekura6.dispatch.status()
    expect(allEchoed()).toContain("Mounted: <red>YES")
    expect(allEchoed():find("YES?", 1, true)).toBeNil()
  end)

  it("with no target it sends nothing, and its echo uses only colours in our palette", function()
    fixture(45)
    target = ""
    local ok, err = pcall(tekura6.dispatch.run)
    target = "Agathon"
    if not ok then error(err, 0) end
    expect(#sent).toBe(0)
    expect(allEchoed()).toContain("No target set")
    expect(badTag(allEchoed())).toBeNil()
  end)
end)

describe("the Kai Surge window (monk/002_Kai_Surge)", function()
  -- Timers on the hand-moved clock: tempTimer arms, killTimer disarms, advance() fires what falls
  -- due, earliest first.
  local timers, nextId = {}, 0
  local function pending()
    local n = 0
    for _ in pairs(timers) do n = n + 1 end
    return n
  end
  local function advance(dt)
    local stop = now + dt
    while true do
      local id, at
      for k, t in pairs(timers) do
        if t.at <= stop and (not at or t.at < at) then id, at = k, t.at end
      end
      if not id then break end
      local fn = timers[id].fn
      timers[id] = nil
      now = at
      fn()
    end
    now = stop
  end

  -- One surge landing on our target: the real trigger body in its own environment, so what it
  -- writes stays in `state` (its ataxiaTemp).
  local LINE = "As the power of your kai builds within you, you lift a hand towards Agathon."
  local function surge(state)
    local fn = body(SURGE)
    local noop = function() end
    setfenv(fn, setmetatable({
      matches = { LINE, "Agathon" }, line = LINE,
      isTargeted = function(n) return n == "Agathon" end,
      erAff = noop, tarAffed = noop, selectString = noop, setBold = noop, fg = noop, resetFormat = noop,
      cecho = noop, send = noop, partyrelay = false,
      tempTimer = function(delay, cb)
        nextId = nextId + 1
        timers[nextId] = { at = now + delay, fn = cb }
        return nextId
      end,
      killTimer = function(id) timers[id] = nil end,
      ataxiaTemp = state, ataxia = { afflictions = {} },
    }, { __index = _G }))
    fn()
  end

  it("a second surge 5 s after the first: one timer pending, and its window open 14 s later", function()
    timers, nextId = {}, 0
    local st = {}
    surge(st)
    advance(5)
    surge(st)
    expect(pending()).toBe(1)
    advance(14)
    expect(st.kaiSurgeWindow).toBeTrue()
    expect(st.kaiSurgeWho).toBe("Agathon") -- whom it holds down, for TK6
    advance(2)
    expect(st.kaiSurgeWindow).toBeFalse()
    expect(st.kaiSurgeWho).toBeNil()
    expect(st.kaiSurgeTimer).toBeNil()
    expect(pending()).toBe(0)
  end)

  it("a lone surge still closes its window after 15 s", function()
    timers, nextId = {}, 0
    local st = {}
    surge(st)
    advance(14.9)
    expect(st.kaiSurgeWindow).toBeTrue()
    advance(0.2)
    expect(st.kaiSurgeWindow).toBeFalse()
  end)
end)

describe("the kaido aliases say when kai is short, and still send", function()
  local KAIDO = ROOT .. "aliases/levi_ataxia/for_levi/levi_062424/kaido/"

  -- One press of an alias's real body, with `kai` of ours (nil = no Kai charstat this session).
  local function press(file, kai, tgt)
    now = now + 10
    ataxia = { vitals = { kai = kai, class = kai }, settings = {} }
    ataxiaTemp = { kaiAt = kai and now or nil }
    target = tgt or "Agathon"
    echoed, sent = {}, {}
    body(KAIDO .. file)()
  end

  -- { alias file, a short kai, just enough kai, what it sends, what it says when short }
  local CASES = {
    { "001_SURGE.lua", 30, 45, "queue addclear free kai surge Agathon", "[Kai] SURGE needs 45, have 30 -- sent anyway" },
    { "006_Kaido_Surge.lua", 30, 45, "queue addclear free kai surge Agathon", "[Kai] SURGE needs 45, have 30 -- sent anyway" },
    { "001_kai_enfeeble.lua", 60, 61, "queue addclear free kai enfeeble Agathon", "[Kai] ENFEEBLE needs 61, have 60 -- sent anyway" },
    { "003_KAI_CRIPPLE.lua", 40, 41, "queue addclear free kai cripple Agathon", "[Kai] CRIPPLE needs 41, have 40 -- sent anyway" },
    { "005_Kai_heal.lua", 20, 21, "queue addclear free kai heal", "[Kai] HEAL needs 21, have 20 -- sent anyway" },
  }

  it("short: the typed command still goes out, after an ASCII warning", function()
    for _, c in ipairs(CASES) do
      press(c[1], c[2])
      expect(#sent).toBe(1)
      expect(sent[1]).toBe(c[4])
      expect(#echoed).toBe(1)
      expect(allEchoed()).toContain(c[5])
      expect(ascii(allEchoed())).toBeTrue()
      expect(badTag(allEchoed())).toBeNil()
    end
  end)

  it("enough kai, or kai not read yet: it goes out without a word", function()
    for _, c in ipairs(CASES) do
      for _, kai in ipairs({ c[3], 100 }) do
        press(c[1], kai)
        expect(sent[1]).toBe(c[4])
        expect(#echoed).toBe(0)
      end
      press(c[1], nil)
      expect(sent[1]).toBe(c[4])
      expect(#echoed).toBe(0)
    end
  end)

  it("ks surges at 31-44 kai too, with the warning (it used to gate, silently, at 31)", function()
    press("006_Kaido_Surge.lua", 40)
    expect(sent[1]).toBe("queue addclear free kai surge Agathon")
    expect(allEchoed()).toContain("[Kai] SURGE needs 45, have 40 -- sent anyway")
  end)

  it("kc chokes at 10 kai or unknown kai, and sends MIND CRUSH, said, when known short", function()
    press("002_KAI_CHOKE.lua", 10)
    expect(sent[1]).toBe("queue addclear free kai choke Agathon")
    expect(#echoed).toBe(0)
    press("002_KAI_CHOKE.lua", nil)
    expect(sent[1]).toBe("queue addclear free kai choke Agathon")
    expect(#echoed).toBe(0)
    press("002_KAI_CHOKE.lua", 9)
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("queue addclear free mind crush Agathon")
    expect(allEchoed()).toContain("[Kai] CHOKE needs 10, have 9 -- mind crush instead")
    expect(ascii(allEchoed())).toBeTrue()
    expect(badTag(allEchoed())).toBeNil()
  end)

  it("kc against a denizen chokes at 0 kai: free there (Kaido.wiki:289)", function()
    press("002_KAI_CHOKE.lua", 0, 12345)
    expect(sent[1]).toBe("queue addclear free kai choke 12345")
    expect(#echoed).toBe(0)
  end)
end)

-- Since v4.7.420 trigger 265 records whose mount the flag is (ataxiaTemp.mountedWho): the target
-- we were attacking when its line printed, as the line names nobody. TK6 reads that owner, so a
-- rider's flag no longer follows us to the next target, and a rider whose flag was already up
-- when they became the target is known as one the moment the line prints about them -- which the
-- seen-down-then-up inference above could not see (true over true). Driven through the real 265
-- body and the real target switch, 016's switchTarget. An owner recorded under part of a name
-- (`t aga`) is matched as 016's isTargeted matches a name, and completed with the target's name by
-- its updateTarget, which the last three tests drive.
describe("the mount flag is the target's that trigger 265 printed against", function()
  local TL = dofile(ROOT .. "tests/trigger_lib.lua")
  local MOUNTED = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/265_Mounted.lua"
  local MOUNT_LINE = "Being mounted, your opponent has little use for their legs."
  -- A load failure fails the tests that switch targets, rather than ending this file before its
  -- restore at the bottom runs.
  local loadErr
  for _, f in ipairs({
    ROOT .. "scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua",
    ROOT .. "scripts/levi_ataxia/levi/ataxia/misc_scripts/002_System_Class_Functions.lua",
  }) do
    local ok, err = pcall(dofile, f)
    if not ok and not loadErr then loadErr = "Failed to load " .. f .. ": " .. tostring(err) end
  end

  -- The 265 line about whoever is our target: the real body, once the line is checked against the
  -- trigger's real pattern.
  local function mountLine()
    assert(TL.anyMatches(TL.patterns(MOUNTED), MOUNT_LINE), "265's pattern no longer takes its line")
    body(MOUNTED)()
  end

  -- Our target becomes `who` by 016's switchTarget, as the `t` alias does it. What it reaches
  -- outside TK6's world is stubbed for the call and put back after. The new target has Agathon's
  -- limbs and parries the same leg (switchTarget forgets the last target's parry).
  local STUBBED = { "matches", "gmcp", "pariah", "ataxiaBasher", "raiseEvent", "resetStatesV3",
    "setafflictionstackslevi", "twohanded_resetFractures", "tBals" }
  local function retarget(who)
    if loadErr then error(loadErr, 0) end
    local saved = {}
    for i, k in ipairs(STUBBED) do saved[i] = _G[k] end
    matches = { "t " .. who:lower(), who:lower() }
    gmcp = { Char = { Status = { class = "Monk" } } }
    pariah, ataxiaBasher = nil, nil         -- 016 indexes pariah when set (the runner's is "")
    tBals = {}                              -- 016 writes a field before it replaces the table
    raiseEvent = function() end
    resetStatesV3 = function() end          -- the V3 tracker is not loaded here; TK6 reads tAffs
    setafflictionstackslevi = function() end
    twohanded_resetFractures = function() end
    ataxia.settings.separator = "::"
    ataxiaTemp.class = "Monk"
    local ok, err = pcall(switchTarget, who)
    for i, k in ipairs(STUBBED) do _G[k] = saved[i] end
    if not ok then error(err, 0) end
    lb[target] = lb.Agathon
    ataxiaTemp.parriedLimb = "left leg"
    echoed, sent = {}, {}
  end

  -- Each test starts with Agathon as the target (the alias tests above leave a denizen's number)
  -- and ends with Agathon, pass or fail.
  local function onAgathon(fn)
    target = "Agathon"
    local ok, err = pcall(fn)
    target = "Agathon"
    if not ok then error(err, 0) end
  end

  it("265 records the target it printed against", function()
    onAgathon(function()
      fixture(45, { mounted = false })
      mountLine()
      expect(tmounted).toBeTrue()
      expect(ataxiaTemp.mountedWho).toBe("Agathon")
      expect(build()).toBe("kai surge Agathon;combo Agathon swk hfp left hfp left")
    end)
  end)

  it("a flag 265 set for Agathon is no mount of the next target", function()
    onAgathon(function()
      fixture(45, { mounted = false })
      mountLine()                           -- Agathon rides
      retarget("Claes")
      expect(target).toBe("Claes")
      expect(tmounted).toBeTrue()           -- the global is untouched...
      expect(build()).toBe("combo Claes swk hfp left hfp left") -- ...and no kai goes on Claes
      ataxia.vitals.kai = 30
      expect(build()).toBe("combo Claes swk hfp left hfp left")
      expect(#echoed).toBe(0)               -- no shortfall either: Claes needs no dismount
      tekura6.dispatch.status()
      expect(allEchoed()).toContain("Mounted: <green>NO")
    end)
  end)

  it("the line about the new target makes the flag theirs, though it was already up", function()
    onAgathon(function()
      fixture(30, { mounted = false })
      mountLine()                           -- Agathon rides, and the flag stays up...
      retarget("Claes")
      expect(build()).toBe("combo Claes swk hfp left hfp left")
      mountLine()                           -- ...when the line prints about Claes
      expect(ataxiaTemp.mountedWho).toBe("Claes")
      expect(build()).toBe("combo Claes snk left jbp hfp left") -- a rider we cannot pay to dismount
      expect(allEchoed()).toContain("SURGE needs 45 kai, have 30 -- no sweep, prepping instead")
      ataxia.vitals.kai = 45
      expect(build()).toBe("kai surge Claes;combo Claes swk hfp left hfp left")
      echoed = {}
      tekura6.dispatch.status()
      expect(allEchoed()).toContain("Mounted: <red>YES")
    end)
  end)

  it("the whole round: Agathon's flag sends Claes no surge; Claes's own line does", function()
    onAgathon(function()
      fixture(45, { mounted = false })
      mountLine()
      retarget("Claes")
      tekura6.dispatch.run()
      expect(sent[1]).toBe("queue addclear free unwield all;dismount;combo Claes swk hfp left hfp left")
      mountLine()
      sent = {}
      tekura6.dispatch.run()
      expect(sent[1]).toBe("queue addclear free unwield all;dismount;kai surge Claes;combo Claes swk hfp left hfp left")
    end)
  end)

  -- `t aga` makes the target "Aga" (switchTarget title-cases what was typed), and a later line
  -- naming Agathon completes it through 016's isTargeted -> updateTarget, with no switchTarget:
  -- what any trigger that checks a name against our target does. string.starts (Mudlet's, which
  -- isTargeted calls) is lent for the call.
  local function lineNames(who)
    if loadErr then error(loadErr, 0) end
    local savedStarts = string.starts
    string.starts = string.starts or function(s, p) return s:sub(1, #p) == p end
    local ok, res = pcall(isTargeted, who)
    string.starts = savedStarts
    if not ok then error(res, 0) end
    return res
  end

  it("a rider 265 saw under part of their name stays mounted once a line completes the name", function()
    onAgathon(function()
      fixture(45, { mounted = false })
      retarget("Aga")                       -- `t aga`
      expect(target).toBe("Aga")
      mountLine()                           -- 265 prints before any line has named them in full
      expect(lineNames("Agathon")).toBeTrue()
      expect(target).toBe("Agathon")
      expect(build()).toBe("kai surge Agathon;combo Agathon swk hfp left hfp left")
      expect(ataxiaTemp.mountedWho).toBe("Agathon") -- the owner is completed with the target
    end)
  end)

  it("a known rider targeted again by part of their name is still mounted", function()
    onAgathon(function()
      fixture(45, { mounted = false })
      mountLine()                           -- Agathon rides
      retarget("Aga")                       -- `t aga`: the same person, by the rule isTargeted uses
      expect(build()).toBe("kai surge Aga;combo Aga swk hfp left hfp left")
    end)
  end)

  it("a completed owner does not pass to another name that starts the same way", function()
    onAgathon(function()
      fixture(45, { mounted = false })
      retarget("Aga")
      mountLine()
      lineNames("Agathon")                  -- the rider is Agathon
      retarget("Agatha")                    -- someone else, whose name also starts "Aga"
      expect(build()).toBe("combo Agatha swk hfp left hfp left")
    end)
  end)
end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
