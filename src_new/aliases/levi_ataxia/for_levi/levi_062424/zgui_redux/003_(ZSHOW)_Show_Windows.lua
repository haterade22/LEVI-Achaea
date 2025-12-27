--[[mudlet
type: alias
name: (ZSHOW) Show Windows
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- ZulahGUI - Saonji Edit
- zGUI Redux
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^zshow(?: (\w+))?$'
command: ''
packageName: ''
]]--

if matches[2] then
  local showThis = string.title(matches[2])
  if showThis == "All" then
    for i=1, #zgui.modules, 1 do
      zgui[zgui.modules[i]]()
    end 
  elseif zgui["build"..showThis] then
    zgui["build"..showThis]()
    cecho("\n<purple> -Ran: zgui\.build"..showThis.."\(\) \n")
  else
    cecho("\n<purple> -No <white>\["..showThis.."\]<purple> Found for zgui\.build"..showThis.."\(\) check capitalization \n")
  end
else
  cecho("\n<purple> --------------------------------------------------------")
  cecho("\n<purple> -To display all windows type: <white>zshow all\n")
  cecho("\n<white> Modules Installed:")
  for i=1, #zgui.modules, 1 do
    cecho("\n<purple> - <SteelBlue>"..utf8.remove(zgui.modules[i], 1, 5))
  end 
  cecho("\n\n<purple> -To display a single window type:")
  cecho("\n<white>    zshow Log")
  cecho("\n<white>    zshow RoomItems")
  cecho("\n<purple> --------------------------------------------------------\n")
end