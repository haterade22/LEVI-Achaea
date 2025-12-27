--[[mudlet
type: script
name: set priority targets
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- AzzysEnemyManagement
- Enemy Management
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function SetPriorityTargets(targetlist)
  priorityTargets = {}
  priorityTargets = targetlist
  reportstring = ""
  for i,d in ipairs(priorityTargets) do
    reportstring = reportstring .. d:title() .. ", "
    namecheck = priorityTargets[i]
    send("enemy "..namecheck)
    for x,y in ipairs(dembaddies.enemies) do
      if namecheck:title() == y:title() then
        table.remove(dembaddies.enemies, x)
      end
    end
  end
  
  send("pt Priority target list: "..reportstring)
  
end