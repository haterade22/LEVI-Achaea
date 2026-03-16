--[[mudlet
type: alias
name: (ataxiaDmg)
hierarchy:
- Levi_Ataxia
- Systems
- ataxia.data
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^ataxiadmg(?: (.+))?$'
command: ''
packageName: ''
]]--

local args = matches[2]

if not args or args == "" then
  ataxia.data.db.showMobDamage()
elseif args == "reset" then
  ataxia.data.db.resetMobDamage()
elseif args:match("^delete%s+(.+)$") then
  local filter = args:match("^delete%s+(.+)$")
  ataxia.data.db.deleteMobDamage(filter)
else
  ataxia.data.db.showMobDamage(args)
end
