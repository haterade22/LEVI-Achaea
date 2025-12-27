--[[mudlet
type: script
name: buildRoomPlayers
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

function zgui.buildRoomPlayers()
  zgui.roomPlayersSize = zgui.roomPlayersSize or 9
  zgui.roomPlayers = {}

  --Create the roomPlayers Adjustable
  zgui.roomPlayers.window = Adjustable.Container:new({
    name = "zgui.roomPlayers.window",
    x = 0, y = 0,
    width = "50%",
    height = "50%",  
    adjLabelstyle = zgui.adjLabelstyle,
    buttonstyle=[[
      QLabel{ border-radius: 5px; background-color: rgba(140,140,140,100%);}
      QLabel::hover{ background-color: rgba(160,160,160,50%);}
    ]],
    buttonFontSize = 9,
    buttonsize = 14,          
  },main)
  zgui.roomPlayers.window:changeMenuStyle("dark")

  --Create the roomPlayers container
  zgui.roomPlayers.container = Geyser.Container:new({
    name = "zgui.roomPlayers.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.roomPlayers.window)  

  --Create the roomPlayers Console
  zgui.roomPlayers.console = Geyser.MiniConsole:new({
    name = "roomPlayersDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "80%",
    height = "100%",
    color="black",
  },zgui.roomPlayers.container) 

  setFontSize("roomPlayersDisplay", zgui.roomPlayersSize)
  --zgui.roomPlayers.window:setTitle("Players","gray")
  zgui.roomPlayers.window:show()
  
  if not table.contains(zgui.modules, "buildRoomPlayers") then
    table.insert(zgui.modules, "buildRoomPlayers")
  end  
end