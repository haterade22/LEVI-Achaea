--[[mudlet
type: script
name: target swapping
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

function TargetSwapForward()
  if targetindex < table.maxn(dembaddies.enemies) then 
    targetindex = targetindex + 1
    expandAlias("t "..dembaddies.enemies[targetindex])
  else
    expandAlias("t "..dembaddies.enemies[targetindex])
  end 
end

function TargetSwapBackwards()
  if targetindex > 1 then 
    targetindex = targetindex - 1
    expandAlias("t "..dembaddies.enemies[targetindex])
  else
    expandAlias("t "..dembaddies.enemies[targetindex])
  end 
end

function PrioTargetSwapForward()
  if priotargetindex < table.maxn(priorityTargets) then 
    priotargetindex = priotargetindex + 1
    expandAlias("t "..priorityTargets[priotargetindex])
  else
    expandAlias("t "..priorityTargets[priotargetindex])
  end 
end

function PrioTargetSwapBackwards()
  if priotargetindex > 1 then 
    priotargetindex = priotargetindex - 1
    expandAlias("t "..priorityTargets[priotargetindex])
  else
    expandAlias("t "..priorityTargets[priotargetindex])
  end 
end