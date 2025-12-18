-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > Mapper > buildMap

function zgui.buildMap()
  zgui.mapSize = zgui.mapSize or 9
  zgui.map = {}
  zgui.map.tabs = {"Wilderness","Ocean","Mapper"}
  zgui.map.color1 = "rgb(218,218,218)"
  zgui.map.color2 = "rgb(0,0,0)"
  zgui.map.color3 = "rgb(150,150,150)"
  zgui.map.width = "100%"
  zgui.map.height = "100%"
  zgui.map.current = zgui.map.tabs[3]

  --Create the Adjustable container
  --Our tabbed window will need a container. This will be the bottom layer. Containers are invisible so no need to set a stylesheet. 
  zgui.map.window = Adjustable.Container:new({
    name = "zgui.map.window",
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
  zgui.map.window:changeMenuStyle("dark")

  --Create the main container
  zgui.map.container = Geyser.Container:new({
    name = "zgui.map.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.map.window)
  
 --Create an HBox
 --All of our tabs will be evenly spaced. So we'll create an HBox to sit at the top of our container. 
 zgui.map.header = Geyser.HBox:new({
    name = "zgui.map.header",
    x = 0, y = 0,
    width = "100%",
    height = "0%",
  },zgui.map.container)  
  setBackgroundColor("zgui.map.header", 0,0,0,255) 
  
  --Create a label
  --This label will serve as a container for each window. It sits right underneath the HBox we just created for the tabs. 
  zgui.map.footer = Geyser.Label:new({
    name = "zgui.map.footer",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  },zgui.map.container)
  
  --Each window actually has two labels. One for the light blue background, and another for the dark blue center. This will create that dark blue center.
  zgui.map.center = Geyser.Label:new({
    name = "zgui.map.center",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  },zgui.map.footer)

    zgui.map.Mapper = Geyser.Label:new({
      name = "zgui.map.Mapper",
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    },zgui.map.footer)
    zgui.map["Mappercenter"] = Geyser.Label:new({
      name = "zgui.map.Mappercenter",
      x = 0, y = 0,
      width = "100%",
      height = "100%",
      bgColor = "black",
    },zgui.map.Mapper)
    zgui.map.Mapper:hide()

    zgui.map.Wilderness = Geyser.Label:new({
      name = "zgui.map.Wilderness",
        x = 0, y = 0,
      width = "100%",
      height = "100%",
    },zgui.map.footer)
    zgui.map["Wildernesscenter"] = Geyser.Label:new({
      name = "zgui.map.Wildernesscenter",
      x = 0, y = 0,
      width = "100%",
      height = "100%",
      bgColor = "black",
    },zgui.map.Wilderness)
    zgui.map.Wilderness:hide()  
    
    zgui.map.Ocean = Geyser.Label:new({
      name = "zgui.map.Ocean",
      x = 0, y = 0,
      width = "100%",
      height = "100%",
      bgColor = "black",
    },zgui.map.footer)
    zgui.map["Oceancenter"] = Geyser.Label:new({
      name = "zgui.map.Oceancenter",
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    },zgui.map.Ocean)
    zgui.map.Ocean:hide()     
  
  zgui.map.mapperWindow = Geyser.Mapper:new({
    name = "Mapper",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  },zgui.map.Mappercenter)
  showWindow("Mapper")
  
  zgui.map.oceanWindow = Geyser.MiniConsole:new({
    name = "Ocean",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  },zgui.map.Oceancenter)  
  setBackgroundColor("Ocean", 0,0,0,255)
  hideWindow("Ocean")
 
  zgui.map.wildernessWindow = Geyser.MiniConsole:new({
    name = "Wilderness",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  },zgui.map.Wildernesscenter)  
  setBackgroundColor("Wilderness", 0,0,0,255)  
  hideWindow("Wilderness")

  setFontSize("Ocean", zgui.mapSize)
  setFontSize("Wilderness", zgui.mapSize)
  zgui.map.window:setTitle("Map","gray")
  zgui.map.window:show()  
  
  if not table.contains(zgui.modules, "Map") then
    table.insert(zgui.modules, "Map")
  end
end