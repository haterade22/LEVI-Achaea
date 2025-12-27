--[[mudlet
type: script
name: buildRoomDenizens
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

function zgui.buildRoomDenizens()
  zgui.roomDenizensSize = zgui.roomDenizensSize or 6
  zgui.roomDenizens = {}

  --Create the roomDenizens Adjustable
  zgui.roomDenizens.window = Adjustable.Container:new({
    name = "zgui.roomDenizens.window",
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
  zgui.roomDenizens.window:changeMenuStyle("dark")

  --Create the roomDenizens container
  zgui.roomDenizens.container = Geyser.Container:new({
    name = "zgui.roomDenizens.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.roomDenizens.window)  

  --Create the roomDenizens Console
  zgui.roomDenizens.console = Geyser.MiniConsole:new({
    name = "roomDenizensDisplay",
    x = 0, y = 0,
    autoWrap = false,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.roomDenizens.container) 

  setFontSize("roomDenizensDisplay", zgui.roomDenizensSize)
  --zgui.roomDenizens.window:setTitle("Denizens","gray")
  zgui.roomDenizens.window:show()
  
  if not table.contains(zgui.modules, "buildRoomDenizens") then
    table.insert(zgui.modules, "buildRoomDenizens")
  end  
end