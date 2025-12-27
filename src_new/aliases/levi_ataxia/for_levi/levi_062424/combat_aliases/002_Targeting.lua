--[[mudlet
type: alias
name: Targeting
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^t (.+)$
command: ''
packageName: ''
]]--

local x = matches[2]
if type(x) == "string" then x = x:title() end
switchTarget(x)

if tar_upper then killTrigger(tar_upper) end
tar_upper = tempTrigger(target, [[
  local c = 1
  while selectString("]] .. target .. [[",c) > -1 do
    fg("yellow")
    c = c + 1
  end
  resetFormat()
]])

if tar_lower then killTrigger(tar_lower) end
tar_lower = tempTrigger(target:lower(), [[
  local c = 1
  while selectString("]] .. target:lower() .. [[",c) > -1 do
    fg("yellow")
    c = c + 1
  end
  resetFormat()
]])
engaged = false
if partyrelay then send("pt target: "..target) end
partyrelay = true



target = matches[2]:lower():title()


if gmcp.Char.Status.race == "Undead" then
send("ct target: "..target)
end