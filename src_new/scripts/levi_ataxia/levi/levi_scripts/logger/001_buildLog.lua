--[[mudlet
type: script
name: buildLog
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Logger
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function zgui.buildLog()
  zgui.loggerSize = zgui.loggerSize or 9
  zgui.logger = {}

  --Create the main Adjustable
  zgui.logger.window = Adjustable.Container:new({
    name = "zgui.logger.window",
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
  zgui.logger.window:changeMenuStyle("dark")

  --Create the log container
  zgui.logger.container = Geyser.Container:new({
    name = "zgui.logger.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.logger.window)  

  --Create the Logger Console
  zgui.logger.console = Geyser.MiniConsole:new({
    name = "logDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.logger.container)

  setFontSize("logDisplay", zgui.loggerSize)
  --zgui.logger.window:setTitle("Log","gray")
  zgui.logger.window:show()  
  
  if not table.contains(zgui.modules, "buildLog") then
    table.insert(zgui.modules, "buildLog")
  end
end