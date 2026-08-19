--[[mudlet
type: trigger
name: FIRE SCALD
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Unknown Checks
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
- pattern: A greater fire elemental reaches up and removes its mask, the pure brightness and heat causing your face to burn
    and your vision to fade.
  type: 3
- pattern: The elemental rotates its mask, the permanent rictus now a fanged frown, making its displeasure known.
  type: 3
]]--

expandAlias("diag")
if ataxia.afflictions.blackout then	send("cq all;touch tree") end
if ataxia.afflictions.blackout then		expandAlias("diag") end
-- Was `defense blind reset`: wrong on both halves. Every other site in the tree spells it
-- `defence`, and the defence is named `blindness` (deffing/004_Defence_Sorting) -- `blind`
-- is not a defence, so this was silently rejected. A rejected curing command prints
-- nothing, which is why it survived.
ataxia_sendCuringPriority("curing priority defence blindness reset", false)