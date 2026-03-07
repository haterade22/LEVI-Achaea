--[[mudlet
type: script
name: buildChat
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

function ataxia.buildChat()
  ataxia.chatSize = ataxia.chatSize or 9
  ataxia.chat = {}
  ataxia.chat.tabs = {"All","City","House","Order","Party","Clans","Tells","Market","Misc"}
  ataxia.chat.color1 = "rgb(15,15,15)"
  ataxia.chat.color2 = "rgb(0,0,0)"
  ataxia.chat.color3 = "rgb(25,25,25)"
  ataxia.chat.width = "100%"
  ataxia.chat.height = "100%"
  ataxia.chat.current = ataxia.chat.tabs[1]
  ataxia.chat.useCmdLine = false

  --Create the main container
  --Our tabbed window will need a container. This will be the bottom layer. Containers are invisible so no need to set a stylesheet. 
  ataxia.chat.window = Adjustable.Container:new({
    name = "ataxia.chat.window",
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
  ataxia.chat.window:changeMenuStyle("dark")

  --Create the main container
  --Our tabbed window will need a container. This will be the bottom layer. Containers are invisible so no need to set a stylesheet. 
  ataxia.chat.container = Geyser.Container:new({
    name = "ataxia.chat.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },ataxia.chat.window)
  
 --Create an HBox
 --All of our tabs will be evenly spaced. So we'll create an HBox to sit at the top of our container. 
 ataxia.chat.header = Geyser.HBox:new({
    name = "ataxia.chat.header",
    x = 0, y = 0,
    width = "100%",
    height = "8%",
  },ataxia.chat.container)  
  
  --Create a label
  --This label will serve as a container for each window. It sits right underneath the HBox we just created for the tabs. 
  ataxia.chat.footer = Geyser.Label:new({
    name = "ataxia.chat.footer",
    x = 0, y = "8%",
    width = "100%",
    height = "92%",
  },ataxia.chat.container)
  
  --Each window actually has two labels.
  ataxia.chat.center = Geyser.Label:new({
    name = "ataxia.chat.center",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  },ataxia.chat.footer)
  --ataxia.chat.center:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")

  ataxia.chat.click = function(tab)
    ataxia.chat[ataxia.chat.current.."tab"]:setStyleSheet([[
      background-color: ]]..ataxia.chat.color1..[[;
      color: DimGrey;
      border-top-left-radius: 10px;
      border-top-right-radius: 10px;
      margin-right: 1px;
      margin-left: 1px;
    ]])
    ataxia.chat[ataxia.chat.current]:hide()
    ataxia.chat.current = tab
    ataxia.chat[ataxia.chat.current]:show()
    ataxia.chat[ataxia.chat.current.."tab"]:setStyleSheet([[
      background-color: ]]..ataxia.chat.color3..[[;
      color: NavajoWhite;
      border-top-left-radius: 15px;
      border-top-right-radius: 15px;
      margin-right: 2px;
      margin-left: 2px;
    ]])  
  end
  
  for k,v in pairs(ataxia.chat.tabs) do
    ataxia.chat[v.."tab"] = Geyser.Label:new({
      name = "ataxia.chat."..v.."tab",
      fgColor = "white",
    },ataxia.chat.header)
    
    ataxia.chat[v.."tab"]:setStyleSheet([[
      background-color: ]]..ataxia.chat.color1..[[;
      border-top-left-radius: 10px;
      border-top-right-radius: 10px;
      margin-right: 1px;
      margin-left: 1px;
    ]])
    
    ataxia.chat[v.."tab"]:echo("<center>"..v)
    ataxia.chat[v.."tab"]:setClickCallback("ataxia.chat.click",v)

    ataxia.chat[v] = Geyser.Label:new({
      name = "ataxia.chat."..v,
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    },ataxia.chat.footer)

    ataxia.chat[v.."center"] = Geyser.Label:new({
      name = "ataxia.chat."..v.."center",
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    },ataxia.chat[v])
  
    ataxia.chat[v]:hide()
  end
  
--  -- Setup a command line prompt for the chat windows
--  ataxia.chat.cmd = Geyser.CommandLine:new({
--    name = "ataxia.chat.cmd", 
--    x = 0, y = "100%-40px", 
--    width = "100%", height = 40,
--    stylesheet = "border: 1px solid silver;"
--  },ataxia.chat.footer)
  
  -- Create each channel window
  ataxia.chat.allchat = Geyser.MiniConsole:new({
    name = "All",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },ataxia.chat.Allcenter)     
  hideWindow("All")
  --ataxia.chat.allchat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")

  ataxia.chat.citychat = Geyser.MiniConsole:new({
    name = "City",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },ataxia.chat.Citycenter)     
  hideWindow("City")
  --ataxia.chat.citychat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  ataxia.chat.housechat = Geyser.MiniConsole:new({
    name = "House",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },ataxia.chat.Housecenter)       
  hideWindow("House")
  --ataxia.chat.housechat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  ataxia.chat.orderchat = Geyser.MiniConsole:new({
    name = "Order",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
    color="black",
  },ataxia.chat.Ordercenter)       
  hideWindow("Order")
  --ataxia.chat.orderchat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")

  ataxia.chat.partychat = Geyser.MiniConsole:new({
    name = "Party",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },ataxia.chat.Partycenter)       
  hideWindow("Party")
  --ataxia.chat.partychat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")

  ataxia.chat.clanschat = Geyser.MiniConsole:new({
    name = "Clans",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },ataxia.chat.Clanscenter)       
  hideWindow("Clans")
  --ataxia.chat.clanschat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  ataxia.chat.tellschat = Geyser.MiniConsole:new({
    name = "Tells",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },ataxia.chat.Tellscenter)         
  hideWindow("Tells")
  --ataxia.chat.tellschat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  ataxia.chat.marketchat = Geyser.MiniConsole:new({
    name = "Market",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },ataxia.chat.Marketcenter)     
  hideWindow("Market")
  --ataxia.chat.marketchat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  ataxia.chat.miscchat = Geyser.MiniConsole:new({
    name = "Misc",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },ataxia.chat.Misccenter)     
  hideWindow("Misc")
  --ataxia.chat.miscchat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  setFontSize("All", ataxia.chatSize)
  setFontSize("City", ataxia.chatSize)
  setFontSize("House", ataxia.chatSize)
  setFontSize("Order", ataxia.chatSize)
  setFontSize("Party", ataxia.chatSize)
  setFontSize("Clans", ataxia.chatSize)
  setFontSize("Tells", ataxia.chatSize)
  setFontSize("Market", ataxia.chatSize)
  setFontSize("Misc", ataxia.chatSize)
  --ataxia.chat.window:setTitle("Chat","gray")
  ataxia.chat.window:show()
  
  if not table.contains(zgui.modules, "buildChat") then
    table.insert(zgui.modules, "buildChat")
  end
end

