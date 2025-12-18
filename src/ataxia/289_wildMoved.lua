-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > Mapper > wildMoved

function zgui.wildMoved()
  --Update Window On Movement  
  clearWindow("Wilderness") 
  clearWindow("Ocean")
  WildernessCoords()
end
-------------------------------------------------------------------
registerAnonymousEventHandler("gmcp.Room.Info", "zgui.wildMoved")