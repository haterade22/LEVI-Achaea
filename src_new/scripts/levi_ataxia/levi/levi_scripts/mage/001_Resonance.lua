--[[mudlet
type: script
name: Resonance
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

magi = {

staff = "staff569815",
keep_firestorm = true,
immolation_windup = false,
calcifying_head = false,
calcify_resto = false,
firestorm = false,
convergence = false,
auto_focus = false,
    resonance = {
        ["earth"] = 0,
        ["water"] = 0,
        ["air"] = 0,
        ["fire"] = 0
    }
}
function get_resonance()
  for k, v in pairs(gmcp.Char.Vitals.charstats) do
    if string.match(v, "rair") then
      if v:split(":")[2]:trim():lower() == "major" then
        magi.resonance.air = 3
      elseif v:split(":")[2]:trim():lower() == "moderate" then
        magi.resonance.air = 2
      elseif v:split(":")[2]:trim():lower() == "minor" then
        magi.resonance.air = 1
      else
        magi.resonance.air = 0
      end
    end
    if string.match(v, "rfire") then
      if v:split(":")[2]:trim():lower() == "major" then
        magi.resonance.fire = 3
      elseif v:split(":")[2]:trim():lower() == "moderate" then
        magi.resonance.fire = 2
      elseif v:split(":")[2]:trim():lower() == "minor" then
        magi.resonance.fire = 1
      else
        magi.resonance.fire = 0
      end
    end
    if string.match(v, "rearth") then
      if v:split(":")[2]:trim():lower() == "major" then
        magi.resonance.earth = 3
      elseif v:split(":")[2]:trim():lower() == "moderate" then
        magi.resonance.earth = 2
      elseif v:split(":")[2]:trim():lower() == "minor" then
        magi.resonance.earth = 1
      else
        magi.resonance.earth = 0
      end
    end
    if string.match(v, "rwater") then
      if v:split(":")[2]:trim():lower() == "major" then
        magi.resonance.water = 3
      elseif v:split(":")[2]:trim():lower() == "moderate" then
        magi.resonance.water = 2
      elseif v:split(":")[2]:trim():lower() == "minor" then
        magi.resonance.water = 1
      else
        magi.resonance.water = 0
      end
    end
  end
end

registerAnonymousEventHandler("gmcp.Char.Vitals", "get_resonance")