local mp, mmp, hp, mhp = matches[4], matches[5], matches[2], matches[3]
deleteLine()
cecho("\n<orange>  [<white>"..target:title().."<orange>]  <red>HP: <firebrick>"..math.floor((hp/mhp)*100).."%<white>  |  <blue>MP: <DodgerBlue>"..math.floor((mp/mmp)*100).."%<orange>  [<white>"..target:title().."<orange>]")
manapercent = math.floor((mp/mmp)*100)