--[[mudlet
type: alias
name: TARGET
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- General
attributes:
  isActive: 'no'
  isFolder: 'no'
regex: ^t (\w+)$
command: ''
packageName: ''
]]--

target = matches[2]:lower():title()
if targett then killTrigger(targett) end
targett = tempTrigger(target, [[selectString("]] .. target .. [[", 1) fg("red") 
resetFormat()]])
cecho("<light_slate_blue>MY TARGET FOR ATTACKS IS (((((((((((( <red>"..target.."<light_slate_blue> ))))))))))))\n")
