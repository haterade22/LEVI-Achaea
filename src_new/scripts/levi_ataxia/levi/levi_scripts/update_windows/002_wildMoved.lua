--[[mudlet
type: script
name: wildMoved
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Update Windows
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function zgui.wildMoved()
  --Update Window On Movement  
  clearWindow("Wilderness") 
  clearWindow("Ocean")
end
-------------------------------------------------------------------
registerAnonymousEventHandler("gmcp.Room.Info", "zgui.wildMoved")