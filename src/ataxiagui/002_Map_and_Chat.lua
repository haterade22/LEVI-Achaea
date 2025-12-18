-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Gui Stuff > Map and Chat

function ataxiagui_createMap()
	if ataxiagui_smallUI then
		ataxiagui_createSmallMap()
		return
	end

	ataxiagui.mapBG = Geyser.Label:new({
		x = 120, y = "5%",
		width = 360, height = "32%",
	}, ataxiagui.rightContainer)
	ataxiagui.mapBG:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[ataxiaBorder.png")]])

	ataxiagui.mapper = Geyser.Mapper:new({
		x = 145, y = "7%",
		width = 310, height = "28%",
	}, ataxiagui.rightContainer)

	ataxiagui.mapRoom = Geyser.Label:new({
		x = 110, y = "1%",
		width = 380, height = "3%",
	}, ataxiagui.rightContainer)
	ataxiagui.mapRoom:setStyleSheet([[
		background-color: transparent;
    		border-width: 2px;
    		border-color: transparent;
    		border-style: solid;
    		border-radius: 14;
    		padding: 3px;
	]])
	ataxiagui.mapRoom:echo([[<p style="font-size:12px"><center><font color="NavajoWhite"><font face="Merienda">]].."Room Area"..[[</font></p>]] )

	ataxiagui.mapExits = Geyser.Label:new({
		x = 110, y = "4%",
		width = 380, height = "3%",
	}, ataxiagui.rightContainer)
	ataxiagui.mapExits:setStyleSheet([[
		background-color: transparent;
    		border-width: 2px;
    		border-color: transparent;
    		border-style: solid;
    		border-radius: 14;
    		padding: 3px;
	]])
	ataxiagui.mapExits:echo([[<p style="font-size:12px"><center><font color="NavajoWhite"><font face="Merienda">]].."Room Exits"..[[</font></p>]] )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	ataxiagui.basherBar = Geyser.Gauge:new({
		name = "ataxiagui.basherBar",
		x = 150, y = "38%",
		width = 300, height = "2%",
		fontSize = 12,
	}, ataxiagui.rightContainer)

	ataxiagui.basherBar.front:setStyleSheet([[
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #f1f34e, stop: 0.1 #eef022, stop: 0.49 #a5db67, stop: 0.5 #a5db67, stop: 1 #5e5e19);
		border-top: 2px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 10;
		padding: 3px;]])
	ataxiagui.basherBar.back:setStyleSheet([[
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #f8f9a6, stop: 0.1 #bec01b, stop: 0.49 #777811, stop: 0.5 #777811, stop: 1 #2f3006);
		border-width: 2px;
		border-color: black;
		border-style: solid;
		border-radius: 12;
		padding: 3px;]]) 
	ataxiagui.basherBar:setValue(40, 100)
	ataxiagui.basherBar:hide()
	
	ataxiagui.basherBarClear = Geyser.Gauge:new({
		name = "ataxiagui.basherBarClear",
		x = 150, y = "38%",
		width = 300, height = "2%",
		fontSize = 12,
	}, ataxiagui.rightContainer)

	ataxiagui.basherBarClear.front:setStyleSheet([[ 
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 1, y2: 0, stop: 0 rgba(2,2,2,255), stop: .02 rgba(29,29,29,255),stop: .19 rgba(255,255,255,166), stop: .37 rgba(2,2,2,69), stop: .50 rgba(2,2,2,0), stop: .78 rgba(2,2,2,107), stop: .89 rgba(2,2,2,77), stop: .94 rgba(80,113,117,61), stop: .99 rgba(158,224,232,255), stop: 1 rgba(173,246,255,255));
    border: 1px solid rgba(208,208,208,100);    
		border-top: 2px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 10;
    padding: 3px;
	]])
	ataxiagui.basherBarClear.back:setStyleSheet([[
		background-color: transparent;
		border-width: 2px;
		border-color: black;
		border-style: solid;
		border-radius: 12;
    padding: 3px;
	]])
	ataxiagui.basherBarClear:setValue(100,100,"<B><left><font face = 'Merienda' color = 'white' size = '2'>".."Rooms".."</font></left>")
	ataxiagui.basherBarClear:hide()
end

function ataxiagui_chatSelect(tab)
	local current = ataxiagui.Chat.current
	ataxiagui.Chat[current]:hide()
	ataxiagui.Chat[current.."tab"]:echo([[<p style="font-size:12px"><center><font color="red"><font face="Merienda">]]..current..[[</font></p>]] )

	ataxiagui.Chat.current = tab
	current = ataxiagui.Chat.current
	ataxiagui.Chat[current]:show()
	ataxiagui.Chat[current.."tab"]:echo([[<p style="font-size:12px"><center><font color="green"><font face="Merienda">]]..current..[[</font></p>]] )

end

function ataxiagui_createChat()
	if ataxiagui_smallUI then
		ataxiagui_createSmallChat()
		return
	end

	ataxiagui.Chat = {}
	ataxiagui.chatBG = Geyser.Label:new({
		x = 65, y = "42%",
		width = 470, height = "57%",
	}, ataxiagui.rightContainer)
	ataxiagui.chatBG:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[ataxiaBorder.png")]])

	ataxiagui.Chat = {
		tabs = {"All", "City", "Clans" ,"Misc", "Order", "Party", "Tells"},
		colour1 = "DarkGreen",
		colour2 = "black",
		current = "",
		wrapWidth = math.floor(411/7)
	}

	ataxiagui.Chat.container = Geyser.Container:new({
		x = 93, y = "45%",
		width = 411, height = "51%",
	}, ataxiagui.rightContainer)

	ataxiagui.Chat.header = Geyser.HBox:new({
		name = "ataxiagui.Chat.header",
		x = 0, y = 0,
		width = "100%", height = "4%"
	}, ataxiagui.Chat.container)

	ataxiagui.Chat.footer = Geyser.Label:new({
		name = "ataxiagui.Chat.footer",
		x = 0, y = "4%",
		width = "100%", height = "96%"
	}, ataxiagui.Chat.container)
	ataxiagui.Chat.footer:setStyleSheet([[
		background-color: black;
		border-color: black;
		border-bottom-left-radius: 8px;
		border-bottom-right-radius: 8px;
	]])

	ataxiagui.Chat.center = Geyser.Label:new({
		name = "ataxiagui.Chat.center",
		x = 0, y = 0,
		width = "100%", height = "100%",
	}, ataxiagui.Chat.footer)
	ataxiagui.Chat.center:setStyleSheet([[
		background-color: black;
		border-color: black;
		border-radius: 8px;
		margin: 5px;]])

	for _, sec in pairs(ataxiagui.Chat.tabs) do
		--The individual tabs
		ataxiagui.Chat[sec.."tab"] = Geyser.Label:new({
			name = "ataxiagui.Chat."..sec.."tab"
		}, ataxiagui.Chat.header)
		ataxiagui.Chat[sec.."tab"]:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[chatTab.png")]])
		ataxiagui.Chat[sec.."tab"]:echo([[<p style="font-size:12px"><center><font color="red"><font face="Merienda">]]..sec..[[</font></p>]] )
		ataxiagui.Chat[sec.."tab"]:setClickCallback("ataxiagui_chatSelect", sec)

		--Windows where the consoles are placed
		ataxiagui.Chat[sec] = Geyser.Label:new({
			name = "ataxiagui.Chat."..sec,
			x = 0, y = 0,
			width = "100%", height = "100%"
		}, ataxiagui.Chat.footer)
		ataxiagui.Chat[sec]:setStyleSheet([[
			background-color: black;
			border-bottom-left-radius: 5px;
			border-bottom-right-radius: 5px
		]])
	
		--Consoles where the text is placed
		ataxiagui.Chat[sec.."center"] = Geyser.MiniConsole:new({
			name = "ataxiagui.Chat."..sec.."center",
			x = "1%", y = "1%",
			width = "98%", height = "98%",
			color = "black",
      autoWrap = true,
		}, ataxiagui.Chat[sec])
		ataxiagui.Chat[sec.."center"]:setFontSize(8)
		--ataxiagui.Chat[sec.."center"]:setWrap(ataxiagui.Chat.wrapWidth)
		ataxiagui.Chat[sec]:hide()
	end
	ataxiagui.Chat.current = "All"
	ataxiagui.Chat.All:show()
	ataxiagui.Chat.Alltab:echo([[<p style="font-size:12px"><center><font color="green"><font face="Merienda">]].."All"..[[</font></p>]] )
end