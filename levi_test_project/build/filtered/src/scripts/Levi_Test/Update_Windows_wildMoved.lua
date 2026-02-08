function zgui.wildMoved()
  --Update Window On Movement  
  clearWindow("Wilderness") 
  clearWindow("Ocean")
end
-------------------------------------------------------------------
registerAnonymousEventHandler("gmcp.Room.Info", "zgui.wildMoved")