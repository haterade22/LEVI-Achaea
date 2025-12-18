-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > Build Windows > buildStatsWindow

function zgui.buildStatsWindow()
  zgui.statsWindowSize = zgui.statsWindowSize or 8
  zgui.statwindow = {}

  --Create the enemy Adjustable
  zgui.statwindow.window = Adjustable.Container:new({
    name = "zgui.statwindow.window",
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
  zgui.statwindow.window:changeMenuStyle("dark")

  --Create the enemy container
  zgui.statwindow.container = Geyser.Container:new({
    name = "zgui.bwindow.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.statwindow.window)  

  --Create the enemy Console
  zgui.statwindow.console = Geyser.MiniConsole:new({
    name = "statsDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.statwindow.container) 

  setFontSize("statsDisplay", zgui.statsWindowSize)
  --zgui.statwindow.window:setTitle("Stats Window","gray")
  zgui.statwindow.window:show()
  
  if not table.contains(zgui.modules, "buildStatsWindow") then
    table.insert(zgui.modules, "buildStatsWindow")
  end  
end