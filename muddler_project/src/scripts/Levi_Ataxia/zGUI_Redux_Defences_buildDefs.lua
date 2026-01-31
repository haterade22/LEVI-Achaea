function zgui.buildDefence()
  zgui.defenceSize = zgui.defenceSize or 9
  zgui.defence = {}

  --Create the defence Adjustable
  zgui.defence.window = Adjustable.Container:new({
    name = "zgui.defence.window",
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
  zgui.defence.window:changeMenuStyle("dark")

  --Create the defence container
  zgui.defence.container = Geyser.Container:new({
    name = "zgui.defence.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.defence.window)  

  --Create the defence Console
  zgui.defence.console = Geyser.MiniConsole:new({
    name = "defenceDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.defence.container) 

  setFontSize("defenceDisplay", zgui.defenceSize)
  zgui.defence.window:setTitle("Defences","gray")
  zgui.defence.window:show()
  
  if not table.contains(zgui.modules, "Defence") then
    table.insert(zgui.modules, "Defence")
  end  
end