function zgui.buildAffs()
  zgui.afflictionSize = zgui.afflictionSize or 9
  zgui.affliction = {}

  --Create the affliction Adjustable
  zgui.affliction.window = Adjustable.Container:new({
    name = "zgui.affliction.window",
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
  zgui.affliction.window:changeMenuStyle("dark")

  --Create the affliction container
  zgui.affliction.container = Geyser.Container:new({
    name = "zgui.affliction.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.affliction.window)  

  --Create the affliction Console
  zgui.affliction.console = Geyser.MiniConsole:new({
    name = "afflictionDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.affliction.container) 

  setFontSize("afflictionDisplay", zgui.afflictionSize)
  --zgui.affliction.window:setTitle("Afflictions","gray")
  zgui.affliction.window:show()
  
  if not table.contains(zgui.modules, "buildAffs") then
    table.insert(zgui.modules, "buildAffs")
  end  
end