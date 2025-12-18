-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > Build Windows > buildRoomInfo

function zgui.buildRoomInfo()
  zgui.roomInfoSize = zgui.roomInfoSize or 8
  zgui.rinfWindow = {}

  --Create the enemy Adjustable
  zgui.rinfWindow.window = Adjustable.Container:new({
    name = "zgui.rinfWindow.window",
    x = 0, y = 0,
    width = "50%",
    height = "50%",  
    adjLabelstyle = zgui.adjLabelstyle,
    buttonstyle=[[
      QLabel{ border-radius: 3px; background-color: rgba(140,140,140,100%);}
      QLabel::hover{ background-color: rgba(160,160,160,50%);}
    ]],
    buttonFontSize = 10,
    buttonsize = 15,          
  },main)
  zgui.rinfWindow.window:changeMenuStyle("dark")

  --Create the enemy container
  zgui.rinfWindow.container = Geyser.Container:new({
    name = "zgui.bwindow.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.rinfWindow.window)  

  --Create the enemy Console
  zgui.rinfWindow.console = Geyser.MiniConsole:new({
    name = "roomInfoDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.rinfWindow.container) 

  setFontSize("roomInfoDisplay", zgui.roomInfoSize)
  --zgui.rinfWindow.window:setTitle("Stats Window","gray")
  zgui.rinfWindow.window:show()
  
  if not table.contains(zgui.modules, "buildRoomInfo") then
    table.insert(zgui.modules, "buildRoomInfo")
  end  
end