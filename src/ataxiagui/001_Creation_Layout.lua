-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Gui Stuff > Creation/Layout

function ataxiagui_Create()
	winWid, winHei = getMainWindowSize()
	winHeiP = (winHei/100)
  setConsoleBufferSize("main", 2000000, 2000)
  
  if ataxia.usegui == true or ataxia.usegui == nil then
  
    ataxiagui_sep = string.char(getMudletHomeDir():byte()) == "/" and "/" or "\\"		
    ataxiagui_dir = (getMudletHomeDir()..ataxiagui_sep.."Pictures"..ataxiagui_sep):gsub("\\","/")
    ataxiagui_smallUI = false

    if winWid < 1500 then
      ataxiagui_smallUI = true
		  aBorders = {l = 200, t = 30, b = 70, r = 450}
    else
      aBorders = {l = 215, t = 30, b = 70, r = 600}
    end
    setBorderLeft(aBorders.l)
    setBorderTop(aBorders.t)
    setBorderBottom(aBorders.b)
    setBorderRight(aBorders.r)
	
	

    ataxiagui_containers()
    ataxiagui_boxes()
    ataxiagui_consoles()
    ataxiagui_createMap()
    ataxiagui_createChat()
    ataxiagui_vitalsElements()
  end
end

function ataxiagui_containers()
	--Initialise containers to hold the various elements of the GUI.
	--The labels beneath each will house the backgrounds.
	ataxiagui.leftContainer = Geyser.Container:new({
		x = 0, y = 0,
		width = aBorders.l, height = winHei,
	})
	ataxiagui.leftBG = Geyser.Label:new({
		x = 0, y = 0,
		width = "100%", height = "100%",
	}, ataxiagui.leftContainer)
	ataxiagui.leftBG:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[leftBorder.png")]])

	ataxiagui.rightContainer = Geyser.Container:new({
		x = winWid - aBorders.r, y = 0,
		width = aBorders.r, height = winHei,
	})
	ataxiagui.rightBG = Geyser.Label:new({
		x = 0, y = 0,
		width = "100%", height = "100%",
	}, ataxiagui.rightContainer)
	ataxiagui.rightBG:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[rightBorder.png")]])

	ataxiagui.topContainer = Geyser.Container:new({
		x = aBorders.l, y = 0,
		width = winWid - (aBorders.r + aBorders.l), height = aBorders.t,
	})
	ataxiagui.topBG = Geyser.Label:new({
		x = 0, y = 0,
		width = "100%", height = "100%",
	}, ataxiagui.topContainer)
	ataxiagui.topBG:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[topBorder.png")]])

	ataxiagui.bottomContainer = Geyser.Container:new({
		x = aBorders.l, y = winHei - aBorders.b,
		width = winWid - (aBorders.r + aBorders.l), height = aBorders.b,
	})
	ataxiagui.bottomBG = Geyser.Label:new({
		x = 0, y = 0,
		width = "100%", height = "100%",
	}, ataxiagui.bottomContainer)
	ataxiagui.bottomBG:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[bottomBorder.png")]])
end

function ataxiagui_boxes()
	setAppStyleSheet([[
		QScrollBar:vertical {background: #000;}
		QScrollBar::handle:vertical {background-color: #07f; min-height: 50px;}
		QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {background: none; height: 0px;}
		QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {background: none;}
		QMenuBar {background-color: #000; color: #07f;}
		QMenuBar::item:selected {background-color: #000; color: #0ff}
	]])

	ataxiagui.playersBG = Geyser.Label:new({
		x = 0, y = "6%",
		width = "100%", height = "25%",
	}, ataxiagui.leftContainer)
	ataxiagui.playersBG:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[ataxiaBorder.png")]])

	ataxiagui.roomBG = Geyser.Label:new({
		x = 0, y = "35%",
		width = "100%", height = "25%",
	}, ataxiagui.leftContainer)
	ataxiagui.roomBG:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[ataxiaBorder.png")]])

	ataxiagui.bashBG = Geyser.Label:new({
		x = 0, y = "65%",
		width = "100%", height = "30%",
	}, ataxiagui.leftContainer)
	ataxiagui.bashBG:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[ataxiaBorder.png")]])
end

function ataxiagui_consoles()
	ataxiagui.playersConsole = Geyser.MiniConsole:new({
		x = "7%", y = (winHeiP*7)+5,
		width = "86%", height = "22%",
		color = "black",
	}, ataxiagui.leftContainer)

	ataxiagui.roomConsole = Geyser.MiniConsole:new({
		x = "7%", y = (winHeiP*36)+5,
		width = "86%", height = "22%",
		color = "black",
	}, ataxiagui.leftContainer)

	ataxiagui.bashConsole = Geyser.MiniConsole:new({
		x = "7%", y = (winHeiP*66)+5,
		width = "86%", height = "26%",
		color = "black",
	}, ataxiagui.leftContainer)
end

registerAnonymousEventHandler("ataxia system loaded", "ataxiagui_Create")