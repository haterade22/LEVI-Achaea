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

function zgui.buildChat()
  zgui.chatSize = zgui.chatSize or 9
  zgui.chat = {}
  zgui.chat.tabs = {"All","City","House","Order","Party","Clans","Tells","Market","Misc"}
  zgui.chat.color1 = "rgb(15,15,15)"
  zgui.chat.color2 = "rgb(0,0,0)"
  zgui.chat.color3 = "rgb(25,25,25)"
  zgui.chat.width = "100%"
  zgui.chat.height = "100%"
  zgui.chat.current = zgui.chat.tabs[1]
  zgui.chat.useCmdLine = false

  --Create the main container
  --Our tabbed window will need a container. This will be the bottom layer. Containers are invisible so no need to set a stylesheet. 
  zgui.chat.window = Adjustable.Container:new({
    name = "zgui.chat.window",
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
  zgui.chat.window:changeMenuStyle("dark")

  --Create the main container
  --Our tabbed window will need a container. This will be the bottom layer. Containers are invisible so no need to set a stylesheet. 
  zgui.chat.container = Geyser.Container:new({
    name = "zgui.chat.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.chat.window)
  
 --Create an HBox
 --All of our tabs will be evenly spaced. So we'll create an HBox to sit at the top of our container. 
 zgui.chat.header = Geyser.HBox:new({
    name = "zgui.chat.header",
    x = 0, y = 0,
    width = "100%",
    height = "8%",
  },zgui.chat.container)  
  
  --Create a label
  --This label will serve as a container for each window. It sits right underneath the HBox we just created for the tabs. 
  zgui.chat.footer = Geyser.Label:new({
    name = "zgui.chat.footer",
    x = 0, y = "8%",
    width = "100%",
    height = "92%",
  },zgui.chat.container)
  
  --Each window actually has two labels.
  zgui.chat.center = Geyser.Label:new({
    name = "zgui.chat.center",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  },zgui.chat.footer)
  --zgui.chat.center:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")

  zgui.chat.click = function(tab)
    zgui.chat[zgui.chat.current.."tab"]:setStyleSheet([[
      background-color: ]]..zgui.chat.color1..[[;
      color: DimGrey;
      border-top-left-radius: 10px;
      border-top-right-radius: 10px;
      margin-right: 1px;
      margin-left: 1px;
    ]])
    zgui.chat[zgui.chat.current]:hide()
    zgui.chat.current = tab
    zgui.chat[zgui.chat.current]:show()
    zgui.chat[zgui.chat.current.."tab"]:setStyleSheet([[
      background-color: ]]..zgui.chat.color3..[[;
      color: NavajoWhite;
      border-top-left-radius: 15px;
      border-top-right-radius: 15px;
      margin-right: 2px;
      margin-left: 2px;
    ]])  
  end
  
  for k,v in pairs(zgui.chat.tabs) do
    zgui.chat[v.."tab"] = Geyser.Label:new({
      name = "zgui.chat."..v.."tab",
      fgColor = "white",
    },zgui.chat.header)
    
    zgui.chat[v.."tab"]:setStyleSheet([[
      background-color: ]]..zgui.chat.color1..[[;
      border-top-left-radius: 10px;
      border-top-right-radius: 10px;
      margin-right: 1px;
      margin-left: 1px;
    ]])
    
    zgui.chat[v.."tab"]:echo("<center>"..v)
    zgui.chat[v.."tab"]:setClickCallback("zgui.chat.click",v)

    zgui.chat[v] = Geyser.Label:new({
      name = "zgui.chat."..v,
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    },zgui.chat.footer)

    zgui.chat[v.."center"] = Geyser.Label:new({
      name = "zgui.chat."..v.."center",
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    },zgui.chat[v])
  
    zgui.chat[v]:hide()
  end
  
--  -- Setup a command line prompt for the chat windows
--  zgui.chat.cmd = Geyser.CommandLine:new({
--    name = "zgui.chat.cmd", 
--    x = 0, y = "100%-40px", 
--    width = "100%", height = 40,
--    stylesheet = "border: 1px solid silver;"
--  },zgui.chat.footer)
  
  -- Create each channel window
  zgui.chat.allchat = Geyser.MiniConsole:new({
    name = "All",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.chat.Allcenter)     
  hideWindow("All")
  --zgui.chat.allchat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")

  zgui.chat.citychat = Geyser.MiniConsole:new({
    name = "City",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.chat.Citycenter)     
  hideWindow("City")
  --zgui.chat.citychat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  zgui.chat.housechat = Geyser.MiniConsole:new({
    name = "House",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.chat.Housecenter)       
  hideWindow("House")
  --zgui.chat.housechat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  zgui.chat.orderchat = Geyser.MiniConsole:new({
    name = "Order",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.chat.Ordercenter)       
  hideWindow("Order")
  --zgui.chat.orderchat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")

  zgui.chat.partychat = Geyser.MiniConsole:new({
    name = "Party",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.chat.Partycenter)       
  hideWindow("Party")
  --zgui.chat.partychat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")

  zgui.chat.clanschat = Geyser.MiniConsole:new({
    name = "Clans",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.chat.Clanscenter)       
  hideWindow("Clans")
  --zgui.chat.clanschat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  zgui.chat.tellschat = Geyser.MiniConsole:new({
    name = "Tells",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.chat.Tellscenter)         
  hideWindow("Tells")
  --zgui.chat.tellschat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  zgui.chat.marketchat = Geyser.MiniConsole:new({
    name = "Market",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.chat.Marketcenter)     
  hideWindow("Market")
  --zgui.chat.marketchat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  zgui.chat.miscchat = Geyser.MiniConsole:new({
    name = "Misc",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.chat.Misccenter)     
  hideWindow("Misc")
  --zgui.chat.miscchat:setBackgroundImage(getMudletHomeDir()..[[\Zulah GUI 3.2\Artwork\Wallpapers\slate.jpg]], "center")
  
  setFontSize("All", zgui.chatSize)
  setFontSize("City", zgui.chatSize)
  setFontSize("House", zgui.chatSize)
  setFontSize("Order", zgui.chatSize)
  setFontSize("Party", zgui.chatSize)
  setFontSize("Clans", zgui.chatSize)
  setFontSize("Tells", zgui.chatSize)
  setFontSize("Market", zgui.chatSize)
  setFontSize("Misc", zgui.chatSize)
  --zgui.chat.window:setTitle("Chat","gray")
  zgui.chat.window:show()
  
  if not table.contains(zgui.modules, "buildChat") then
    table.insert(zgui.modules, "buildChat")
  end
end

