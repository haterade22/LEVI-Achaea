--[[mudlet
type: script
name: buildBashWindow
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Build Windows
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function zgui.buildBashWindow()
  zgui.bashWindowSize = zgui.bashWindowSize or 7
  zgui.bwindow = {}

  --Create the enemy Adjustable
  zgui.bwindow.window = Adjustable.Container:new({
    name = "zgui.bwindow.window",
    x = 0, y = 0,
    width = "50%",
    height = "50%",  
    adjLabelstyle = zgui.adjLabelstyle,
    buttonstyle=[[
      QLabel{ border-radius: 5px; background-color: rgba(140,140,140,100%);}
      QLabel::hover{ background-color: rgba(160,160,160,50%);}
    ]],
    buttonFontSize = 10,
    buttonsize = 15,          
  },main)
  zgui.bwindow.window:changeMenuStyle("dark")

  --Create the enemy container
  zgui.bwindow.container = Geyser.Container:new({
    name = "zgui.bwindow.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.bwindow.window)  

  --Create the enemy Console
  zgui.bwindow.console = Geyser.MiniConsole:new({
    name = "bashDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.bwindow.container) 

  setFontSize("bashDisplay", zgui.bashWindowSize)
  --zgui.bwindow.window:setTitle("Basher Window","gray")
  zgui.bwindow.window:show()
  
  if not table.contains(zgui.modules, "buildBashWindow") then
    table.insert(zgui.modules, "buildBashWindow")
  end  
end