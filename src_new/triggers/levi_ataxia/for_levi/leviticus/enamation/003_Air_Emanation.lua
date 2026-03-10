--[[mudlet
type: trigger
name: Air Emanation
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Enamation
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
- pattern: ^You sweep an? \w+ staff over your head and a great wind rises, picking up (\w+) and dashing them violently
    about before casting them back to the ground\.$
  type: 1
]]--

local tgt = matches[2]
if tgt ~= target then return end

tarAffed("paralysis")
tarAffed("dizziness")
magi.offense = magi.offense or {}
magi.offense.ptRelay(target .. ": Emanation Air (Paralysis + Dizziness)")
selectCurrentLine() bg("cyan")