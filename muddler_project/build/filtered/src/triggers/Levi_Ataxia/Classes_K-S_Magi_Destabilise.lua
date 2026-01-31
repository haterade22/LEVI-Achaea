local destabilise = {
  plague = {"brokenleftleg", "brokenrightleg", "brokenleftarm"},
  oscillate = {"epilepsy", "stupidity"},
  disorientation = {"prone", "dizziness"},
}
local vibe = matches[2]

if destabilise[vibe] and targetIshere then
  addAffList(destabilise[vibe])
end

vibes_inRoom[matches[2]] = nil