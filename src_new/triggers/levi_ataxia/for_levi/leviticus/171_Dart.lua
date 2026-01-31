--[[mudlet
type: trigger
name: Dart
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Start Shikudo
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
mStayOpen: 2
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Spinning on one foot you bring a warped black iron staff coated with rust around in a lightning fast thrust at
    the (.*) of (\w+).$
  type: 1
- pattern: ^Sharply extending out your arms in front of you, you deliver a lightning-fast thrust to the (.*) of (\w+) with
    a warped black iron staff coated with rust.$
  type: 1
]]--

if isTarget(matches[3]) then
 monk.shikudo.limb_hit(matches[2], "dart")
end