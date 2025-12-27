--[[mudlet
type: trigger
name: Stop Capturing Credits
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Clean-up
- Credits For Sale
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
- pattern: '^Total credits for sale: (.+).$'
  type: 1
]]--

deleteLine()
cecho("\n <DarkSlateBlue>"..string.rep("~", 52))
cecho("\n<DimGrey> Can buy a total of <gold>"..creditMarket.totalTB.."<DimGrey>cr for <gold>"..creditMarket.totalSpent.."<DimGrey> gold.")
cecho("\n <DarkSlateBlue>"..string.rep("~", 52))
echo("\n"..line)
setTriggerStayOpen("Credits for Sale", 0)