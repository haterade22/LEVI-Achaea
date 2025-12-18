-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > Mapper > WildWalker > Wilderness Exit Utilities

local firstSpace, secondSpace = 25,30 

function makeWildExit(name,fullname,num)
  local first,second = firstSpace,secondSpace
  local blank1 = string.rep(" ", first-#name)
  local blank2 = string.rep(" ", second-#fullname)
  local x,y = translateWilderness(num)
  local s1 = string.rep(" ", 5-#(""..x))
--  echo(string.format([[%s =%s{name="%s",%sx = %s,%sy = %s},]].."\n",name:lower(),blank1,fullname,blank2,x,s1,y))
  wildernessExits[name] = {name = fullname, x = x, y = y}
  reDrawWildernessExitTable()
end

function reDrawWildernessExitTable()
  -- Just used for pretifying the table, makes it easier to change spacing and such.
  local first,second = firstSpace,secondSpace
  echo "wildernessExits = wildernessExits or {\n"
  for k,v in pairsByKeys(wildernessExits) do
    local name, fullname = k, v.name 
    local x,y = v.x,v.y
    local blank1 = string.rep(" ", first-#name)
    local blank2 = string.rep(" ", second-#fullname)
    local s1 = string.rep(" ", 5-#(""..x))
    echo(string.format([[%s =%s{name="%s",%sx = %s,%sy = %s},]].."\n",name,blank1,fullname,blank2,x,s1,y))
  end
  echo("} \n \n ")
end