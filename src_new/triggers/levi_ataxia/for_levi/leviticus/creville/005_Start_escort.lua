--[[mudlet
type: trigger
name: Start escort
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Questing
- Creville
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
- pattern: Climbing painfully atop the gurney, the beaten prisoner situates himself on the pushcart's table. After lying down
    on his back, he drapes the cloth over his legs and stomach before pulling it up and over his head.
  type: 3
]]--

ataxia_Echo("If you haven't cleared the area up until here, do so now otherwise PUSH GURNEY until you reach the exit.")
ataxia_Echo("You'll have to use the lift to go to the ground floor.")
ataxia_Echo("Also prepare to fight more mobs on the way out.")