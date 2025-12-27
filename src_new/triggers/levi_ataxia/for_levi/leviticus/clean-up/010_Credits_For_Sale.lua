--[[mudlet
type: trigger
name: Credits For Sale
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Clean-up
attributes:
  isActive: 'no'
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
mStayOpen: 99
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: 'Credits currently available for purchase:'
  type: 3
]]--

deleteLine()
creditMarket = {
	available = 0,
	handGold = tonumber(gmcp.Char.Status.gold),
	bankGold = tonumber(gmcp.Char.Status.bank),
	avgPrice = 0,
	totalTB = 0,
	totalSpent = 0
}
cecho("\n<DarkSlateBlue> ~~~~~~~~~~~~~~* <DimGrey>Achaea Credit Market <DarkSlateBlue>*~~~~~~~~~~~~~~")
cecho("\n<DimGrey>"..string.rep(" ", 44-string.len(creditMarket.handGold)).."Balance: <gold>"..creditMarket.handGold)
cecho("\n<DarkSlateBlue> ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")