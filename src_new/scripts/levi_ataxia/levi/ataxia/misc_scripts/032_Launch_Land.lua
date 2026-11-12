--[[mudlet
type: script
name: Launch Land
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- LAUNCHED INTO THE SKY -> LAND (v4.7.491).
--
-- User: "We need to LAND when this happens." In kb/raw/logs/ours/2026-11-03_102828_Harkon.log
-- (rows 503, 1578, 7302) Dunn launched us three times:
--   A single, piercing note emanates from Dunn, a sound to set teeth on edge and glass to shattering.
--   A violent force suddenly takes hold of you and launches you high into the sky.
-- and each time gmcp said "Flying above <room>" and we stayed up, out of the fight.
--
-- The trigger keys on the SECOND line: it names "you", so it is the proof that WE went up. The note
-- line goes to the whole room.
--
-- LAND goes out directly, not through the server queue: the next round's `queue addclearfull`
-- deletes a queued command (the v4.7.490 last-stand lesson). If the game refuses it (balance,
-- paralysis), a 0.5 s retry sends it again while gmcp still says "Flying above", for up to 6 s.
--
-- Two cases stay in the air on purpose:
--   * the SLC both-arms flee (004_Defensive_Reactions) flies us out to heal the arms;
--   * a Mnemosyne hover or kite (S.flying) is the swarm's own flight.

ataxiaTemp = ataxiaTemp or {}

ataxia_launchLand = ataxia_launchLand or {}
local L = ataxia_launchLand
L.RETRY = 0.5
L.WINDOW = 6

function L.flying()
  local name = gmcp and gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.name
  return type(name) == "string" and name:find("^Flying above") ~= nil
end

function L.stop()
  if ataxiaTemp.launchLandTimer then killTimer(ataxiaTemp.launchLandTimer) end
  ataxiaTemp.launchLandTimer = nil
end

-- Why we must stay up, or nil.
function L.holdReason()
  if selfLimbDamage and selfLimbDamage.bothArmsFlee then return "SLC flee" end
  local S = ataxia and ataxia.mnemosyne and ataxia.mnemosyne.swarm
  if S and S.flying then return "Mnemosyne flight" end
  return nil
end

local function tick(deadline)
  ataxiaTemp.launchLandTimer = nil
  if not L.flying() or L.holdReason() then return end
  send("land", false)
  if getEpoch() + L.RETRY <= deadline then
    ataxiaTemp.launchLandTimer = tempTimer(L.RETRY, function() tick(deadline) end)
  end
end

function ataxia_launchedLand()
  L.stop()
  local hold = L.holdReason()
  if hold then
    cecho("\n<yellow>[LAUNCHED]<reset> into the sky -- staying up (" .. hold .. ").")
    return
  end
  cecho("\n<red>[LAUNCHED]<reset> into the sky -- landing.")
  send("land", false)
  local deadline = getEpoch() + L.WINDOW
  ataxiaTemp.launchLandTimer = tempTimer(L.RETRY, function() tick(deadline) end)
end
