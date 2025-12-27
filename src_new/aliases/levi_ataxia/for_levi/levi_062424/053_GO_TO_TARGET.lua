--[[mudlet
type: alias
name: GO TO TARGET
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^top(?: (\w+))?$'
command: ''
packageName: ''
]]--

send("clearqueue all; queue add free scry for " ..target)
local function to(whom)
  local p = whom:title()
  if not mmp.pdb[p] then mmp.echo("Sorry - don't know where "..p.." is.") return end
 
  local nums = mmp.getnums(mmp.pdb[p], true)
  mmp.gotoRoom(nums[1])
  mmp.echo(string.format("Going to %s in %s%s.", p, mmp.cleanAreaName(mmp.areatabler[getRoomArea(nums[1])] or '?'), (#nums ~= 1 and " (non-unique location though)" or "")))
send("pt going to "..target.." in "..nums[1])
end
 
if not matches[2] then
  if not target then
    mmp.echo("I don't know what your target is (set the 'target' variable)") return
  else
    goto(target)
  end
else
  goto(matches[2])
end