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