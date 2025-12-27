--[[mudlet
type: alias
name: AVALANCHE
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- EARTH LORD
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^av$
command: ''
packageName: ''
]]--

myminiconsole:cecho("\n<orange>HEAD<white> "..antonius.target.hits.head)
myminiconsole:cecho("\n\n<orange>TORSO<white> "..antonius.target.hits.torso)
myminiconsole:cecho("\n\n<orange>LEFT LEG<white> "..antonius.target.hits["left leg"])
myminiconsole:cecho("\n<orange>RIGHT LEG<white> "..antonius.target.hits["right leg"])
myminiconsole:cecho("\n\n<orange>RIGHT ARM<white> "..antonius.target.hits["right arm"])
myminiconsole:cecho("\n<orange>LEFT ARM<white> "..antonius.target.hits["left arm"])
myvariablename:setTitle("SHAPE      [[[  "..shape.."   ]]]", "orange")
if shape == 4 and affstrack.score.prone == 0 then
send("queue addclear free manifest quake;manifest avalanche "..target)
else
send("queue addclear free manifest avalanche "..target)
end