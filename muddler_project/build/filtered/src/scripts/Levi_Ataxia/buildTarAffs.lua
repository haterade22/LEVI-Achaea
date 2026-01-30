function zgui.buildTarAffs()
  zgui.targetAffsSize = zgui.targetAffsSize or 9
  zgui.targetaffliction = {}

  --Create the affliction Adjustable
  zgui.targetaffliction.window = Adjustable.Container:new({
    name = "zgui.targetaffliction.window",
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
  zgui.targetaffliction.window:changeMenuStyle("dark")

  --Create the targetaffliction container
  zgui.targetaffliction.container = Geyser.Container:new({
    name = "zgui.targetaffliction.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.targetaffliction.window)  

  --Create the targetaffliction Console
  zgui.targetaffliction.console = Geyser.MiniConsole:new({
    name = "targetafflictionDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.targetaffliction.container) 

  setFontSize("targetafflictionDisplay", zgui.targetAffsSize)
  --zgui.targetaffliction.window:setTitle("Target Affs","gray")
  zgui.targetaffliction.window:show()
  
  if not table.contains(zgui.modules, "buildTarAffs") then
    table.insert(zgui.modules, "buildTarAffs")
  end  
end