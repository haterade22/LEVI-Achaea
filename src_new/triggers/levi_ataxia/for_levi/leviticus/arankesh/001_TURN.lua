--[[mudlet
type: trigger
name: TURN
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MINE ALL MINE
- ARANKESH
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
- pattern: Aran'Kesh, the Fleshrender tilts his horrific head back and lets forth a blood-curdling screech before buffeting
    massive wings and rising high into the firmament.
  type: 3
- pattern: The rope extending from an ancient harpoon suddenly goes limp as Aran'Kesh breaks free of the bonds threatening
    to ground him. Ready your harpoon for another pass!
  type: 3
]]--

deleteFull()
send("clearqueue all;turn harpoon")