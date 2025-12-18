-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > zGUI Redux > EDIT ME: Startup Main

-------------------------------------------------
-- Zulah GUI build 
-- 11/4/20
-- v3.2.2
-- convert Adjustable.Containers to UserWindows and back
-- v0.1
-- Note: saving if UserWindow won't bring back as UserWindow if reloading
-- by Edru 7th October 2020
-------------------------------------------------

function zgui.zStartup() 
 if not zgui.running then
  zgui.running = true
--------------------------------------------------------------------
-- Change the Font Size of each window on startup to fit your screen size better if needed
  zgui.chatSize = 9
  zgui.loggerSize = 8
  zgui.promptSize = 8
  zgui.goldSize = 8
  zgui.defenceSize = 8
  zgui.afflictionSize = 8
  zgui.targetAffsSize = 9
  zgui.targetListSize = 8
  zgui.enemySize = 8
  zgui.allySize = 8
  zgui.roomDenizensSize = 7
  zgui.roomItemsSize = 7
  zgui.roomPlayersSize = 10
  zgui.mapSize = 8
  zgui.bashWindowSize = 7
  zgui.statsWindowSize = 8
  zgui.roomInfoSize = 8
--------------------------------------------------------------------
  setBorderColor("0","0","0")  -- Change this if you attach windows to side borders and want to color the background of those borders
                               -- setBorderColor("218","218","218") -- Mudlet Default Menu Grey
                               -- setBorderColor("RED","GREEN","BLUE")
--------------------------------------------------------------------       
-- Which Style To Start With?  
  if not zgui.useStyle then zgui.useStyle = "darkmode" end                        
  for k,v in pairs(zgui.styles) do
    if zgui.useStyle == k then
      zgui.adjLabelstyle = v
    end
  end   
----------------------------------------------------------------------------------------------------------------------------------------

    sendGMCP([[Core.Supports.Add ["Comm.Channel 1"] ]])
    sendGMCP('Core.Supports.Add ["IRE.Tasks 1"]')
    sendGMCP('Core.Supports.Add ["IRE.Time 1"]')
    sendGMCP('Core.Supports.Add ["IRE.Misc 1"]')
    sendGMCP('Core.Supports.Add ["IRE.Display 1"]')
    sendGMCP('Core.Supports.Add ["IRE.Sound 1"]')
    
    --If you want to enable one of these modules, simply remove the -- at the start.
    --Use zgui afterwards to redraw the gui, this does not require restarting.
    --A few modules have been removed entirely from Zulah's release, as I found these unnecessary.
    
    if not table.contains(zgui.modules, "buildChat") then table.insert(zgui.modules, "buildChat") end
    if not table.contains(zgui.modules, "buildMap") then  table.insert(zgui.modules, "buildMap") end  
    --if not table.contains(zgui.modules, "buildExp") then table.insert(zgui.modules, "buildExp") end
    --if not table.contains(zgui.modules, "buildLog") then table.insert(zgui.modules, "buildLog") end
    --if not table.contains(zgui.modules, "buildPrompt") then table.insert(zgui.modules, "buildPrompt") end
    --if not table.contains(zgui.modules, "buildAlly") then table.insert(zgui.modules, "buildAlly") end
    --if not table.contains(zgui.modules, "buildEnemy") then table.insert(zgui.modules, "buildEnemy") end
    --if not table.contains(zgui.modules, "buildBashWindow") then table.insert(zgui.modules, "buildBashWindow") end
    --if not table.contains(zgui.modules, "buildAffs") then table.insert(zgui.modules, "buildAffs") end
    --if not table.contains(zgui.modules, "buildAffLock") then table.insert(zgui.modules, "buildAffLock") end
    if not table.contains(zgui.modules, "buildTarAffs") then table.insert(zgui.modules, "buildTarAffs") end
    if not table.contains(zgui.modules, "buildRoomPlayers") then table.insert(zgui.modules, "buildRoomPlayers") end
    if not table.contains(zgui.modules, "buildRoomDenizens") then table.insert(zgui.modules, "buildRoomDenizens") end
    --if not table.contains(zgui.modules, "buildStatsWindow") then table.insert(zgui.modules, "buildStatsWindow") end
    --if not table.contains(zgui.modules, "buildRoomInfo") then table.insert(zgui.modules, "buildRoomInfo") end
    
    for i=1, #zgui.modules, 1 do
      zgui[zgui.modules[i]]()
    end
    ------------------------------------------------------------------------
    zgui.debug = false
    zgui.trueTime = 0

	  zgui.vitals = {
 		  h = 5000,
 		  m = 5000,
 		  maxh = 5000,
 	 	  maxm = 5000,
  		oh = 5000, --old health
  		om = 5000, --old mana
 	  	xp = 0,
   		oxp = 0, --old xp
	  }
    zgui.myTargetList = zgui.myTargetList or {} 
	  zgui.allies = zgui.allies or {}
	  zgui.enemies = zgui.enemies or {}
  
    send("ql")    
    send("allies")
    send("enemies")
    ------------------------------------------------------------------------
    setAppStyleSheet([[
		  QScrollBar:vertical {background: #000;}
		  QScrollBar::handle:vertical {background-color: #07f; min-height: 50px;}
		  QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {background: none; height: 0px;}
		  QScrollBar::add-page:vertical, QScrollBar::sub-page:vertical {background: none;}
		  QMenuBar {background-color: #000; color: #07f;}
		  QMenuBar::item:selected {background-color: #000; color: #0ff}
	 ]])
 end
end

registerAnonymousEventHandler("gmcp.Char", "zgui.zStartup")