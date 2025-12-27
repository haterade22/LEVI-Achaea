--[[mudlet
type: alias
name: priority targets
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- AzzysEnemyManagement
- Enemy Management
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^prio (.*)$
command: ''
packageName: ''
]]--

targets = matches[2]

targetslist = string.split(targets, " ")

SetPriorityTargets(targetslist)

priotargetindex = 0