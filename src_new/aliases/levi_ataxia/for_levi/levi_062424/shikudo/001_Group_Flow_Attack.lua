--[[mudlet
type: alias
name: Group Flow Attack
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
regex: ^sr$
command: ''
packageName: ''
]]--

 kickshikudoattack()
 shikudostaffstrike()
 shikudostafftwo()

if tAffs.shield then
send("queue addclear free;stand;stand;wield staff;combo " ..target.. " shatter " ..kicked.. " ;assess " ..target)
elseif shikudostance == "rain" and katachain >= 21 then
send("queue addclear free;stand;stand;wield staff;combo " ..target.. " " ..kicked.. " " ..staff.. " " ..stafftwo.. " ;transition to the oak form;assess " ..target)
elseif shikudostance == "oak" and katachain >= 9 then 
send("queue addclear free;stand;stand;wield staff;combo " ..target.. " " ..kicked.. " " ..staff.. " " ..stafftwo.. " ;transition to the gaital form;assess " ..target)
elseif shikudostance == "willow" and katachain >= 9 then 
send("queue addclear free;stand;stand;wield staff;combo " ..target.. " " ..kicked.. " " ..staff.. " " ..stafftwo.. " ;transition to the rain form;assess " ..target)
elseif shikudostance == "gaital" and katachain >= 9 then 
send("queue addclear free;stand;stand;wield staff;combo " ..target.. " " ..kicked.. " " ..staff.. " " ..stafftwo.. " ;transition to the maelstrom form;assess " ..target)
elseif shikudostance == "maelstrom" and katachain >= 9 then 
send("queue addclear free;stand;stand;wield staff;combo " ..target.. " " ..kicked.. " " ..staff.. " " ..stafftwo.. " ;transition to the oak form;assess " ..target)
else
send("queue addclear free;stand;stand;wield staff;combo " ..target.. " " ..kicked.. " " ..staff.. " " ..stafftwo.. " ;assess " ..target)
end