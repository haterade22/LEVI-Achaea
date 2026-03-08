--[[mudlet
type: script
name: movement
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Basher
- ataxia.data
- ataxia.data
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Basher > ataxia.data > ataxia.data > movement

-------------------------------------------------
--                                             --
--         ataxia.data.getClassWithSpec()            --
--  Format class name with knight spec         --
--                                             --
-------------------------------------------------
function ataxia.data.getClassWithSpec()
  local class = gmcp.Char.Status.class
  local spec = ataxia.vitals.knight

  -- Knight class abbreviations
  local knightAbbrev = {
    ["Infernal"] = "Inf",
    ["Runewarden"] = "Run",
    ["Paladin"] = "Pal",
    ["Unnamable"] = "Unn"
  }

  -- Spec abbreviations
  local specAbbrev = {
    ["Dual Cutting"] = "DWC",
    ["Dual Blunt"] = "DWB",
    ["Sword and Shield"] = "S&B",
    ["Two-Handed"] = "2H"
  }

  -- If knight class with known spec, format as "Abbrev - Spec"
  if knightAbbrev[class] and spec and specAbbrev[spec] then
    return knightAbbrev[class] .. " - " .. specAbbrev[spec]
  end

  -- Otherwise return original class name
  return class
end

-------------------------------------------------
--                                             --
--               ataxia.data.movement()              --
--  This Function Runs Everytime Room Updates  --
--                                             --
-------------------------------------------------
function ataxia.data.movement() 
-----------------------------------------------------------------------------------------------
-- Update Area    
  if gmcp.Room.Info.area ~= ataxia.data.char.lastArea then  -------------<--<--< Zone Change Detected

-----------------------------------------------------------------------------------------------
-- Collect experience percent from gmcp, check old xp (ataxia.data.char.oxp)
    if string.match(gmcp.Char.Status.xp, "%d+.%d+") then
      ataxia.data.char.xp = tonumber(string.match(gmcp.Char.Status.xp, "%d+.%d+"))
    elseif string.match(gmcp.Char.Status.xp, "%d+") then
      ataxia.data.char.xp = tonumber(string.match(gmcp.Char.Status.xp, "%d+"))
    end
    if ataxia.data.char.oxp == 0 then ataxia.data.char.oxp = ataxia.data.char.xp end

-----------------------------------------------------------------------------------------------
-- If your exp is not = to your old exp AND you have been in a zone FOR MORE > THAN 60 SECONDS
    if (ataxia.data.char.oxp ~= ataxia.data.char.xp or ataxia.data.char.killsCount > 0) and getStopWatchTime("zoneHuntWatch") > 60 then
      stopStopWatch("zoneHuntWatch")  

-----------------------------------------------------------------------------------------------
-- Update ataxia.data.Character Variables used for saving to the Database
      ataxia.data.char.tempTime = getStopWatchTime("zoneHuntWatch")
      ataxia.data.char.minuteTime = ataxia.data.char.tempTime/60
      ataxia.data.char.xpGains = ataxia.data.char.xp-ataxia.data.char.oxp
      ataxia.data.char.xpGainsMin = ataxia.data.char.xpGains/ataxia.data.char.minuteTime
      ataxia.data.char.killsPerMinute = ataxia.data.char.killsCount/ataxia.data.char.minuteTime
      ataxia.data.char.gpm = ataxia.data.char.gold/ataxia.data.char.minuteTime

-----------------------------------------------------------------------------------------------
-- Convert tables to strings for the database (will turn back to tables when pulled)
      ataxia.data.char.killListString = nil
      if #ataxia.data.char.killList > 0 then
        ataxia.data.char.killListString = table.concat(ataxia.data.char.killList, "| ")
      end
      ataxia.data.char.taliListString = nil
      if #ataxia.data.char.taliList > 0 then
        ataxia.data.char.taliListString = table.concat(ataxia.data.char.taliList, "| ")
      end

-----------------------------------------------------------------------------------------------
-- Record when this happened with Epoch time
      ataxia.data.char.when = getEpoch()
      
-----------------------------------------------------------------------------------------------
-- Send All information to database   
      ataxia.data.db.zoneAdd(
        ataxia.data.char.lastArea,
        ataxia.data.getClassWithSpec(), 
        ataxia.data.defs.exp, 
        ataxia.data.defs.crit, 
        ataxia.data.char.tempTime, 
        ataxia.data.char.xpGainsMin,
        ataxia.data.char.xpGains,
        ataxia.data.char.rawExpGains,
        ataxia.data.char.killsCount, 
        ataxia.data.char.killsPerMinute, 
        ataxia.data.char.gold, 
        ataxia.data.char.gpm, 
        ataxia.data.char.str, 
        ataxia.data.char.dex, 
        ataxia.data.char.int, 
        ataxia.data.char.con, 
        ataxia.data.char.totalAttacks, 
        ataxia.data.char.crithits, ataxia.data.char.crit1, ataxia.data.char.crit2, ataxia.data.char.crit3, ataxia.data.char.crit4, ataxia.data.char.crit5, ataxia.data.char.crit6, 
        ataxia.data.char.shield, 
        ataxia.data.char.paragon, 
        ataxia.data.char.searedglyph, 
        ataxia.data.char.mayafigure, 
        ataxia.data.char.taliCount, 
        ataxia.data.char.killListString, 
        ataxia.data.char.taliListString,
        ataxia.data.char.when
        )
    end

-----------------------------------------------------------------------------------------------
-- Reset all saved data for next area
    ataxia.data.char = {
      lastArea = gmcp.Room.Info.area,
      tempTime = 0,
      minuteTime = 0,
      xpGains = 0,
      xpGainsMin = 0,
      rawExpGains = 0,
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
      ataxia.data.char.oxp = tonumber(string.match(gmcp.Char.Status.xp, "%d+.%d+"))
    elseif string.match(gmcp.Char.Status.xp, "%d+") then
      ataxia.data.char.oxp = tonumber(string.match(gmcp.Char.Status.xp, "%d+"))
    end

-----------------------------------------------------------------------------------------------
-- Reset and Start Stopwatch for this zone (always running / only resets here on zone change)
    resetStopWatch("zoneHuntWatch")
    startStopWatch("zoneHuntWatch") 
	end  
end
-----------------------------------------------------------------------------------------------
registerAnonymousEventHandler("gmcp.Room.Info", "ataxia.data.movement") ---<--< Run When Room Updates
-----------------------------------------------------------------------------------------------