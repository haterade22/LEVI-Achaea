--[[mudlet
type: trigger
name: Destabilise
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Magi
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Turning to .+ you direct \w+ to project a disruptive tone at \w+ (\w+) vibration.$
  type: 1
]]--

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