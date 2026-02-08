cecho("\n <a_blue>+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+")
cecho("\n <a_blue>|      <NavajoWhite>Bashing Report For This Session     <a_blue> |")
cecho("\n <a_blue>+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+")
cecho("\n <a_blue>| <DimGrey>Gold gained: <gold>"..bashStats.gainedGold..string.rep(" ", 29-string.len(bashStats.gainedGold)).."<a_blue>|")
cecho("\n  <a_blue>-------------------------------------------")
local atkLine = " Hits : "..bashStats.attacks..string.rep(" ", 6-string.len(bashStats.attacks)).."| Crits: "..bashStats.crits..string.rep(" ", 6-string.len(bashStats.crits)).."("..string.format("%2.2f", ((bashStats.crits/bashStats.attacks)*100)).."%)"
cecho("\n <a_blue>|<orange>"..atkLine..string.rep(" ", 43-string.len(atkLine)).."<a_blue>|")
atkLine = " Taken: "..bashStats.mobhits..string.rep(" ", 6-string.len(bashStats.mobhits)).."| SoA  : "..bashStats.blockedhits..string.rep(" ", 6-string.len(bashStats.blockedhits)).."("..string.format("%2.2f", ((bashStats.blockedhits/bashStats.mobhits)*100)).."%)"
cecho("\n <a_blue>|<tomato>"..atkLine..string.rep(" ", 43-string.len(atkLine)).."<a_blue>|")
cecho("\n <a_blue>|<a_darkred> Slain: <red>"..bashStats.slain..string.rep(" ", 35-string.len(bashStats.slain)).."<a_blue>|")
cecho("\n <a_blue>+-------------------------------------------+")
cecho("\n <a_blue>|               <NavajoWhite>Critical Data               <a_blue>|")
cecho("\n <a_blue>+-------------------------------------------+")
atkLine = " 2x:"..string.rep(" ", 7-string.len(bashStats.criticals["2x"]))..bashStats.criticals["2x"].." ("..string.format("%2.2f", ((bashStats.criticals["2x"]/bashStats.crits))*100).."%)"
cecho("\n <a_blue>|<DimGrey>"..atkLine..string.rep(" ", 43-string.len(atkLine)).."<a_blue>|")
atkLine = " 4x:"..string.rep(" ", 7-string.len(bashStats.criticals["4x"]))..bashStats.criticals["4x"].." ("..string.format("%2.2f", ((bashStats.criticals["4x"]/bashStats.crits))*100).."%)"
cecho("\n <a_blue>|<white>"..atkLine..string.rep(" ", 43-string.len(atkLine)).."<a_blue>|")
atkLine = " 8x:"..string.rep(" ", 7-string.len(bashStats.criticals["8x"]))..bashStats.criticals["8x"].." ("..string.format("%2.2f", ((bashStats.criticals["8x"]/bashStats.crits))*100).."%)"
cecho("\n <a_blue>|<green>"..atkLine..string.rep(" ", 43-string.len(atkLine)).."<a_blue>|")
atkLine = " 16x:"..string.rep(" ", 6-string.len(bashStats.criticals["16x"]))..bashStats.criticals["16x"].." ("..string.format("%2.2f", ((bashStats.criticals["16x"]/bashStats.crits))*100).."%)"
cecho("\n <a_blue>|<yellow>"..atkLine..string.rep(" ", 43-string.len(atkLine)).."<a_blue>|")
atkLine = " 32x:"..string.rep(" ", 6-string.len(bashStats.criticals["32x"]))..bashStats.criticals["32x"].." ("..string.format("%2.2f", ((bashStats.criticals["32x"]/bashStats.crits))*100).."%)"
cecho("\n <a_blue>|<orange>"..atkLine..string.rep(" ", 43-string.len(atkLine)).."<a_blue>|")
atkLine = " 64x:"..string.rep(" ", 6-string.len(bashStats.criticals["64x"]))..bashStats.criticals["64x"].." ("..string.format("%2.2f", ((bashStats.criticals["64x"]/bashStats.crits))*100).."%)"
cecho("\n <a_blue>|<red>"..atkLine..string.rep(" ", 43-string.len(atkLine)).."<a_blue>|")
cecho("\n <a_blue>+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+")
send(" ")