--- test_dead_callee_lines.lua -- active triggers and aliases that threw on every match (2026-11-08)
--
-- Each item below called a global that nothing defines, or indexed a table nothing creates, so
-- Mudlet raised an error on every line it matched and the rest of the body never ran:
--   616 whirl            killTimer(numbRight): a typo for numbedLeft. The parried limb was lost.
--   blade_dance x6       the same killTimer(numbRight) typo.
--   sylvan/014, 015      sylvan_propagateAff, deleted with the old limb counters (3c312975).
--                        014 also read the name from a capture its pattern does not have.
--   vibrato, tremolo     bard_tremvib (3c312975), before `ataxiaTemp.tvBal = true`.
--   557 powderise        earth_powderiseHit (3c312975), before `targetIshere = true`.
--   snb slice x5         swordneed/shieldneed (3c312975) in a dead block that set paraslick.
--   attacks/009          priest_selftLimbHit: a typo for priest_selfLimbHit.
--   twohand/005, 007     slc.* while only the switched-off slc/002 creates `slc`. These two do not
--                        ship: a same-named folder sits beside each leaf, and Muddler's merge keeps
--                        the folder. The guard is checked against the source only.
--   aliases              cat (expandALias), bec (tar), top (goto), mu (osend), colours
--                        (showColours, which Mudlet 5.1.1 does not have: showColors).
-- And the room-items handler: `waterguards` for `waterGuards`, so the salute/grab dedupe never
-- saw a guard it had already handled.
--
-- The last block covers tools/check_orphans.py check 1c's list (2026-11-08): the aliases whose
-- engine is gone (guarded), `viv` (re-pointed at apostate_vivisect), trigger 123 QUAKED, the prompt
-- echo, and bloodPact. Nothing here can be restored: each deleted function read the deleted tLimbs
-- table, and the others were never in this repo (a foreign package's: AK, Svof).
--
-- The REAL trigger and alias bodies run here. Every global they create or change is restored at
-- the end (one shared Lua state for all test files).

local mock = require("mock_mudlet")
local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains

local ROOT = "src_new/"
local LEVI = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/"
local ALIAS = ROOT .. "aliases/levi_ataxia/for_levi/levi_062424/"

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
-- A trigger or alias body without its YAML header, as Mudlet runs it.
local function body(p) return assert((loadstring or load)(read(p):match("%]%]%-%-\r?\n(.*)$"), p)) end

-- Mudlet's killTimer refuses anything but an id ("bad argument #1 type ... got nil!").
local killed
local function mudletKillTimer(id)
  if type(id) ~= "number" and type(id) ~= "string" then
    error("killTimer: bad argument #1 type (timer id as number or string expected, got "
      .. type(id) .. "!)", 2)
  end
  killed[#killed + 1] = id
  return false
end

-- Mudlet 5.1.1's table.contains (mudlet-lua/lua/TableUtils.lua:221-239): a non-table first
-- argument is not an error, it simply contains nothing.
local function mudletContains(t, v)
  if type(t) ~= "table" then return false end
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

local added, erased
local function world()
  mock.reset()
  killed, added, erased = {}, {}, {}
  killTimer = mudletKillTimer
  table.contains = mudletContains
  target = "Agathon"
  isTargeted = function(n) return type(n) == "string" and n:lower() == "agathon" end
  tarAffed = function(...)
    for _, a in ipairs({ ... }) do added[#added + 1] = a end
  end
  erAff = function(a) erased[#erased + 1] = a end
  haveAff = function(a) return tAffs[a] and true or false end
  ataxiaTemp, tAffs = {}, {}
  envenomList = {}
  targetIshere = nil
  cecho = function() end
  fg, deselect = function() end, function() end
  matches, multimatches = nil, nil
end

local function contains(list, v)
  for _, x in ipairs(list) do if x == v then return true end end
  return false
end

local ok, err = pcall(function()

describe("616 whirl: a parry after a left-arm numb (killTimer typo)", function()
  local WHIRL = body(LEVI .. "616_Whirl_(morningstars).lua")

  it("kills the numb timer, clears it, and records the parried limb", function()
    world()
    numbedLeft = 7
    tAffs.numbedleftarm = true
    multimatches = {
      { "You whip a morning star toward the left leg of Agathon.", "a morning star", "left leg", "Agathon" },
      { "" },
      -- the third-person form is kb/raw/logs/2026-08-19_leviticus_blademaster-vs-sentinel_loss_Sentinel.txt:839
      { "Agathon parries the attack with a deft manoeuvre." },
    }
    WHIRL()
    expect(ataxiaTemp.parriedLimb).toBe("left leg")
    expect(tAffs.numbedleftarm).toBeNil()
    expect(killed[1]).toBe(7)
    expect(numbedLeft).toBeNil()
  end)

  it("a parry with no numb timer running kills nothing", function()
    world()
    numbedLeft = nil
    multimatches = {
      { "You whip a morning star toward the head of Agathon.", "a morning star", "head", "Agathon" },
      { "" },
      { "Agathon parries the attack with a deft manoeuvre." },
    }
    WHIRL()
    expect(ataxiaTemp.parriedLimb).toBe("head")
    expect(#killed).toBe(0)
  end)
end)

describe("blade dance: a parry after a left-arm numb (the same killTimer typo)", function()
  local FILES = { "001_Blade_Jab_-_Arms.lua", "002_Blade_Jab_-_Torso.lua", "004_Flick.lua",
    "005_High_Sun_Arm.lua", "006_HeelSnap.lua", "007_High_Sun_-_Head.lua" }

  -- The parry path reads only the third row (first row: the jab; second: the line delta). The
  -- third-person form is kb/raw/logs/2026-08-19_leviticus_blademaster-vs-sentinel_loss_Sentinel.txt:839.
  local function parry(file)
    tAffs.numbedleftarm = numbedLeft and true or nil
    ataxiaTemp.lastLimbHit = "left arm"
    bardtemposequence = 0
    multimatches = { { "" }, { "" }, { "Agathon parries the attack with a deft manoeuvre." } }
    body(LEVI .. "blade_dance/" .. file)()
  end

  it("kills the numb timer, clears it, and records the parried limb, in all six", function()
    for _, file in ipairs(FILES) do
      world()
      numbedLeft = 7
      parry(file)
      expect(killed[1]).toBe(7)
      expect(numbedLeft).toBeNil()
      expect(tAffs.numbedleftarm).toBeNil()
      expect(ataxiaTemp.parriedLimb).toBe("left arm")
    end
  end)

  it("a parry with no numb timer running kills nothing, in all six", function()
    for _, file in ipairs(FILES) do
      world()
      numbedLeft = nil
      parry(file)
      expect(#killed).toBe(0)
      expect(ataxiaTemp.parriedLimb).toBe("left arm")
    end
  end)
end)

describe("sylvan thornrend: sylvan_propagateAff restored (3c312975 deleted it)", function()
  local UNTARGETED = body(LEVI .. "sylvan/014_Untargeted_thornrend.lua")
  local LIMB = body(LEVI .. "sylvan/015_Thornrended_Limb.lua")
  -- Loaded inside a pcall, so a missing script fails these tests and not the whole file.
  sylvan_propagateAff = nil
  pcall(dofile, ROOT .. "scripts/levi_ataxia/levi/ataxia/limb_management/011_Sylvan_Propagation.lua")

  it("maps the arms' propagation to its affliction, and false when there is none", function()
    world()
    ataxiaTemp.currentProps = { arms = "kelp" }
    expect(sylvan_propagateAff()).toBe("healthleech")
    ataxiaTemp.currentProps = { arms = "hawthorn" }
    expect(sylvan_propagateAff()).toBe("sensitivity")
    ataxiaTemp.currentProps = { arms = false }
    expect(sylvan_propagateAff()).toBeFalse()
    -- `prop` was never run: no table at all.
    ataxiaTemp.currentProps = nil
    expect(sylvan_propagateAff()).toBeFalse()
  end)

  it("015 adds the propagated affliction with the envenom, and marks the limb attack", function()
    world()
    ataxiaTemp.currentProps = { arms = "bellwort" }
    envenomList = { "curare" }
    multimatches = { { "You command the razor-edged thorny vines around you to lash out and rend the left leg of Agathon.",
      "left leg", "Agathon" } }
    LIMB()
    expect(targetIshere).toBeTrue()
    expect(contains(added, "curare")).toBeTrue()
    expect(contains(added, "weariness")).toBeTrue()
    expect(#envenomList).toBe(0)
    expect(lastLimbAttack).toBe("thornrend")
    expect(contains(erased, "shield")).toBeTrue()
  end)

  it("015 with nothing propagated adds only the envenom, never a false affliction", function()
    world()
    ataxiaTemp.currentProps = nil
    envenomList = { "curare" }
    multimatches = { { "You command the razor-edged thorny vines around you to lash out and rend the head of Agathon.",
      "head", "Agathon" } }
    LIMB()
    expect(#added).toBe(1)
    expect(added[1]).toBe("curare")
  end)

  it("014 reads the name from its only capture and adds the propagated affliction", function()
    world()
    ataxiaTemp.currentProps = { arms = "valerian" }
    multimatches = { { "You command the razor-edged thorny vines around you to lash out and rend the flesh of Agathon.",
      "Agathon" } }
    UNTARGETED()
    expect(targetIshere).toBeTrue()
    expect(#added).toBe(1)
    expect(added[1]).toBe("slickness")
  end)

  it("014 on someone else adds nothing", function()
    world()
    ataxiaTemp.currentProps = { arms = "valerian" }
    multimatches = { { "You command the razor-edged thorny vines around you to lash out and rend the flesh of Zed.", "Zed" } }
    UNTARGETED()
    expect(#added).toBe(0)
    expect(targetIshere).toBeNil()
  end)
end)

describe("bard vibrato/tremolo: bard_tremvib is gone (3c312975)", function()
  it("vibrato on the target sets the tremolo/vibrato balance flag", function()
    world()
    matches = { "With a trilling vibrato you attack Agathon's broken left arm. He screams in pain.", "Agathon", "left" }
    body(LEVI .. "limb_hits_unorganised/003_Vibrato.lua")()
    expect(ataxiaTemp.tvBal).toBeTrue()
  end)

  it("tremolo on the target sets it too", function()
    world()
    matches = { "Using a heavy tremolo you brutally punish Agathon's already shattered right leg.", "Agathon", "right" }
    body(LEVI .. "limb_hits_unorganised/004_Tremolo.lua")()
    expect(ataxiaTemp.tvBal).toBeTrue()
  end)
end)

describe("557 powderise: earth_powderiseHit is gone (3c312975)", function()
  it("a hit on the target marks it present", function()
    world()
    -- kb/raw/logs/2026-11-01_unknown_earthlord-vs-sentinel_loss_JDvzR7j7.txt:86 (target Vothaec)
    matches = { "Your fist crunches into the head of Agathon.", "head", "Agathon" }
    body(LEVI .. "557_Powderise.lua")()
    expect(targetIshere).toBeTrue()
  end)
end)

describe("snb slice: the dead swordneed/shieldneed block (3c312975)", function()
  local SNB = LEVI .. "snb/"
  local FILES = { "001_SnB_slice_no_limb.lua", "006_SnB_slice_limb.lua", "011_SnB_slice_limb4.lua",
    "012_SnB_slice_limb3.lua", "013_SnB_slice_limb2.lua" }

  it("a dodged slice runs to the end in all five triggers", function()
    for _, f in ipairs(FILES) do
      world()
      gmcp = { Char = { Status = { class = "Runewarden" } } }
      swordneed, shieldneed, targetlimb = nil, nil, nil
      ataxiaTemp.ignoreShield = nil
      local limbLine = f ~= "001_SnB_slice_no_limb.lua"
      multimatches = {
        limbLine and { "You slice into the left leg of Agathon with a scimitar.", "left leg", "Agathon", "a scimitar" }
          or { "You slice into Agathon with a scimitar.", "Agathon", "a scimitar" },
        { "" },
        { "The attack rebounds back onto you!" },
      }
      local ran, e = pcall(body(SNB .. f))
      if not ran then error(f .. ": " .. tostring(e)) end
    end
  end)
end)

describe("attacks/009 priest smite: priest_selftLimbHit typo", function()
  it("the smite reaches the real priest_selfLimbHit, which highlights the limb", function()
    world()
    local selected = {}
    selectString = function(s) selected[#selected + 1] = s; return 0 end
    setBold, resetFormat = function() end, function() end
    dofile(ROOT .. "scripts/levi_ataxia/levi/ataxia/self_limb_tracking/001_Different_Attacks.lua")
    matches = { "Zed utters a prayer and smites your left arm with a holy hammer.", "Zed", "left arm", "a holy hammer" }
    body(LEVI .. "attacks/009_Priest_Smite.lua")()
    expect(selected[1]).toBe("left arm")
  end)
end)

describe("twohand overhand/underhand: slc exists only in the switched-off slc/002", function()
  it("an overhand hammer blow records the weapon and the head", function()
    world()
    slc, slc_last_limb = nil, nil
    -- kb/raw/logs/2026-11-01_claes_runewarden-vs-runewarden_loss_CxxKSMq.txt:225
    multimatches = { { "Blonk brings an eponymously emblazoned wooden hammer down upon you with a brutal overhand blow.",
      "Blonk", "an eponymously emblazoned wooden hammer" } }
    body(LEVI .. "twohand/007_Overhand.lua")()
    expect(slc.overhand_weapon).toBe("hammer")
    expect(slc_last_limb).toBe("head")
  end)

  it("an underhand blow records the weapon and the limb", function()
    world()
    slc, slc_last_limb = nil, nil
    -- kb/raw/logs/2026-11-01_claes_runewarden-vs-runewarden_loss_CxxKSMq.txt:560-561 (wrapped there)
    multimatches = { { "Blonk explodes upward from a low crouch, driving an eponymously emblazoned wooden hammer toward your torso.",
      "Blonk", "an eponymously emblazoned wooden hammer", "torso" } }
    body(LEVI .. "twohand/005_Underhand.lua")()
    expect(slc.underhand_weapon).toBe("hammer")
    expect(slc_last_limb).toBe("torso")
  end)
end)

describe("aliases that called undefined globals", function()
  it("cat expands bp and draws catarin (expandALias)", function()
    world()
    local expanded = {}
    expandAlias = function(c) expanded[#expanded + 1] = c end
    matches = { "cat" }
    body(ALIAS .. "051_CATARIN.lua")()
    expect(expanded[1]).toBe("bp")
    expect(mock.was_sent("legenddeck draw catarin")).toBeTrue()
  end)

  it("bec beckons the target (tar)", function()
    world()
    tar = nil
    matches = { "bec" }
    body(ALIAS .. "apostate/009_BECKON.lua")()
    expect(mock.was_sent("demon beckon Agathon")).toBeTrue()
  end)

  it("top walks to the target's room (goto)", function()
    world()
    local went
    mmp = {
      pdb = { Agathon = 1234 },
      getnums = function() return { 4321 } end,
      gotoRoom = function(r) went = r end,
      echo = function() end,
      cleanAreaName = function(s) return s end,
      areatabler = {},
    }
    getRoomArea = function() return 1 end
    matches = { "top" }
    body(ALIAS .. "052_GO_TO_TARGET.lua")()
    expect(went).toBe(4321)
    expect(mock.was_sent("pt going to Agathon in 4321")).toBeTrue()
  end)

  it("mu unlocks and tells the party (osend)", function()
    world()
    matches = { "mu" }
    body(ALIAS .. "telepathy/001_MIND_UNLOCK.lua")()
    expect(mock.was_sent("mind unlock Agathon")).toBeTrue()
    expect(mock.was_sent("pt MIND UNLOCK: Agathon")).toBeTrue()
  end)

  it("colours N shows the colour table (showColours is not a Mudlet function)", function()
    world()
    local cols
    showColours = nil
    showColors = function(n) cols = n end
    matches = { "colours 4", "4" }
    body(ALIAS .. "195_Show_Colours.lua")()
    expect(cols).toBe(4)
  end)
end)

describe("room items: the guard dedupe reads waterGuards (waterguards typo)", function()
  local function room(items)
    gmcp = { Char = { Items = { List = { location = "room", items = items } } } }
  end

  it("a guardsman already saluted is not saluted again", function()
    world()
    ataxia = { denizensHere = {} }
    ataxiaBasher = { enabled = false }
    ataxiaBasher_invalidateStormhammer = function() end
    ataxiaBasher_isMount, ataxiaBasher_profanedForget = nil, nil
    item_Pickup = {}
    dofile(ROOT .. "scripts/levi_ataxia/levi/ataxia/update_stuff/003_ataxia_RoomContents_Update.lua")
    saluteGuards, beckonGuards = true, nil
    waterguards = nil
    waterGuards = { "555" }
    room({ { id = "555", name = "an audacious guardsman", attrib = "m" } })
    ataxia_RoomContents_Update("gmcp.Char.Items.List")
    expect(mock.was_sent("wsalute 555")).toBeFalse()
    expect(#waterGuards).toBe(1)

    -- A new one is saluted once, and remembered.
    room({ { id = "556", name = "an audacious guardsman", attrib = "m" } })
    ataxia_RoomContents_Update("gmcp.Char.Items.List")
    expect(mock.was_sent("wsalute 556")).toBeTrue()
    expect(#waterGuards).toBe(2)
    saluteGuards = nil
  end)
end)

-- Files whose only statement is one call to the global, guarded because it is gone. Run with the
-- global missing they must not throw; with a stand-in present (another package, or a restored
-- engine) they must still call it.
describe("aliases whose engine is gone: the guard, both ways (check 1c)", function()
  local SINGLE = {
    { "earth_lord/006_HEAD_PATH.lua", "headpath" },
    { "earth_lord/014_RIGHT_SIDE.lua", "rightside" },
    { "earth_lord/015_LEFT_SIDE.lua", "leftside" },
    { "114_SOFTLOCK_BASIC.lua", "infernalpriosbasic" },
    { "115_RIGHT_ARM.lua", "infernalpriosprep" },
    { "116_RIGHT_LEG.lua", "infernalpriosprep" },
    { "117_LEFT_LEG.lua", "infernalpriosprep" },
    { "119_TORSO.lua", "infernalpriosprep" },
    { "122_DAMAGE.lua", "infernalpriosdamage" },
    { "125_IMPALE.lua", "infernalpriosimpale" },
    { "128_TRAMPLE.lua", "infernalpriostrample" },
    { "129_RAGEBLADE.lua", "infernalpriosblackout" },
    { "131_DARKSHADE.lua", "infernalpriosdarkshade" },
    { "029_INITIATE.lua", "svo_init_system" },
  }

  local function run(file, name, standIn)
    world()
    _G[name] = standIn
    local ran, e = pcall(body(ALIAS .. file))
    _G[name] = nil
    if not ran then error(file .. ": " .. tostring(e)) end
  end

  it("does nothing, and throws nothing, with the global missing", function()
    for _, row in ipairs(SINGLE) do run(row[1], row[2], nil) end
  end)

  it("still calls it when something defines it", function()
    for _, row in ipairs(SINGLE) do
      local calls = 0
      run(row[1], row[2], function() calls = calls + 1 end)
      expect(calls).toBe(1)
    end
  end)

  it("ila and ihe still set the limb and run the parry warning, with both engines gone", function()
    for _, file in ipairs({ "113_LEFT_ARM.lua", "120_HEAD.lua" }) do
      world()
      infernalpriosprep, infernalpriosbasic = nil, nil
      local limb = file == "113_LEFT_ARM.lua" and "left arm" or "torso"
      local warned
      ataxia_boxEcho = function(s) warned = s end
      tAffs.nausea = nil
      ataxiaTemp.parriedLimb = limb
      targetlimb = nil
      body(ALIAS .. file)()
      expect(targetlimb).toBe(file == "113_LEFT_ARM.lua" and "left arm" or "head")
      expect(warned).toBe("THEY ARE PARRYING THAT LIMB --- YOU IDIOT")
    end
  end)

  it("ila and ihe throw nothing in any of their three branches with both engines gone", function()
    for _, file in ipairs({ "113_LEFT_ARM.lua", "120_HEAD.lua" }) do
      local parried = file == "113_LEFT_ARM.lua" and "left arm" or "torso"
      for _, state in ipairs({ { nausea = true }, { parriedLimb = parried }, {} }) do
        world()
        infernalpriosprep, infernalpriosbasic = nil, nil
        ataxia_boxEcho = function() end
        tAffs.nausea = state.nausea
        ataxiaTemp.parriedLimb = state.parriedLimb
        local ran, e = pcall(body(ALIAS .. file))
        if not ran then error(file .. ": " .. tostring(e)) end
      end
    end
  end)

  it("ila still reaches a defined prep engine", function()
    world()
    local prep = 0
    infernalpriosprep = function() prep = prep + 1 end
    infernalpriosbasic = nil
    body(ALIAS .. "113_LEFT_ARM.lua")()
    expect(prep).toBe(1)
    infernalpriosprep = nil
  end)

  it("kel as an Infernal does not throw with infernalpriosweariness gone", function()
    world()
    infernalpriosweariness = nil
    gmcp = { Char = { Status = { class = "Infernal" } } }
    ataxiaNDB_getClass = function() return "Magi" end
    local ran, e = pcall(body(ALIAS .. "apostate/008_KELP_STACK.lua"))
    if not ran then error(e) end
  end)

  it("aoff throws on neither line with noDisplay and ak missing, and uses them when present", function()
    world()
    noDisplay, ak = nil, nil
    body(ALIAS .. "012_DISPLAY_OFF.lua")()
    expect(ak).toBeNil()

    local calls = 0
    noDisplay = function() calls = calls + 1 end
    ak = {}
    body(ALIAS .. "012_DISPLAY_OFF.lua")()
    expect(calls).toBe(1)
    expect(ak.nodisplay).toBeTrue()
    noDisplay, ak = nil, nil
  end)
end)

describe("130 and 018: `ak` is another system's table, and nothing here creates it", function()
  local gagged, echoed
  local function lines()
    world()
    gagged, echoed = 0, {}
    deleteFull = function() gagged = gagged + 1 end
    cecho = function(s) echoed[#echoed + 1] = s end
    matches = { "the line", "Agathon" }
    ak = nil
  end

  it("130 still gags and echoes the crush with ak missing", function()
    lines()
    gmcp = { Char = { Vitals = { charstats = { "Bleed: 0", "Rage: 0", "Shape: Crag" } } } }
    body(LEVI .. "130_SHIELD_CRUSHED.lua")()
    expect(gagged).toBe(1)
    expect(#echoed).toBe(1)
    expect(echoed[1]:find("Shape: Crag", 1, true) ~= nil).toBeTrue()
  end)

  it("130 still echoes with no charstats in GMCP", function()
    lines()
    gmcp = { Char = { Vitals = {} } }
    body(LEVI .. "130_SHIELD_CRUSHED.lua")()
    expect(#echoed).toBe(1)
  end)

  it("130 writes the flag when that system is loaded", function()
    lines()
    gmcp = { Char = { Vitals = { charstats = {} } } }
    ak = { defs = { shield = true } }
    body(LEVI .. "130_SHIELD_CRUSHED.lua")()
    expect(ak.defs.shield).toBe(false)
    ak = nil
  end)

  it("018 does not throw with ak missing, and calls scoreup when it exists", function()
    lines()
    body(LEVI .. "018_RAGEBLADE_GAG.lua")()
    expect(gagged).toBe(1)
    local scored = 0
    ak = { prompt = { scoreup = function() scored = scored + 1 end } }
    body(LEVI .. "018_RAGEBLADE_GAG.lua")()
    expect(scored).toBe(1)
    ak = nil
  end)
end)

describe("viv: apostate_viviprio was deleted, apostate_vivisect is the wrapper now", function()
  it("sets the vivisect mode and dispatches", function()
    world()
    apostate, apostate_viviprio = nil, nil
    dofile(ROOT .. "scripts/levi_ataxia/levi/levi_scripts/apostate/015_CC_Apostate.lua")
    local dispatched = 0
    apostate.dispatch = function() dispatched = dispatched + 1 end
    apostate.state.mode = "lock"
    body(ALIAS .. "130_VIVISECT.lua")()
    expect(apostate.state.mode).toBe("vivisect")
    expect(dispatched).toBe(1)
  end)
end)

describe("123 QUAKED: OppGainedAff is a call to a tracker this repo never shipped", function()
  -- kb/raw/logs/2026-11-01_unknown_earthlord-vs-sentinel_loss_JDvzR7j7.txt:319
  local STOMP = "You stomp upon the ground, a ripple of tremors radiating out from the impact."

  it("the stomp's gag and echo still run, and nothing throws", function()
    world()
    OppGainedAff = nil
    local deleted, echoes = 0, {}
    deleteFull = function() deleted = deleted + 1 end
    cecho = function(s) echoes[#echoes + 1] = s end
    matches = { STOMP }
    body(LEVI .. "123_QUAKED.lua")()
    expect(deleted).toBe(1)
    expect(echoes[1]:find("PRONED ALL THOSE LOSERS", 1, true) ~= nil).toBeTrue()
  end)

  it("a defined OppGainedAff still receives the prone", function()
    world()
    local got
    OppGainedAff = function(a) got = a end
    deleteFull = function() end
    matches = { STOMP }
    body(LEVI .. "123_QUAKED.lua")()
    expect(got).toBe("prone")
    OppGainedAff = nil
  end)

  it("558 Quake is what records the prone on that line, while the target is here", function()
    world()
    targetIshere = true
    ataxia = { playersHere = {} }
    selectString, resetFormat = function() return 0 end, function() end
    line = STOMP
    matches = { STOMP }
    body(LEVI .. "558_Quake.lua")()
    expect(contains(added, "prone")).toBeTrue()
  end)
end)

describe("ataxia_promptEcho: limbCounter_promptAddon is defined nowhere", function()
  local function load()
    world()
    limbCounter_promptAddon = nil
    ataxia_isClass = function(c) return c == "magi" end
    ataxia_promptAffs = function() ataxiaTemp.promptAffs = (ataxiaTemp.promptAffs or 0) + 1 end
    ataxia = { settings = { prompt = { affs = true } } }
    gmcp = { Char = { Vitals = { nl = "1" } } }
    dofile(ROOT .. "scripts/levi_ataxia/levi/ataxia/010_Prompt_Running.lua")
  end

  it("as a Magi the affliction echo runs and nothing throws", function()
    load()
    ataxia_promptEcho()
    expect(ataxiaTemp.promptAffs).toBe(1)
  end)

  it("as a Magi a defined addon is still called, as a Serpent it is not", function()
    load()
    local calls = 0
    limbCounter_promptAddon = function() calls = calls + 1 end
    ataxia_promptEcho()
    expect(calls).toBe(1)
    ataxia_isClass = function() return false end
    ataxia_promptEcho()
    expect(calls).toBe(1)
    limbCounter_promptAddon = nil
  end)
end)

describe("bloodPact: apo and addToCommand were never in this repo", function()
  local function load()
    world()
    apo, addToCommand, apostate = nil, nil, nil
    bloodTimer, dsum, pentagramEnt = nil, nil, "baalzadeen"
    dofile(ROOT .. "scripts/levi_ataxia/levi/levi_scripts/apostate/015_CC_Apostate.lua")
  end

  it("returns, without throwing, when neither exists", function()
    load()
    expect(bloodPact()).toBeNil()
  end)

  it("with a package providing both it still builds the commands", function()
    load()
    local cmds = {}
    addToCommand = function(c) cmds[#cmds + 1] = c end
    apo = { pentagram = function() return false end, demon = function() return "daegger" end }
    bloodTimer = true
    bloodPact()
    expect(#cmds).toBe(2)
    expect(cmds[1]).toBe("summon daegger")
    expect(cmds[2]).toBe("wield daegger shield;demon bloodpact &tar for baalzadeen/order loyals kill &tar")
  end)

  it("with the pentagram up and the wrong demon it swaps to the pentagram's demon", function()
    load()
    local cmds = {}
    addToCommand = function(c) cmds[#cmds + 1] = c end
    apo = { pentagram = function() return true end, demon = function() return "fiend" end }
    dsum = true
    bloodPact()
    expect(#cmds).toBe(1)
    expect(cmds[1]).toBe("wield daegger shield;dispel pentagram;summon baalzadeen")
  end)
end)

describe("bardvenomprioslimb: bardlimbattack was deleted, and nothing calls this", function()
  it("runs to the end with bardlimbattack gone", function()
    world()
    bardlimbattack = nil
    getLockingAffliction = function() return "none" end
    checkAffList = function() return false end
    tBals = {}
    dofile(ROOT .. "scripts/levi_ataxia/levi/levi_scripts/037_TEST_LIMB_PRIOS.lua")
    local ran, e = pcall(bardvenomprioslimb)
    if not ran then error(e) end
    expect(type(bardvenom)).toBe("table")
  end)
end)

end)

mock.reset()
table.contains = savedContains
-- Restore the shared Lua state: drop every global the loaded files created and put back every
-- one they replaced.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
