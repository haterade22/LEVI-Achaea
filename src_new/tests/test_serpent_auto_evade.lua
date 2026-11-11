--- test_serpent_auto_evade.lua -- the Serpent evades when 2 players hit us within 3 s (2026-11-11)
--
-- The user's rules: 2 attackers within 3 seconds; out the way we came, else a random exit; only with
-- balance and not paralysed, webbed or entangled. Loads the REAL serpent/003 and feeds it through
-- the REAL classDetect.noteHit path (class_detect/001), as the class-grab triggers do.
-- One shared Lua state: every global is restored at the end.

local before = {}
for k, v in pairs(_G) do before[k] = v end

local mock = require("mock_mudlet")

local clock, sent = 1000, {}
getEpoch = function() return clock end
send = function(s) sent[#sent + 1] = s end
cecho = function() end

serpent = nil
ataxia = { afflictions = {}, settings = {} }
ataxiaTemp = {}
ataxiaBasher = { enabled = false }

local function room(num, exits)
  gmcp.Room = { Info = { num = num, exits = exits } }
  raiseEvent("gmcp.Room.Info")
end

local function reset()
  gmcp = { Char = { Status = { class = "Serpent" }, Vitals = { bal = "1" } } }
  ataxia.afflictions = {}
  ataxiaBasher.enabled = false
  sent = {}
  clock = clock + 100
  if serpent and serpent.evade then
    local E = serpent.evade
    E.hits, E.sentAt, E.cameFrom, E.arrivedByEvade, E.roomNum = {}, nil, nil, false, nil
    serpent.config.autoEvade = true
  end
end

local loadErr
reset()
local okLoad, e1 = pcall(dofile, "src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/003_Auto_Evade.lua")
if not okLoad then loadErr = tostring(e1) end

local function hit(name) line = "A blow from " .. name .. " strikes you."; serpent.evadeOnHit(name) end

local okRun, err = pcall(function()
  describe("serpent auto-evade", function()
    it("loads", function() if loadErr then error(loadErr) end end)

    it("one attacker: no evade", function()
      reset(); room(1, { n = 2, s = 3 }); hit("Akri"); hit("Akri")
      expect(#sent).toBe(0)
    end)

    it("two attackers within 3 s: evade out the way we came", function()
      reset(); room(3, { n = 1 }); room(1, { n = 2, s = 3, e = 4 })
      hit("Akri"); clock = clock + 2; hit("Mizik")
      expect(sent[1]).toBe("evade s")
      expect(#sent).toBe(1)
    end)

    it("two hits more than 3 s apart: no evade", function()
      reset(); room(1, { n = 2 }); hit("Akri"); clock = clock + 4; hit("Mizik")
      expect(#sent).toBe(0)
    end)

    it("no way back: a random exit", function()
      reset(); room(1, { n = 2, e = 4 })
      hit("Akri"); hit("Mizik")
      expect(sent[1] == "evade n" or sent[1] == "evade e").toBe(true)
    end)

    it("arrived by an auto-evade: not back into the fight", function()
      reset(); room(3, { n = 1 }); room(1, { n = 2, s = 3 })
      hit("Akri"); hit("Mizik")
      expect(sent[1]).toBe("evade s")
      clock = clock + 1; room(3, { n = 1, w = 5 })
      sent = {}
      hit("Akri"); hit("Mizik")
      expect(sent[1]).toBe("evade w")
    end)

    it("hits from the room we left do not count", function()
      reset(); room(1, { n = 2 }); hit("Akri")
      room(2, { s = 1 }); hit("Mizik")
      expect(#sent).toBe(0)
    end)

    it("no balance, paralysis, webbed, entangled, basher on, off, another class: no evade", function()
      local cases = {
        function() gmcp.Char.Vitals.bal = "0" end,
        function() ataxia.afflictions.paralysis = true end,
        function() ataxia.afflictions.webbed = true end,
        function() ataxia.afflictions.entangled = true end,
        function() ataxiaBasher.enabled = true end,
        function() serpent.config.autoEvade = false end,
        function() gmcp.Char.Status.class = "Magi" end,
      }
      for _, set in ipairs(cases) do
        reset(); room(1, { n = 2 }); set(); hit("Akri"); hit("Mizik")
        expect(#sent).toBe(0)
      end
    end)

    it("balance back after two hits: the evade goes then", function()
      reset(); room(1, { n = 2 }); gmcp.Char.Vitals.bal = "0"
      hit("Akri"); hit("Mizik")
      expect(#sent).toBe(0)
      gmcp.Char.Vitals.bal = "1"; raiseEvent("gmcp.Char.Vitals")
      expect(sent[1]).toBe("evade n")
    end)

    it("prone: stand first", function()
      reset(); room(1, { n = 2 }); ataxia.afflictions.prone = true
      hit("Akri"); hit("Mizik")
      expect(sent[1]).toBe("stand")
      expect(sent[2]).toBe("evade n")
    end)

    it("one evade, not one per hit", function()
      reset(); room(1, { n = 2 }); hit("Akri"); hit("Mizik"); hit("Vrox")
      expect(#sent).toBe(1)
    end)

    it("classDetect.noteHit feeds it", function()
      reset(); room(1, { n = 2 })
      classDetect = { state = { hits = {} } }
      dofile("src_new/scripts/levi_ataxia/levi/levi_scripts/class_detect/001_Class_Detect_Engine.lua")
      classDetect.state.hits = {}
      line = "Akri stabs you."; classDetect.noteHit("Akri", "serpent")
      line = "Mizik stabs you."; classDetect.noteHit("Mizik", "serpent")
      expect(sent[#sent]).toBe("evade n")
    end)
  end)
end)

for k in pairs(_G) do if before[k] == nil then _G[k] = nil end end
for k, v in pairs(before) do _G[k] = v end
mock.named_handlers["gmcp.Room.Info"] = nil
mock.named_handlers["gmcp.Char.Vitals"] = nil
if not okRun then error(err) end
