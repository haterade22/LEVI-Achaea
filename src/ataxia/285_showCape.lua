-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > Update Windows > showCape

function zgui.showCape()
  -- update the bar
  if zgui.cape.watch < 240 then
    zgui.cape.capebar:setValue((240-zgui.cape.watch), 240)
    if zgui.cape.count > 49 then
      zgui.cape.capebar.back:setStyleSheet([[
		    border-width: 2px;
		    border-color: darkred;
		    border-style: solid;
		    border-radius: 7;
		    padding: 3px;
	    ]])
      zgui.cape.capebar:echo("<center>FULL - "..(240-zgui.cape.watch).." seconds")
    else
      zgui.cape.capebar.back:setStyleSheet([[
	  	  background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #555555, stop: 0.1 #555555, stop: 0.49 #333333, stop: 0.5 #333333, stop: 1 #555555);
		    border-width: 1px;
		    border-color: black;
		    border-style: solid;
		    border-radius: 7;
		    padding: 3px;
	    ]])
      zgui.cape.capebar:echo("<center>"..zgui.cape.count.."/50 - "..(240-zgui.cape.watch).." seconds")
    end
  elseif zgui.cape.watch == 220 then
    cecho(" == WARNING: 20 SECONDS LEFT ON CAPE ==")  
    zgui.cape.capebar:setValue((240-zgui.cape.watch), 240)
    zgui.cape.capebar:echo("<center>"..zgui.cape.count.."/50 - "..(240-zgui.cape.watch).." seconds")
  else
    zgui.clearCape()   
  end
end

function zgui.renewCape()
  zgui.cape.watch = 0
  if not zgui.cape.count then zgui.cape.count = 0 end
  zgui.cape.count = zgui.cape.count + 1
  if zgui.cape.count > 50 then zgui.cape.count = 50 end
  zgui.showCape()
  enableTimer("Deathcape Timer")
end

function zgui.clearCape()
  zgui.cape.watch = 0
  zgui.cape.count = 0
  zgui.cape.capebar:setValue(0, 240)
  disableTimer("Deathcape Timer")
    zgui.cape.capebar:echo("")
    zgui.cape.capebar.back:setStyleSheet([[
		  background-color:rgba(20,20,20,50%);
		  border-width: 1px;
		  border-color: black;
		  border-style: solid;
		  border-radius: 7;
		  padding: 3px;
	  ]])    
end

registerAnonymousEventHandler("You Died", "zgui.clearCape")
registerAnonymousEventHandler("You Starbursted", "zgui.clearCape")