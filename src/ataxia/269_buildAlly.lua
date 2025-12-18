-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > Build Windows > buildAlly

function zgui.buildAlly()
  zgui.allySize = zgui.allySize or 9
  zgui.ally = {}

  --Create the ally Adjustable
  zgui.ally.window = Adjustable.Container:new({
    name = "zgui.ally.window",
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
  zgui.ally.window:changeMenuStyle("dark")

  --Create the ally container
  zgui.ally.container = Geyser.Container:new({
    name = "zgui.ally.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.ally.window)  

  --Create the ally Console
  zgui.ally.console = Geyser.MiniConsole:new({
    name = "allyDisplay",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.ally.container) 

  setFontSize("allyDisplay", zgui.allySize)
  --zgui.ally.window:setTitle("Allies","gray")
  zgui.ally.window:show()
  
  if not table.contains(zgui.modules, "buildAlly") then
    table.insert(zgui.modules, "buildAlly")
  end  
end