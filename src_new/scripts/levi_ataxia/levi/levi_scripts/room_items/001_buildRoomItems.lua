--[[mudlet
type: script
name: buildRoomItems
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- Room Items
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function zgui.buildRoomitems()
  zgui.roomItemsSize = zgui.roomItemsSize or 9
  zgui.roomitems = {}

  --Create the roomitems Adjustable
  zgui.roomitems.window = Adjustable.Container:new({
    name = "zgui.roomitems.window",
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
  zgui.roomitems.window:changeMenuStyle("dark")

  --Create the roomitems container
  zgui.roomitems.container = Geyser.Container:new({
    name = "zgui.roomitems.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.roomitems.window)  

  --Create the roomitems Console
  zgui.roomitems.console = Geyser.MiniConsole:new({
    name = "roomItemsDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.roomitems.container) 

  setFontSize("roomItemsDisplay", zgui.roomItemsSize)
  zgui.roomitems.window:setTitle("Items","gray")
  zgui.roomitems.window:show()
  
  if not table.contains(zgui.modules, "Roomitems") then
    table.insert(zgui.modules, "Roomitems")
  end  
end