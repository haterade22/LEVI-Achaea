--[[mudlet
type: trigger
name: Mnemosyne Wall Melted
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
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
- pattern: ^You send a lash of fire to strike the icewall to the \w+, and it quickly melts\.
  type: 1
]]--

-- Melt CONFIRMED (Bracers of Flame): the wall in this room is gone -- clear the
-- swarm module's wall memory so escapes stop routing leap-only and the melt
-- retry loop stops. The end-of-room melt re-sends until this line lands.
if ataxia.mnemosyne and ataxia.mnemosyne.swarm and ataxia.mnemosyne.swarm.onWallMelted then
  ataxia.mnemosyne.swarm.onWallMelted()
end
