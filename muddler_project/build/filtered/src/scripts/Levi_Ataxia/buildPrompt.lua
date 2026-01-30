function zgui.buildPrompt()
  zgui.promptSize = zgui.promptSize or 9
  zgui.prompt = {}
  
  --Create the prompt Adjustable
  zgui.prompt.window = Adjustable.Container:new({
    name = "zgui.prompt.window",
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
  zgui.prompt.window:changeMenuStyle("dark")

  --Create the prompt container
  zgui.prompt.container = Geyser.Container:new({
    name = "zgui.prompt.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.prompt.window)  

  --Create the prompt Console
  zgui.prompt.console = Geyser.MiniConsole:new({
    name = "myPrompt",
    x = 0, y = 0,
    autoWrap = true,
    width = "100%",
    height = "100%",
    color="black",
  },zgui.prompt.container) 
 
  setFontSize("myPrompt", zgui.promptSize)
  --zgui.prompt.window:setTitle("Prompt","gray")
  zgui.prompt.window:show()  
  
  if not table.contains(zgui.modules, "buildPrompt") then
    table.insert(zgui.modules, "buildPrompt")
  end
end