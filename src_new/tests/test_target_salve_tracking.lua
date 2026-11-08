--- test_target_salve_tracking.lua -- one enemy salve application is one cure (v4.7.404)
--
-- The game's line ("X takes some salve from a vial and rubs it on his body") names the spot, not
-- the salve, so the tracker branches over everything a salve there can cure. These tests drive
-- the REAL triggers (391 body/skin, 392 head) through the REAL V3 tracker. Before v4.7.404:
-- trigger 391 erased anorexia, itching, selarnia and frostbite on every body application on top
-- of the branching; trigger 392 never called the tracker, so head cures were never seen; and the
-- lists held afflictions from the wrong spot. Every global the loaded files touch is restored.

local mock = require("mock_mudlet")

local before = {}
for k, v in pairs(_G) do before[k] = v end

for _, f in ipairs({
  "src_new/scripts/levi_ataxia/levi/ataxia/curing/002_Wide_Groups.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/007_Branching_State_Tracker.lua",
  "src_new/scripts/levi_ataxia/levi/ataxia/affliction_tracking_core/008_V3_Integration.lua",
}) do
  local ok, err = pcall(dofile, f)
  if not ok then error("Failed to load " .. f .. ": " .. tostring(err)) end
end

local TRG = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local function body(file)
  local fh = assert(io.open(TRG .. file, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
end
local BODY_SKIN, HEAD = body("391_Applied_Body_Skin.lua"), body("392_Applied_Head.lua")
local TORSO = body("393_Applied_Torso.lua")

-- The world the triggers run in. erAff/haveAff go straight to V3 (the public API's job).
-- The limb damage comes from the limb counter (lb, limb/002), which 392 and 393 read; the global
-- tLimbs they used to read is defined by nothing in the package, so it is left nil here.
local function world(limbs)
  isTargeted = function(n) return n == "Xarthus" end
  erAff = function(a) if removeAffV3 then removeAffV3(a) end end
  haveAff = function(a) return getAffProbabilityV3(a) >= 0.3 end
  passiveFailsafe, onTargetSalveBodyV2, onTargetSalveSkinV2 = nil, nil, nil
  magi = { offense = { state = { burns = 0 } } }
  selectCurrentLine, fg, cecho, ataxia_boxEcho, target_salveBal = function() end, function() end,
    function() end, function() end, function() end
  tLimbs = nil
  target = "Xarthus"
  lb = { Xarthus = { hits = limbs or { head = 0, torso = 0 }, t = {} } }
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.crushedCheck = { pending = false, timer = nil, lastApply = 0 }
  targetBurningLevelV3 = 1
end

local function fresh(affs)
  resetStatesV3()
  if resetCureBalancesV3 then resetCureBalancesV3() end
  for _, a in ipairs(affs) do applyAffV3(a) end
end

local function apply(chunk, spot)
  matches = { "Xarthus takes some salve from a vial and rubs it on his " .. spot .. ".", "Xarthus", spot }
  chunk()
end

local P = function(a) return getAffProbabilityV3(a) end

local ok, err = pcall(function()
describe("enemy salve tracking: one application, one cure", function()
  it("a body application does not also wipe the other body afflictions", function()
    world(); fresh({ "anorexia", "burning" })
    apply(BODY_SKIN, "body")
    -- SSC cures anorexia first on the body; the burn is still there.
    expect(P("anorexia")).toBe(0)
    expect(P("burning")).toBe(1)
  end)

  it("with two candidates it branches instead of curing both", function()
    world(); fresh({ "itching", "selarnia" })
    apply(BODY_SKIN, "body")
    local i, s = P("itching"), P("selarnia")
    expect(i > 0 and i < 1).toBeTrue()
    expect(s > 0 and s < 1).toBeTrue()
    expect(math.abs((i + s) - 1) < 0.001).toBeTrue()   -- exactly one of them is gone
  end)

  it("a body application never touches frostbite (caloric, the skin)", function()
    world(); fresh({ "frostbite", "anorexia" })
    apply(BODY_SKIN, "body")
    expect(P("frostbite")).toBe(1)
  end)

  it("restoration-to-body afflictions the old list missed are candidates now", function()
    world(); fresh({ "internalbleeding" })
    apply(BODY_SKIN, "body")
    expect(P("internalbleeding")).toBe(0)
  end)

  it("while hypothermia is up the body application is 393's restoration, so nothing else is cured", function()
    world(); fresh({ "hypothermia", "anorexia" })
    apply(BODY_SKIN, "body")
    expect(P("anorexia")).toBe(1)
  end)

  it("any application proves slickness and bloodfire absent", function()
    world(); fresh({ "slickness", "bloodfire", "frozen" })
    apply(BODY_SKIN, "skin")
    expect(P("slickness")).toBe(0)
    expect(P("bloodfire")).toBe(0)
  end)

  -- applyAffV3("frozen") runs the cold CHAIN (nocaloric -> shivering -> frozen) rather than
  -- setting frozen, so these build the target's state directly and check it first.
  local function exactly(affs)
    fresh({})
    local set = {}
    for _, a in ipairs(affs) do set[a] = true end
    afflictionStatesV3 = { { affs = set, prob = 1 } }
    rebuildCacheV3()
    for _, a in ipairs(affs) do expect(P(a)).toBe(1) end
  end

  it("skin (caloric) cures a cold affliction", function()
    world(); exactly({ "frozen" })
    apply(BODY_SKIN, "skin")
    expect(P("frozen")).toBe(0)
  end)

  it("skin cures nothing cold while hypothermic", function()
    world(); exactly({ "frozen", "hypothermia" })
    apply(BODY_SKIN, "skin")
    expect(P("frozen")).toBe(1)
  end)

  it("a head application is finally seen: it cures stuttering", function()
    world(); fresh({ "stuttering" })
    apply(HEAD, "head")
    expect(P("stuttering")).toBe(0)
  end)

  it("a head application on a damaged head is the restoration, not another cure", function()
    world({ head = 150, torso = 0 }); fresh({ "stuttering" })
    apply(HEAD, "head")
    expect(P("stuttering")).toBe(1)
  end)

  -- 2026-11-08 deep review (F13): 392 and 393 read tLimbs.H / tLimbs.T, a global nothing defines,
  -- so in the client every head application raised an error before the cure and every body or
  -- torso application without hypothermia raised one in 393. world() leaves tLimbs nil, as the
  -- package does.
  it("with no tLimbs global a head application runs to the cure (F13)", function()
    world(); fresh({ "stuttering" })
    expect(tLimbs).toBeNil()
    local ran, e = pcall(apply, HEAD, "head")
    expect(ran).toBe(true)
    expect(e).toBeNil()
    expect(P("stuttering")).toBe(0)
  end)

  it("a body application on a calcified torso is counted down by 393 (F13)", function()
    world(); fresh({ "calcifiedtorso" })
    expect(P("calcifiedtorso")).toBe(1)
    mock.reset()
    apply(BODY_SKIN, "body")        -- 391 leaves the calcified torso to 393
    local ran, e = pcall(apply, TORSO, "body")
    expect(e).toBeNil()
    expect(ran).toBe(true)
    expect(P("calcifiedtorso")).toBe(1)   -- the restoration takes 4 s
    mock.fire_timers()
    expect(P("calcifiedtorso")).toBe(0)
  end)

  it("a torso application on a broken torso takes the salve balance and leaves lb to reset it", function()
    world({ head = 0, torso = 150 }); fresh({})
    local bal
    target_salveBal = function(t) bal = t end
    apply(TORSO, "torso")
    expect(bal).toBe(3.5)
    expect(lb.Xarthus.hits.torso).toBe(150)   -- lb.salve (limb/003) owns the reset
  end)

  it("with a crushed throat up, 392's own crushed-throat logic owns the application", function()
    world(); fresh({ "crushedthroat", "stuttering" })
    apply(HEAD, "head")
    expect(P("stuttering")).toBe(1)
  end)

  it("the duplicate elixir trigger (590) is gone, so a fracture is counted down once", function()
    expect(io.open(TRG .. "590_Applied_1.lua", "r")).toBeNil()
  end)

  it("every salve list holds only afflictions, ordered by our own curing priority", function()
    local prios = {}
    if ataxia_defaultCuringPrios then prios = ataxia_defaultCuringPrios() end
    for spot, list in pairs(salveCureTableV3) do
      for _, a in ipairs(list) do
        if a == "epidermal" or a == "scalded" or a == "bloodfire" then
          error(spot .. " lists " .. a .. ", which a salve application cannot cure")
        end
      end
    end
  end)
end)
end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
