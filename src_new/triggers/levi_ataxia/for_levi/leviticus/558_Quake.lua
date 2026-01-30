--[[mudlet
type: trigger
name: Quake
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes A-J
- Earth Lord
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
- pattern: You stomp upon the ground, a ripple of tremors radiating out from the impact.
  type: 3
- pattern: ^The (right|left) leg of (\w+) buckles under the impact, and \w+ goes sprawling.$
  type: 1
]]--

if targetIshere or table.contains(ataxia.playersHere) then
  tAffs.prone = true
  selectString(line,1)
  fg("purple")
  deselect()
  resetFormat()
end