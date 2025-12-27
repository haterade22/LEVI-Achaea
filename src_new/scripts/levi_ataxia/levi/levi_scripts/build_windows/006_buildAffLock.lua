--[[mudlet
type: script
name: buildAffLock
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

function zgui.buildAffLock()
  zgui.afflictionlock = {}

  --Create the afflictionlock Adjustable
  zgui.afflictionlock.window = Adjustable.Container:new({
    name = "zgui.afflictionlock.window",
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
  zgui.afflictionlock.window:changeMenuStyle("dark")

  --Create the afflictionlock container
  zgui.afflictionlock.container = Geyser.Container:new({
    name = "zgui.afflictionlock.back",
    x = 0, y = 0,
    width = "100%",
    height = "100%",        
  },zgui.afflictionlock.window)  

  --zgui.afflictionlock.window:setTitle("Lock Out","gray")
  zgui.afflictionlock.window:show()

	zgui.afflictionlock.bg = Geyser.Label:new({
		name = "afflictionlockBG",
		color = "black",
		x = 0,	y = 0,
		width = 0,	height = 0
	}, zgui.afflictionlock.container)
  setBackgroundColor("afflictionlockBG", 0, 0, 0, 255)

---------------------------------------------------------------------------

	zgui.afflictionlock.pronLabel = Geyser.Label:new({
		name = "pronAff",
		x = "1%", y = "2%",
		width = "98%", height = "18%",
	}, zgui.afflictionlock.container)
	setBackgroundColor("pronAff", 80, 0, 0, 255)
	zgui.afflictionlock.pronLabel:echo("<center>Prone")	

	zgui.afflictionlock.paraLabel = Geyser.Label:new({
		name = "paraAff",
		x = "1%", y = "22%",
		width = "18%", height = "70%",
	}, zgui.afflictionlock.container)
	setBackgroundColor("paraAff", 80, 0, 0, 255)
	zgui.afflictionlock.paraLabel:echo("<center>Para")

	zgui.afflictionlock.impaLabel = Geyser.Label:new({
		name = "impaAff",
		x = "21%", y = "22%",
		width = "18%", height = "70%",
	}, zgui.afflictionlock.container)
	setBackgroundColor("impaAff", 80, 0, 0, 255)
	zgui.afflictionlock.impaLabel:echo("<center>Imp")
	
	zgui.afflictionlock.asthLabel = Geyser.Label:new({
		name = "asthAff",
		x = "41%", y = "22%",
		width = "18%", height = "70%",
	}, zgui.afflictionlock.container)
	setBackgroundColor("asthAff", 80, 0, 0, 255)
	zgui.afflictionlock.asthLabel:echo("<center>Ast")
	
	zgui.afflictionlock.anorLabel = Geyser.Label:new({
		name = "anorAff",
		x = "61%", y = "22%",
		width = "18%", height = "70%",
	}, zgui.afflictionlock.container)
	setBackgroundColor("anorAff", 80, 0, 0, 255)
	zgui.afflictionlock.anorLabel:echo("<center>Ano")
	
	zgui.afflictionlock.slicLabel = Geyser.Label:new({
		name = "slicAff",
		x = "81%", y = "22%",
		width = "18%", height = "70%",
	}, zgui.afflictionlock.container)
	setBackgroundColor("slicAff", 80, 0, 0, 255)
	zgui.afflictionlock.slicLabel:echo("<center>Sli")
  
  if not table.contains(zgui.modules, "buildAffLock") then
    table.insert(zgui.modules, "buildAffLock")
  end  
end