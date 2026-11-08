--- test_shikudo_group_damage.lua -- v4.7.456, from the 2026-10-27 group log (ZQfua3XR):
--   * the staff a round wields: an inventory id, never the bare keyword that took the lightspire
--   * ASSESS only with the Health Inspector trait; the trait list (misc_scripts/031, 792/793)
--   * no round at a dead or absent target (006 shikudo.targetUsable)
--   * the group damage route (shikudo/013) and `sr`
--   * the [SK] combo line (shikudo/012) and its triggers (797/798, 794, 795, 796)
-- Loads the REAL scripts and trigger bodies. Every global they create or change is restored at the
-- end (one shared Lua state for all test files).

local before = {}
for k, v in pairs(_G) do before[k] = v end

local TL = dofile("src_new/tests/trigger_lib.lua")

local ROOT = "src_new/"
local SH = ROOT .. "scripts/levi_ataxia/levi/levi_scripts/shikudo/"
local KAIKATA = ROOT .. "scripts/levi_ataxia/levi/ataxia/monk/004_Kai_And_Kata.lua"
local TRAITS = ROOT .. "scripts/levi_ataxia/levi/ataxia/misc_scripts/031_Traits.lua"
local TRIG = ROOT .. "triggers/levi_ataxia/for_levi/leviticus/"
local ALIAS = ROOT .. "aliases/levi_ataxia/for_levi/levi_062424/"

local function read(p) local f = assert(io.open(p, "r")); local s = f:read("*a"); f:close(); return s end
local function body(p) return assert((loadstring or load)(read(p):match("%]%]%-%-\r?\n(.*)$"), p)) end

local now = 1000
getEpoch = function() return now end
local printed = {}
cecho = function(s) printed[#printed + 1] = s end
local echoed = {}
ataxiaEcho = function(s) echoed[#echoed + 1] = s end
local timers = {}
tempTimer = function(_, fn) timers[#timers + 1] = fn end
local sent = {}
send = function(s) sent[#sent + 1] = s end
sendGMCP = function() end
ataxia_saveSettings = function() end
isTargeted = function(n) return type(n) == "string" and type(target) == "string" and n:lower() == target:lower() end
ataxia_isClass = function(c) return c == "monk" end
selectCurrentLine, fg, resetFormat = function() end, function() end, function() end
bg, replace = function() end, function() end

ataxia = { vitals = {}, settings = {}, afflictions = {} }
ataxiaTemp = {}
tAffs = {}
target = "Sadey"
lb = {}
gmcp = { Char = { Items = {} }, Room = {} }
for _, f in ipairs({ KAIKATA, TRAITS, SH .. "006_CC_Shikudo_Dispatch.lua", SH .. "007_CC_Shikudo_Lock.lua",
                     SH .. "010_Shikudo_Strike_Ledger.lua", SH .. "012_Shikudo_Combo_Echo.lua",
                     SH .. "013_Shikudo_Group_Damage.lua" }) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

-- A fight: our form and chain, the target's afflictions and limbs, the players in the room.
local function setup(form, affs, opts)
  opts = opts or {}
  ataxia.vitals = { form = form, kata = opts.kata or 0 }
  ataxia.settings = { separator = ";" }
  ataxia.playersHere = opts.here or { "Sadey", "Akri" }
  ataxiaTemp = {}
  tAffs = affs or {}
  haveAff = function(a) return tAffs[a] and true or false end
  combatQueue, reboundHold, tCity = nil, nil, nil
  ataxiaBasher = { enabled = false } -- a shared Lua state: another test file can leave the basher on
  shikudoDmg.state = { breathHeld = {} }
  shikudoEcho.rec = nil
  shikudoEcho.formAtPrompt, shikudoEcho.stanceAtPrompt, shikudostance = nil, nil, nil
  shikudoLedger.cur = nil
  lb = { Sadey = { hits = { head = opts.head or 0, torso = 0, ["left arm"] = 0, ["right arm"] = 0,
    ["left leg"] = 0, ["right leg"] = 0 } } }
  target = "Sadey"
  sent, printed, echoed, timers = {}, {}, {}, {}
  -- The user's inventory, as GMCP lists it: the oaken staff, the Magi staff and the lightspire.
  gmcp.Char.Items.List = { location = "inv", items = {
    { id = "485994", name = "a Shar'ilian lightspire", attrib = "lL" },
    { id = "569815", name = "a primordial staff" },
    { id = "489282", name = "a twisted oaken staff" },
  } }
  shikudo.invEvent("gmcp.Char.Items.List")
end

describe("the staff a round wields (the lightspire swap, 2026-10-27)", function()
  it("picks the oaken staff's id from the inventory, never the lightspire", function()
    setup("Oak")
    expect(shikudo.staffRef()).toBe("staff489282")
  end)

  it("never takes an item whose name does not end in 'staff'", function()
    setup("Oak")
    gmcp.Char.Items.List = { location = "inv", items = { { id = "485994", name = "a Shar'ilian lightspire", attrib = "l" } } }
    shikudo.invEvent("gmcp.Char.Items.List")
    expect(shikudo.inventoryStaff()).toBeNil()
    expect(shikudo.staffRef()).toBe("staff")
  end)

  it("the skstaff setting wins, then the inventory, then the staff2 weapon slot", function()
    setup("Oak")
    ataxia.settings.shikudoStaff = "staff123456"
    expect(shikudo.staffRef()).toBe("staff123456")
    ataxia.settings.shikudoStaff = nil
    ataxiaTemp.shikudoStaves = nil
    ataxia.settings.weapons = { staff2 = "staff777" }
    expect(shikudo.staffRef()).toBe("staff777")
  end)

  it("the lock offense (007, sr's old route) wields the id too", function()
    setup("Oak", {}, { kata = 0 })
    shikudoLock.dispatch()
    local line = sent[#sent]
    expect(line:find("wield staff489282;", 1, true) ~= nil).toBeTrue()
    expect(line:find("wield staff;", 1, true)).toBeNil()
  end)

  it("794: a refusal drops the inventory id it sent and prints FAILED", function()
    setup("Oak")
    body(TRIG .. "794_Shikudo_No_Staff.lua")()
    expect(ataxiaTemp.shikudoStaves["489282"]).toBeNil()
    expect(printed[#printed]:find("FAILED: no staff (staff489282)", 1, true) ~= nil).toBeTrue()
  end)
end)

describe("ASSESS only with Health Inspector (the user, 2026-10-27)", function()
  it("the user's own list has no Health Inspector, so no round carries ASSESS", function()
    setup("Oak")
    ataxia_traitRacial("Child of Ceylon")
    for _, t in ipairs({ "Nimble", "Fully fit", "Marksman", "Improved physique", "Master contemplator",
                         "Decorated", "Lucky", "In service", "Clean freak" }) do
      ataxia_traitLevel(t)
    end
    expect(ataxia_hasTrait("Master contemplator")).toBeTrue()
    expect(ataxia_assessFree()).toBeFalse()
    expect(ataxia_contemplateFree()).toBeFalse()
    expect(shikudo.assessSuffix(true, ";")).toBe("")
    shikudoDmg.dispatch()
    expect(sent[#sent]:find("assess", 1, true)).toBeNil()
  end)

  it("Health inspector in the list turns ASSESS on", function()
    setup("Oak")
    ataxia_traitRacial("Child of Ceylon")
    ataxia_traitLevel("Health inspector")
    expect(ataxia_assessFree()).toBeTrue()
    expect(shikudo.assessSuffix(true, ";")).toBe(";assess Sadey")
    expect(shikudo.assessSuffix(false, ";")).toBe("")
  end)

  it("an unread list answers no", function()
    setup("Oak")
    expect(ataxia_traitsKnown()).toBeFalse()
    expect(ataxia_assessFree()).toBeFalse()
  end)

  it("a Level row outside the Racial row's window is not a trait", function()
    setup("Oak")
    ataxia_traitRacial("Child of Ceylon")
    now = now + 10
    ataxia_traitLevel("Health inspector")
    expect(ataxia_assessFree()).toBeFalse()
  end)

  it("every class: the send filter removes ASSESS and CONTEMPLATE commands without the trait", function()
    setup("Oak")
    local F = ataxia_traitFilter
    expect(F("queue addclear free wield x;combo Sadey a b c;assess Sadey"))
      .toBe("queue addclear free wield x;combo Sadey a b c")
    expect(F("queue addclear free assess Sadey;combo Sadey a b c"))
      .toBe("queue addclear free combo Sadey a b c")
    -- Depthswalker's form (001_Attack:87), spaces before the separator.
    expect(F("shadow cull Sadey curare;assess Sadey ;contemplate Sadey")).toBe("shadow cull Sadey curare")
    -- Psion's form (001_Levi_Psion_Logic:362) with a two-character separator.
    ataxia.settings.separator = "::"
    expect(F("weave x Sadey::assess Sadey::contemplate Sadey")).toBe("weave x Sadey")
    ataxia.settings.separator = ";"
    expect(F("assess Sadey")).toBe("")
    expect(F("boon contemplate Bloodscent")).toBe("boon contemplate Bloodscent")
    expect(F("say I will assess the situation")).toBe("say I will assess the situation")
    expect(F("combo Sadey a b c")).toBe("combo Sadey a b c")
  end)

  it("the filter keeps what the trait makes free", function()
    setup("Oak")
    ataxia_traitRacial("Child of Ceylon")
    ataxia_traitLevel("Health inspector")
    expect(ataxia_traitFilter("combo Sadey a;assess Sadey;contemplate Sadey")).toBe("combo Sadey a;assess Sadey")
    ataxia_traitLevel("Mind warden")
    expect(ataxia_traitFilter("combo Sadey a;assess Sadey;contemplate Sadey"))
      .toBe("combo Sadey a;assess Sadey;contemplate Sadey")
  end)

  it("send itself is filtered, and a command left empty is not sent", function()
    setup("Oak")
    send("queue addclear free combo Sadey a;assess Sadey")
    send("assess Sadey")
    expect(#sent).toBe(1)
    expect(sent[1]).toBe("queue addclear free combo Sadey a")
    ataxia_rawSend("assess Sadey")
    expect(sent[2]).toBe("assess Sadey")
  end)

  it("792 and 793 match the game's rows, and read the trait names", function()
    local function pat(f) return TL.patterns(TRIG .. f)[1] end
    local r, l = pat("792_Trait_List_Racial.lua"), pat("793_Trait_List_Level.lua")
    expect(r.pat).toBe([[^Racial:\s+(.+?)\s*$]])
    expect(l.pat).toBe([[^Level \d+:\s+(.+?)\s*$]])
    -- The same rows through Lua patterns of the same meaning (trigger_lib has no \s).
    expect(("Racial:   Child of Ceylon"):match("^Racial:%s+(.-)%s*$")).toBe("Child of Ceylon")
    expect(("Level 100: Clean freak              "):match("^Level %d+:%s+(.-)%s*$")).toBe("Clean freak")
  end)
end)

describe("no round at a dead or absent target", function()
  it("not in the room: nothing is sent, and one line says why", function()
    setup("Oak", {}, { here = { "Akri" } })
    shikudoDmg.dispatch()
    shikudoDmg.dispatch()
    expect(#sent).toBe(0)
    local n = 0
    for _, p in ipairs(printed) do if p:find("not here", 1, true) then n = n + 1 end end
    expect(n).toBe(1)
  end)

  it("401 marks the kill: no round for 6 s, then rounds again", function()
    setup("Oak")
    shikudo.markDead("Sadey")
    shikudoDmg.dispatch()
    expect(#sent).toBe(0)
    now = now + 7
    shikudoDmg.dispatch()
    expect(#sent).toBe(1)
  end)

  it("a revived target the room shows again is attacked at once", function()
    setup("Oak")
    shikudo.markDead("Sadey")
    gmcp.Room.AddPlayer = { name = "Sadey" }
    shikudo.playerAdded()
    shikudoDmg.dispatch()
    expect(#sent).toBe(1)
  end)

  it("795 ('no power over the dead') marks our target dead", function()
    setup("Oak")
    body(TRIG .. "795_Mind_No_Power_Over_Dead.lua")()
    expect(shikudo.targetUsable("Sadey")).toBeFalse()
    expect(shikudo.targetUsable("Sadey", true)).toBeFalse()
  end)

  it("a MIND round may reach out of the room; a strike may not", function()
    setup("Oak", {}, { here = { "Akri" } })
    expect(shikudo.targetUsable("Sadey", true)).toBeTrue()
    expect(shikudo.targetUsable("Sadey")).toBeFalse()
  end)
end)

describe("the group damage route (shikudo/013)", function()
  local function round() return sent[#sent] end

  -- The user, 2026-11-02: "It should do mind crush in rain when doing srd for damage. If we cannot
  -- mind crush then kai choke. No combos in srd as, once again it is for damage."
  it("Rain: MIND CRUSH alone, with no combo and no staff to wield", function()
    setup("Rain", {}, { kata = 3 })
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free mind crush Sadey")
  end)

  it("Rain: MIND CRUSH comes first even when kai could pay for a choke", function()
    setup("Rain", {}, { kata = 3 })
    ataxiaTemp.kaiAt = now
    ataxia.vitals.kai = 40
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free mind crush Sadey")
  end)

  it("Rain: KAI CHOKE when the crush would take mana below the floor", function()
    setup("Rain", {}, { kata = 3 })
    ataxiaTemp.kaiAt = now
    ataxia.vitals.kai = 40
    ataxia.vitals.mp, ataxia.vitals.maxmp = 1000, 3000 -- the floor is 30% of 3000
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free kai choke Sadey")
  end)

  it("the mana floor is the sipping setting, and exactly the floor still crushes", function()
    setup("Rain", {}, { kata = 3 })
    ataxia.vitals.mp, ataxia.vitals.maxmp = 1050, 3000
    expect(shikudoDmg.canCrush()).toBeTrue()
    ataxia.vitals.mp = 1049
    expect(shikudoDmg.canCrush()).toBeFalse()
    ataxia.settings.sipping = { manause = 10 }
    expect(shikudoDmg.canCrush()).toBeTrue()
  end)

  it("an unknown mana does not block the crush", function()
    setup("Rain", {}, { kata = 3 })
    ataxia.vitals.mp, ataxia.vitals.maxmp = nil, nil
    expect(shikudoDmg.canCrush()).toBeTrue()
  end)

  it("Rain: neither one payable sends nothing, and one line says why", function()
    setup("Rain", {}, { kata = 3 })
    ataxia.vitals.mp, ataxia.vitals.maxmp = 100, 3000
    ataxiaTemp.kaiAt = now
    ataxia.vitals.kai = 5
    shikudoDmg.dispatch()
    shikudoDmg.dispatch()
    expect(#sent).toBe(0)
    local n = 0
    for _, p in ipairs(printed) do if p:find("No attack", 1, true) then n = n + 1 end end
    expect(n).toBe(1)
  end)

  it("a choke that did not land means no choke for a while", function()
    setup("Rain", {}, { kata = 3 })
    ataxiaTemp.kaiAt = now
    ataxia.vitals.kai = 40
    ataxia.vitals.mp, ataxia.vitals.maxmp = 100, 3000
    shikudoDmg.chokeCast("Sadey")
    timers[#timers]() -- no landing line came
    shikudoDmg.dispatch()
    expect(#sent).toBe(0)
    now = now + 11
    ataxiaTemp.kaiAt = now
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free kai choke Sadey")
  end)

  it("a choke that landed (063) keeps the choke", function()
    setup("Rain", {}, { kata = 3 })
    shikudoDmg.chokeCast("Sadey")
    ataxiaTemp.kaiChokeLandedAt = now
    timers[#timers]()
    expect(shikudoDmg.breathHeld("Sadey")).toBeFalse()
  end)

  it("out of Rain: adopt Rain alone, whatever the kata, and no crush in the same round", function()
    for _, form in ipairs({ "Oak", "Gaital", "Willow", "Tykonos", "Maelstrom" }) do
      setup(form, {}, { kata = 12 })
      shikudoDmg.dispatch()
      expect(round()).toBe("queue addclear free wield staff489282;adopt rain form")
    end
  end)

  it("no ordinary round in any form holds a combo", function()
    for _, form in ipairs({ "Rain", "Oak", "Gaital", "Willow", "Tykonos", "Maelstrom" }) do
      setup(form, {}, { kata = 15 })
      shikudoDmg.dispatch()
      expect(round():find("combo", 1, true)).toBeNil()
      expect(round():find("transition", 1, true)).toBeNil()
    end
  end)

  it("Maelstrom: CRESCENT alone at half health and prone; above half, adopt Rain", function()
    setup("Maelstrom", { prone = true }, { kata = 12 })
    ataxiaTemp.lastAssessAt, ataxiaTemp.lastAssessWho = now, "Sadey"
    ataxiaTemp.lastAssessHp, ataxiaTemp.lastAssessMax = 3000, 6000
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free wield staff489282;combo Sadey crescent")
    ataxiaTemp.lastAssessHp = 3100
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free wield staff489282;adopt rain form")
  end)

  it("DISPATCH when prone with a damaged head and a crushed throat", function()
    setup("Rain", { prone = true, crushedthroat = true }, { head = 100 })
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free wield staff489282;dispatch Sadey")
  end)

  -- The city comes from the NDB, through the real ataxia_ndb/003 getter (shikudo.targetIsMhaldorian,
  -- 006). This route read a global tCity that nothing ever assigned, so a Mhaldorian was dispatched.
  it("INCAPACITATE for a Mhaldorian the NDB knows; anyone else is dispatched", function()
    setup("Rain", { prone = true, crushedthroat = true }, { head = 100 })
    dofile(ROOT .. "scripts/levi_ataxia/levi/ataxia/ataxia_ndb/003_ataxiaNDB_API.lua")
    ataxiaNDB = { players = { Sadey = { city = "Mhaldor" } } }
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free wield staff489282;incapacitate Sadey")

    -- Another city, or a name the NDB has not gathered, is dispatched: the old global decides nothing.
    ataxiaNDB.players.Sadey.city = "Cyrene"
    tCity = "Mhaldor"
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free wield staff489282;dispatch Sadey")
    tCity = nil
    ataxiaNDB.players.Sadey = nil
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free wield staff489282;dispatch Sadey")
    -- No NDB at all: still a dispatch, and no error at the kill.
    ataxiaNDB = nil
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free wield staff489282;dispatch Sadey")
  end)

  -- The user, 2026-11-02: MIND CRUSH passes a shield, so srd has no shatter and no combo for it.
  it("a shield changes nothing: the crush still goes", function()
    setup("Rain", { shield = true })
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free mind crush Sadey")
    setup("Oak", { shield = true })
    shikudoDmg.dispatch()
    expect(round()).toBe("queue addclear free wield staff489282;adopt rain form")
  end)

  it("sr is the lock, srd the damage route", function()
    setup("Oak", {}, { kata = 3 })
    gmcp.Char.Status = { class = "Monk" }
    body(ALIAS .. "154_Group_(All_Classes).lua")()
    -- The lock prints its [LOCK] status; the damage route never does.
    local lock = false
    for _, p in ipairs(printed) do if p:find("[LOCK]", 1, true) then lock = true end end
    expect(lock).toBeTrue()
    printed = {}
    body(ALIAS .. "shikudo/009_Group_Damage.lua")()
    for _, p in ipairs(printed) do expect(p:find("[LOCK]", 1, true)).toBeNil() end
    expect(round()).toBe("queue addclear free wield staff489282;adopt rain form")
  end)

  it("the crush callout is a party line the game understands", function()
    local f = io.open(TRIG .. "monk/001_Crush.lua", "r")
    local src = f:read("*a")
    f:close()
    expect(src:find('send("pt " ..matches[2]', 1, true) ~= nil).toBeTrue()
    expect(src:find('send("pt: ', 1, true)).toBeNil()
  end)

  it("srd with no Shikudo form sends nothing", function()
    setup("Oak", {}, { kata = 3 })
    ataxia.vitals.form = nil
    body(ALIAS .. "shikudo/009_Group_Damage.lua")()
    expect(#sent).toBe(0)
  end)
end)

describe("the [SK] combo line (shikudo/012)", function()
  local DMG = "As your blow lands with a crunch, you perceive that you have dealt 9.2% damage to Sadey's left arm."

  local function strike(text, outcome)
    shikudoLedger.strike(text)
    if outcome then shikudoLedger.outcome(outcome) end
  end

  it("three hits with their limbs and afflictions, closed by the kata line", function()
    setup("Rain", {}, { kata = 3 })
    strike("You lash out with a straight kick at the left shoulder of Sadey.", DMG)
    strike("Falling back into a low crouch, you lash out with a swift strike at the left thigh of Sadey.",
      "As your blow lands with a crunch, you perceive that you have dealt 9.2% damage to Sadey's left leg.")
    shikudoEcho.onAfflicted("tar afflicted", { "prone" })
    shikudoEcho.onAfflicted("tar afflicted", { "weariness", "prone" })
    strike("You whip a twisted oaken staff at Sadey in a controlled arc, bringing its length to crack against her torso.",
      "Sadey staggers as the staff cracks across her ribs, sweat breaking out upon her forehead.")
    shikudoEcho.close(3)
    local line = printed[#printed]
    expect(line).toBe("\n<chartreuse>[SK] Sadey  HIT 3/3  LA+9.2 LL+9.2  prone weariness  Rain:3")
  end)

  it("797/798 match the game's lines", function()
    local p797 = TL.patterns(TRIG .. "797_Strike_Into_Reflection.lua")[1]
    local p798 = TL.patterns(TRIG .. "798_Reflection_Blinks_Out.lua")[1]
    expect(TL.matches(p797.pat, p797.type, "The attack harmlessly passes through one of Akri's reflections.")).toBeTrue()
    expect(TL.matches(p798.pat, p798.type, "A reflection of Akri blinks out of existence.")).toBeTrue()
  end)

  it("a reflection in our combo drops the strike in flight; another player's is ignored", function()
    setup("Oak", {}, { kata = 9 })
    target = "Akri"
    ataxia.playersHere = { "Akri" }
    strike("You drive your foot up in a rising kick at the torso of Akri.")
    shikudoEcho.onReflection("Akri")
    strike("Turning with the motion, you channel the momentum of your previous strike into a thrust at the solar plexus of Akri with a twisted oaken staff.")
    shikudoEcho.onReflection("Akri")
    shikudoEcho.onReflection("Valkyri")
    shikudoEcho.close(12)
    expect(printed[#printed]).toBe("\n<red>[SK] Akri  MISS 0/2  (reflection 2)  Oak:12")
  end)

  it("the prompt closes a combo the kata line did not, and a quiet strike shows as unseen", function()
    setup("Oak", {}, { kata = 3 })
    strike("You drive your foot up in a rising kick at the torso of Sadey.", DMG)
    strike("Turning with the motion, you channel the momentum of your previous strike into a thrust at the solar plexus of Sadey with a twisted oaken staff.")
    shikudoEcho.close()
    expect(printed[#printed]).toBe("\n<yellow>[SK] Sadey  HIT 1/2  (1 unseen)  LA+9.2  Oak:3")
  end)

  it("while a combo is read, the inline [AFF] tags are left to the [SK] line", function()
    setup("Oak")
    expect(shikudoEcho.recording()).toBeFalse()
    strike("You drive your foot up in a rising kick at the torso of Sadey.")
    expect(shikudoEcho.recording()).toBeTrue()
    ataxia.settings.shikudoEcho = false
    expect(shikudoEcho.recording()).toBeFalse()
  end)

  -- The user's screen, 2026-11-03: three strikes that hit an Arcadian sentry, then a red
  -- "[SK] 651916  MISS 0/3  (3 unseen)  Willow:12". The ledger does not read "Damage dealt".
  local function bashCombo()
    strike("Lunging forward, you drive the end of a twisted oaken staff viciously into the solar plexus of an Arcadian sentry.",
      "Damage dealt: 5988 (physical blunt).")
    expect(shikudoEcho.recording()).toBeFalse()
    strike("You whip a twisted oaken staff at the side of an Arcadian sentry's neck.",
      "Damage dealt: 713 (physical blunt).")
    strike("You drive your foot up in a rising kick at the head of an Arcadian sentry.",
      "Damage dealt: 748 (physical blunt).")
    shikudoEcho.close(12)
  end

  it("prints nothing for a combo at a denizen: a numeric target", function()
    setup("Oak", {}, { kata = 9 })
    target = 651916
    bashCombo()
    expect(#printed).toBe(0)
    expect(shikudoEcho.recording()).toBeFalse()
  end)

  it("prints nothing with the basher on, even at a target with a name", function()
    setup("Oak", {}, { kata = 9 })
    ataxiaBasher.enabled = true
    bashCombo()
    expect(#printed).toBe(0)
    expect(shikudoEcho.recording()).toBeFalse()
  end)

  -- MISS needs proof (v4.7.475): a strike with no outcome line may have hit.
  local KICK = "You drive your foot up in a rising kick at the torso of Sadey."
  local THRUST = "Turning with the motion, you channel the momentum of your previous strike into a thrust at the solar plexus of Sadey with a twisted oaken staff."
  local PARRIED = "Sadey parries the attack with a deft manoeuvre."

  it("zero hits with no strike settled is a yellow UNSEEN, not a red MISS", function()
    setup("Oak", {}, { kata = 3 })
    strike(KICK)
    strike(THRUST)
    shikudoEcho.close(3)
    expect(printed[#printed]).toBe("\n<yellow>[SK] Sadey  UNSEEN 0/2  (2 unseen)  Oak:3")
  end)

  it("a parry and a quiet strike is UNSEEN: nothing proves the second one missed", function()
    setup("Oak", {}, { kata = 3 })
    strike(KICK, PARRIED)
    strike(THRUST)
    shikudoEcho.close(3)
    expect(printed[#printed]).toBe("\n<yellow>[SK] Sadey  UNSEEN 0/2  (parry 1)  (1 unseen)  Oak:3")
  end)

  it("every strike proven to fail is still a red MISS", function()
    setup("Oak", {}, { kata = 3 })
    strike(KICK, PARRIED)
    strike(THRUST, "You fumble your strike, the attack going wide.")
    shikudoEcho.close(3)
    expect(printed[#printed]).toBe("\n<red>[SK] Sadey  MISS 0/2  (fumble 1, parry 1)  Oak:3")
  end)

  it("a dodge is a miss with its reason (kb/raw/logs/2026-11-03_shikudo-group-alias.txt:11214-11219)", function()
    setup("Rain", {}, { kata = 12 })
    target = "Averine"
    strike("You lash out with a straight kick at the right shoulder of Averine.",
      "Averine dexterously dances aside, evading your blow.")
    strike("Falling back into a low crouch, you lash out with a swift strike at the right thigh of Averine.",
      "As your blow lands with a crunch, you perceive that you have dealt 9.2% damage to Averine's right leg.")
    strike("You spin a full rotation, bringing a twisted oaken staff around in a blur of motion to smash into the right arm of Averine.",
      "As your blow lands with a crunch, you perceive that you have dealt 9.2% damage to Averine's right arm.")
    shikudoEcho.close(15)
    expect(printed[#printed]).toBe("\n<yellow>[SK] Averine  HIT 2/3  (dodge 1)  RL+9.2 RA+9.2  Rain:15")
  end)

  it("KAI HEAL opens like a strike and is not one (kb/raw/logs/2026-11-01_elmer_shikudo-vs-runewarden_win_2N1HTSWZ.txt:1099)", function()
    setup("Oak", {}, { kata = 3 })
    local unresolved = shikudoLedger.unresolved
    local p587 = TL.patterns(TRIG .. "587_Shikudo_Strike_Start.lua")[1]
    local row = "You whip your hands through the air, and a red haze formed of your Kai energy forms about you. It disperses suddenly, refreshing you and healing your"
    expect(TL.matches(p587.pat, p587.type, row)).toBeTrue()
    shikudoLedger.strike(row)
    expect(shikudoEcho.recording()).toBeFalse()
    expect(shikudoLedger.cur == nil).toBeTrue()
    shikudoEcho.prompt()
    shikudoLedger.flush()
    expect(#printed).toBe(0)
    expect(shikudoLedger.unresolved).toBe(unresolved)
  end)

  it("a kai heal between two strikes leaves the strike in flight alone", function()
    setup("Oak", {}, { kata = 3 })
    strike(KICK)
    shikudoLedger.strike("You whip your hands through the air, and a red haze formed of your Kai energy forms about you.")
    shikudoLedger.outcome(DMG)
    shikudoEcho.close(3)
    expect(printed[#printed]).toBe("\n<chartreuse>[SK] Sadey  HIT 1/1  LA+9.2  Oak:3")
  end)

  it("789 hands over the dodge line", function()
    local matched = false
    for _, p in ipairs(TL.patterns(TRIG .. "789_Shikudo_Strike_Outcome.lua")) do
      if TL.matches(p.pat, p.type, "Averine dexterously dances aside, evading your blow.") then matched = true end
    end
    expect(matched).toBeTrue()
  end)

  -- The form label (v4.7.475). The user's screen, 2026-11-03: "Willow:12" for an Oak combo, one row
  -- above the Willow form line. GMCP named the next form before the lines of its block were read.
  local OAK_LINE, WILLOW_LINE = TRIG .. "stances/003_Oak_Form.lua", TRIG .. "stances/004_Willow_Form.lua"
  local HIT = "\n<chartreuse>[SK] Sadey  HIT 1/1  LA+9.2  "

  it("an inline transition: the combo keeps its form, and the next combo has the new one", function()
    setup("Oak", {}, { kata = 9 })
    body(OAK_LINE)()
    shikudoEcho.prompt()
    ataxia.vitals.form = "Willow"
    strike(KICK, DMG)
    shikudoEcho.close(12)
    expect(printed[#printed]).toBe(HIT .. "Oak:12")
    body(WILLOW_LINE)()
    shikudoEcho.prompt()
    strike(KICK, DMG)
    shikudoEcho.close(3)
    expect(printed[#printed]).toBe(HIT .. "Willow:3")
  end)

  it("a combo that only the prompt closes keeps its form too", function()
    setup("Oak", {}, { kata = 9 })
    body(OAK_LINE)()
    shikudoEcho.prompt()
    ataxia.vitals.form = "Willow"
    strike(KICK, DMG)
    body(WILLOW_LINE)()
    shikudoEcho.prompt()
    expect(printed[#printed]).toBe(HIT .. "Oak:9")
  end)

  it("a transition sent first: the strikes are in the new form, with GMCP behind or ahead", function()
    setup("Oak", {}, { kata = 9 })
    body(OAK_LINE)()
    shikudoEcho.prompt()
    body(WILLOW_LINE)()
    strike(KICK, DMG)
    shikudoEcho.close(3)
    expect(printed[#printed]).toBe(HIT .. "Willow:3")

    ataxia.vitals.form = "Willow"
    shikudoEcho.prompt()
    ataxia.vitals.form = "Oak"
    body(OAK_LINE)()
    strike(KICK, DMG)
    shikudoEcho.close(3)
    expect(printed[#printed]).toBe(HIT .. "Oak:3")
  end)

  it("a form change with no form line (a stumble): GMCP wins from the next prompt", function()
    setup("Oak", {}, { kata = 12 })
    body(OAK_LINE)()
    shikudoEcho.prompt()
    ataxia.vitals.form = "Tykonos"
    strike(KICK, DMG)
    shikudoEcho.close(12)
    expect(printed[#printed]).toBe(HIT .. "Oak:12")
    shikudoEcho.prompt()
    strike(KICK, DMG)
    shikudoEcho.close(3)
    expect(shikudostance).toBe("oak")
    expect(printed[#printed]).toBe(HIT .. "Tykonos:3")
  end)

  it("318 ends the combo and takes the form at every prompt", function()
    expect(read(TRIG .. "318_Prompt_Trigger.lua"):find("shikudoEcho.prompt()", 1, true) ~= nil).toBeTrue()
  end)

  it("796 names the last command that carried KAI", function()
    setup("Oak")
    ataxia_kaiSendSeen("queue addclear free kai choke Crixos;assess Crixos")
    ataxia_kaiSendSeen("combo Crixos risingkick torso")
    body(TRIG .. "796_Kai_Power_Question.lua")()
    expect(echoed[#echoed]:find("kai choke Crixos", 1, true) ~= nil).toBeTrue()
  end)
end)

describe("the party limb-hit call", function()
  it("is off for a Monk unless set, on for other classes, and the setting wins", function()
    setup("Oak")
    expect(ataxia_relayLimbHits()).toBeFalse()
    ataxia_isClass = function(c) return c == "magi" end
    expect(ataxia_relayLimbHits()).toBeTrue()
    ataxia.settings.relayLimbHits = false
    expect(ataxia_relayLimbHits()).toBeFalse()
    ataxia_isClass = function(c) return c == "monk" end
    ataxia.settings.relayLimbHits = true
    expect(ataxia_relayLimbHits()).toBeTrue()
  end)
end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
