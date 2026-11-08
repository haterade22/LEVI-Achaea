--[[mudlet
type: alias
name: GO TO TARGET
hierarchy:
- Levi_Ataxia
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
 
-- These called goto(), which nothing defines (the walker above is the local `to`): the scry went
-- out and the walk threw.
if not matches[2] then
  if not target then
    mmp.echo("I don't know what your target is (set the 'target' variable)") return
  else
    to(target)
  end
else
  to(matches[2])
end