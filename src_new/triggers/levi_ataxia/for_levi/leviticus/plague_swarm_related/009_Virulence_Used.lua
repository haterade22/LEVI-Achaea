--[[mudlet
type: trigger
name: Virulence Used
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Plague/Swarm Related
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
- pattern: ^You send an arcane pulse into (\w+), seeking to make the latent become rampant.$
  type: 1
]]--

if pariah.state.expose then
  pariah.state.expose = false
end

if pariah.state.virulenceTimer then killTimer(pariah.state.virulenceTimer) end
pariah.state.virulenceTimer = tempTimer(10, [[ pariah.state.virulenceTimer = nil ]])

selectString(line,1)
fg("DarkOrchid")
deselect()
resetFormat()