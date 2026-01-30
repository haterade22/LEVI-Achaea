--[[mudlet
type: alias
name: Crescent Kill
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Monks
- Monk
- Shikudo
attributes:
  isActive: 'no'
  isFolder: 'no'
regex: ^sc$
command: ''
packageName: ''
]]--

kickshikudoattack()
shikudostaffstrike()
shikudostafftwo()


if (targshield == true) and (svo.bals.balance and svo.bals.equilibrium) and (not svo.affl.paralysis) then
send("queue addclear freestand;stand;wield staff;combo " ..target.. " shatter " ..kicked.. " ;assess " ..target)
elseif shikudostance == "maelstrom" and tAffs.prone >= 100 and currHealth <= 49 then
send("queue addclear free stand;stand;wield staff;combo " ..target.. " livestrike jinzuku crescent;assess " ..target)
elseif shikudostance == "gaital" and tAffs.prone >= 100 and currHealth <= 45  and katachain >= 5 then
send("queue addclear free stand;stand;wield staff;transition to the maelstrom form;combo " ..target.. " livestrike jinzuku crescent;assess " ..target)
elseif shikudostance == "maelstrom" and tAffs.prone < 100 and currHealth <= 49 then
send("queue addclear free stand;stand;wield staff;combo " ..target.. " sweep crescent;assess " ..target)
elseif shikudostance == "gaital" and tAffs.prone < 100 and currHealth <= 40 and katachain >= 5 then
send("queue addclear free stand;stand;wield staff;transition to the maelstrom form;combo " ..target.. " sweep crescent;assess " ..target)
elseif shikudostance == "gaital" and tAffs.prone < 100 and currHealth >= 50 then
send("queue addclear free stand;stand;wield staff;combo " ..target.. " sweep spinkick;assess " ..target)
elseif shikudostance == "gaital" and tAffs.prone >= 100 and currHealth >= 50 then
send("queue addclear free stand;stand;wield staff;combo " ..target.. " kuro right kuro right spinkick;assess " ..target)
elseif shikudostance == "oak" and tAffs.prone >= 100 and currHealth >= 50  and katachain >= 5 then
send("queue addclear free stand;stand;wield staff;transition to the gaital form;combo " ..target.. " kuro right kuro right spinkick;assess " ..target)
elseif shikudostance == "oak" and tAffs.prone < 100 and currHealth >= 50  and katachain >= 5 then
send("queue addclear free stand;stand;wield staff;transition to the gaital form;combo " ..target.. " sweep spinkick;assess " ..target)
else
send("queue addclear free stand;stand;wield staff;combo " ..target.. " " ..kicked.. " " ..staff.. " " ..stafftwo.. " ;assess " ..target)

end
