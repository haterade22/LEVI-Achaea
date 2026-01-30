--[[mudlet
type: trigger
name: Adding Fashions
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Vodun
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
- pattern: ^While you hastily examine \w+, you mould the fledgling doll a bit, further defining the arms and legs.$
  type: 1
- pattern: ^Adding further detail to the doll of \w+, you work on defining the nose, ears, eyes, and mouth.$
  type: 1
- pattern: You examine the doll carefully, and begin to form fingers and toes.
  type: 3
- pattern: You quickly sneak in another fashion.
  type: 3
- pattern: ^You fashion the eyes of your doll to resemble those of \w+.$
  type: 1
- pattern: ^With one hand pointed towards \w+, you rub a finger over the heart of your doll.$
  type: 1
- pattern: ^You laugh darkly and squint at \w+ as you add some final touches to your doll of \w+.$
  type: 1
]]--

ataxiaTemp.dollFashions = ataxiaTemp.dollFashions + 1
deleteLine()
cecho("\n<a_brown>[<purple>Doll<a_brown>]: <DimGrey>Fashioned doll, now at <a_red>"..ataxiaTemp.dollFashions.."<DimGrey> fashions.")