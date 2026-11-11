--- test_magi_relay_class.lua -- only a Magi calls or echoes a resonance (2026-11-11)
--
-- As a Serpent in a group fight we sent "pt Akri: Resonance Air (asthma)." for lines that any class
-- can cause (the asthma gasp, "A loud crack emanates ..."). magi.offense.ptRelay and resoEcho now
-- do nothing unless gmcp.Char.Status.class is Magi. Loads the REAL 001 and 004.
-- One shared Lua state: every global is restored at the end.

local before = {}
for k, v in pairs(_G) do before[k] = v end

local MAGE = "src_new/scripts/levi_ataxia/levi/levi_scripts/mage/"

magi = nil
ataxia = { afflictions = {}, settings = {} }
ataxiaTemp, tAffs = {}, {}
target = "Akri"
partyrelay = true
gmcp = { Char = { Vitals = { charstats = {} }, Status = { class = "Serpent" } } }

local loadErr
for _, f in ipairs({ MAGE .. "001_Resonance.lua", MAGE .. "004_Magi_Offense.lua" }) do
  local ok, err = pcall(dofile, f)
  if not ok then loadErr = "Failed to load " .. f .. ": " .. tostring(err); break end
end

local sent, echoed = {}, {}
local savedSend, savedCecho = send, cecho
send = function(s) sent[#sent + 1] = s end
cecho = function(s) echoed[#echoed + 1] = s end

local ok, err = pcall(function()
  describe("magi relay: class gate", function()
    it("loads", function()
      if loadErr then error(loadErr) end
    end)

    it("a Serpent sends no resonance call and no resonance echo", function()
      sent, echoed = {}, {}
      gmcp.Char.Status.class = "Serpent"
      magi.offense.state.partyrelay = true
      magi.offense.ptRelay("Akri: Resonance Air (asthma)")
      magi.offense.resoEcho("Air", "Asthma", "Akri")
      expect(#sent).toBe(0)
      expect(#echoed).toBe(0)
    end)

    it("a Magi still calls it", function()
      sent, echoed = {}, {}
      gmcp.Char.Status.class = "Magi"
      magi.offense.state.partyrelay = true
      magi.offense.ptRelay("Akri: Resonance Air (asthma)")
      expect(sent[1]).toBe("pt Akri: Resonance Air (asthma)")
    end)

    it("no class read: no call", function()
      sent = {}
      gmcp.Char.Status = nil
      magi.offense.ptRelay("Akri: Resonance Air (asthma)")
      expect(#sent).toBe(0)
    end)
  end)
end)

send, cecho = savedSend, savedCecho
for k in pairs(_G) do if before[k] == nil then _G[k] = nil end end
for k, v in pairs(before) do _G[k] = v end
if not ok then error(err) end
