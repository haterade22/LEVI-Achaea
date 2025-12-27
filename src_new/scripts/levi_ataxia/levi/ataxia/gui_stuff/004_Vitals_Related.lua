--[[mudlet
type: script
name: Vitals Related
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Gui Stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function ataxiagui_vitalsElements()
	ataxiagui.balIdentifier = Geyser.Label:new({
		x = "2%", y = 5,
		width = 30, height = 30,
	}, ataxiagui.bottomContainer)
	ataxiagui.balIdentifier:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[onBal.png")]])

	ataxiagui.eqIdentifier = Geyser.Label:new({
		x = "2%", y = 35,
		width = 30, height = 30.
	}, ataxiagui.bottomContainer)
	ataxiagui.eqIdentifier:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[onBal.png")]])
--------------------------------------------------------------------------------------------------------------
	ataxiagui.healthGauge = Geyser.Gauge:new({
		name = "ataxiagui.healthGauge",
		x = "6%", y = 12,
		width = "50%", height = 16,
		fontSize = 12,
	}, ataxiagui.bottomContainer)

	ataxiagui.healthGauge.front:setStyleSheet([[
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #4a0003, stop: 0.1 #fdccce, stop: 0.49 #f7000b, stop: 0.5 #f7000b, stop: 1 #620004);
		border-top: 2px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 10;
		padding: 3px;]])
	ataxiagui.healthGauge.back:setStyleSheet([[
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 0, y2: 1,  stop: 0 #8a2f2f, stop: .25 #581111, stop: .53 #250707, stop: .84 #7e1919, stop: 1 #b17575,);
		border-width: 2px;
		border-color: black;
		border-style: solid;
		border-radius: 12;
		padding: 3px;]]) 
	ataxiagui.healthGauge:setValue(40, 100)

	ataxiagui.healthGaugeClear = Geyser.Gauge:new({
		name = "ataxiagui.healthGaugeClear",
		x = "6%", y = 12,
		width = "50%", height = 16,
		fontSize = 12,
	}, ataxiagui.bottomContainer)

	ataxiagui.healthGaugeClear.front:setStyleSheet([[ 
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 1, y2: 0, stop: 0 rgba(2,2,2,255), stop: .02 rgba(29,29,29,255),stop: .19 rgba(255,255,255,166), stop: .37 rgba(2,2,2,69), stop: .50 rgba(2,2,2,0), stop: .78 rgba(2,2,2,107), stop: .89 rgba(2,2,2,77), stop: .94 rgba(80,113,117,61), stop: .99 rgba(158,224,232,255), stop: 1 rgba(173,246,255,255));
    border: 1px solid rgba(208,208,208,100);    
		border-top: 2px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 10;
    padding: 3px;
	]])
	ataxiagui.healthGaugeClear.back:setStyleSheet([[
		background-color: transparent;
		border-width: 2px;
		border-color: black;
		border-style: solid;
		border-radius: 12;
    padding: 3px;
	]])
	ataxiagui.healthGaugeClear:setValue(100,100,"<B><left><font face = 'Merienda' color = 'white' size = '2'>".."Health: 15%".."</font></left>")

--------------------------------------------------------------------------------------------------------------
	ataxiagui.manaGauge = Geyser.Gauge:new({
		name = "ataxiagui.manaGauge",
		x = "6%", y = 42,
		width = "50%", height = 16,
		fontSize = 12,
	}, ataxiagui.bottomContainer)

	ataxiagui.manaGauge.front:setStyleSheet([[
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #12655d, stop: 0.1 #b9d8d5, stop: 0.49 #177f75, stop: 0.5 #177f75, stop: 1 #09322e);
		border-top: 0px black solid;
		border-left: 2px black solid;
		border-bottom: 1px black solid;
		border-radius: 9;
		padding: 3px;]])
	ataxiagui.manaGauge.back:setStyleSheet([[
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #7f7f7f, stop: 0.1 #000000, stop: 0.49 #000000, stop: 0.5 #191919, stop: 1 #02545f);
		border-width: 2px;
		border-color: black;
		border-style: solid;
		border-radius: 9;
		padding: 3px;
		border-top: 2px #cccccc solid;]])
	ataxiagui.manaGauge:setValue(40, 100)


	ataxiagui.manaGaugeClear = Geyser.Gauge:new({
		name = "ataxiagui.manaGaugeClear",
		x = "6%", y = 42,
		width = "50%", height = 16,
		fontSize = 12,
	}, ataxiagui.bottomContainer)
	ataxiagui.manaGaugeClear.front:setStyleSheet([[ 
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 1, y2: 0, stop: 0 rgba(2,2,2,255), stop: .02 rgba(29,29,29,255),stop: .19 rgba(255,255,255,166), stop: .37 rgba(2,2,2,69), stop: .50 rgba(2,2,2,0), stop: .78 rgba(2,2,2,107), stop: .89 rgba(2,2,2,77), stop: .94 rgba(80,113,117,61), stop: .99 rgba(158,224,232,255), stop: 1 rgba(173,246,255,255));
    border: 1px solid rgba(208,208,208,100);    
		border-top: 2px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 10;
    padding: 3px;
	]])
	ataxiagui.manaGaugeClear.back:setStyleSheet([[
		background-color: transparent;
		border-width: 2px;
		border-color: black;
		border-style: solid;
		border-radius: 12;
    padding: 3px;
	]])
	ataxiagui.manaGaugeClear:setValue(100,100,"<B><left><font face = 'Merienda' color = 'white' size = '2'>".."Mana: 15%".."</font></left>")

--------------------------------------------------------------------------------------------------------------
	ataxiagui.xpGauge = Geyser.Gauge:new({
		name = "ataxiagui.xpGauge",
		x = "3%", y = "22%",
		width = "94%", height = "56%",
		fontSize = 12,
	}, ataxiagui.topContainer)

	ataxiagui.xpGauge.front:setStyleSheet([[
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 rgba(170,0,255,255), stop: .05 rgba(179,27,255,255), stop: .23 rgba(255,255,255,166), stop: .39 rgba(170,0,255,69), stop: .51 rgba(170,0,255,0), stop: .76 rgba(170,0,255,107), stop: .96 rgba(170,0,255,255), stop: 1 rgba(170,0,255,255));
		border-top: 2px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 10;
		padding: 3px;]])
	ataxiagui.xpGauge.back:setStyleSheet([[
		background-color: background-color: QLinearGradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 rgba(145,106,183,255), stop:.7 rgba(149,125,177,255), stop:.40 rgba(126,89,163,255),stop:.65 rgba(128,2,255,255), stop:.86 rgba(140,11,226,255), stop: 1 rgba(172,26,191,255));
		border-width: 2px;
		border-color: black;
		border-style: solid;
		border-radius: 12;
		padding: 3px;]])
	ataxiagui.xpGauge:setValue(40, 100)


	ataxiagui.xpGaugeClear = Geyser.Gauge:new({
		name = "ataxiagui.xpGaugeClear",
		x = "3%", y = "22%",
		width = "94%", height = "56%",
		fontSize = 12,
	}, ataxiagui.topContainer)
	ataxiagui.xpGaugeClear.front:setStyleSheet([[ 
		background-color: QLinearGradient(x1: 0, y1: 0, x2: 1, y2: 0, stop: 0 rgba(2,2,2,255), stop: .03 rgba(29,29,29,255),stop: .11 rgba(255,255,255,166), stop: .36 rgba(2,2,2,69), stop: .47 rgba(2,2,2,0), stop: .76 rgba(2,2,2,107), stop: .84 rgba(2,2,2,77), stop: .94 rgba(80,113,117,61), stop: .99 rgba(158,224,232,255), stop: 1 rgba(173,246,255,255));
		border-top: 2px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 10;
    padding: 3px;
	]])
	ataxiagui.xpGaugeClear.back:setStyleSheet([[
		background-color: transparent;
		border-width: 2px;
		border-color: black;
		border-style: solid;
		border-radius: 12;
    padding: 3px;
	]])
	ataxiagui.xpGaugeClear:setValue(100,100,"<B><left><font face = 'Merienda' color = 'white' size = '2'>".."To next level: 15%".."</font></left>")

--------------------------------------------------------------------------------------------------------------
end

function ataxiagui_updateVitals()
  if ataxia.usegui == nil or ataxia.usegui == true then
  
    if ataxia.vitals.bal then
      ataxiagui.balIdentifier:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[onBal.png")]])
    else
      ataxiagui.balIdentifier:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[offBal.png")]])
    end

    if ataxia.vitals.eq then
      ataxiagui.eqIdentifier:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[onBal.png")]])
    else
      ataxiagui.eqIdentifier:setStyleSheet([[border-image: url("]]..ataxiagui_dir..[[offBal.png")]])
    end

    ataxiagui.healthGaugeClear:setValue(100,100,"<left><font face = 'Lucida Console' color = 'black' size = '3'>".." Health: "..ataxia.vitals.hp.."/"..ataxia.vitals.maxhp.."</font></left>")
    ataxiagui.healthGauge:setValue(ataxia.vitals.hpp, 100)

    ataxiagui.manaGaugeClear:setValue(100,100,"<left><font face = 'Lucida Console' color = 'black' size = '3'>".." Mana: "..ataxia.vitals.mp.."/"..ataxia.vitals.maxmp.."</font></left>")
    ataxiagui.manaGauge:setValue(ataxia.vitals.mpp, 100)
	
    ataxiagui.xpGaugeClear:setValue(100,100,"<left><font face = 'Lucida Console' color = 'black' size = '3'>".." >>> To next level: "..ataxia.vitals.xp.."% </font></left>")
    ataxiagui.xpGauge:setValue(ataxia.vitals.xp, 100)
	
    if ataxiaTemp.basherRooms then
      ataxiaTemp.basherBarHidden = false
      ataxiagui.basherBarClear:setValue(100,100, "<left><font face = 'Lucida Console' color = 'black' size = '3'>".." Rooms Left: "..#ataxiaBasher_path.."/"..ataxiaTemp.basherRooms.." </font></left>")
      ataxiagui.basherBar:setValue(#ataxiaBasher_path, ataxiaTemp.basherRooms)
    elseif not ataxiaTemp.basherBarHidden then
      ataxiagui.basherBar:hide()
      ataxiagui.basherBarClear:hide()
      ataxiaTemp.basherBarHidden = true
    end
 end
end