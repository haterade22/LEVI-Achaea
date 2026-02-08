function zgui.buildCape()
  zgui.cape = {}
  zgui.cape.count = 0
  --Create the cape Adjustable
  zgui.cape.window = Adjustable.Container:new({
    name = "zgui.cape.window",
    x = 0, y = 0,
    width = "50%",
    height = "50%",  
    adjLabelstyle = "background-color:rgba(50,50,50,0%);",
    buttonstyle=[[
      QLabel{ border-radius: 5px; background-color: rgba(140,140,140,100%);}
      QLabel::hover{ background-color: rgba(160,160,160,50%);}
    ]],
    buttonFontSize = 5,
    buttonsize = 10,          
  },main)
  zgui.cape.window:changeMenuStyle("dark")

  --Create the cape container
  zgui.cape.container = Geyser.Container:new({
    name = "zgui.cape.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.cape.window)  

  --Create the cape Gauge
  zgui.cape.capebar = Geyser.Gauge:new({
    name="capeDisplay",
    x="2%", y="2%",
    width="96%", height="96%",
  },zgui.cape.container) 
  zgui.cape.capebar:setValue(math.random(1,100),100)

	zgui.cape.capebar.front:setStyleSheet([[
		background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #621616, stop: 0.1 #640a0a, stop: 0.49 #8a0000, stop: 0.5 #560000, stop: 1 #260000);
		border-top: 1px DimGrey solid;
		border-left: 1px DimGrey solid;
		border-bottom: 1px DimGrey solid;
		border-radius: 7;
		padding: 3px;
	]])
	
	zgui.cape.capebar.back:setStyleSheet([[
		background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #555555, stop: 0.1 #555555, stop: 0.49 #333333, stop: 0.5 #333333, stop: 1 #555555);
		border-width: 1px;
		border-color: DimGrey;
		border-style: solid;
		border-radius: 7;
		padding: 3px;
	]])
  
  setFontSize("capeDisplay", 9)
  --zgui.cape.window:setTitle("Deathcape","gray")
  zgui.cape.window:show()
  zgui.clearCape()
  
  if not table.contains(zgui.modules, "buildCape") then
    table.insert(zgui.modules, "buildCape")
  end 
end