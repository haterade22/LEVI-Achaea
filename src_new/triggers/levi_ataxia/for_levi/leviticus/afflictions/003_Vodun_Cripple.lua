--[[mudlet
type: trigger
name: Vodun Cripple
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Vodun
- Afflictions
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
- pattern: ^With a prayer to the spirits, you break all the limbs on your doll of \w+.$
  type: 1
]]--

tarAffed(	"brokenleftleg", "brokenrightleg", "brokenleftarm", "brokenrightarm", "prone" )
if applyAffV3 then applyAffV3("brokenleftleg"); applyAffV3("brokenrightleg"); applyAffV3("brokenleftarm"); applyAffV3("brokenrightarm"); applyAffV3("prone") end

ataxiaTemp.dollFashions = ataxiaTemp.dollFashions - 7
cecho(" <yellow>(<a_red>"..ataxiaTemp.dollFashions.."<yellow>)")


