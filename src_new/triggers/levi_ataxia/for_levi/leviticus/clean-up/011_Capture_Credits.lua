--[[mudlet
type: trigger
name: Capture Credits
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
- pattern: ^\s+(\d+) credits? at (\d+) gold per credit.$
  type: 1
]]--

deleteLine()
local amt, price = tonumber(matches[2]), tonumber(matches[3])
creditMarket.available = creditMarket.available + amt

cecho("\n<LightSkyBlue> "..utf8.char(187).." <DimGrey>"..amt..string.rep(" ", 4-string.len(amt)).." @ "..price.."g")

local canBuy = 0

for cr=1, amt do creditMarket.avgPrice = creditMarket.avgPrice + price end


while creditMarket.handGold > price do
	if canBuy < amt then
		canBuy = canBuy + 1
		creditMarket.handGold = creditMarket.handGold - price
		creditMarket.totalSpent = creditMarket.totalSpent + price
	else
		break
	end
end

creditMarket.totalTB = creditMarket.totalTB + canBuy

cecho(string.rep(" ", 6-string.len(price)).."<DarkGreen>- <DimGrey>Can buy"..string.rep(" ", 3-string.len(canBuy)).."<gold>"..canBuy.."<DimGrey> with ")
cecho("<goldenrod>"..string.rep(" ", 8-string.len(creditMarket.handGold))..creditMarket.handGold.." <DimGrey>gold left.")
