--[[mudlet
type: alias
name: priority targets
hierarchy:
- Levi_Ataxia
- Combat
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