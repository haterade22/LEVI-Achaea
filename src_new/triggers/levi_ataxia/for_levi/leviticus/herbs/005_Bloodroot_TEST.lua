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

-- isTargeted, like the other herb triggers (002, 011-014): it also accepts a part name (`t sai`)
-- and completes the target's name. An exact compare sent a part-name target's eat to the old bystander branch.
if isTargeted(matches[2]) then
tdeliverance = false
    -- Eating proves no anorexia (anorexia blocks eating)
    erAff("anorexia")
    if anorexiaFailsafe then
        tAffs[lastFocus] = true
        ataxiaEcho("Backtracked anorexia being cured with last focus.")
        anorexiaFailsafe = nil
        lastFocus = nil
    end
    -- Track for adaptive serpent offense
    if serpent and serpent.trackCure then serpent.trackCure("bloodroot") end

    -- V2 tracking support: bloodroot cures paralysis or slickness
    if onTargetBloodrootV2 then onTargetBloodrootV2(matches[2]) end

    -- One eat cures ONE affliction. With V3 on, V3 decides which one (it branches on paralysis and
    -- slickness, and a quicksilver apply collapses the branches, 013). V3 then copies its result into
    -- tAffs. Until 2026-11-07 the V1 chain below ran after that copy as well: tAffs.paralysis was
    -- already false, so it erased slickness too, and every eat took two afflictions (the spar's
    -- slickness vanished this way). So the V1 chain runs only when V3 is off, like 002 Goldenseal.
    -- The V1 erase also raised "target cured aff" (the fight log's -tar row). onHerbCureV3 raises
    -- nothing, so a cure it made certain is reported here, as the passive cure does (008): through
    -- ataxia_tarAffFaded, which also stops a timed clock. A cure V3 only branched over is a guess,
    -- and it is not reported.
    local v3 = affConfigV3 and affConfigV3.enabled and onHerbCureV3
    if v3 then
      local pool = (curingTable and curingTable.bloodroot) or (curingTableV3 and curingTableV3.bloodroot) or {}
      local had = {}
      for _, aff in ipairs(pool) do
        if getAffProbabilityV3(aff) > 0 then had[#had + 1] = aff end
      end
      onHerbCureV3("bloodroot")
      if ataxia_tarAffFaded then
        for _, aff in ipairs(had) do
          if getAffProbabilityV3(aff) < 0.01 then ataxia_tarAffFaded(aff) end
        end
      end
    elseif tAffs.prone then
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
            if tAffs.paralysis and tAffs.slickness then
                -- Wait for quicksilver apply to disambiguate
                pendingBloodrootV1 = true
                if bloodrootApplyTimerV1 then killTimer(bloodrootApplyTimerV1) end
                bloodrootApplyTimerV1 = tempTimer(0.5, [[
                    if pendingBloodrootV1 then
                        ataxiaEcho("No apply: bloodroot cured paralysis")
                        erAff("paralysis")
                        pendingBloodrootV1 = nil
                    end
                    bloodrootApplyTimerV1 = nil
                ]])
            elseif tAffs.paralysis then
                erAff("paralysis")
            elseif tAffs.pyramides then
              erAff("pyramides")
           else
                erAff("slickness")
           end
        end

    -- The rest is about the TARGET's eat, so it stays in this branch. Until the spar fix
    -- (2026-11-07), an `else` here closed `if matches[2] == target`. The code below then ran only
    -- for SOMEONE ELSE's eat, and that branch also erased our target's paralysis, pyramides or
    -- slickness. So the target's own eat never set targetIshere, the plant clock or the herb
    -- prediction. Her 29 magnesium eats in that spar did not stop the TargetOutOfRoom timer.
    -- That branch also coloured the line peru, but the red below always replaced it in the same
    -- pass. So the peru is gone, and the line looks as it did before.
    tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
    if tAffs.mercury then
        erAff("mercury")
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
-- Every eat line, the target's or anyone else's, is red. A bystander's eat changes nothing else.
selectString(line, 1)
	fg("red")
	resetFormat()