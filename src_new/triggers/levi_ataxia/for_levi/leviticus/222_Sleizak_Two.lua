--[[mudlet
type: trigger
name: Sleizak Two
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RuneWarden
- SNB
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^The blade of \w+ is a blur as he moves forward, slicing into (\w+).$
  type: 1
- pattern: ^The sleizak rune flashes bright upon a Logosian longsword in the hand of \w+.$
  type: 1
]]--

if target == matches[2] then
tarAffed("weariness")
if applyAffV3 then applyAffV3("weariness") end
tarAffed("nausea")
if applyAffV3 then applyAffV3("nausea") end
end

