--[[mudlet
type: trigger
name: Bloodroot TEST
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Herbs
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) eats a (magnesium chip|bloodroot leaf).$
  type: 1
]]--

if matches[2] == target and tBals.plant then
tdeliverance = false
    if anorexiaFailsafe then
        tAffs[lastFocus] = true
        ataxiaEcho("Backtracked anorexia being cured with last focus.")
        anorexiaFailsafe = nil
        lastFocus = nil
    end
    -- Track for adaptive serpent offense
    if serpent and serpent.trackCure then serpent.trackCure("bloodroot") end
    
    if tAffs.prone then
      tempTimer(0.3, [[
                if not tAffs.prone then
                    ataxiaEcho("Backtracked paralysis being cured.")
                    erAff("paralysis")
                    tarAffed("slickness")
                else
                    ataxiaEcho("Backtracked slickness being cured.")
                    erAff("slickness")
                    tarAffed("paralysis")
                end
            ]])
        else
            if tAffs.paralysis then
                erAff("paralysis")
            elseif tAffs.pyramides then
              erAff("pyramides")
           else
                erAff("slickness")
           end
        end
    else
            if tAffs.paralysis then
                erAff("paralysis")
            elseif tAffs.pyramides then
        erAff("pyramides")        
            else
                erAff("slickness")
            end
    
  

    selectString(line, 1)
    fg("peru")
    resetFormat()

    tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
    if tAffs.mercury then
        tAffs.mercury = false
        tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
    else
        tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
    end
    
    if strikingHigh and not strikeHighTimer then
        strikingHigh = nil
        strikeHighTimer = tempTimer(1.15, [[
            if ataxia.vitals.ferocity == 4 and not haveAff("rebounding") then
                send("shieldstrike "..target.." high")
            end     
            strikeHighTimer = nil
        ]])
    end    
    targetIshere = true
  predictBal("herb", 1.55)	
end
selectString(line, 1)
	fg("red")
	resetFormat()