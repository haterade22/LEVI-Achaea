--[[mudlet
type: alias
name: DWB Runie Mode
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Knight
- Infernal
- Dual Blunt
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^rw(torso|pulp|group|status)$
command: ''
packageName: ''
]]--

local cmd = matches[2]
if cmd == "status" then
  dwbRunie.status()
else
  dwbRunie.setMode(cmd)
end
