-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > zData > zData > movement

-------------------------------------------------
--                                             --
--               zData.movement()              --
--  This Function Runs Everytime Room Updates  --
--                                             --
-------------------------------------------------
function zData.movement() 
-----------------------------------------------------------------------------------------------
-- Update Area    
  if gmcp.Room.Info.area ~= zData.char.lastArea then  -------------<--<--< Zone Change Detected

-----------------------------------------------------------------------------------------------
-- Collect experience percent from gmcp, check old xp (zData.char.oxp)
    if string.match(gmcp.Char.Status.xp, "%d+.%d+") then
      zData.char.xp = tonumber(string.match(gmcp.Char.Status.xp, "%d+.%d+"))
    elseif string.match(gmcp.Char.Status.xp, "%d+") then
      zData.char.xp = tonumber(string.match(gmcp.Char.Status.xp, "%d+"))
    end
    if zData.char.oxp == 0 then zData.char.oxp = zData.char.xp end

-----------------------------------------------------------------------------------------------
-- If your exp is not = to your old exp AND you have been in a zone FOR MORE > THAN 60 SECONDS
    if (zData.char.oxp ~= zData.char.xp or zData.char.killsCount > 0) and getStopWatchTime("zoneHuntWatch") > 60 then
      stopStopWatch("zoneHuntWatch")  

-----------------------------------------------------------------------------------------------
-- Update zData.Character Variables used for saving to the Database
      zData.char.tempTime = getStopWatchTime("zoneHuntWatch")
      zData.char.minuteTime = zData.char.tempTime/60
      zData.char.xpGains = zData.char.xp-zData.char.oxp
      zData.char.xpGainsMin = zData.char.xpGains/zData.char.minuteTime
      zData.char.killsPerMinute = zData.char.killsCount/zData.char.minuteTime
      zData.char.gpm = zData.char.gold/zData.char.minuteTime

-----------------------------------------------------------------------------------------------
-- Convert tables to strings for the database (will turn back to tables when pulled)
      zData.char.killListString = nil
      if #zData.char.killList > 0 then
        zData.char.killListString = table.concat(zData.char.killList, "| ")
      end
      zData.char.taliListString = nil
      if #zData.char.taliList > 0 then
        zData.char.taliListString = table.concat(zData.char.taliList, "| ")
      end

-----------------------------------------------------------------------------------------------
-- Record when this happened with Epoch time
      zData.char.when = getEpoch()
      
-----------------------------------------------------------------------------------------------
-- Send All information to database   
      zData.db.zoneAdd(
        zData.char.lastArea,
        gmcp.Char.Status.class, 
        zData.defs.exp, 
        zData.defs.crit, 
        zData.char.tempTime, 
        zData.char.xpGainsMin, 
        zData.char.xpGains, 
        zData.char.killsCount, 
        zData.char.killsPerMinute, 
        zData.char.gold, 
        zData.char.gpm, 
        zData.char.str, 
        zData.char.dex, 
        zData.char.int, 
        zData.char.con, 
        zData.char.totalAttacks, 
        zData.char.crithits, zData.char.crit1, zData.char.crit2, zData.char.crit3, zData.char.crit4, zData.char.crit5, zData.char.crit6, 
        zData.char.shield, 
        zData.char.paragon, 
        zData.char.searedglyph, 
        zData.char.mayafigure, 
        zData.char.taliCount, 
        zData.char.killListString, 
        zData.char.taliListString,
        zData.char.when
        )
    end

-----------------------------------------------------------------------------------------------
-- Reset all saved data for next area
    zData.char = {
      lastArea = gmcp.Room.Info.area,
      tempTime = 0,
      minuteTime = 0,
      xpGains = 0,
      xpGainsMin = 0,
      killsPerMinute = 0, 
      killsCount = 0,
      taliCount = 0,
      ogold = gmcp.Char.Status.gold,
      gold = 0,
      gpm = 0,
      totalAttacks = 0,
      crithits = 0,
      crit1 = 0,
      crit2 = 0,
      crit3 = 0,
      crit4 = 0,
      crit5 = 0,
      crit6 = 0,
      searedglyph = 0,
      shield = 0,
      paragon = 0,
      mayafigure = 0,     
      killList = {},
      taliList = {},
      when= 0,
    }

-----------------------------------------------------------------------------------------------
-- Save OLD experience for new zone    
    if string.match(gmcp.Char.Status.xp, "%d+.%d+") then
      zData.char.oxp = tonumber(string.match(gmcp.Char.Status.xp, "%d+.%d+"))
    elseif string.match(gmcp.Char.Status.xp, "%d+") then
      zData.char.oxp = tonumber(string.match(gmcp.Char.Status.xp, "%d+"))
    end

-----------------------------------------------------------------------------------------------
-- Reset and Start Stopwatch for this zone (always running / only resets here on zone change)
    resetStopWatch("zoneHuntWatch")
    startStopWatch("zoneHuntWatch") 
	end  
end
-----------------------------------------------------------------------------------------------
registerAnonymousEventHandler("gmcp.Room.Info", "zData.movement") ---<--< Run When Room Updates
-----------------------------------------------------------------------------------------------