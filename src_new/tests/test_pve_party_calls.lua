--- test_pve_party_calls.lua -- no target / battlerage / block calls to party chat in PvE (v4.7.516)
--
-- ataxia_partyCallAllowed (ataxia/016) is the one rule. PvE = the target is a denizen id (a number)
-- or the basher runs; then a call goes out only with ataxia.settings.pvePartyCalls == true.
-- Real files: the helper in 016, trigger 332 (battlerage), trigger 805 (block call).

require("mock_mudlet")
local TL = dofile("src_new/tests/trigger_lib.lua")

local before = {}
for k, v in pairs(_G) do before[k] = v end

local ok0, err0 = pcall(dofile, "src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua")
if not ok0 then error("Failed to load 016: " .. tostring(err0)) end

local function body(path)
  local fh = assert(io.open(path, "r"))
  local src = fh:read("*a"); fh:close()
  return assert((loadstring or load)(src:match("%]%]%-%-\r?\n(.*)$")))
end
local T = "src_new/triggers/levi_ataxia/for_levi/leviticus/"
local BR_BODY = body(T .. "332_Battlerage_Special.lua")
local BLOCK = T .. "805_Block_Exit_Call.lua"
local BLOCK_BODY = body(BLOCK)
local DIED = T .. "401_Target_Has_Died.lua"
local DIED_BODY = body(DIED)

local sent = {}
send = function(s) sent[#sent + 1] = s end
tempTimer = function() return 1 end
ataxiaBasher_brCd = function(n) return n end
ataxiaBasher_brFired = nil
bashStats = { attacks = 0 }
battleRage_Timers = {}
ataxiaEcho = function() end
raiseEvent = raiseEvent or function() end

local function reset(tgt, basher, switch)
  sent = {}
  target = tgt
  partyrelay = true
  ataxia = { settings = { pvePartyCalls = switch }, afflictions = {}, vitals = {} }
  ataxiaTemp = {}
  ataxiaBasher = { enabled = basher or false }
  gmcp = { Char = { Status = { class = "Apostate" } } }
end

local function battlerage()
  line = "You hurl a precise blast"
  matches = { line, "x" }
  BR_BODY()
end

local function block(text)
  local pats = TL.patterns(BLOCK)
  local hit = false
  for _, p in ipairs(pats) do if TL.matches(p.pat, p.type, text) then hit = true end end
  if not hit then error("no pattern matches: " .. text) end
  matches = { text, text:match("^You move over to block the (%w+) exit%.$") }
  BLOCK_BODY()
end

local okRun, err = pcall(function()
  describe("PvE party calls", function()
    it("a denizen id target: battlerage call is not sent", function()
      reset(78823); battlerage()
      expect(#sent).toBe(0)
    end)

    it("a denizen id target with the switch on: sent", function()
      reset(78823, false, true); battlerage()
      expect(sent[1]).toBe("pt Battlerage - Charmed given to 78823")
    end)

    it("a player name target (PvP): sent as before", function()
      reset("Saibel"); battlerage()
      expect(sent[1]).toBe("pt Battlerage - Charmed given to Saibel")
    end)

    it("a player name but the basher runs: PvE, not sent", function()
      reset("Saibel", true); battlerage()
      expect(#sent).toBe(0)
    end)

    it("the helper names its reason; the switch set to false is off", function()
      reset(621879)
      local a, why = ataxia_partyCallAllowed(621879)
      expect(a).toBe(false)
      expect(why:match("pvecalls") ~= nil).toBe(true)
      reset(621879, false, false)
      expect(ataxia_partyCallAllowed("621879")).toBe(false)
    end)

    it("016 switchTarget: a denizen id is not called, a player is, the switch turns it on", function()
      local function sw(who, sw_)
        reset("old", false, sw_)
        target_calling = true; pariah = nil; ataxiaTemp.class = "serpent"
        ataxia.settings.separator = ";"
        ataxia.playersHere = {}
        matches = { "t " .. who, who }
        -- The PvP reset code touches many tracker globals; stub each one the error names.
        for _ = 1, 60 do
          local ok, e = pcall(switchTarget, who)
          if ok then return end
          local fn = tostring(e):match("call global '([%w_]+)'")
          local tb = tostring(e):match("index global '([%w_]+)'")
          if fn then _G[fn] = function() end
          elseif tb then _G[tb] = {}
          else error(e) end
        end
      end
      local function called()
        for _, s in ipairs(sent) do if s:match("^pt Target: ") then return s end end
      end
      sw("78823"); expect(called()).toBe(nil)
      sw("78823", true); expect(called()).toBe("pt Target: 78823")
      sw("Saibel"); expect(called()).toBe("pt Target: Saibel")
    end)

    it("401: our kill of an adventurer calls Slain <Name>; another's kill and a mob do not", function()
      local function died(text, cap)
        reset(78823)  -- a number: the R.I.P. block (our target only) is skipped
        ataxia.defences = {}
        ataxia_paused = function() return false end
        ataxia_isClass = function() return false end
        local hit = false
        for _, p in ipairs(TL.patterns(DIED)) do if TL.matches(p.pat, p.type, text) then hit = true end end
        matches = { text, cap }
        if hit then DIED_BODY() end
        return hit
      end
      expect(died("You have slain Tabethys.", "Tabethys")).toBe(true)
      expect(sent[1]).toBe("pt Slain Tabethys")
      expect(died("Tabethys has been slain by Dunn.", "Tabethys")).toBe(true)
      expect(#sent).toBe(0)
      expect(died("You have slain a rat, retrieving the corpse.", "a rat")).toBe(false)
      expect(#sent).toBe(0)
    end)

    it("block call: Blocking Northeast, in PvP and with no basher", function()
      reset("Saibel"); block("You move over to block the northeast exit.")
      expect(sent[1]).toBe("pt Blocking Northeast")
      reset(nil); block("You move over to block the up exit.")
      expect(sent[1]).toBe("pt Blocking Up")
    end)

    it("block call while the basher runs: off by default, sent with the switch", function()
      reset(78823, true); block("You move over to block the northeast exit.")
      expect(#sent).toBe(0)
      reset(78823, true, true); block("You move over to block the northeast exit.")
      expect(sent[1]).toBe("pt Blocking Northeast")
    end)
    -- v4.7.517: every automatic call follows the same rule. Each case runs the real trigger body.
    local function ptSent()
      local out = {}
      for _, s in ipairs(sent) do if s:match("^pt ") then out[#out + 1] = s end end
      return out
    end
    tarAffed = function() end
    ataxiaNDB = { players = { Saibel = { city = "Mhaldor" }, ["78823"] = { city = "Mhaldor" } } }

    local CASES = {
      { name = "197 parry call", file = "197_Morningstar_Parry_Left_Leg.lua",
        m = function(t) return { "x", t } end, say = "pt %s: PARRYING left leg" },
      { name = "230 smash low call", file = "230_Smash_low.lua",
        m = function(t) return { "x", t, t } end, say = "pt %s: clumsiness" },
      { name = "277 flying call", file = "277_Fly.lua",
        m = function(t) return { "x", t } end, say = "pt %s: Flying!" },
    }
    for _, c in ipairs(CASES) do
      local fn = body(T .. c.file)
      local function run(tgt, basher, switch)
        reset(tgt, basher, switch)
        matches = c.m(tgt)
        fn()
        return ptSent()
      end
      it(c.name .. ": a denizen id is silent, a player is called, the switch turns it on", function()
        expect(#run("78823")).toBe(0)
        expect(#run("Saibel", true)).toBe(0)
        expect(run("Saibel")[1]).toBe(c.say:format("Saibel"))
        expect(run("78823", false, true)[1]).toBe(c.say:format("78823"))
      end)
    end

    it("128 party enter: names no target, so only the basher silences it", function()
      local fn = body(T .. "128_PARTY_ENTER.lua")
      reset("Saibel", true); matches = { "x", "Bob" }; fn()
      expect(#ptSent()).toBe(0)
      reset("Saibel", true, true); matches = { "x", "Bob" }; fn()
      expect(ptSent()[1]).toBe("pt Bob has ENTERED my area !!!")
      reset(78823); matches = { "x", "Bob" }; fn()
      expect(ptSent()[1]).toBe("pt Bob has ENTERED my area !!!")
    end)
  end)
end)

for k in pairs(_G) do
  if before[k] == nil then _G[k] = nil end
end
for k, v in pairs(before) do _G[k] = v end
if not okRun then error(err) end
