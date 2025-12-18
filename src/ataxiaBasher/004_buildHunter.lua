-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > zData > zData > buildHunter

function zData.buildHunter()
  zData.hunter = {}

  --Create the hunter Adjustable
  zData.hunter.window = Adjustable.Container:new({
    name = "zgui.hunter.window",
    x = 0, y = 0,
    width = "50%",
    height = "50%",  
    adjLabelstyle = "background-color:rgba(0,40,100,100%); border: 5px inset purple;",
    buttonstyle=[[
      QLabel{ border-radius: 5px; background-color: rgba(140,140,140,100%);}
      QLabel::hover{ background-color: rgba(160,160,160,50%);}
    ]],
    buttonFontSize = 10,
    buttonsize = 15,          
  },main)

  --Create the hunter container
  zData.hunter.container = Geyser.Container:new({
    name = "zData.hunter.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zData.hunter.window)  

  --Create the hunter Console
  zData.hunter.console = Geyser.MiniConsole:new({
    name = "hunterDisplay",
    x = 0, y = 0,
    autoWrap = false,
    width = "100%",
    height = "100%",
    color="black",
    --scrollBar = true,
  },zData.hunter.container) 

  setFontSize("hunterDisplay", 9)
  zData.hunter.window:setTitle("Hunting Scrolls","gray")
  zData.hunter.window:show()

end