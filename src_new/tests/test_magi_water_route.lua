--- test_magi_water_route.lua -- Tabethys's Magi water route: mode "waterroute", run by the new
--- alias ww (v4.7.421)
--
-- The route (kb/raw/players/magi-tabethys-2026-10-12.txt; .claude/classes/magi.md, "Tabethys's
-- core rotation"): magma, dehydrate, dehydrate, fulminate; the mudslide "bonk" at water 2; then
-- emanate water, freeze until frozen, and glaciate (hypothermia first only when glaciate would not
-- kill). Before v4.7.421 no mode ran it: vv's "water" mode runs the fire tree, and P3/P7/P8 sit
-- above every mode branch with gates of their own.
--
-- What this file loads is REAL: the affliction API (017), the V3 tracker (007, 008), 001_Resonance,
-- 004_Magi_Offense, and the bodies of the ww, mm and vv aliases. Resonance reaches the offense the
-- way it does in the game, through gmcp.Char.Vitals.charstats and get_resonance (dispatch calls it);
-- the target's afflictions are V3 branches written straight into the tracker, so haveAff,
-- getAffProbabilityV3 and getStateProbabilityV3 are the real functions. One shared Lua state:
-- every global, and table.contains, is restored at the end.

local before = {}
for k, v in pairs(_G) do before[k] = v end
local savedContains = table.contains

local MAGE = "src_new/scripts/levi_ataxia/levi/levi_scripts/mage/"
local ALIASES = "src_new/aliases/levi_ataxia/for_levi/levi_062424/"
local NAME = "Xarthus"

-- Fresh tables, so the loads below build their own and the restore drops them. The V3 files
-- initialise theirs as `X = X or {...}`, so a table an earlier test file left would be reused.
magi = nil
for _, k in ipairs({ "afflictionStatesV3", "affConfigV3", "simpleAffsV3", "affCacheV3", "targetBurningLevelV3",
  "affLastConfirmedV3", "targetDefensesV3", "cureBalancesV3", "cureBalanceTimerIDsV3", "passiveCooldownsV3",
  "negativeConfirmTimersV3", "tAffsV2", "tAffStacksV2" }) do
  _G[k] = nil
end
ataxia = { afflictions = {}, settings = {} }
ataxiaTemp, tAffs, affTimers = {}, {}, {}
target = NAME
partyrelay = false
targetHealth, php = nil, nil
gmcp = { Char = { Status = { class = "Magi" }, Vitals = { bal = "1", eq = "1", charstats = {} } } }

-- A failed load is raised inside the protected block below, so the restore at the end still runs.
local loadErr
for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua",    -- haveAff, the API
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
  MAGE .. "001_Resonance.lua",
  MAGE .. "004_Magi_Offense.lua",
}) do
  local okLoad, errLoad = pcall(dofile, f)
  if not okLoad then loadErr = "Failed to load " .. f .. ": " .. tostring(errLoad); break end
end
-- table.contains is a Mudlet extension (the real tarAffed uses it); restored at the end.
table.contains = table.contains or function(t, v)
  for _, x in pairs(t) do if x == v then return true end end
  return false
end

-- The alias bodies below their YAML headers, as Mudlet runs them (test_monk_aliases' idiom).
local function aliasBody(file)
  local fh = assert(io.open(ALIASES .. file, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(assert(src:match("%]%]%-%-\r?\n(.*)$"), "no header: " .. file), "=" .. file))
end

-- What the offense sends, and what it echoes.
local sent, echoes = {}, {}
send = function(cmd) sent[#sent + 1] = cmd end
cecho = function(s) echoes[#echoes + 1] = s end
echo = function(s) echoes[#echoes + 1] = s end
ataxiaEcho = function(s) echoes[#echoes + 1] = s end

-- Resonance as the game sends it: one charstats entry per plane that is up. The key format is the
-- one get_resonance reads (unconfirmed by a capture, kb/CONFLICTS.md #29).
local LEVEL = { "Minor", "Moderate", "Major" }
local function reso(r)
  local stats = {}
  for _, plane in ipairs({ "air", "earth", "fire", "water" }) do
    local n = r[plane] or 0
    if n > 0 then stats[#stats + 1] = "R" .. plane .. ": " .. LEVEL[n] end
  end
  gmcp.Char.Vitals.charstats = stats
  get_resonance()
end

-- The target as V3 holds it. `affs(...)`: one certain branch. `branches{ {p, aff, ...}, ... }`:
-- several. Written straight into the tracker, then the cache rebuilt as the tracker does.
local function set(list, from)
  local s = {}
  for i = from or 1, #list do s[list[i]] = true end
  return s
end
local function branches(list)
  afflictionStatesV3 = {}
  for _, b in ipairs(list) do
    afflictionStatesV3[#afflictionStatesV3 + 1] = { affs = set(b, 2), prob = b[1] }
  end
  simpleAffsV3 = {}
  rebuildCacheV3()
end
local function affs(...) branches({ { 1.0, ... } }) end

-- A fresh round: no target state left over, the mode set, and health as `hp` (nil = no reading).
local function world(opts)
  opts = opts or {}
  target = NAME
  sent, echoes = {}, {}
  local st = magi.offense.state
  magi.offense.reset()
  st.mode = opts.mode or "waterroute"
  st.scalded = opts.scalded or false
  st.conflagrated = opts.conflagrated or false
  st.shalestorm = opts.shalestorm or false
  magi.offense.config.glaciateKillAt = 100
  -- Health as the assess tail leaves it: targetHealth from general/001, and trigger 698's stamp
  -- (the figure, when, and whom it read: `assessed`, default our target whenever there is a reading).
  targetHealth, php = opts.hp, nil
  ataxiaTemp = {}
  if opts.hp then
    ataxiaTemp.lastAssess = opts.hp
    ataxiaTemp.lastAssessAt = getEpoch()
    ataxiaTemp.lastAssessWho = opts.assessed or NAME
  end
  if opts.branches then branches(opts.branches) else affs(unpack(opts.affs or {})) end
  reso(opts.reso or {})
end

-- One round through dispatch: the spell the route chose, out of the command it sent.
local function round()
  sent = {}
  magi.offense.dispatch()
  local cmd = sent[#sent]
  return cmd and cmd:match("shield::(.-)::assess") or cmd
end

local function T(spell) return (spell:gsub("<T>", NAME)) end

local ok, err = pcall(function()
if loadErr then error(loadErr, 0) end

describe("ww opener: magma, dehydrate, dehydrate, fulminate, keyed on the live state", function()
  it("sends the cast the way every Magi round goes out (stand, staff, spell, assess)", function()
    world()
    magi.offense.dispatch()
    expect(sent[#sent]).toBe("queue addclearfull freestand stand::wield staff569815 shield::cast magma at "
      .. NAME .. "::assess " .. NAME)
  end)

  it("unscalded: magma", function()
    world({ reso = { water = 2, earth = 1, fire = 3 } })
    expect(round()).toBe(T("cast magma at <T>"))
  end)

  it("scalded by either clock (the offense's own, or V3) is scalded", function()
    world({ scalded = true })
    expect(round()).toBe(T("cast dehydrate at <T>"))
    world({ affs = { "scalded" } })
    expect(round()).toBe(T("cast dehydrate at <T>"))
  end)

  it("scalded, water 0 or 1: dehydrate", function()
    world({ scalded = true, reso = { earth = 1, fire = 1 } })
    expect(round()).toBe(T("cast dehydrate at <T>"))
    world({ scalded = true, reso = { earth = 1, fire = 2, water = 1 } })
    expect(round()).toBe(T("cast dehydrate at <T>"))
  end)

  it("water 2, air 0: fulminate, at fire 3 as at any other fire level", function()
    for _, fire in ipairs({ 0, 1, 2, 3 }) do
      world({ scalded = true, reso = { earth = 1, fire = fire, water = 2 } })
      expect(round()).toBe(T("cast fulminate at <T>"))
    end
  end)

  it("re-derives after a fade: water back to 1 is a dehydrate again, air back to 0 a fulminate", function()
    world({ scalded = true, reso = { earth = 1, fire = 3, water = 1, air = 1 } })
    expect(round()).toBe(T("cast dehydrate at <T>"))
    world({ scalded = true, reso = { earth = 1, fire = 3, water = 2, air = 0 } })
    expect(round()).toBe(T("cast fulminate at <T>"))
  end)
end)

describe("ww bonk: the mudslide at water 2", function()
  it("water 2, air 1, earth 1: mudslide", function()
    world({ scalded = true, reso = { earth = 1, fire = 3, water = 2, air = 1 } })
    expect(round()).toBe(T("cast mudslide at <T>"))
  end)

  it("needs no asthma: either of fulminated and asthma feeds the lock", function()
    world({ scalded = true, affs = { "fulminated" }, reso = { earth = 1, fire = 3, water = 2, air = 1 } })
    expect(round()).toBe(T("cast mudslide at <T>"))
  end)

  it("earth 0 or 2: still the mudslide", function()
    for _, earth in ipairs({ 0, 2 }) do
      world({ scalded = true, reso = { earth = earth, fire = 3, water = 2, air = 1 } })
      expect(round()).toBe(T("cast mudslide at <T>"))
    end
  end)
end)

describe("ww is not pre-empted by the shared priorities; the guards still apply", function()
  it("P8's asthma + water 2 mudslide does not jump the fulminate", function()
    world({ scalded = true, affs = { "asthma" }, reso = { earth = 1, fire = 3, water = 2 } })
    expect(round()).toBe(T("cast fulminate at <T>"))
    -- The same state in fire mode is P8's mudslide: the route really is ahead of it.
    world({ mode = "fire", scalded = true, affs = { "asthma" }, reso = { earth = 1, fire = 3, water = 2 } })
    expect(round()).toBe(T("cast mudslide at <T>"))
  end)

  it("P4's stormhammer at 25% does not replace the route", function()
    world({ hp = 20, reso = { water = 2 } })
    expect(round()).toBe(T("cast magma at <T>"))
  end)

  it("P5's free scintilla under a shalestorm does not replace the route", function()
    world({ shalestorm = true, scalded = true, reso = { earth = 2, water = 1 } })
    expect(round()).toBe(T("cast dehydrate at <T>"))
    world({ mode = "fire", shalestorm = true, scalded = true, reso = { earth = 2, water = 1 } })
    expect(round()).toBe(T("staffcast scintilla at <T>"))
  end)

  it("P4's stormhammer is a fire-mode pick at the same health", function()
    world({ mode = "fire", hp = 20, reso = { water = 2 } })
    expect(round()).toBe(T("cast stormhammer at <T>"))
  end)

  it("P6's emanation earth at earth 3 does not jump the finisher's freeze", function()
    local affs6 = { "slickness", "paralysis", "anorexia", "fulminated", "shivering" }
    world({ affs = affs6, reso = { earth = 3, water = 1, air = 2 } })
    expect(round()).toBe(T("cast freeze at <T>"))
    world({ mode = "fire", affs = affs6, reso = { earth = 3, water = 1, air = 2 } })
    expect(round()).toBe(T("cast emanation at <T> earth"))
  end)

  it("a shielded target still gets P2's meteorite first", function()
    world({ affs = { "shield" }, reso = { water = 2 } })
    expect(round()).toBe(T("cast meteorite at <T> pure 4"))
  end)

  it("P1 DESTROY still slays a conflagrated target at 35% or less", function()
    world({ conflagrated = true, hp = 30, affs = { "burning" }, scalded = true, reso = { water = 2 } })
    expect(round()).toBe(T("cast destroy at <T>"))
  end)

  it("dispatch's guards still apply: no target, no equilibrium", function()
    world()
    target = ""
    expect(round()).toBeNil()
    world()
    gmcp.Char.Vitals.eq = "0"
    local okR, errR = pcall(round)
    gmcp.Char.Vitals.eq = "1"
    if not okR then error(errR, 0) end
    expect(#sent).toBe(0)
  end)
end)

-- After the bonk the target is slick; its lock afflictions as the bonk leaves them.
local LOCKED = { "slickness", "paralysis", "anorexia", "prone", "fulminated", "scalded" }

describe("ww finisher: emanate water, freeze until frozen", function()
  it("after the bonk, water 3: emanation water", function()
    world({ affs = LOCKED, reso = { earth = 2, fire = 3, water = 3, air = 1 } })
    expect(round()).toBe(T("cast emanation at <T> water"))
  end)

  it("after the bonk, water under 3 and not frozen: freeze (shivering, then frozen)", function()
    world({ affs = LOCKED, reso = { earth = 2, fire = 3, air = 1 } })
    expect(round()).toBe(T("cast freeze at <T>"))
    local shivering = { unpack(LOCKED) }
    shivering[#shivering + 1] = "shivering"
    world({ affs = shivering, reso = { earth = 2, fire = 3, water = 1, air = 2 } })
    expect(round()).toBe(T("cast freeze at <T>"))
  end)

  it("not slick: the opener again, even at the water a freeze would have used", function()
    -- They cured slickness: caloric would take the freezes off, so the route bonks again.
    world({ affs = { "paralysis", "anorexia", "fulminated" }, scalded = true, reso = { earth = 2, water = 1, air = 1 } })
    expect(round()).toBe(T("cast dehydrate at <T>"))
  end)

  it("major water before any bonk is spent too, and the opener rebuilds it to 2", function()
    world({ scalded = true, reso = { water = 3, air = 1, earth = 1 } })
    expect(round()).toBe(T("cast emanation at <T> water"))
  end)
end)

describe("ww kill: glaciate a frozen target, hypothermia first only out of range", function()
  local FROZEN = { "slickness", "paralysis", "anorexia", "fulminated", "frozen", "shivering", "nocaloric" }

  it("frozen, health 30%, glaciateKillAt 100: glaciate", function()
    world({ affs = FROZEN, hp = 30, reso = { air = 3, water = 2 } })
    expect(round()).toBe(T("cast glaciate at <T>"))
  end)

  it("frozen, health 80%, glaciateKillAt 50, no hypothermia: hypothermia, then glaciate", function()
    world({ affs = FROZEN, hp = 80, reso = { air = 3, water = 2 } })
    magi.offense.config.glaciateKillAt = 50
    expect(round()).toBe(T("cast hypothermia at <T>"))
    local withHypo = { unpack(FROZEN) }
    withHypo[#withHypo + 1] = "hypothermia"
    world({ affs = withHypo, hp = 80, reso = { air = 3, water = 3 } })
    magi.offense.config.glaciateKillAt = 50
    expect(round()).toBe(T("cast glaciate at <T>"))
  end)

  it("at or under the line is glaciate: 50% with glaciateKillAt 50", function()
    world({ affs = FROZEN, hp = 50, reso = { air = 3, water = 2 } })
    magi.offense.config.glaciateKillAt = 50
    expect(round()).toBe(T("cast glaciate at <T>"))
  end)

  it("glaciateKillAt false (mm glaciate off): hypothermia first, whatever the health", function()
    for _, hp in ipairs({ 10, 100 }) do
      world({ affs = FROZEN, hp = hp, reso = { air = 3, water = 2 } })
      magi.offense.config.glaciateKillAt = false
      expect(round()).toBe(T("cast hypothermia at <T>"))
    end
    world({ affs = FROZEN, reso = { air = 3, water = 2 } })   -- unknown health too
    magi.offense.config.glaciateKillAt = false
    expect(round()).toBe(T("cast hypothermia at <T>"))
  end)

  it("unknown health is glaciate, the usual finisher: no reading, or a reading of someone else", function()
    world({ affs = FROZEN, reso = { air = 3, water = 2 } })
    magi.offense.config.glaciateKillAt = 50
    expect(round()).toBe(T("cast glaciate at <T>"))
    world({ affs = FROZEN, hp = 90, assessed = "Someoneelse", reso = { air = 3, water = 2 } })
    magi.offense.config.glaciateKillAt = 50
    expect(round()).toBe(T("cast glaciate at <T>"))
    world({ affs = FROZEN, hp = 90, assessed = "xarthus", reso = { air = 3, water = 2 } })   -- any case
    magi.offense.config.glaciateKillAt = 50
    expect(round()).toBe(T("cast hypothermia at <T>"))
  end)

  it("needs only frozen: no hypothermia, water and air under 2 (P3's gates do not apply)", function()
    world({ affs = { "frozen" }, hp = 60 })
    expect(round()).toBe(T("cast glaciate at <T>"))
    -- In fire mode the same frozen target gets no glaciate (P3 wants hypothermia and water/air 2+).
    world({ mode = "fire", affs = { "frozen" }, hp = 60, scalded = true })
    expect(round() ~= T("cast glaciate at <T>")).toBeTrue()
  end)

  it("P7's hypothermia-first does not pre-empt a glaciate in range", function()
    world({ affs = FROZEN, hp = 30, reso = { air = 2, water = 2 } })
    expect(round()).toBe(T("cast glaciate at <T>"))
    world({ mode = "fire", affs = FROZEN, hp = 30, reso = { air = 2, water = 2 } })
    expect(round()).toBe(T("cast hypothermia at <T>"))
  end)

  it("frozen at water 3 is the kill (or the hypothermia that holds frozen), not the emanation", function()
    local withHypo = { unpack(FROZEN) }
    withHypo[#withHypo + 1] = "hypothermia"
    world({ affs = withHypo, hp = 80, reso = { air = 3, water = 3 } })
    magi.offense.config.glaciateKillAt = 50
    expect(round()).toBe(T("cast glaciate at <T>"))
    world({ affs = FROZEN, hp = 80, reso = { air = 3, water = 3 } })
    magi.offense.config.glaciateKillAt = 50
    expect(round()).toBe(T("cast hypothermia at <T>"))
  end)
end)

describe("focusLocked: the JOINT probability of paralysis, slickness and anorexia", function()
  it("all three in one certain branch: locked", function()
    world({ affs = { "paralysis", "slickness", "anorexia" } })
    expect(magi.offense.focusLockProb()).toBe(1)
    expect(magi.offense.focusLocked()).toBeTrue()
  end)

  it("each at 50% or more, never together: NOT locked (per-affliction tests would say it is)", function()
    world({ branches = { { 0.5, "paralysis", "slickness" }, { 0.5, "slickness", "anorexia" } } })
    for _, a in ipairs({ "paralysis", "slickness", "anorexia" }) do
      expect(getAffProbabilityV3(a) >= 0.5).toBeTrue()
    end
    expect(magi.offense.focusLockProb()).toBe(0)
    expect(magi.offense.focusLocked()).toBeFalse()
  end)

  it("together in half the branches: 50%, locked; in 40%: not", function()
    world({ branches = { { 0.5, "paralysis", "slickness", "anorexia" }, { 0.5, "slickness" } } })
    expect(magi.offense.focusLocked()).toBeTrue()
    world({ branches = { { 0.4, "paralysis", "slickness", "anorexia" }, { 0.6, "slickness", "anorexia" } } })
    expect(magi.offense.focusLocked()).toBeFalse()
  end)

  it("asthma is not part of it", function()
    world({ affs = { "paralysis", "slickness", "anorexia" } })
    expect(getAffProbabilityV3("asthma")).toBe(0)
    expect(magi.offense.focusLocked()).toBeTrue()
  end)
end)

describe("ww keeps fulminated up after the bonk while the lock is not on", function()
  it("slick, not locked, fulminated down: fulminate before the emanation and before a freeze", function()
    world({ affs = { "slickness", "anorexia" }, reso = { earth = 1, fire = 3, water = 3, air = 1 } })
    expect(round()).toBe(T("cast fulminate at <T>"))
    world({ affs = { "slickness", "anorexia" }, reso = { earth = 1, fire = 3, water = 1, air = 1 } })
    expect(round()).toBe(T("cast fulminate at <T>"))
  end)

  it("locked: no re-fulminate, the finisher goes on", function()
    world({ affs = { "slickness", "anorexia", "paralysis" }, reso = { water = 3, air = 1 } })
    expect(round()).toBe(T("cast emanation at <T> water"))
  end)

  it("not locked but fulminated up: the finisher goes on", function()
    world({ affs = { "slickness", "anorexia", "fulminated" }, reso = { water = 1, air = 2 } })
    expect(round()).toBe(T("cast freeze at <T>"))
  end)

  it("fulminated at 40% counts as up, as the fulminate trigger reads it (haveAff, 30%)", function()
    world({ branches = { { 0.4, "slickness", "fulminated" }, { 0.6, "slickness" } }, reso = { water = 1 } })
    expect(round()).toBe(T("cast freeze at <T>"))
  end)

  it("the joint lock decides, not the separate probabilities", function()
    -- Each lock affliction at 50%+, never together: not locked, so fulminated is laid again.
    world({ branches = { { 0.5, "paralysis", "slickness" }, { 0.5, "slickness", "anorexia" } }, reso = { water = 1 } })
    expect(round()).toBe(T("cast fulminate at <T>"))
  end)

  it("never before the kill: a frozen target gets glaciate", function()
    world({ affs = { "slickness", "frozen" }, hp = 30, reso = { water = 2, air = 3 } })
    expect(round()).toBe(T("cast glaciate at <T>"))
  end)

  it("never before the bonk: the opener does not re-fulminate", function()
    world({ scalded = true, reso = { earth = 1, fire = 3, water = 2, air = 1 } })
    expect(round()).toBe(T("cast mudslide at <T>"))
  end)
end)

-- Everything echoed since the last world(), as one string.
local function said() return table.concat(echoes, "\n") end
local function count(s, what)
  local n, i = 0, 1
  while true do
    local a, b = s:find(what, i, true)
    if not a then return n end
    n, i = n + 1, b + 1
  end
end
local function ascii(s) return not s:find("[\128-\255]") end

describe("ww echoes its step each round", function()
  it("opener, bonk and finisher, with the spell and why", function()
    world()
    round()
    expect(said()).toContain("Route opener: <white>magma")
    world({ scalded = true, reso = { earth = 1, water = 2, air = 1 } })
    round()
    expect(said()).toContain("Route bonk: <white>mudslide")
    world({ affs = LOCKED, reso = { water = 3, air = 1 } })
    round()
    expect(said()).toContain("Route finisher: <white>emanation water")
    expect(said()).toContain("LOCKED")
    expect(ascii(said())).toBeTrue()
  end)

  it("earth not 1 at the bonk: still the mudslide, and said ONCE that it brings no paralysis", function()
    world({ scalded = true, reso = { earth = 0, fire = 3, water = 2, air = 1 } })
    expect(round()).toBe(T("cast mudslide at <T>"))
    round()                                   -- a second press before the bonk goes off
    expect(count(said(), "Bonk at earth 0: no paralysis")).toBe(1)
    expect(ascii(said())).toBeTrue()
  end)

  it("at earth 1 nothing is said; the note clears once the route moves on, so the next bonk says it again", function()
    world({ scalded = true, reso = { earth = 1, fire = 3, water = 2, air = 1 } })
    round()
    expect(said():find("Bonk at earth", 1, true)).toBeNil()
    world({ scalded = true, reso = { earth = 2, fire = 3, water = 2, air = 1 } })
    round()
    reso({ earth = 2, fire = 3, water = 1, air = 1 })   -- water fades: a dehydrate, not the bonk
    round()
    reso({ earth = 2, fire = 3, water = 2, air = 1 })
    round()
    expect(count(said(), "Bonk at earth 2: no paralysis")).toBe(2)
  end)
end)

describe("mm status in waterroute mode: the step, the lock and glaciateKillAt", function()
  local function statusText()
    echoes = {}
    magi.offense.status()
    return said()
  end

  it("shows the step the next round would take, the joint lock beside asthma and fulminated", function()
    world({ scalded = true, affs = { "asthma" }, reso = { earth = 1, water = 2, air = 1 } })
    local s = statusText()
    expect(s).toContain("Route step: <white>bonk <dim_grey>-- mudslide")
    expect(s).toContain("Focus lock: <dim_grey>no")
    expect(s).toContain("together 0%; asthma 100%, fulminated 0%")
    expect(s).toContain("Glaciate first: <white>at 100% health or less, or unknown health")
    expect(ascii(s)).toBeTrue()
    expect(#sent).toBe(0)                      -- a status sends nothing
  end)

  it("locked, glaciate off, no target", function()
    world({ affs = LOCKED, reso = { water = 1 } })
    magi.offense.config.glaciateKillAt = false
    local s = statusText()
    expect(s).toContain("Route step: <white>finisher <dim_grey>-- freeze")
    expect(s).toContain("Focus lock: <green>YES")
    expect(s).toContain("Glaciate first: <dim_grey>off (hypothermia first)")
    target = ""
    expect(statusText()).toContain("Route step: <dim_grey>no target")
  end)

  it("other modes print no route lines", function()
    world({ mode = "water" })
    local s = statusText()
    expect(s:find("Route step", 1, true)).toBeNil()
    expect(s:find("Glaciate first", 1, true)).toBeNil()
  end)
end)

-- The alias bodies, compiled once (inside the protected block, so a missing file is a failure
-- reported here rather than a load error that skips the restore).
local WW = aliasBody("magi_things/007_Water_Route.lua")
local MM = aliasBody("magi_things/006_Magi_Mode.lua")
local VV = aliasBody("153_Fourth_Attack_(All_Classes).lua")
local HELP = aliasBody("magi_things/001_Magi_Help.lua")
local function mm(args)
  matches = { ("mm " .. args):gsub("%s+$", ""), args }
  MM()
end
local function press(body)
  sent = {}
  body()
  local cmd = sent[#sent]
  return cmd and cmd:match("shield::(.-)::assess") or cmd
end

describe("ww: sets waterroute and dispatches; a Magi only", function()
  it("one press: the mode, and the route's cast", function()
    world({ mode = "fire", scalded = true, reso = { water = 2, fire = 3, earth = 1 } })
    expect(press(WW)).toBe(T("cast fulminate at <T>"))
    expect(magi.offense.state.mode).toBe("waterroute")
  end)

  it("not a Magi: nothing sent, the mode untouched", function()
    world({ mode = "fire" })
    gmcp.Char.Status.class = "Serpent"
    local okP, errP = pcall(press, WW)
    gmcp.Char.Status.class = "Magi"
    if not okP then error(errP, 0) end
    expect(#sent).toBe(0)
    expect(magi.offense.state.mode).toBe("fire")
  end)
end)

describe("vv is unchanged: water mode, the fire tree", function()
  -- Pinned from the code before v4.7.421 (the same states run through the same vv body): water 2,
  -- fire 3, earth 1, air 0 on a scalded target was a bombard, and still is, while ww fulminates.
  local A = "queue addclearfull freestand stand::wield staff569815 shield::cast bombard at Xarthus::assess Xarthus"

  it("the pinned round, before and after a ww press", function()
    world({ mode = "fire", scalded = true, reso = { water = 2, fire = 3, earth = 1 } })
    sent = {}
    VV()
    expect(sent[#sent]).toBe(A)
    expect(magi.offense.state.mode).toBe("water")
    expect(press(WW)).toBe(T("cast fulminate at <T>"))
    sent = {}
    VV()
    expect(sent[#sent]).toBe(A)
    expect(magi.offense.state.mode).toBe("water")
  end)

  it("the other pinned rounds: P8's mudslide, P3's glaciate, magma", function()
    world({ scalded = true, affs = { "asthma" }, reso = { water = 2, air = 1, earth = 1, fire = 3 } })
    expect(press(VV)).toBe(T("cast mudslide at <T>"))
    world({ scalded = true, affs = { "frozen", "hypothermia" }, reso = { water = 2, air = 2 } })
    expect(press(VV)).toBe(T("cast glaciate at <T>"))
    world()
    expect(press(VV)).toBe(T("cast magma at <T>"))
  end)
end)

describe("mm: waterroute, route, and glaciate N|off", function()
  it("mm waterroute and mm route set the mode and send nothing", function()
    for _, word in ipairs({ "waterroute", "route", "WaterRoute" }) do
      world({ mode = "fire" })
      mm(word)
      expect(magi.offense.state.mode).toBe("waterroute")
      expect(#sent).toBe(0)
    end
  end)

  it("mm glaciate 50 / off / bare / out of range", function()
    world()
    mm("glaciate 50")
    expect(magi.offense.config.glaciateKillAt).toBe(50)
    mm("glaciate")
    expect(said()).toContain("at 50% health or less")
    mm("glaciate off")
    expect(magi.offense.config.glaciateKillAt).toBeFalse()
    mm("glaciate 150")
    expect(magi.offense.config.glaciateKillAt).toBeFalse()
    expect(said()).toContain("Usage: mm glaciate N")
    mm("glaciate 0")
    expect(magi.offense.config.glaciateKillAt).toBe(0)
    mm("glaciate 100")
    expect(magi.offense.config.glaciateKillAt).toBe(100)
    expect(ascii(said())).toBeTrue()
  end)

  it("'mm glaciate off' makes the route lay hypothermia first", function()
    local frozen = { "slickness", "frozen", "fulminated" }
    world({ affs = frozen, hp = 10, reso = { water = 2, air = 3 } })
    expect(press(WW)).toBe(T("cast glaciate at <T>"))
    mm("glaciate off")
    expect(press(WW)).toBe(T("cast hypothermia at <T>"))
  end)

  it("bare mm in waterroute mode is the status with the route lines; the help lists the new words", function()
    world({ scalded = true, reso = { water = 2, earth = 1, air = 1 } })
    mm("")
    expect(said()).toContain("Route step: <white>bonk")
    echoes = {}
    mm("nonsense")
    expect(said()).toContain("waterroute")
    expect(said()).toContain("mm glaciate N|off")
    expect(ascii(said())).toBeTrue()
  end)

  it("magi help lists ww and the new mm commands", function()
    echoes = {}
    HELP()
    local s = said()
    expect(s).toContain("WW")
    expect(s).toContain("MM WATERROUTE")
    expect(s).toContain("MM GLACIATE")
    expect(ascii(s)).toBeTrue()
  end)
end)

describe("targetHPKnown: a reading of THIS target", function()
  it("698's stamp names our target, in any case", function()
    world({ hp = 60 })
    ataxiaTemp.lastAssessWho = "XARTHUS"
    expect(magi.offense.targetHPKnown()).toBeTrue()
    ataxiaTemp.lastAssessWho = "Someoneelse"
    expect(magi.offense.targetHPKnown()).toBeFalse()
    ataxiaTemp.lastAssessWho = nil
    expect(magi.offense.targetHPKnown()).toBeFalse()
  end)

  it("a stamp with no figure, or older than 30 s, is no reading", function()
    world({ hp = 60 })
    expect(magi.offense.routeTargetHP()).toBe(60)
    ataxiaTemp.lastAssessAt = getEpoch() - 31
    expect(magi.offense.targetHPKnown()).toBeFalse()
    expect(magi.offense.routeTargetHP()).toBeNil()
    world({ hp = 60 })
    ataxiaTemp.lastAssess = nil
    expect(magi.offense.targetHPKnown()).toBeFalse()
  end)

  it("targetHealth from a bystander's assess is never read as our target's health", function()
    world({ affs = { "slickness", "frozen", "fulminated" }, reso = { water = 2, air = 3 } })
    targetHealth = 90   -- general/001 wrote someone else's glance; 698 stamped nothing
    magi.offense.config.glaciateKillAt = 50
    expect(round()).toBe(T("cast glaciate at <T>"))
  end)
end)

end)

-- Restore the shared Lua state.
for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
table.contains = savedContains
if not ok then error(err) end
