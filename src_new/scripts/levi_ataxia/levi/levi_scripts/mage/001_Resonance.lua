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

magi = magi or {}

magi.staff = magi.staff or "staff569815"
magi.keep_firestorm = (magi.keep_firestorm == nil) and true or magi.keep_firestorm
magi.immolation_windup = magi.immolation_windup or false
magi.calcifying_head = magi.calcifying_head or false
magi.calcify_resto = magi.calcify_resto or false
magi.firestorm = magi.firestorm or false
magi.convergence = magi.convergence or false
magi.auto_focus = magi.auto_focus or false
magi.resonance = magi.resonance or {
    ["earth"] = 0,
    ["water"] = 0,
    ["air"] = 0,
    ["fire"] = 0
}
-- Resonance per plane, 0-3, from the charstats the game sends with every prompt: an entry
-- naming r<plane> ("rair", "rfire", "rearth", "rwater"), with the level after its colon.
--
-- THE KEY FORMAT IS UNCONFIRMED: no charstats capture with resonance up exists in kb/ or the
-- tests. Every other charstats key we read is capitalised ("Stance: ...", "Kai: N%"), and this
-- match was case-sensitive, so a key sent as "Rair" left every plane at 0. It is matched on the
-- lowercased entry now. Every plane is also zeroed first: a plane whose entry is absent used to
-- keep its last level for good, and now reads 0 (harmless if the game always sends all four).
-- Capture one gmcp.Char.Vitals.charstats with resonance up into kb/raw/live to settle both.
local RESONANCE_PLANES = { "air", "fire", "earth", "water" }
local RESONANCE_LEVELS = { minor = 1, moderate = 2, major = 3 }

function get_resonance()
  local r = magi.resonance
  for _, plane in ipairs(RESONANCE_PLANES) do r[plane] = 0 end
  local stats = gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.charstats
  if type(stats) ~= "table" then return end
  for _, v in pairs(stats) do
    local entry = tostring(v):lower()
    for _, plane in ipairs(RESONANCE_PLANES) do
      if entry:find("r" .. plane, 1, true) then
        local level = (entry:match("^[^:]*:([^:]*)") or ""):trim()
        r[plane] = RESONANCE_LEVELS[level] or 0
      end
    end
  end
end

if magi._resonanceHandler then killAnonymousEventHandler(magi._resonanceHandler) end
magi._resonanceHandler = registerAnonymousEventHandler("gmcp.Char.Vitals", "get_resonance")